/*****************************Survival Pod********************************/
/area/survivalpod
	name = "\improper Emergency Shelter"
	icon_state = "away"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	area_flags = BLOBS_ALLOWED | UNIQUE_AREA
	flags_1 = CAN_BE_DIRTY_1

/area/survivalpod/nonpowered
	name = "\proper Emergency Shelter"
	requires_power = TRUE

//Survival Capsule
/obj/item/survivalcapsule
	name = "bluespace shelter capsule"
	desc = "An emergency shelter stored within a pocket of bluespace."
	icon = 'icons/obj/mining.dmi'
	icon_state = "capsule"
	w_class = WEIGHT_CLASS_TINY
	var/template_id = "shelter_alpha"
	var/datum/map_template/shelter/template
	var/used = FALSE

/obj/item/survivalcapsule/proc/get_template()
	if(template)
		return
	template = SSmapping.shelter_templates[template_id]
	if(!template)
		stack_trace("Shelter template ([template_id]) not found!")
		qdel(src)

/obj/item/survivalcapsule/Destroy()
	template = null // without this, capsules would be one use. per round.
	. = ..()

/obj/item/survivalcapsule/examine(mob/user)
	. = ..()
	get_template()
	. += "This capsule has the [template.name] stored."
	. += template.description

/obj/item/survivalcapsule/attack_self()
	//Can't grab when capsule is New() because templates aren't loaded then
	get_template()
	if(!used)
		loc.visible_message("<span class='warning'>\The [src] begins to shake. Stand back!</span>")
		used = TRUE
		sleep(50)
		var/turf/deploy_location = get_turf(src)
		var/status = template.check_deploy(deploy_location)
		switch(status)
			if(SHELTER_DEPLOY_BAD_AREA)
				src.loc.visible_message("<span class='warning'>\The [src] will not function in this area.</span>")
			if(SHELTER_DEPLOY_BAD_TURFS, SHELTER_DEPLOY_ANCHORED_OBJECTS)
				var/width = template.width
				var/height = template.height
				src.loc.visible_message("<span class='warning'>\The [src] doesn't have room to deploy! You need to clear a [width]x[height] area!</span>")

		if(status != SHELTER_DEPLOY_ALLOWED)
			used = FALSE
			return

		playsound(src, 'sound/effects/phasein.ogg', 100, 1)

		var/turf/T = deploy_location
		if(!is_mining_level(T.z)) //only report capsules away from the mining/lavaland level
			message_admins("[ADMIN_LOOKUPFLW(usr)] activated a bluespace capsule away from the mining level! [ADMIN_VERBOSEJMP(T)]")
			log_admin("[key_name(usr)] activated a bluespace capsule away from the mining level at [AREACOORD(T)]")
		template.load(deploy_location, centered = TRUE)
		new /obj/effect/particle_effect/smoke(get_turf(src))
		qdel(src)

//Non-default pods

/obj/item/survivalcapsule/luxury
	name = "luxury bluespace shelter capsule"
	desc = "An exorbitantly expensive luxury suite stored within a pocket of bluespace."
	icon_state = "capsule-lux"
	template_id = "shelter_beta"

/obj/item/survivalcapsule/luxury/elitebar
	name = "luxury elite bar capsule"
	desc = "A luxury bar in a capsule. Bartender required and not included."
	template_id = "shelter_charlie"

/obj/item/survivalcapsule/luxury/empty
	name = "large empty capsule"
	desc = "An extremly large capsule which requires power. Useful for projects all over."
	template_id = "shelter_delta"

/obj/item/survivalcapsule/luxury/penthouse
	name = "penthouse bluespace shelter capsule"
	desc = "The absolute pinnacle of luxury in terms of survival capsules. While exuberantly expensive it has everything needed to survive in luxury."
	template_id = "shelter_epsilon"
/obj/item/survivalcapsule/luxury/garden
	name = "garden & kitchen bluespace shelter capsule"
	desc = "Everything someone needs to make a home cooked meal while surviving the depths of hell... or space."
	template_id = "shelter_zeta"

// RBMK reactor beacon so people can create the engine

/obj/item/survivalcapsule/reactor // the not-so-survival capsule
	name = "RMBK Reactor Beacon"
	desc = "A special bluespace beacon designed to implement a reactor into the hull of the ship or station that it is activated on."
	icon = 'icons/obj/device.dmi'
	icon_state = "beacon"
	template_id = "reactor"

//Pod objects

//Window
/obj/structure/window/shuttle/survival_pod
	name = "pod window"
	icon = 'icons/obj/smooth_structures/pod_window.dmi'
	icon_state = "smooth"
	smooth = SMOOTH_MORE
	canSmoothWith = list(/turf/closed/wall/mineral/titanium/survival, /obj/machinery/door/airlock/survival_pod, /obj/structure/window/shuttle/survival_pod)

/obj/structure/window/shuttle/survival_pod/spawner/north
	dir = NORTH

/obj/structure/window/shuttle/survival_pod/spawner/east
	dir = EAST

/obj/structure/window/shuttle/survival_pod/spawner/west
	dir = WEST

/obj/structure/window/reinforced/survival_pod
	name = "pod window"
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "pwindow"

//Door
/obj/machinery/door/airlock/survival_pod
	name = "airlock"
	icon = 'icons/obj/doors/airlocks/survival/survival.dmi'
	overlays_file = 'icons/obj/doors/airlocks/survival/survival_overlays.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_pod

/obj/machinery/door/airlock/survival_pod/glass
	opacity = FALSE
	glass = TRUE

/obj/structure/door_assembly/door_assembly_pod
	name = "pod airlock assembly"
	icon = 'icons/obj/doors/airlocks/survival/survival.dmi'
	base_name = "pod airlock"
	overlays_file = 'icons/obj/doors/airlocks/survival/survival_overlays.dmi'
	airlock_type = /obj/machinery/door/airlock/survival_pod
	glass_type = /obj/machinery/door/airlock/survival_pod/glass

//Windoor
/obj/machinery/door/window/survival_pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "windoor"
	base_state = "windoor"

//Table
/obj/structure/table/survival_pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "table"
	smooth = SMOOTH_FALSE

//Sleeper
/obj/machinery/sleeper/survival_pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "sleeper"

/obj/machinery/sleeper/survival_pod/update_icon_state()
	return

/obj/machinery/sleeper/survival_pod/update_overlays()
	. = ..()
	if(!state_open)
		. += "sleeper_cover"

//Lifeform Stasis Unit
/obj/machinery/stasis/survival_pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "sleeper"
	mattress_state = null
	buckle_lying = 270

/obj/machinery/stasis/survival_pod/play_power_sound()
	return

//NanoMed
/obj/machinery/vending/wallmed/survival_pod
	name = "survival pod medical supply"
	desc = "Wall-mounted Medical Equipment dispenser. This one seems just a tiny bit smaller."
	refill_canister = null
	onstation = FALSE

//Computer
/obj/item/gps/computer
	name = "pod computer"
	icon_state = "pod_computer"
	icon = 'icons/obj/lavaland/pod_computer.dmi'
	anchored = TRUE
	density = TRUE
	pixel_y = -32

/obj/item/gps/computer/wrench_act(mob/living/user, obj/item/I)
	if(flags_1 & NODECONSTRUCT_1)
		return TRUE

	user.visible_message("<span class='warning'>[user] disassembles [src].</span>",
		"<span class='notice'>You start to disassemble [src]...</span>", "You hear clanking and banging noises.")
	if(I.use_tool(src, user, 20, volume=50))
		new /obj/item/gps(loc)
		qdel(src)
	return TRUE

/obj/item/gps/computer/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	attack_self(user)

//Bed
/obj/structure/bed/pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "bed"

/obj/structure/bed/double/pod
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "bed_double"

//Survival Storage Unit
/obj/machinery/smartfridge/survival_pod
	name = "survival pod storage"
	desc = "A heated storage unit."
	icon_state = "donkvendor"
	icon = 'icons/obj/lavaland/donkvendor.dmi'
	light_range = 5
	light_power = 1.2
	light_color = "#DDFFD3"
	max_n_of_items = 10
	pixel_y = -4
	flags_1 = NODECONSTRUCT_1
	var/empty = FALSE

/obj/machinery/smartfridge/survival_pod/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_blocker)

/obj/machinery/smartfridge/survival_pod/Initialize(mapload)
	. = ..()
	if(empty)
		return
	for(var/i in 1 to 5)
		var/obj/item/reagent_containers/food/snacks/donkpocket/warm/W = new(src)
		load(W)
	if(prob(50))
		var/obj/item/storage/dice/D = new(src)
		load(D)
	else
		var/obj/item/instrument/guitar/G = new(src)
		load(G)

/obj/machinery/smartfridge/survival_pod/accept_check(obj/item/O)
	return isitem(O)

/obj/machinery/smartfridge/survival_pod/empty
	name = "dusty survival pod storage"
	desc = "A heated storage unit. This one's seen better days."
	empty = TRUE

//Fans
/obj/structure/fans
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	icon_state = "fans"
	name = "environmental regulation system"
	desc = "A large machine releasing a constant gust of air."
	anchored = TRUE
	density = TRUE
	var/buildstacktype = /obj/item/stack/sheet/metal
	var/buildstackamount = 5
	CanAtmosPass = ATMOS_PASS_NO

/obj/structure/fans/deconstruct()
	if(!(flags_1 & NODECONSTRUCT_1))
		if(buildstacktype)
			new buildstacktype(loc,buildstackamount)
	qdel(src)

/obj/structure/fans/wrench_act(mob/living/user, obj/item/I)
	if(flags_1 & NODECONSTRUCT_1)
		return TRUE

	user.visible_message("<span class='warning'>[user] disassembles [src].</span>",
		"<span class='notice'>You start to disassemble [src]...</span>", "You hear clanking and banging noises.")
	if(I.use_tool(src, user, 20, volume=50))
		deconstruct()
	return TRUE

/obj/structure/fans/tiny
	name = "tiny fan"
	desc = "A tiny fan, releasing a thin gust of air."
	layer = ABOVE_NORMAL_TURF_LAYER
	density = FALSE
	icon_state = "fan_tiny"
	buildstackamount = 2

/obj/structure/fans/Initialize(mapload)
	. = ..()
	air_update_turf(1)

//Inivisible, indestructible fans
/obj/structure/fans/tiny/invisible
	name = "air flow blocker"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	invisibility = INVISIBILITY_ABSTRACT

//Signs
/obj/structure/sign/mining
	name = "nanotrasen mining corps sign"
	desc = "A sign of relief for weary miners, and a warning for would-be competitors to Genesis's mining claims." //GS13 - Nanotrasen to Genesis
	icon = 'icons/turf/walls/survival_pod_walls.dmi'
	icon_state = "ntpod"
	buildable_sign = FALSE

/obj/structure/sign/mining/survival
	name = "shelter sign"
	desc = "A high visibility sign designating a safe shelter."
	icon = 'icons/turf/walls/survival_pod_walls.dmi'
	icon_state = "survival"

//Fluff
/obj/structure/tubes
	icon_state = "tubes"
	icon = 'icons/obj/lavaland/survival_pod.dmi'
	name = "tubes"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	density = FALSE

/obj/item/fakeartefact
	name = "expensive forgery"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x2"
	var/possible = list(/obj/item/ship_in_a_bottle,
						/obj/item/gun/energy/pulse,
						/obj/item/book/granter/martial/carp,
						/obj/item/melee/supermatter_sword,
						/obj/item/shield/changeling,
						/obj/item/lava_staff,
						/obj/item/energy_katana,
						/obj/item/hierophant_club,
						/obj/item/his_grace,
						/obj/item/gun/energy/minigun,
						/obj/item/gun/ballistic/automatic/l6_saw,
						/obj/item/gun/magic/staff/chaos,
						/obj/item/gun/magic/staff/spellblade,
						/obj/item/gun/magic/wand/death,
						/obj/item/gun/magic/wand/fireball,
						/obj/item/stack/telecrystal/twenty,
						/obj/item/nuke_core,
						/obj/item/phylactery,
						/obj/item/banhammer)

/obj/item/fakeartefact/Initialize(mapload)
	. = ..()
	var/obj/item/I = pick(possible)
	name = initial(I.name)
	icon = initial(I.icon)
	desc = initial(I.desc)
	icon_state = initial(I.icon_state)
	item_state = initial(I.item_state)
