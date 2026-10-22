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