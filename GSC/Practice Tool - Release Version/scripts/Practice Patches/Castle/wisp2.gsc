Wisp2Practice()
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
    thread WriteToScreen("Wisp 2 Practice Loaded");
    level thread DE_NoPanzerLift();
    level flag::clear("spawn_zombies");
    level flag::set("story_playing");
    level flag::set("castle_teleporter_used");
    level flag::set("ee_start_done");
    // counts as the death ray having been used once, so the monitors show the safe code inputs once
    // the fuse is in (the game only shows them after the death ray has been fired)
    level flag::set("death_ray_trap_used");
    Timescale(10);
    self.score = 4500;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    self thread GiveAllPerks();
    self zm_weapons::weapon_give(GetWeapon("ar_cqb"));
    self zm_weapons::weapon_give(GetWeapon("pistol_standard"));
    self FinishStorm();
    while(!self HasWeapon(GetWeapon("elemental_bow_storm"))) wait 0.05;
    self bgb::give("zm_bgb_extra_credit");
    // the next gum out of the machine is Anywhere But Here, then the rest of the pack in a random order
    self.bgb_pack_randomized = Array("zm_bgb_anywhere_but_here");
    foreach(gum in array::randomize(Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_extra_credit"))) self.bgb_pack_randomized[self.bgb_pack_randomized.size] = gum;
    thread SkipToRound(7, 1);
    wait 2;
    level flag::set("time_travel_teleporter_ready");
    tele = GetEntArray("trigger_teleport_pad", "targetname")[0];
    self SetOrigin(tele.origin);
    wait 0.25;
    tele notify("trigger", self);
    level thread wp2_RoundEightBeforeReturn();
    wait 25;
    Timescale(1);
    IPrintLnBold("Read Safe Code");
    wait 7;
    Timescale(10);
    fuse = struct::get("ee_lab_fuse");
    canister = struct::get("mpd_canister");
    fuse_found = 0;
    canister_found = 0;
    for(;;)
    {
        foreach(stub in level._unitriggers.trigger_stubs)
        {
            if(!fuse_found && fuse.origin == stub.origin)
            {
                self BuildAndActivateTrigger(stub);
                fuse_found = 1;
            }
            if(!canister_found && canister.origin == stub.origin)
            {
                self BuildAndActivateTrigger(stub);
                canister_found = 1;
            }
        }
        if(fuse_found && canister_found) break;
        wait 0.05;
    }
    level flag::wait_till("spawn_zombies");
    Timescale(1);
    self thread HoldStormBowOnReturn();
    level thread ChargedBowWarning();
    level flag::clear("story_playing");
}

// Round 8 starts while you're in the past, timed so the first wisp of the second set shows up about
// when you get back (like a real run). The past lasts 37 seconds from the teleport; after the round
// ends there's the 10 second break, then the game waits 9 seconds before the first wisp.
wp2_RoundEightBeforeReturn()
{
    wait 17;
    // drop the wisp that's still up from the start, so the step waits for the new round like it does
    // after a failed wisp (otherwise the round change could be missed)
    if(IsDefined(level.var_a0ef3c5e))
    {
        level flag::set("reset_time_travel_target");
        while(level flag::get("reset_time_travel_target")) wait 0.05;
    }
    level thread wp2_ClearRound();
    level waittill("end_of_round");
    level notify("wp2_round_cleared");
}

// keep round 7 empty until it ends (no zombies spawn in the past, so this is just the leftover count)
wp2_ClearRound()
{
    level endon("wp2_round_cleared");
    for(;;)
    {
        level.zombie_total = 0;
        foreach(zombie in GetAITeamArray(level.zombie_team)) if(IsAlive(zombie)) zombie Kill();
        wait 0.5;
    }
}
