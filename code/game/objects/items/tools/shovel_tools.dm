
//*****************************Shovels********************************/

/obj/item/tool/shovel
	name = "shovel"
	desc = "A large tool for digging and moving dirt."
	icon = 'icons/obj/items/items.dmi'
	icon_state = "shovel"
	item_state = "shovel"
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_WAIST
	force = 8
	throwforce = 4
	w_class = SIZE_MEDIUM
	matter = list("metal" = 50)

	attack_verb = list("bashed", "bludgeoned", "thrashed", "whacked")
	var/dirt_overlay = "dirt"
	var/folded = FALSE
	/// 0 for no dirt, 1 for brown dirt, 2 for snow, 3 for big red.
	var/dirt_type = NO_DIRT
	var/shovelspeed = 30
	var/dirt_amt = 0
	var/dirt_amt_per_dig = 6

/obj/item/tool/shovel/Initialize()
	. = ..()
	update_icon()

/obj/item/tool/shovel/update_icon()
	var/image/I = image(icon,src,"[icon_state]_[dirt_overlay]")
	switch(dirt_type) // We can actually shape the color for what enviroment we dig up our dirt in.
		if(DIRT_TYPE_GROUND) I.color = "#512A09"
		if(DIRT_TYPE_MARS) I.color = "#FF5500"
		if(DIRT_TYPE_SNOW) I.color = "#EBEBEB"
		if(DIRT_TYPE_SAND) I.color = "#ab804b"
		if(DIRT_TYPE_SHALE) I.color = "#1c2142"
	overlays -= I
	if(dirt_amt)
		overlays += I
	else
		I = null

/obj/item/tool/shovel/get_examine_text(mob/user)
	. = ..()
	if(dirt_amt)
		var/dirt_name = dirt_type == DIRT_TYPE_SNOW ? "snow" : "dirt"
		. += "It holds [dirt_amt] layer\s of [dirt_name]."

/obj/item/tool/shovel/attack_self(mob/user)
	..()
	add_fingerprint(user)

	if(dirt_amt)
		to_chat(user, SPAN_NOTICE("You dump the [dirt_type == DIRT_TYPE_SNOW ? "snow" : "dirt"]!"))
		if(dirt_type == DIRT_TYPE_SNOW)
			var/turf/T = get_turf(user.loc)
			var/obj/item/stack/snow/S = locate() in T
			if(S && S.amount < S.max_amount)
				S.amount += dirt_amt
			else
				new /obj/item/stack/snow(T, dirt_amt)
		dirt_amt = 0

	update_icon()


/obj/item/tool/shovel/afterattack(atom/target, mob/user, proximity)
	if(!proximity || folded)
		return

	if(user.action_busy)
		return

	if(!dirt_amt)
		if(istype(target, /turf))
			var/turf/T = target
			var/turfdirt = T.get_dirt_type()
			if(turfdirt)
				to_chat(user, SPAN_NOTICE("You start digging."))
				playsound(user.loc, 'sound/effects/thud.ogg', 40, 1, 6)
				if(!do_after(user, shovelspeed * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
					to_chat(user, SPAN_NOTICE("You stop digging."))
					return

				var/transfer_amount = dirt_amt_per_dig
				if(istype(T,/turf/open))
					var/turf/open/ot = T
					if(ot.bleed_layer)
						transfer_amount = min(ot.bleed_layer, dirt_amt_per_dig)
						if(istype(T, /turf/open/auto_turf))
							var/turf/open/auto_turf/AT = T
							AT.changing_layer(AT.bleed_layer - transfer_amount)
						else
							ot.bleed_layer -= transfer_amount
							ot.update_icon(1,0)
				to_chat(user, SPAN_NOTICE("You dig up some [dirt_type_to_name(turfdirt)]."))
				dirt_amt = transfer_amount
				dirt_type = turfdirt
				update_icon()

		else if(istype(target, /obj/structure/snow))
			var/obj/structure/snow/snow = target
			to_chat(user, SPAN_NOTICE("You start digging."))
			playsound(user.loc, 'sound/effects/thud.ogg', 40, 1, 6)
			if(!do_after(user, shovelspeed * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				to_chat(user, SPAN_NOTICE("You stop digging."))
				return

			var/transfer_amount = min(snow.bleed_layer, dirt_amt_per_dig)
			snow.changing_layer(snow.bleed_layer - transfer_amount)
			to_chat(user, SPAN_NOTICE("You dig up some [dirt_type_to_name(DIRT_TYPE_SNOW)]."))
			dirt_amt = transfer_amount
			dirt_type = DIRT_TYPE_SNOW
			update_icon()

	else
		dump_shovel(target, user)

/obj/item/tool/shovel/proc/dump_shovel(atom/target, mob/user)
	if(istype(target, /turf))
		var/turf/T = target
		to_chat(user, SPAN_NOTICE("You dump the [dirt_type_to_name(dirt_type)]!"))
		playsound(user.loc, "rustle", 30, 1, 6)
		if(dirt_type == DIRT_TYPE_SNOW)
			var/obj/item/stack/snow/S = locate() in T
			if(S && S.amount + dirt_amt < S.max_amount)
				S.amount += dirt_amt
			else
				new /obj/item/stack/snow(T, dirt_amt)
		dirt_amt = 0

	else if(istype(target, /obj/structure/snow) && dirt_type == DIRT_TYPE_SNOW)
		var/obj/structure/snow/snow = target
		if(snow.bleed_layer >= MAX_LAYER_SNOW_LEVELS)
			to_chat(user, SPAN_NOTICE("There no more space!"))
			return
		else
			to_chat(user, SPAN_NOTICE("You dump the [dirt_type_to_name(dirt_type)]!"))
			playsound(user.loc, "rustle", 30, 1, 6)
			snow.changing_layer(1)
			dirt_amt = 0

	update_icon()

/obj/item/tool/shovel/proc/dirt_type_to_name(dirt_type)
	switch(dirt_type)
		if(DIRT_TYPE_GROUND)
			return "dirt"
		if(DIRT_TYPE_MARS)
			return "red sand"
		if(DIRT_TYPE_SNOW)
			return "snow"
		if(DIRT_TYPE_SAND)
			return "sand"
		if(DIRT_TYPE_SHALE)
			return "loam"

/obj/item/tool/shovel/proc/check_dirt_type()
	if(dirt_amt <= 0)
		dirt_type = NO_DIRT
	return dirt_type

/obj/item/tool/shovel/spade
	name = "spade"
	desc = "A small tool for digging and moving dirt."
	icon_state = "spade"
	item_state = "spade"
	force = 5
	throwforce = 7
	w_class = SIZE_SMALL
	shovelspeed = 60
	dirt_amt_per_dig = 1


//Snow Shovel----------
/obj/item/tool/shovel/snow
	name = "snow shovel"
	desc = "I had enough winter for this year!"
	w_class = SIZE_LARGE
	force = 5
	throwforce = 3




// Entrenching tool.
/obj/item/tool/shovel/etool
	name = "entrenching tool"
	desc = "Used to dig holes and bash heads in. Folds in to fit in small spaces."
	icon = 'icons/obj/items/marine-items.dmi'
	icon_state = "etool"
	item_state = "etool"
	force = 30
	throwforce = 2
	w_class = SIZE_LARGE

	dirt_amt_per_dig = 5
	shovelspeed = 50

/obj/item/tool/shovel/etool/update_icon()
	if(folded)
		icon_state = "[icon_state]_c"
		item_state = "[item_state]_c"
	else
		icon_state = initial(icon_state)
		item_state = initial(item_state)
	..()

/obj/item/tool/shovel/etool/attack_self(mob/user as mob)
	folded = !folded
	if(folded)
		w_class = SIZE_SMALL
		force = 2
	else
		w_class = SIZE_LARGE
		force = 30
	..()

/obj/item/tool/shovel/etool/folded
	folded = TRUE
	w_class = SIZE_SMALL
	force = 2
