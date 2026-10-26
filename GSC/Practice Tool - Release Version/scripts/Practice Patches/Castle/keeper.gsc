KeeperPractice()
{
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    self.bgb_pack = Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_extra_credit");
 	level.players[0].bgb_pack = Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_extra_credit");
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Keeper Practice Loaded");
    level thread DE_NoPanzerLift();
    level flag::clear("spawn_zombies");
    level flag::set("story_playing");
    Timescale(10);
    self.score = 10000;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    self thread GiveAllPerks();
    FinishStorm();
    while(!self HasWeapon(GetWeapon("elemental_bow_storm"))) wait 0.05;
    self zm_weapons::weapon_give(GetWeapon("ar_cqb"));
    self zm_weapons::weapon_give(GetWeapon("pistol_standard"));
    self TimeTravel(2);
    self SimonSays();
    self ActivateDempsey();
    thread SkipToRound(9);
    level flag::set("time_travel_teleporter_ready");
    tele = GetEntArray("trigger_teleport_pad", "targetname")[1];
    self SetOrigin(tele.origin);
    wait 0.25;
    tele notify("trigger", self);
    key_slot = struct::get("golden_key_slot_past");
    key_slot notify("trigger_activated");
    wait 0.5;
    tablet = GetEnt("stone_past", "targetname");
    tablet notify("trigger_activated");
    level flag::wait_till("channeling_stone_replacement");
    level flag::wait_till("spawn_zombies");
    Timescale(1);
    self thread HoldStormBowOnReturn();
    level thread ChargedBowWarning();
    level notify("hash_b5927dd");
    self thread kp_PickupBackup();
    level thread PracticeRoundTimer();
    level thread kp_RodTimer();
    thread KeeperProgress();
    level flag::clear("story_playing");
    level.var_1f18338d = "storm";
}

KeeperProgress()
{
    while(!IsDefined(GetEnt("keeper_archon_ai", "targetname"))) wait 0.05;
    progress = hud::createfontstring("big", 1.25);
    progress hud::setpoint("TOPLEFT", "TOPLEFT", 20, 5);
    progress.alpha = 1;
    progress SetText("Keeper Moving");
    keeper = GetEnt("keeper_archon_ai", "targetname");
    wait 5;
    while(!IsDefined(level.var_8ef26cd9))
    {
        keeper waittill("goal");
        thread UpdateProgress(progress);
        while(!KeeperCanMove()) wait 0.05;
        level notify("keeper_update_stop");
        progress SetText("Keeper Moving");
    }
    progress SetText("Keeper Finished!");
    wait 3;
    progress FadeOverTime(5);
    progress.alpha = 0;
    wait 5;
    progress Destroy();
}

UpdateProgress(progress)
{
    level endon("keeper_update_stop");
    while(level.var_8bdb0713) wait 0.05;
    souls = level.var_8bdb0713;
    progress SetText("Keeper Progress: " + souls + "/" + BowSoulCount());
    for(;;)
    {
        if(souls != level.var_8bdb0713)
        {
            souls = level.var_8bdb0713;
            progress SetText("Keeper Progress: " + souls + "/" + BowSoulCount());
        }
        wait 0.05;
    }
}

KeeperCanMove()
{
	cam_move = 0;
	if(level.var_8bdb0713 >= BowSoulCount())
	{
		if(IsTrue(level.var_f91118d9))
		{
			cam_move = 1;
		}
		else if(level.var_8bdb0713 >= PreRoundEndMove())
		{
			cam_move = 1;
		}
	}
	return cam_move;
}

BowSoulCount()
{
	soul_count = 16;
	switch(level.var_1f18338d)
	{
		case "demongate":
		{
			soul_count = 17;
			break;
		}
		case "rune_prison":
		{
			soul_count = 16;
			break;
		}
		case "storm":
		{
			soul_count = 20;
			break;
		}
		case "wolf_howl":
		{
			soul_count = 18;
			break;
		}
		default:
		{
			break;
		}
	}
	return soul_count;
}

PreRoundEndMove()
{
	soul_count = BowSoulCount();
	n_players = level.players.size;
	multiplier = 4 - (n_players - 1);
	soul_count = soul_count * multiplier;
	return soul_count;
}

// Backup for the 2 pickups that didn't work in this patch: the Ragnarok piece the panzer drops and
// the vril generator (the gold rod from the crashed rocket), plus placing the vril generator.
// Walk up to one and press use: if the game's own pickup didn't take it, this does. The first time it
// has to step in it also prints why the game refused (so the real cause can be fixed later).
kp_PickupBackup()
{
    self endon("disconnect");
    level endon("end_game");
    told = 0;
    for(;;)
    {
        while(!self UseButtonPressed()) wait 0.05;
        // give the game's own pickup a moment first
        wait 0.3;
        used = self kp_TryBackupPickup();
        if(used && !told)
        {
            told = 1;
            drinking = 0;
            if(IsDefined(self.is_drinking)) drinking = self.is_drinking;
            IPrintLn("Pickup backup used - drinking: " + drinking + " valid: " + zm_utility::is_player_valid(self) + " revive trig: " + self zm_utility::in_revive_trigger());
        }
        while(self UseButtonPressed()) wait 0.05;
    }
}

kp_TryBackupPickup()
{
    // Ragnarok pieces lying on the ground
    stubs = ArrayCombine(level._unitriggers.trigger_stubs, level._unitriggers.dynamic_stubs, 1, 0);
    foreach(stub in stubs)
    {
        if(!IsDefined(stub) || !IsDefined(stub.piece) || !IsDefined(stub.piece.craftablename)) continue;
        if(stub.piece.craftablename != "gravityspike") continue;
        if(DistanceSquared(self.origin, stub.origin) > 96 * 96) continue;
        self thread zm_craftables::player_take_piece(stub.piece);
        return 1;
    }
    // the vril generator that has to be picked up
    foreach(model in GetEntArray("script_model", "classname"))
    {
        if(!IsDefined(model) || model.model !== "p7_zm_ctl_vril_generator" || !IsDefined(model.s_unitrigger)) continue;
        if(!IsTrue(model.s_unitrigger.registered)) continue;
        if(DistanceSquared(self.origin, model.origin) > 96 * 96) continue;
        model notify("trigger_activated", self);
        return 1;
    }
    // where the vril generator gets placed
    spot = struct::get("vril_generator_family");
    if(IsDefined(spot) && IsDefined(spot.s_unitrigger) && IsTrue(spot.s_unitrigger.registered) && DistanceSquared(self.origin, spot.origin) <= 96 * 96)
    {
        spot notify("trigger_activated", self);
        return 1;
    }
    return 0;
}

kp_Hud(y, label)
{
    hud = NewHudElem();
    hud.alignx = "right";
    hud.aligny = "top";
    hud.horzalign = "user_right";
    hud.vertalign = "user_top";
    hud.x = -15;
    hud.y = y;
    hud.fontscale = 1.5;
    hud.hidewheninmenu = 1;
    hud.label = label;
    return hud;
}

// Keeper timer, top right under the round timer: starts when the gold rod (vril generator) is placed
// and stops when the keeper is done (the time stays on screen).
kp_RodTimer()
{
    spot = struct::get("vril_generator_family");
    if(!IsDefined(spot)) return;
    spot waittill("trigger_activated");
    start = GetTime();
    timer = kp_Hud(55, &"^3Keeper Time: ^2");
    timer SetTenthsTimerUp(0.05);
    while(!IsDefined(level.var_8ef26cd9)) wait 0.05;
    time = GetTime() - start;
    timer Destroy();
    done = kp_Hud(55, &"");
    done SetText("^3Keeper Time: ^2" + CalcTime(time));
}
