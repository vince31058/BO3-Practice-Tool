LockdownPractice()
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
    thread WriteToScreen("Lockdown Practice Loaded");
    self.score = 50000;
    self thread OpenAllDoors();
    self thread ActivateAllPower();
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    self thread GiveAllPerks();
    self DeathBarrierGrace();
    self ld_TeleportToGumMachine();
    self zm_weapons::weapon_give(level.w_raygun_mark3_upgraded, 1);
    self zm_weapons::weapon_give(GetWeapon("lmg_cqb"));
    self zm_weapons::weapon_give(GetWeapon("sniper_fastsemi"));
    self GiveRiotshield(0);
    self bgb::give("zm_bgb_anywhere_but_here");
    level flag::set("dragonride_crafted");
    // charge the generator (normally a Valkyrie drone killed next to it) so it's running and the valve
    // (pneumatic tube) step can be started right away
    level flag::set("generator_charged");
	level flag::set("dragon_pavlov_first_time");
    // start with Anywhere But Here; the machine cycles all five gums in a random order
    self.bgb_pack_randomized = array::randomize(Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_shopping_free"));
    level thread PracticeRoundTimer();
    level thread ld_ValveHud();
    thread SkipToRound(7);
}

// In front of the Hatchery gum machine (the one closest to Pack-a-Punch), facing it. Falls back to the
// old lockdown spot if it can't be found.
ld_TeleportToGumMachine()
{
    old_spot = (-3270.17, 21277.4, 160.125);
    pap = undefined;
    foreach(zbarrier in GetEntArray("zm_pack_a_punch", "targetname"))
    {
        if(!IsDefined(pap) || DistanceSquared(zbarrier.origin, old_spot) < DistanceSquared(pap.origin, old_spot)) pap = zbarrier;
    }
    target = old_spot;
    if(IsDefined(pap)) target = pap.origin;
    machine = undefined;
    if(IsDefined(level.bgb_machines))
    {
        foreach(m in level.bgb_machines)
        {
            if(!IsDefined(machine) || DistanceSquared(m.origin, target) < DistanceSquared(machine.origin, target)) machine = m;
        }
    }
    if(!IsDefined(machine))
    {
        self SetOrigin(old_spot);
        self SetPlayerAngles((4.19678, 61.4575, 0));
        return;
    }
    // the machine's use side is its right side
    front = AnglesToRight(machine.angles);
    spot = machine.origin + front * 60;
    ground = GetClosestPointOnNavMesh(spot, 64, 32);
    if(IsDefined(ground)) spot = ground;
    self SetOrigin(spot);
    look = VectorToAngles(machine.origin - spot);
    self SetPlayerAngles((0, look[1], 0));
}
// Valve step helper (this patch only): top right, under the round timer, lists every valve with the
// number its lever is on (1-3, updates as you turn them), and the title says which valve has the
// password cylinder.
// It doesn't say which valve is the green (start) one - that's for the player to find.
ld_ValveHud()
{
    while(!IsDefined(level.var_57f8b6c5) || level.var_57f8b6c5.size < 6) wait 0.05;
    foreach(tube in level.var_57f8b6c5) while(!IsDefined(tube.var_1f3c0ca7)) wait 0.05;
    cylinder = level.var_57f8b6c5[5];
    order = Array("store", "command", "armory", "library", "barracks", "factory");
    tubes = [];
    foreach(label in order)
    {
        foreach(tube in level.var_57f8b6c5) if(tube.script_label == label) tubes[tubes.size] = tube;
    }
    title = ld_HudLine(55);
    title SetText("^3Valves (password: ^2" + ld_ValveName(cylinder.script_label) + "^3)");
    level thread ld_ValveMessages();
    lines = [];
    shown = [];
    foreach(i, tube in tubes)
    {
        lines[i] = ld_HudLine(72 + i * 15);
        shown[i] = -1;
    }
    while(!level flag::get("tube_puzzle_complete"))
    {
        foreach(i, tube in tubes)
        {
            if(shown[i] == tube.var_1f3c0ca7) continue;
            shown[i] = tube.var_1f3c0ca7;
            text = ld_ValveName(tube.script_label) + ": ^2" + (tube.var_1f3c0ca7 + 1);
            lines[i] SetText("^7" + text);
        }
        wait 0.1;
    }
    title SetText("^3Valves: ^2Done");
    foreach(line in lines) line Destroy();
    wait 5;
    title Destroy();
}

ld_HudLine(y)
{
    hud = NewHudElem();
    hud.alignx = "right";
    hud.aligny = "top";
    hud.horzalign = "user_right";
    hud.vertalign = "user_top";
    hud.x = -15;
    hud.y = y;
    hud.fontscale = 1.2;
    hud.hidewheninmenu = 1;
    return hud;
}

ld_ValveName(label)
{
    switch(label)
    {
        case "armory": return "Armory";
        case "barracks": return "Infirmary";
        case "command": return "Dragon Command";
        case "factory": return "Tank";
        case "library": return "Supply";
        case "store": return "Department";
    }
    return label;
}

ld_ValveMessages()
{
    wait 2;
    IPrintLnBold("Input The Valves Into Whatever Valve Solver You Use");
    wait 5;
    IPrintLnBold("This Is Just For The Segment - It Won't Continue The Easter Egg");
}
