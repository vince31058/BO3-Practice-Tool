FireBowShotsPractice()
{
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Fire Bow Shots Loaded");
    self.score = 50000;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    level flag::clear("spawn_zombies");
    self thread GiveAllPerks();
    self zm_weapons::weapon_give(GetWeapon("elemental_bow"));
    self InfiniteAmmo(1);
    self thread WatchFireBowShots();
    self thread WaypointSetup(1);
}

WatchFireBowShots()
{
    obelisk = GetEnt("aq_rp_obelisk_magma_trig", "targetname");
    circles = GetEntArray("aq_rp_runic_circle_volume", "script_noteworthy");
    array::thread_all(circles, ::WaitCircleHit);
    for(;;)
    {
        obelisk waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);
        if(CheckBowHit(point, obelisk)) IPrintLnBold("Obelisk Hit");
    }
}

WaitCircleHit()
{
    damage = GetEnt(self.target + "_trig", "targetname");
    for(;;)
    {
        damage waittill("damage", amount, attacker, direction, point, mod, tagname, modelname, partname, weapon);
        if(CheckBowHit(point, damage)) IPrintLnBold("Circle Hit");
    }
}