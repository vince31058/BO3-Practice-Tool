#include scripts\codescripts\struct;
#include scripts\shared\system_shared;
#include scripts\shared\_burnplayer;
#include scripts\shared\callbacks_shared;
#include scripts\shared\clientfield_shared;
#include scripts\shared\ai_shared;
#include scripts\shared\vehicle_shared;
#include scripts\shared\vehicle_ai_shared;
#include scripts\shared\array_shared;
#include scripts\shared\math_shared;
#include scripts\shared\flag_shared;
#include scripts\shared\lui_shared;
#include scripts\shared\scene_shared;
#include scripts\shared\trigger_shared;
#include scripts\shared\visionset_mgr_shared;
#include scripts\shared\spawner_shared;
#include scripts\shared\exploder_shared;
#include scripts\shared\scoreevents_shared;
#include scripts\shared\util_shared;
#include scripts\shared\hud_util_shared;
#include scripts\shared\fx_shared;
#include scripts\shared\aat_shared;
#include scripts\shared\ai\zombie_utility;
#include scripts\shared\ai\systems\blackboard;
#include scripts\shared\ai\systems\gib;
#include scripts\zm\_zm;
#include scripts\zm\_zm_stats;
#include scripts\zm\_zm_audio;
#include scripts\zm\_zm_score;
#include scripts\zm\_zm_bgb;
#include scripts\zm\_zm_blockers;
#include scripts\zm\_zm_equipment;
#include scripts\zm\_zm_pack_a_punch_util;
#include scripts\zm\_zm_perks;
#include scripts\zm\_zm_powerups;
#include scripts\zm\_zm_power;
#include scripts\zm\_zm_magicbox;
#include scripts\zm\_zm_weapons;
#include scripts\zm\_zm_hero_weapon;
#include scripts\zm\_zm_placeable_mine;
#include scripts\zm\_zm_utility;
#include scripts\zm\_zm_zonemgr;
#include scripts\zm\_zm_spawner;
#include scripts\zm\_zm_unitrigger;
#include scripts\zm\craftables\_zm_craftables;
#include scripts\zm\zm_genesis_ee_quest;
#include scripts\zm\zm_genesis_hope;
#include scripts\zm\zm_genesis_arena;
#include scripts\zm\zm_genesis_sound;

#namespace serious;

openalldoors()
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
					door thread openairlock();
					break;
				case "zombie_debris":
					door thread opendebris();
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

opendebris()
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

openairlock()
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
		self.trigs[i] thread changedoormodels();
	}
	all_trigs = getentarray(self.target, "target");
	for(i = 0; i < all_trigs.size; i++)
	{
		all_trigs[i] triggerenable(0);
	}
}

changedoormodels()
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
		doors[i] thread airlockconnectpaths();
	}
}

airlockconnectpaths()
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

openallpower()
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
			generator capturegenerator(self);
			wait(0.5);
		}
	}
}

capturegenerator(player)
{
	level.zone_capture.last_zone_captured = self;
	self setplayercontrolledzone();
	self.n_current_progress = 100;
	level clientfield::set("state_" + self.script_noteworthy, 2);
	level clientfield::set(self.script_noteworthy, self.n_current_progress / 100);
}

setplayercontrolledzone()
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
	updatecapturedzonecount();
	self enableperksinzone();
	self enablerandomperksinzone();
	self enableboxinzone();
	level flag::set("power_on" + self.script_int);
	level notify("zone_captured_by_player", self.str_zone);
}

updatecapturedzonecount()
{
	level.total_capture_zones = getcapturedzonecount();
	if(level.total_capture_zones == 6)
	{
		level flag::set("all_zones_captured");
	}
	else
	{
		level flag::clear("all_zones_captured");
	}
}

getcapturedzonecount()
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

enableperksinzone()
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

enablerandomperksinzone()
{
	if(isdefined(self.perk_machines_random) && isarray(self.perk_machines_random))
	{
		foreach(random_perk_machine in self.perk_machines_random)
		{
			random_perk_machine.is_locked = 0;
			if(is_true(random_perk_machine.current_perk_random_machine))
			{
				random_perk_machine set_perk_random_machine_state("idle");
				continue;
			}
			random_perk_machine set_perk_random_machine_state("away");
		}
	}
}

set_perk_random_machine_state(state)
{
	wait(0.1);
	for(i = 0; i < self getnumzbarrierpieces(); i++)
	{
		self hidezbarrierpiece(i);
	}
	self notify("zbarrier_state_change");
	self [[ level.perk_random_machine_state_func ]](state);
}

enableboxinzone()
{
	foreach(mystery_box in self.mystery_boxes)
	{
		mystery_box.is_locked = 0;
		mystery_box.zbarrier [[ level.magic_box_zbarrier_state_func ]]("player_controlled");
		mystery_box.zbarrier clientfield::set("magicbox_runes", 1);
	}
}

run_debug()
{
	thread active_zones();
	self thread monitor_zone();
	self thread monitor_origin();
	self thread monitor_angles();
	thread change_debug_alpha();
}

change_debug_alpha()
{
	prev_value = 0;
	for(;;)
	{
		if(prev_value != getdvarint("show_debug"))
		{
			iprintln("Debug Toggled");
			prev_value = getdvarint("show_debug");
			if(level.zc_alpha == 0)
			{
				change_zombie_counter_alpha();
			}
		}
		wait(0.05);
	}
}

active_zones()
{
	level.active_zones_hud = zombie_hud(-10, 140, (1, 1, 1));
	level.active_zones_hud.alpha = getdvarint("show_debug");
	for(;;)
	{
		active_zones_str = "^5Active Zones:^7";
		foreach(index, zone in level.zones)
		{
			if(zone.is_active)
			{
				active_zones_str = active_zones_str + "\n" + index;
			}
		}
		level.active_zones_hud settext(active_zones_str);
		level.active_zones_hud.alpha = getdvarint("show_debug");
		wait(0.05);
	}
}

monitor_zone()
{
	level.player_zone_hud = zombie_hud(-10, 70, (1, 1, 1));
	level.player_zone_hud.alpha = getdvarint("show_debug");
	zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 1);
	level.player_zone_hud settext(zone);
	for(;;)
	{
		if(getdvarint("show_debug"))
		{
			zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 0);
			level.player_zone_hud settext("^5Current Zone: ^7" + zone);
			level.player_zone_hud.alpha = getdvarint("show_debug");
		}
		level.player_zone_hud.alpha = getdvarint("show_debug");
		wait(0.05);
	}
}

coords_to_str(coords)
{
	coord_str = "(" + coords[0] + ", " + coords[1] + ", " + coords[2] + ")";
	return coord_str;
}

monitor_origin()
{
	for(;;)
	{
		if(getdvarint("show_debug"))
		{
			iprintln("^5Origin: ^7" + coords_to_str(self.origin));
			wait(1.5);
		}
		wait(0.05);
	}
}

monitor_angles()
{
	for(;;)
	{
		if(getdvarint("show_debug"))
		{
			iprintln("^5Angles: ^7" + coords_to_str(self.angles));
			wait(1.5);
		}
		wait(0.05);
	}
}

monitor_zombie_counter()
{
	for(;;)
	{
		if(self actionslottwobuttonpressed())
		{
			iprintln("Zombie Counter Toggled");
			change_zombie_counter_alpha();
			wait(0.4);
		}
		wait(0.05);
	}
}

change_zombie_counter_alpha()
{
	if(!isdefined(level.zc_alpha))
	{
		level.zc_alpha = 0;
	}
	if(level.zc_alpha == 0)
	{
		level.zc_alpha = 1;
	}
	else
	{
		level.zc_alpha = 0;
	}
	level.total_zombies.alpha = level.zc_alpha;
	level.current_zombies.alpha = level.zc_alpha;
}

zombie_counter()
{
	level endon("end_game");
	last_counted_total = -1;
	last_counted_current = -1;
	level.total_zombies = zombie_hud(-10, 35, (1, 0, 0));
	level.current_zombies = zombie_hud(-10, 50, (0, 1, 0));
	level.total_zombies.alpha = 0;
	level.current_zombies.alpha = 0;
	for(;;)
	{
		if(level.zombie_total + zombie_utility::get_current_zombie_count() != last_counted_total)
		{
			last_counted_total = level.zombie_total + zombie_utility::get_current_zombie_count();
			level.total_zombies settext("Zombies Remaining: " + last_counted_total);
		}
		if(zombie_utility::get_current_zombie_count() != last_counted_current)
		{
			last_counted_current = zombie_utility::get_current_zombie_count();
			level.current_zombies settext("Zombies Spawned: " + last_counted_current);
		}
		wait(0.05);
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
				iprintln("Rock Hit");
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
	self thread zm_genesis_ee_quest::function_0958fb16();
	v_position = zm_genesis_ee_quest::function_04e44f01(self.origin, 1);
	self notify(#"hash_d940112c");
	wait(1);
	self moveto(v_position, 3);
	wait(3);
	playsoundatposition("zmb_main_reel3_bone_disappear", self.origin);
	self stoploopsound(2);
	self zm_genesis_ee_quest::function_156b5313();
}

custom_cleanup()
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
		level.activeplayers[i] thread zm_genesis_arena::function_56668973(a_s_teleports[i]);
	}
	level thread zm_genesis_sound::function_936d084f();
	level thread zm_genesis_arena::function_07719ec7(4);
	wait(4);
	level flag::set("boss_rush_phase_1");
	level notify(#"hash_f115a4c8");
	level thread zm_genesis_arena::function_389f8efe();
	level.first_passed = 0;
	cur_patch = level.patches[getdvarint("rev_practice_patch")];
	n_phases = 250;
	b_boss1 = 1;
	if(cur_patch != "Boss 1 Practice")
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
			level thread zm_genesis_arena::function_07719ec7(15);
			wait(15);
		}
		level thread zm_genesis_arena::function_7b82ff07(6);
		n_element = level.var_6000c357[i];
		level.var_8e402c12 = a_n_zombies_per_phase[i];
		level.var_a0135c54 = a_n_spawn_rate[i];
		level clientfield::set("circle_challenge_identity", n_element);
		level clientfield::set("arena_state", 2);
		level clientfield::set("circle_state", 3);
		level flag::clear("arena_vanilla_zombie_override");
		func_challenge = level.var_43e34f20[n_element];
		level thread [[ func_challenge ]](n_element, 0, 0, 1);
		level thread zm_genesis_arena::function_d9624751();
		level waittill(#"hash_e59686ee");
		playsoundatposition("zmb_bossrush_round_over", (0, 0, 0));
		custom_cleanup();
		level.phase_counter++;
		level thread zm_genesis_arena::function_7b82ff07(6);
		level.first_passed = 1;
		if(b_boss1)
		{
			zm_powerups::specific_powerup_drop("full_ammo", level.players[0].origin);
		}
	}
	wait(1);
	custom_cleanup();
	level thread zm_genesis_sound::function_d73dcf42();
	wait(3);
	playsoundatposition("zmb_main_completion_big", (0, 0, 0));
	level flag::clear("boss_rush_phase_1");
	level notify(#"hash_07af29ab");
}

detour zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_3d57dcdd()
{
	level endon("book_runes_failed");
	level endon("book_runes_success");
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
	iprintlnbold("SPAM SYMBOLS");
	while(level.var_be50c24f < level.var_6000c357.size)
	{
		level thread zm_genesis_arena::function_e3fb6380();
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
	level.players[0] thread ignore_player(0);
	custom_cleanup();
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
				b_success = level.ai_companion zm_genesis_ee_quest::function_3877f225(mdl_shard);
				if(b_success)
				{
					break;
				}
			}
		}
		wait(0.5);
	}
	s_target = struct::get(s_spot.target, "targetname");
	s_target thread zm_genesis_ee_quest::function_0bde2ec4(n_audio);
	mdl_shard delete();
	level flag::wait_till("placed_audio" + n_audio);
	foreach(s_spot in a_s_spots)
	{
		s_spot struct::delete();
	}
}

detour zm_magicbox<scripts\zm\zm_magicbox.gsc>::treasure_chest_chooseweightedrandomweapon(player)
{
	keys = array::randomize(getarraykeys(level.zombie_weapons));
	if(isdefined(level.customrandomweaponweights))
	{
		keys = player [[ level.customrandomweaponweights ]](keys);
	}
	pap_triggers = zm_pap_util::get_triggers();
	for(i = 0; i < keys.size; i++)
	{
		if(zm_magicbox::treasure_chest_canplayerreceiveweapon(player, keys[i], pap_triggers))
		{
			return keys[i];
		}
	}
	return keys[0];
}

autoexec __init__system__()
{
	compiler::detour();
	system::register("serious", ::__init__, undefined, undefined);
}

__init__()
{
	callback::on_start_gametype(::init);
	callback::on_connect(::on_player_connect);
	callback::on_spawned(::on_player_spawned);
}

istrue(bool)
{
	if(isdefined(bool) && bool)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

is_true(bool)
{
	if(isdefined(bool) && bool)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

ms_to_str(ms)
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

wait_de_leave()
{
	for(;;)
	{
		while(!istrue(self.var_5aef0317))
		{
			wait(0.05);
		}
		while(!istrue(self.streamer_hint))
		{
			wait(0.05);
		}
		zone = zm_zonemgr::get_zone_from_position(self.streamer_hint.origin + vectorscale((0, 0, 1), 32), 0);
		if(zone == "zm_castle_power_zone")
		{
			break;
		}
		while(istrue(self.var_5aef0317))
		{
			wait(0.05);
		}
	}
}

trap_big_apothicon()
{
	trap_trig = struct::get("apothicon_trap_trig", "targetname");
	level thread scene::skipto_end("cin_genesis_apothicon_flightpath", level.var_e7e8e5d6);
	level flag::wait_till("apothicon_near_trap");
	trap_trig notify("trigger_activated", self);
}

set_wisp_complete()
{
	level clientfield::set("hope_state", 3);
	level flag::set("hope_done");
}

spawn_car_wisp()
{
	level clientfield::set("hope_state", 1);
	level thread zm_genesis_hope::function_bb1fbc7f();
}

go_to_round(round)
{
	level.round_number = round;
	thread zm_utility::zombie_goto_round(round);
	level flag::clear("spawn_zombies");
	level.zombie_total = 1;
	level flag::set("spawn_zombies");
}

kill_all_zombies(limit = -1)
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

init_hud(x, y, color)
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

timer_hud()
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

text_hud()
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

zombie_hud(x, y, color)
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

create_timer(start_time)
{
	self endon("disconnect");
	timer = newclienthudelem(self);
	timer.alignx = "rightr";
	timer.aligny = "top";
	timer.horzalign = "center";
	timer.vertalign = "top";
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

basic_timer(start_time = 0, y = 90)
{
	timer = init_hud(20, y, (1, 1, 1));
	timer settimerup(start_time);
	timer.label = &"^7Time: ^2";
	return timer;
}

init()
{
	if(!isdefined(getdvarint("rev_practice_patch")))
	{
		setdvar("rev_practice_patch", 0);
	}
	if(getdvarint("show_debug") == 0)
	{
		modvar("show_debug", 0);
	}
	if(getdvarint("arnies_bug_round") == 0)
	{
		modvar("arnies_bug_round", 5);
	}
	if(getdvarint("use_basic_timer") == 0)
	{
		modvar("use_basic_timer", 0);
	}
}

on_player_connect()
{
	setdvar("sv_cheats", 1);
	level.player_out_of_playable_area_monitor = 0;
	level.patches = array("Soft Patch", "Arnies Practice", "Bones Practice", "Eggs Practice", "Boss 1 Practice", "Basketball", "Boss 2 Practice");
}

on_player_spawned()
{
	credit = hud::createfontstring("big", 1.25);
	credit hud::setpoint("BOTTOM LEFT", "BOTTOM LEFT", 0, 0);
	credit.alpha = 0.7;
	credit settext("By cbrnn");
	patch_msg = hud::createfontstring("big", 1.25);
	patch_msg hud::setpoint("TOPLEFT", "TOPLEFT", 20, 15);
	patch_msg.alpha = 0.7;
	thread monitor_patch_message(patch_msg);
	thread monitor_patch_change();
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	thread zombie_counter();
	self thread monitor_zombie_counter();
	self thread run_debug();
	level.show_controls = 1;
	thread show_controls();
	switch(getdvarint("rev_practice_patch"))
	{
		case 0:
			self run_rev_soft_patch();
		case 1:
			self run_arnies_patch();
		case 2:
			self run_bones_patch();
		case 3:
			self run_eggs_patch();
		case 4:
			self run_boss1_patch();
		case 5:
			self run_basketball_patch();
		case 6:
			self run_boss2_patch();
	}
}

show_controls()
{
	if(level.show_controls == 1)
	{
		controls = hud::createserverfontstring("big", 1.25);
		controls hud::setpoint("TOP", "TOP", 0, 15);
		controls settext("^5Press Grenade+Melee to Cycle Patches");
		controls settypewriterfx(50, 15000, 0);
		wait(6);
		controls fadeovertime(5);
		controls.alpha = 0;
		wait(5);
		controls destroy();
		level.show_controls = 0;
	}
}

monitor_patch_message(hud)
{
	for(;;)
	{
		hud settext("Rev Practice Tool v1.3\nCurrent Patch: " + level.patches[getdvarint("rev_practice_patch")]);
		wait(0.05);
	}
}

change_patch()
{
	if(getdvarint("rev_practice_patch") == 6)
	{
		setdvar("rev_practice_patch", 0);
	}
	else
	{
		setdvar("rev_practice_patch", getdvarint("rev_practice_patch") + 1);
	}
}

monitor_patch_change()
{
	for(;;)
	{
		if(self fragbuttonpressed() && self meleebuttonpressed())
		{
			change_patch();
			wait(0.45);
		}
		wait(0.05);
	}
}

ignore_player(ignore)
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

give_player_loadout(weapon1, weapon2, weapon3)
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

give_all_perks()
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

revarniespractice()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	bug_round = getdvarint("arnies_bug_round");
	if(bug_round == 6)
	{
		level.var_783db6ab = 6;
	}
	else
	{
		level.var_783db6ab = 5;
	}
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	spawn_car_wisp();
	level flag::set("character_stones_done");
	level flag::set("shards_done");
	level flag::set("extraction_ritual");
	level flag::set("got_audio1");
	wait(0.1);
	self.score = 10000;
	setdvar("timescale", 10);
	self give_all_perks();
	give_player_loadout("ar_cqb", "shotgun_pump", "idgun_genesis_0");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self bgb::give("zm_bgb_reign_drops");
	wait(0.1);
	self trap_big_apothicon();
	go_to_round(5);
	if(getdvarint("arnies_round") == 5)
	{
		wait(12);
	}
	else
	{
		wait(40);
		kill_all_zombies(20);
	}
	setdvar("timescale", 1);
	self setorigin((-137, 478, -237));
	self setplayerangles((0, -61.441, 0));
	self disableinvulnerability();
}

wait_squid_enter()
{
	zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 0);
	while(zone != "zm_prototype_apothicon_zone")
	{
		zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 0);
		wait(0.05);
	}
}

revarniestimer()
{
	if(level.de_leaves == 0)
	{
		self wait_squid_enter();
		level.guide_msg destroy();
		level.main_timer_start = gettime();
		if(getdvarint("use_basic_timer") == 0)
		{
			level.main_timer = create_timer(0);
		}
		else
		{
			level.main_timer = basic_timer(0);
		}
		self wait_de_leave();
		segment_time = gettime() - level.main_timer_start;
		iprintlnbold("Arnies Segment: " + ms_to_str(segment_time));
	}
}

run_arnies_patch()
{
	self revarniespractice();
	level.guide_msg = hud::createfontstring("big", 1.25);
	level.guide_msg hud::setpoint("TOPCENTER", "TOPCENTER", 20, 15);
	level.guide_msg.alpha = 1;
	level.guide_msg settext("Place Reel and Enter Squid");
	level.de_leaves = 0;
	self thread revarniestimer();
}

revbasketballpractice()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	level.var_783db6ab = 100;
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	level flag::set("shards_done");
	level flag::set("character_stones_done");
	level flag::set("phased_sophia_start");
	level flag::set("boss_rush");
	level flag::set("grand_tour");
	setdvar("timescale", 10);
	wait(0.1);
	self.score = 10000;
	self give_all_perks();
	give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self trap_big_apothicon();
	setdvar("timescale", 1);
	self setorigin((-760, -8503, -3767));
	self setplayerangles((4.39453, -123.492, 0));
	self disableinvulnerability();
}

monitor_basketball_reset()
{
	for(;;)
	{
		if(self adsbuttonpressed() && self meleebuttonpressed())
		{
			level.var_7d7ca0ea notify("reset");
			level.bball_timer destroy();
			if(self flag::get("has_ball"))
			{
				self notify("ball_pass");
				wait(0.5);
			}
			level.ball.visuals[0] clientfield::set("ball_on_ground_fx", 0);
			level.ball [[ @ball<scripts\zm\_zm_weap_ball.gsc>::function_a41df27c ]]();
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_11a85c29 ]](1);
			level thread [[ @zm_genesis_arena<scripts\zm\zm_genesis_arena.gsc>::function_b1e065cd ]]();
			level.bball_timer = self basketball_timer();
		}
		wait(0.05);
	}
	wait(0.05);
}

monitor_ball_reset()
{
	for(;;)
	{
		if(self reloadbuttonpressed() && self meleebuttonpressed())
		{
			level.ball [[ @ball<scripts\zm\_zm_weap_ball.gsc>::reset_ball ]](1, self.origin, 1);
		}
		wait(0.05);
	}
}

basketball_timer()
{
	level waittill(#"hash_f81a82d1");
	while(!self.b_teleporting)
	{
		wait(0.05);
	}
	level.bball_start_time = gettime();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = create_timer(0);
	}
	else
	{
		level.main_timer = basic_timer(0, 70);
	}
	return level.main_timer;
}

run_basketball_patch()
{
	self revbasketballpractice();
	level notify("toys_collected");
	level.bball_timer = self basketball_timer();
	self thread monitor_basketball_reset();
	self thread monitor_ball_reset();
	level notify("toys_collected");
	self thread watch_toys();
	thread watch_completion();
	show_reset_controls();
	show_ball_reset_controls();
	dist_hud = hud::createfontstring("big", 1.25);
	dist_hud hud::setpoint("TOPLEFT", "TOPLEFT", 20, 150);
	dist_hud.alpha = 0.7;
	thread monitor_dist_from_toy(dist_hud);
}

watch_completion()
{
	result = level.var_7d7ca0ea util::waittill_any_return("trigger", "reset");
	if(result == "trigger")
	{
		segment_time = gettime() - level.bball_start_time;
		iprintlnbold("Basketball Segment: " + ms_to_str(segment_time));
	}
}

show_reset_controls()
{
	reset_controls = hud::createfontstring("big", 1.25);
	reset_controls hud::setpoint("TOPLEFT", "TOPLEFT", 20, 100);
	reset_controls.alpha = 0.7;
	reset_controls settext("ADS+Melee To Reset");
}

show_ball_reset_controls()
{
	ball_controls = hud::createfontstring("big", 1.25);
	ball_controls hud::setpoint("TOPLEFT", "TOPLEFT", 20, 115);
	ball_controls.alpha = 0.7;
	ball_controls settext("Reload+Melee To Reset Ball");
}

watch_toys()
{
	ball_prev_origin = undefined;
	level.distances = [];
	level.closest = 0;
	for(;;)
	{
		ball = level.ball;
		ball_visuals = ball.visuals[0];
		ball_origin = ball_visuals.origin;
		if(isdefined(ball.carrier) || istrue(ball.isresetting) && ball.isresetting)
		{
			util::wait_network_frame();
			continue;
		}
		else if(isdefined(ball_prev_origin) && ball_origin != ball_prev_origin && distancesquared(ball_origin, ball_prev_origin) < 40000)
		{
			level.hit = 0;
			foreach(toy in level.var_6e907685)
			{
				point = pointonsegmentnearesttopoint(ball_origin, ball_prev_origin, toy.origin);
				v_diff = point - toy.origin;
				dist = length(v_diff);
				if(dist < toy.radius)
				{
					level.hit = 1;
					level.closest = -1;
					iprintlnbold("Toy Hit");
					mdl_toy = util::spawn_model(toy.model, toy.origin, toy.angles);
					mdl_toy setscale(toy.script_float);
					mdl_toy notsolid();
					switch(toy.script_string)
					{
						case "up":
							v_launch = vectorscale((0, 0, 1), 160);
							break;
						case "forward":
							v_launch = vectornormalize(ball.lastcarrier.origin - toy.origin) * 160;
							break;
						default:
							break;
					}
					mdl_toy thread [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_e2a94206 ]](v_launch);
					ball thread [[ @ball<scripts\zm\_zm_weap_ball.gsc>::function_b8faebaf ]](5);
					playsoundatposition("zmb_gen_ee_toy_found", toy.origin);
					wait(4.8);
					level thread [[ @zm_genesis_vo<scripts\zm\zm_genesis_vo.gsc>::function_e644549c ]](ball.lastcarrier);
					toy notify("toy_found");
					if(level.var_6e907685.size)
					{
						if(toy.target == "ee_grand_tour_origins")
						{
							ball [[ @ball<scripts\zm\_zm_weap_ball.gsc>::reset_ball ]](1, ball.lastcarrier.origin, 1);
						}
						else
						{
							v_diff = distance2d(ball.lastcarrier.origin, toy.origin);
							n_height = v_diff * 0.3;
							n_z_diff = abs(ball.lastcarrier.origin[2] - toy.origin[2]);
							n_height += n_z_diff * 0.5;
							n_height += 150;
							v_target = ball.lastcarrier.origin + (0, 0, n_height) - ball_origin;
							ball thread [[ @ball<scripts\zm\_zm_weap_ball.gsc>::function_fed77788 ]](ball_origin, v_target);
						}
						wait(1);
						continue;
					}
					ball [[ @ball<scripts\zm\_zm_weap_ball.gsc>::function_a41df27c ]]();
					continue;
				}
				dist_from_toy = dist - toy.radius;
				level.distances[level.distances.size] = dist_from_toy;
				if(dist_from_toy < level.closest || level.closest == 0)
				{
					level.closest = dist_from_toy;
				}
			}
		}
		ball_prev_origin = ball_origin;
		util::wait_network_frame();
	}
}

monitor_dist_from_toy(hud)
{
	for(;;)
	{
		if(isdefined(level.ball.carrier))
		{
			level.closest = 0;
			hud settext("Lowest Distance To Toy: Ball In Hand");
			wait(0.05);
			continue;
		}
		if(level.closest == -1)
		{
			level.closest = 0;
			hud settext("Lowest Distance To Toy: Toy Hit!");
			while(!isdefined(level.ball.carrier))
			{
				wait(0.05);
			}
			wait(0.05);
			continue;
		}
		hud settext("Lowest Distance To Toy: " + level.closest);
		wait(0.05);
	}
}

revbonespractice()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	level.var_783db6ab = 100;
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	spawn_car_wisp();
	level flag::set("character_stones_done");
	level flag::set("shards_done");
	level flag::set("extraction_ritual");
	level flag::set("acm_wave_in_progress");
	level flag::set("acm_done");
	level flag::set("got_audio1");
	level flag::set("placed_audio1");
	level flag::set("got_audio2");
	wait(0.1);
	self.score = 10000;
	setdvar("timescale", 10);
	self give_all_perks();
	give_player_loadout("ar_cqb_upgraded", "shotgun_pump", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self trap_big_apothicon();
	go_to_round(6);
	wait(12);
	self setorigin((727.473, -32.2299, -3329.72));
	self setplayerangles((0, -61.441, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
}

revbonestimer()
{
	if(level.de_leaves < 1)
	{
		self wait_de_leave();
		level.de_leaves++;
		level.weapon_swap_msg destroy();
		level.main_timer_start = gettime();
		if(getdvarint("use_basic_timer") == 0)
		{
			level.main_timer = create_timer(0);
		}
		else
		{
			level.main_timer = basic_timer(0);
		}
		level flag::wait_till("teleporter_on");
		segment_time = gettime() - level.main_timer_start;
		iprintlnbold("Bones Segment: " + ms_to_str(segment_time));
	}
}

bonesweaponselect()
{
	level.cur_weap = 1;
	for(;;)
	{
		if(self meleebuttonpressed() && self adsbuttonpressed())
		{
			self swap_bones_weap();
			wait(2);
		}
		wait(0.05);
	}
}

swap_bones_weap()
{
	switch(level.cur_weap)
	{
		case 0:
			iprintlnbold("Giving HVK");
			self zm_weapons::weapon_give(getweapon("ar_cqb_upgraded"), 1);
		case 1:
			iprintlnbold("Giving Ray Gun");
			self zm_weapons::weapon_give(getweapon("ray_gun_upgraded"), 1);
		case 2:
			iprintlnbold("Giving Shieva");
			self zm_weapons::weapon_give(getweapon("ar_marksman_upgraded"), 1);
		case 3:
			iprintlnbold("Giving Dingo");
			self zm_weapons::weapon_give(getweapon("lmg_cqb_upgraded"), 1);
	}
	if(level.cur_weap < 3)
	{
		level.cur_weap++;
	}
	else
	{
		level.cur_weap = 0;
	}
}

create_split(split_index, text)
{
	level.split_times[split_index] = gettime();
	split_y = 105 + 15 * split_index;
	ovum_split = init_hud(20, split_y, (1, 1, 1));
	ovum_split settext(text);
}

run_bones_patch()
{
	self revbonespractice();
	level.de_leaves = 0;
	self thread revbonestimer();
	level.weapon_swap_msg = hud::createfontstring("big", 1.25);
	level.weapon_swap_msg hud::setpoint("TOPCENTER", "TOPCENTER", 20, 15);
	level.weapon_swap_msg.alpha = 1;
	level.weapon_swap_msg settext("ADS + Melee to Cycle Weapons");
	self thread bonesweaponselect();
}

revboss1practice()
{
	level.ik_counter = -1;
	level.phase_counter = 0;
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	level.var_783db6ab = 100;
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	level flag::set("shards_done");
	level flag::set("character_stones_done");
	level flag::set("phased_sophia_start");
	level flag::set("book_picked_up");
	level flag::set("book_placed");
	level flag::set("rune_circle_on");
	level.var_b1b99f8d[0] = 0;
	level.var_b1b99f8d[1] = 1;
	level.var_b1b99f8d[2] = 2;
	level.var_b1b99f8d[3] = 3;
	level clientfield::set("gen_rune_electricity", 1);
	level clientfield::set("gen_rune_fire", 1);
	level clientfield::set("gen_rune_light", 1);
	level clientfield::set("gen_rune_shadow", 1);
	wait(0.1);
	level.players[0] thread ignore_player(1);
	self.score = 3000;
	setdvar("timescale", 10);
	self give_all_perks();
	give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self trap_big_apothicon();
	go_to_round(8);
	self setorigin((-364.035, -8082.19, -1327.55));
	level waittill(#"hash_78e9c51c");
	book = struct::get("ee_book_arena", "targetname");
	wait(0.25);
	book notify("trigger_activated", self);
	wait(30);
	setdvar("timescale", 3);
}

margwa_counter()
{
	counter = init_hud(15, 150, (1, 1, 1));
	for(;;)
	{
		counter settext("Instakill Phases: " + level.ik_counter + "/" + level.phase_counter);
		wait(0.05);
	}
}

run_boss1_patch()
{
	self revboss1practice();
	thread margwa_counter();
}

revboss2practice()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	level.var_783db6ab = 100;
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	set_wisp_complete();
	level flag::set("character_stones_done");
	level flag::set("shards_done");
	level flag::set("extraction_ritual");
	level flag::set("acm_wave_in_progress");
	level flag::set("acm_done");
	level flag::set("b_targets_collected");
	level flag::set("b_target_flesh");
	level flag::set("b_target_done");
	level flag::set("got_audio1");
	level flag::set("got_audio2");
	level flag::set("got_audio3");
	level flag::set("placed_audio1");
	level flag::set("placed_audio2");
	level flag::set("placed_audio3");
	level flag::set("phased_sophia_start");
	level flag::set("teleporter_on");
	level flag::set("book_picked_up");
	level flag::set("book_placed");
	level flag::set("rune_circle_on");
	wait(0.1);
	self.score = 3000;
	setdvar("timescale", 10);
	self give_all_perks();
	give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self bgb::give("zm_bgb_reign_drops");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self trap_big_apothicon();
	go_to_round(8);
	self setorigin((-133.799, -7799.34, -3607.38));
	self setplayerangles((4.39453, -123.492, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
}

boss2_timer()
{
	level flag::wait_till("boss_fight");
	level.main_timer_start = gettime();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = create_timer(-6.8);
	}
	else
	{
		level.main_timer = basic_timer(-6.8);
	}
	level flag::wait_till("final_boss_defeated");
	segment_time = gettime() - level.main_timer_start + 32800;
	iprintlnbold("Boss 2 Segment: " + ms_to_str(segment_time));
}

run_boss2_patch()
{
	self revboss2practice();
	thread boss2_timer();
	level flag::set("toys_collected");
	level flag::set("boss_fight");
}

reveggspractice()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	level.var_783db6ab = 100;
	self enableinvulnerability();
	level flag::clear("spawn_zombies");
	openalldoors();
	openallpower();
	set_wisp_complete();
	level flag::set("character_stones_done");
	level flag::set("shards_done");
	level flag::set("extraction_ritual");
	level flag::set("acm_wave_in_progress");
	level flag::set("acm_done");
	level flag::set("b_targets_collected");
	level flag::set("b_target_flesh");
	level flag::set("b_target_done");
	level flag::set("got_audio1");
	level flag::set("got_audio2");
	level flag::set("got_audio3");
	level flag::set("placed_audio1");
	level flag::set("placed_audio2");
	level flag::set("placed_audio3");
	level flag::set("phased_sophia_start");
	level flag::set("sophia_beam_locked");
	level flag::set("sophia_at_teleporter");
	level flag::set("teleporter_on");
	level flag::set("teleporter_cooldown");
	level flag::set("book_picked_up");
	wait(0.1);
	self.score = 3000;
	setdvar("timescale", 10);
	self give_all_perks();
	give_player_loadout("ar_cqb_upgraded", "shotgun_pump", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self bgb::give("zm_bgb_anywhere_but_here");
	wait(0.1);
	self trap_big_apothicon();
	go_to_round(7);
	wait(22);
	self setorigin((-1053.51, -9313.9, -1637.55));
	self setplayerangles((0, 75, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = create_timer(-40.5);
	}
	else
	{
		level.main_timer = basic_timer(-40.5);
	}
}

run_eggs_patch()
{
	self reveggspractice();
}

revsoftpatch()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	level.customrandomweaponweights = ::genesisbox;
	level.magicbox_hits = 0;
	level flag::wait_till("start_zombie_round_logic");
	level flag::wait_till("initial_blackscreen_passed");
	self.bgb_pack = array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_shopping_free", "zm_bgb_immolation_liquidation", "zm_bgb_extra_credit");
	level.players[0].bgb_pack = array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_shopping_free", "zm_bgb_immolation_liquidation", "zm_bgb_extra_credit");
	self.bgb_pack_randomized = array::randomize(self.bgb_pack);
	while(self.bgb_pack_randomized[0] != "zm_bgb_reign_drops" || !isvalueinarray(self.bgb_pack_randomized[1], array("zm_bgb_extra_credit", "zm_bgb_shopping_free")) || self.bgb_pack_randomized[2] == "zm_bgb_immolation_liquidation")
	{
		self.bgb_pack_randomized = array::randomize(self.bgb_pack);
	}
	sec_cycle = array("zm_bgb_reign_drops", "zm_bgb_shopping_free", "zm_bgb_immolation_liquidation", "zm_bgb_extra_credit", "zm_bgb_perkaholic");
	foreach(gum in sec_cycle)
	{
		self.bgb_pack_randomized[self.bgb_pack_randomized.size] = gum;
	}
	level.var_783db6ab = 5;
	spawn_car_wisp();
}

isvalueinarray(value, array)
{
	foreach(item in array)
	{
		if(item == value)
		{
			return 1;
		}
	}
	return 0;
}

genesisbox(keys)
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

set_split_time(hudelm, split_name, start_time)
{
	level.previous_segment = gettime();
	hudelm settext("^7" + split_name + ": ^5" + ms_to_str(level.previous_segment - start_time));
	reset_segment_timer();
}

wait_keeper_start()
{
	while(!isdefined(level.ai_companion))
	{
		wait(0.05);
	}
	for(;;)
	{
		while(isalive(level.ai_companion) && !level.ai_companion issceneplaying("cin_zm_dlc4_keeper_prtctr_ee_idle"))
		{
			wait(0.05);
		}
		if(level.ai_companion issceneplaying("cin_zm_dlc4_keeper_prtctr_ee_idle"))
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

wait_egg_end()
{
	while(!level issceneplaying("genesis_ee_sams_room"))
	{
		wait(0.05);
	}
	wait(0.3);
}

issceneplaying(scene_name)
{
	return self scene::is_playing(scene_name);
}

reset_segment_timer()
{
	if(isdefined(level.segment_timer))
	{
		level.segment_timer destroy();
	}
	level.segment_timer = init_hud(20, 105, (1, 1, 1));
	level.segment_timer settimerup(0);
	level.segment_timer.label = &"^7Segment Time: ^2";
}

revsoftpatchtimer()
{
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}
	main_timer = init_hud(20, 90, (1, 1, 1));
	main_timer settimerup(0);
	main_timer.label = &"^7Time: ^2";
	level.sp_start_time = gettime();
	reset_segment_timer();
	keeper_split = init_hud(20, 120, (1, 1, 1));
	keeper_split settext("^7Keeper: ");
	wait_keeper_start();
	set_split_time(keeper_split, "Keeper", level.sp_start_time);
	squid_leave_split = init_hud(20, 135, (1, 1, 1));
	squid_leave_split settext("^7Squid Leave: ");
	level flag::wait_till("placed_audio1");
	self wait_de_leave();
	set_split_time(squid_leave_split, "Squid Leave", level.sp_start_time);
	house_split = init_hud(20, 150, (1, 1, 1));
	house_split settext("^7House: ");
	level flag::wait_till("teleporter_on");
	set_split_time(house_split, "House", level.sp_start_time);
	boss1_split = init_hud(20, 165, (1, 1, 1));
	boss1_split settext("^7Boss 1: ");
	level flag::wait_till("rift_entrance_open");
	set_split_time(boss1_split, "Boss 1", level.sp_start_time);
	basketball_split = init_hud(20, 180, (1, 1, 1));
	basketball_split settext("^7Basketball: ");
	level waittill(#"hash_f81a82d1");
	while(!self.b_teleporting)
	{
		wait(0.05);
	}
	set_split_time(basketball_split, "Basketball", level.sp_start_time);
	boss2_split = init_hud(20, 195, (1, 1, 1));
	boss2_split settext("^7Boss 2: ");
	level flag::wait_till("teleporter_on");
	set_split_time(boss2_split, "Boss 2", level.sp_start_time);
	end_split = init_hud(20, 210, (1, 1, 1));
	end_split settext("^7Egg End: ");
	wait_egg_end();
	set_split_time(end_split, "Egg End", level.sp_start_time);
}

run_rev_soft_patch()
{
	thread revsoftpatchtimer();
	self revsoftpatch();
}
