LightningBowShotsPractice()
{
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Lightning Bow Shots Loaded");
    self.score = 50000;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    level flag::clear("spawn_zombies");
    self thread GiveAllPerks();
    self zm_weapons::weapon_give(GetWeapon("elemental_bow"));
    self SetOrigin((-631.237, 1906.1, 608.125));
    self SetPlayerAngles((-8.62427, -64.0613, 0));
    self InfiniteAmmo(1);
    self thread ShowLightningBowControls();
    self thread WatchLightningBowShots();
    self thread ToggleBeaconFX();
    self thread ToggleDogFog();
    self thread CameraPos(3);
    self thread CameraToggle(4);
    self thread WaypointSave();
    self thread WaypointLoad();
}

WatchLightningBowShots()
{
    beacons = GetEntArray("aq_es_beacon_trig", "script_noteworthy");
    for(;;)
    {
        hit = 0;
        self waittill("projectile_impact", weapon, point, radius, attacker, normal);
        foreach(beacon in beacons)
        {
            if(CheckBowHit(point, beacon))
            {
                hit = 1;
                break;
            }
        }
        if(hit) IPrintLnBold("Beacon Hit");
    }
}

CheckBowHit(impact, damage)
{
	touching = Spawn("script_origin", impact);
    if(!touching IsTouching(damage))
    {
        touching Delete();
        return false;
    }
    touching Delete();
	return true;
}

ToggleBeaconFX()
{
    beacons = GetEntArray("aq_es_beacon_trig", "script_noteworthy");
    foreach(beacon in beacons)
    {
        beacon_fx = struct::get(beacon.target);
        beacon_fx.fx = util::spawn_model("tag_origin", beacon_fx.origin);
    }
    for(;;)
    {
        WaitAction(1);
        foreach(beacon in beacons)
        {
            beacon_fx = struct::get(beacon.target);
            beacon_fx.fx clientfield::set("beacon_fx", 1);
        }
        IPrintLnBold("Beacons Activated");
        wait 1;
        WaitAction(1);
        foreach(beacon in beacons)
        {
            beacon_fx = struct::get(beacon.target);
            beacon_fx.fx clientfield::set("beacon_fx", 0);
        }
        IPrintLnBold("Beacons Deactivated");
        wait 1;
    }
}

ToggleDogFog()
{
    for(;;)
    {
        WaitAction(2);
        level clientfield::set("castle_fog_bank_switch", 1);
        IPrintLnBold("Fog Start");
        wait 1;
        WaitAction(2);
        level clientfield::set("castle_fog_bank_switch", 0);
        IPrintLnBold("Fog Stop");
        wait 1;
    }
}

ShowLightningBowControls()
{
    self ShowControls(Array(Array("action1", "Toggle Beacon FX"), Array("action2", "Toggle Fog"), Array("action3", "Set Camera Position"), Array("action4", "Toggle Camera"), Array("save_pos", "Save Position"), Array("load_pos", "Load Position")));
}