/*
/ai/proc/can_enter_turf(var/turf/T)

	if(!ignore_hazard_turfs && istype(T,/turf/simulated/liquid/))
		return FALSE

	return TRUE
*/

/ai/proc/post_move(var/mob/living/L,args)

	var/atom/old_loc = args[1]

	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(L.loc)

	//Frustration
	if(old_turf && new_turf)
		if(old_turf == new_turf)
			frustration_move++
			if(length(current_node_path))
				frustration_path++
			if(debug) log_debug("[src.get_debug_name()] post_move'd to the same loc")
		else
			frustration_move = max(0,frustration_move-0.25)
			if(debug) log_debug("[src.get_debug_name()] post_move'd to a different loc.")

	if(!new_turf || !old_turf || new_turf.z != old_turf.z)
		if(active)
			if(old_turf) remove_from_active_list(old_turf.z)
			if(new_turf) add_to_active_list(new_turf.z)
		else
			if(old_turf) remove_from_inactive_list(old_turf.z)
			if(new_turf) add_to_inactive_list(new_turf.z)

	return TRUE

/ai/proc/set_move_objective(var/atom/desired_objective,var/follow = FALSE) //Set follow to true if it should constantly follow the person.
	if(desired_objective)
		set_active(TRUE)
	objective_move = desired_objective
	should_follow_objective_move = follow
	return TRUE

/ai/proc/handle_movement_attack_objective()

	if(objective_attack)

		if(cowardice >= 0)
			var/health_percent = owner.health ? owner.health.health_current/owner.health.health_max : 1
			if(health_percent <= cowardice)
				owner.move_dir = get_dir(objective_attack,owner) //RUN AWAY.
				owner.movement_flags = MOVEMENT_RUNNING
				return TRUE
		if(!objective_attack.z) //Inside something. Get close to it.
			owner.move_dir = get_dir(owner,get_turf(objective_attack))
			owner.movement_flags = MOVEMENT_RUNNING
			return TRUE
		var/target_distance = get_dist(owner,objective_attack)
		if(target_distance < attack_distance_min) //Get farther to attack.
			owner.move_dir = get_dir(objective_attack,owner)
			owner.movement_flags = MOVEMENT_NORMAL
		if(target_distance > attack_distance_max) //Get closer to attack.
			owner.move_dir = get_dir(owner,objective_attack)
			owner.movement_flags = MOVEMENT_RUNNING
		else
			owner.movement_flags = MOVEMENT_NORMAL
			var/owner_to_objective_dir = get_dir(owner,objective_attack)
			var/turf/T1 = get_step(owner,owner_to_objective_dir)
			if(!T1.is_safe_teleport(FALSE))
				owner.move_dir = turn(owner_to_objective_dir,pick(-90,90,180))
				frustration_move++
				return TRUE
			var/objective_to_owner_dir = get_dir(objective_attack,owner)
			var/turf/T2 = get_step(objective_attack,objective_to_owner_dir)
			if(!T2.is_safe_teleport(FALSE))
				owner.move_dir = turn(objective_to_owner_dir,pick(-90,90,180))
				frustration_move++
				return TRUE
			if(prob(target_distance <= 1 ? 25 : 5)) //Strafe when close.
				owner.move_dir = turn(get_dir(owner,objective_attack),pick(-90,90))

		return TRUE

	return FALSE

/ai/proc/handle_movement_move_objective()
	if(objective_move)
		var/move_distance = get_dist(owner,objective_move)
		if(move_distance > 1)
			if(should_follow_objective_move && move_distance >= 4)
				owner.movement_flags = MOVEMENT_RUNNING
			else
				owner.movement_flags = MOVEMENT_NORMAL
			owner.move_dir = get_dir(owner,objective_move)
		else
			if(!should_follow_objective_move)
				set_move_objective(null)
			owner.movement_flags = MOVEMENT_NORMAL
			owner.move_dir = 0x0
		return TRUE
	return FALSE

/ai/proc/check_node_path_obstructions()

	if(length(current_node_path) < path_steps)
		return FALSE

	if(!current_node_path[path_steps])
		return FALSE

	var/obj/marker/map_node/desired_node = current_node_path[path_steps]
	var/turf/T1 = get_turf(owner)
	var/turf/T2 = locate(desired_node.x,desired_node.y,desired_node.z)
	var/list/obstructions = get_obstructions(T1,T2)

	if(!length(obstructions)) //All good.
		return TRUE

	if(set_path_astar(T2)) //Okay we found obstructions, but we can path through it.
		return TRUE

	for(var/k in obstructions) //Can't path though it, so we destroy it.
		var/atom/A = k
		if(!A.can_be_attacked(owner)) //Can't even destroy it. Just give up.
			obstacles.Cut()
			set_path(null)
			break //Give up.
		obstacles[A] = TRUE

	return TRUE


/ai/proc/handle_movement_astar()

	if(length(current_path_astar))
		var/turf/T = get_turf(owner)
		var/turf/desired_turf = current_path_astar[1]
		if(T == desired_turf)
			current_path_astar -= desired_turf
			if(length(current_path_astar))
				desired_turf = current_path_astar[1]
			else
				desired_turf = null
		if(desired_turf)
			owner.move_dir = get_dir(owner,desired_turf)
		else
			owner.move_dir = 0x0
			set_path_astar(null)
		return TRUE

	return FALSE

/ai/proc/handle_movement_path()
	if(length(current_node_path))
		if(path_steps <= length(current_node_path))
			var/obj/marker/map_node/desired_node = current_node_path[path_steps]
			var/desired_precision = desired_node.precision
			if(path_steps - 1 >= 1)
				var/obj/marker/map_node/last_node = current_node_path[path_steps-1]
				desired_precision = min(desired_precision,last_node.precision)
			var/turf/T = get_turf(owner)
			var/calc_distance = abs(desired_node.x - T.x) + abs(desired_node.y - T.y)
			if(calc_distance <= desired_precision) //We've made it to the next node.
				path_steps++
				owner.move_dir = 0
				if(check_for_obstructions) check_node_path_obstructions()
				frustration_path = 0
			else
				owner.move_dir = get_dir(owner,locate(desired_node.x,desired_node.y,desired_node.z))
		else //Complete path
			start_turf = get_turf(owner)
			set_path(null)
			owner.move_dir = 0
		return TRUE
	return FALSE

/ai/proc/handle_movement_path_frustration()

	if(frustration_path > frustration_path_threshold)

		frustration_path = 0

		var/obj/marker/map_node/N_start = find_closest_node(owner,check_view=TRUE)
		if(!N_start)
			set_path(null)
			return FALSE

		var/obj/marker/map_node/N_end = find_closest_node(path_end_turf)
		if(!N_end)
			log_error("[owner] ([owner.x],[owner.y],[owner.z]) is stuck and cannot find a path end!")
			set_path(null)
			return FALSE

		var/list/obj/marker/map_node/found_path = AStar_Circle_node(N_start,N_end)
		if(!found_path)
			log_error("[owner] ([owner.x],[owner.y],[owner.z]) is stuck and cannot find a final path!")
			set_path(null)
			return FALSE

		set_path_astar(get_turf(N_start))
		set_path(found_path)

		return TRUE

	return FALSE

/ai/proc/handle_movement_roaming()
	if(roaming_distance >= 1)
		if(get_dist(owner,start_turf) >= roaming_distance-1)
			owner.movement_flags = MOVEMENT_WALKING
			owner.move_dir = get_dir(owner,start_turf)
			return TRUE
		else if(roaming_distance > 1)
			if(roam)
				if(prob(5))
					owner.movement_flags = MOVEMENT_WALKING
					owner.move_dir = pick(DIRECTIONS_ALL)
					roam_counter -= 1
			else
				owner.movement_flags = MOVEMENT_WALKING
				owner.move_dir = 0x0
				if(prob(25))
					roam_counter -= 1
			if(roam_counter <= 0)
				roam = !roam
				roam_counter = initial(roam_counter)

	return FALSE

/ai/proc/handle_movement_alert()

	if(alert_level > ALERT_LEVEL_NONE && objective_investigate)
		owner.movement_flags = MOVEMENT_WALKING
		owner.move_dir = get_dir(owner,objective_investigate)
		return TRUE

	else if(alert_level == ALERT_LEVEL_CAUTION)
		owner.movement_flags = MOVEMENT_WALKING
		owner.move_dir = pick(list(0,0,0,0,NORTH,EAST,SOUTH,WEST))
		return TRUE

	return FALSE

/ai/proc/handle_movement_reset()
	owner.movement_flags = MOVEMENT_NORMAL
	owner.move_dir = 0x0
	return TRUE

/ai/proc/handle_movement()

	if(handle_movement_astar())
		return TRUE

	if(handle_movement_path_frustration())
		return TRUE

	if(handle_movement_attack_objective())
		return TRUE

	if(handle_movement_move_objective())
		return TRUE

	if(handle_movement_alert())
		return TRUE

	if(handle_movement_path())
		return TRUE

	if(handle_movement_roaming())
		return TRUE

	handle_movement_reset()

	return FALSE

/ai/proc/Bump(var/atom/obstacle,var/trigger_other_bump=TRUE)

	if(obstacle)
		if(is_living(obstacle))
			var/mob/living/L = obstacle
			if(is_enemy(L))
				set_alert_level(ALERT_LEVEL_CAUTION,FALSE,L,L)
				spawn do_attack(obstacle,prob(left_click_chance))
			if(trigger_other_bump && L.ai)
				L.ai.Bump(owner,FALSE)
		else if(attack_movement_obstructions)
			spawn do_attack(obstacle,prob(left_click_chance))



	return TRUE