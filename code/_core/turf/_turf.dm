/turf/
	name = "TURF ERROR"
	desc = "Report to Burger#3948 on discord"
	icon = 'icons/debug/turfs.dmi'
	icon_state = ""

	plane = PLANE_FLOOR
	layer = LAYER_FLOOR

	opacity = 0

	appearance_flags = PIXEL_SCALE | TILE_BOUND

	mouse_over_pointer = MOUSE_INACTIVE_POINTER
	collision_flags = FLAG_COLLISION_NONE

	//Density
	var/density_north = FALSE
	var/density_south = FALSE
	var/density_east  = FALSE
	var/density_west  = FALSE
	var/density_up    = FALSE
	var/density_down  = TRUE
	var/allow_bullet_pass = FALSE

	var/footstep/footstep //The footstep sounds that play.

	var/list/mob/living/old_living //List of mobs that used to be on this turf.

	var/material_id

	var/move_delay_modifier = 1 //Increase to make it harder to move on this turf. Decrease to make it easier. Only applies to mobs that touch the floor.

	var/world_spawn = FALSE

	var/list/stored_shuttle_items //List of movables

	var/safe_fall = FALSE //Set to true if it's safe to fall on this tile.

	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER | VIS_INHERIT_ID

	var/disallow_generation = FALSE

	var/friction = TRUE //True or false. Can't really do decimals 0 to 1, yet.

	var/parallax_icon = 'icons/obj/effects/parallax.dmi'

	//Stored variables for shuttles
	var/area/transit_area
	var/turf/transit_turf

	density = FALSE

	var/corner_icons = FALSE
	var/corner_category = "none"

	var/has_dense_atom = FALSE

/turf/proc/recalculate_atom_density()

	has_dense_atom = FALSE

	if(density)
		has_dense_atom = TRUE
		return TRUE

	for(var/k in src.contents)
		var/atom/movable/M = k
		if(M.density)
			has_dense_atom = TRUE
			break

	return TRUE

/turf/proc/pre_change() //When this turf is removed in favor of a new turf.
	return TRUE

/turf/proc/get_crossable_neighbors(var/atom/movable/crosser=null,var/cardinal=TRUE,var/intercardinal=TRUE)

	. = list()
	if(cardinal)
		for(var/d in DIRECTIONS_CARDINAL)
			var/turf/T = get_step(src,d)
			if(!T.Enter(null,src))
				continue
			var/can_cross = TRUE
			for(var/k in T.contents)
				var/atom/movable/M = k
				if(!M.density)
					continue
				if(M.allow_path)
					continue
				if(M.Cross(crosser,src))
					continue
				can_cross = FALSE
				break
			if(!can_cross)
				continue
			. += T

	if(intercardinal)
		for(var/d in DIRECTIONS_INTERCARDINAL)
			var/first_dir = get_true_4dir(d)
			var/second_dir = d & ~first_dir

			var/turf/T1 = get_step(src,first_dir)
			if(!T1) continue

			var/turf/T2 = get_step(T1,second_dir)

			if(!T1.Enter(null,src))
				continue

			if(!T2.Enter(null,T1))
				continue

			var/can_cross = TRUE
			for(var/k in T1.contents)
				var/atom/movable/M = k
				if(!M.density)
					continue
				if(M.allow_path)
					continue
				if(M.Cross(crosser,src))
					continue
				can_cross = FALSE
				break
			if(!can_cross)
				continue

			for(var/k in T2.contents)
				var/atom/movable/M = k
				if(!M.density)
					continue
				if(M.allow_path)
					continue
				if(M.Cross(crosser,T1))
					continue
				can_cross = FALSE
				break
			if(!can_cross)
				continue

			. += T2


/turf/proc/on_step()
	return TRUE

/turf/proc/is_space()
	var/area/A = loc
	return istype(A) && A.is_space()

/turf/proc/is_safe_teleport(var/check_contents=TRUE)

	var/area/A = loc
	if(A && A.flags_area & FLAG_AREA_NO_LOYALTY)
		return FALSE

	return !is_space()


/turf/proc/post_move(var/mob/M,var/atom/old_loc)

	if(M.ckey_last) //Only care about mobs with ckeys.
		for(var/k in M.parallax)
			var/obj/parallax/P = M.parallax[k]
			P.icon = parallax_icon
			var/desired_x = FLOOR(-(src.x - (WORLD_SIZE*0.5)) * P.ratio,1)
			var/desired_y = FLOOR(-(src.y - (WORLD_SIZE*0.5)) * P.ratio,1)
			P.screen_loc = "CENTER-7:[desired_x],CENTER-7:[desired_y]"

	return TRUE

/turf/New(loc)

	. = ..()

	if(opacity)
		has_opaque_atom = TRUE

	if(density)
		has_dense_atom = TRUE


/turf/Destroy()
	CRASH("Tried destroying a turf!")
	return FALSE

/turf/Finalize()
	. = ..()
	if(corner_icons)
		if(SSsmoothing.initialized)
			SSsmoothing.queue_update_edges(src)
		else
			SSsmoothing.queued_smoothing |= src


/*
/turf/clicked_on_by_object(var/mob/caller,var/atom/object,location,control,params)
	caller.face_atom(src)
	return ..()
*/

/turf/change_victim(var/atom/attacker,var/atom/object)

	if(density_north || density_south || density_east || density_west)
		return src

	for(var/k in contents)
		var/atom/movable/v = k
		if(attacker == v)
			continue
		if(!v.health)
			continue
		if(ismob(v))
			var/mob/M = v
			if(M.mouse_opacity == 0)
				continue
		if(!v.can_be_attacked(attacker))
			continue
		return v

	if(old_living)
		for(var/k in old_living)
			var/mob/living/L = k
			if(attacker == L || L.dead || L.mouse_opacity <= 0 || L.next_move <= 0 || get_dist(L,src) > 1)
				continue
			return L

	return src

/turf/proc/do_footstep(var/mob/living/source,var/enter=FALSE)

	if(!source.has_footsteps)
		return FALSE

	var/list/returning_footsteps = source.get_footsteps(footstep ? list(footstep) : list(),enter)
	if(length(returning_footsteps))
		return source.handle_footsteps(src,returning_footsteps,enter)

	return FALSE

/turf/Entered(var/atom/movable/enterer,var/atom/old_loc)

	if(src.loc && (!old_loc || src.loc != old_loc.loc))
		src.loc.Entered(enterer)

	. = ..()

	if(!enterer.qdeleting && is_living(enterer))
		do_footstep(enterer,TRUE)

	if(!density_down)
		var/turf/T = locate(x,y,z-1)
		if(T && !T.density_up && enterer.Move(T) && !T.safe_fall)
			enterer.on_fall(src)

	if(enterer.density)
		has_dense_atom = TRUE

	var/area/A = src.loc

	if(enterer.enable_chunk_clean && SSchunk.initialized && !A.safe_storage)
		var/old_loc_chunk_x = old_loc ? CEILING(old_loc.x/CHUNK_SIZE,1) : 0
		var/old_loc_chunk_y = old_loc ? CEILING(old_loc.y/CHUNK_SIZE,1) : 0
		var/old_loc_chunk_z = old_loc ? old_loc.z : 0

		var/new_loc_chunk_x = CEILING(src.x/CHUNK_SIZE,1)
		var/new_loc_chunk_y = CEILING(src.y/CHUNK_SIZE,1)
		var/new_loc_chunk_z = src.z

		if(new_loc_chunk_z > 0 && old_loc_chunk_x != new_loc_chunk_x || old_loc_chunk_y != new_loc_chunk_y || old_loc_chunk_z != new_loc_chunk_z)
			var/chunk/new_chunk = SSchunk.chunks[new_loc_chunk_z][new_loc_chunk_x][new_loc_chunk_y]
			if(new_chunk) new_chunk.cleanables += enterer

/turf/Exited(var/atom/movable/exiter,var/atom/new_loc)

	if(src.loc && (!new_loc || src.loc != new_loc.loc))
		src.loc.Exited(exiter)

	. = ..()

	if(!exiter.qdeleting && is_living(exiter))
		do_footstep(exiter,FALSE)

	if(exiter.density)
		recalculate_atom_density()

	if(exiter.enable_chunk_clean && SSchunk.initialized)

		var/old_loc_chunk_x = CEILING(src.x/CHUNK_SIZE,1)
		var/old_loc_chunk_y = CEILING(src.y/CHUNK_SIZE,1)
		var/old_loc_chunk_z = src.z

		var/new_loc_chunk_x = new_loc ? CEILING(new_loc.x/CHUNK_SIZE,1) : 0
		var/new_loc_chunk_y = new_loc ? CEILING(new_loc.y/CHUNK_SIZE,1) : 0
		var/new_loc_chunk_z = new_loc ? new_loc.z : 0

		if(old_loc_chunk_z > 0 && old_loc_chunk_x != new_loc_chunk_x || old_loc_chunk_y != new_loc_chunk_y || old_loc_chunk_z != new_loc_chunk_z)
			var/chunk/old_chunk = SSchunk.chunks[old_loc_chunk_z][old_loc_chunk_x][old_loc_chunk_y]
			if(old_chunk) old_chunk.cleanables -= exiter


/turf/can_be_attacked(var/atom/attacker,var/atom/weapon,var/params,var/damagetype/damage_type)
	return istype(health)

/turf/Enter(var/atom/movable/enterer,var/atom/oldloc)

	if(enterer && oldloc && length(contents) > TURF_CONTENT_LIMIT && !ismob(enterer))
		return FALSE

	if(density && (!enterer || (enterer.collision_flags && src.collision_flags) && (enterer.collision_flags & src.collision_flags)))
		if(oldloc)
			var/enter_direction = get_dir(oldloc,src)
			if((enter_direction & NORTH) && density_north)
				return FALSE
			if((enter_direction & EAST) && density_east)
				return FALSE
			if((enter_direction & SOUTH) && density_south)
				return FALSE
			if((enter_direction & WEST) && density_west)
				return FALSE
		else if(density_west || density_east || density_south || density_north)
			return FALSE

	return ..()


/turf/act_explode(var/atom/owner,var/atom/source,var/atom/epicenter,var/magnitude,var/desired_loyalty_tag)

	for(var/k in src.contents)
		var/atom/movable/M = k
		M.act_explode(owner,source,epicenter,magnitude,desired_loyalty_tag)

	return ..()

/turf/proc/setup_turf_light(var/sunlight_freq)
	return FALSE

/turf/should_smooth_with(var/turf/T)

	if(T.plane == plane && T.corner_category == corner_category)
		return T

	for(var/obj/structure/O in T.contents)
		if(O.corner_category != corner_category)
			continue
		if(O.plane != plane)
			continue
		return O

	return null

/turf/proc/is_occupied(var/plane_min=-INFINITY,var/plane_max=INFINITY,var/check_under_tile=FALSE)

	for(var/atom/movable/A in src.contents)
		if(A.plane < plane_min || A.plane > plane_max)
			continue
		if(istype(A,/obj/effect/temp/construction/))
			return A
		if(is_living(A))
			return A
		if(isobj(A))
			var/obj/O = A
			if(check_under_tile && O.under_tile)
				return O
			if(is_structure(O))
				return O

	return null

/turf/proc/can_construct_on(var/mob/caller,var/obj/structure/structure_to_make)
	caller.to_chat(span("warning","You cannot deploy on this turf!"))
	return FALSE

/turf/proc/is_straight_path_to(var/turf/target_turf,var/check_vision=FALSE,var/check_density=TRUE)

	if(src == target_turf)
		return TRUE

	if(!check_vision && !check_density)
		return FALSE

	if(src.z != target_turf.z)
		return FALSE

	var/limit = get_dist(src,target_turf)
	if(limit >= 64) //Don't want to path forever.
		return FALSE
	limit *= 2 //Compensates for corners.

	var/list/diag = list(
		"[NORTHEAST]" = TRUE,
		"[SOUTHEAST]" = TRUE,
		"[NORTHWEST]" = TRUE,
		"[SOUTHWEST]" = TRUE
	)

	var/turf/T = src
	while(limit>0)
		limit--
		var/next_direction = get_dir(T,target_turf)
		if(diag["[next_direction]"])
			var/dir1 = get_true_4dir(next_direction)
			var/turf/T1 = get_step(T,dir1)
			if((check_density && T1.has_dense_atom) || (check_vision && T1.has_opaque_atom))
				var/dir2 = next_direction - dir1
				var/turf/T2 = get_step(T,dir2)
				if((check_density && T2.has_dense_atom) || (check_vision && T2.has_opaque_atom))
					return FALSE
		T = get_step(T,next_direction)
		if(T == target_turf)
			return TRUE
		if((check_density && T.has_dense_atom) || (check_vision && T.has_opaque_atom))
			return FALSE