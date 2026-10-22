ZodSoftPatch()
{
    WaitFadeIn();
    if(level.script != "zm_zod")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Shadows of Evil");
        return;
    }
    if(self SetPresetGums()) // default pack: the patch's own gum cycle
    {
        // Gum cycle: Reign Drops first, then the other four in a random order with ABH never second.
        MixRandom();
        rest = ShuffleArray(Array("zm_bgb_anywhere_but_here", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_perkaholic", "zm_bgb_wall_power"));
        while(rest[0] == "zm_bgb_anywhere_but_here") rest = ShuffleArray(rest);
        self.bgb_pack_randomized = Array("zm_bgb_reign_drops", rest[0], rest[1], rest[2], rest[3]);
    }
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("SOE Soft Patch Loaded");

    self GiveZodCharacter();
    level.givecustomcharacters = ::GiveZodCharacter;
    self thread FixSwordPickups();

    level.next_wasp_round = 6;
}