// ---------------------------------------------------------------------------
// Moon - Box Lock Practice (ported from the standalone "Moon God Mod")
//
// - Annihilator (kept fully charged), 50,000 points and every perk
// - Mystery Box only rolls QED and Gersh Device
// - Fire sale that never ends
// - Box lock trainer: 12s countdown, lock detector, force lock (action 1)
// - Spawn a Death Machine powerup in front of you (action 2)
// - Zombie spawns off without rounds flipping (toggle: action 3)
// - Power on at start; teleporter cage and NML bunker gate stay open
// ---------------------------------------------------------------------------

MoonBoxLockPractice()
{
    WaitFadeIn();
    if(level.script != "zm_moon")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Moon");
        return;
    }

    level thread MoonBoxSetupBox();
    level thread MoonBoxPerpetualFireSale();
    level thread MoonBoxSpawnControl();
    level thread MoonBoxTrainerInit();
    level thread MoonBoxPowerOn();
    level thread MoonBoxTeleporterGates();

    level flag::wait_till("initial_blackscreen_passed");
    wait 1.5;
    thread WriteToScreen("Box Lock Practice Loaded");

    if(self.score < 50000) self zm_score::add_to_player_score(50000 - self.score);

    self MoonBoxGiveLoadout();
    self thread MoonBoxButtonWatcher();
    self thread MoonBoxKeepAnnihilatorFull();
    self thread MoonBoxRespawnWatcher();
}

// Re-applies the loadout after a respawn (the standalone mod did this on every spawn)
MoonBoxRespawnWatcher()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("spawned_player");
        wait 1.5;
        self MoonBoxGiveLoadout();
    }
}

MoonBoxGiveLoadout()
{
    self MoonBoxGiveAnnihilator();
    self MoonBoxGiveAllPerks();
}

MoonBoxGiveAnnihilator()
{
    w_annihilator = GetWeapon("hero_annihilator");
    if(!self HasWeapon(w_annihilator)) self zm_weapons::weapon_give(w_annihilator, 0, 0, 1, 0);
    // Slot 0 is the hero weapon gadget slot; 100 = fully charged
    self GadgetPowerSet(0, 100);
}

MoonBoxGiveAllPerks()
{
    if(!IsDefined(level._custom_perks)) return;
    foreach(perk in GetArrayKeys(level._custom_perks))
    {
        if(!self HasPerk(perk) && !self zm_perks::has_perk_paused(perk))
        {
            self zm_perks::give_perk(perk, 0);
            wait 0.05;
        }
    }
}

// ---------------------------------------------------------------------------
// Box: only QED + Gersh
// ---------------------------------------------------------------------------
// The box shuffles its weapon list and passes it through
// level.customrandomweaponweights. Returning only QED + Gersh means the box
// can't give anything else.

MoonBoxSetupBox()
{
    level flag::wait_till("initial_blackscreen_passed");

    level.moon_box_weapons = [];
    foreach(name in Array("quantum_bomb", "black_hole_bomb"))
    {
        w = GetWeapon(name);
        if(IsDefined(level.zombie_weapons[w]))
        {
            level.zombie_weapons[w].is_in_box = 1;
            level.moon_box_weapons[level.moon_box_weapons.size] = w;
        }
    }

    if(!level.moon_box_weapons.size)
    {
        thread WriteToScreen("^1QED/Gersh not found, box unchanged");
        return;
    }
    level.customrandomweaponweights = ::MoonBoxWeaponList;
}

MoonBoxWeaponList(keys)
{
    return array::randomize(level.moon_box_weapons);
}

// ---------------------------------------------------------------------------
// Perpetual fire sale
// ---------------------------------------------------------------------------
// The fire sale counts zombie_powerup_fire_sale_time down and ends at 0.
// Start one and keep topping the timer up; if it ever ends anyway, start a new one.

MoonBoxPerpetualFireSale()
{
    level flag::wait_till("initial_blackscreen_passed");
    wait 3;
    for(;;)
    {
        if(!IsTrue(level.zombie_vars["zombie_powerup_fire_sale_on"]))
        {
            level thread [[ @zm_powerup_fire_sale<scripts\zm\_zm_powerup_fire_sale.gsc>::start_fire_sale ]](undefined);
            wait 0.5;
        }
        level.zombie_vars["zombie_powerup_fire_sale_time"] = 9999;
        wait 5;
    }
}

// ---------------------------------------------------------------------------
// Zombie spawns off (without the round flipping)
// ---------------------------------------------------------------------------
// Rounds end when zombie_total and the live zombie count are both 0, so just
// deleting zombies makes rounds flip forever. Instead:
//  - clear "spawn_zombies", which pauses the round spawner before it takes
//    anything off zombie_total
//  - keep zombie_total at 1 or more, so the round can never end
//  - delete anything that still spawns (No Man's Land spawns directly and
//    ignores the flag)

MoonBoxSpawnControl()
{
    level.moon_box_spawns_off = 1;
    level flag::wait_till("initial_blackscreen_passed");
    for(;;)
    {
        if(level.moon_box_spawns_off)
        {
            if(level flag::get("spawn_zombies")) level flag::clear("spawn_zombies");
            if(!IsTrue(level.intermission) && level.zombie_total < 1) level.zombie_total = 1;
            foreach(zombie in GetAITeamArray(level.zombie_team))
            {
                if(IsDefined(zombie)) zombie Delete();
            }
        }
        else if(!level flag::get("spawn_zombies"))
        {
            level flag::set("spawn_zombies");
        }
        wait 0.05;
    }
}

// ---------------------------------------------------------------------------
// Box lock trainer
// ---------------------------------------------------------------------------
// The box closes when treasure_chest_timeout() sends ONE "trigger" notify,
// 12s after the weapon stops cycling. If the box thread is in a short wait()
// from a blocked grab (helmet anim = 0.1s, Annihilator = 0.05s) at that
// moment, the notify is lost and the box never closes: that's the lock.

MoonBoxNewHud(y, fontscale)
{
    hud = NewHudElem();
    hud.alignx = "center";
    hud.aligny = "top";
    hud.horzalign = "center";
    hud.vertalign = "top";
    hud.y = y;
    hud.fontscale = fontscale;
    hud.hidewheninmenu = 1;
    hud.alpha = 0;
    return hud;
}

MoonBoxTrainerInit()
{
    level flag::wait_till("initial_blackscreen_passed");

    level.moon_box_timer = MoonBoxNewHud(36, 1.3);
    level.moon_box_timer.label = &"Box closes in: ";
    level.moon_box_status = MoonBoxNewHud(52, 1.3);

    foreach(chest in level.chests) chest thread MoonBoxWatcher();
}

MoonBoxShowStatus(text, duration)
{
    level notify("moon_box_status");
    level endon("moon_box_status");
    level.moon_box_status SetText(text);
    level.moon_box_status.alpha = 1;
    wait duration;
    level.moon_box_status.alpha = 0;
}

// Runs on each chest
MoonBoxWatcher()
{
    for(;;)
    {
        self.zbarrier waittill("randomization_done");
        waittillframeend;

        // Teddy bear: box is moving, nothing to time
        if(!IsTrue(self.grab_weapon_hint)) continue;

        self.moon_box_forcelocked = undefined;
        level.moon_box_timer SetTenthsTimer(12);
        level.moon_box_timer.alpha = 1;

        result = self util::waittill_any_timeout(11.5, "user_grabbed_weapon");
        if(result == "timeout")
        {
            level thread MoonBoxShowStatus("^1PRESS NOW!", 1);
            result = self util::waittill_any_timeout(1, "user_grabbed_weapon");
        }
        level.moon_box_timer.alpha = 0;

        if(IsDefined(self.moon_box_forcelocked)) level thread MoonBoxShowStatus("^3BOX FORCE LOCKED", 3);
        else if(result != "timeout") level thread MoonBoxShowStatus("Weapon grabbed - no lock", 3);
        else if(IsTrue(self._box_open) && IsTrue(self.grab_weapon_hint)) level thread MoonBoxShowStatus("^2BOX LOCKED!", 4);
        else level thread MoonBoxShowStatus("^1Missed - box closed at 12.0s", 3);
    }
}

// Locks the nearest open box by ending its 12s timeout thread, the same end
// result as the real glitch
MoonBoxForceLockNearest()
{
    best = undefined;
    best_dist = 200 * 200;
    foreach(chest in level.chests)
    {
        if(!IsTrue(chest.grab_weapon_hint)) continue;
        d = DistanceSquared(self.origin, chest.origin);
        if(d < best_dist)
        {
            best = chest;
            best_dist = d;
        }
    }
    if(!IsDefined(best))
    {
        thread WriteToScreen("No open box nearby to lock");
        return;
    }
    best.moon_box_forcelocked = 1;
    best notify("user_grabbed_weapon"); // kills treasure_chest_timeout
}

MoonBoxButtonWatcher()
{
    self thread ShowControls(Array(Array("action1", "Force Lock"), Array("action2", "Death Machine"), Array("action3", "Zombie Spawns On / Off")));
    self thread MoonBoxActionForceLock();
    self thread MoonBoxActionDeathMachine();
    self thread MoonBoxActionSpawns();
}

MoonBoxActionForceLock()
{
    self endon("disconnect");
    for(;;)
    {
        WaitAction(1);
        self MoonBoxForceLockNearest();
    }
}

MoonBoxActionDeathMachine()
{
    self endon("disconnect");
    for(;;)
    {
        WaitAction(2);
        self MoonBoxSpawnDeathMachine();
    }
}

MoonBoxActionSpawns()
{
    self endon("disconnect");
    for(;;)
    {
        WaitAction(3);
        level.moon_box_spawns_off = !level.moon_box_spawns_off;
        if(level.moon_box_spawns_off) thread WriteToScreen("Zombie Spawns Off");
        else thread WriteToScreen("Zombie Spawns On");
    }
}

// Drops a real Death Machine powerup about 80 units in front of the player.
// It never times out, so it stays until you grab it.
MoonBoxSpawnDeathMachine()
{
    forward = AnglesToForward((0, self GetPlayerAngles()[1], 0));
    drop_spot = self.origin + (forward * 80);
    level thread zm_powerups::specific_powerup_drop("minigun", drop_spot, undefined, undefined, undefined, undefined, 1);
}

// Tops the Annihilator back up to 100% every server frame. Each shot drains
// gadget power and the game puts it away at 0%; refilling every frame means it
// never gets there. Also gives it back if you ever lose it.
MoonBoxKeepAnnihilatorFull()
{
    self endon("disconnect");
    w_annihilator = GetWeapon("hero_annihilator");
    for(;;)
    {
        if(IsAlive(self) && self.sessionstate !== "spectator")
        {
            if(!self HasWeapon(w_annihilator)) self zm_weapons::weapon_give(w_annihilator, 0, 0, 1, 0);
            if(self GadgetPowerGet(0) < 100) self GadgetPowerSet(0, 100);
        }
        wait 0.05;
    }
}

// ---------------------------------------------------------------------------
// Power
// ---------------------------------------------------------------------------
// Sends the same "trigger" a player flipping the switch would, so the shared
// _zm_power handler and Moon's own electric_switch() both run normally.

MoonBoxPowerOn()
{
    level flag::wait_till("initial_blackscreen_passed");
    wait 1;
    if(level flag::exists("power_on") && level flag::get("power_on")) return;
    player = GetPlayers()[0];
    foreach(switch_trig in GetEntArray("use_elec_switch", "targetname")) switch_trig notify("trigger", player);
}

// ---------------------------------------------------------------------------
// Teleporter cage + No Man's Land bunker gate
// ---------------------------------------------------------------------------
// Cage (moon side): shut after you come back from NML, normally reopens ~120s
// after the next round starts. Bunker gate (NML): normally opens 20s (first
// visit) / 75s after arriving. Whenever either is shut, wait for its 3s close
// animation to finish (moving it mid-animation leaves it in the wrong spot)
// and reopen it. The game's own later "open" calls then do nothing.

MoonBoxTeleporterGates()
{
    level flag::wait_till("initial_blackscreen_passed");
    while(!IsDefined(level.teleporter_to_nml_gate_ent) || !IsDefined(level.teleporter_exit_nml_gate_ent)) wait 0.5;

    for(;;)
    {
        if(!level.teleporter_to_nml_gate_open)
        {
            wait level.teleporter_gate_move_time + 0.25;
            if(!level.teleporter_to_nml_gate_open) MoonBoxOpenCageGate();
        }
        if(!level.teleporter_exit_nml_gate_open && level flag::get("enter_nml"))
        {
            wait level.teleporter_gate_move_time + 0.25;
            if(!level.teleporter_exit_nml_gate_open && level flag::get("enter_nml")) level thread MoonBoxOpenBunkerGate();
        }
        wait 0.5;
    }
}

// Same moves as zm_moon_teleporter's gate functions; the teleporter's
// indicator lights aren't changed.
MoonBoxOpenCageGate()
{
    if(level.teleporter_to_nml_gate_open) return;
    level.teleporter_to_nml_gate_open = 1;
    time = level.teleporter_gate_move_time;
    accel = time / 6;
    ent = level.teleporter_to_nml_gate_ent;
    ent2 = level.teleporter_to_nml_gate2_ent;
    h = level.teleporter_to_nml_gate_height;
    ent PlaySound("amb_teleporter_gate_start");
    ent MoveTo((ent.origin[0], ent.origin[1], ent.origin[2] - h), time, accel, accel);
    ent2 MoveTo((ent2.origin[0], ent2.origin[1], ent2.origin[2] + h), time, accel, accel);
    ent ConnectPaths();
}

MoonBoxOpenBunkerGate()
{
    if(level.teleporter_exit_nml_gate_open) return;
    level.teleporter_exit_nml_gate_open = 1;
    time = level.teleporter_gate_move_time;
    accel = time / 6;
    ent = level.teleporter_exit_nml_gate_ent;
    ent2 = level.teleporter_exit_nml_gate2_ent;
    h = level.teleporter_exit_nml_gate_height;
    h2 = level.teleporter_exit_nml_gate2_height;
    ent PlaySound("amb_teleporter_gate_start");
    ent2 MoveTo((ent2.origin[0], ent2.origin[1], ent2.origin[2] - h2), time, accel, accel);
    ent MoveTo((ent.origin[0], ent.origin[1], ent.origin[2] - h), time, accel, accel);
    ent ConnectPaths();
}
