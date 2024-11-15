GLOBAL_LIST_EMPTY_TYPED(machines, /obj/structure/machinery)
GLOBAL_LIST_EMPTY_TYPED(processing_machines, /obj/structure/machinery)

//Holds all powernet datums in use or pooled
GLOBAL_LIST_EMPTY_TYPED(powernets, /datum/powernet)
GLOBAL_LIST_EMPTY_TYPED(powernets_by_name, /datum/powernet)

SUBSYSTEM_DEF(machinery)
	name		= "Machinery"
	wait		= 3.5 SECONDS
	flags		= SS_KEEP_TIMING
	init_order	= SS_INIT_MACHINES
	priority	= SS_PRIORITY_MACHINERY

	var/list/currentrunmachines = list()

/datum/controller/subsystem/machinery/Initialize(start_timeofday)
	makepowernets()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/machinery/stat_entry(msg)
	msg = "M:[GLOB.processing_machines.len]"
	return ..()

/datum/controller/subsystem/machinery/fire(resumed = FALSE)
	if(!resumed)
		currentrunmachines = GLOB.processing_machines.Copy()

	while (currentrunmachines.len)
		var/obj/structure/machinery/M = currentrunmachines[currentrunmachines.len]
		currentrunmachines.len--

		if(!M || QDELETED(M))
			continue

		M.process()
		//if(M.process() == PROCESS_KILL)
			//M.inMachineList = FALSE
			//machines.Remove(M)
			//continue

		if(MC_TICK_CHECK)
			return


