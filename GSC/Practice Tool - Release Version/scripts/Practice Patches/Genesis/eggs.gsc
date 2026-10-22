// Rev - Eggs Practice (from cbrnn's Rev Practice Tool v1.3)

EggsPractice()
{
    self RevPracticeStart("Eggs Practice", ::rev_run_eggs_patch);
}

rev_eggspractice()
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
	rev_openalldoors();
	rev_openallpower();
	rev_set_wisp_complete();
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
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb_upgraded", "shotgun_pump", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self bgb::give("zm_bgb_anywhere_but_here");
	wait(0.1);
	self rev_trap_big_apothicon();
	rev_go_to_round(7);
	wait(22);
	self setorigin((-1053.51, -9313.9, -1637.55));
	self setplayerangles((0, 75, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = rev_create_timer(-40.5);
	}
	else
	{
		level.main_timer = rev_basic_timer(-40.5);
	}
}

rev_run_eggs_patch()
{
	self rev_eggspractice();
}
