// Rev - Bones Practice (from cbrnn's Rev Practice Tool v1.3)

BonesPractice()
{
    self RevPracticeStart("Bones Practice", ::rev_run_bones_patch);
}

rev_bonespractice()
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
	rev_spawn_car_wisp();
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
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb_upgraded", "shotgun_pump", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self rev_trap_big_apothicon();
	rev_go_to_round(6);
	wait(12);
	self setorigin((727.473, -32.2299, -3329.72));
	self setplayerangles((0, -61.441, 0));
	setdvar("timescale", 1);
	self disableinvulnerability();
}

rev_bonestimer()
{
	if(level.de_leaves < 1)
	{
		self rev_wait_de_leave();
		level.de_leaves++;
		level.main_timer_start = gettime();
		if(getdvarint("use_basic_timer") == 0)
		{
			level.main_timer = rev_create_timer(0);
		}
		else
		{
			level.main_timer = rev_basic_timer(0);
		}
		level flag::wait_till("teleporter_on");
		segment_time = gettime() - level.main_timer_start;
		iprintlnbold("Bones Segment: " + rev_ms_to_str(segment_time));
	}
}

rev_bonesweaponselect()
{
	level.cur_weap = 1;
	for(;;)
	{
		WaitAction(1);
		self rev_swap_bones_weap();
	}
}

rev_swap_bones_weap()
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

rev_create_split(split_index, text)
{
	level.split_times[split_index] = gettime();
	split_y = 105 + 15 * split_index;
	ovum_split = rev_init_hud(20, split_y, (1, 1, 1));
	ovum_split settext(text);
}

rev_run_bones_patch()
{
	self rev_bonespractice();
	level.de_leaves = 0;
	self thread rev_bonestimer();
	self thread ShowControls(Array(Array("action1", "Cycle Weapons")));
	self thread rev_bonesweaponselect();
}
