// --------------------------------------------
// *** Retrieve an experimental device ***
// --------------------------------------------

/datum/cm_objective/retrieve_item/device
	value = OBJECTIVE_EXTREME_VALUE

/datum/cm_objective/retrieve_item/post_round_start()
	SSfactions.statistics["item_retrieval_total_instances"]++

/datum/cm_objective/retrieve_item/device/complete()
	..()
	SSfactions.statistics["item_retrieval_completed"]++

/datum/cm_objective/retrieve_item/device
	objective_flags = OBJECTIVE_DEAD_END | OBJECTIVE_START_PROCESSING_ON_DISCOVERY
	number_of_clues_to_generate = 8

/datum/cm_objective/retrieve_item/device/get_clue()
	return SPAN_DANGER("Retrieve <u>[target_item]</u> in <u>[initial_area]</u>.")

/datum/cm_objective/retrieve_item/device/get_related_label()
	var/obj/item/device/D = target_item
	return D.serial_number

// --------------------------------------------
// *** Experimental devices ***
// --------------------------------------------
/obj/item/device/mass_spectrometer/adv/objective
	var/datum/cm_objective/retrieve_item/device/objective
	unacidable = TRUE
	indestructible = TRUE
	is_objective = TRUE

/obj/item/device/mass_spectrometer/adv/objective/Initialize(mapload, _faction_to_get)
	faction_to_get = _faction_to_get
	. = ..()
	objective = new /datum/cm_objective/retrieve_item/device(faction_to_get, src)
	name += " #[serial_number]"

/obj/item/device/mass_spectrometer/adv/objective/Destroy()
	qdel(objective)
	objective = null
	// see [/datum/cm_objective/retrieve_item/proc/clean_up_ref]
	return ..()

/obj/item/device/reagent_scanner/adv/objective
	var/datum/cm_objective/retrieve_item/device/objective
	unacidable = TRUE
	indestructible = TRUE
	is_objective = TRUE

/obj/item/device/reagent_scanner/adv/objective/Initialize(mapload, _faction_to_get)
	faction_to_get = _faction_to_get
	. = ..()
	objective = new /datum/cm_objective/retrieve_item/device(faction_to_get, src)
	name += " #[serial_number]"

/obj/item/device/reagent_scanner/adv/objective/Destroy()
	qdel(objective)
	objective = null
	// see [/datum/cm_objective/retrieve_item/proc/clean_up_ref]
	return ..()

/obj/item/device/healthanalyzer/objective
	var/datum/cm_objective/retrieve_item/device/objective
	unacidable = TRUE
	indestructible = TRUE
	is_objective = TRUE

/obj/item/device/healthanalyzer/objective/Initialize(mapload, _faction_to_get)
	faction_to_get = _faction_to_get
	. = ..()
	objective = new /datum/cm_objective/retrieve_item/device(faction_to_get, src)
	name += " #[serial_number]"

/obj/item/device/healthanalyzer/objective/Destroy()
	qdel(objective)
	objective = null
	// see [/datum/cm_objective/retrieve_item/proc/clean_up_ref]
	return ..()

/obj/item/device/autopsy_scanner/objective
	var/datum/cm_objective/retrieve_item/device/objective
	unacidable = TRUE
	indestructible = TRUE
	is_objective = TRUE

/obj/item/device/autopsy_scanner/objective/Initialize(mapload, _faction_to_get)
	faction_to_get = _faction_to_get
	. = ..()
	objective = new /datum/cm_objective/retrieve_item/device(faction_to_get, src)
	name += " #[serial_number]"

/obj/item/device/autopsy_scanner/objective/Destroy()
	qdel(objective)
	objective = null
	// see [/datum/cm_objective/retrieve_item/proc/clean_up_ref]
	return ..()
