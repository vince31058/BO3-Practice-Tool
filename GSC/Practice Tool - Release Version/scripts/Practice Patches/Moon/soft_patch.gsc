// Moon Soft Patch
//  - Gums: Immolation, Reign, Perkaholic, Dead of Nuclear Winter, Shopping Free; the first gum is
//    a coin flip between Reign Drops and Shopping Free, the rest of the cycle is random.
//  - Excavators: Pi is the only one that can start until it has started once (it can still start
//    early by chance, or on the game's own guaranteed round); after that all three are normal.
//  - Box: Gersh Device by the 10th hit; then Wave Gun and QEDs within the next 10 hits;
//    once the sphere is in the pyramid, the box always gives a Gersh Device (when you can take one).

MoonSoftPatch()
{
    WaitFadeIn();
    if(level.script != "zm_moon")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Moon");
        return;
    }
    level.moon_soft_patch = true;

    if(self SetPresetGums()) // default pack: the patch's own gum cycle
    {
        MixRandom();
        if(RandomInt(2)) first = "zm_bgb_reign_drops";
        else first = "zm_bgb_shopping_free";
        rest = [];
        foreach(gum in self.bgb_pack)
        {
            if(gum != first) rest[rest.size] = gum;
        }
        rest = ShuffleArray(rest);
        self.bgb_pack_randomized = Array(first, rest[0], rest[1], rest[2], rest[3]);
    }

    level.moon_box_hits = 0;
    level.moon_box_stage = 0;
    level.moon_box_got = [];
    level.customrandomweaponweights = ::MoonSoftPatchBox;
    self thread MoonWatchBoxWeapons();
    level thread MoonPiFirst();

    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Moon Soft Patch Loaded");
}

// Excavator Pi (the game's "teleporter" digger, Tunnel 6) is the only one that can start until it
// has started once. The game picks a random digger from level.diggers, so it only gets Pi until then.
MoonPiFirst()
{
    level endon("end_game");
    if(level flag::get("start_teleporter_digger")) return;
    level.diggers = Array("teleporter");
    level flag::wait_till("start_teleporter_digger");
    level.diggers = Array("teleporter", "hangar", "biodome");
}

// Remembers which of the box weapons the player has had at some point (QEDs replace the Gersh
// Device in the grenade slot, so "has it right now" isn't enough).
MoonWatchBoxWeapons()
{
    self endon("disconnect");
    weapons = [];
    foreach(weapon in Array(level.w_black_hole_bomb, level.w_quantum_bomb, MoonWaveGun()))
    {
        if(IsDefined(weapon)) weapons[weapons.size] = weapon;
    }
    for(;;)
    {
        foreach(weapon in weapons)
        {
            if(self HasWeapon(weapon)) level.moon_box_got[weapon.name] = true;
        }
        wait 0.25;
    }
}

MoonWaveGun()
{
    if(IsDefined(level.w_microwavegundw) && IsDefined(level.zombie_weapons[level.w_microwavegundw])) return level.w_microwavegundw;
    return level.w_microwavegun;
}

MoonGot(weapon)
{
    return IsDefined(weapon) && IsTrue(level.moon_box_got[weapon.name]);
}

// Box hook (the game calls it on the player for every box hit with the shuffled weapon list).
// Putting a weapon first makes the box give it if the player can take it.
MoonSoftPatchBox(keys)
{
    level.moon_box_hits++;
    force = undefined;
    gersh = level.w_black_hole_bomb;
    qed = level.w_quantum_bomb;
    wave = MoonWaveGun();

    if(level flag::exists("complete_be_1") && level flag::get("complete_be_1"))
    {
        // sphere is in the pyramid: Gersh every hit
        force = gersh;
    }
    else if(level.moon_box_stage == 0)
    {
        if(MoonGot(gersh))
        {
            level.moon_box_stage = 1;
            level.moon_box_stage_start = level.moon_box_hits - 1;
        }
        else if(level.moon_box_hits >= 10) force = gersh;
    }
    if(!IsDefined(force) && level.moon_box_stage == 1)
    {
        n = level.moon_box_hits - level.moon_box_stage_start; // hit number in this 10-hit window
        need = [];
        if(!MoonGot(wave)) need[need.size] = wave;
        if(!MoonGot(qed)) need[need.size] = qed;
        if(!need.size) level.moon_box_stage = 2;
        else if(n >= 10 || (n >= 9 && need.size == 2)) force = need[0];
    }

    if(IsDefined(force))
    {
        pap_triggers = zm_pap_util::get_triggers();
        if(zm_magicbox::treasure_chest_canplayerreceiveweapon(self, force, pap_triggers) && zm_weapons::limited_weapon_below_quota(force))
        {
            ArrayInsert(keys, force, 0);
        }
    }
    return keys;
}
