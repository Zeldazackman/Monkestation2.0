/datum/job_milestone
	var/key_id = JOB_CAPTAIN
	var/list/milestones
	var/list/in_round_milestones


/datum/job_milestone/proc/check_milestones(level, client/user)
	if(!length(milestones) && !length(in_round_milestones))
		return
	if(!milestones[num2text(level)] && !in_round_milestones[num2text(level)])
		return

	if(milestones[num2text(level)])
		var/datum/milestone_type = milestones[level]

		//handles adding loadout items
		if(istype(milestone_type, /datum/loadout_item))
			var/datum/loadout_item/listed_loadout = milestone_type
			for(var/path in user.prefs.job_rewards_claimed[key_id])
				if(path == initial(milestone_type))
					return

			user.prefs.job_rewards_claimed[key_id] |= initial(milestone_type)
			if(!user.prefs.inventory[initial(listed_loadout.item_path)])
				user.prefs.inventory += initial(listed_loadout.item_path)
				var/datum/db_query/query_add_gear_purchase = SSdbcore.NewQuery({"
					INSERT INTO [format_table_name("metacoin_item_purchases")] (`ckey`, `item_id`, `amount`) VALUES (:ckey, :item_id, :amount)"},
					list("ckey" = user.ckey, "item_id" = initial(listed_loadout.item_path), "amount" = 1))
				if(!query_add_gear_purchase.Execute())
					to_chat(user, "Failed to add level up reward contact coders")
					qdel(query_add_gear_purchase)
					return FALSE
				qdel(query_add_gear_purchase)
			else
				user.prefs.inventory += initial(listed_loadout.item_path)
				var/datum/db_query/query_add_gear_purchase = SSdbcore.NewQuery({"
					UPDATE [format_table_name("metacoin_item_purchases")] SET amount = :amount WHERE ckey = :ckey AND item_id = :item_id"},
					list("ckey" = user.ckey, "item_id" = initial(listed_loadout.item_path), "amount" = 1))
				if(!query_add_gear_purchase.Execute())
					to_chat(user, "Failed to add level up reward contact coders")
					qdel(query_add_gear_purchase)
					return FALSE
				qdel(query_add_gear_purchase)
		user.prefs.save_preferences()

	if(in_round_milestones[num2text(level)])
		var/obj/item/temp = in_round_milestones[num2text(level)]
		var/obj/item/milestone_item = new temp
		if(!islist(user.prefs.job_rewards_per_round[key_id]))
			user.prefs.job_rewards_per_round[key_id] = list()
		user.prefs.job_rewards_per_round[key_id] += milestone_item.type
		user.prefs.save_preferences()
		qdel(milestone_item)

/client
	var/list/redeemed_rewards = list()

/client/verb/claim_job_reward()
	set category = "IC"
	set name = "Claim Job Rewards"
	set desc = "List job rewards you have for the current job and can spawn."

	if(!isliving(mob))
		to_chat(src, "For this to work you need to be living.")
		return

	var/datum/mind/listed_mob = mob.mind
	var/job_string = listed_mob.assigned_role.title

	if(!islist(mob.client.prefs.job_rewards_per_round[job_string]))
		to_chat(mob, span_notice("You currently don't have any job rewards to claim!"))
	var/list/viable_rewards = mob.client.prefs.job_rewards_per_round[job_string]
	if(length(mob.client.redeemed_rewards))
		for(var/path in mob.client.redeemed_rewards)
			var/path_to_text = "[path]"
			if(path_to_text in viable_rewards)
				viable_rewards -= path_to_text
	if(!length(viable_rewards))
		to_chat(mob, span_notice("You have redeemed all the rewards you have for this job."))

	var/list/name_and_path = list()
	for(var/path as anything in viable_rewards)
		var/obj/item/true_path = text2path(path)
		name_and_path[initial(true_path.name)] = true_path

	var/choice = tgui_input_list(mob, "Choose a reward to redeem.", "Job Reward Claim.", name_and_path)
	if(!choice)
		return

	var/path = name_and_path[choice]
	var/obj/item/new_item = new path(get_turf(mob))
	mob.client.redeemed_rewards += path

	if(ishuman(mob))
		var/mob/living/carbon/human/human_mob = mob
		human_mob.put_in_hands(new_item)
