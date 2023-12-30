


//FLAMETHROWER

/obj/item/weapon/gun/flamer
	name = "M240A1 incinerator unit"
	desc = "M240A1 incinerator unit has proven to be one of the most effective weapons at clearing out soft-targets. This is a weapon to be feared and respected as it is quite deadly."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/uscm.dmi'
	icon_state = "m240"
	item_state = "m240"
	flags_equip_slot = SLOT_BACK
	w_class = SIZE_LARGE
	force = 15
	fire_sound = ""
	unload_sound = 'sound/weapons/handling/flamer_unload.ogg'
	reload_sound = 'sound/weapons/handling/flamer_reload.ogg'
	aim_slowdown = SLOWDOWN_ADS_INCINERATOR
	current_mag = /obj/item/ammo_magazine/flamer_tank
	var/fuel_pressure = 1 //Pressure setting of the attached fueltank, controls how much fuel is used per tile
	var/max_range = 9 //9 tiles, 7 is screen range, controlled by the type of napalm in the canister. We max at 9 since diagonal bullshit.

	attachable_allowed = list( //give it some flexibility.
		/obj/item/attachable/flashlight,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/attached_gun/extinguisher,
		/obj/item/attachable/attached_gun/flamer_nozzle
	)
	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_WIELDED_FIRING_ONLY|GUN_TRIGGER_SAFETY|GUN_AMMO_COUNTER
	durability_tier = WEAPON_DAMAGE_ALOT
	gun_category = GUN_CATEGORY_HEAVY
	can_jammed = FALSE


/obj/item/weapon/gun/flamer/Initialize(mapload, spawn_empty)
	. = ..()
	update_icon()

/obj/item/weapon/gun/flamer/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 0, "muzzle_y" = 0, "rail_x" = 11, "rail_y" = 20, "under_x" = 21, "under_y" = 14, "stock_x" = 0, "stock_y" = 0)

/obj/item/weapon/gun/flamer/x_offset_by_attachment_type(attachment_type)
	switch(attachment_type)
		if(/obj/item/attachable/flashlight)
			return 8
	return 0

/obj/item/weapon/gun/flamer/y_offset_by_attachment_type(attachment_type)
	switch(attachment_type)
		if(/obj/item/attachable/flashlight)
			return -1
	return 0

/obj/item/weapon/gun/flamer/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_5 * 5)

/obj/item/weapon/gun/flamer/unique_action(mob/user)
	toggle_gun_safety()

/obj/item/weapon/gun/flamer/gun_safety_handle(mob/user)
	to_chat(user, SPAN_NOTICE("You [SPAN_BOLD(flags_gun_features & GUN_TRIGGER_SAFETY ? "extinguish" : "ignite")] the pilot light."))
	playsound(user,'sound/weapons/handling/flamer_ignition.ogg', 25, 1)
	update_icon()

/obj/item/weapon/gun/flamer/get_examine_text(mob/user)
	. = ..()
	if(current_mag)
		. += "The fuel gauge shows the current tank is [round(current_mag.get_ammo_percent())]% full!"
	else
		. += "There's no tank in [src]!"

/obj/item/weapon/gun/flamer/get_display_ammo_count()
	if(!current_mag)
		return 0
	else
		return round(current_mag.get_ammo_percent())

/obj/item/weapon/gun/flamer/update_icon()
	..()

	// Have to redo this here because we don't want the empty sprite when the tank is empty (just when it's not in the gun)
	var/new_icon_state = gun_icon
	if(has_empty_icon && !current_mag)
		new_icon_state += "_e"
	icon_state = new_icon_state

	if(current_mag && current_mag.reagents)
		var/image/I = image(icon, icon_state="[gun_icon]_strip")
		I.color = mix_color_from_reagents(current_mag.reagents.reagent_list)
		overlays += I

	if(!(flags_gun_features & GUN_TRIGGER_SAFETY))
		var/obj/item/attachable/attached_gun/flamer_nozzle/nozzle = locate() in contents
		var/image/I = image(icon, src, "+lit")
		I.pixel_x += nozzle && nozzle == active_attachable ? 6 : 1
		overlays += I

/obj/item/weapon/gun/flamer/able_to_fire(mob/user)
	. = ..()
	if(.)
		if(!current_mag || !current_mag.ammo_position)
			return NONE

/obj/item/weapon/gun/flamer/proc/get_fire_sound()
	var/list/fire_sounds = list(
							'sound/weapons/gun_flamethrower1.ogg',
							'sound/weapons/gun_flamethrower2.ogg',
							'sound/weapons/gun_flamethrower3.ogg')
	return pick(fire_sounds)

/obj/item/weapon/gun/flamer/Fire(atom/target, mob/living/user, params, reflex)
	set waitfor = FALSE

	if(!able_to_fire(user))
		return NONE

	var/turf/curloc = get_turf(user) //In case the target or we are expired.
	var/turf/targloc = get_turf(target)
	if(!targloc || !curloc)
		return NONE //Something has gone wrong...

	if(active_attachable && active_attachable.flags_attach_features & ATTACH_WEAPON) //Attachment activated and is a weapon.
		if(active_attachable.flags_attach_features & ATTACH_PROJECTILE)
			return
		if(active_attachable.ammo_position <= 0 && !(active_attachable.flags_attach_features & ATTACH_IGNORE_EMPTY))
			click_empty(user) //If it's empty, let them know.
			to_chat(user, SPAN_WARNING("[active_attachable] is empty!"))
			to_chat(user, SPAN_NOTICE("You disable [active_attachable]."))
			active_attachable.activate_attachment(src, null, TRUE)
		else
			active_attachable.fire_attachment(target, src, user) //Fire it.
			active_attachable.last_fired = world.time
		return NONE

	if(flags_gun_features & GUN_TRIGGER_SAFETY)
		to_chat(user, SPAN_WARNING("\The [src] isn't lit!"))
		return NONE

	if(!current_mag)
		return NONE
	if(current_mag.ammo_position <= 0)
		click_empty(user)
	else
		user.track_shot(initial(name))
		unleash_flame(target, user)
		user?.hud_used.update_ammo_hud(src, get_ammo_list(), get_display_ammo_count())
		return AUTOFIRE_CONTINUE
	return NONE

/obj/item/weapon/gun/flamer/reload(mob/user, obj/item/ammo_magazine/magazine)
	if(!magazine || !istype(magazine))
		to_chat(user, SPAN_WARNING("That's not a magazine!"))
		return

	if(magazine.ammo_position <= 0)
		to_chat(user, SPAN_WARNING("That [magazine.name] is empty!"))
		return

	if(!istype(src, magazine.gun_type))
		to_chat(user, SPAN_WARNING("That magazine doesn't fit in there!"))
		return

	if(!QDELETED(current_mag) && current_mag.loc == src)
		to_chat(user, SPAN_WARNING("It's still got something loaded!"))
		return

	else
		if(user)
			if(magazine.transfer_delay > 1)
				to_chat(user, SPAN_NOTICE("You begin reloading [src]. Hold still..."))
				if(do_after(user, magazine.transfer_delay * user.get_skill_duration_multiplier(SKILL_FIREARMS), INTERRUPT_ALL_OUT_OF_RANGE, BUSY_ICON_FRIENDLY))
					replace_magazine(user, magazine)
				else
					to_chat(user, SPAN_WARNING("Your reload was interrupted!"))
					return
			else
				replace_magazine(user, magazine)
		else
			current_mag = magazine
			magazine.forceMove(src)
			replace_ammo(, magazine)
	var/obj/item/ammo_magazine/flamer_tank/tank = magazine
	fuel_pressure = tank.fuel_pressure
	update_icon()
	return 1

/obj/item/weapon/gun/flamer/unload(mob/user, reload_override = 0, drop_override = 0)
	if(!current_mag)
		return //no magazine to unload
	if(drop_override || !user) //If we want to drop it on the ground or there's no user.
		current_mag.forceMove(get_turf(src)) //Drop it on the ground.
	else if(user)
		user.put_in_hands(current_mag)

	if(user)
		playsound(user, unload_sound, 25, 1)
		user.visible_message(SPAN_NOTICE("[user] unloads [current_mag] from [src]."),
		SPAN_NOTICE("You unload [current_mag] from [src]."))

	current_mag.update_icon()
	current_mag = null
	fuel_pressure = 1

	update_icon()

/obj/item/weapon/gun/flamer/proc/unleash_flame(atom/target, mob/living/user)
	set waitfor = FALSE
	var/obj/item/ammo_magazine/flamer_tank/flamer_tank = current_mag
	last_fired = world.time
	if(!flamer_tank || !flamer_tank.reagents || !flamer_tank.reagents.reagent_list.len)
		return

	if(flamer_tank.glob_flame)
		var/obj/item/projectile/proj = flamer_tank.transfer_bullet_out()
		proj.forceMove(src)
		apply_traits(proj)
		proj.bullet_ready_to_fire(initial(name), weapon_source_mob = user)
		GIVE_BULLET_TRAIT(proj, /datum/element/bullet_trait_iff, faction)
		playsound(get_turf(user), src.get_fire_sound(), 50, TRUE)
		proj.fire_at(target, src, user, proj.ammo.max_range, proj.ammo.shell_speed)
	else
		var/datum/reagent/R = flamer_tank.reagents.reagent_list[1]

		var/flameshape = R.flameshape
		var/fire_type = R.fire_type

		R.intensityfire = Clamp(R.intensityfire, flamer_tank.reagents.min_fire_int, flamer_tank.reagents.max_fire_int)
		R.durationfire = Clamp(R.durationfire, flamer_tank.reagents.min_fire_dur, flamer_tank.reagents.max_fire_dur)
		R.rangefire = Clamp(R.rangefire, flamer_tank.reagents.min_fire_rad, flamer_tank.reagents.max_fire_rad)
		var/max_range = R.rangefire
		if(max_range < fuel_pressure) //Used for custom tanks, allows for higher ranges
			max_range = Clamp(fuel_pressure, 0, flamer_tank.reagents.max_fire_rad)
		if(R.rangefire == -1)
			max_range = flamer_tank.reagents.max_fire_rad

		var/turf/temp[] = getline2(get_turf(user), get_turf(target))

		var/turf/to_fire = temp[2]

		var/obj/flamer_fire/fire = locate() in to_fire
		if(fire)
			qdel(fire)

		playsound(to_fire, src.get_fire_sound(), 50, TRUE)

		new /obj/flamer_fire(to_fire, create_cause_data(initial(name), user), R, max_range, flamer_tank.reagents, flameshape, target, CALLBACK(src, PROC_REF(show_percentage), user), fuel_pressure, fire_type)

/obj/item/weapon/gun/flamer/proc/show_percentage(mob/living/user)
	if(current_mag)
		to_chat(user, SPAN_WARNING("The gauge reads: <b>[round(current_mag.get_ammo_percent())]</b>% fuel remains!"))
		display_ammo(user)

/obj/item/weapon/gun/flamer/underextinguisher
	starting_attachment_types = list(/obj/item/attachable/attached_gun/extinguisher)

/obj/item/weapon/gun/flamer/deathsquad //w-y deathsquad waist flamer
	name = "\improper M240A3 incinerator unit"
	desc = "A next-generation incinerator unit, the M240A3 is much lighter and dextrous than its predecessors thanks to the ceramic alloy construction. It can be slinged over a belt and usually comes equipped with EX-type fuel."
	attachable_allowed = list(
		/obj/item/attachable/flashlight,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/attached_gun/extinguisher,
	)
	starting_attachment_types = list(/obj/item/attachable/attached_gun/extinguisher/pyro, /obj/item/attachable/magnetic_harness)
	flags_equip_slot = SLOT_BACK | SLOT_WAIST
	auto_retrieval_slot = WEAR_WAIST
	current_mag = /obj/item/ammo_magazine/flamer_tank/ex
	flags_gun_features = GUN_WY_RESTRICTED|GUN_WIELDED_FIRING_ONLY

/obj/item/weapon/gun/flamer/deathsquad/nolock
	flags_gun_features = GUN_WIELDED_FIRING_ONLY

/obj/item/weapon/gun/flamer/M240T
	name = "M240-T incinerator unit"
	desc = "An improved version of the M240A1 incinerator unit, the M240-T model is capable of dispersing a larger variety of fuel types."
	icon_state = "m240t"
	item_state = "m240t"
	unacidable = TRUE
	indestructible = 1
	current_mag = null
	var/obj/item/storage/large_holster/fuelpack/fuelpack

	attachable_allowed = list(
		/obj/item/attachable/flashlight,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/attached_gun/extinguisher,
	)
	starting_attachment_types = list(/obj/item/attachable/attached_gun/extinguisher/pyro)
	flags_gun_features = GUN_UNUSUAL_DESIGN|GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER
	flags_item = TWOHANDED|NO_CRYO_STORE

/obj/item/weapon/gun/flamer/M240T/unique_action(mob/user)
	if(fuelpack)
		fuelpack.do_toggle_fuel(user)

/obj/item/weapon/gun/flamer/M240T/Destroy()
	if(fuelpack)
		if(fuelpack.linked_flamer == src)
			fuelpack.linked_flamer = null
		fuelpack = null
	. = ..()

/obj/item/weapon/gun/flamer/M240T/retrieval_check(mob/living/carbon/human/user, retrieval_slot)
	if(retrieval_slot == WEAR_IN_SCABBARD)
		var/obj/item/storage/large_holster/fuelpack/FP = user.back
		if(istype(FP) && !length(FP.contents))
			return TRUE
		return FALSE
	return ..()

/obj/item/weapon/gun/flamer/M240T/retrieve_to_slot(mob/living/carbon/human/user, retrieval_slot)
	if(retrieval_slot == WEAR_J_STORE) //If we are using a magharness...
		if(..(user, WEAR_IN_SCABBARD)) //...first try to put it onto the Broiler.
			return TRUE
	return ..()

/obj/item/weapon/gun/flamer/M240T/x_offset_by_attachment_type(attachment_type)
	switch(attachment_type)
		if(/obj/item/attachable/flashlight)
			return 7
	return 0

/obj/item/weapon/gun/flamer/M240T/y_offset_by_attachment_type(attachment_type)
	switch(attachment_type)
		if(/obj/item/attachable/flashlight)
			return -1
	return 0

/obj/item/weapon/gun/flamer/M240T/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 0, "muzzle_y" = 0, "rail_x" = 13, "rail_y" = 20, "under_x" = 21, "under_y" = 14, "stock_x" = 0, "stock_y" = 0)

/obj/item/weapon/gun/flamer/M240T/Fire(atom/target, mob/living/user, params, reflex = 0, dual_wield)
	if(!link_fuelpack(user) && !current_mag)
		to_chat(user, SPAN_WARNING("You must equip the specialized Broiler-T back harness or load in a fuel tank to use this incinerator unit!"))
		click_empty(user)
		return
	if(fuelpack)
		// Check we're actually firing the right fuel tank
		if(current_mag != fuelpack.active_fuel)
			// This was a manually loaded fuel tank
			if(current_mag && !(current_mag in list(fuelpack.fuel, fuelpack.fuelB, fuelpack.fuelX)))
				to_chat(user, SPAN_WARNING("\The [current_mag] is ejected by the Broiler-T back harness and replaced with \the [fuelpack.active_fuel]!"))
				unload(user, drop_override = TRUE)
			current_mag = fuelpack.active_fuel
			update_icon()
	return ..()


/obj/item/weapon/gun/flamer/M240T/reload(mob/user, obj/item/ammo_magazine/magazine)
	if(fuelpack)
		to_chat(user, SPAN_WARNING("The Broiler-T feed system cannot be reloaded manually."))
		return
	..()

/obj/item/weapon/gun/flamer/M240T/unload(mob/user, reload_override = 0, drop_override = 0, loc_override = 0)
	if(fuelpack && (current_mag in list(fuelpack.fuel, fuelpack.fuelB, fuelpack.fuelX)))
		to_chat(user, SPAN_WARNING("The incinerator tank is locked in place. It cannot be removed."))
		return
	..()

/obj/item/weapon/gun/flamer/M240T/able_to_fire(mob/user)
	. = ..()
	if(.)
		if(!current_mag || !current_mag.ammo_position)
			return FALSE

		if(!skillcheck(user, SKILL_SPEC_WEAPONS,  SKILL_SPEC_ALL) && user.skills.get_skill_level(SKILL_SPEC_WEAPONS) != SKILL_SPEC_PYRO)
			to_chat(user, SPAN_WARNING("You don't seem to know how to use [src]..."))
			return FALSE

/obj/item/weapon/gun/flamer/M240T/proc/link_fuelpack(mob/user)
	if(fuelpack)
		fuelpack.linked_flamer = null
		fuelpack = null

	if(istype(user.back, /obj/item/storage/large_holster/fuelpack))
		var/obj/item/storage/large_holster/fuelpack/FP = user.back
		if(FP.linked_flamer)
			FP.linked_flamer.fuelpack = null
		FP.linked_flamer = src
		fuelpack = FP
		return TRUE
	return FALSE

/obj/item/weapon/gun/flamer/M240T/auto // With NEW advances in science, we've learned how to drain a pyro's tank in 6 seconds, or your money back!
	name = "\improper M240-T2 incinerator unit"
	desc = "A prototyped model of the M240-T incinerator unit, it was discontinued after its automatic mode was deemed too expensive to deploy in the field."
	start_semiauto = FALSE
	start_automatic = TRUE

/obj/item/weapon/gun/flamer/M240T/auto/set_gun_config_values()
	. = ..()
	set_fire_delay(FIRE_DELAY_TIER_7)

GLOBAL_LIST_EMPTY(flamer_particles)
/particles/flamer_fire
	icon = 'icons/effects/particles/bonfire.dmi'
	icon_state = "bonfire"
	width = 100
	height = 100
	count = 1000
	spawning = 8
	lifespan = 0.7 SECONDS
	fade = 1 SECONDS
	grow = -0.01
	velocity = list(0, 0)
	position = generator("box", list(-16, -16), list(16, 16), NORMAL_RAND)
	drift = generator("vector", list(0, -0.2), list(0, 0.2))
	gravity = list(0, 0.95)
	scale = generator("vector", list(0.3, 0.3), list(1,1), NORMAL_RAND)
	rotation = 30
	spin = generator("num", -20, 20)

/particles/flamer_fire/New(set_color)
	..()
	color = set_color

/obj/flamer_fire
	name = "fire"
	desc = "Ouch!"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/fire.dmi'
	icon_state = "dynamic_2"
	layer = BELOW_OBJ_LAYER

	light_system = STATIC_LIGHT
	light_range = 3
	light_power = 0.4
	light_color = "#f88818"
	light_on = TRUE

	var/firelevel = 12 //Tracks how much "fire" there is. Basically the timer of how long the fire burns
	var/burnlevel = 10 //Tracks how HOT the fire is. This is basically the heat level of the fire and determines the temperature.

	/// After the fire is created, for 0.5 seconds this variable will be TRUE.
	var/initial_burst = TRUE

	var/flame_icon = "dynamic"
	var/flameshape = FLAMESHAPE_DEFAULT // diagonal square shape
	var/datum/cause_data/weapon_cause_data
	var/turf/target_clicked

	var/datum/reagent/tied_reagent
	var/datum/reagents/tied_reagents
	var/datum/callback/to_call

	var/fire_variant = FIRE_VARIANT_DEFAULT

	var/weather_smothering_strength = 0

/obj/flamer_fire/Initialize(mapload, datum/cause_data/cause_data, datum/reagent/R, fire_spread_amount = 0, datum/reagents/obj_reagents = null, new_flameshape = FLAMESHAPE_DEFAULT, atom/target = null, datum/callback/C, fuel_pressure = 1, fire_type = FIRE_VARIANT_DEFAULT)
	. = ..()
	if(!R)
		R = new /datum/reagent/napalm/ut()

	if(!tied_reagents)
		create_reagents(100) // So that the expanding flames are all linked together by 1 tied_reagents object
		tied_reagents = reagents
		tied_reagents.locked = TRUE

	flameshape = new_flameshape

	fire_variant = fire_type

	//non-dynamic flame is already colored
	if(R.burn_sprite == "dynamic")
		color = R.burncolor
	else
		flame_icon = R.burn_sprite

	set_light(l_color = R.burncolor)

	if(!GLOB.flamer_particles[R.burncolor])
		GLOB.flamer_particles[R.burncolor] = new /particles/flamer_fire(R.burncolor)
	particles = GLOB.flamer_particles[R.burncolor]

	tied_reagent = new R.type() // Can't get deleted this way
	tied_reagent.make_alike(R)

	tied_reagents = obj_reagents

	target_clicked = target

	if(istype(cause_data))
		weapon_cause_data = cause_data
	else if(cause_data)
		weapon_cause_data = create_cause_data(cause_data)
	else
		weapon_cause_data = create_cause_data(initial(name), null)

	icon_state = "[flame_icon]_2"

	//Fire duration increases with fuel usage
	firelevel = R.durationfire + fuel_pressure*R.durationmod
	burnlevel = R.intensityfire

	//are we in weather??
	update_in_weather_status()

	update_flame()

	addtimer(CALLBACK(src, PROC_REF(un_burst_flame)), 0.5 SECONDS)
	START_PROCESSING(SSobj, src)

	to_call = C

	var/burn_dam = burnlevel*FIRE_DAMAGE_PER_LEVEL

	if(tied_reagents && !tied_reagents.locked)
		var/removed = tied_reagents.remove_reagent(tied_reagent.id, FLAME_REAGENT_USE_AMOUNT * fuel_pressure)
		if(removed)
			qdel(src)
			return

	if(fire_spread_amount > 0)
		var/datum/flameshape/FS = GLOB.flameshapes[flameshape]
		if(!FS)
			CRASH("Invalid flameshape passed to /obj/flamer_fire. (Expected /datum/flameshape, got [FS] (id: [flameshape]))")

		INVOKE_ASYNC(FS, TYPE_PROC_REF(/datum/flameshape, handle_fire_spread), src, fire_spread_amount, burn_dam, fuel_pressure)
	//Apply fire effects onto everyone in the fire

	// Melt a single layer of snow
	if(istype(loc, /turf/open/snow))
		var/turf/open/snow/S = loc

		if(S.bleed_layer > 0)
			S.bleed_layer--
			S.update_icon(1, 0)

	//scorch mah grass HNNGGG
	if (istype(loc, /turf/open))
		var/turf/open/scorch_turf_target = loc
		if(scorch_turf_target.scorchable)
			scorch_turf_target.scorch(burnlevel)

	if(istype(loc, /turf/open/auto_turf/snow))
		var/turf/open/auto_turf/snow/S = loc
		if(S.bleed_layer > 0)
			var/new_layer = S.bleed_layer - 1
			S.changing_layer(new_layer)

	var/mob/shoot_mob = weapon_cause_data.resolve_mob()
	for(var/mob/living/ignited_morb in loc) //Deal bonus damage if someone's caught directly in initial stream
		if(ignited_morb.stat == DEAD)
			continue

		if(ishuman(ignited_morb))
			var/mob/living/carbon/human/H = ignited_morb //fixed :s

			if(weapon_cause_data)
				var/mob/user = weapon_cause_data.resolve_mob()
				if(user)
					var/area/thearea = get_area(user)
					if(user.faction == H.faction && !thearea?.statistic_exempt)
						H.attack_log += "\[[time_stamp()]\] <b>[key_name(user)]</b> shot <b>[key_name(H)]</b> with \a <b>[name]</b> in [get_area(user)]."
						user.attack_log += "\[[time_stamp()]\] <b>[key_name(user)]</b> shot <b>[key_name(H)]</b> with \a <b>[name]</b> in [get_area(user)]."
						if(weapon_cause_data.cause_name)
							H.track_friendly_fire(weapon_cause_data.cause_name)
						var/ff_msg = "[key_name(user)] shot [key_name(H)] with \a [name] in [get_area(user)]"
						var/ffl = "[ADMIN_JMP(user)] [ADMIN_PM(user)]"
						var/ff_living = TRUE
						if(H.stat == DEAD)
							ff_living = FALSE
						msg_admin_ff("[ff_msg] [ffl]", ff_msg, ff_living)
					else
						H.attack_log += "\[[time_stamp()]\] <b>[key_name(user)]</b> shot <b>[key_name(H)]</b> with \a <b>[name]</b> in [get_area(user)]."
						user.attack_log += "\[[time_stamp()]\] <b>[key_name(user)]</b> shot <b>[key_name(H)]</b> with \a <b>[name]</b> in [get_area(user)]."
						msg_admin_attack("[key_name(user)] shot [key_name(H)] with \a [name] in [get_area(user)] ([user.loc.x],[user.loc.y],[user.loc.z]).", user.loc.x, user.loc.y, user.loc.z)
				if(shoot_mob)
					shoot_mob.track_shot_hit(weapon_cause_data.cause_name, H)

		var/fire_intensity_resistance = ignited_morb.check_fire_intensity_resistance()
		var/firedamage = max(burn_dam - fire_intensity_resistance, 0)
		if(!firedamage)
			continue

		var/sig_result = SEND_SIGNAL(ignited_morb, COMSIG_LIVING_FLAMER_FLAMED, tied_reagent)

		if(!(sig_result & COMPONENT_NO_IGNITE))
			switch(fire_variant)
				if(FIRE_VARIANT_TYPE_B) //Armor Shredding Greenfire, super easy to pat out. 50 duration -> 10 stacks (1 pat/resist)
					ignited_morb.TryIgniteMob(round(tied_reagent.durationfire / 5), tied_reagent)
				else
					ignited_morb.TryIgniteMob(tied_reagent.durationfire, tied_reagent)

		if(sig_result & COMPONENT_NO_BURN)
			continue

		ignited_morb.last_damage_data = weapon_cause_data
		ignited_morb.apply_damage(firedamage, BURN)
		animation_flash_color(ignited_morb, tied_reagent.burncolor) //pain hit flicker

		var/msg = "Augh! You are roasted by the flames!"
		if(isxeno(ignited_morb))
			to_chat(ignited_morb, SPAN_XENODANGER(msg))
		else
			to_chat(ignited_morb, SPAN_HIGHDANGER(msg))

		if(shoot_mob)
			shoot_mob.track_damage(weapon_cause_data.cause_name, ignited_morb, firedamage)
			if(shoot_mob.faction == ignited_morb.faction)
				shoot_mob.track_friendly_damage(weapon_cause_data.cause_name, ignited_morb, firedamage)

	RegisterSignal(SSdcs, COMSIG_GLOB_WEATHER_CHANGE, PROC_REF(update_in_weather_status))

/obj/flamer_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	to_call = null
	tied_reagent = null
	tied_reagents = null
	. = ..()

/obj/flamer_fire/initialize_pass_flags(datum/pass_flags_container/PF)
	..()
	if(PF)
		PF.flags_pass = PASS_FLAGS_FLAME

/obj/flamer_fire/Crossed(atom/movable/atom_movable)
	atom_movable.handle_flamer_fire_crossed(src)

/obj/flamer_fire/proc/type_b_debuff_xeno_armor(mob/living/carbon/xenomorph/X)
	var/sig_result = SEND_SIGNAL(X, COMSIG_LIVING_FLAMER_CROSSED, tied_reagent)
	. = 1
	if(sig_result & COMPONENT_XENO_FRENZY)
		. = 0.8
	if(sig_result & COMPONENT_NO_IGNITE)
		. = 0.6
	X.armor_deflection_debuff = (X.armor_deflection + X.armor_deflection_buff) * 0.5 * . //At the moment this just directly sets the debuff var since it's the only interaction with it. In the future if the var is used more, usages of type_b_debuff_armor may need to be refactored (or just make them mutually exclusive and have the highest overwrite).

/mob/living/carbon/xenomorph/proc/reset_xeno_armor_debuff_after_time(mob/living/carbon/xenomorph/X, wait_ticks) //Linked onto Xenos instead of the fire so it doesn't cancel on fire deletion.
	spawn(wait_ticks)
	if(X.armor_deflection_debuff)
		X.armor_deflection_debuff = 0

/obj/flamer_fire/proc/set_on_fire(mob/living/M)
	if(!istype(M))
		return

	var/sig_result = SEND_SIGNAL(M, COMSIG_LIVING_FLAMER_CROSSED, tied_reagent)
	var/burn_damage = round(burnlevel * 0.5)
	switch(fire_variant)
		if(FIRE_VARIANT_TYPE_B) //Armor Shredding Greenfire, 2x tile damage (Equiavlent to UT)
			burn_damage = burnlevel
	var/fire_intensity_resistance = M.check_fire_intensity_resistance()

	if(!tied_reagent.fire_penetrating)
		burn_damage = max(burn_damage - fire_intensity_resistance * 0.5, 0)

	if(sig_result & COMPONENT_XENO_FRENZY)
		var/mob/living/carbon/xenomorph/X = M
		if(X.plasma_stored != X.plasma_max) //limit num of noise
			to_chat(X, SPAN_DANGER("The heat of the fire roars in your veins! KILL! CHARGE! DESTROY!"))
			X.emote("roar")
		X.plasma_stored = X.plasma_max

	if(!(sig_result & COMPONENT_NO_IGNITE) && burn_damage)
		switch(fire_variant)
			if(FIRE_VARIANT_TYPE_B) //Armor Shredding Greenfire, super easy to pat out. 50 duration -> 10 stacks (1 pat/resist)
				M.TryIgniteMob(round(tied_reagent.durationfire / 5), tied_reagent)
			else
				M.TryIgniteMob(tied_reagent.durationfire, tied_reagent)

	if(sig_result & COMPONENT_NO_BURN && !tied_reagent.fire_penetrating)
		burn_damage = 0

	if(!burn_damage)
		to_chat(M, SPAN_DANGER("You step over the flames."))
		return

	M.last_damage_data = weapon_cause_data
	M.apply_damage(burn_damage, BURN) //This makes fire stronk.

	var/variant_burn_msg = null
	switch(fire_variant) //Fire variant special message appends.
		if(FIRE_VARIANT_TYPE_B)
			if(isxeno(M))
				var/mob/living/carbon/xenomorph/X = M
				X.armor_deflection?(variant_burn_msg=" You feel the flames weakening your exoskeleton!"):(variant_burn_msg=" You feel the flaming chemicals eating into your body!")
	to_chat(M, SPAN_DANGER("You are burned![variant_burn_msg?"[variant_burn_msg]":""]"))
	M.updatehealth()

/obj/flamer_fire/proc/update_flame()
	var/light_intensity = 3
	if(burnlevel < 15 && flame_icon != "dynamic")
		color = "#c1c1c1" //make it darker to make show its weaker.
	light_color = color
	var/flame_level = 1
	switch(firelevel)
		if(1 to 9)
			flame_level = 1
			light_intensity = 2
		if(10 to 25)
			flame_level = 2
			light_intensity = 4
		if(25 to INFINITY)
			flame_level = 3
			light_intensity = 6
	switch(flame_icon)
		if("blue")
			light_color = COLOR_BRIGHT_BLUE
		if("white")
			light_color = COLOR_WHITE
		if("green")
			light_color = COLOR_LIME

	set_light_range_power_color(light_intensity, light_power, light_color)

	if(initial_burst)
		flame_level++ //the initial flame burst is 1 level higher for a small time

	icon_state = "[flame_icon]_[flame_level]"
	set_light(flame_level * 2)

/obj/flamer_fire/proc/un_burst_flame()
	initial_burst = FALSE
	update_flame()

/obj/flamer_fire/process(delta_time)
	var/turf/T = loc
	firelevel = max(0, firelevel)
	if(!istype(T)) //Is it a valid turf? Has to be on a floor
		qdel(src)
		return PROCESS_KILL
	var/damage = burnlevel*delta_time
	T.flamer_fire_act(damage)

	if(!firelevel)
		qdel(src)
		return

	update_flame()

	for(var/atom/thing in loc)
		thing.handle_flamer_fire(src, damage, delta_time)

	//This has been made a simple loop, for the most part flamer_fire_act() just does return, but for specific items it'll cause other effects.

	firelevel -= 2 + weather_smothering_strength //reduce the intensity by 2 as default or more if in weather ---- weather_smothering_strength is set as /datum/weather_event's fire_smothering_strength

	return

/obj/flamer_fire/proc/update_in_weather_status()
	SIGNAL_HANDLER
	var/turf/turf = get_turf(src)
	if(!turf)
		return
	if(SSparticle_weather.running_weather && turf.turf_flags & TURF_WEATHER)
		weather_smothering_strength = SSparticle_weather.running_weather.fire_smothering_strength
	else
		weather_smothering_strength = 0

/proc/fire_spread_recur(turf/target, datum/cause_data/cause_data, remaining_distance, direction, fire_lvl, burn_lvl, f_color, burn_sprite = "dynamic")
	var/direction_angle = dir2angle(direction)
	var/obj/flamer_fire/foundflame = locate() in target
	if(!foundflame)
		var/datum/reagent/R = new()
		R.intensityfire = burn_lvl
		R.durationfire = fire_lvl
		R.burn_sprite = burn_sprite
		R.burncolor = f_color
		new/obj/flamer_fire(target, cause_data, R)
	if(target.density)
		return

	for(var/spread_direction in GLOB.alldirs)

		var/spread_power = remaining_distance

		var/spread_direction_angle = dir2angle(spread_direction)

		var/angle = 180 - abs( abs( direction_angle - spread_direction_angle ) - 180 ) // the angle difference between the spread direction and initial direction

		switch(angle) //this reduces power when the explosion is going around corners
			if(0)
				//no change
			if(45)
				spread_power *= 0.75
			else //turns out angles greater than 90 degrees almost never happen. This bit also prevents trying to spread backwards
				continue

		switch(spread_direction)
			if(NORTH,SOUTH,EAST,WEST)
				spread_power--
			else
				spread_power -= 1.414 //diagonal spreading

		if(spread_power < 1)
			continue

		var/turf/T = get_step(target, spread_direction)

		if(!T) //prevents trying to spread into "null" (edge of the map?)
			continue

		spawn(0)
			fire_spread_recur(T, cause_data, spread_power, spread_direction, fire_lvl, burn_lvl, f_color, burn_sprite)

/proc/fire_spread(turf/target, datum/cause_data/cause_data, range, fire_lvl, burn_lvl, f_color, burn_sprite = "dynamic")
	var/datum/reagent/R = new()
	R.intensityfire = burn_lvl
	R.durationfire = fire_lvl
	R.burn_sprite = burn_sprite
	R.burncolor = f_color

	new/obj/flamer_fire(target, cause_data, R)
	for(var/direction in GLOB.alldirs)
		var/spread_power = range
		switch(direction)
			if(NORTH,SOUTH,EAST,WEST)
				spread_power--
			else
				spread_power -= 1.414 //diagonal spreading
		var/turf/T = get_step(target, direction)
		fire_spread_recur(T, cause_data, spread_power, direction, fire_lvl, burn_lvl, f_color, burn_sprite)
