// Rev - Basketball Practice (from cbrnn's Rev Practice Tool v1.3)

BasketballPractice()
{
    self RevPracticeStart("Basketball Practice", ::rev_run_basketball_patch);
}

rev_basketballpractice()
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
	level flag::set("shards_done");
	level flag::set("character_stones_done");
	level flag::set("phased_sophia_start");
	level flag::set("boss_rush");
	level flag::set("grand_tour");
	setdvar("timescale", 10);
	wait(0.1);
	self.score = 10000;
	self rev_give_all_perks();
	rev_give_player_loadout("ar_cqb_upgraded", "shotgun_pump_upgraded", "idgun_genesis_0_upgraded");
	self [[ level.zombie_weapons_callbacks[level.w_octobomb] ]]();
	wait(0.1);
	self rev_trap_big_apothicon();
	setdvar("timescale", 1);
	self setorigin((-760, -8503, -3767));
	self setplayerangles((4.39453, -123.492, 0));
	self disableinvulnerability();
}

rev_monitor_basketball_reset()
{
	for(;;)
	{
		WaitAction(1);
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
		level.bball_timer = self rev_basketball_timer();
	}
}

rev_monitor_ball_reset()
{
	for(;;)
	{
		WaitAction(2);
		level.ball [[ @ball<scripts\zm\_zm_weap_ball.gsc>::reset_ball ]](1, self.origin, 1);
	}
}

rev_basketball_timer()
{
	level waittill(#"hash_f81a82d1");
	while(!self.b_teleporting)
	{
		wait(0.05);
	}
	level.bball_start_time = gettime();
	if(getdvarint("use_basic_timer") == 0)
	{
		level.main_timer = rev_create_timer(0);
	}
	else
	{
		level.main_timer = rev_basic_timer(0, 70);
	}
	return level.main_timer;
}

rev_run_basketball_patch()
{
	self rev_basketballpractice();
	level notify("toys_collected");
	level.bball_timer = self rev_basketball_timer();
	self thread rev_monitor_basketball_reset();
	self thread rev_monitor_ball_reset();
	level notify("toys_collected");
	self thread rev_watch_toys();
	thread rev_watch_completion();
	self thread ShowControls(Array(Array("action1", "Reset"), Array("action2", "Reset Ball")));
	dist_hud = hud::createfontstring("big", 1.25);
	dist_hud hud::setpoint("TOPLEFT", "TOPLEFT", 20, 100);
	dist_hud.alpha = 0.7;
	thread rev_monitor_dist_from_toy(dist_hud);
}

rev_watch_completion()
{
	result = level.var_7d7ca0ea util::waittill_any_return("trigger", "reset");
	if(result == "trigger")
	{
		segment_time = gettime() - level.bball_start_time;
		iprintlnbold("Basketball Segment: " + rev_ms_to_str(segment_time));
	}
}

rev_watch_toys()
{
	ball_prev_origin = undefined;
	level.distances = [];
	level.closest = 0;
	for(;;)
	{
		ball = level.ball;
		ball_visuals = ball.visuals[0];
		ball_origin = ball_visuals.origin;
		if(isdefined(ball.carrier) || IsTrue(ball.isresetting) && ball.isresetting)
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

// Only sets the text when it changes: every different string sent to a HUD uses up a game
// config string, so setting it every frame can run the game out of them.
rev_monitor_dist_from_toy(hud)
{
	shown = undefined;
	for(;;)
	{
		if(isdefined(level.ball.carrier))
		{
			level.closest = 0;
			text = "Lowest Distance To Toy: Ball In Hand";
			if(!isdefined(shown) || shown != text)
			{
				hud settext(text);
				shown = text;
			}
			wait(0.05);
			continue;
		}
		if(level.closest == -1)
		{
			level.closest = 0;
			text = "Lowest Distance To Toy: Toy Hit!";
			hud settext(text);
			shown = text;
			while(!isdefined(level.ball.carrier))
			{
				wait(0.05);
			}
			wait(0.05);
			continue;
		}
		text = "Lowest Distance To Toy: " + int(level.closest);
		if(!isdefined(shown) || shown != text)
		{
			hud settext(text);
			shown = text;
		}
		wait(0.05);
	}
}
