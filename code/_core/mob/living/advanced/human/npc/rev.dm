/mob/living/advanced/npc/rev
	name = "revolutionary soldier"
	desc = "FOR THE REVOLUTION!"
	desc_extended = "An ex-nanotrasen revolutionary soldier fighting for their right to \[EXPUNGED\]. Surprisingly, they're not syndicate backed."
	ai = /ai/advanced/slavic

	var/list/possible_outfits = list(
		/loadout/rev/solider = 10,
		/loadout/rev/solider/alt = 10,
		/loadout/rev/skat = 10,
		/loadout/rev/exo = 5,
		/loadout/rev/sniper = 5
	)

	var/loadout_to_level = list(
		/loadout/rev/solider = 1,
		/loadout/rev/solider/alt = 2,
		/loadout/rev/skat = 4,
		/loadout/rev/exo = 8,
		/loadout/rev/sniper = 8
	)

	level = 22

/mob/living/advanced/npc/rev/Initialize()

	var/loadout_to_use = pickweight(possible_outfits)
	level *= loadout_to_level[loadout_to_use]

	. = ..()

	var/species/S = SPECIES(species)

	sex = pick(MALE,FEMALE)
	gender = sex

	change_organ_visual("skin", desired_color = pick("#E0BCAA","#BC9E8F","#967F73","#7A675E"))

	var/hair_color = random_color()
	change_organ_visual("hair_head", desired_color = hair_color, desired_icon_state = pick(SSspecies.all_hair_files[S.default_icon_hair]))
	if(sex == MALE && prob(25))
		change_organ_visual("hair_face", desired_color = hair_color, desired_icon_state = pick(SSspecies.all_hair_files[S.default_icon_hair_face]))

	src.add_organ(/obj/item/organ/internal/implant/hand/left/iff/revolutionary)
	src.add_organ(/obj/item/organ/internal/implant/head/loyalty/revolutionary)

	update_all_blends()

	equip_loadout(loadout_to_use)

