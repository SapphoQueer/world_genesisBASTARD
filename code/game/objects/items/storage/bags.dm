/*
 *	These absorb the functionality of the plant bag, ore satchel, etc
 *	They use the use_to_pickup, quick_gather, and quick_empty functions
 *	that were already defined in weapon/storage, but which had been
 *	re-implemented in other classes.
 *
 *	Contains:
 *		Trash Bag
 *		Mining Satchel
 *		Plant Bag
 *		Sheet Snatcher
 *		Book Bag
 *      Biowaste Bag
 *
 *	-Sayu
 */

//  Generic non-item
/obj/item/storage/bag
	slot_flags = ITEM_SLOT_BELT

/obj/item/storage/bag/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.allow_quick_gather = TRUE
	STR.allow_quick_empty = TRUE
	STR.display_numerical_stacking = TRUE
	STR.click_gather = TRUE

// -----------------------------
//          Trash bag
// -----------------------------
/obj/item/storage/bag/trash
	name = "trash bag"
	desc = "It's the heavy-duty black polymer kind. Time to take out the trash!"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "trashbag"
	item_state = "trashbag"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'

	w_class = WEIGHT_CLASS_BULKY
	var/insertable = TRUE

/obj/item/storage/bag/trash/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_combined_w_class = 30
	STR.max_items = 30
	STR.can_hold_extra = typecacheof(list(/obj/item/organ/lungs, /obj/item/organ/liver, /obj/item/organ/stomach, /obj/item/clothing/shoes)) - typesof(/obj/item/clothing/shoes/magboots, /obj/item/clothing/shoes/clown_shoes, /obj/item/clothing/shoes/jackboots, /obj/item/clothing/shoes/workboots)
	STR.cant_hold = typecacheof(list(/obj/item/disk/nuclear, /obj/item/storage/wallet, /obj/item/organ/brain))
	STR.limited_random_access = TRUE
	STR.limited_random_access_stack_position = 3

/obj/item/storage/bag/trash/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] puts [src] over [user.p_their()] head and starts chomping at the insides! Disgusting!</span>")
	playsound(loc, 'sound/items/eatfood.ogg', 50, 1, -1)
	return (TOXLOSS)

/obj/item/storage/bag/trash/update_icon_state()
	switch(contents.len)
		if(0)
			icon_state = "[initial(icon_state)]"
		if(1 to 11)
			icon_state = "[initial(icon_state)]1"
		if(11 to 20)
			icon_state = "[initial(icon_state)]2"
		else
			icon_state = "[initial(icon_state)]3"

/obj/item/storage/bag/trash/cyborg
	insertable = FALSE

/obj/item/storage/bag/trash/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	if(insertable)
		J.put_in_cart(src, user)
		J.mybag=src
		J.update_icon()
	else
		to_chat(user, "<span class='warning'>You are unable to fit your [name] into the [J.name].</span>")
		return

/obj/item/storage/bag/trash/bluespace
	name = "trash bag of holding"
	desc = "The latest and greatest in custodial convenience, a trashbag that is capable of holding vast quantities of garbage."
	icon_state = "bluetrashbag"
	item_state = "bluetrashbag"
	item_flags = NO_MAT_REDEMPTION
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/storage/bag/trash/bluespace/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 60
	STR.max_items = 60
	STR.limited_random_access_stack_position = 5

/obj/item/storage/bag/trash/bluespace/cyborg
	insertable = FALSE

// -----------------------------
//        Mining Satchel
// -----------------------------

/obj/item/storage/bag/ore
	name = "mining satchel"
	desc = "This little bugger can be used to store and transport ores."
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack
	var/spam_protection = FALSE //If this is TRUE, the holder won't receive any messages when they fail to pick up ore through crossing it
	var/mob/listeningTo
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	var/range = null

/obj/item/storage/bag/ore/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/rad_insulation, 0.01) //please datum mats no more cancer
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.can_hold = typecacheof(list(/obj/item/stack/ore))
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_combined_stack_amount = 50

/obj/item/storage/bag/ore/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(Pickup_ores))
	listeningTo = user

/obj/item/storage/bag/ore/dropped(mob/user)
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	listeningTo = null

/obj/item/storage/bag/ore/proc/Pickup_ores(mob/living/user)
	var/show_message = FALSE
	var/obj/structure/ore_box/box
	var/turf/tile = user.loc
	if (!isturf(tile))
		return
	if (istype(user.pulling, /obj/structure/ore_box))
		box = user.pulling
	if(issilicon(user))
		var/mob/living/silicon/robot/borgo = user
		for(var/obj/item/cyborg_clamp/C in borgo.module.modules)
			for(var/obj/structure/ore_box/B in C)
				box = B

	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/A in tile)
			if (!is_type_in_typecache(A, STR.can_hold))
				continue
			if (box)
				if(range)
					for(var/obj/item/stack/ore/ore in range(range, user))
						user.transferItemToLoc(ore, box)
				user.transferItemToLoc(A, box)
				show_message = TRUE
			else if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, "<span class='warning'>Your [name] is full and can't hold any more!</span>")
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		if (box)
			user.visible_message("<span class='notice'>[user] offloads the ores beneath [user.p_them()] into [box].</span>", \
			"<span class='notice'>You offload the ores beneath you into your [box].</span>")
		else
			user.visible_message("<span class='notice'>[user] scoops up the ores beneath [user.p_them()].</span>", \
				"<span class='notice'>You scoop up the ores beneath you with your [name].</span>")
	spam_protection = FALSE

/obj/item/storage/bag/ore/cyborg
	name = "cyborg mining satchel"
	range = 1

/obj/item/storage/bag/ore/cyborg/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.can_hold = typecacheof(list(/obj/item/stack/ore))
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_combined_stack_amount = 150

/obj/item/storage/bag/ore/large
	name = "large mining satchel"
	desc = "This bag can hold three times the ore in many small pockets. Shockingly foldable and compact for its volume."

/obj/item/storage/bag/ore/large/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.can_hold = typecacheof(list(/obj/item/stack/ore))
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_combined_stack_amount = 150

/obj/item/storage/bag/ore/holding //miners, your messiah has arrived
	name = "mining satchel of holding"
	desc = "A revolution in convenience, this satchel allows for huge amounts of ore storage. It's been outfitted with anti-malfunction safety measures."
	icon_state = "satchel_bspace"

/obj/item/storage/bag/ore/holding/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_items = INFINITY
	STR.max_combined_w_class = INFINITY
	STR.max_combined_stack_amount = INFINITY

// -----------------------------
//          Plant bag
// -----------------------------

/obj/item/storage/bag/plants
	name = "plant bag"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "plantbag"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/plants/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 100
	STR.max_items = 100
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/food/snacks/grown, /obj/item/seeds, /obj/item/grown, /obj/item/reagent_containers/honeycomb, /obj/item/disk/plantgene))

////////

/obj/item/storage/bag/plants/portaseeder
	name = "portable seed extractor"
	desc = "For the enterprising botanist on the go. Less efficient than the stationary model, it creates one seed per plant."
	icon_state = "portaseeder"

/obj/item/storage/bag/plants/portaseeder/verb/dissolve_contents()
	set name = "Activate Seed Extraction"
	set category = "Object"
	set desc = "Activate to convert your plants into plantable seeds."
	var/mob/living/L = usr
	if(istype(L) && !CHECK_MOBILITY(L, MOBILITY_USE))
		return
	for(var/obj/item/O in contents)
		seedify(O, 1)

// -----------------------------
//        Sheet Snatcher
// -----------------------------
// Because it stacks stacks, this doesn't operate normally.
// However, making it a storage/bag allows us to reuse existing code in some places. -Sayu

/obj/item/storage/bag/sheetsnatcher
	name = "sheet snatcher"
	desc = "A patented Genesis storage system designed for any kind of mineral sheet." //GS13 - Nanotrasen to Genesis
	icon = 'icons/obj/mining.dmi'
	icon_state = "sheetsnatcher"

	var/capacity = 300; //the number of sheets it can carry.
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack

/obj/item/storage/bag/sheetsnatcher/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.can_hold = typecacheof(list(/obj/item/stack/sheet))
	STR.cant_hold = typecacheof(list(/obj/item/stack/sheet/mineral/sandstone, /obj/item/stack/sheet/mineral/wood))
	STR.max_combined_stack_amount = 300

// -----------------------------
//    Sheet Snatcher (Cyborg)
// -----------------------------

/obj/item/storage/bag/sheetsnatcher/borg
	name = "sheet snatcher 9000"
	desc = ""
	capacity = 500//Borgs get more because >specialization

/obj/item/storage/bag/sheetsnatcher/borg/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_combined_stack_amount = 500

// -----------------------------
//           Book bag
// -----------------------------

/obj/item/storage/bag/books
	name = "book bag"
	desc = "A bag for books."
	icon = 'icons/obj/library.dmi'
	icon_state = "bookbag"
	w_class = WEIGHT_CLASS_BULKY //Bigger than a book because physics
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/books/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 21
	STR.max_items = 7
	STR.display_numerical_stacking = FALSE
	STR.can_hold = typecacheof(list(/obj/item/book, /obj/item/storage/book, /obj/item/spellbook))

/*
 * Trays - Agouri
 */
/obj/item/storage/bag/tray
	name = "serving tray"
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "tray"
	desc = "A metal tray to lay food on."
	force = 5
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_BULKY
	flags_1 = CONDUCT_1
	custom_materials = list(/datum/material/iron=3000)
	var/max_items = 7

/obj/item/storage/bag/tray/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/food, /obj/item/reagent_containers/glass, /datum/reagent/consumable, /obj/item/kitchen/knife, /obj/item/kitchen/rollingpin, /obj/item/kitchen/fork, /obj/item/storage/box)) //Should cover: Bottles, Beakers, Bowls, Booze, Glasses, Food, Kitchen Tools, and ingredient boxes.
	STR.insert_preposition = "on"
	STR.max_items = max_items

/obj/item/storage/bag/tray/attack(mob/living/M, mob/living/user)
	. = ..()
	// Drop all the things. All of them.
	var/list/obj/item/oldContents = contents.Copy()
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	// Make each item scatter a bit
	for(var/obj/item/I in oldContents)
		spawn()
			for(var/i = 1, i <= rand(1,2), i++)
				if(I)
					step(I, pick(NORTH,SOUTH,EAST,WEST))
					sleep(rand(2,4))

	if(prob(50))
		playsound(M, 'sound/items/trayhit1.ogg', 50, 1)
	else
		playsound(M, 'sound/items/trayhit2.ogg', 50, 1)

	if(ishuman(M) || ismonkey(M))
		if(prob(10))
			M.DefaultCombatKnockdown(40)
	update_icon()

/obj/item/storage/bag/tray/update_overlays()
	. = ..()
	for(var/obj/item/I in contents)
		var/mutable_appearance/I_copy = new(I)
		I_copy.plane = FLOAT_PLANE
		I_copy.layer = FLOAT_LAYER
		. += I_copy

/obj/item/storage/bag/tray/Entered()
	. = ..()
	update_icon()

/obj/item/storage/bag/tray/Exited()
	. = ..()
	update_icon()

/obj/item/storage/bag/tray/cafeteria
	name = "cafeteria tray"
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "foodtray"
	desc = "A cheap metal tray to pile today's meal onto."

//bluespace tray, holds more items
/obj/item/storage/bag/tray/bluespace
	name = "bluespace tray"
	icon_state = "bluespace_tray"
	desc = "A tray created using bluespace technology to fit more food on it."
	max_items = 100 //GS13 - we loooove our mountains of food here
	custom_materials = list(/datum/material/iron = 2000, /datum/material/bluespace = 500)

/*
 *	Chemistry bag
 */

/obj/item/storage/bag/chemistry
	name = "chemistry bag"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bag"
	desc = "A bag for storing pills, patches, and bottles."
	slot_flags = ITEM_SLOT_BELT|ITEM_SLOT_POCKETS
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/chemistry/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_volume = STORAGE_VOLUME_CHEMISTRY_BAG
	STR.insert_preposition = "in"
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/pill, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/syringe/dart, /obj/item/reagent_containers/chem_pack))

/*
 *  Biowaste bag (mostly for xenobiologists)
 */

/obj/item/storage/bag/bio
	name = "bio bag"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "biobag"
	desc = "A bag for the safe transportation and disposal of biowaste and other biological materials."
	slot_flags = ITEM_SLOT_BELT|ITEM_SLOT_POCKETS
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/bio/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL //Allows you to pick up Lungs, Liver, and Stomach
	STR.max_combined_w_class = 200
	STR.max_items = 25
	STR.insert_preposition = "in"
	STR.can_hold = typecacheof(list(/obj/item/slime_extract, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/blood, /obj/item/reagent_containers/hypospray/medipen, /obj/item/reagent_containers/food/snacks/deadmouse, /obj/item/reagent_containers/food/snacks/cube, /obj/item/organ, /obj/item/reagent_containers/food/snacks/meat/slab, /obj/item/bodypart))
	STR.cant_hold = typecacheof(list(/obj/item/organ/brain, /obj/item/organ/liver/cybernetic, /obj/item/organ/heart/cybernetic, /obj/item/organ/lungs/cybernetic, /obj/item/organ/tongue/cybernetic, /obj/item/organ/ears/cybernetic, /obj/item/organ/eyes/robotic, /obj/item/organ/cyberimp))

/obj/item/storage/bag/bio/holding
	name = "bio bag of holding"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bspace_biobag"
	desc = "A bag for the safe transportation and disposal of biowaste and other biological materials."
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/storage/bag/bio/holding/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = INFINITY
	STR.max_items = 100

/obj/item/storage/bag/ammo
	name = "ammo pouch"
	desc = "A pouch for your ammo that goes in your pocket."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "ammopouch"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_BULKY
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/ammo/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 30
	STR.max_items = 3
	STR.display_numerical_stacking = FALSE
	STR.can_hold = typecacheof(list(/obj/item/ammo_box/magazine, /obj/item/ammo_casing))

/*
Bag for holding materials
*/
/obj/item/storage/bag/material
	name = "material pouch"
	desc = "A pouch for sheets and RCD ammunition that manages to hang where you would normally put things in your pocket."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "materialpouch"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_BULKY
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/material/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = INFINITY
	STR.max_items = 2
	STR.display_numerical_stacking = TRUE
	STR.can_hold = typecacheof(list(/obj/item/rcd_ammo, /obj/item/stack/sheet))

/*
 *  Construction bag (for engineering, holds stock parts and electronics)
 */

/obj/item/storage/bag/construction
	name = "construction bag"
	icon = 'icons/obj/tools.dmi'
	icon_state = "construction_bag"
	desc = "A bag for storing small construction components."
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/construction/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 100
	STR.max_items = 50
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.insert_preposition = "in"
	STR.can_hold = typecacheof(list(/obj/item/stack/ore/bluespace_crystal, /obj/item/assembly, /obj/item/stock_parts, /obj/item/reagent_containers/glass/beaker, /obj/item/stack/cable_coil, /obj/item/circuitboard, /obj/item/electronics,/obj/item/wallframe/camera))
