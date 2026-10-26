BossQuoteSkipPractice()
{
    WaitFadeIn();
    if(level.script != "zm_stalingrad")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Gorod Krovi");
        return;
    }
    self.bgb_pack = Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_shopping_free");
    level.players[0].bgb_pack = Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_shopping_free");
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Boss Practice Loaded");
    self.score = 50000;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    self thread GiveAllPerks();
    self zm_weapons::weapon_give(level.w_raygun_mark3_upgraded, 1);
    self zm_weapons::weapon_give(GetWeapon("lmg_cqb"));
    self zm_weapons::weapon_give(GetWeapon("sniper_fastsemi"));
    self thread GiveGauntlet();
    self thread GiveDragonStrike();
    self GiveRiotshield(0);
    self DeathBarrierGrace();
    self SetOrigin((-275.725, 4768.26, 144.125));
    self SetPlayerAngles((5.32288, 179.615, 0));
    thread SkipToRound(14);
    level flag::clear("spawn_zombies");
    level flag::set("story_playing");
    IPrintLnBold("Wait...");
    wait 10;
    level flag::clear("story_playing");
    level notify("ee_cylinder_acquired");
    level.var_a090a655 HidePart("button_green_jnt");
	level.var_a090a655 ShowPart("button_red_jnt");
    IPrintLnBold(BindText("action1") + " To Start Countdown");
    WaitAction(1);
    timer = hud::createfontstring("big", 2);
    timer hud::setpoint("TOPLEFT", "TOPLEFT", 5, 200);
    timer SetTenthsTimer(5);
    wait 5;
    timer Destroy();
    level flag::set("weapon_cores_delivered");
}