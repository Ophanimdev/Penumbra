/datum/antagonist/zombie
	name = "Zomble"
	antag_hud_type = ANTAG_HUD_TRAITOR
	antag_hud_name = "zombie"
	show_in_roundend = FALSE
	rogue_enabled = TRUE
	/// SET TO FALSE IF WE DON'T TURN INTO ROTMEN WHEN REMOVED
	var/become_rotman = FALSE
	var/zombie_start
	var/revived = FALSE
	var/next_idle_sound
	// CACHE VARIABLES SO ZOMBIFICATION CAN BE CURED
	var/was_i_undead = FALSE
	var/special_role
	var/ambushable = TRUE
	var/soundpack_m
	var/soundpack_f
	var/STASTR
	var/STASPD
	var/STAINT
	var/cmode_music
	var/list/base_intents
	/// Whether or not we have been turned
	var/has_turned = FALSE
	/// Last time we bit someone - Zombies will try to bite after 10 seconds of not biting
	var/last_bite
	/// Traits applied to the owner mob when we turn into a zombie
	var/static/list/traits_zombie = list(
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_NOROGSTAM,
		TRAIT_NOMOOD,
		TRAIT_NOHUNGER,
		TRAIT_EASYDISMEMBER,
		TRAIT_NOPAIN,
		TRAIT_NOPAINSTUN,
		TRAIT_NOBREATH,
		TRAIT_NOBREATH,
		TRAIT_TOXIMMUNE,
		TRAIT_CHUNKYFINGERS,
		TRAIT_NOSLEEP,
		TRAIT_BASHDOORS,
		TRAIT_SPELLCOCKBLOCK,
		TRAIT_BLOODLOSS_IMMUNE,
		TRAIT_ZOMBIE_SPEECH,
		TRAIT_ZOMBIE_IMMUNE,
		TRAIT_ROTMAN,
		TRAIT_NORUN
	)
	/// Traits applied to the owner when we are cured and turn into just "rotmen"
	var/static/list/traits_rotman = list(
		TRAIT_EASYDISMEMBER,
		TRAIT_NOPAIN,
		TRAIT_NOPAINSTUN,
		TRAIT_NOBREATH,
		TRAIT_TOXIMMUNE,
		TRAIT_ZOMBIE_IMMUNE,
		TRAIT_ROTMAN,
	)

/datum/antagonist/zombie/examine_friendorfoe(datum/antagonist/examined_datum,mob/examiner,mob/examined)
	if(istype(examined_datum, /datum/antagonist/vampirelord))
		var/datum/antagonist/vampirelord/V = examined_datum
		if(!V.disguised)
			return span_boldnotice("Another deadite.")
	if(istype(examined_datum, /datum/antagonist/zombie))
		var/datum/antagonist/zombie/fellow_zombie = examined_datum
		return span_boldnotice("Another deadite. [fellow_zombie.has_turned ? "My ally." : span_warning("Hasn't turned yet.")]")
	if(istype(examined_datum, /datum/antagonist/skeleton))
		return span_boldnotice("Another deadite.")

/datum/antagonist/zombie/on_gain()
	var/mob/living/carbon/human/zombie = owner?.current
	if(zombie)
		var/obj/item/bodypart/head = zombie.get_bodypart(BODY_ZONE_HEAD)
		if(!head)
			qdel(src)
			return
	zombie_start = world.time
	was_i_undead = zombie.mob_biotypes & MOB_UNDEAD
	special_role = zombie.mind?.special_role
	ambushable = zombie.ambushable
	if(zombie.dna?.species)
		soundpack_m = zombie.dna.species.soundpack_m
		soundpack_f = zombie.dna.species.soundpack_f
	base_intents = zombie.base_intents
	STASTR = zombie.STASTR
	STASPD = zombie.STASPD
	STAINT = zombie.STAINT
	cmode_music = zombie.cmode_music
	return ..()

/datum/antagonist/zombie/on_removal()
	var/mob/living/carbon/human/zombie = owner?.current
	if(zombie)
		zombie.verbs -= /mob/living/carbon/human/proc/zombie_seek
		zombie.mind?.special_role = special_role
		zombie.ambushable = ambushable
		if(zombie.dna?.species)
			zombie.dna.species.soundpack_m = soundpack_m
			zombie.dna.species.soundpack_f = soundpack_f
		zombie.base_intents = base_intents
		zombie.update_a_intents()
		zombie.aggressive = FALSE
		zombie.mode = AI_OFF
		if(zombie.charflaw)
			zombie.charflaw.ephemeral = FALSE
		zombie.update_body()
		zombie.STASTR = STASTR
		zombie.STASPD = STASPD
		zombie.STAINT = STAINT
		zombie.cmode_music = cmode_music
		for(var/trait in traits_zombie)
			REMOVE_TRAIT(zombie, trait, "[type]")
		zombie.remove_client_colour(/datum/client_colour/monochrome)
		if(has_turned && become_rotman)
			zombie.STACON = max(zombie.STACON - 2, 1) //ur rotting bro
			zombie.STASPD = max(zombie.STASPD - 3, 1)
			zombie.STAINT = max(zombie.STAINT - 3, 1)
			for(var/trait in traits_rotman)
				ADD_TRAIT(zombie, trait, "[type]")
			to_chat(zombie, span_green("I no longer crave for flesh... <i>But I still feel ill.</i>"))
		else
			if(!was_i_undead)
				zombie.mob_biotypes &= ~MOB_UNDEAD
			zombie.faction -= "undead"
			zombie.faction += "station"
			zombie.faction += "neutral"
			zombie.regenerate_organs()
			if(has_turned)
				to_chat(zombie, span_green("I no longer crave for flesh..."))
		for(var/obj/item/bodypart/zombie_part as anything in zombie.bodyparts)
			zombie_part.rotted = FALSE
			zombie_part.update_disabled()
			zombie_part.update_limb()
		zombie.update_body()
	// Bandaid to fix the zombie ghostizing not allowing you to re-enter
	if(zombie)
		var/mob/dead/observer/ghost = zombie.get_ghost(TRUE)
		if(ghost)
			ghost.can_reenter_corpse = TRUE
	return ..()

/datum/antagonist/zombie/proc/transform_zombie()
	var/mob/living/carbon/human/zombie = owner.current
	if(!zombie)
		qdel(src)
		return
	var/obj/item/bodypart/head = zombie.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		qdel(src)
		return
	revived = TRUE //so we can die for real later
	zombie.add_client_colour(/datum/client_colour/monochrome)
	for(var/trait_applied in traits_zombie)
		ADD_TRAIT(zombie, trait_applied, "[type]")
	if(zombie.mind)
		special_role = zombie.mind.special_role
		zombie.mind.special_role = name
	if(zombie.dna?.species)
		soundpack_m = zombie.dna.species.soundpack_m
		soundpack_f = zombie.dna.species.soundpack_f
		zombie.dna.species.soundpack_m = new /datum/voicepack/zombie/m()
		zombie.dna.species.soundpack_f = new /datum/voicepack/zombie/f()
	base_intents = zombie.base_intents
	zombie.base_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB, /datum/intent/unarmed/claw)
	zombie.update_a_intents()
	zombie.aggressive = TRUE
	zombie.mode = AI_IDLE
	zombie.handle_ai()
	ambushable = zombie.ambushable
	zombie.ambushable = FALSE

	if(zombie.charflaw)
		zombie.charflaw.ephemeral = TRUE
	zombie.mob_biotypes |= MOB_UNDEAD
	zombie.faction += "undead"
	zombie.faction -= "station"
	zombie.faction -= "neutral"
	zombie.verbs |= /mob/living/carbon/human/proc/zombie_seek
	for(var/obj/item/bodypart/zombie_part as anything in zombie.bodyparts)
		if(!zombie_part.rotted && !zombie_part.skeletonized)
			zombie_part.rotted = TRUE
		zombie_part.update_disabled()
	zombie.update_body()
	zombie.cmode_music = 'sound/music/combat_weird.ogg'

	// Reduce strength by 3
	zombie.STASTR = max(zombie.STASTR - 3, 1)

	// This is the original first commit values for it, aka 5-7
	zombie.STASPD = rand(5,7)

	zombie.STAINT = 1
	last_bite = world.time
	has_turned = TRUE
	// Drop your helm and gorgies boy you won't need it anymore!!!
	var/static/list/removed_slots = list(
		SLOT_HEAD,
		SLOT_WEAR_MASK,
		SLOT_MOUTH,
		SLOT_NECK,
	)
	for(var/slot in removed_slots)
		zombie.dropItemToGround(zombie.get_item_by_slot(slot), TRUE)


/datum/antagonist/zombie/greet()
	to_chat(owner.current, span_userdanger("Death is not the end..."))
	return ..()

/datum/antagonist/zombie/on_life(mob/user)
	if(!user || user.stat >= DEAD || !has_turned)
		return
	var/mob/living/carbon/human/zombie = user
	if(world.time > next_idle_sound)
		zombie.emote("idle")
		next_idle_sound = world.time + rand(5 SECONDS, 10 SECONDS)

//Infected wake param is just a transition from living to zombie, via zombie_infect()
//Previously you just died without warning in 3 minutes, now you just become an antag
/datum/antagonist/zombie/proc/wake_zombie(infected_wake = FALSE)
	testing("WAKEZOMBIE")
	if(!owner.current)
		return
	var/mob/living/carbon/human/zombie = owner.current
	if(!zombie || !istype(zombie))
		return
	var/obj/item/bodypart/head = zombie.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		qdel(src)
		return
	if(zombie.stat != DEAD && !infected_wake)
		qdel(src)
		return
	if(istype(zombie.loc, /obj/structure/closet/dirthole) || istype(zombie.loc, /obj/structure/closet/crate/coffin))
		qdel(src)
		return


	zombie.blood_volume = BLOOD_VOLUME_NORMAL
	zombie.setOxyLoss(0, updating_health = FALSE, forced = TRUE) //zombles dont breathe
	zombie.setToxLoss(0, updating_health = FALSE, forced = TRUE) //zombles are immune to poison
	if(!infected_wake) //if we died, heal all of this too
		zombie.adjustBruteLoss(-INFINITY, updating_health = FALSE, forced = TRUE)
		zombie.adjustFireLoss(-INFINITY, updating_health = FALSE, forced = TRUE)
		zombie.heal_wounds(INFINITY) //Heal every wound that is not permanent
	zombie.stat = UNCONSCIOUS //Start unconscious
	zombie.updatehealth() //then we check if the mob should wake up
	zombie.update_mobility()
	zombie.update_sight()
	zombie.reload_fullscreen()
	transform_zombie()
	if(zombie.stat >= DEAD)
		//could not revive
		qdel(src)

/mob/living/carbon/human/proc/zombie_seek()
	set name = "Seek Brains"
	set category = "ZOMBIE"

	if(!mind.has_antag_datum(/datum/antagonist/zombie))
		return FALSE
	if(stat >= UNCONSCIOUS)
		return FALSE
	var/closest_dist
	var/the_dir
	for(var/mob/living/carbon/human/humie as anything in GLOB.human_list)
		if(humie == src)
			continue
		if(humie.mob_biotypes & MOB_UNDEAD)
			continue
		if(humie.stat >= DEAD)
			continue
		var/total_distance = get_dist(src, humie)
		if(!closest_dist)
			closest_dist = total_distance
			the_dir = get_dir(src, humie)
		else
			if(total_distance < closest_dist)
				closest_dist = total_distance
				the_dir = get_dir(src, humie)
	if(!closest_dist)
		to_chat(src, span_warning("I failed to smell anything..."))
		return FALSE
	to_chat(src, span_warning("[closest_dist] meters away, [dir2text(the_dir)]..."))
	return TRUE

/// Use this to attempt to add the zombie antag datum to a human
/mob/living/carbon/human/proc/zombie_check()
	return FALSE // Completely disable zombie infection
	
	/* Original code left commented out for easy restoration later
	if(!mind)
		return
	var/already_zombie = mind.has_antag_datum(/datum/antagonist/zombie)
	if(already_zombie)
		return already_zombie
	if(mind.has_antag_datum(/datum/antagonist/vampirelord))
		return
	if(mind.has_antag_datum(/datum/antagonist/werewolf))
		return
	if(mind.has_antag_datum(/datum/antagonist/skeleton))
		return
	if(HAS_TRAIT(src, TRAIT_ZOMBIE_IMMUNE))
		return
	return mind.add_antag_datum(/datum/antagonist/zombie)
	*/

/**
 * This occurs when one zombie infects a living human, going into instadeath from here is kind of shit and confusing
 * We instead just transform at the end
 */
/mob/living/carbon/human/proc/zombie_infect_attempt()
	return FALSE // Completely disable zombie infection
	
	/* Original code left commented out for easy restoration later
	var/datum/antagonist/zombie/zombie_antag = zombie_check()
	if(!zombie_antag)
		return
	if(stat >= DEAD) //do shit the natural way i guess
		return
	to_chat(src, span_danger("I feel horrible... REALLY horrible..."))
	mob_timers["puke"] = world.time
	vomit(1, blood = TRUE, stun = FALSE)
	addtimer(CALLBACK(src, PROC_REF(wake_zombie)), 1 MINUTES)
	return zombie_antag
	*/

/mob/living/carbon/human/proc/wake_zombie()
	var/datum/antagonist/zombie/zombie_antag = mind?.has_antag_datum(/datum/antagonist/zombie)
	if(!zombie_antag || zombie_antag.has_turned)
		return FALSE
	flash_fullscreen("redflash3")
	to_chat(src, span_danger("It hurts... Is this really the end for me?"))
	emote("scream") // heres your warning to others bro
	Knockdown(1)
	zombie_antag.wake_zombie(TRUE)
	return TRUE
