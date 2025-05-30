/obj/item/gun/energy/e_gun
	name = "energy gun"
	desc = "A basic hybrid energy gun with two settings: disable and kill."
	icon_state = "energy"
	item_state = null	//so the human update icon uses the icon_state instead.
	ammo_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser)
	modifystate = 1
	can_flashlight = 1
	ammo_x_offset = 3
	flight_x_offset = 15
	flight_y_offset = 10

/obj/item/gun/energy/e_gun/mini
	name = "miniature energy gun"
	desc = "A small, pistol-sized energy gun with a built-in flashlight. It has two settings: stun and kill."
	icon_state = "mini"
	item_state = "gun"
	w_class = WEIGHT_CLASS_SMALL
	cell_type = /obj/item/stock_parts/cell{charge = 600; maxcharge = 600}
	ammo_x_offset = 2
	charge_sections = 3
	gunlight_state = "mini-light"
	can_flashlight = 0 // Can't attach or detach the flashlight, and override it's icon update
	shot_type_overlay = FALSE

/obj/item/gun/energy/e_gun/mini/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()

/obj/item/gun/energy/e_gun/stun
	name = "tactical energy gun"
	desc = "Military issue energy gun, is able to fire stun rounds."
	icon_state = "energytac"
	ammo_x_offset = 2
	ammo_type = list(/obj/item/ammo_casing/energy/electrode/spec, /obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser)

/obj/item/gun/energy/e_gun/old
	name = "prototype energy gun"
	desc = "GT-P:01 Prototype Energy Gun. Early stage development of a unique laser rifle that has multifaceted energy lens allowing the gun to alter the form of projectile it fires on command." //GS13 - NT to GT
	icon_state = "protolaser"
	ammo_x_offset = 2
	ammo_type = list(/obj/item/ammo_casing/energy/laser, /obj/item/ammo_casing/energy/electrode/old)

/obj/item/gun/energy/e_gun/mini/practice_phaser
	name = "practice phaser"
	desc = "A modified version of the basic phaser gun, this one fires less concentrated energy bolts designed for target practice."
	ammo_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser/practice)
	icon_state = "decloner"
	//You have no icons for energy types, you're a decloner
	modifystate = FALSE

/obj/item/gun/energy/e_gun/hos
	name = "\improper X-01 MultiPhase Energy Gun"
	desc = "This is an expensive, modern recreation of an antique laser gun. This gun has several unique firemodes, but lacks the ability to recharge over time in exchange for inbuilt advanced firearm EMP shielding. <span class='boldnotice'>Right click in combat mode to fire a taser shot with a cooldown.</span>"
	icon_state = "hoslaser"
	force = 10
	ammo_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser/hos, /obj/item/ammo_casing/energy/ion/hos, /obj/item/ammo_casing/energy/electrode/hos)
	ammo_x_offset = 4
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/last_altfire = 0
	var/altfire_delay = 0

/obj/item/gun/energy/e_gun/hos/altafterattack(atom/target, mob/user, proximity_flag, params)
	. = TRUE
	if(last_altfire + altfire_delay > world.time)
		return
	var/current_index = current_firemode_index
	set_firemode_to_type(/obj/item/ammo_casing/energy/electrode)
	process_afterattack(target, user, proximity_flag, params)
	set_firemode_index(current_index)
	last_altfire = world.time

/obj/item/gun/energy/e_gun/hos/emp_act(severity)
	return

/obj/item/gun/energy/e_gun/dragnet
	name = "\improper DRAGnet"
	desc = "The \"Dynamic Rapid-Apprehension of the Guilty\" net is a revolution in law enforcement technology."
	icon_state = "dragnet"
	item_state = "dragnet"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/net, /obj/item/ammo_casing/energy/trap)
	modifystate = FALSE
	can_flashlight = 0
	ammo_x_offset = 1

/obj/item/gun/energy/e_gun/dragnet/snare
	name = "Energy Snare Launcher"
	desc = "Fires an energy snare that slows the target down."
	ammo_type = list(/obj/item/ammo_casing/energy/trap)

/obj/item/gun/energy/e_gun/turret
	name = "hybrid turret gun"
	desc = "A heavy hybrid energy cannon with two settings: Stun and kill."
	icon_state = "turretlaser"
	item_state = "turretlaser"
	slot_flags = null
	w_class = WEIGHT_CLASS_HUGE
	ammo_type = list(/obj/item/ammo_casing/energy/electrode, /obj/item/ammo_casing/energy/laser)
	weapon_weight = WEAPON_HEAVY
	can_flashlight = 0
	trigger_guard = TRIGGER_GUARD_NONE
	ammo_x_offset = 2

/obj/item/gun/energy/e_gun/nuclear
	name = "advanced energy gun"
	desc = "An energy gun with an experimental miniaturized nuclear reactor that automatically charges the internal power cell."
	icon_state = "nucgun"
	item_state = "nucgun"
	charge_delay = 5
	pin = null
	can_charge = 0
	ammo_x_offset = 1
	ammo_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser)
	selfcharge = EGUN_SELFCHARGE
	var/fail_tick = 0
	var/fail_chance = 0

/obj/item/gun/energy/e_gun/nuclear/process()
	if(fail_tick > 0)
		fail_tick--
	..()

/obj/item/gun/energy/e_gun/nuclear/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	failcheck()
	update_icon()
	..()

/obj/item/gun/energy/e_gun/nuclear/proc/failcheck()
	if(prob(fail_chance))
		switch(fail_tick)
			if(0 to 200)
				fail_tick += (2*(fail_chance))
				radiation_pulse(src, 50)
				var/mob/M = (ismob(loc) && loc) || (ismob(loc.loc) && loc.loc)		//thank you short circuiting. if you powergame and nest these guns deeply you get to suffer no-warning radiation death.
				if(M)
					to_chat(M, "<span class='userdanger'>Your [name] feels warmer.</span>")
			if(201 to INFINITY)
				SSobj.processing.Remove(src)
				radiation_pulse(src, 200)
				crit_fail = TRUE
				var/mob/M = (ismob(loc) && loc) || (ismob(loc.loc) && loc.loc)
				if(M)
					to_chat(M, "<span class='userdanger'>Your [name]'s reactor overloads!</span>")

/obj/item/gun/energy/e_gun/nuclear/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	fail_chance = min(fail_chance + round(severity/6.6), 100)

/obj/item/gun/energy/e_gun/nuclear/update_overlays()
	. = ..()
	if(crit_fail)
		. += "[icon_state]_fail_3"
	else
		switch(fail_tick)
			if(0)
				. += "[icon_state]_fail_0"
			if(1 to 150)
				. += "[icon_state]_fail_1"
			if(151 to INFINITY)
				. += "[icon_state]_fail_2"
