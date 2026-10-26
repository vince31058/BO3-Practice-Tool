// Flags Practice (Shadows of Evil) - Scrappy's setup, reworked to put you right at the flag step:
//   - Scrappy's door / beast door / power setup (the same doors and power boxes as a real route)
//   - all rituals and Pack-a-Punch done, all perks, 6000 points
//   - the upgraded sword handed out the way the game does it, so the Easter egg starts: the book
//     shows up, gets used for you, and the flag (totem) drops into place
//   - weapons: Bloodhound, HVK-30, Dagon's Glare (upgraded KRM-262)
//   - a fresh round 8 (the round is ended into 8 with its full zombie count)
//   - Dead of Nuclear Winter (nukes) in your gum slot and the other 4 gums of the pack still left in
//     the cycle
//   - special rounds as if the 1st parasite round was round 6: the meatball-only round on 9/10 like
//     the base game, then the 2nd parasite round after it
//   - you're put right next to the flag
// The old version swapped the sword for your original character's one after pickup, so the game's
// "everyone has the upgraded sword" check never passed and the book / flag never spawned.

FlagsPractice()
{
    WaitFadeIn();
    if(level.script != "zm_zod")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Shadows of Evil");
        return;
    }
    self.bgb_pack = Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_wall_power");
    level.players[0].bgb_pack = self.bgb_pack;
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Flags Practice Loaded - Setting Up...");
    level flag::clear("spawn_zombies");
    level.next_wasp_round = 256; // no parasite round during the setup
    wait 3;
    Timescale(10);
    self thread Godmode(1);

    // Scrappy's map setup
    self thread OpenBeastDoors();
    doors = GetEntArray("zombie_door", "targetname");
    order = Array(1, 4, 5, 6, 7, 8, 9, 10);
    foreach(item in order)
    {
        doors[item] thread zm_blockers::door_opened(doors[item].zombie_cost, 0);
    }
    doors = GetEntArray("zombie_debris", "targetname");
    order = Array(4);
    bgb = self.bgb;
    self.bgb = "zm_bgb_shopping_free";
    foreach(item in order)
    {
        doors[item] notify("trigger", self, 1);
    }
    wait 0.1;
    self.bgb = bgb;
    self thread ActivateAllPower(Array((2471, -3811, 306), (4567, -4666, 306), (1922, -4784, -332), (857, -3728, 501), (1191, -5509, 178), (3026, -4458, 180), (2637, -5649, -102), (4712, -4224, 452), (2861, -6897, 306)));
    self thread ZombieCounter();

    self GiveZodCharacter();
    level.givecustomcharacters = ::GiveZodCharacter;
    self GiveAllPerks();
    self.score = 6000;
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    self zm_weapons::weapon_give(GetWeapon("pistol_revolver38"));
    self zm_weapons::weapon_give(GetWeapon("ar_cqb"));
    self zm_weapons::weapon_give(GetWeapon("shotgun_pump_upgraded"), 1); // Dagon's Glare (upgraded KRM-262)

    // rituals + Pack-a-Punch
    self thread FinishRitual(4);
    level flag::wait_till("ritual_pap_complete");

    // the upgraded sword, given the game's way for this character, so the EE's sword check passes
    self [[ @zm_zod_sword<scripts\zm\zm_zod_sword_quest.gsc>::give_sword ]](2, 1);

    // the book shows up once everyone has the upgraded sword; use it so the flag drops
    level flag::wait_till("ee_begin");
    book = GetEnt("ee_book", "targetname");
    while(!IsDefined(book.unitrigger_stub)) wait 0.05;
    wait 0.5;
    self BuildAndActivateTrigger(book.unitrigger_stub);
    level flag::wait_till("ee_book");
    while(level clientfield::get("ee_totem_state") != 1) wait 0.05;

    // fresh round 8
    self fl_FreshRound8();
    self fl_SetSecondBugRound();
    level.var_bf361dc0 = RandomIntRange(10, 12);

    // Dead of Nuclear Winter (nukes) in the gum slot, the other 4 still to come in the cycle
    self thread GivePlayerGum("zm_bgb_dead_of_nuclear_winter");
    self.bgb_pack_randomized = array::randomize(Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_anywhere_but_here", "zm_bgb_wall_power"));

    // next to the flag
    self fl_TeleportToFlag();
    Timescale(1);
    self thread Godmode(0);
    level thread zm_blockers::open_all_zbarriers();
    level flag::set("spawn_zombies");
    thread WriteToScreen("Flags Practice Ready - Round 8");
}

// End the current round straight into round 8 (its own full zombie count) and wait for it to start.
// Doesn't use SkipToRound: EndRound's endon("end_of_round") ends the calling thread.
fl_FreshRound8()
{
    level flag::clear("spawn_zombies");
    while(!level.zombie_total && !zombie_utility::get_round_enemy_array().size) wait 0.05;
    zm::set_round_number(7);
    level.zombie_total = 0;
    level thread fl_KillUntilRoundEnd();
    level waittill("end_of_round");
    level waittill("start_of_round");
}

fl_KillUntilRoundEnd()
{
    level endon("end_of_round");
    for(;;)
    {
        level.zombie_total = 0;
        foreach(zombie in GetAITeamArray(level.zombie_team)) zombie Kill();
        wait 0.5;
    }
}

fl_TeleportToFlag()
{
    s_loc = struct::get("ee_totem_landed_position", "targetname");
    if(!IsDefined(s_loc)) return;
    spot = GetClosestPointOnNavMesh(s_loc.origin, 128);
    if(!IsDefined(spot)) return;
    self DeathBarrierGrace();
    self SetOrigin(spot);
    facing = VectorToAngles(s_loc.origin - spot);
    self SetPlayerAngles((0, facing[1], 0));
}

// Special rounds like a real game where the 1st parasite round was round 6:
//   - the meatball-only round stays where the game put it (round 9 or 10; moved to 9-10 if it would
//     land on round 8 or earlier)
//   - the parasite round count is 2, and the next parasite round is worked out the way the map does
//     it after a round 6 parasite round (5 rounds after the later of round 6 and the meatball round)
//   - the game turns on mixed parasite + meatball spawning by itself once the meatball round ends
fl_SetSecondBugRound()
{
    if(!IsDefined(level.n_next_raps_round) || level.n_next_raps_round <= level.round_number) level.n_next_raps_round = RandomIntRange(9, 11);
    level.wasp_round_count = 2;
    first = 6;
    if(level.n_next_raps_round > first) first = level.n_next_raps_round;
    level.var_1300aaeb = first + 5;
    level.next_wasp_round = level.var_1300aaeb;
}
