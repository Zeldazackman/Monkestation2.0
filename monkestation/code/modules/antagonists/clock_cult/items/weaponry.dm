#define HAMMER_FLING_DISTANCE 2
#define HAMMER_THROW_FLING_DISTANCE 3

/obj/item/clockwork/weapon
	name = "clockwork weapon"
	desc = "Something"
	icon = 'monkestation/icons/obj/clock_cult/clockwork_weapons.dmi'
	lefthand_file = 'monkestation/icons/mob/clock_cult/clockwork_lefthand.dmi'
	righthand_file = 'monkestation/icons/mob/clock_cult/clockwork_righthand.dmi'
	worn_icon = 'monkestation/icons/mob/clock_cult/clockwork_garb_worn.dmi'
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 20
	throw_speed = 4
	armour_penetration = 10
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "pokes", "jabs", "tears", "gores")
	attack_verb_simple = list("attack", "poke", "jab", "tear", "gore")
	sharpness = SHARP_EDGED
	wound_bonus = -10 //wounds are really strong for clock cult, so im making their weapons slightly worse then normal at wounding
	/// Typecache of valid turfs to have the weapon's special effect on
	var/static/list/effect_turf_typecache = typecacheof(list(/turf/open/floor/bronze, /turf/open/indestructible/reebe_flooring))


/obj/item/clockwork/weapon/afterattack(mob/living/target, mob/living/user)
	. = ..()
	var/turf/gotten_turf = get_turf(user)

	if(!is_type_in_typecache(gotten_turf, effect_turf_typecache))
		return

	if((!QDELETED(target) && (!ismob(target) || (ismob(target) && target.stat != DEAD && !IS_CLOCK(target) && !target.can_block_magic(MAGIC_RESISTANCE_HOLY)))))
		hit_effect(target, user)


/obj/item/clockwork/weapon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(.)
		return

	if(!isliving(hit_atom))
		return

	var/mob/living/target = hit_atom

	if(!target.can_block_magic(MAGIC_RESISTANCE_HOLY) && !IS_CLOCK(target))
		hit_effect(target, throwingdatum.thrower, TRUE)


/// What occurs to non-holy people when attacked from brass tiles
/obj/item/clockwork/weapon/proc/hit_effect(mob/living/target, mob/living/user, thrown = FALSE)
	return


/obj/item/clockwork/weapon/brass_spear
	name = "brass spear"
	desc = "A razor-sharp spear made of brass. It thrums with barely-contained energy."
	icon_state = "ratvarian_spear"
	embedding = list("max_damage_mult" = 15, "armour_block" = 80)
	throwforce = 36
	force = 26
	armour_penetration = 24
	block_chance = 40
	clockwork_desc = "Can be summoned back to its last holder every 10 seconds if they are standing on bronze."
	///ref to our recall spell
	var/datum/action/cooldown/spell/summon_spear/our_summon = new
	///weakref to our current holder
	var/datum/weakref/current_holder

/obj/item/clockwork/weapon/brass_spear/Initialize(mapload)
	. = ..()

	RegisterSignal(src, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	our_summon.recalled_spear = src

/obj/item/clockwork/weapon/brass_spear/Destroy(force)
	UnregisterSignal(src, COMSIG_ITEM_PICKUP)
	QDEL_NULL(our_summon)
	return ..()

/obj/item/clockwork/weapon/brass_spear/proc/on_pickup(picked_up, mob/taker)
	SIGNAL_HANDLER

	if(taker == current_holder?.resolve())
		return

	current_holder = WEAKREF(taker)
	if(our_summon.owner)
		our_summon.Remove(our_summon.owner)
	if(!IS_CLOCK(taker))
		return
	if(!(locate(our_summon) in taker.actions)) //dont let them have multiple summons
		our_summon.Grant(taker)

/datum/action/cooldown/spell/summon_spear
	name = "Summon Brass Spear"
	desc = "Summons the last brass spear you picked up if you are currently standing on bronze."
	button_icon = 'monkestation/icons/obj/clock_cult/clockwork_weapons.dmi'
	button_icon_state = "ratvarian_spear"
	background_icon = 'monkestation/icons/mob/clock_cult/background_clock.dmi'
	background_icon_state = "bg_clock"
	overlay_icon_state = ""
	active_background_icon_state = "bg_clock_active"
	invocation_type = INVOCATION_NONE
	cooldown_time = 15 SECONDS
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	///ref to the spear we summon
	var/obj/item/clockwork/weapon/brass_spear/recalled_spear

/datum/action/cooldown/spell/summon_spear/Destroy()
	recalled_spear = null
	return ..()

/datum/action/cooldown/spell/summon_spear/can_cast_spell(feedback)
	. = ..()
	if(QDELETED(recalled_spear))
		qdel(src)
		return FALSE

	if(!recalled_spear)
		return FALSE

	if(!IS_CLOCK(owner))
		return FALSE

	var/turf/summoner_turf = get_turf(owner)
	if(!is_type_in_typecache(summoner_turf, recalled_spear?.effect_turf_typecache))
		if(feedback)
			to_chat(owner, span_brass("You need to be standing on bronze to do this."))
		return FALSE

/datum/action/cooldown/spell/summon_spear/cast(mob/living/cast_on)
	. = ..()

	recalled_spear.loc?.visible_message(span_warning("\The [recalled_spear] suddenly disappears!"))

	if(cast_on.put_in_hands(recalled_spear))
		recalled_spear.loc.visible_message(span_warning("[recalled_spear] suddenly appears in [cast_on]'s hand!"))
	else
		recalled_spear.forceMove(cast_on.drop_location())
		recalled_spear.loc.visible_message(span_warning("[recalled_spear] suddenly appears!"))
	playsound(get_turf(recalled_spear), 'sound/magic/summonitems_generic.ogg', 50, TRUE)

/obj/item/clockwork/weapon/brass_battlehammer
	name = "brass battle-hammer"
	desc = "A brass hammer glowing with energy."
	base_icon_state = "ratvarian_hammer"
	icon_state = "ratvarian_hammer0"
	throwforce = 25
	armour_penetration = 6
	attack_verb_simple = list("bash", "hammer", "attack", "smash")
	attack_verb_continuous = list("bashes", "hammers", "attacks", "smashes")
	clockwork_desc = "Enemies hit by this will be flung back while you are on bronze tiles."
	sharpness = FALSE
	hitsound = 'sound/weapons/smash.ogg'
	block_chance = 10


/obj/item/clockwork/weapon/brass_battlehammer/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, \
		force_unwielded = 15, \
		icon_wielded = "[base_icon_state]1", \
		force_wielded = 30, \
	)


/obj/item/clockwork/weapon/brass_battlehammer/hit_effect(mob/living/target, mob/living/user, thrown = FALSE)
	if((!thrown && !HAS_TRAIT(src, TRAIT_WIELDED)) || !istype(target))
		return

	var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))
	target.throw_at(throw_target, thrown ? HAMMER_THROW_FLING_DISTANCE : HAMMER_FLING_DISTANCE, 4)

/obj/item/clockwork/weapon/brass_battlehammer/update_icon_state()
	icon_state = "[base_icon_state]0"
	return ..()

/obj/item/clockwork/weapon/brass_sword
	name = "brass longsword"
	desc = "A large sword made of brass."
	icon_state = "ratvarian_sword"
	force = 26
	throwforce = 20
	armour_penetration = 12
	attack_verb_simple = list("attack", "slash", "cut", "tear", "gore")
	attack_verb_continuous = list("attacks", "slashes", "cuts", "tears", "gores")
	clockwork_desc = "Enemies and mechs will be struck with a powerful electromagnetic pulse while you are on bronze tiles, with a cooldown."
	block_chance = 35
	COOLDOWN_DECLARE(emp_cooldown)


/obj/item/clockwork/weapon/brass_sword/hit_effect(mob/living/target, mob/living/user, thrown)
	if(!COOLDOWN_FINISHED(src, emp_cooldown))
		return

	COOLDOWN_START(src, emp_cooldown, 30 SECONDS)

	target.emp_act(EMP_LIGHT)
	new /obj/effect/temp_visual/emp/pulse(target.loc)
	addtimer(CALLBACK(src, PROC_REF(send_message), user), 30 SECONDS)
	to_chat(user, span_brass("You strike [target] with an electromagnetic pulse!"))
	playsound(user, 'sound/magic/lightningshock.ogg', 40)


/obj/item/clockwork/weapon/brass_sword/attack_atom(obj/attacked_obj, mob/living/user, params)
	. = ..()
	var/turf/gotten_turf = get_turf(user)

	if(!ismecha(attacked_obj) || !is_type_in_typecache(gotten_turf, effect_turf_typecache))
		return

	if(!COOLDOWN_FINISHED(src, emp_cooldown))
		return

	COOLDOWN_START(src, emp_cooldown, 20 SECONDS)

	var/obj/vehicle/sealed/mecha/target = attacked_obj
	target.emp_act(EMP_HEAVY)
	new /obj/effect/temp_visual/emp/pulse(target.loc)
	addtimer(CALLBACK(src, PROC_REF(send_message), user), 20 SECONDS)
	to_chat(user, span_brass("You strike [target] with an electromagnetic pulse!"))
	playsound(user, 'sound/magic/lightningshock.ogg', 40)


/obj/item/clockwork/weapon/brass_sword/proc/send_message(mob/living/target)
	to_chat(target, span_brass("[src] glows, indicating the next attack will disrupt electronics of the target."))


/obj/item/gun/ballistic/bow/clockwork
	name = "brass bow"
	desc = "A bow made from brass and other components that you can't quite understand. It glows with a deep energy and frabricates arrows by itself. \
			It's bolts destabilize hit structures, making them lose additional integrity."
	icon = 'monkestation/icons/obj/clock_cult/clockwork_weapons.dmi'
	lefthand_file = 'monkestation/icons/mob/clock_cult/clockwork_lefthand.dmi'
	righthand_file = 'monkestation/icons/mob/clock_cult/clockwork_righthand.dmi'
	icon_state = "bow_clockwork_unchambered_undrawn"
	inhand_icon_state = "clockwork_bow"
	base_icon_state = "bow_clockwork"
	force = 10
	mag_type = /obj/item/ammo_box/magazine/internal/bow/clockwork
	/// Time between bolt recharges
	var/recharge_time = 1.5 SECONDS
	/// Typecache of valid turfs to have the weapon's special effect on
	var/static/list/effect_turf_typecache = typecacheof(list(/turf/open/floor/bronze, /turf/open/indestructible/reebe_flooring))

/obj/item/gun/ballistic/bow/clockwork/Initialize(mapload)
	. = ..()
	update_icon_state()
	AddElement(/datum/element/clockwork_description, "Firing from brass tiles will halve the time that it takes to recharge a bolt.")
	AddElement(/datum/element/clockwork_pickup)

/obj/item/gun/ballistic/bow/clockwork/afterattack(atom/target, mob/living/user, flag, params, passthrough)
	if(!drawn || !chambered)
		to_chat(user, span_notice("[src] must be drawn to fire a shot!"))
		return

	return ..()

/obj/item/gun/ballistic/bow/clockwork/can_trigger_gun(mob/living/user, akimbo_usage)
	return IS_CLOCK(user) //clock cultists should always be able to use their weapons

/obj/item/gun/ballistic/bow/clockwork/shoot_live_shot(mob/living/user, pointblank, atom/pbtarget, message)
	. = ..()
	var/turf/user_turf = get_turf(user)

	if(is_type_in_typecache(user_turf, effect_turf_typecache))
		recharge_time = 0.75 SECONDS

	addtimer(CALLBACK(src, PROC_REF(recharge_bolt)), recharge_time)
	recharge_time = initial(recharge_time)

/obj/item/gun/ballistic/bow/clockwork/attack_self(mob/living/user)
	if(drawn || !chambered)
		return

	if(!do_after(user, 0.5 SECONDS, src))
		return

	to_chat(user, span_notice("You draw back the bowstring."))
	drawn = TRUE
	playsound(src, 'sound/weapons/draw_bow.ogg', 75, 0) //gets way too high pitched if the freq varies
	update_icon()


/// Recharges a bolt, done after the delay in shoot_live_shot
/obj/item/gun/ballistic/bow/clockwork/proc/recharge_bolt()
	var/obj/item/ammo_casing/caseless/arrow/clockbolt/bolt = new
	magazine.give_round(bolt)
	chambered = bolt
	update_icon()


/obj/item/gun/ballistic/bow/clockwork/attackby(obj/item/I, mob/user, params)
	return


/obj/item/gun/ballistic/bow/clockwork/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[chambered ? "chambered" : "unchambered"]_[drawn ? "drawn" : "undrawn"]"


/obj/item/ammo_box/magazine/internal/bow/clockwork
	ammo_type = /obj/item/ammo_casing/caseless/arrow/clockbolt
	start_empty = FALSE


/obj/item/ammo_casing/caseless/arrow/clockbolt
	name = "energy bolt"
	desc = "An arrow made from a strange energy."
	icon = 'monkestation/icons/obj/clock_cult/ammo.dmi'
	icon_state = "arrow_redlight"
	projectile_type = /obj/projectile/energy/clockbolt


/obj/projectile/energy/clockbolt
	name = "energy bolt"
	icon = 'monkestation/icons/obj/clock_cult/projectiles.dmi'
	icon_state = "arrow_energy"
	damage = 25
	damage_type = BURN

//double damage to non clockwork structures and machines
/obj/projectile/energy/clockbolt/on_hit(atom/target, blocked, pierce_hit)
	if(ismob(target))
		var/mob/mob_target = target
		if(IS_CLOCK(mob_target)) //friendly fire is bad
			return

	. = ..()
	if(!.)
		return

	if(!QDELETED(target) && (istype(target, /obj/structure) || istype(target, /obj/machinery)) && !istype(target, /obj/structure/destructible/clockwork))
		target.update_integrity(target.get_integrity() - 25)

#undef HAMMER_FLING_DISTANCE
#undef HAMMER_THROW_FLING_DISTANCE
