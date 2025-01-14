/datum/advclass/cheesemaker
	name = "Cheesemaker"
	tutorial = "Cheese cheese cheese! You have a rare wheel of cheese and know how to make more of the rare delicacy \
	As very skilled cook you come with some ingredients to make food and feed the masses. \
	cook up some cuisine with food gathered from the local flora and fauna"
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALLPLUSKOBOLD
	outfit = /datum/outfit/job/roguetown/adventurer/cheesemaker

	category_tags = list(CTAG_PILGRIM, CTAG_TOWNER)

/datum/outfit/job/roguetown/adventurer/cheesemaker/pre_equip(mob/living/carbon/human/H)
	..()
	H.mind.adjust_skillrank(/datum/skill/combat/wrestling, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/combat/unarmed, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/combat/knives, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/craft/crafting, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/misc/reading, 2, TRUE)
	H.mind.adjust_skillrank(/datum/skill/misc/sewing, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/labor/butchering, 2, TRUE)
	H.mind.adjust_skillrank(/datum/skill/craft/cooking, 3, TRUE)
	H.mind.adjust_skillrank(/datum/skill/labor/farming, 2, TRUE)
	H.mind.adjust_skillrank(/datum/skill/misc/medicine, 1, TRUE)
	H.mind.adjust_skillrank(/datum/skill/combat/improvised, 2, TRUE)
	mouth = /obj/item/rogueweapon/huntingknife
	belt = /obj/item/storage/belt/rogue/leather
	pants = /obj/item/clothing/under/roguetown/tights/random
	shirt = /obj/item/clothing/suit/roguetown/shirt/shortshirt/random
	cloak = /obj/item/clothing/cloak/apron
	shoes = /obj/item/clothing/shoes/roguetown/simpleshoes
	backl = /obj/item/storage/backpack/rogue/backpack
	neck = /obj/item/storage/belt/rogue/pouch/coins/poor
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
	beltr = /obj/item/reagent_containers/glass/bottle/waterskin/milk
	beltl = /obj/item/flint
	backpack_contents = list(
		/obj/item/reagent_containers/powder/salt = 3,
		/obj/item/reagent_containers/food/snacks/rogue/cheddar = 2,
		/obj/item/natural/cloth = 2,
		/obj/item/book/rogue/yeoldecookingmanual = 1,
		)
	H.change_stat("intelligence", 1)
	H.change_stat("constitution", 2) // Cheese diet. (M EDIT: ok sure)
	H.change_stat("endurance", 1)
