/client/proc/adjust_predator_round()
	set name = "Adjust Predator Round"
	set desc = "Adjust the number of predators present in a predator round."
	set category = "Server.Round"

	if(admin_holder)
		if(!SSticker || !SSticker.mode)
			to_chat(src, SPAN_WARNING("The game hasn't started yet!"))
			return

		var/value = tgui_input_number(src,"How many additional predators can join? Decreasing the value is not recommended. Current predator count: [SSticker.mode.pred_current_num]","Input:", 0, (SSticker.mode.pred_additional_max - SSticker.mode.pred_current_num))

		if(value < SSticker.mode.pred_current_num)
			to_chat(src, SPAN_NOTICE("Aborting. Number cannot be lower than the current pred count. (current: [SSticker.mode.pred_current_num], attempted: [value])"))
			return

		if(value)
			SSticker.mode.pred_additional_max = abs(value)
			message_admins("[key_name_admin(usr)] adjusted the additional pred amount to [abs(value)].")

/datum/admins/proc/force_predator_round()
	set name = "Toggle Predator Round"
	set desc = "Force-toggle a predator round for the round type. Only works on maps that support Predator spawns."
	set category = "Server.Round"

	// note: This is a proof of concept. ideally, scenario parameters should all be changeable in the same UI, rather than writing snowflake code everywhere like this
	if(!SSticker || SSticker.current_state < GAME_STATE_PLAYING || !SSticker.mode)
		var/enabled = FALSE
		if(SSnightmare.get_scenario_value("predator_round"))
			enabled = TRUE
		var/ret = alert("Nightmare Scenario has the upcoming round being a [(enabled ? "PREDATOR" : "NORMAL")] round. Do you want to toggle this?", "Toggle Predator Round", "Yes", "No")
		if(ret == "Yes")
			SSnightmare.set_scenario_value("predator_round", !enabled)
		return

	var/datum/game_mode/predator_round = SSticker.mode
	if(alert("Are you sure you want to force-toggle a predator round? Predators currently: [(predator_round.flags_round_type & MODE_PREDATOR) ? "Enabled" : "Disabled"]", usr.client.auto_lang(LANGUAGE_CONFIRM), usr.client.auto_lang(LANGUAGE_YES), usr.client.auto_lang(LANGUAGE_NO)) != usr.client.auto_lang(LANGUAGE_YES))
		return

	if(!(predator_round.flags_round_type & MODE_PREDATOR))
		var/datum/job/PJ = GET_MAPPED_ROLE(JOB_PREDATOR)
		if(istype(PJ) && !PJ.spawn_positions)
			PJ.set_spawn_positions(players_preassigned)
		predator_round.flags_round_type |= MODE_PREDATOR
	else
		predator_round.flags_round_type &= ~MODE_PREDATOR

	message_admins("[key_name_admin(usr)] has [(predator_round.flags_round_type & MODE_PREDATOR) ? "allowed predators to spawn" : "prevented predators from spawning"].")
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_PREDATOR_ROUND_TOGGLED)

/client/proc/free_slot()
	set name = "Free Job Slots"
	set category = "Server.Round"

	if(!admin_holder)
		return

	var/roles[] = new
	var/i
	var/list/roles_pool
	var/datum/job/J
	for(var/f in SSticker.role_authority.roles_for_mode)
		roles_pool = SSticker.role_authority.roles_for_mode[f]
		for(i in roles_pool)
			J = SSticker.role_authority.roles_for_mode[i]
			if(J.total_positions > 0 && J.current_positions > 0)
				roles += i

	to_chat(usr, SPAN_BOLDNOTICE("There is not a single taken job slot."))
	var/role = input("This list contains all roles that have at least one slot taken.\nPlease select role slot to free.", "Free role slot")  as null|anything in roles
	if(!role)
		return
	SSticker.role_authority.free_role_admin(roles_pool[role], TRUE, src)

/client/proc/modify_slot()
	set name = "Adjust Job Slots"
	set category = "Server.Round"

	if(!admin_holder)
		return

	var/roles[] = new
	var/datum/job/J

	var/active_role_names = SSticker.mode.active_roles_pool
	for(var/role_name as anything in active_role_names)
		var/datum/job/job = GET_MAPPED_ROLE(role_name)
		if(!job)
			continue
		roles += role_name

	var/role = input("Please select role slot to modify", "Modify amount of slots") as null|anything in roles
	if(!role)
		return
	J = GET_MAPPED_ROLE(role)
	var/tpos = J.spawn_positions
	var/num = tgui_input_number(src, "How many slots role [J.title] should have?\nCurrently taken slots: [J.current_positions]\nTotal amount of slots opened this round: [J.total_positions_so_far]","Number:", tpos)
	if(isnull(num))
		return
	if(!SSticker.role_authority.modify_role(J, num))
		to_chat(usr, SPAN_BOLDNOTICE("Can't set job slots to be less than amount of log-ins or you are setting amount of slots less than minimal. Free slots first."))
	message_admins("[key_name(usr)] adjusted job slots of [J.title] to be [num].")

/client/proc/check_antagonists()
	set name = "Check Antagonists"
	set category = "Server.Round"
	if(admin_holder)
		admin_holder.check_antagonists()
		log_admin("[key_name(usr)] checked antagonists.")
	return

/client/proc/check_round_status()
	set name = "Round Status"
	set category = "Server.Round"
	if(admin_holder)
		admin_holder.check_round_status()
		log_admin("[key_name(usr)] checked round status.")
	return

/datum/admins/proc/end_round()
	set name = "End Round"
	set desc = "Immediately ends the round, be very careful"
	set category = "Server.Round"

	if(!check_rights(R_SERVER) || !SSticker.mode)
		return

	// trying to end the round before it even starts. bruh
	if(!SSticker.mode)
		return

	if(alert("Are you sure you want to end the round?", "End Round", usr.client.auto_lang(LANGUAGE_YES), usr.client.auto_lang(LANGUAGE_NO)) != usr.client.auto_lang(LANGUAGE_YES))
		return

	var/winstate = input(usr, "What do you want the round end state to be?", "End Round") as null|anything in list("Custom", "Admin Intervention") + SSticker.mode.round_end_states
	if(!winstate)
		return

	if(winstate == "Custom")
		winstate = input(usr, "Please enter a custom round end state.", "End Round") as null|text
		if(!winstate)
			return

	if(SSticker.mode.faction_round_end_state[winstate])
		SSticker.mode.faction_won = GLOB.faction_datum[SSticker.mode.faction_round_end_state[winstate]]
	SSticker.mode.round_finished = winstate

	log_admin("[key_name(usr)] has made the round end early - [winstate].")
	message_admins("[key_name(usr)] has made the round end early - [winstate].")
	for(var/client/C in GLOB.admins)
		to_chat(C, {"
		<hr>
		[SPAN_CENTERBOLD("Staff-Only Alert: <EM>[usr.key]</EM> has made the round end early")]
		<hr>
		"})
	return

/datum/admins/proc/delay()
	set name = "Delay Round Start/End"
	set desc = "Delay the game start/end"
	set category = "Server.Round"

	if(!check_rights(R_SERVER))
		return
	if(SSticker.current_state != GAME_STATE_PREGAME)
		SSticker.delay_end = !SSticker.delay_end
		message_admins("[SPAN_NOTICE("[key_name(usr)] [SSticker.delay_end ? "delayed the round end" : "has made the round end normally"].")]")
		for(var/client/C in GLOB.admins)
			to_chat(C, {"<hr>
			[SPAN_CENTERBOLD("Staff-Only Alert: <EM>[usr.key]</EM> [SSticker.delay_end ? "delayed the round end" : "has made the round end normally"]")]
			<hr>"})
		return
	else
		SSticker.delay_start = !SSticker.delay_start
		message_admins("[SPAN_NOTICE("[key_name(usr)] [SSticker.delay_start ? "delayed the round start" : "has made the round start normally"].")]")
		to_chat(world, SPAN_CENTERBOLD("The game start has been [SSticker.delay_start ? "delayed" : "continued"]."))
		return

/datum/admins/proc/startnow()
	set name = "Start Round"
	set desc = "Start the round RIGHT NOW"
	set category = "Server.Round"

	if(alert("Are you sure you want to start the round early?",,"Yes","No") != "Yes")
		return

	if(SSticker.current_state == GAME_STATE_STARTUP)
		message_admins("Game is setting up and will launch as soon as it is ready.")
		message_admins(SPAN_ADMINNOTICE("[usr.key] has started the process to start the game when loading is finished."))
		while(SSticker.current_state == GAME_STATE_STARTUP)
			stoplag()

	if(SSticker.current_state == GAME_STATE_PREGAME)
		SSticker.request_start()
		message_admins(SPAN_BLUE("[usr.key] has started the game."))

		return TRUE
	else
		to_chat(usr, "<font color='red'>Error: Start Now: Game has already started.</font>")
		return FALSE
