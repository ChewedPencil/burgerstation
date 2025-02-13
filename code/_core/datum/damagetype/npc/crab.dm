/damagetype/npc/crab
	attack_verbs = list("pinch","snip")

	//The base attack damage of the weapon. It's a flat value, unaffected by any skills or attributes.
	attack_damage_base = list(
		BLADE = 30*0.3,
		PIERCE = 30*0.1,
	)

	attack_damage_penetration = list(
		BLADE = 20*0.25,
		PIERCE = 20*0.75
	)

	attribute_stats = list(
		ATTRIBUTE_STRENGTH = 30*0.4,
		ATTRIBUTE_DEXTERITY = 30*0.2
	)

	attribute_damage = list(
		ATTRIBUTE_STRENGTH = list(BLADE,PIERCE),
		ATTRIBUTE_DEXTERITY = list(BLADE,PIERCE)
	)

	attack_delay = 10*0.5
	attack_delay_max = 10