/obj/item/weapon/gun/flare
	name = "M82-F flare gun"
	desc = "A flare gun issued to JTAC operators to use with flares. Comes with a miniscope. One shot, one... life saved?"
	icon_state = "m82f"
	item_state = "m82f"
	current_mag = /obj/item/ammo_magazine/internal/flare
	reload_sound = 'sound/weapons/gun_shotgun_shell_insert.ogg'
	fire_sound = 'sound/weapons/gun_flare.ogg'
	aim_slowdown = 0
	flags_equip_slot = SLOT_WAIST
	wield_delay = WIELD_DELAY_VERY_FAST
	movement_onehanded_acc_penalty_mult = MOVEMENT_ACCURACY_PENALTY_MULT_TIER_4
	flags_gun_features = GUN_INTERNAL_MAG|GUN_CAN_POINTBLANK
	gun_category = GUN_CATEGORY_HANDGUN
	attachable_allowed = list(/obj/item/attachable/scope/mini/flaregun)
	var/last_signal_flare_name

/obj/item/weapon/gun/flare/Initialize(mapload, spawn_empty)
	. = ..()
	if(spawn_empty)
		update_icon()

/obj/item/weapon/gun/flare/handle_starting_attachment()
	..()
	var/obj/item/attachable/scope/mini/flaregun/S = new(src)
	S.hidden = TRUE
	S.flags_attach_features &= ~ATTACH_REMOVABLE
	S.Attach(src)
	update_attachables()

/obj/item/weapon/gun/flare/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 12, "rail_y" = 20, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)

/obj/item/weapon/gun/flare/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_12)
	accuracy_mult = BASE_ACCURACY_MULT
	accuracy_mult_unwielded = BASE_ACCURACY_MULT - HIT_ACCURACY_MULT_TIER_10
	scatter = 0
	recoil = RECOIL_AMOUNT_TIER_4
	recoil_unwielded = RECOIL_AMOUNT_TIER_4

/obj/item/weapon/gun/flare/set_bullet_traits()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff)
	))

/obj/item/weapon/gun/flare/reload_into_chamber(mob/user)
	. = ..()
	to_chat(user, SPAN_WARNING("You pop out [src]'s tube!"))
	update_icon()

/obj/item/weapon/gun/flare/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/device/flashlight/flare))
		var/obj/item/device/flashlight/flare/F = I
		if(F.light_on)
			to_chat(user, SPAN_WARNING("You can't put a lit flare in [src]!"))
			return
		if(!F.fuel)
			to_chat(user, SPAN_WARNING("You can't put a burnt out flare in [src]!"))
			return
		if(current_mag && current_mag.ammo_position == 0)
			playsound(user, reload_sound, 25, 1)
			to_chat(user, SPAN_NOTICE("You load \the [F] into [src]."))
			var/obj/item/projectile/flare = new(current_mag)
			flare.ammo = F.ammo_datum
			flare.caliber = current_mag.caliber
			current_mag.ammo_position++
			current_mag.current_rounds[current_mag.ammo_position] = flare
			qdel(I)
			update_icon()
		else
			to_chat(user, SPAN_WARNING("\The [src] is already loaded!"))
	else if(istype(I, /obj/item/tool/weldingtool))
		var/obj/item/tool/weldingtool/WT = I
		if(do_after(user, 60 * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD) && !broken)
			if(WT.remove_fuel(3, user))
				to_chat(user, SPAN_NOTICE("Вы починили повреждения [src]."))
				durability += max_durability / 8
				durability_percentage()
				failure_probability--
			return
		to_chat(user, SPAN_NOTICE("[src] невозможно починить, для этого требуется специальное устройство."))
	else if(istype(I, /obj/item/prop/helmetgarb/gunoil))
		if(oil)
			to_chat(user, SPAN_NOTICE("[src] недавно смазано."))
			return
		var/obj/item/prop/helmetgarb/gunoil/GO = I
		var/oil_verb = pick("lubes", "oils", "cleans", "tends to", "gently strokes")
		if(do_after(user, 60 * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_GENERIC))
			if(GO.remove_oil(gun_category, user))
				user.visible_message("[user] [oil_verb] [src]. It shines like new.", "You oil up and immaculately clean [src]. It shines like new.")
				clean_blood()
				oil(oil_max/2,0.5)
		else
			return
	else
		to_chat(user, SPAN_WARNING("That's not a flare!"))

/obj/item/weapon/gun/flare/unload(mob/user)
	if(flags_gun_features & GUN_BURST_FIRING)
		return
	unload_flare(user)

/obj/item/weapon/gun/flare/proc/unload_flare(mob/user)
	if(!current_mag)
		return
	if(current_mag.ammo_position)
		var/obj/item/device/flashlight/flare/unloaded_flare = new ammo.handful_type(get_turf(src))
		playsound(user, reload_sound, 25, TRUE)
		var/obj/item/projectile/flare = current_mag.transfer_bullet_out()
		qdel(flare)
		if(user)
			to_chat(user, SPAN_NOTICE("You unload \the [unloaded_flare] from \the [src]."))
			user.put_in_hands(unloaded_flare)
		update_icon()

/obj/item/weapon/gun/flare/unique_action(mob/user)
	if(!user || !isturf(user.loc) || !current_mag || !current_mag.ammo_position)
		return

	var/turf/flare_turf = user.loc

	if(!(flare_turf.turf_flags & TURF_WEATHER))
		to_chat(user, SPAN_NOTICE("The roof above you is too dense."))
		return

	if(!istype(ammo, /datum/ammo/flare))
		to_chat(user, SPAN_NOTICE("\The [src] jams as it is somehow loaded with incorrect ammo!"))
		return

	if(user.action_busy)
		return

	if(!do_after(user, 1 SECONDS, INTERRUPT_ALL, BUSY_ICON_GENERIC))
		return

	var/obj/item/projectile/flare = current_mag.transfer_bullet_out()
	qdel(flare)

	var/datum/ammo/flare/explicit_ammo = ammo

	var/obj/item/device/flashlight/flare/fired_flare = new explicit_ammo.flare_type(get_turf(src))
	to_chat(user, SPAN_NOTICE("You fire \the [fired_flare] into the air!"))
	fired_flare.visible_message(SPAN_WARNING("\A [fired_flare] bursts into brilliant light in the sky!"))
	fired_flare.invisibility = INVISIBILITY_MAXIMUM
	fired_flare.mouse_opacity = FALSE
	playsound(user.loc, fire_sound, 50, 1)

	var/obj/effect/flare_light/light_effect = new (fired_flare, fired_flare.light_range, fired_flare.light_power, fired_flare.light_color)
	light_effect.RegisterSignal(fired_flare, COMSIG_ATOM_SET_LIGHT_ON, TYPE_PROC_REF(/obj/effect/flare_light, flare_light_change))

	if(fired_flare.activate_signal(user))
		last_signal_flare_name = fired_flare.name

	update_icon()

/obj/item/weapon/gun/flare/get_examine_text(mob/user)
	. = ..()
	if(last_signal_flare_name)
		. += SPAN_NOTICE("The last signal flare fired has the designation: [last_signal_flare_name]")

/obj/effect/flare_light
	name = "flare light"
	desc = "You are not supposed to see this. Please report it."
	icon_state = "" //No sprite
	invisibility = INVISIBILITY_MAXIMUM
	light_system = STATIC_LIGHT

/obj/effect/flare_light/Initialize(mapload, light_range, light_power, light_color)
	. = ..()
	set_light(light_range, light_power, light_color)

/obj/effect/flare_light/proc/flare_light_change(original_flare, new_light_value)
	if(!new_light_value)
		qdel(original_flare)
		qdel(src)
