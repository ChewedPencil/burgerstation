/obj/item/weapon/ranged/bullet/revolver/detective
	name = "\improper .38 Special revolver"
	desc = "The detective's trusty sidearm. Uses .38 revolver rounds."
	desc_extended = "Private Detectives still carry snub-nose revolvers due to them packing a bigger punch in a much smaller guns. Can be useful in a pinch."
	icon = 'icons/obj/item/weapons/ranged/revolver/38.dmi'
	icon_state = "inventory"
	value = 300

	company_type = "Solarian"

	tier = 1

	shoot_delay = 2

	automatic = FALSE

	bullet_count_max = 6

	shoot_sounds = list('sound/weapons/revolver_light/revolver.ogg')

	size = SIZE_1
	weight = 5

	bullet_length_min = 10
	bullet_length_best = 29
	bullet_length_max = 30

	bullet_diameter_min = 8.5
	bullet_diameter_best = 9
	bullet_diameter_max = 9.5

	heat_max = 0.05

	attachment_whitelist = list(
		/obj/item/attachment/barrel/charger = TRUE, /obj/item/attachment/barrel/charger/advanced = TRUE,
		/obj/item/attachment/barrel/compensator = TRUE,
		/obj/item/attachment/barrel/extended = TRUE,
		/obj/item/attachment/barrel/gyro = TRUE,
		/obj/item/attachment/barrel/laser_charger = FALSE,
		/obj/item/attachment/barrel/suppressor = FALSE,

		/obj/item/attachment/sight/laser_sight = TRUE,
		/obj/item/attachment/sight/quickfire_adapter = TRUE,
		/obj/item/attachment/sight/red_dot = TRUE,
		/obj/item/attachment/sight/scope = TRUE,
		/obj/item/attachment/sight/scope/large = TRUE,
		/obj/item/attachment/sight/targeting_computer = TRUE,



		/obj/item/attachment/undermount/angled_grip = TRUE,
		/obj/item/attachment/undermount/bipod = TRUE,
		/obj/item/attachment/undermount/burst_adapter = FALSE,
		/obj/item/attachment/undermount/vertical_grip = TRUE
	)

	attachment_barrel_offset_x = 28 - 16
	attachment_barrel_offset_y = 19 - 16

	attachment_sight_offset_x = 17 - 16
	attachment_sight_offset_y = 19 - 16

	attachment_undermount_offset_x = 26 - 16
	attachment_undermount_offset_y = 17 - 16

	inaccuracy_modifier = 0.25
	movement_inaccuracy_modifier = 0.25
	movement_spread_base = 0.02

/obj/item/weapon/ranged/bullet/revolver/detective/get_static_spread()
	return 0

/obj/item/weapon/ranged/bullet/revolver/detective/get_skill_spread(var/mob/living/L)
	return max(0,0.005 - (0.02 * L.get_skill_power(SKILL_RANGED)))