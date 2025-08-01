/datum/overmap/outpost
	name = "outpost"
	char_rep = "T"
	token_icon_state = "globe"

	// The map template used for the outpost. If null, there will be no central area loaded.
	// Set to an instance of the singleton for its type in New.
	var/datum/map_template/outpost/main_template = null

	var/datum/map_template/outpost/elevator_template = null
	/// List of hangar templates. This list should contain hangar templates sufficient for any ship to dock within one,
	/// allowing it to dock with the outpost. This list is sorted on outpost initialization, in ascending order,
	/// first of width and then of height. When a ship requires a hangar, the outpost will iterate through this list until
	/// it finds a hangar large enough to fit the ship. Because of this, combining wide hangars (with a greater width than height)
	/// and tall hangars (with a greater height than width) in the list is discouraged; it is possible that a large hangar will "hide" a
	/// smaller one by appearing earlier in the sorted list.
	var/list/datum/map_template/outpost/hangar/hangar_templates = list(
		/datum/map_template/outpost/hangar/indie_space_20x20,
		/datum/map_template/outpost/hangar/indie_space_40x20,
		/datum/map_template/outpost/hangar/indie_space_40x40,
		/datum/map_template/outpost/hangar/indie_space_56x20,
		/datum/map_template/outpost/hangar/indie_space_56x40
	)
	// NOTE: "planetary" outposts should use baseturf specification and possibly different ztrait sun type, for both hangars and main level.
	var/list/main_level_ztraits = list(
		ZTRAIT_STATION = TRUE,
		ZTRAIT_SUN_TYPE = AZIMUTH,
		ZTRAIT_GRAVITY = STANDARD_GRAVITY,
		ZTRAIT_SCAN_DISRUPT = TRUE // [CELADON-EDIT] - CELADON_SURVEY_HANDHELD
	)
	var/list/hangar_ztraits = list(
		ZTRAIT_SUN_TYPE = STATIC_EXPOSED,
		ZTRAIT_GRAVITY = STANDARD_GRAVITY,
		ZTRAIT_SCAN_DISRUPT = TRUE // [CELADON-EDIT] - CELADON_SURVEY_HANDHELD
	)

	/// The mapzone used by the outpost level and hangars. Using a single mapzone means networked radio messages.
	var/datum/map_zone/mapzone
	var/list/datum/hangar_shaft/shaft_datums = list()

	/// The maximum number of missions that may be offered by the outpost at one time.
	/// Missions which have been accepted do not count against this limit.
	var/max_missions
	/// List of missions that can be accepted at this outpost. Missions which have been accepted are removed from this list.
	var/list/datum/mission/missions
	/// List of all of the things this outpost offers
	var/list/supply_packs = list()
	/// our 'Order number'
	var/ordernum = 1
	/// Our faction of the outpost
	var/datum/faction/faction

/datum/overmap/proc/Initialize(position, ...)
	PROTECTED_PROC(TRUE)
	return


// !!! ЭТОТ ПРОК ЗАКОМЕНТИРОВАН ЧТОБ В ТЕКУЩЕМ СОСТОЯНИИ РАБОТАЛО ТО ЧТО ВЫШЕ !!!

/datum/overmap/outpost/Initialize(position, ...)
	. = ..()
	// init our template vars with the correct singletons
	main_template = SSmapping.outpost_templates[main_template]
	elevator_template = SSmapping.outpost_templates[elevator_template]
	SSpoints_of_interest.make_point_of_interest(token)
	for(var/i in 1 to hangar_templates.len)
		hangar_templates[i] = SSmapping.outpost_templates[hangar_templates[i]]
	sortTim(hangar_templates, /proc/cmp_hangarsize_asc)
	SSovermap.outposts += src
	mapzone = SSmapping.create_map_zone("[name]")
	if(main_template)
		load_main_level()
	else
		shaft_datums += new /datum/hangar_shaft("A", null)
	// doing this after the main level is loaded means that the outpost areas are all renamed for us
	Rename(gen_outpost_name())

//	fill_missions() < - я закоментил прок fill_missions(), ищи по именам в коде, люблю тебя, солнце

	populate_cargo()
//	addtimer(CALLBACK(src, PROC_REF(fill_missions)), 10 MINUTES, TIMER_STOPPABLE|TIMER_LOOP|TIMER_DELETE_ME)

/datum/overmap/outpost/Destroy(...)
	SSpoints_of_interest.make_point_of_interest(token)
	// cleanup our data structures. behavior here is currently relatively restrained; may be made more expansive in the future
	for(var/list/datum/hangar_shaft/h_shaft as anything in shaft_datums)
		qdel(h_shaft)
		shaft_datums -= h_shaft

	SSovermap.outposts -= src
	. = ..()

/datum/overmap/outpost/get_jump_to_turf()
	if(main_template)
		// the main level is (hopefully) going to be the first in the mapzone's virtual levels
		var/datum/virtual_level/vlevel = mapzone.virtual_levels[1]
		return locate(round((vlevel.low_x + vlevel.high_x) / 2), round((vlevel.low_y + vlevel.high_y) / 2), vlevel.z_value)
	else
		var/datum/hangar_shaft/rand_shaft = pick(shaft_datums)
		if(!length(rand_shaft.hangar_docks))
			return null
		return get_turf(pick(rand_shaft.hangar_docks))

/datum/overmap/outpost/Rename(new_name, force)
	. = ..()
	if(!.)
		return
	var/list/hangar_vlevels = mapzone.virtual_levels.Copy()
	mapzone.name = name

	if(main_template)
		var/datum/virtual_level/vlevel = mapzone.virtual_levels[1]
		hangar_vlevels -= vlevel

		vlevel.name = name
		for(var/area/outpost/outpost_area in SSmapping.areas_in_z["[vlevel.z_value]"])
			if(vlevel.is_in_bounds(outpost_area))
				outpost_area.name = "[name] [initial(outpost_area.name)]"

	for(var/datum/hangar_shaft/shaft in shaft_datums)
		for(var/i in 1 to shaft.hangar_docks.len)
			// assumes that order in shaft = order in hangar list
			var/hangar_name = "[name] Hangar [shaft.name]-[i]"
			var/obj/docking_port/stationary/h_dock = shaft.hangar_docks[i]
			h_dock.name = hangar_name
			for(var/datum/virtual_level/h_vlevel in hangar_vlevels)
				if(h_vlevel.is_in_bounds(h_dock))
					h_vlevel.name = hangar_name
					hangar_vlevels -= h_vlevel
					break

// Shamelessly cribbed from how Elite: Dangerous does station names.
/datum/overmap/outpost/proc/gen_outpost_name()
	return "[random_species_name()] [pick(GLOB.station_suffixes)]"

/proc/random_species_name()
	var/person_name
	if(prob(40))
		// fun fact: "Hutton" is in last_names
		person_name = pick(GLOB.last_names)
	else
		person_name = pick(prob(50) ? GLOB.lizard_names_male : GLOB.lizard_names_female)

// ДАВАЙТЕ ПОКА БЕЗ ЭТОГО УМОЛЯЮ

//		switch(rand(1, 4))
//			if(1)
//				person_name = pick(prob(50) ? GLOB.lizard_names_male : GLOB.lizard_names_female)
//			if(2)
//				person_name = spider_name()
//			if(3)
//				person_name = kepori_name()
//			if(4)
//				person_name = vox_name()
	return person_name

// ЭТО НАМ ТОЖЕ НЕ НАДО

//	/datum/overmap/outpost/proc/fill_missions()
//		max_missions = min(10 + (SSovermap.controlled_ships.len * 2), 25)
//		while(LAZYLEN(missions) < max_missions)
//			var/mission_type = SSmissions.get_weighted_mission_type()
//			var/datum/mission/outpost/M = new mission_type(src)
//			LAZYADD(missions, M)

/datum/overmap/outpost/proc/populate_cargo()
	ordernum = rand(1, 99000)

	for(var/datum/supply_pack/current_pack as anything in subtypesof(/datum/supply_pack))
		current_pack = new current_pack()
		if(current_pack.faction)
			current_pack.faction = SSfactions.factions[current_pack.faction]
		if(!current_pack.contains)
			continue
		supply_packs += current_pack
	/datum/faction
/datum/overmap/outpost/proc/load_main_level()
	if(!main_template)
		CRASH("[src] ([src.type]) tried to load without a template!")

	log_game("[src] [REF(src)] OUTPOST MAP LEVEL INIT")
	log_shuttle("[src] [REF(src)] OUTPOST MAP LEVEL INIT")

	var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(
		name,
		main_level_ztraits,
		mapzone,
		QUADRANT_MAP_SIZE,
		QUADRANT_MAP_SIZE,
		ALLOCATION_QUADRANT,
		QUADRANT_MAP_SIZE
	)
	vlevel.reserve_margin(QUADRANT_SIZE_BORDER)

	main_template.load(vlevel.get_unreserved_bottom_left_turf())

	// assoc list of lists of landmarks in a shaft, starting with the main landmark
	var/list/list/shaft_lists = list()
	for(var/obj/effect/landmark/outpost/elevator/ele_mark in GLOB.outpost_landmarks)
		if(!vlevel.is_in_bounds(ele_mark))
			continue
		if(!istext(ele_mark.shaft))
			stack_trace("Invalid shaft var [ele_mark.shaft] on [ele_mark] found when loading [main_template]!")
			qdel(ele_mark)
		else
			shaft_lists[ele_mark.shaft] = list(ele_mark)

	if(!shaft_lists.len)
		stack_trace("No elevator shafts found while loading [main_template]! The map will be inaccessible!")

	// now we get the machine landmarks (button, doors) and add them to the shaft list
	for(var/obj/effect/landmark/outpost/elevator_machine/mach_mark in GLOB.outpost_landmarks)
		if(!vlevel.is_in_bounds(mach_mark))
			continue
		if(!(mach_mark.shaft in shaft_lists))
			stack_trace("Invalid shaft var [mach_mark.shaft] on [mach_mark] found when loading [main_template]!")
			qdel(mach_mark)
		else
			shaft_lists[mach_mark.shaft] += mach_mark

	for(var/shaft_name in shaft_lists)
		var/list/obj/shaft_li = shaft_lists[shaft_name]
		var/obj/effect/landmark/outpost/elevator/anchor_landmark = shaft_li[1]
		var/obj/structure/elevator_platform/plat

		// load the template
		elevator_template.load(anchor_landmark.loc)
		plat = locate() in anchor_landmark.loc
		// create the shaft datum
		shaft_datums += new /datum/hangar_shaft(shaft_name, plat.master_datum)
		// give the elevator a first floor
		plat.master_datum.add_floor_landmarks(anchor_landmark, shaft_li - anchor_landmark)

/datum/overmap/outpost/pre_docked(datum/overmap/ship/controlled/dock_requester)
	var/obj/docking_port/stationary/h_dock
	var/datum/map_template/outpost/h_template = get_hangar_template(dock_requester.shuttle_port)
	if(!h_template || !length(shaft_datums))
		return FALSE

	h_dock = ensure_hangar(h_template)
	if(!h_dock)
		stack_trace("Outpost [src] ([src.type]) [REF(src)] unable to create hangar [h_template] for ship [dock_requester] (template [dock_requester.source_template])!")
		return FALSE

	// [CELADON-ADD] - CELADON_COMPONENT - Pirates Update - NEEDS_TO_FIX_ALARM!
	// if(dock_requester.get_faction() == "Pirates") //Проверка шипа на пиратскую фракцию
	// 	return new /datum/docking_ticket(_docking_error = "Неавторизованным лицам отказано в стыковке с аванпостом.") //Запрет пиратам на стыковку с аванпостом
	// [/CELADON-ADD]

	if(src in dock_requester.blacklisted)
		return new /datum/docking_ticket(_docking_error = "Docking request denied: [dock_requester.blacklisted[src]]")

	adjust_dock_to_shuttle(h_dock, dock_requester.shuttle_port)
	return new /datum/docking_ticket(h_dock, src, dock_requester)
// [CELADON-REMOVE] - CELADON_MASTER_FILES - Вырезано, так как создаёт рантаймы при удалении корабля через манипулятор
/*
/datum/overmap/outpost/post_undocked(datum/overmap/ship/controlled/dock_requester)
	// just get an arbitrary hangar dock. for the message source. at this point,
	// we don't have enough information to know which hangar the ship was docked to.
	// however, so long as the speaker is an atom on a virtual_level in the right mapzone, we should be good.
	// since they were just docked, we'll definitely find A hangar, even if it's the wrong one
	var/obj/message_src
	for(var/datum/hangar_shaft/shaft as anything in shaft_datums)
		if(length(shaft.hangar_docks))
			message_src = shaft.hangar_docks[1]
			break

	// Prepare and send a radio message about the undock over Common, in Common.
	// See outpost post_docked() for some notes on what we're doing here.
	var/atom/movable/virtualspeaker/v_speaker = new(null, token, null)
	var/datum/signal/subspace/vocal/signal = new(
		message_src,
		FREQ_COMMON,
		v_speaker,
		/datum/language/galactic_common,
		"[dock_requester.name] has departed from [src].",
		list(SPAN_ROBOT),
		list(MODE_CUSTOM_SAY_EMOTE = "coldly states")
	)
	signal.send_to_receivers()
*/
// [/CELADON-REMOVE]

/datum/overmap/outpost/proc/get_hangar_template(obj/docking_port/mobile/request_port)
	RETURN_TYPE(/datum/map_template/outpost)
	var/list/request_size = list(request_port.width, request_port.height)

	for(var/datum/map_template/outpost/hangar/hangar_template as anything in hangar_templates)
		if( \
			(request_size[1] <= hangar_template.dock_width && request_size[2] <= hangar_template.dock_height) || \
			(request_size[1] <= hangar_template.dock_height && request_size[2] <= hangar_template.dock_width) \
		)
			return hangar_template
	return null // this is implicit, but i want to be clear that intended behavior here is to return null. it's not necessarily an error

/datum/overmap/outpost/proc/ensure_hangar(datum/map_template/outpost/hangar/h_template)
	RETURN_TYPE(/obj/docking_port/stationary)
	for(var/datum/hangar_shaft/h_shaft as anything in shaft_datums)
		for(var/obj/docking_port/stationary/h_dock as anything in h_shaft.hangar_docks)
			// a dock/undock cycle may leave the stationary port w/ flipped width and height,
			// due to adjust_dock_to_shuttle(). so we need to check both orderings of the list.
			if( \
				!h_dock.current_docking_ticket && !h_dock.docked && \
				( \
					(h_dock.width == h_template.dock_width && h_dock.height == h_template.dock_height) || \
					(h_dock.width == h_template.dock_height && h_dock.height == h_template.dock_width) \
				) \
			)
				return h_dock

	// we didn't find a valid hangar, so we have to make one
	var/datum/hangar_shaft/chosen_shaft = pick(shaft_datums)
	return make_hangar(h_template, chosen_shaft)

/datum/overmap/outpost/proc/make_hangar(datum/map_template/outpost/hangar/h_template, datum/hangar_shaft/shaft)
	RETURN_TYPE(/obj/docking_port/stationary)

	if(!(h_template in hangar_templates))
		CRASH("[src] ([src.type]) was told to instance hangar [h_template], which is not in its hangar_templates list!")

	log_game("[src] ([src.type]) [REF(src)] OUTPOST HANGAR INIT")
	log_shuttle("[src] ([src.type]) [REF(src)] OUTPOST HANGAR INIT")

	var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(
		"[src.name] Loading Hangar", // we actually need to change this later; we can't number the hangar if we CHECK_TICK before we add the hangar to the list
		hangar_ztraits,
		mapzone,
		h_template.width+2,
		h_template.height+2,
		ALLOCATION_FREE
	)
	vlevel.reserve_margin(1)

	h_template.load(vlevel.get_unreserved_bottom_left_turf())

	var/turf/dock_turf
	for(var/obj/effect/landmark/outpost/hangar_dock/dock_mark in GLOB.outpost_landmarks)
		if(vlevel.is_in_bounds(dock_mark))
			dock_turf = dock_mark.loc
			qdel(dock_mark, TRUE)
			break
	if(!dock_turf)
		CRASH("[src] ([src.type]) could not find a hangar docking port landmark for its spawned hangar [h_template]!")

	var/obj/docking_port/stationary/h_dock = new(dock_turf)
	h_dock.dir = NORTH
	h_dock.width = h_template.dock_width
	h_dock.height = h_template.dock_height
	shaft.hangar_docks += h_dock

	// important not to CHECK_TICK after this point, so that the number is guaranteed to be correct
	var/hangar_num = length(shaft.hangar_docks)
	var/hangar_name = "[src.name] Hangar [shaft.name]-[hangar_num]"
	h_dock.name = hangar_name
	vlevel.name = hangar_name
	// hangar area has UNIQUE_AREA, so do not rename it (annoying)

	// now that we have the hangar num, we can add decals where necessary
	for(var/obj/effect/landmark/outpost/hangar_numbers/num_mark in GLOB.outpost_landmarks)
		if(!vlevel.is_in_bounds(num_mark))
			continue
		num_mark.write_number(hangar_num) // deletes the mark
	for(var/obj/effect/landmark/outpost/hangar_crate_spawner/crate_spawner_mark in GLOB.outpost_landmarks)
		if(!vlevel.is_in_bounds(crate_spawner_mark))
			continue
		h_dock.crate_spawner = crate_spawner_mark.create_spawner()
	if(!shaft.shaft_elevator)
		// if there's no elevator in this shaft, then delete the landmarks
		for(var/obj/effect/landmark/outpost/mark as anything in GLOB.outpost_landmarks)
			if(vlevel.is_in_bounds(mark))
				qdel(mark)
	else
		var/obj/effect/landmark/outpost/elevator/anchor_mark
		var/list/obj/effect/landmark/outpost/elevator_machine/mach_marks = list()

		for(var/obj/effect/landmark/outpost/mark as anything in GLOB.outpost_landmarks)
			if(!vlevel.is_in_bounds(mark))
				continue

			if(!anchor_mark && istype(mark, /obj/effect/landmark/outpost/elevator))
				anchor_mark = mark
			else if(istype(mark, /obj/effect/landmark/outpost/elevator_machine))
				mach_marks += mark

		shaft.shaft_elevator.add_floor_landmarks(anchor_mark, mach_marks)
	return h_dock

/*
	Hangar shafts
*/

/// Rudimentary data structure used by outposts to organize their hangars.
/datum/hangar_shaft
	var/name

	var/datum/elevator_master/shaft_elevator
	var/list/obj/docking_port/stationary/hangar_docks = list()

/datum/hangar_shaft/New(_name, _elevator)
	if(_name)
		name = _name
	if(_elevator)
		shaft_elevator = _elevator

// DEBUG: move out of here, maybe?
GLOBAL_LIST_EMPTY(hangar_dock_landmarks)
GLOBAL_LIST_EMPTY(hangar_elevator_landmarks)

/obj/effect/landmark/hangar_dock
	name = "hangar docking port landmark"

/obj/effect/landmark/hangar_dock/New(...)
	GLOB.hangar_dock_landmarks += src
	. = ..()

/obj/effect/landmark/hangar_dock/Destroy(...)
	GLOB.hangar_dock_landmarks -= src
	. = ..()

/obj/effect/landmark/hangar_elevator
	name = "hangar elevator landmark"

/obj/effect/landmark/hangar_elevator/New(...)
	GLOB.hangar_elevator_landmarks += src
	. = ..()

/obj/effect/landmark/hangar_elevator/Destroy(...)
	GLOB.hangar_elevator_landmarks -= src
	. = ..()

// DEBUG: move these out too
/datum/map_template/hangar
	var/skin
	var/port_width
	var/port_height

/datum/map_template/hangar/New()
	var/new_name = "hangar_[skin]_[port_width]x[port_height]"
	. = ..(path = "_maps/hangars/[new_name].dmm", rename = new_name)
