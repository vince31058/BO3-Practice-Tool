// Rev - Boss 1 Practice (from cbrnn's Rev Practice Tool v1.3)

Boss1Practice()
{
    self RevPracticeStart("Boss 1 Practice", ::rev_run_boss1_patch);
}

rev_boss1practice()
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
	rev_openalldoors();
	rev_openallpower();
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
	level.players[0] thread rev_ignore_player(1);
	self.score = 3000;
	setdvar("timescale", 10);
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self rev_trap_big_apothicon();
	rev_go_to_round(8);
	self setorigin((-364.035, -8082.19, -1327.55));
	level waittill(#"hash_78e9c51c");
	book = struct::get("ee_book_arena", "targetname");
	wait(0.25);
	book notify("trigger_activated", self);
	wait(30);
	setdvar("timescale", 3);
}

rev_margwa_counter()
{
	counter = rev_init_hud(15, 150, (1, 1, 1));
	shown = "";
	for(;;)
	{
		text = "Instakill Phases: " + level.ik_counter + "/" + level.phase_counter;
		if(text != shown)
		{
			counter settext(text);
			shown = text;
		}
		wait(0.05);
	}
}

rev_run_boss1_patch()
{
	self rev_boss1practice();
	thread rev_margwa_counter();
}
