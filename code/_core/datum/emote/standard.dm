/emote/dab
	name = "Dab"
	id = "dab"
	action = "\The #USER suddenly hits a dab!"
	action_target = "\The #USER dabs on #TARGET!"

/emote/nod
	name = "Nod Head"
	id = "nod"
	action = "\The #USER nods."
	action_target = "\The #USER nods their head at #TARGET."

/emote/shake
	name = "Shake Head"
	id = "shake"
	action = "\The #USER shakes their head."
	action_target = "\The #USER shakes their head at #TARGET."

/emote/bow
	name = "Bow"
	id = "bow"
	action = "\The #USER bows."
	action_target = "\The #USER bows towards #TARGET."

/emote/fist
	name = "Shake Fist"
	id = "fist"
	action = "\The #USER shakes their fist."
	action_target = "\The #USER shakes their fist at #TARGET!"

/emote/think
	name = "Think"
	id = "think"
	action = "\The #USER thinks."
	action_target = null

/emote/wave
	name = "Wave"
	id = "wave"
	action = "\The #USER waves."
	action_target = "\The #USER waves at #TARGET."

/emote/shrug
	name = "Shrug"
	id = "shrug"
	action = "\The #USER shrugs."
	action_target = null

/emote/cheer
	name = "Cheer"
	id = "cheer"
	action = "\The #USER cheers!"
	action_target = "\The #USER cheers #TARGET on!"

/emote/beckon
	name = "Beckon"
	id = "beckon"
	action = "\The #USER beckons."
	action_target = "\The #USER beckons #TARGET."

/emote/yawn
	name = "Yawn"
	id = "yawn"
	action = "\The #USER yawns."
	action_target = "\The #USER yawns at #TARGET."

/emote/cry
	name = "Cry"
	id = "cry"
	action = "\The #USER cries."
	action_target = "\The #USER cries towards #TARGET!"

/emote/clap
	name = "Clap"
	id = "clap"
	action = "\The #USER claps!"
	action_target = "\The #USER claps for #TARGET!"

/emote/salute
	name = "Salute"
	id = "salute"
	action = "\The #USER salutes!"
	action_target = "\The #USER salutes #TARGET!"

/emote/inhale
	name = "Inhale"
	id = "inhale"
	action = "\The #USER inhales."

/emote/inhale/on_emote(var/atom/emoter,var/atom/target)
	if(is_advanced(emoter))
		var/mob/living/advanced/A = emoter
		if(A.inventories_by_id[BODY_FACE])
			var/obj/item/I = A.inventories_by_id[BODY_FACE].get_top_object()
			if(istype(I,/obj/item/container/cigarette))
				var/obj/item/container/cigarette/C = I
				C.consume(5)
	. = ..()

/emote/drag
	name = "Drag"
	id = "drag"
	action = "\The #USER takes a drag from their smoke."

/emote/drag/can_emote(var/atom/emoter,var/atom/target)
	. = ..()
	if(!.) return FALSE
	if(is_advanced(emoter))
		var/mob/living/advanced/A = emoter
		if(A.inventories_by_id[BODY_FACE])
			var/obj/item/I = A.inventories_by_id[BODY_FACE].get_top_object()
			if(istype(I,/obj/item/container/cigarette))
				return TRUE

/emote/drag/on_emote(var/atom/emoter,var/atom/target)
	if(is_advanced(emoter))
		var/mob/living/advanced/A = emoter
		if(A.inventories_by_id[BODY_FACE])
			var/obj/item/I = A.inventories_by_id[BODY_FACE].get_top_object()
			if(istype(I,/obj/item/container/cigarette))
				var/obj/item/container/cigarette/C = I
				C.consume(10)
	. = ..()

/emote/exhale
	name = "Exhale"
	id = "exhale"
	action = "\The #USER exhales."

/emote/exhale
	name = "Blink"
	id = "blink"
	action = "\The #USER blinks."

/emote/spin
	name = "Spin"
	id = "spin"
	action = null
	action_target = null

/emote/spin/proc/spin(var/atom/emoter,var/spins_remaining=0)

	emoter.set_dir(turn(emoter.dir,90))

	if(spins_remaining > 0)
		CALLBACK("\ref[emoter]_spin",1,src,.proc/spin,emoter,spins_remaining-1)

/emote/spin/on_emote(var/atom/emoter,var/atom/target)
	spin(emoter,11)
	return ..()

/emote/help
	name = "Help"
	id = "help"
	action = null
	action_target = null

/emote/help/on_emote(var/atom/emoter,var/atom/target)
	var/mob/M = emoter
	M.view_emotes()
	return ..()