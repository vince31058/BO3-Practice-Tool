CastleSoftPatch()
{
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    if(self SetPresetGums()) // default pack: the patch's own gum cycle
    {
        self.bgb_pack_randomized = array::randomize(Array("zm_bgb_anywhere_but_here", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_perkaholic", "zm_bgb_extra_credit"));
        ArrayInsert(self.bgb_pack_randomized, "zm_bgb_reign_drops", 0);
    }

    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("DE Soft Patch Loaded");

    self GiveCastleCharacter();
    level.givecustomcharacters = ::GiveCastleCharacter;
    level.next_dog_round = 5;
}