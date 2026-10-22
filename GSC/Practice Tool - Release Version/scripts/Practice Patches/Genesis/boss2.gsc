// Rev - Boss 2 Practice (from cbrnn's Rev Practice Tool v1.3)

Boss2Practice()
{
    self RevPracticeStart("Boss 2 Practice", ::rev_run_boss2_patch);
}

rev_boss2practice()
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
	level flag::set("teleporter_on");
	level flag::set("book_picked_up");
	level flag::set("book_placed");
	level flag::set("rune_circle_on");
	wait(0.1);
	self.score = 3000;
	setdvar("timescale", 10);
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self bgb::give("zm_bgb_reign_drops");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self rev_trap_big_apothicon();
	rev_go_to_round(8);
	self setorigin((-133.799, -7799.34, -3607.38));
	self setplayerangles((4.39453, -123.492, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
}

rev_boss2_timer()
{
	level flag::wait_till("boss_fight");
	level.main_timer_start = gettime();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = rev_create_timer(-6.8);
	}
	else
	{
		level.main_timer = rev_basic_timer(-6.8);
	}
	level flag::wait_till("final_boss_defeated");
	segment_time = gettime() - level.main_timer_start + 32800;
	iprintlnbold("Boss 2 Segment: " + rev_ms_to_str(segment_time));
}

rev_run_boss2_patch()
{
	self rev_boss2practice();
	thread rev_boss2_timer();
	level flag::set("toys_collected");
	level flag::set("boss_fight");
}
