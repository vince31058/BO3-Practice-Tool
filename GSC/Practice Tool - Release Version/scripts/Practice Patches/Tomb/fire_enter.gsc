// Origins - Fire Enter Practice (Fire Enter Midgame With Splits V2, by Margz), ported into the
// practice tool. It starts right away with its saved options; in game the universal binds
// change them (they apply on the next fast_restart):
//   action1 Fire Enter Time 11:10 / 11:40, action2 Splits 2 Box / 3 Box,
//   action3 R2L Death Barrier On / Off, reset_patch puts all three back to their defaults.
// Its robot order and first-recapture choice only apply while this patch is loaded
// (level.fire_enter_active); otherwise the game behaves normally.

FireEnterPractice()
{
    if(level.script != "zm_tomb")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Origins");
        return;
    }
    level.fire_enter_active = true;
    level.abh_index = 0;
    level.var_2c12d9a6 = ::fe_abh;
    self thread FireEnterSettings();

    // R2L death barrier: practice_death_barrier_off 0 = YES (barrier on), 1 = NO (off)
    if(!GetDvarInt("practice_death_barrier_off"))
    {
        level.player_out_of_playable_area_monitor = 1;
        self thread zm::player_out_of_playable_area_monitor();
    }
    level thread FireEnterLoadedMessage();
    self fe_ActivatePractice();
}

FireEnterLoadedMessage()
{
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Fire Enter Practice Loaded");
}

// Options (dvars keep them through fast_restart). Each action bind flips one option for the next
// fast restart; reset_patch puts them all back to the defaults (11:10, 2 Box, barrier on).
FireEnterSettings()
{
    level flag::wait_till("initial_blackscreen_passed");
    self thread ShowControls(Array(
        Array("action1", "Fire Enter Time: " + FireEnterOptionText(0, GetDvarInt("practice_fire_enter_late"))),
        Array("action2", "Splits: " + FireEnterOptionText(1, GetDvarInt("practice_splits_old"))),
        Array("action3", "R2L Death Barrier: " + FireEnterOptionText(2, GetDvarInt("practice_death_barrier_off"))),
        Array("reset_patch", "Default Options")));
    self thread FireEnterOptionBind(1, 0, "practice_fire_enter_late", "Fire Enter Time");
    self thread FireEnterOptionBind(2, 1, "practice_splits_old", "Splits");
    self thread FireEnterOptionBind(3, 2, "practice_death_barrier_off", "R2L Death Barrier");
    for(;;)
    {
        WaitBind("reset_patch");
        SetDvar("practice_fire_enter_late", 0);
        SetDvar("practice_splits_old", 0);
        SetDvar("practice_death_barrier_off", 0);
        thread WriteToScreen("Fire Enter Options Reset - Fast Restart To Use Them");
    }
}

FireEnterOptionBind(action, option, dvar, name)
{
    for(;;)
    {
        WaitAction(action);
        value = 1 - GetDvarInt(dvar);
        SetDvar(dvar, value);
        thread WriteToScreen("Next " + name + ": " + FireEnterOptionText(option, value) + " - Fast Restart To Use It");
    }
}

FireEnterOptionText(option, value)
{
    switch(option)
    {
        case 0:
            if(value) return "11:40";
            return "11:10";
        case 1:
            if(value) return "3 Box";
            return "2 Box";
        default:
            if(value) return "Off";
            return "On";
    }
}

// Fire Enter robot order (called from the robot_cycling detour in Detours/giant_robot.gsc
// after the intro walk): Odin first, then singles alternate Freya / Thor; once all staffs are
// placed the next trios gives Odin the hatch.
FireEnterRobotCycling()
{
	order = array(0);
	index = 0;
	three_robot_round = 4;
	last_robot = -1;
	while(true)
	{
		if(!(level.round_number % 4) && three_robot_round != level.round_number)
		{
			level flag::set("three_robot_round");
		}
		if(level flag::get("ee_all_staffs_placed") && !level flag::get("ee_mech_zombie_hole_opened"))
		{
			level flag::set("three_robot_round");
			order = array(0);
			index = 0;
		}
		if(level flag::get("three_robot_round"))
		{
			level.zombie_ai_limit = 22;
			if(IsDefined(order[index]))
			{
				random_number = order[index];
				index++;
			}
			else random_number = RandomInt(3);
			if(random_number == 2 || level flag::get("all_robot_hatch"))
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2);
			}
			else
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2, 0);
			}
			wait(5);
			if(random_number == 0 || level flag::get("all_robot_hatch"))
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](0);
			}
			else
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](0, 0);
			}
			wait(5);
			if(random_number == 1 || level flag::get("all_robot_hatch"))
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](1);
			}
			else
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](1, 0);
			}
			level waittill("giant_robot_walk_cycle_complete");
			level waittill("giant_robot_walk_cycle_complete");
			level waittill("giant_robot_walk_cycle_complete");
			wait(5);
			level.zombie_ai_limit = 24;
			three_robot_round = level.round_number;
			last_robot = -1;
			level flag::clear("three_robot_round");
		}
		else
		{
			if(IsDefined(order[index]))
			{
				random_number = order[index];
				index++;
			}
			else
			{
				if(last_robot == 2) random_number = 1;
				else random_number = 2;
			}
			last_robot = random_number;
			level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](random_number);
			level waittill("giant_robot_walk_cycle_complete");
			wait(5);
		}
	}
}

// First recapture picks one of generators 2-5 while Fire Enter Practice is loaded, and every
// recapture does while Origins Soft Patch is loaded; otherwise this is the game's own get_recapture_zone.
detour zm_tomb_capture_zones<scripts\zm\zm_tomb_capture_zones.gsc>::get_recapture_zone(s_last_recapture_zone)
{
	a_s_player_zones = [];
	foreach(str_key, s_zone in level.zone_capture.zones)
	{
		if(s_zone flag::get("player_controlled"))
		{
			a_s_player_zones[str_key] = s_zone;
		}
	}
	// Origins Soft Patch: every recapture (and the closest-zone pick) only uses generators 2-5 while one is held
	if(IsTrue(level.tomb_soft_active))
	{
		allowed = [];
		foreach(str_key in Array("generator_tank_trench", "generator_mid_trench", "generator_nml_right", "generator_nml_left"))
		{
			if(IsDefined(a_s_player_zones[str_key])) allowed[str_key] = a_s_player_zones[str_key];
		}
		if(allowed.size) a_s_player_zones = allowed;
	}
	s_recapture_zone = undefined;
	if(a_s_player_zones.size)
	{
		if(isdefined(s_last_recapture_zone))
		{
			n_distance_closest = undefined;
			foreach(s_zone in a_s_player_zones)
			{
				n_distance = distancesquared(s_zone.origin, s_last_recapture_zone.origin);
				if(!isdefined(n_distance_closest) || n_distance < n_distance_closest)
				{
					s_recapture_zone = s_zone;
					n_distance_closest = n_distance;
				}
			}
		}
		else if(!IsTrue(level.fire_enter_active) || IsTrue(level.tomb_soft_active))
		{
			s_recapture_zone = array::random(a_s_player_zones);
		}
		else
		{
			gen = randomintrange(2, 6);
			switch(gen)
			{
				case 2:
					s_recapture_zone = a_s_player_zones["generator_tank_trench"];
					break;
				case 3:
					s_recapture_zone = a_s_player_zones["generator_mid_trench"];
					break;
				case 4:
					s_recapture_zone = a_s_player_zones["generator_nml_right"];
					break;
				case 5:
					s_recapture_zone = a_s_player_zones["generator_nml_left"];
					break;
			}
		}
	}
	return s_recapture_zone;
}

fe_ActivatePractice()
{
    level flag::wait_till("start_zombie_round_logic");
    wait 1;

    // Options are changed with the universal binds (FireEnterSettings) and saved in dvars
    b_fire_enter_late = GetDvarInt("practice_fire_enter_late");
    b_splits_old = GetDvarInt("practice_splits_old");
    level.b_splits_old = b_splits_old; //so fe_orgies()/utility.gsc split functions in timer.gsc/utility.gsc can see it
    b_death_barrier_off = GetDvarInt("practice_death_barrier_off"); //0 = YES/barrier on, 1 = NO/barrier off

    self thread fe_monitor_zombies_spawns();
    self thread fe_run_round_timer();

    
    IPrintLnBold("Switch To Mauser + Pickup Shovel");

    wait 6;

    SetDvar("timescale", 10);

    wait 1;

    self.score = 7000;

    //Base game forces the first dig ever (dig_vars["n_spots_dug"] == 0) to always roll a "good"
    //prize (powerup/weapon), never a zombie/grenade. n_spots_dug is a single global counter that
    //every dig anywhere increments, so seed it to the sum of a real run's digs across all 3 ice
    //piece zones by this point: bunker 2-5, nml 2-5, village 1-3.
    if (!isdefined(self.dig_vars))
        self.dig_vars = [];
    self.dig_vars["n_spots_dug"] = randomintrange(2, 6) + randomintrange(2, 6) + randomintrange(1, 4);

	level flag::wait_till("initial_blackscreen_passed");

    self TakeWeapon(self GetCurrentWeapon());
    wait 0.5;
    self TakeWeapon(self GetCurrentWeapon());
    wait 0.5;
    self zm_weapons::weapon_give(GetWeapon("pistol_c96_upgraded"));
    wait 0.5;
    self zm_weapons::weapon_give(GetWeapon("smg_versatile"));
    wait 0.5;
    self zm_weapons::weapon_give(level.w_beacon);

    //Ice Tombstones + Code Complete - Light Switches Turned
    level flag::set("ice_puzzle_1_complete");
    wait 2;
	level flag::set("ice_puzzle_2_complete");
    wait 2.5;

    //Gaobblegums 
    self thread bgb::give("zm_bgb_self_medication");

    wait 0.5;

    self thread fe_give_all_perks();
    wait 0.5;
    self thread fe_OpenAllDoors();
    wait 0.5;
    self thread fe_OpenAllPower();
    wait 0.5;
    self thread fe_EnableTeleporters();
    wait 0.5;
    self  thread fe_TriggerCrypt(); //Opens Mound
    wait 0.5;
    self thread fe_SendTank();
    wait 0.5;
    self thread fe_PickupFire();
    if (b_fire_enter_late)
        wait 38;
    else
        wait 8;
    level thread fe_SetRound();

    wait 1;

    //Maxis + Gram
    self thread zm_craftables::player_get_craftable_piece("equip_dieseldrone", "body");
    self thread zm_craftables::player_get_craftable_piece("equip_dieseldrone", "brain");
    self thread zm_craftables::player_get_craftable_piece("equip_dieseldrone", "engine");
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_player");
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_master");

    //Fire
    self thread zm_craftables::player_get_craftable_piece("elemental_staff_fire", "middle_staff");
    self thread zm_craftables::player_get_craftable_piece("elemental_staff_fire", "upper_staff");
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_fire");

    //Light
    //Tied to the death barrier choice: only hand this piece out when the barrier is off (NO) --
    //with the barrier on (YES), the player is expected to get it for real instead.
    if (b_death_barrier_off)
        self thread zm_craftables::player_get_craftable_piece("elemental_staff_lightning", "upper_staff");
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_elec");

    //Wind
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_air");

    //Ice
    self thread zm_craftables::player_get_craftable_piece("gramophone", "vinyl_water");

    wait 1;

    //Makes Staffs Visible & Gives Pieces
    foreach(craft in GetArrayKeys(level.zombie_include_craftables))
    {
        if(!IsSubStr(craft, "water")) continue;
        foreach(piece in level.zombie_include_craftables[craft].a_piecestubs)
        {
            self thread zm_craftables::player_get_craftable_piece(piece.craftablename, piece.pieceName);
        }
        if(IsDefined(level.zombie_include_craftables[craft].onfullycrafted)) [[level.zombie_include_craftables[craft].onfullycrafted]]();
    }

    foreach(craft in GetArrayKeys(level.zombie_include_craftables))
    {
        if(!IsSubStr(craft, "air")) continue;
        foreach(piece in level.zombie_include_craftables[craft].a_piecestubs)
        {
            self thread zm_craftables::player_get_craftable_piece(piece.craftablename, piece.pieceName);
        }
        if(IsDefined(level.zombie_include_craftables[craft].onfullycrafted)) [[level.zombie_include_craftables[craft].onfullycrafted]]();
    }

    wait 1;
    self thread fe_CraftStuff();
    wait 0.5;
    self zm_weapons::weapon_give(GetWeapon("staff_air"));

    //Ice Dials
    discs = getentarray("crypt_puzzle_disc", "script_noteworthy");
	prev_disc_pos = 0;
	foreach(disc in discs)
	{
		if(!isdefined(disc.target))
		{
			continue;
		}
		disc.position = 0;
		prev_disc_pos = disc.position;
	}
	fe_chamber_discs_move_all_to_position(discs);

    wait 1;

    self thread fe_ActivateGem("Ice");

    //Fire Tunnel TP
    self SetOrigin((3131.87, 4503.79, -603.741));
    self SetPlayerAngles((0,76,0));

    wait 1;

    foreach(index, box in getentarray("foot_box", "script_noteworthy"))
    {
        box thread fe_WatchSouls(index);
    }

    wait 7;

    //We hand out the ice staff pieces directly above instead of digging them up for real, so
    //level.ice_staff_pieces (populated by the base game's own EE setup thread, which has long
    //since run by this point) still thinks all 3 are undug. Left alone, that permanently locks
    //dig spots in the bunker/nml/village zones into always giving a staff piece and never rolling
    //the normal loot table, making "dig a zombie" impossible there. Clear it to match reality.
    level.ice_staff_pieces = [];

    SetDvar("timescale", 1);

    //600 ticks = 30s at the 0.05 tick length used by fe_game_time()/splits. Pure display offset,
    //not a real wait -- the actual 11:40 timing comes from the wait 8/38 branch above.
    level.n_split_tick_offset = 13204;
    if (b_fire_enter_late)
        level.n_split_tick_offset += 600;

    IPrintLnBold("Self Med In Pocket -> Fresh Cycle");

    self thread fe_game_time();
    self thread fe_orgies();

    level waittill("electric_puzzle_1_complete");
    wait 5;
    level flag::set("electric_puzzle_2_complete");
}

fe_monitor_zombies_spawns()
{
    last_counted_total = -1;
    last_counted_current = -1;

    hud_total = fe_zombie_hud(-15, 20, (1, 0, 0));
    hud_current = fe_zombie_hud(-20, 35, (0, 1, 0));

    for(;;)
    {
        current = zombie_utility::get_current_zombie_count(); // counts every zombie; once per frame
        if(level.zombie_total + current != last_counted_total)
        {
            last_counted_total = level.zombie_total + current;
            hud_total SetText("Zombies Remaining: " + last_counted_total);
        }
        if(current != last_counted_current)
        {
            last_counted_current = current;
            hud_current SetText("Zombies Spawned: " + last_counted_current);
        }
        wait 0.05;
    }
}

fe_abh()
{
    spawn_points = struct::get_array("player_respawn_point", "targetname");
    location = Array(18, 19, 9, 10, 15, 11, 4, 0, 3, 5);

    choice1 = location[randomintrange(0, 10)];
    choice2 = location[randomintrange(0, 5)];
	choice3 = location[randomintrange(0, 10)];
    choice4 = location[randomintrange(0, 10)];
	choice5 = location[randomintrange(0, 10)];

    switch(level.abh_index)
    { 
		case 0:
            spawn_point = spawn_points[choice1];
            break;
        case 1:
            spawn_point = spawn_points[choice2];
            break;
        case 2:
            spawn_point = spawn_points[choice3];
            break;
        case 3:
            spawn_point = spawn_points[choice4];  
            break;
        case 4:
            spawn_point = spawn_points[choice5];
            break;
    }
    spawns = struct::get_array(spawn_point.target, "targetname");
    foreach(spawn in spawns)
    {
        n_script_int = self getentitynumber() + 1;
        if(spawn.script_int === n_script_int)
        {
            spot = spawn;
        }
    }
    level.abh_index++;
    if(level.abh_index >= 4) level.var_2c12d9a6 = undefined;
    return spot;
}

fe_give_all_perks()
{
	perks = GetArrayKeys(level._custom_perks);
	foreach(player in level.players)
	{
		foreach(perk in perks)
		{
			if(!player hasPerk(perk)) player zm_perks::give_perk(perk, 0);
		}
	}
}



fe_init_hud(x, y, color)
{
	hud = NewClientHudElem(self);

	hud.alignX = "left";
	hud.alignY = "top";
	hud.horzAlign = "user_left";
	hud.vertAlign = "user_top";
	hud.foreground = false;
	hud.hidewheninmenu = false;
	hud.x = x;
	hud.y = y;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontScale = 1.3;
	hud.color = color;
	
	return hud;
}

fe_timer_hud()
{
    hud = NewHudElem();

	hud.alignX = "left";
	hud.alignY = "top";
	hud.horzAlign = "user_left";
	hud.vertAlign = "user_top";
	hud.foreground = true;
	hud.hidewheninmenu = false;
	hud.x = 0;
	hud.y = 5;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontScale = 1.5;
	hud.color = (1,1,1);
	
	return hud;
}

fe_zombie_hud(x, y, color)
{
	hud = NewClientHudElem(self);

	hud.alignX = "left";
	hud.alignY = "top";
	hud.horzAlign = "user_left";
	hud.vertAlign = "user_top";
	hud.foreground = false;
	hud.hidewheninmenu = false;
	hud.x = 15;
	hud.y = y;
	hud.alpha = 1;
	hud.font = "default";
	hud.fontScale = 1.3;
	hud.color = color;
	
	return hud;
}

fe_create_new_round_timer()
{
    level.round_timer = fe_init_hud(15, 50, (1, 1, 1));
    level.round_timer SetTenthsTimerUp(0.05);
    level.round_timer.label = &"^7Round Time: ^2";
}

fe_run_round_timer()
{
    while(!IsDefined(level.n_gameplay_start_time)) wait 0.05;
    fe_create_new_round_timer();
    recent_round = level.round_number;
    for(;;){
        if (level.round_number!=recent_round)
        {
            level.round_timer Destroy();
            fe_create_new_round_timer();
            recent_round = level.round_number;
        }
        wait 0.05;
    }
}

fe_OpenAllDoors()
{
    types = array("zombie_door", "zombie_airlock_buy", "zombie_debris");
    foreach(type in types)
    {
        doors = GetEntArray(type, "targetname");
        foreach(door in doors)
        {
			switch(type)
			{
				case "zombie_door":
					door thread zm_blockers::door_opened(door.zombie_cost, 0);
					break;
				case "zombie_airlock_buy":
					door thread fe_OpenAirlock();
					break;
				case "zombie_debris":
					door thread fe_OpenDebris();
					break;
			}
        }
    }

	switch(level.script)
	{
		case "zm_island":
			gate = GetEnt("pap_gate", "targetname");
			gate MoveTo(gate.s_pos.origin, 3);
			break;
	}
}

fe_OpenDebris()
{
	junk = GetEntArray(self.target, "targetname");
	if(isdefined(self.script_flag))
	{
		tokens = StrToK(self.script_flag, ",");
		for(i = 0; i < tokens.size; i++)
		{
			level flag::set(tokens[i]);
		}
	}
	a_clip = [];
	for(i = 0; i < junk.size; i++)
	{
		junk[i] ConnectPaths();
		if(isdefined(junk[i].script_noteworthy))
		{
			if(junk[i].script_noteworthy == "clip")
			{
				a_clip[a_clip.size] = junk[i];
				continue;
			}
		}
		struct = undefined;
		if(junk[i] IsZBarrier())
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
				junk[i] Delete();
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
				junk[i] Delete();
			}
			continue;
		}
		junk[i] Delete();
	}
	a_nd_targets = GetNodeArray(self.target, "targetname");
	foreach(nd_target in a_nd_targets)
	{
		if(isdefined(nd_target.script_noteworthy) && nd_target.script_noteworthy == "air_buy_gate")
		{
			LinkTraversal(nd_target);
		}
	}
	all_trigs = GetEntArray(self.target, "target");
	all_trigs[0] Delete();
	for(i = 0; i < a_clip.size; i++)
	{
		a_clip[i] Delete();
	}
}

fe_OpenAirlock()
{
	if(isdefined(self.script_flag))
	{
		tokens = StrToK(self.script_flag, ",");
		for(i = 0; i < tokens.size; i++)
		{
			level flag::set(tokens[i]);
		}
	}
	for(i = 0; i < self.trigs.size; i++)
	{
		self.trigs[i] TriggerEnable(1);
		self.trigs[i] thread fe_ChangeDoorModels();
	}
	all_trigs = GetEntArray(self.target, "target");
	for(i = 0; i < all_trigs.size; i++)
	{
		all_trigs[i] TriggerEnable(0);
	}
}

fe_ChangeDoorModels()
{
	doors = GetEntArray(self.target, "targetname");
	for(i = 0; i < doors.size; i++)
	{
		if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_lt_locked")
		{
			doors[i] SetModel("p7_zm_moo_door_airlock_heavy_lt");
		}
		else
		{
			if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_rt_locked")
			{
				doors[i] SetModel("p7_zm_moo_door_airlock_heavy_rt");
			}
			else if(isdefined(doors[i].model) && doors[i].model == "p7_zm_moo_door_airlock_heavy_single_locked")
			{
				doors[i] SetModel("p7_zm_moo_door_airlock_heavy_single");
			}
		}
		doors[i] thread fe_AirlockConnectPaths();
	}
}

fe_AirlockConnectPaths()
{
	if(self.classname == "script_brushmodel")
	{
		self NotSolid();
		self ConnectPaths();
		if(!isdefined(self._door_open) || self._door_open == 0)
		{
			self Solid();
		}
	}
}

fe_OpenAllPower()
{
    level flag::set("power_on");
    power_trigs = GetEntArray("use_elec_switch", "targetname");
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
        trigs = GetEntArray("use_elec_switch", "targetname");
        if(IsDefined(trigs))
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
		if (count != 10) // 7+ for early gen || #3 for regular fast 4
		{
			generator fe_CaptureGenerator(self);
			wait 0.5;
		}
	}
}

fe_CaptureGenerator(player)
{
	level.zone_capture.last_zone_captured = self;
	self fe_SetPlayerControlledZone();
	self.n_current_progress = 100;
	level clientfield::set("state_" + self.script_noteworthy, 2);
	level clientfield::set(self.script_noteworthy, self.n_current_progress / 100);
}

fe_SetPlayerControlledZone()
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
	if(!isdefined(self.perk_fx_func) || [[self.perk_fx_func]]())
	{
		level clientfield::set("zone_capture_perk_machine_smoke_fx_" + self.script_int, 1);
	}
	self flag::set("player_controlled");
	fe_UpdateCapturedZoneCount();
	self fe_EnablePerksInZone();
	self fe_EnableRandomPerksInZone();
	self fe_EnableBoxInZone();
	level flag::set("power_on" + self.script_int);
	level notify("zone_captured_by_player", self.str_zone);
}

fe_UpdateCapturedZoneCount()
{
	level.total_capture_zones = fe_GetCapturedZoneCount();
	if(level.total_capture_zones == 6)
	{
		level flag::set("all_zones_captured");
	}
	else
	{
		level flag::clear("all_zones_captured");
	}
}

fe_GetCapturedZoneCount()
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

fe_EnablePerksInZone()
{
	if(IsDefined(self.perk_machines) && IsArray(self.perk_machines))
	{
		a_keys = GetArrayKeys(self.perk_machines);
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

fe_EnableRandomPerksInZone()
{
	if(IsDefined(self.perk_machines_random) && IsArray(self.perk_machines_random))
	{
		foreach(random_perk_machine in self.perk_machines_random)
		{
			random_perk_machine.is_locked = 0;
			if(IsTrue(random_perk_machine.current_perk_random_machine))
			{
				random_perk_machine fe_set_perk_random_machine_state("idle");
				continue;
			}
			random_perk_machine fe_set_perk_random_machine_state("away");
		}
	}
}

fe_set_perk_random_machine_state(State)
{
	wait(0.1);
	for(i = 0; i < self GetNumZBarrierPieces(); i++)
	{
		self HideZBarrierPiece(i);
	}
	self notify("zbarrier_state_change");
	self [[level.perk_random_machine_state_func]](State);
}

fe_EnableBoxInZone()
{
	foreach(mystery_box in self.mystery_boxes)
	{
		mystery_box.is_locked = 0;
		mystery_box.zbarrier [[level.magic_box_zbarrier_state_func]]("player_controlled");
		mystery_box.zbarrier clientfield::set("magicbox_runes", 1);
	}
}

fe_TriggerCrypt()
{
    door = getentarray("chamber_entrance", "targetname")[1];
    trig_position = struct::get(door.targetname + "_position", "targetname");
    level notify("open_sesame");
    trig_position.has_vinyl = 1;
    level.b_open_all_gramophone_doors = 1;
    wait 0.5;
    trig_position.trigger notify("trigger", self);
    wait 1;
    level.b_open_all_gramophone_doors = 0;
}

fe_CraftStuff()
{
    foreach(craft in level.a_uts_craftables)
    {
        if(IsSubStr(craft.targetname, "water") || IsSubStr(craft.targetname, "air"))
        {
            self zm_craftables::player_craft(craft);
        }
        else if(IsSubStr(craft.targetname, "gramophone"))
        {
            craft notify("trigger");
        }
        else if(craft.origin == (2301, 703, 38))
        {
            self zm_craftables::player_craft(craft.craftablestub);
        }
    }
}

fe_WatchSouls(index)
{
    hadBlood = false;
    switch(self.script_int)
    {
        case 0:
            name = "Excavation Box Souls - ";
            break;
        case 1:
            name = "Gen 4 Box Souls - ";
            break;
        case 2:
            name = "Church Box Souls - ";
            break;
        case 3:
            name = "Gen 5 Box Souls - ";
            break;
    }
    hud = fe_timer_hud();
    hud.y = 20 + (15 * index);
    previous_souls = self.n_souls_absorbed;
    num = randomIntRange(20, 25);
    for(;;)
    {
        if(self.n_souls_absorbed > 0 && self.n_souls_absorbed > previous_souls)
        {
            previous_souls = self.n_souls_absorbed;
        }
        if(self.n_souls_absorbed >= 30) break;
        //Gives blood mid way thru gen 5 box
        if(self.script_int == 3 && self.n_souls_absorbed >= num && !hadBlood) //Change 15 to make earlier or later blood
        {
            level.custom_zombie_powerup_drop = ::fe_give_zombie_blood; 
            hadBlood = true;
        }
        wait 0.05;
    }
    hud Destroy();
}

fe_give_zombie_blood(drop_point)
{
	powerup = zm_powerups::specific_powerup_drop("zombie_blood", drop_point);
	level.custom_zombie_powerup_drop = undefined;
	return 1;
}


fe_EnableTeleporters()
{
    level flag::set("enable_teleporter_" + 1);
    level flag::set("enable_teleporter_" + 2);
    level flag::set("enable_teleporter_" + 3);
    level flag::set("enable_teleporter_" + 4);

    wait 1;

    level flag::clear("enable_teleporter_" + 1);
    level flag::clear("enable_teleporter_" + 2);
    level flag::clear("enable_teleporter_" + 3);
    level flag::clear("enable_teleporter_" + 4);
}

fe_ActivateGem(type)
{

    switch(type)
    {
        case "Ice":
            gem_model = "p7_zm_ori_orb_ice";
            staff = "staff_water";
            break;

        case "Lightning":
            gem_model = "p7_zm_ori_orb_lightning";
            staff = "staff_lightning";
            break;

        case "Fire":
            gem_model = "p7_zm_ori_orb_fire";
            staff = "staff_fire";
            break;

        case "Wind":
            gem_model = "p7_zm_ori_orb_wind";
            staff = "staff_air";
            break;

        default:
            gem_model = "p7_zm_ori_orb_ice";
            staff = "staff_water";
            break;
    }

    foreach(entity in GetEntArray("script_model", "classname"))
    {
        if(entity.model == gem_model)
        {
            entity notify("damage", 1, self, (0, 0, 0), entity.origin, undefined, undefined, undefined, undefined, GetWeapon(staff));
        }
    }
}

fe_PickupFire()
{
    foreach(uts_box in level.a_uts_challenge_boxes)
    {
        if(uts_box.str_location == "church_capture")
        {
            uts_box flag::wait_till("waiting_for_grab");
            uts_box flag::clear("waiting_for_grab");
            self zm_craftables::player_take_piece(uts_box.s_staff_piece.piecespawn);
        }
    }
}

fe_SendTank()
{
    level.vh_tank.t_use notify("trigger", self);
}

fe_chamber_discs_move_all_to_position(discs = getentarray("chamber_puzzle_disc", "script_noteworthy"))
{
	level flag::set("disc_rotation_active");
	foreach(e_disc in discs)
	{
		e_disc fe_chamber_disc_move_to_position();
	}
	level flag::clear("disc_rotation_active");
}

fe_chamber_disc_move_to_position()
{
	new_angles = (self.angles[0], self.position * 90, self.angles[2]);
	self rotateto(new_angles, 1, 0, 0);
	self playsound("zmb_crypt_disc_turn");
	wait(1 * 0.75);
	self fe_bryce_cake_light_update(0);
	wait(1 * 0.25);
	self fe_bryce_cake_light_update(0);
	self playsound("zmb_crypt_disc_stop");
}

fe_bryce_cake_light_update(b_on = 1)
{
	if(!isdefined(self.n_bryce_cake))
	{
		self.n_bryce_cake = 0;
	}
	if(!b_on)
	{
		self.n_bryce_cake = (self.n_bryce_cake + 1) % 2;
	}
	else
	{
		self.n_bryce_cake = 2;
	}
	if(isdefined(self.var_b1c02d8a))
	{
		self.var_b1c02d8a clientfield::set("bryce_cake", self.n_bryce_cake);
	}
}

// zombie_goto_round only changes the hidden round counter, so round_think worked out the zombie
// speed from level.round_number (still 1) and round 8 got round 1-2 walkers. Setting level.round_number
// first makes the round change give real round 8 zombies (speed, spawn delay and spawning).
fe_SetRound()
{
	level.round_number = 7;
	zm_utility::zombie_goto_round(8);
	if(level.gamedifficulty == 0)
		level.zombie_move_speed = level.zombie_vars["zombie_move_speed_multiplier_easy"] * 7;
	else
		level.zombie_move_speed = level.zombie_vars["zombie_move_speed_multiplier"] * 7;
}

fe_init_hudelem(alignx, aligny, horzalign, vertalign, x, y, fontscale, alpha, color, hidewheninmenu, label){

    self.alignx = alignx;
    self.aligny = aligny;
    self.horzalign = horzalign;
    self.vertalign = vertalign;
    self.x = x;
    self.y = y;
    self.fontscale = fontscale;
    self.alpha = alpha;
    self.color = color;
    self.hidewheninmenu = hidewheninmenu;
    self.label = label;

}

fe_orgies()
{
    level thread fe_thenumbersmasonwhatdotheymean();

    //level thread fe_icecrafted();
    level thread fe_segmenttimer();
    level thread fe_fireteleported();
    level thread fe_lightningteleported();

    if (level.b_splits_old)
    {
        level thread fe_windteleported();
    }
    else
    {
        level thread fe_lightningcrafted();
        level thread fe_lightningteleportedagain();
    }

    level thread fe_iceteleported();
    level thread fe_allstaffsupgraded();
    level thread fe_endoftheeasteregg();
}

fe_icecrafted()
{
    self endon("disconnect");

    if (!isdefined(level.icecrafted))
    {
        level.icecrafted = newHudElem();
        level.icecrafted fe_init_hudelem("left", "top", "user_left", "user_top", 5, 10, 1.2, 0, (1,1,1), 1, &"^7Ice Craft: ");
    }

    level.icecrafted.alpha = 1;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    level.icecrafted setTenthsTimerUp(0.05);

    level waittill("elemental_staff_water_crafted");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.icecrafted setText(split_time);
}

fe_segmenttimer()
{
    self endon("disconnect");

    if (!isdefined(level.segmenttimer))
    {
        level.segmenttimer = newHudElem();
        level.segmenttimer fe_init_hudelem("left", "top", "user_left", "user_top", 15, 65, 1.3, 1, (1,1,1), 1, &"^7Segment: ^3");
    }

    level.segmenttimer setTenthsTimerUp(0.05);

    level waittill("stop_timer_fire");
    level.segmenttimer setTenthsTimerUp(0.05);

    level waittill("stop_timer_lightning");
    level.segmenttimer setTenthsTimerUp(0.05);

    level waittill("stop_timer_lightning_craft");
    level.segmenttimer setTenthsTimerUp(0.05);

    level waittill("stop_timer_lightning2");
    level.segmenttimer setTenthsTimerUp(0.05);

    level waittill("stop_timer_ice");
    level.segmenttimer setTenthsTimerUp(0.05);

    level flag::wait_till("ee_all_staffs_upgraded");
    level.segmenttimer setTenthsTimerUp(0.05);

    level flag::wait_till("ee_samantha_released");
}

fe_fireteleported()
{
    self endon("disconnect");

    if (!isdefined(level.fireteleported))
    {
        level.fireteleported = newHudElem();
        level.fireteleported fe_init_hudelem("left", "top", "user_left", "user_top", 15, 80, 1.3, 0, (1,1,1), 1, &"^7Fire Enter: ");
    }

    level.fireteleported.alpha = 1;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.fireteleported SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.fireteleported setText(split_time);
}

fe_lightningteleported()
{
    self endon("disconnect");

    if (!isdefined(level.lightningteleported))
    {
        level.lightningteleported = newHudElem();
        level.lightningteleported fe_init_hudelem("left", "top", "user_left", "user_top", 15, 95, 1.3, 0, (1,1,1), 1, &"^7Light Enter: ");
    }

    level.lightningteleported.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.lightningteleported SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level.lightningteleported.alpha = 1;
    level waittill("stop_timer_lightning");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.lightningteleported setText(split_time);
}

//Old splits variant only (level.b_splits_old). Position matches where Light Craft sits in the
//new variant since only one of the two ever runs.
fe_windteleported()
{
    self endon("disconnect");

    if (!isdefined(level.windteleported))
    {
        level.windteleported = newHudElem();
        level.windteleported fe_init_hudelem("left", "top", "user_left", "user_top", 15, 110, 1.3, 0, (1,1,1), 1, &"^7Wind Enter: ");
    }

    level.windteleported.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.windteleported SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level waittill("stop_timer_lightning");
    level.windteleported.alpha = 1;
    level waittill("stop_timer_wind");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.windteleported setText(split_time);
}

fe_lightningcrafted()
{
    self endon("disconnect");

    if (!isdefined(level.lightningcrafted))
    {
        level.lightningcrafted = newHudElem();
        level.lightningcrafted fe_init_hudelem("left", "top", "user_left", "user_top", 15, 110, 1.3, 0, (1,1,1), 1, &"^7Light Craft: ");
    }

    level.lightningcrafted.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.lightningcrafted SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level waittill("stop_timer_lightning");
    level.lightningcrafted.alpha = 1;
    level waittill("stop_timer_lightning_craft");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.lightningcrafted setText(split_time);
}

fe_lightningteleportedagain()
{
    self endon("disconnect");

    if (!isdefined(level.lightningteleportedagain))
    {
        level.lightningteleportedagain = newHudElem();
        level.lightningteleportedagain fe_init_hudelem("left", "top", "user_left", "user_top", 15, 125, 1.3, 0, (1,1,1), 1, &"^7Light Enter 2: ");
    }

    level.lightningteleportedagain.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.lightningteleportedagain SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level waittill("stop_timer_lightning");
    level waittill("stop_timer_lightning_craft");
    level.lightningteleportedagain.alpha = 1;
    level waittill("stop_timer_lightning2");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.lightningteleportedagain setText(split_time);
}

fe_iceteleported()
{
    self endon("disconnect");

    if (!isdefined(level.iceteleported))
    {
        level.iceteleported = newHudElem();
        n_y = level.b_splits_old ? 125 : 140;
        level.iceteleported fe_init_hudelem("left", "top", "user_left", "user_top", 15, n_y, 1.3, 0, (1,1,1), 1, &"^7Ice Leave: ");
    }

    level.iceteleported.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.iceteleported SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level waittill("stop_timer_lightning");
    if (level.b_splits_old)
    {
        level waittill("stop_timer_wind");
    }
    else
    {
        level waittill("stop_timer_lightning_craft");
        level waittill("stop_timer_lightning2");
    }
    level.iceteleported.alpha = 1;
    level waittill("stop_timer_ice");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.iceteleported setText(split_time);
}

fe_allstaffsupgraded()
{
    self endon("disconnect");

    if (!isdefined(level.allstaffsupgraded))
    {
        level.allstaffsupgraded = newHudElem();
        n_y = level.b_splits_old ? 140 : 155;
        level.allstaffsupgraded fe_init_hudelem("left", "top", "user_left", "user_top", 15, n_y, 1.3, 0, (1,1,1), 1, &"^7Staffs Upgraded: ");
    }

    level.allstaffsupgraded.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.allstaffsupgraded SetTimerUp(n_timer_start);

    level waittill("stop_timer_fire");
    level waittill("stop_timer_lightning");
    if (level.b_splits_old)
    {
        level waittill("stop_timer_wind");
    }
    else
    {
        level waittill("stop_timer_lightning_craft");
        level waittill("stop_timer_lightning2");
    }
    level waittill("stop_timer_ice");
    level.allstaffsupgraded.alpha = 1;
    level flag::wait_till("ee_all_staffs_upgraded");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.allstaffsupgraded setText(split_time);
}

fe_endoftheeasteregg()
{
    self endon("disconnect");

    if (!isdefined(level.endoftheeasteregg))
    {
        level.endoftheeasteregg = newHudElem();
        n_y = level.b_splits_old ? 155 : 170;
        level.endoftheeasteregg fe_init_hudelem("left", "top", "user_left", "user_top", 15, n_y, 1.3, 0, (1,1,1), 1, &"^7End: ");
    }

    level.endoftheeasteregg.alpha = 0;
    n_first_tick = level.ticks;
    n_tick_offset = level.n_split_tick_offset;
    n_timer_start = 0 - (n_tick_offset * 0.05);
    level.endoftheeasteregg SetTimerUp(n_timer_start);

    level flag::wait_till("ee_all_staffs_upgraded");
    level.endoftheeasteregg.alpha = 1;
    level flag::wait_till("ee_samantha_released");

    n_last_tick = level.ticks + n_tick_offset;

    split_time = fe_timecalculated_ticks(n_first_tick, n_last_tick);

    level.endoftheeasteregg setText(split_time);
}

fe_timecalculated_ticks(start_tick, end_tick)
{
    time_taken_s = (end_tick - start_tick) * 0.05;

    min = int(time_taken_s / 60);
    seconds = int(time_taken_s) % 60;
    ms = int((time_taken_s - int(time_taken_s)) * 100);

    if (min > 0)
        return min + ":" + ((seconds < 10) ? "0" + seconds : seconds);
    else
        return ((seconds < 10) ? "0" + seconds : seconds);
}

fe_game_time()
{
	level.tick = 0.05;
	level.ticks = 0;

	while(true)
        {
		wait level.tick;
		level.ticks++;
	}
}

fe_thenumbersmasonwhatdotheymean()
{
    thread fe_checkfortheteleportlol("Fire", 1, "teleport_fire", "stop_timer_fire");

    if (level.b_splits_old)
    {
        thread fe_checkfortheteleportlolwindthenice("Wind", 2, "teleport_wind", "stop_timer_wind_ice");
        thread fe_checkfortheteleportlol("Lightning", 3, "teleport_lightning", "stop_timer_lightning");
    }
    else
    {
        thread fe_checkfortheteleportlollightningtwice(3, "teleport_lightning", "stop_timer_lightning", "stop_timer_lightning2");
        thread fe_checkforlightningcraft("stop_timer_lightning_craft");
        thread fe_checkforsecondlightningenterthenice("stop_timer_lightning2", "stop_timer_ice");
    }
}

// Old Wind-route watcher: fires stop_timer_wind on the Wind pad, then 10s later starts polling
// for the player's Ice teleport to fire stop_timer_ice. Only used when level.b_splits_old is set.
fe_checkfortheteleportlolwindthenice(name, script_int_value, flag_name, timer_event)
{
    for (;;)
    {
        level waittill("player_teleported", player, script_int);

        if (script_int == script_int_value)
        {

            level notify("stop_timer_wind");

            wait(10);

            for (;;)
            {
                foreach (p in GetPlayers())
                {
                    if (isdefined(p.teleporting) && p.teleporting)
                    {
                        level.teleport_ice = true;

                        level notify("stop_timer_ice");
                        return;
                    }
                }
                wait(0.05);
            }
        }
    }
}

fe_checkfortheteleportlol(name, script_int_value, flag_name, timer_event)
{
    for (;;)
    {
        level waittill("player_teleported", player, script_int);

        if (script_int == script_int_value)
        {
            level notify(timer_event);
        }
    }
}

// Lightning pad is used twice in this route (once before crafting the staff,
// once after). First occurrence fires first_event, second fires second_event.
fe_checkfortheteleportlollightningtwice(script_int_value, flag_name, first_event, second_event)
{
    count = 0;

    for (;;)
    {
        level waittill("player_teleported", player, script_int);

        if (script_int == script_int_value)
        {
            count++;

            if (count == 1)
                level notify(first_event);
            else if (count == 2)
                level notify(second_event);
        }
    }
}

fe_checkforlightningcraft(timer_event)
{
    level waittill("elemental_staff_lightning_crafted");
    level notify(timer_event);
}

fe_checkforsecondlightningenterthenice(wait_event, timer_event)
{
    level waittill(wait_event);

    wait(10);

    for (;;)
    {
        foreach (p in GetPlayers())
        {
            if (isdefined(p.teleporting) && p.teleporting)
            {
                level.teleport_ice = true;

                level notify(timer_event);
                return;
            }
        }
        wait(0.05);
    }
}
