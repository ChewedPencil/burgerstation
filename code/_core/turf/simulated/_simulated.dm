/turf/simulated/

	dynamic_lighting = TRUE

	health = null
	health_base = 100

	var/real_icon
	var/real_icon_state

	var/tile = FALSE //Set to true if this is a tile.

	var/turf/destruction_turf

	var/reinforced_material_id
	var/reinforced_color
	var/reinforced_alpha = 255
	var/reinforced_blend = BLEND_DEFAULT

	var/exposed = TRUE //Are pipes and other hidden objects visible?

	var/turf_temperature_mod = 0

	var/image/overlay/stored_water_overlay
	var/water_reagent

	var/blood_level = 0 //How bloody the turf is. Used for footprints.
	var/blood_level_hard = 0 //How many blood objects. Used for checking if there is blood.
	var/blood_color //The color of blood.
	var/wet_level = 0

	var/drying_add = 0.1
	var/drying_mul = 0.02

	var/slip_factor = 1

	var/organic = FALSE

	var/map_color = null //The map color. For drawing maps.

/turf/simulated/is_safe_teleport(var/check_contents=TRUE)

	if(collision_flags & FLAG_COLLISION_WALKING)
		return FALSE

	if(check_contents)
		for(var/atom/movable/M in src.contents)
			if(!M.density)
				continue
			if(M.collision_flags & FLAG_COLLISION_WALKING)
				return FALSE

	return ..()

/turf/simulated/proc/get_slip_strength(var/mob/living/L)
	return (wet_level ? 1 : 0) + (wet_level/100)*slip_factor

/turf/simulated/proc/add_wet(var/wet_to_add)
	var/old_wet = wet_level
	wet_level += wet_to_add
	SSturf.wet_turfs |= src
	if(old_wet <= 0)
		overlays.Cut()
		update_overlays()
	return TRUE

/turf/simulated/proc/add_blood_level(var/amount_to_add,var/minimus=0,var/desired_color)
	if(desired_color && desired_color != blood_color)
		if(!blood_level || !blood_color)
			blood_color = desired_color
		else
			blood_color = blend_colors(blood_color,desired_color,amount_to_add/(amount_to_add+blood_level))
	blood_level = max(0,minimus,blood_level+amount_to_add)
	return TRUE

/turf/simulated/proc/add_blood_level_hard(var/amount_to_add,var/minimus=0)
	blood_level_hard = max(0,minimus,blood_level_hard+amount_to_add)
	return TRUE

/turf/simulated/on_destruction(var/mob/caller,var/damage = FALSE)

	if(!destruction_turf)
		CRASH_SAFE("[get_debug_name()] called on_destruction without having a destruction turf!")
		return FALSE

	for(var/obj/effect/temp/impact/I in src.contents)
		I.alpha = 0

	. = ..()

	pixel_x = 0
	pixel_y = 0

	var/missing_health = health.health_current < 0 ? -health.health_current : 0

	change_turf(destruction_turf)
	if(missing_health && src.health)
		src.health.health_current -= missing_health
		src.health.update_health(caller,missing_health)

/turf/simulated/Initialize()
	var/area/A = loc
	if(!(A.flags_area & FLAG_AREA_NO_CONSTRUCTION))
		if(!destruction_turf)
			if(loc && loc.type != src.type && is_floor(loc))
				destruction_turf = loc.type
			else if(A.destruction_turf != src.type)
				destruction_turf = A.destruction_turf
		if(destruction_turf)
			health = /health/turf/
	set_exposed(exposed,!exposed)
	return ..()

/turf/simulated/PostInitialize()
	. = ..()
	if(istype(health))
		health.organic = organic

/turf/simulated/proc/get_smooth_code()

	var/list/calc_list = list()

	for(var/d in DIRECTIONS_ALL)
		var/dir_to_text = "[d]"
		calc_list[dir_to_text] = FALSE //Default
		var/turf/T = get_step(src,d)
		if(!T)
			continue
		if(should_smooth_with(T))
			calc_list[dir_to_text] = TRUE
			continue

	var/ne = ""
	var/nw = ""
	var/sw = ""
	var/se = ""

	if(!tile)
		if(calc_list["[NORTH]"])
			ne += "n"
			nw += "n"
		if(calc_list["[SOUTH]"])
			se += "s"
			sw += "s"

		if(calc_list["[EAST]"])
			ne += "e"
			se += "e"
		if(calc_list["[WEST]"])
			nw += "w"
			sw += "w"

	if(nw == "nw" && calc_list["[NORTHWEST]"])
		nw = "f"

	if(ne == "ne" && calc_list["[NORTHEAST]"])
		ne = "f"

	if(sw == "sw" && calc_list["[SOUTHWEST]"])
		sw = "f"

	if(se == "se" && calc_list["[SOUTHEAST]"])
		se = "f"

	if(!ne) ne = "i"
	if(!nw) nw = "i"
	if(!se) se = "i"
	if(!sw) sw = "i"

	return list(ne,nw,se,sw)


/turf/simulated/update_sprite()

	if(real_icon)
		icon = real_icon
	if(real_icon_state)
		icon_state = real_icon_state

	. = ..()

/turf/simulated/proc/smooth_turf()

	var/list/smooth_code = get_smooth_code()

	var/ne = smooth_code[1]
	var/nw = smooth_code[2]
	var/se = smooth_code[3]
	var/sw = smooth_code[4]

	var/full_icon_string = "[type]_[icon_state]_[ne][nw][se][sw]"

	var/icon/I

	if(SSturf.icon_cache[full_icon_string])
		I = SSturf.icon_cache[full_icon_string]
		SSturf.saved_icons++
	else
		I = new /icon(icon,"1-[nw]")

		var/icon/NE = new /icon(icon,"2-[ne]")
		I.Blend(NE,ICON_OVERLAY)

		var/icon/SW = new /icon(icon,"3-[sw]")
		I.Blend(SW,ICON_OVERLAY)

		var/icon/SE = new /icon(icon,"4-[se]")
		I.Blend(SE,ICON_OVERLAY)

		SSturf.icon_cache[full_icon_string] = I

	icon = I
	pixel_x = (TILE_SIZE - I.Width())/2
	pixel_y = (TILE_SIZE - I.Height())/2

	return TRUE

/turf/simulated/update_icon()

	if(!corner_icons)
		return ..()

	smooth_turf()

	return TRUE

/turf/simulated/update_overlays()

	. = ..()

	if(reinforced_material_id)
		var/image/I = new/image(initial(icon),"ref")
		I.appearance_flags = appearance_flags | RESET_COLOR | RESET_ALPHA
		I.color = "#FFFFFF"
		I.alpha = reinforced_alpha
		I.blend_mode = reinforced_blend
		add_overlay(I)


/turf/simulated/proc/set_exposed(var/desired_exposed = FALSE,var/force=FALSE)

	if(desired_exposed == exposed && !force)
		return FALSE

	for(var/obj/O in src.contents)
		if(!O.under_tile)
			continue
		if(desired_exposed)
			O.invisibility = 0
		else
			O.invisibility = 101

	return TRUE

