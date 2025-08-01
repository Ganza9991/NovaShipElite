/*
	Map templates
*/

/datum/map_template/outpost
	// Necessary to stop planetary outposts from having space underneath all their turfs.
	// They were being "placed on top", so instead of their baseturf, there was just space underneath.
	// (Interestingly, this is much less of a problem for ruins: PlaceOnTop ignores the top closed turf in the baseturfs stack
	// of the new tile, meaning that placing plating on top of a wall doesn't result in a wall underneath the plating.)
	should_place_on_top = FALSE

/datum/map_template/outpost/New()
	// [CELADON-EDIT] - CELADON_CONFIGS_MAPS
	// . = ..(path = "_maps/outpost/[name].dmm") // CELADON-EDIT - ORIGINAL
	. = ..(path = "_maps/nodalec/outpost/[name].dmm")
	// [/CELADON-EDIT]


/datum/map_template/outpost/hangar
	var/dock_width
	var/dock_height

/datum/map_template/outpost/elevator_test
	name = "elevator_test"

/datum/map_template/outpost/elevator_indie
	name = "elevator_indie"

/datum/map_template/outpost/elevator_ice
	name = "elevator_ice"

/datum/map_template/outpost/elevator_rock
	name = "elevator_rock"


/*
	Independent Space Outpost //creative name!
*/
/datum/map_template/outpost/indie_space
	name = "indie_space"

/datum/map_template/outpost/hangar/indie_space_20x20
	name = "hangar/indie_space_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x20
	name = "hangar/indie_space_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x40
	name = "hangar/indie_space_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/indie_space_56x20
	name = "hangar/indie_space_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_56x40
	name = "hangar/indie_space_56x40"
	dock_width = 56
	dock_height = 40

/*
	Nanotrasen Ice Planet
*/
/datum/map_template/outpost/nanotrasen_ice
	name = "nanotrasen_ice"

/datum/map_template/outpost/hangar/nt_ice_20x20
	name = "hangar/nt_ice_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_40x20
	name = "hangar/nt_ice_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_40x40
	name = "hangar/nt_ice_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/nt_ice_56x20
	name = "hangar/nt_ice_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/nt_ice_56x40
	name = "hangar/nt_ice_56x40"
	dock_width = 56
	dock_height = 40

/*
	Independent Rock Planet //ROCK AND STONE!
*/
/datum/map_template/outpost/ngr_rock
	name = "ngr_rock"

/datum/map_template/outpost/hangar/ngr_rock_20x20
	name = "hangar/ngr_rock_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_40x20
	name = "hangar/ngr_rock_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_40x40
	name = "hangar/ngr_rock_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/ngr_rock_56x20
	name = "hangar/ngr_rock_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/ngr_rock_56x40
	name = "hangar/ngr_rock_56x40"
	dock_width = 56
	dock_height = 40


/*
	/datum/overmap/outpost subtypes
*/
// [CELADON-REMOVE] - CELADON_CONFIGS_MAPS - Отправляется в щитспавн по приказу Head of Maps
/*
/datum/overmap/outpost/indie_space
	token_icon_state = "station_1"
	main_template = /datum/map_template/outpost/indie_space
	elevator_template = /datum/map_template/outpost/elevator_indie
	// Uses "default" hangars (indie_space).
*/
// [/CELADON-REMOVE]
/*
/datum/overmap/outpost/nanotrasen_asteroid
	token_icon_state = "station_asteroid_0"
	main_template = /datum/map_template/outpost/nt_asteroid
	elevator_template = /datum/map_template/outpost/elevator_test
	// Using a second list of hangar templates.
	hangar_templates = list(
		/datum/map_template/outpost/hangar/nt_asteroid_20x20,
		/datum/map_template/outpost/hangar/nt_asteroid_40x20,
		/datum/map_template/outpost/hangar/nt_asteroid_40x40,
		/datum/map_template/outpost/hangar/nt_asteroid_56x20,
		/datum/map_template/outpost/hangar/nt_asteroid_56x40
	)
*/
// [CELADON-REMOVE] - CELADON_CONFIGS_MAPS - Перенесено в модуль в maps
// /datum/overmap/outpost/nanotrasen_ice
// 	token_icon_state = "station_asteroid_0"
// 	main_template = /datum/map_template/outpost/nanotrasen_ice
// 	elevator_template = /datum/map_template/outpost/elevator_ice
// 	hangar_templates = list(
// 		/datum/map_template/outpost/hangar/nt_ice_20x20,
// 		/datum/map_template/outpost/hangar/nt_ice_40x20,
// 		/datum/map_template/outpost/hangar/nt_ice_40x40,
// 		/datum/map_template/outpost/hangar/nt_ice_56x20,
// 		/datum/map_template/outpost/hangar/nt_ice_56x40
// 	)
	// faction = /datum/faction/nt

// /datum/overmap/outpost/ngr_rock
// 	token_icon_state = "station_asteroid_0"
// 	main_template = /datum/map_template/outpost/ngr_rock
// 	elevator_template = /datum/map_template/outpost/elevator_rock
// 	hangar_templates = list(
// 		/datum/map_template/outpost/hangar/ngr_rock_20x20,
// 		/datum/map_template/outpost/hangar/ngr_rock_40x20,
// 		/datum/map_template/outpost/hangar/ngr_rock_40x40,
// 		/datum/map_template/outpost/hangar/ngr_rock_56x20,
// 		/datum/map_template/outpost/hangar/ngr_rock_56x40
// 	)

// /datum/overmap/outpost/no_main_level // For example and adminspawn.
// 	main_template = null
// 	elevator_template = /datum/map_template/outpost/elevator_test
// 	// Uses "test" hangars.
// [/CELADON-REMOVE]
