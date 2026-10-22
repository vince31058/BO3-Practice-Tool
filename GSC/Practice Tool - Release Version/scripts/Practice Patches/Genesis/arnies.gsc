// Rev - Arnies Practice (from cbrnn's Rev Practice Tool v1.3)

ArniesPractice()
{
    self RevPracticeStart("Arnies Practice", ::rev_run_arnies_patch);
}

rev_arniespractice()
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
	rev_openalldoors();
	rev_openallpower();
	rev_spawn_car_wisp();
	level flag::set("character_stones_done");
	level flag::set("shards_done");
	level flag::set("extraction_ritual");
	level flag::set("got_audio1");
	wait(0.1);
	self.score = 10000;
	setdvar("timescale", 10);
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb", "shotgun_pump", "idgun_genesis_0");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self bgb::give("zm_bgb_reign_drops");
	wait(0.1);
	self rev_trap_big_apothicon();
	rev_go_to_round(5);
	if(getdvarint("arnies_round") == 5)
	{
		wait(12);
	}
	else
	{
		wait(40);
		rev_kill_all_zombies(20);
	}
	setdvar("timescale", 1);
	self setorigin((-137, 478, -237));
	self setplayerangles((0, -61.441, 0));
	self disableinvulnerability();
}

rev_wait_squid_enter()
{
	zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 0);
	while(zone != "zm_prototype_apothicon_zone")
	{
		zone = zm_zonemgr::get_zone_from_position(self.origin + vectorscale((0, 0, 1), 32), 0);
		wait(0.05);
	}
}

rev_arniestimer()
{
	if(level.de_leaves == 0)
	{
		self rev_wait_squid_enter();
		level.guide_msg destroy();
		level.main_timer_start = gettime();
		if(getdvarint("use_basic_timer") == 0)
		{
			level.main_timer = rev_create_timer(0);
		}
		else
		{
			level.main_timer = rev_basic_timer(0);
		}
		self rev_wait_de_leave();
		segment_time = gettime() - level.main_timer_start;
		iprintlnbold("Arnies Segment: " + rev_ms_to_str(segment_time));
	}
}

rev_run_arnies_patch()
{
	self rev_arniespractice();
	level.guide_msg = hud::createfontstring("big", 1.25);
	level.guide_msg hud::setpoint("TOPCENTER", "TOPCENTER", 20, 15);
	level.guide_msg.alpha = 1;
	level.guide_msg settext("Place Reel and Enter Squid");
	level.de_leaves = 0;
	self thread rev_arniestimer();
}
