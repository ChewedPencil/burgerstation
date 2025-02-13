/datum/
	var/qdel_warning = 0
	var/qdel_warning_time = FALSE
	var/qdeleting = FALSE
	var/initialized = FALSE
	var/generated = FALSE
	var/finalized = FALSE
	var/queue_delete_immune = FALSE
	var/list/hooks

/datum/proc/get_examine_list(var/mob/examiner)
	return list(div("examine_title","[src]"),div("examine_description","[src.type]"))

/datum/proc/get_examine_details_list(var/mob/examiner)
	return list()

/datum/proc/Initialize()
	if(initialized)
		CRASH_SAFE("WARNING: [src.get_debug_name()] was initialized twice!")
		return TRUE
	return TRUE

/datum/proc/PostInitialize()
	return TRUE

/datum/proc/Generate() //Generate the atom, giving it stuff if needed.
	if(generated)
		CRASH_SAFE("WARNING: [src.get_debug_name()] was generated twice!")
		return TRUE
	return TRUE

/datum/proc/Finalize() //We're good to go.
	if(finalized)
		CRASH_SAFE("WARNING: [src.get_debug_name()] was finalized twice!")
		return TRUE
	return TRUE

/datum/proc/delete()
	qdel(src)
	return TRUE


/datum/Destroy()
	HOOK_CALL("Destroy")
	hooks?.Cut()
	. = ..()

/datum/proc/get_debug_name()
	return "[src.type]"

/datum/proc/get_log_name()
	return "[src.type]"

/datum/atom/Destroy()

	if(!finalized)
		log_error("Warning: [get_debug_name()] is being destroyed before it is finalized!")

	return ..()