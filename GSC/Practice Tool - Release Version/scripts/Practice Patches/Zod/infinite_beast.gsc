InfiniteBeastStart(hud = 1)
{
    level flag::wait_till("initial_blackscreen_passed");
    if(level.script != "zm_zod")
    {
        thread WriteToScreen("Wrong Map - This Patch Is For Shadows of Evil");
        return;
    }
    level endon("infinite_beast_end");
    thread WriteToScreen("Infinite Beast Loaded");
    self.score = 50000;
    level clientfield::set("bm_superbeast", 1);
    level flag::clear("spawn_zombies");
    thread InfiniteKiosks();
    self thread InfiniteLives();
    if(hud)
    {
        // the practice patch also sets up the whole map (Spawner Debug reuses this with hud = 0 and
        // does its own setup): every door and beast door, every power box, all perks, and Pack-a-Punch
        // (the 4 rituals + the PaP ritual, so the PaP is up)
        self thread OpenAllDoors();
        self thread ActivateAllPower();
        self thread GiveAllPerks();
        self thread FinishRitual(4);
        self thread WaypointSetup(1);
    }
}

InfiniteKiosks()
{
    level endon("infinite_beast_end");
    for(;;)
    {
        level waittill("kiosk_used", kiosk);
        wait 0.25;
        kiosk.is_cooling_down = 0;
    }
}

InfiniteLives()
{
    level endon("infinite_beast_end");
    for(;;)
    {
        self.og_beastlives = self.beastlives;
        level waittill("kiosk_used", kiosk);
        self.beastlives = 99;
    }
}

InfiniteBeastEnd()
{
    level notify("infinite_beast_end");
    self.beastlives = self.og_beastlives;
}