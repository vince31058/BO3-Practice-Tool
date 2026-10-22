// Rev (Revelations) practice patches - ported from cbrnn's Rev Practice Tool v1.3.
// Each patch is picked from the Practice Patches menu instead of cycling in game.
// The detours below only change the game while one of these patches is loaded
// (level.rev_patch is set); otherwise they run the game's own code.
// This file: the Soft Patch, the code every Rev patch shares, and the detours.

GenesisSoftPatch()
{
    self RevPracticeStart("Soft Patch", ::rev_run_rev_soft_patch);
}

RevPracticeStart(patch_name, run_func)
{
    if(level.script != "zm_genesis")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Revelations");
        return;
    }
    level.rev_patch = patch_name;
    rev_init_dvars();
    WaitFadeIn();
    thread WriteToScreen("Rev " + patch_name + " Loaded");

    self [[run_func]]();
}

rev_init_dvars()
{
    // defaults for the dvars the Rev patches read (set them in the console to change)
    if(getdvarint("arnies_bug_round") == 0)
    {
        SetDvar("arnies_bug_round", 5);
    }
    if(getdvarint("use_basic_timer") == 0)
    {
        SetDvar("use_basic_timer", 0);
    }
}

rev_openalldoors()
{
	types = array("zombie_door", "zombie_airlock_buy", "zombie_debris");
	foreach(type in types)
	{
		doors = getentarray(type, "targetname");
		foreach(door in doors)
		{
			switch(type)
			{
				case "zombie_door":
					door thread zm_blockers::door_opened(door.zombie_cost, 0);
					break;
				case "zombie_airlock_buy":
					door thread rev_openairlock();
					break;
				case "zombie_debris":
					door thread rev_opendebris();
					break;
			}
		}
	}
	switch(level.script)
	{
		case "zm_island":
			gate = getent("pap_gate", "targetname");
			gate moveto(gate.s_pos.origin, 3);
			break;
	}
}

rev_opendebris()
{
	junk = getentarray(self.target, "targetname");
	if(isdefined(self.script_flag))
	{
		tokens = strtok(self.script_flag, ",");
		for(i = 0; i < tokens.size; i++)
		{
			level flag::set(tokens[i]);
		}
	}
	a_clip = [];
	for(i = 0; i < junk.size; i++)
	{
		junk[i] connectpaths();
		if(isdefined(junk[i].script_noteworthy))
		{
			if(junk[i].script_noteworthy == "clip")
			{
				a_clip[a_clip.size] = junk[i];
				continue;
			}
		}
		struct = undefined;
		if(junk[i] iszbarrier())
		{
			junk[i] thread zm_blockers::debris_zbarrier_move();
			continue;
		}
		if(isdefined(junk[i].script_linkto))
		{
			struct = struct::get(junk[i].script_linkto, "script_linkname");
			if(isdefined(struct))
			{
				junk[i] thread zm_blockers::debris_move(struct);
			}
			else
			{
				junk[i] delete();
			}
			continue;
		}
		if(isdefined(junk[i].target))
		{
			struct = struct::get(junk[i].target, "targetname");
			if(isdefined(struct))
			{
				junk[i] thread zm_blockers::debris_move(struct);
			}
			else
			{
				junk[i] delete();
			}
			continue;
		}
		junk[i] delete();
	}
	a_nd_targets = getnodearray(self.target, "targetname");
	foreach(nd_target in a_nd_targets)
	{
		if(isdefined(nd_target.script_noteworthy) && nd_target.script_noteworthy == "air_buy_gate")
		{
			linktraversal(nd_target);
		}
	}
	all_trigs = getentarray(self.target, "target");
	all_trigs[0] delete();
	for(i = 0; i < a_clip.size; i++)
	{
		a_clip[i] delete();
	}
}

rev_openairlock()
{
	if(isdefined(self.script_flag))
	{
		tokens = strtok(self.script_flag, ",");
		for(i = 0; i < tokens.size; i++)
		{
			level flag::set(tokens[i]);
		}
	}
	for(i = 0; i < self.trigs.size; i++)
	{
		self.trigs[i] triggerenable(1);
		self.trigs[i] thread rev_changedoormodels();
	}
	all_trigs = getentarray(self.target, "target");
	for(i = 0; i < all_trigs.size; i++)
	{
		all_trigs[i] triggerenable(0);
	}
}

rev_changedoormodels()
{
	doors = getentarray(self.target, "targetname");
	for(i = 0; i < doors.size; i++)
	{
		if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_lt_locked")
		{
			doors[i] setmodel("p7_zm_moo_door_airlock_heavy_lt");
		}
		else if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_rt_locked")
		{
			doors[i] setmodel("p7_zm_moo_door_airlock_heavy_rt");
		}
		else if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_single_locked")
		{
			doors[i] setmodel("p7_zm_moo_door_airlock_heavy_single");
		}
		doors[i] thread rev_airlockconnectpaths();
	}
}

rev_airlockconnectpaths()
{
	if(self.classname == "script_brushmodel")
	{
		self notsolid();
		self connectpaths();
		if(!isdefined(self._door_open) || self._door_open == 0)
		{
			self solid();
		}
	}
}

rev_openallpower()
{
	level flag::set("power_on");
	power_trigs = getentarray("use_elec_switch", "targetname");
	foreach(trig in power_trigs)
	{
		if(isdefined(trig.script_int))
		{
			level flag::set("power_on" + trig.script_int);
			level clientfield::set("zombie_power_on", trig.script_int);
		}
	}
	foreach(obj in array("elec", "power", "master"))
	{
		trigs = getentarray("use_elec_switch", "targetname");
		if(isdefined(trigs))
		{
			foreach(trig in trigs)
			{
				trig notify("trigger", level.players[0]);
			}
		}
	}
	count = 0;
	foreach(generator in struct::get_array("s_generator", "targetname"))
	{
		count++;
		if(count != 3)
		{
			generator rev_capturegenerator(self);
			wait(0.5);
		}
	}
}

rev_capturegenerator(player)
{
	level.zone_capture.last_zone_captured = self;
	self rev_setplayercontrolledzone();
	self.n_current_progress = 100;
	level clientfield::set("state_" + self.script_noteworthy, 2);
	level clientfield::set(self.script_noteworthy, self.n_current_progress / 100);
}

rev_setplayercontrolledzone()
{
	if(!self flag::get("player_controlled"))
	{
		foreach(e_player in level.players)
		{
			e_player thread zm_craftables::player_show_craftable_parts_ui(undefined, "zmInventory.capture_generator_wheel_widget", 0);
		}
	}
	self flag::set("player_controlled");
	self flag::clear("attacked_by_recapture_zombies");
	level clientfield::set("zone_capture_hud_generator_" + self.script_int, 1);
	level clientfield::set("zone_capture_monolith_crystal_" + self.script_int, 0);
	if(!isdefined(self.perk_fx_func) || [[ self.perk_fx_func ]]())
	{
		level clientfield::set("zone_capture_perk_machine_smoke_fx_" + self.script_int, 1);
	}
	self flag::set("player_controlled");
	rev_updatecapturedzonecount();
	self rev_enableperksinzone();
	self rev_enablerandomperksinzone();
	self rev_enableboxinzone();
	level flag::set("power_on" + self.script_int);
	level notify("zone_captured_by_player", self.str_zone);
}

rev_updatecapturedzonecount()
{
	level.total_capture_zones = rev_getcapturedzonecount();
	if(level.total_capture_zones == 6)
	{
		level flag::set("all_zones_captured");
	}
	else
	{
		level flag::clear("all_zones_captured");
	}
}

rev_getcapturedzonecount()
{
	n_player_controlled_zones = 0;
	foreach(generator in level.zone_capture.zones)
	{
		if(generator flag::get("player_controlled"))
		{
			n_player_controlled_zones++;
		}
	}
	return n_player_controlled_zones;
}

rev_enableperksinzone()
{
	if(isdefined(self.perk_machines) && isarray(self.perk_machines))
	{
		a_keys = getarraykeys(self.perk_machines);
		for(i = 0; i < a_keys.size; i++)
		{
			level notify(a_keys[i] + "_on");
		}
		for(i = 0; i < a_keys.size; i++)
		{
			e_perk_trigger = self.perk_machines[a_keys[i]];
			e_perk_trigger.is_locked = 0;
			e_perk_trigger zm_perks::reset_vending_hint_string();
		}
	}
}

rev_enablerandomperksinzone()
{
	if(isdefined(self.perk_machines_random) && isarray(self.perk_machines_random))
	{
		foreach(random_perk_machine in self.perk_machines_random)
		{
			random_perk_machine.is_locked = 0;
			if(IsTrue(random_perk_machine.current_perk_random_machine))
			{
				random_perk_machine rev_set_perk_random_machine_state("idle");
				continue;
			}
			random_perk_machine rev_set_perk_random_machine_state("away");
		}
	}
}

rev_set_perk_random_machine_state(state)
{
	wait(0.1);
	for(i = 0; i < self getnumzbarrierpieces(); i++)
	{
		self hidezbarrierpiece(i);
	}
	self notify("zbarrier_state_change");
	self [[ level.perk_random_machine_state_func ]](state);
}

rev_enableboxinzone()
{
	foreach(mystery_box in self.mystery_boxes)
	{
		mystery_box.is_locked = 0;
		mystery_box.zbarrier [[ level.magic_box_zbarrier_state_func ]]("player_controlled");
		mystery_box.zbarrier clientfield::set("magicbox_runes", 1);
	}
}

detour zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_24240140()
{
	self setcandamage(1);
	while(1)
	{
		self waittill("damage", n_damage, e_attacker, v_dir, v_loc, str_type, str_model, str_tag, str_part, w_weapon, n_flags);
		if(isdefined(w_weapon) && w_weapon.name != "idgun_genesis_0_upgraded")
		{
			b_upgraded = zm_weapons::is_weapon_upgraded(w_weapon);
			if(b_upgraded)
			{
				if(isdefined(level.rev_patch))
				{
					iprintln("Rock Hit");
				}
				break;
			}
		}
	}
	self playsound("zmb_main_reel3_bone_brick_smash");
	self setmodel(self.script_string);
	if(isdefined(self.script_int))
	{
		self.angles += (0, self.script_int, 0);
	}
	self playloopsound("zmb_main_reel3_bone_lp", 1);
	self thread [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_0958fb16 ]]();
	v_position = [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_04e44f01 ]](self.origin, 1);
	self notify(#"hash_d940112c");
	wait(1);
	self moveto(v_position, 3);
	wait(3);
	playsoundatposition("zmb_main_reel3_bone_disappear", self.origin);
	self stoploopsound(2);
	self [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_156b5313 ]]();
}

rev_custom_cleanup()
{
	level lui::screen_flash(0.2, 0.5, 1, 0.8, "white");
	wait(0.2);
	margwas = getaiarchetypearray("margwa", level.zombie_team);
	cleaned_m = 0;
	foreach(margwa in margwas)
	{
		if(isalive(margwa))
		{
			margwa kill();
			cleaned_m++;
		}
	}
	if(cleaned_m == 0)
	{
		level.ik_counter++;
	}
	wait(0.1);
	foreach(zombie in getaiteamarray(level.zombie_team))
	{
		zombie kill();
	}
}

detour zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_655271b9()
{
	if(!isdefined(level.rev_patch))
	{
		// no Rev practice patch loaded: the game's own boss rush (zm_genesis_arena::function_655271b9)
		level notify(#"hash_f115a4c8");
		a_n_zombies_per_phase = array(6, 8, 10, 12);
		a_n_spawn_rate = array(4, 5, 6, 8);
		level.var_beccbadb = 0;
		level.var_c4133b63 = 2;
		level.var_de72c885 = 0;
		level.var_a0135c54 = a_n_spawn_rate[0];
		level.var_435967f3 = 0;
		level.var_e10b491b = 1;
		level.var_359cfe42 = 0;
		level.var_b9b689ce = 3;
		level.var_8e402c12 = a_n_zombies_per_phase[0];
		a_s_teleports = struct::get_array("dark_arena_teleport_hijack", "targetname");
		for(i = 0; i < level.activeplayers.size; i++)
		{
			level.activeplayers[i] thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_56668973 ]](a_s_teleports[i]);
		}
		level thread [[ @zm_genesis_sound<scripts\zm\zm_genesis_sound.gsc>::function_936d084f ]]();
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_07719ec7 ]](4);
		wait(4);
		level flag::set("boss_rush_phase_1");
		level notify(#"hash_f115a4c8");
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_389f8efe ]]();
		for(i = 0; i < level.var_6000c357.size; i++)
		{
			clientfield::set("summoning_key_charge_state", i);
			level flag::set("arena_vanilla_zombie_override");
			if(i > 0)
			{
				level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_07719ec7 ]](15);
				wait(15);
			}
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_7b82ff07 ]](6);
			n_element = level.var_6000c357[i];
			level.var_8e402c12 = a_n_zombies_per_phase[i];
			level.var_a0135c54 = a_n_spawn_rate[i];
			level clientfield::set("circle_challenge_identity", n_element);
			level clientfield::set("arena_state", 2);
			level clientfield::set("circle_state", 3);
			level flag::clear("arena_vanilla_zombie_override");
			func_challenge = level.var_43e34f20[n_element];
			level thread [[ func_challenge ]](n_element, 0, 0, 1);
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_d9624751 ]]();
			level waittill(#"hash_e59686ee");
			playsoundatposition("zmb_bossrush_round_over", (0, 0, 0));
			level.var_d90687be thread [[ @namespace_d90687be<scripts\zm\zm_genesis_arena.gsc>::function_b4aac082 ]]();
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_7b82ff07 ]](6);
		}
		wait(1);
		level.var_d90687be thread [[ @namespace_d90687be<scripts\zm\zm_genesis_arena.gsc>::function_b4aac082 ]]();
		level thread [[ @zm_genesis_sound<scripts\zm\zm_genesis_sound.gsc>::function_d73dcf42 ]]();
		wait(3);
		playsoundatposition("zmb_main_completion_big", (0, 0, 0));
		level flag::clear("boss_rush_phase_1");
		level notify(#"hash_07af29ab");
		return;
	}
	level notify(#"hash_f115a4c8");
	a_n_zombies_per_phase = array(6, 8, 10, 12);
	a_n_spawn_rate = array(4, 5, 6, 8);
	level.var_beccbadb = 0;
	level.var_c4133b63 = 2;
	level.var_de72c885 = 0;
	level.var_a0135c54 = a_n_spawn_rate[0];
	level.var_435967f3 = 0;
	level.var_e10b491b = 1;
	level.var_359cfe42 = 0;
	level.var_b9b689ce = 3;
	level.var_8e402c12 = a_n_zombies_per_phase[0];
	a_s_teleports = struct::get_array("dark_arena_teleport_hijack", "targetname");
	for(i = 0; i < level.activeplayers.size; i++)
	{
		level.activeplayers[i] thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_56668973 ]](a_s_teleports[i]);
	}
	level thread [[ @zm_genesis_sound<scripts\zm\zm_genesis_sound.gsc>::function_936d084f ]]();
	level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_07719ec7 ]](4);
	wait(4);
	level flag::set("boss_rush_phase_1");
	level notify(#"hash_f115a4c8");
	level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_389f8efe ]]();
	level.first_passed = 0;
	n_phases = 250;
	b_boss1 = 1;
	if(level.rev_patch != "Boss 1 Practice")
	{
		n_phases = 4;
		b_boss1 = 0;
	}
	for(i = 0; i < n_phases; i++)
	{
		i %= 4;
		clientfield::set("summoning_key_charge_state", i);
		level flag::set("arena_vanilla_zombie_override");
		if(i > 0 || level.first_passed == 1)
		{
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_07719ec7 ]](15);
			wait(15);
		}
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_7b82ff07 ]](6);
		n_element = level.var_6000c357[i];
		level.var_8e402c12 = a_n_zombies_per_phase[i];
		level.var_a0135c54 = a_n_spawn_rate[i];
		level clientfield::set("circle_challenge_identity", n_element);
		level clientfield::set("arena_state", 2);
		level clientfield::set("circle_state", 3);
		level flag::clear("arena_vanilla_zombie_override");
		func_challenge = level.var_43e34f20[n_element];
		level thread [[ func_challenge ]](n_element, 0, 0, 1);
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_d9624751 ]]();
		level waittill(#"hash_e59686ee");
		playsoundatposition("zmb_bossrush_round_over", (0, 0, 0));
		rev_custom_cleanup();
		level.phase_counter++;
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_7b82ff07 ]](6);
		level.first_passed = 1;
		if(b_boss1)
		{
			zm_powerups::specific_powerup_drop("full_ammo", level.players[0].origin);
		}
	}
	wait(1);
	rev_custom_cleanup();
	level thread [[ @zm_genesis_sound<scripts\zm\zm_genesis_sound.gsc>::function_d73dcf42 ]]();
	wait(3);
	playsoundatposition("zmb_main_completion_big", (0, 0, 0));
	level flag::clear("boss_rush_phase_1");
	level notify(#"hash_07af29ab");
}

detour zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_3d57dcdd()
{
	level endon("book_runes_failed");
	level endon("book_runes_success");
	if(!isdefined(level.rev_patch))
	{
		// no Rev practice patch loaded: the game's own book runes (zm_genesis_ee_quest::function_3d57dcdd)
		a_mdl_runes = [];
		for(i = 0; i < level.var_6000c357.size; i++)
		{
			s_rune = struct::get("ee_book_runes_correct_0" + (i + 1), "targetname");
			mdl_rune = util::spawn_model("tag_origin", s_rune.origin, s_rune.angles);
			a_mdl_runes[a_mdl_runes.size] = mdl_rune;
			level thread util::delete_on_death_or_notify(mdl_rune, "book_runes_failed");
			level thread util::delete_on_death_or_notify(mdl_rune, "book_runes_success");
		}
		while(level.var_be50c24f < level.var_6000c357.size)
		{
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_e3fb6380 ]]();
			self waittill("trigger_activated", e_player);
			if(isdefined(level.var_63fa69fd))
			{
				level notify(#"hash_6760e3ae");
				level clientfield::set("arena_timeout_warning", 0);
				if(level.var_63fa69fd == level.var_6000c357[level.var_be50c24f])
				{
					a_mdl_runes[level.var_be50c24f] setmodel("p7_zm_gen_rune_" + (level.var_63fa69fd + 1) + "_yellow");
					level.var_5da45153 = array::exclude(level.var_5da45153, level.var_63fa69fd);
					level.var_be50c24f++;
					e_player playsound("zmb_main_bookish_rune_choose_good");
					level notify(#"hash_ef87390a");
				}
				else
				{
					e_player playsound("zmb_main_bookish_rune_choose_fail");
					wait(1.4);
					level flag::set("book_runes_failed");
				}
			}
		}
		wait(1.4);
		level flag::set("book_runes_success");
		return;
	}
	a_mdl_runes = [];
	for(i = 0; i < level.var_6000c357.size; i++)
	{
		s_rune = struct::get("ee_book_runes_correct_0" + (i + 1), "targetname");
		mdl_rune = util::spawn_model("tag_origin", s_rune.origin, s_rune.angles);
		if(!isdefined(a_mdl_runes))
		{
			a_mdl_runes = [];
		}
		else if(!isarray(a_mdl_runes))
		{
			a_mdl_runes = array(a_mdl_runes);
		}
		a_mdl_runes[a_mdl_runes.size] = mdl_rune;
		level thread util::delete_on_death_or_notify(mdl_rune, "book_runes_failed");
		level thread util::delete_on_death_or_notify(mdl_rune, "book_runes_success");
	}
	iprintlnbold("Spam Symbols");
	while(level.var_be50c24f < level.var_6000c357.size)
	{
		level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_e3fb6380 ]]();
		self waittill("trigger_activated", e_player);
		if(isdefined(level.var_63fa69fd))
		{
			level notify(#"hash_6760e3ae");
			level clientfield::set("arena_timeout_warning", 0);
			a_mdl_runes[level.var_be50c24f] setmodel("p7_zm_gen_rune_" + (level.var_63fa69fd + 1) + "_yellow");
			level.var_5da45153 = array::exclude(level.var_5da45153, level.var_63fa69fd);
			level.var_be50c24f++;
			e_player playsound("zmb_main_bookish_rune_choose_good");
			level notify(#"hash_ef87390a");
		}
	}
	setdvar("timescale", 1);
	level.players[0] thread rev_ignore_player(0);
	rev_custom_cleanup();
	level.players[0] disableinvulnerability();
	wait(1.4);
	level flag::set("book_runes_success");
}

detour zm_genesis_keeper_companion<scripts\zm\zm_genesis_keeper_companion.gsc>::function_dbc32a6d()
{
	a_s_totems = struct::get_array("companion_totem_part", "targetname");
	level.flag_index = randomint(a_s_totems.size);
	s_totem = a_s_totems[level.flag_index];
	s_totem.n_scale = 0.75;
	s_totem.var_fdb628a4 = "keeper_callbox_totem";
	s_totem.v_offset = vectorscale((0, 0, 1), 20);
	s_totem thread function_085555c9();
	level.flag_part = s_totem;
	a_s_heads = struct::get_array("companion_head_part", "targetname");
	level.head_index = randomint(a_s_heads.size);
	s_head = a_s_heads[level.head_index];
	s_head.n_scale = 1.5;
	s_head.var_fdb628a4 = "keeper_callbox_head";
	s_head thread function_085555c9();
	level.head_part = s_head;
	a_s_gems = struct::get_array("companion_gem_part", "targetname");
	level.gem_index = randomint(a_s_gems.size);
	s_gem = a_s_gems[level.gem_index];
	s_gem.n_scale = 2;
	s_gem.var_fdb628a4 = "keeper_callbox_gem";
	s_gem thread function_085555c9();
	level.gem_part = s_gem;
}

function_085555c9()
{
	level flag::init(self.var_fdb628a4 + "_found");
	mdl_part = util::spawn_model(self.model, self.origin, self.angles);
	mdl_part setscale(self.n_scale);
	s_unitrigger = self zm_unitrigger::create_unitrigger(&"ZM_GENESIS_CALLBOX_PICKUP_PART", 64, ::function_fe778474);
	zm_unitrigger::unitrigger_force_per_player_triggers(s_unitrigger, 1);
	if(isdefined(self.v_offset))
	{
		s_unitrigger.origin += self.v_offset;
	}
	s_unitrigger flag::init("part_picked_up");
	self waittill("trigger_activated", e_player);
	self thread function_49da2964(e_player);
	level.var_d1d9fa3c++;
	s_unitrigger flag::set("part_picked_up");
	if(level.var_d1d9fa3c >= 3)
	{
		level flag::set("companion_box_parts_collected");
	}
	zm_unitrigger::unregister_unitrigger(s_unitrigger);
	mdl_part delete();
	self struct::delete();
}

function_fe778474(e_player)
{
	if(self.stub flag::get("part_picked_up"))
	{
		self sethintstring(&"");
		return 0;
	}
	if(level flag::get("companion_box_parts_collected"))
	{
		self sethintstring(&"");
		return 0;
	}
	self sethintstring(&"ZM_GENESIS_CALLBOX_PICKUP_PART");
	return 1;
}

function_49da2964(e_player)
{
	level flag::set(self.var_fdb628a4 + "_found");
	level clientfield::set(self.var_fdb628a4, 1);
	e_player playsound("zmb_keeper_callbox_pickup");
	level notify("widget_ui_override");
	foreach(e_player in level.players)
	{
		e_player thread function_3ab53b5c("zmInventory.player_keeper_protector", "zmInventory.widget_keeper_protector_parts", 0);
	}
	e_player notify("player_got_keeper_companion_piece");
}

function_3ab53b5c(str_crafted_clientuimodel, str_widget_clientuimodel, b_is_crafted)
{
	self endon("disconnect");
	if(b_is_crafted)
	{
		if(isdefined(str_crafted_clientuimodel))
		{
			self thread clientfield::set_player_uimodel(str_crafted_clientuimodel, 1);
		}
		n_show_ui_duration = 3.5;
	}
	else
	{
		n_show_ui_duration = 3.5;
	}
	self thread clientfield::set_player_uimodel(str_widget_clientuimodel, 1);
	level util::waittill_any_ex(n_show_ui_duration, "widget_ui_override", self, "disconnect");
	self thread clientfield::set_player_uimodel(str_widget_clientuimodel, 0);
}

detour zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_be26578d(n_audio)
{
	a_s_spots = struct::get_array("audio1_start", "targetname");
	if(!isdefined(level.rev_patch))
	{
		// no Rev practice patch loaded: random spot, like the game
		s_spot = array::random(a_s_spots);
	}
	else
	{
		while(!isdefined(level.flag_index))
		{
			wait(0.05);
		}
		if(level.flag_index == 0)
		{
			level.rock_index = 2;
		}
		else
		{
			level.rock_index = 0;
		}
		s_spot = a_s_spots[level.rock_index];
	}
	v_offset = vectorscale((0, 0, 1), 20);
	mdl_shard = util::spawn_model("p7_zm_gen_horror_shards_kit_03_h", s_spot.origin - v_offset, s_spot.angles);
	util::wait_network_frame();
	mdl_shard moveto(s_spot.origin, 15);
	mdl_shard waittill("movedone");
	while(1)
	{
		if(isdefined(level.ai_companion) && isalive(level.var_bfd9ed83))
		{
			if(level.ai_companion.reviving_a_player === 1 || level.ai_companion.b_teleporting === 1 || isdefined(level.ai_companion.traversestartnode))
			{
				wait(0.1);
				continue;
			}
			if(distancesquared(level.var_bfd9ed83.origin, mdl_shard.origin) < 2500 && distancesquared(level.ai_companion.origin, mdl_shard.origin) < 40000)
			{
				b_success = level.ai_companion [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_3877f225 ]](mdl_shard);
				if(b_success)
				{
					break;
				}
			}
		}
		wait(0.5);
	}
	s_target = struct::get(s_spot.target, "targetname");
	s_target thread [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_0bde2ec4 ]](n_audio);
	mdl_shard delete();
	level flag::wait_till("placed_audio" + n_audio);
	foreach(s_spot in a_s_spots)
	{
		s_spot struct::delete();
	}
}

rev_ms_to_str(ms)
{
	min = 0;
	sec = 0;
	if(ms >= 60000)
	{
		min = int(ms / 60000);
		ms -= min * 60000;
	}
	if(ms >= 1000)
	{
		sec = int(ms / 1000);
		ms -= sec * 1000;
	}
	time = "";
	if(min > 0)
	{
		time += (min + ":");
	}
	if(min || sec > 0)
	{
		if(sec < 10 && min)
		{
			time += "0";
		}
		time += (sec + ".");
	}
	if(min || sec || ms > 0)
	{
		if(!min && !sec)
		{
			time += "0.";
		}
		if(ms <= 50)
		{
			time += "0";
		}
		ms /= 10;
		time += ms;
	}
	return time;
}

rev_wait_de_leave()
{
	for(;;)
	{
		if(!IsTrue(self.var_5aef0317))
		{
			wait(0.05);
			continue;
		}
		while(!IsTrue(self.streamer_hint))
		{
			wait(0.05);
		}
		zone = zm_zonemgr::get_zone_from_position(self.streamer_hint.origin + vectorscale((0, 0, 1), 32), 0);
		if(zone == "zm_castle_power_zone")
		{
			break;
		}
		while(IsTrue(self.var_5aef0317))
		{
			wait(0.05);
		}
	}
}

rev_trap_big_apothicon()
{
	trap_trig = struct::get("apothicon_trap_trig", "targetname");
	level thread scene::skipto_end("cin_genesis_apothicon_flightpath", level.var_e7e8e5d6);
	level flag::wait_till("apothicon_near_trap");
	trap_trig notify("trigger_activated", self);
}

rev_set_wisp_complete()
{
	level clientfield::set("hope_state", 3);
	level flag::set("hope_done");
}

rev_spawn_car_wisp()
{
	level clientfield::set("hope_state", 1);
	level thread [[ @zm_genesis_hope<scripts\zm\zm_genesis_hope.gsc>::function_bb1fbc7f ]]();
}

rev_go_to_round(round)
{
	level.round_number = round;
	thread zm_utility::zombie_goto_round(round);
	level flag::clear("spawn_zombies");
	level.zombie_total = 1;
	level flag::set("spawn_zombies");
}

rev_kill_all_zombies(limit = -1)
{
	count = 0;
	foreach(zombie in getaiteamarray(level.zombie_team))
	{
		zombie kill();
		count++;
		if(count == limit)
		{
			break;
		}
	}
}

rev_init_hud(x, y, color)
{
	hud = newclienthudelem(self);
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "user_left";
	hud.vertalign = "user_top";
	hud.foreground = 0;
	hud.hidewheninmenu = 0;
	hud.x = x;
	hud.y = y;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontscale = 1.3;
	hud.color = color;
	return hud;
}

rev_timer_hud()
{
	hud = newhudelem();
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "user_left";
	hud.vertalign = "user_top";
	hud.foreground = 1;
	hud.hidewheninmenu = 0;
	hud.x = 0;
	hud.y = 5;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontscale = 1.5;
	hud.color = (1, 1, 1);
	return hud;
}

rev_text_hud()
{
	hud = newhudelem();
	hud.alignx = "center";
	hud.aligny = "center";
	hud.horzalign = "user_center";
	hud.vertalign = "user_center";
	hud.foreground = 1;
	hud.hidewheninmenu = 0;
	hud.x = 0;
	hud.y = 5;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontscale = 1.5;
	hud.color = (1, 1, 1);
	return hud;
}

rev_zombie_hud(x, y, color)
{
	hud = newclienthudelem(self);
	hud.alignx = "right";
	hud.aligny = "top";
	hud.horzalign = "user_right";
	hud.vertalign = "user_top";
	hud.foreground = 0;
	hud.hidewheninmenu = 0;
	hud.x = x;
	hud.y = y;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontscale = 1.3;
	hud.color = color;
	return hud;
}

rev_create_timer(start_time)
{
	self endon("disconnect");
	timer = newclienthudelem(self);
	timer.alignx = "rightr";
	timer.aligny = "top";
	timer.horzalign = "center";
	timer.vertalign = "top";
	timer.y = 30; // below the controls line at the top
	timer.fontscale = 2;
	timer.alpha = 1;
	timer.color = (1, 1, 1);
	timer.hidewheninmenu = 0;
	timer.hidden = 0;
	timer.label = &"";
	timer.alpha = 1;
	timer settimerup(start_time);
	return timer;
}

rev_basic_timer(start_time = 0, y = 90)
{
	timer = rev_init_hud(20, y, (1, 1, 1));
	timer settimerup(start_time);
	timer.label = &"^7Time: ^2";
	return timer;
}

rev_ignore_player(ignore)
{
	level notify("ignore_request");
	level endon("ignore_request");
	for(;;)
	{
		if(ignore)
		{
			self.ignoreme = 1;
		}
		else
		{
			self.ignoreme = 0;
		}
		wait(0.25);
	}
}

rev_give_player_loadout(weapon1, weapon2, weapon3)
{
	self takeweapon(self getcurrentweapon());
	wait(0.5);
	self takeweapon(self getcurrentweapon());
	wait(0.5);
	weapons = array(weapon1, weapon2, weapon3);
	foreach(weapon in weapons)
	{
		wait(0.2);
		if(tolower(weapon) != "none")
		{
			self zm_weapons::weapon_give(getweapon(weapon), 1);
		}
	}
}

rev_give_all_perks()
{
	perks = getarraykeys(level._custom_perks);
	foreach(perk in perks)
	{
		if(!self hasperk(perk))
		{
			self zm_perks::give_perk(perk, 0);
		}
	}
}

rev_softpatch()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level.customrandomweaponweights = ::rev_genesisbox;
	level.magicbox_hits = 0;
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	if(self SetPresetGums()) // default pack: the patch's own gum cycle
	{
		self.bgb_pack_randomized = array::randomize(self.bgb_pack);
		while(self.bgb_pack_randomized[0] != "zm_bgb_reign_drops" || !rev_isvalueinarray(self.bgb_pack_randomized[1], array("zm_bgb_extra_credit", "zm_bgb_shopping_free")) || self.bgb_pack_randomized[2] == "zm_bgb_immolation_liquidation")
		{
			self.bgb_pack_randomized = array::randomize(self.bgb_pack);
		}
		sec_cycle = array("zm_bgb_reign_drops", "zm_bgb_shopping_free", "zm_bgb_immolation_liquidation", "zm_bgb_extra_credit", "zm_bgb_perkaholic");
		foreach(gum in sec_cycle)
		{
			self.bgb_pack_randomized[self.bgb_pack_randomized.size] = gum;
		}
	}
	level.var_783db6ab = 5;
	rev_spawn_car_wisp();
}

rev_isvalueinarray(value, arr)
{
	foreach(item in arr)
	{
		if(item == value)
		{
			return 1;
		}
	}
	return 0;
}

rev_genesisbox(keys)
{
	level.magicbox_hits++;
	if(level.magicbox_hits > 7)
	{
		pap_triggers = zm_pap_util::get_triggers();
		if(zm_magicbox::treasure_chest_canplayerreceiveweapon(self, level.idgun_weapons[0], pap_triggers) && zm_weapons::limited_weapon_below_quota(level.idgun_weapons[0]))
		{
			arrayinsert(keys, level.idgun_weapons[0], 0);
			return keys;
		}
		if(zm_magicbox::treasure_chest_canplayerreceiveweapon(self, level.w_octobomb, pap_triggers))
		{
			arrayinsert(keys, level.w_octobomb, 0);
			return keys;
		}
	}
	return keys;
}

rev_set_split_time(hudelm, split_name, start_time)
{
	level.previous_segment = gettime();
	hudelm settext("^7" + split_name + ": ^5" + rev_ms_to_str(level.previous_segment - start_time));
	rev_reset_segment_timer();
}

rev_wait_keeper_start()
{
	while(!isdefined(level.ai_companion))
	{
		wait(0.05);
	}
	for(;;)
	{
		if(isalive(level.ai_companion) && !level.ai_companion IsScenePlaying("cin_zm_dlc4_keeper_prtctr_ee_idle"))
		{
			wait(0.05);
			continue;
		}
		if(level.ai_companion IsScenePlaying("cin_zm_dlc4_keeper_prtctr_ee_idle"))
		{
			return;
		}
		while(!isalive(level.ai_companion))
		{
			wait(0.05);
		}
		wait(0.05);
	}
}

rev_wait_egg_end()
{
	while(!level IsScenePlaying("genesis_ee_sams_room"))
	{
		wait(0.05);
	}
	wait(0.3);
}

rev_reset_segment_timer()
{
	if(isdefined(level.segment_timer))
	{
		level.segment_timer destroy();
	}
	level.segment_timer = rev_init_hud(20, 105, (1, 1, 1));
	level.segment_timer settimerup(0);
	level.segment_timer.label = &"^7Segment Time: ^2";
}

rev_softpatchtimer()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	main_timer = rev_init_hud(20, 90, (1, 1, 1));
	main_timer settimerup(0);
	main_timer.label = &"^7Time: ^2";
	level.sp_start_time = gettime();
	rev_reset_segment_timer();
	keeper_split = rev_init_hud(20, 120, (1, 1, 1));
	keeper_split settext("^7Keeper: ");
	rev_wait_keeper_start();
	rev_set_split_time(keeper_split, "Keeper", level.sp_start_time);
	squid_leave_split = rev_init_hud(20, 135, (1, 1, 1));
	squid_leave_split settext("^7Squid Leave: ");
	level flag::wait_till("placed_audio1");
	self rev_wait_de_leave();
	rev_set_split_time(squid_leave_split, "Squid Leave", level.sp_start_time);
	house_split = rev_init_hud(20, 150, (1, 1, 1));
	house_split settext("^7House: ");
	level flag::wait_till("teleporter_on");
	rev_set_split_time(house_split, "House", level.sp_start_time);
	boss1_split = rev_init_hud(20, 165, (1, 1, 1));
	boss1_split settext("^7Boss 1: ");
	level flag::wait_till("rift_entrance_open");
	rev_set_split_time(boss1_split, "Boss 1", level.sp_start_time);
	basketball_split = rev_init_hud(20, 180, (1, 1, 1));
	basketball_split settext("^7Basketball: ");
	level waittill(#"hash_f81a82d1");
	while(!self.b_teleporting)
	{
		wait(0.05);
	}
	rev_set_split_time(basketball_split, "Basketball", level.sp_start_time);
	boss2_split = rev_init_hud(20, 195, (1, 1, 1));
	boss2_split settext("^7Boss 2: ");
	level flag::wait_till("teleporter_on");
	rev_set_split_time(boss2_split, "Boss 2", level.sp_start_time);
	end_split = rev_init_hud(20, 210, (1, 1, 1));
	end_split settext("^7Egg End: ");
	rev_wait_egg_end();
	rev_set_split_time(end_split, "Egg End", level.sp_start_time);
}

rev_run_rev_soft_patch()
{
	thread rev_softpatchtimer();
	self rev_softpatch();
}
