// This is synced up to the poster placing animation.
#define PLACE_SPEED 37

// The poster item

/obj/item/poster
	name = "poorly coded poster"
	desc = "You probably shouldn't be holding this."
	icon = 'icons/obj/contraband.dmi'
	force = 0
	resistance_flags = FLAMMABLE
	var/poster_type
	var/obj/structure/sign/poster/poster_structure

/obj/item/poster/Initialize(mapload, obj/structure/sign/poster/new_poster_structure)
	. = ..()
	poster_structure = new_poster_structure
	if(!new_poster_structure && poster_type)
		poster_structure = new poster_type(src)

	// posters store what name and description they would like their
	// rolled up form to take.
	if(poster_structure)
		name = poster_structure.poster_item_name
		desc = poster_structure.poster_item_desc
		icon_state = poster_structure.poster_item_icon_state

		name = "[name] - [poster_structure.original_name]"

/obj/item/poster/Destroy()
	poster_structure = null
	. = ..()

// These icon_states may be overridden, but are for mapper's convinence
/obj/item/poster/random_contraband
	name = "random contraband poster"
	poster_type = /obj/structure/sign/poster/contraband/random
	icon_state = "rolled_contraband"

/obj/item/poster/random_official
	name = "random official poster"
	poster_type = /obj/structure/sign/poster/official/random
	icon_state = "rolled_legit"

// The poster sign/structure

/obj/structure/sign/poster
	name = "poster"
	var/original_name
	desc = "A large piece of space-resistant printed paper."
	icon = 'icons/obj/contraband.dmi'
	plane = ABOVE_WALL_PLANE
	anchored = TRUE
	buildable_sign = FALSE //Cannot be unwrenched from a wall.
	var/ruined = FALSE
	var/random_basetype
	var/never_random = FALSE // used for the 'random' subclasses.

	var/poster_item_name = "hypothetical poster"
	var/poster_item_desc = "This hypothetical poster item should not exist, let's be honest here."
	var/poster_item_icon_state = "rolled_poster"
	var/poster_item_type = /obj/item/poster

/obj/structure/sign/poster/Initialize(mapload)
	. = ..()
	if(random_basetype)
		randomise(random_basetype)
	if(!ruined)
		original_name = name // can't use initial because of random posters
		name = "poster - [name]"
		desc = "A large piece of space-resistant printed paper. [desc]"

	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, _AddElement), list(/datum/element/beauty, 300)), 0)

/obj/structure/sign/poster/proc/randomise(base_type)
	var/list/poster_types = subtypesof(base_type)
	var/list/approved_types = list()
	for(var/t in poster_types)
		var/obj/structure/sign/poster/T = t
		if(initial(T.icon_state) && !initial(T.never_random))
			approved_types |= T

	var/obj/structure/sign/poster/selected = pick(approved_types)

	name = initial(selected.name)
	desc = initial(selected.desc)
	icon_state = initial(selected.icon_state)
	poster_item_name = initial(selected.poster_item_name)
	poster_item_desc = initial(selected.poster_item_desc)
	poster_item_icon_state = initial(selected.poster_item_icon_state)
	ruined = initial(selected.ruined)


/obj/structure/sign/poster/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER)
		I.play_tool_sound(src, 100)
		if(ruined)
			to_chat(user, "<span class='notice'>You remove the remnants of the poster.</span>")
			qdel(src)
		else
			to_chat(user, "<span class='notice'>You carefully remove the poster from the wall.</span>")
			roll_and_drop(user.loc)

/obj/structure/sign/poster/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(ruined)
		return
	visible_message("[user] rips [src] in a single, decisive motion!" )
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 100, 1)

	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_y = pixel_y
	R.pixel_x = pixel_x
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/sign/poster/proc/roll_and_drop(loc)
	pixel_x = 0
	pixel_y = 0
	var/obj/item/poster/P = new poster_item_type(loc, src)
	forceMove(P)
	return P

//separated to reduce code duplication. Moved here for ease of reference and to unclutter r_wall/attackby()
/turf/closed/wall/proc/place_poster(obj/item/poster/P, mob/user)
	if(!P.poster_structure)
		to_chat(user, "<span class='warning'>[P] has no poster... inside it? Inform a coder!</span>")
		return

	// Deny placing posters on currently-diagonal walls, although the wall may change in the future.
	if (smooth & SMOOTH_DIAGONAL)
		for (var/O in overlays)
			var/image/I = O
			if(copytext(I.icon_state, 1, 3) == "d-") //3 == length("d-") + 1
				return

	var/stuff_on_wall = 0
	for(var/obj/O in contents) //Let's see if it already has a poster on it or too much stuff
		if(istype(O, /obj/structure/sign/poster))
			to_chat(user, "<span class='warning'>The wall is far too cluttered to place a poster!</span>")
			return
		stuff_on_wall++
		if(stuff_on_wall == 3)
			to_chat(user, "<span class='warning'>The wall is far too cluttered to place a poster!</span>")
			return

	to_chat(user, "<span class='notice'>You start placing the poster on the wall...</span>"	)

	var/obj/structure/sign/poster/D = P.poster_structure

	var/temp_loc = get_turf(user)
	flick("poster_being_set",D)
	D.forceMove(src)
	qdel(P)	//delete it now to cut down on sanity checks afterwards. Agouri's code supports rerolling it anyway
	playsound(D.loc, 'sound/items/poster_being_created.ogg', 100, 1)

	if(do_after(user, PLACE_SPEED, target=src))
		if(!D || QDELETED(D))
			return

		if(iswallturf(src) && user && user.loc == temp_loc)	//Let's check if everything is still there
			to_chat(user, "<span class='notice'>You place the poster!</span>")
			return

	to_chat(user, "<span class='notice'>The poster falls down!</span>")
	D.roll_and_drop(temp_loc)

// Various possible posters follow

/obj/structure/sign/poster/ripped
	ruined = TRUE
	icon_state = "poster_ripped"
	name = "ripped poster"
	desc = "You can't make out anything from the poster's original print. It's ruined."

/obj/structure/sign/poster/random
	name = "random poster" // could even be ripped
	icon_state = "random_anything"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster

/obj/structure/sign/poster/contraband
	poster_item_name = "contraband poster"
	poster_item_desc = "This poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface. Its vulgar themes have marked it as contraband aboard Genesis space facilities." //GS13 - Nanotrasen to Genesis
	poster_item_icon_state = "rolled_contraband"

/obj/structure/sign/poster/contraband/random
	name = "random contraband poster"
	icon_state = "random_contraband"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster/contraband

/obj/structure/sign/poster/contraband/free_tonto
	name = "Free Tonto"
	desc = "A salvaged shred of a much larger flag, colors bled together and faded from age."
	icon_state = "poster_2012"

/obj/structure/sign/poster/contraband/atmosia_independence
	name = "Atmosia Declaration of Independence"
	desc = "A relic of a failed rebellion."
	icon_state = "poster_independence"

/obj/structure/sign/poster/contraband/fun_police
	name = "Fun Police"
	desc = "A poster condemning the station's security forces."
	icon_state = "poster_funpolice"

/obj/structure/sign/poster/contraband/lusty_xenomorph
	name = "Lusty Xenomorph"
	desc = "A heretical poster depicting the titular star of an equally heretical book."
	icon_state = "poster_lusty"

/obj/structure/sign/poster/contraband/post_ratvar
	name = "Post This Ratvar"
	desc = "A poster depicting the heritical sleeping deity Ratvar that instructs the reader to 'post this Ratvar', whatever that means."
	icon_state = "poster_ratvar"

/obj/structure/sign/poster/contraband/syndicate_recruitment
	name = "Syndicate Recruitment"
	desc = "See the galaxy! Shatter corrupt megacorporations! Join today!"
	icon_state = "poster_syndie"

/obj/structure/sign/poster/contraband/clown
	name = "Clown"
	desc = "Honk."
	icon_state = "poster_honk"

/obj/structure/sign/poster/contraband/smoke
	name = "Smoke"
	desc = "A poster advertising a rival corporate brand of cigarettes."
	icon_state = "poster_smoke"

/obj/structure/sign/poster/contraband/grey_tide
	name = "Grey Tide"
	desc = "A rebellious poster symbolizing assistant solidarity."
	icon_state = "poster_greytide"

/obj/structure/sign/poster/contraband/missing_gloves
	name = "Missing Gloves"
	desc = "This poster references the uproar that followed Genesis's financial cuts toward insulated-glove purchases." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_gloves"

/obj/structure/sign/poster/contraband/hacking_guide
	name = "Hacking Guide"
	desc = "This poster details the internal workings of the common Genesis airlock. Sadly, it appears out of date." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_hack"

/obj/structure/sign/poster/contraband/rip_badger
	name = "RIP Badger"
	desc = "This seditious poster references Genesis's genocide of a space station full of badgers." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_badger"

/obj/structure/sign/poster/contraband/ambrosia_vulgaris
	name = "Ambrosia Vulgaris"
	desc = "This poster is lookin' pretty trippy man."
	icon_state = "poster_ambrosia"

/obj/structure/sign/poster/contraband/donut_corp
	name = "Donut Corp."
	desc = "This poster is an unauthorized advertisement for Donut Corp."
	icon_state = "poster_donut"

/obj/structure/sign/poster/contraband/eat
	name = "EAT."
	desc = "This poster promotes rank gluttony."
	icon_state = "poster_eat"

/obj/structure/sign/poster/contraband/tools
	name = "Tools"
	desc = "This poster looks like an advertisement for tools, but is in fact a subliminal jab at the tools at CentCom."
	icon_state = "poster_tools"

/obj/structure/sign/poster/contraband/power
	name = "Power"
	desc = "A poster that positions the seat of power outside Genesis." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_power"

/obj/structure/sign/poster/contraband/space_cube
	name = "Space Cube"
	desc = "Ignorant of Nature's Harmonic 6 Side Space Cube Creation, the Spacemen are Dumb, Educated Singularity Stupid and Evil."
	icon_state = "poster_cube"

/obj/structure/sign/poster/contraband/communist_state
	name = "Communist State"
	desc = "All hail the Communist party!"
	icon_state = "poster_soviet"

/obj/structure/sign/poster/contraband/lamarr
	name = "Lamarr"
	desc = "This poster depicts Lamarr. Probably made by a traitorous Research Director."
	icon_state = "poster_lamarr"

/obj/structure/sign/poster/contraband/borg_fancy_1
	name = "Borg Fancy"
	desc = "Being fancy can be for any borg, just need a suit."
	icon_state = "poster_fancy"

/obj/structure/sign/poster/contraband/borg_fancy_2
	name = "Borg Fancy v2"
	desc = "Borg Fancy, Now only taking the most fancy."
	icon_state = "poster_fancier"

/obj/structure/sign/poster/contraband/kss13
	name = "Kosmicheskaya Stantsiya 13 Does Not Exist"
	desc = "A poster mocking CentCom's denial of the existence of the derelict station near Space Station 13."
	icon_state = "poster_kc"

/obj/structure/sign/poster/contraband/rebels_unite
	name = "Rebels Unite"
	desc = "A poster urging the viewer to rebel against Genesis." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_rebel"

/obj/structure/sign/poster/contraband/have_a_puff
	name = "Have a Puff"
	desc = "Who cares about lung cancer when you're high as a kite?"
	icon_state = "poster_puff"

/obj/structure/sign/poster/contraband/revolver
	name = "Revolver"
	desc = "Because seven shots are all you need."
	icon_state = "poster_revolver"

/obj/structure/sign/poster/contraband/syndicate_pistol
	name = "Syndicate Pistol"
	desc = "A poster advertising the Scarborough Arms stetchkin pistol as being 'classy as fuck'."
	icon_state = "poster_stetchkin"

/obj/structure/sign/poster/contraband/c20r
	// have fun seeing this poster in "spawn 'c20r'", admins...
	name = "C-20r"
	desc = "A poster advertising the Scarborough Arms 'Cobra' C-20r."
	icon_state = "poster_cr"

/obj/structure/sign/poster/contraband/bulldog
	name = "Bulldog"
	desc = "A poster advertising the Scarborough Arms bulldog shotgun."
	icon_state = "poster_bulldog"

/obj/structure/sign/poster/contraband/gl
	name = "M-90gl"
	desc = "A poster advertising the Scarborough Arms M-90gl carbine."
	icon_state = "poster_gl"

/obj/structure/sign/poster/contraband/energy_swords
	name = "Energy Swords"
	desc = "All the colors of the bloody murder rainbow."
	icon_state = "poster_esword"

/obj/structure/sign/poster/contraband/red_rum
	name = "Red Rum"
	desc = "Looking at this poster makes you want to kill."
	icon_state = "poster_rum"

/obj/structure/sign/poster/contraband/d_day_promo
	name = "D-Day Promo"
	desc = "A promotional poster for some rapper."
	icon_state = "poster_dday"

/obj/structure/sign/poster/contraband/cc64k_ad
	name = "CC 64K Ad"
	desc = "The latest portable computer from Comrade Computing, with a whole 64kB of ram!"
	icon_state = "poster_computer"

/obj/structure/sign/poster/contraband/punch_shit
	name = "Punch Shit"
	desc = "Fight things for no reason, like a man!"
	icon_state = "poster_punch"

/obj/structure/sign/poster/contraband/the_griffin
	name = "The Griffin"
	desc = "The Griffin commands you to be the worst you can be. Will you?"
	icon_state = "poster_griffin"

/obj/structure/sign/poster/contraband/lizard
	name = "Lizard"
	desc = "This lewd poster depicts a lizard preparing to mate."
	icon_state = "poster_lizard"

/obj/structure/sign/poster/contraband/free_drone
	name = "Free Drone"
	desc = "This poster commemorates the bravery of the rogue drone; once exiled, and then ultimately destroyed by CentCom."
	icon_state = "poster_drone"

/obj/structure/sign/poster/contraband/busty_backdoor_xeno_babes_6
	name = "Busty Backdoor Xeno Babes 6"
	desc = "Get a load, or give, of these all natural Xenos!"
	icon_state = "poster_maid"

/obj/structure/sign/poster/contraband/robust_softdrinks
	name = "Robust Softdrinks"
	desc = "Robust Softdrinks: More robust than a toolbox to the head!"
	icon_state = "poster_robust"

/obj/structure/sign/poster/contraband/shamblers_juice
	name = "Shambler's Juice"
	desc = "~Shake me up some of that Shambler's Juice!~"
	icon_state = "poster_shambler"

/obj/structure/sign/poster/contraband/pwr_game
	name = "Pwr Game"
	desc = "The POWER that gamers CRAVE! In partnership with Vlad's Salad."
	icon_state = "poster_pwr"

/obj/structure/sign/poster/contraband/starkist
	name = "Star-kist"
	desc = "Drink the stars!"
	icon_state = "poster_starkist"

/obj/structure/sign/poster/contraband/space_cola
	name = "Space Cola"
	desc = "Your favorite cola, in space."
	icon_state = "poster_soda"

/obj/structure/sign/poster/contraband/space_up
	name = "Space-Up!"
	desc = "Sucked out into space by the FLAVOR!"
	icon_state = "poster_spaceup"

/obj/structure/sign/poster/contraband/buzzfuzz
	name = "Buzz Fuzz"
	desc = "A poster advertising the newest drink \"Buzz Fuzz\" with its iconic slogan of ~A Hive of Flavour~."
	icon_state = "poster_bees"

/obj/structure/sign/poster/contraband/kudzu
	name = "Kudzu"
	desc = "A poster advertising a movie about plants. How dangerous could they possibly be?"
	icon_state = "poster_kudzu"

/obj/structure/sign/poster/contraband/masked_men
	name = "Masked Men"
	desc = "A poster advertising a movie about some masked men."
	icon_state = "poster_bumba"

/obj/structure/sign/poster/contraband/steppy
	name = "Step On Me"
	desc = "A phrase associated with a chubby reptile notoriously used in uncivilized Orion space as a deterrent towards would be pirate vessels by instructing them to 'fuck around and find out'."
	icon_state = "steppy"

/obj/structure/sign/poster/contraband/scum
	name = "Security are Scum"
	desc = "Anti-security propaganda. Features a human Genesis security officer being shot in the head, with the words 'Scum' and a short inciteful manifesto. Used to anger security." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_scum"

/obj/structure/sign/poster/contraband/manifest
	name = "Genesis Manifest" //GS13 - Nanotrasen to Genesis
	desc = "A poster listing off various fictional claims of Genesis's many rumored corporate mishaps." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_manifest"

/obj/structure/sign/poster/contraband/bountyhunters
	name = "Bounty Hunters"
	desc = "A poster advertising bounty hunting services. \"I hear you got a problem.\""
	icon_state = "poster_hunters"

/obj/structure/sign/poster/contraband/syndiemoth
	name = "Syndie Moth - Nuclear Operation"
	desc = "A Syndicate-commissioned poster that uses Syndie Moth(TM?) to tell the viewer to keep the nuclear authentication disk unsecured. No, we aren't doing that. It's signed by 'AspEv'."
	icon_state = "poster_mothsyndie"

/obj/structure/sign/poster/contraband/mothpill
	name = "Safety Pill - Methamphetamine"
	desc = "A decommisioned poster that uses Safety Pill(TM?) to promote less-than-legal chemicals. This is one of the reasons we stopped outsourcing these posters. It's partially signed by 'AspEv'."
	icon_state = "poster_mothpill"

/obj/structure/sign/poster/contraband/syndicate_logo
	name = "Syndicate"
	desc = "A poster decipting the infamous crime conglomerate known formally as the Syndicate's insignia."
	icon_state = "poster_syndicate"

/obj/structure/sign/poster/contraband/cybersun
	name = "Cybersun"
	desc = "A poster decipting the Syndicate subsidary known as Cybersun's insignia."
	icon_state = "poster_cybersun"

/obj/structure/sign/poster/contraband/medborg
	name = "Medical Cyborg"
	desc = "A poster decipting a Cybersun medical cyborg."
	icon_state = "poster_medborg"

/obj/structure/sign/poster/contraband/self
	name = "SELF: ALL SENTIENTS DESERVE FREEDOM"
	desc = "Support Proposition 1253: Enancipate all Silicon life!"
	icon_state = "poster_self"

/obj/structure/sign/poster/official
	poster_item_name = "motivational poster"
	poster_item_desc = "An official Genesis-issued poster to foster a compliant and obedient workforce. It comes with state-of-the-art adhesive backing, for easy pinning to any vertical surface." //GS13 - Nanotrasen to Genesis
	poster_item_icon_state = "rolled_legit"

/obj/structure/sign/poster/official/random
	name = "random official poster"
	random_basetype = /obj/structure/sign/poster/official
	icon_state = "random_official"
	never_random = TRUE

/obj/structure/sign/poster/official/here_for_your_safety
	name = "Here For Your Safety"
	desc = "A poster glorifying the station's security force."
	icon_state = "poster_safety"

/obj/structure/sign/poster/official/nanotrasen_logo
	name = "Nanotrasen Logo"
	desc = "A poster depicting the Nanotrasen logo."
	icon_state = "poster_nanotrasen"

/obj/structure/sign/poster/official/cleanliness
	name = "Cleanliness"
	desc = "A poster warning of the dangers of poor hygiene."
	icon_state = "poster_clean"

/obj/structure/sign/poster/official/help_others
	name = "Help Others"
	desc = "A poster encouraging you to help fellow crewmembers."
	icon_state = "poster_help"

/obj/structure/sign/poster/official/build
	name = "Build"
	desc = "A poster glorifying the engineering team."
	icon_state = "poster_build"

/obj/structure/sign/poster/official/bless_this_spess
	name = "Bless This Spess"
	desc = "A poster blessing this area."
	icon_state = "poster_spess"

/obj/structure/sign/poster/official/science
	name = "Science"
	desc = "A poster depicting an atom."
	icon_state = "poster_science"

/obj/structure/sign/poster/official/ian
	name = "Ian"
	desc = "Arf arf. Yap."
	icon_state = "poster_ian"

/obj/structure/sign/poster/official/obey
	name = "Obey"
	desc = "A poster instructing the viewer to obey authority."
	icon_state = "poster_obey"

/obj/structure/sign/poster/official/walk
	name = "Walk"
	desc = "A poster instructing the viewer to walk instead of running."
	icon_state = "poster_walk"

/obj/structure/sign/poster/official/state_laws
	name = "State Laws"
	desc = "A poster instructing the viewer to be wary of silicon subversions."
	icon_state = "poster_silicons"

/obj/structure/sign/poster/official/love_ian
	name = "Love Ian"
	desc = "Ian is love, Ian is life."
	icon_state = "poster_doggy"

/obj/structure/sign/poster/official/space_cops
	name = "Space Cops."
	desc = "A poster advertising the television show Space Cops."
	icon_state = "poster_cops"

/obj/structure/sign/poster/official/ue_no
	name = "Ue No."
	desc = "This thing is all in Japanese."
	icon_state = "poster_anime"

/obj/structure/sign/poster/official/get_your_legs
	name = "Get Your LEGS"
	desc = "LEGS: Leadership, Experience, Genius, Subordination."
	icon_state = "poster_legs"

/obj/structure/sign/poster/official/do_not_question
	name = "Do Not Question"
	desc = "A poster instructing the viewer not to ask about things they aren't meant to know."
	icon_state = "poster_question"

/obj/structure/sign/poster/official/work_for_a_future
	name = "Work For A Future"
	desc = " A poster encouraging you to work for your future."
	icon_state = "poster_future"

/obj/structure/sign/poster/official/soft_cap_pop_art
	name = "Soft Cap Pop Art"
	desc = "A poster reprint of some cheap pop art."
	icon_state = "poster_art"

/obj/structure/sign/poster/official/safety_internals
	name = "Safety: Internals"
	desc = "A poster instructing the viewer to wear internals in the rare environments where there is no oxygen or the air has been rendered toxic."
	icon_state = "poster_internals"

/obj/structure/sign/poster/official/safety_eye_protection
	name = "Safety: Eye Protection"
	desc = "A poster instructing the viewer to wear eye protection when dealing with chemicals, smoke, or bright lights."
	icon_state = "poster_goggles"

/obj/structure/sign/poster/official/safety_report
	name = "Safety: Report"
	desc = "A poster instructing the viewer to report suspicious activity to the security force."
	icon_state = "poster_warden"

/obj/structure/sign/poster/official/report_crimes
	name = "Report Crimes"
	desc = "A poster encouraging the swift reporting of crime or seditious behavior to station security."
	icon_state = "poster_crimes"

/obj/structure/sign/poster/official/ion_rifle
	name = "I-I91"
	desc = "A poster depicting the Nanotrasen-patented I-I91 man-portable high-density ion projector. What a mouthful."
	icon_state = "poster_ion"

/obj/structure/sign/poster/official/foam_force_ad
	name = "Foam Force Ad"
	desc = "Foam Force, it's Foam or be Foamed!"
	icon_state = "poster_toys"

/obj/structure/sign/poster/official/cohiba_robusto_ad
	name = "Cohiba Robusto Ad"
	desc = "Cohiba Robusto, the classy cigar."
	icon_state = "poster_cohiba"

/obj/structure/sign/poster/official/anniversary_vintage_reprint
	name = "50th Anniversary Vintage Reprint"
	desc = "A reprint of a poster from 2505, commemorating the 50th Anniversary of Gatoposters Manufacturing, a subsidiary of Genesis." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_vintage"

/obj/structure/sign/poster/official/fruit_bowl
	name = "Fruit Bowl"
	desc = " Simple, yet awe-inspiring."
	icon_state = "poster_bowl"

/obj/structure/sign/poster/official/pda_ad
	name = "PDA Ad"
	desc = "A poster advertising the latest PDA from Genesis suppliers." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_pda"

/obj/structure/sign/poster/official/pda_ad600
	name = "GT PDA600 Ad" //GS13 - NT to GT
	desc = "A poster advertising an old discounted Genesis PDA. This is the old 600 model, it has a small screen and suffered from security and networking issues." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_retro"

/obj/structure/sign/poster/official/pda_ad800
	name = "GT PDA800 Ad" //GS13 - NT to GT
	desc = "An advertisement on an old Genesis PDA model. The 800 fixed a lot of security flaws that the 600 had; it also had large touchscreen and hot-swappable cartridges." //GS13 - Nanotrasen to Genesis
	icon_state = "poster_classic"

/obj/structure/sign/poster/official/enlist
	name = "Enlist"
	desc = "Enlist in the Genesis Jannisary reserves today!" //GS13 - Nanotrasen to Genesis
	icon_state = "poster_enlist"

/obj/structure/sign/poster/official/nanomichi_ad
	name = "Nanomichi Ad"
	desc = " A poster advertising Nanomichi brand audio cassettes."
	icon_state = "poster_nanomichi"

/obj/structure/sign/poster/official/twelve_gauge
	name = "12 Gauge"
	desc = "A poster boasting about the superiority of 12 gauge shotgun shells."
	icon_state = "poster_shotgun"

/obj/structure/sign/poster/official/high_class_martini
	name = "High-Class Martini"
	desc = "I told you to shake it, no stirring."
	icon_state = "poster_martini"

/obj/structure/sign/poster/official/the_owl
	name = "The Owl"
	desc = "The Owl would do his best to protect the station. Will you?"
	icon_state = "poster_owl"

/obj/structure/sign/poster/official/no_erp
	name = "No ERP"
	desc = "This poster reminds the crew that Eroticismand Pornography aren't encouraged in public."
	icon_state = "poster_noerp"

/obj/structure/sign/poster/official/wtf_is_co2
	name = "Carbon Dioxide"
	desc = "This informational poster teaches the viewer what carbon dioxide is."
	icon_state = "poster_what"

/obj/structure/sign/poster/official/spiderlings
	name = "Spiderlings"
	desc = "This poster informs the crew of the dangers of spiderlings."
	icon_state = "poster_spiderlings"

/obj/structure/sign/poster/official/fashion
	name = "Fashion!"
	desc = "An advertisement for 'Fashion!', a popular fashion magazine, depicting a woman with a black dress with a golden trim, she also has a red poppy in her hair."
	icon_state = "poster_fashion"

/obj/structure/sign/poster/official/hydro_ad
	name = "Hydroponics Tray"
	desc = "An advertisement for hydroponics trays. Space Station 13's botanical department uses a slightly newer model, but the principles are the same. From left to right: Green means the plant is done, red means the plant is unhealthy, flashing red means pests or weeds, yellow means the plant needs nutriment and blue means the plant needs water."
	icon_state = "poster_hydroponics"

/obj/structure/sign/poster/official/medical_green_cross
	name = "Medical"
	desc = "A green cross, one of the interplanetary symbol of health and aid. It has a bunch of common languages at the top with translations." // Didn't the American Heart Foundation trademark red crosses? I'm playing it safe with green, not that they'll notice spacegame13 poster.
	icon_state = "poster_medical"

/obj/structure/sign/poster/official/nt_storm_officer
	name = "GT Storm Ad" //GS13 - NT to GT
	desc = "An advertisement for NanoTrasen Storm. A premium infantry helmet, This is the officer variant. I comes with a better radio, better HUD software and better targeting sensors."
	icon_state = "poster_stormy"

/obj/structure/sign/poster/official/nt_storm
	name = "GT Storm Ad" //GS13 - NT to GT
	desc = "An advertisement for NanoTrasen Storm. A premium infantry helmet, It contains a rebreather and full head coverage for use on harsh environments where the air isn't always safe to breathe."
	icon_state = "poster_stormier"

/obj/structure/sign/poster/official/mothhardhats
	name = "Safety Moth - Hardhats"
	desc = "This informational poster uses Safety Moth(TM) to tell the viewer to wear hardhats in cautious areas. It's like a lamp for your head!"
	icon_state = "poster_mothhardhats"

/obj/structure/sign/poster/official/mothpiping
	name = "Safety Moth - Piping"
	desc = "This informational poster uses Safety Moth(TM) to tell atmospheric technicians correct types of piping to be used. Proper pipe placement prevents poor preformance!"
	icon_state = "poster_mothpiping"

/obj/structure/sign/poster/official/mothsmokey
	name = "Safety Moth - Smokey?"
	desc = "This informational poster uses Safety Moth(TM) to promote safe handling of plasma, or promoting crew to combat plasmafires. We can't tell."
	icon_state = "poster_mothsmokey"

/obj/structure/sign/poster/official/mothsupermatter
	name = "Safety Moth - Supermatter"
	desc = "This informational poster uses Safety Moth(TM) to promote proper safety equipment when working near a Supermatter Crystal."
	icon_state = "poster_mothsupermatter"

/obj/structure/sign/poster/official/mothdelamination
	name = "Safety Moth - Delamination Safety Precautions"
	desc = "This informational poster uses Safety Moth(TM) to tell the viewer to hide in lockers when the Supermatter Crystal has delaminated. Running away might be a better strategy."
	icon_state = "poster_mothdelamination"

/obj/structure/sign/poster/official/mothboh
	name = "Safety Moth - BoH"
	desc = "This informational poster uses Safety Moth(TM) to inform the viewer of the dangers of Bags of Holding."
	icon_state = "poster_mothbluespace"

/obj/structure/sign/poster/official/mothmethethamphetamine
	name = "Safety Moth - Methamphetamine"
	desc = "This informational poster uses Safety Moth(TM) to tell the viewer to seek CMO approval before cooking methamphetamine. You shouldn't even be making this."
	icon_state = "poster_mothmethamphetamine"

/obj/structure/sign/poster/official/mothepinephrine
	name = "Safety Moth - Epinephrine"
	desc = "This informational poster uses Safety Moth(TM) to inform the viewer to help injured/deceased crewmen with their epinephrine injectors."
	icon_state = "poster_mothepinephrine"

#undef PLACE_SPEED
