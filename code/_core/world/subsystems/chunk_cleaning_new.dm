SUBSYSTEM_DEF(chunk)
	name = "Chunk Subsystem"
	desc = "Handles chunk cleaning."
	tick_rate = SECONDS_TO_TICKS(300) //JUST LIKE MINECRAFT
	priority = SS_ORDER_DELETE

	cpu_usage_max = 25
	tick_usage_max = 25

	var/current_z = 0

	var/list/chunks //Z, X, Y

	var/chunk_count_x = 0
	var/chunk_count_y = 0
	var/chunk_count_z = 0

/subsystem/chunk/Initialize()

	chunk_count_x = CEILING(world.maxx/CHUNK_SIZE,1)
	chunk_count_y = CEILING(world.maxy/CHUNK_SIZE,1)
	chunk_count_z = world.maxz

	if(!chunk_count_x || !chunk_count_y || !chunk_count_z)
		//Something went wrong...
		return FALSE

	chunks = new/list(chunk_count_z,chunk_count_x,chunk_count_y)

	log_subsystem(src.name,"Creating multidimensional chunks list of [chunk_count_z],[chunk_count_x],[chunk_count_y].")

	//Make all the chunks
	var/added_chunks = 0
	for(var/z=1,z<=chunk_count_z,z++) for(var/x=1,x<=chunk_count_x,x++) for(var/y=1,y<=chunk_count_y,y++)
		chunks[z][x][y] = new /chunk/
		added_chunks++

	log_subsystem(src.name,"Added [added_chunks] chunks.")


	//Link adjacent chunks to eachother.
	for(var/z=1,z<=chunk_count_z,z++) for(var/x=1,x<=chunk_count_x,x++) for(var/y=1,y<=chunk_count_y,y++)
		var/chunk/C = chunks[z][x][y]
		//get adjacents
		for(var/x2=-1,x2<=1,x2++) for(var/y2=-1,y2<=1,y2++).
			if(x2==0 && y2==0)
				continue
			if(x+x2 < 1 || y+y2 < 1 || x+x2 > chunk_count_x || y+y2 > chunk_count_y)
				continue
			C.adjacent_chunks += chunks[z][x+x2][y+y2]

	//Add existing map nodes to chunks.
	for(var/k in all_map_nodes)
		var/obj/marker/map_node/N = k
		if(!N.loc || !N.loc.z)
			continue
		var/x = CEILING(N.loc.x/CHUNK_SIZE,1)
		var/y = CEILING(N.loc.y/CHUNK_SIZE,1)
		var/z = N.loc.z
		var/chunk/CH = chunks[z][x][y]
		CH.nodes += N

	. = ..()

	tick_rate = initial(tick_rate) //Set the tick rate based on the amount of z-levels.
	if(world.maxz >= 1)
		tick_rate = CEILING(tick_rate/world.maxz,1)

	var/total_spawnpoints = 0
	for(var/k in SSliving.all_living) //Setup spawnpoints for respawning mobs.
		var/mob/living/L = k
		if(!L.respawn)
			continue
		var/turf/simulated/T = get_turf(L)
		if(!istype(T))
			log_error("Warning: [T] at ([T.x],[T.y],[T.z]) is not a simulated turf and had a mob spawnpoint on it.")
			continue
		var/area/A = T.loc
		if(A.safe_storage)
			continue
		var/obj/marker/mob_spawn/M = new(T,L.type,L,L.respawn_time,L.force_spawn)
		M.set_dir(L.random_spawn_dir ? pick(NORTH,EAST,SOUTH,WEST) : L.dir)
		total_spawnpoints++

	log_subsystem(src.name,"Created [total_spawnpoints] mob spawnpoints.")

/subsystem/chunk/on_life()

	if(current_z == 0)
		//First time initialize. Don't clean.
		current_z++
		return TRUE

	var/benchmark = true_time()
	current_z = (current_z % world.maxz) + 1
	var/process_count = process_entire_z(current_z)
	benchmark = true_time() - benchmark
	log_subsystem(src.name,"Cleaning zlevel [current_z] took [CEILING(benchmark/10,0.1)] seconds and deleted [process_count] mobs/items.")

	return TRUE

/subsystem/chunk/proc/process_entire_z(var/z)

	. = 0

	if(z <= 0)
		return .

	var/list/chunks_to_process = list()

	for(var/x=1,x<=chunk_count_x,x++) for(var/y=1,y<=chunk_count_y,y++)
		var/chunk/C = chunks[z][x][y]
		chunks_to_process += C

	var/old_chunks = length(chunks_to_process)

	log_subsystem(src.name,"Checking [old_chunks] chunks...")

	for(var/k in chunks_to_process)
		var/chunk/C = k
		if(length(C.players))
			chunks_to_process -= C
			chunks_to_process -= C.adjacent_chunks

	log_subsystem(src.name,"Filtered out [old_chunks - length(chunks_to_process)] chunks due to player presence...")

	for(var/k in chunks_to_process)
		var/chunk/C = k
		if(length(C.players) || !length(C.cleanables))
			continue
		for(var/j in C.cleanables)
			CHECK_TICK_SAFE(tick_usage_max,FPS_SERVER*10)
			var/atom/movable/M = j
			if(M.z)
				var/chunk_x = CEILING(M.x/CHUNK_SIZE,1)
				var/chunk_y = CEILING(M.y/CHUNK_SIZE,1)
				var/chunk/C2 = SSchunk.chunks[M.z][chunk_x][chunk_y]
				if(C != C2)
					log_error("Chunk error! [M.get_debug_name()] was found in the wrong chunk!")
			if(M.on_chunk_clean())
				. += 1