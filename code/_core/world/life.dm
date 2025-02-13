var/global/time_dialation = 0

/world/proc/life()

	world_log("Starting world...")

	world_state = STATE_INITIALIZING

	for(var/subsystem in subtypesof(/subsystem/))
		var/subsystem/S = subsystem
		if(!initial(S.priority))
			log_subsystem("Subsystem Controller","ERROR: COUNT NOT LOAD SUBSYSTEM [S.name].")
			continue
		S = new subsystem
		active_subsystems += S

	log_subsystem("Subsystem Controller","Created [length(active_subsystems)] subsystems.")

	sortMerge(active_subsystems, /proc/cmp_subsystem_priority)

	log_subsystem("Subsystem Controller","[length(active_subsystems)] subsystems sorted.")

	var/benchmark = true_time()

	var/current_priority = 0
	var/last_subsystem = ""

	for(var/k in active_subsystems)
		var/subsystem/SS = k
		var/local_benchmark = true_time()
		if(SS.priority < current_priority)
			log_error("Wait, what the fuck? [last_subsystem] wasn't sorted properly! This is a fatal error, so everything is being stopped.")
			return FALSE
		current_priority = SS.priority
		last_subsystem = SS.name
		log_subsystem(SS.name,"Initializing...")
		INITIALIZE(SS)
		log_subsystem(SS.name,"Initialization took [DECISECONDS_TO_SECONDS((true_time() - local_benchmark))] seconds.")
		sleep(-1)

	var/final_time_text = "All initializations took [DECISECONDS_TO_SECONDS((true_time() - benchmark))] seconds."
	log_subsystem("Subsystem Controller","[length(active_subsystems)] subsystems initialized.")
	log_subsystem("Subsystem Controller",final_time_text)
	log_debug(final_time_text)

	for(var/k in active_subsystems)
		var/subsystem/SS = k
		spawn while(SS.tick_rate >= 0 && world_state != STATE_SHUTDOWN)
			if(SS.tick_rate > 0 && SS.overtime_count < SS.overtime_max)
				if(SS.cpu_usage_max > 0 && world.cpu > SS.cpu_usage_max)
					SS.overtime_count++
					sleep(TICK_LAG)
					continue
				if(SS.tick_usage_max > 0 && world.tick_usage > SS.tick_usage_max)
					SS.overtime_count++
					sleep(TICK_LAG)
					continue
			SS.overtime_count = 0
			var/start_time = true_time()
			var/result = SS.on_life()
			if(result == null)
				log_error("[SS.name] failed to run properly!")
				sleep(10)
				continue
			else if(result == FALSE || SS.tick_rate <= 0)
				log_subsystem(SS.name,"Shutting down.")
				break
			SS.last_run_duration = FLOOR(true_time() - start_time,0.01)
			SS.total_run_duration += SS.last_run_duration
			if(time_dialation && SS.use_time_dialation)
				sleep(TICKS_TO_DECISECONDS(SS.tick_rate*time_dialation))
			else
				sleep(TICKS_TO_DECISECONDS(SS.tick_rate))

	world_state = STATE_RUNNING

	if(CONFIG("ENABLE_INSTALOAD",FALSE))
		for(var/mob/abstract/observer/menu/O in all_mobs_with_clients)
			if(!O.load_most_recent_character())
				O.new_character()

	else if(length(lobby_positions))
		for(var/mob/abstract/observer/menu/O in all_mobs_with_clients)
			var/list/possible_music = TRACKS_LOBBY
			var/lobby_track = 1 + (SSlogging.round_id % length(possible_music))
			O.force_move(get_turf(pick(lobby_positions)))
			play_music_track(possible_music[lobby_track], O.client)
			O.show_hud(TRUE,speed = SECONDS_TO_DECISECONDS(2))

	log_subsystem("Subsystem Controller","Life initializations complete.")

	update_server_status()

	return TRUE