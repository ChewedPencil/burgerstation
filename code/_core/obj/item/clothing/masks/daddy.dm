/obj/item/clothing/mask/daddy
	name = "true mask"
	icon = 'icons/obj/item/clothing/masks/daddy.dmi'

	flags_clothing = FLAG_CLOTHING_NOBEAST_HEAD
	desc = "Well, what is it?"
	desc_extended = "A giant mask depicting some sort of father figure. Speeds you up when worn."

	armor = /armor/brass/belt

	size = SIZE_3
	weight = -10

	worn_layer = LAYER_MOB_CLOTHING_ALL

	value = 500

	hidden_organs = list(
		BODY_HEAD = TRUE,
		BODY_HAIR_HEAD = TRUE,
		BODY_HAIR_FACE = TRUE,
		BODY_EYES = TRUE
	)

	item_slot = SLOT_HEAD | SLOT_FACE