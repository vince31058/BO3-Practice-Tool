// Wisp Order Practice (Der Eisendrache)
// Practice the time travel wisp step without touching the Easter egg: the round never changes, the map
// is open (window barricades off too), power is on, all perks, and the Storm Bow (upgraded lightning bow). You start in front of the
// base bow pedestal facing the stairs. Like the real step, nothing says where a wisp is (find it by the
// glow); each hit shows "Hit". A wrong spot or a time out says where it was; any fail puts you back at
// the pedestal after 5 seconds and the next attempt starts 5 seconds later.
// It runs its own copy of the game's wisp step (zm_castle_ee::function_2634b833), with the same rules:
//   - the first wisp can be any of the 8 spots (or the one you pick with action1)
//   - every next wisp is a random pick between the 2 closest spots not shot yet (solo; co-op keeps
//     players + 1 spots like the game does)
//   - only an upgraded bow counts; shooting another wisp spot, missing 111 seconds or using another
//     weapon fails it (it starts over from the first wisp)
//   - 4 wisps finish the step. The teleporter is never opened.
// Extras: a step timer (first wisp showing -> 4th hit) with a PB (pt_de_wisp_pb, kept until the game is
// closed), the route recap after every attempt, action2 = zombies on/off (round 7 with the last 2
// zombies left, applies on fast restart, pt_de_wisp_zombies) and action3 = go again (back to the
// pedestal, new attempt) at any time.
// The spot names come from the wisp table (each row = the closest spots in order), matched to the
// map's targets by distance when the patch loads.

WispOrderPractice()
{
    zombies = GetDvarInt("pt_de_wisp_zombies");
    // zombies on: start the change to round 7 first so the round flips and zombies spawn sooner
    if(level.script == "zm_castle" && zombies) level thread wo_Round7TwoZombies();
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    level flag::wait_till("initial_blackscreen_passed");
    if(!zombies) level flag::clear("spawn_zombies");
    self thread OpenAllDoors();
    // every window's barricade off
    zm_blockers::open_all_zbarriers();
    self thread ActivateAllPower();
    self thread GiveAllPerks();
    self wo_GiveStormBow();
    wait 0.5;
    self wo_TeleportToBowPedestal();

    targets = GetEntArray("activate_teleporter_object", "targetname");
    if(targets.size != 8)
    {
        thread WriteToScreen("Wisp Order Practice: couldn't find the wisp spots");
        return;
    }
    named = wo_MatchNames(targets);
    first = GetDvarInt("pt_de_wisp_first");
    if(!named || first < 0 || first > 8) first = 0;

    thread WriteToScreen("Wisp Order Practice Loaded - First Wisp: " + wo_FirstName(first) + " - Zombies: " + wo_OnOff(zombies));
    controls = [];
    if(named) controls[controls.size] = Array("action1", "First Wisp: " + wo_FirstName(first));
    controls[controls.size] = Array("action2", "Zombies: " + wo_OnOff(zombies));
    controls[controls.size] = Array("action3", "Go Again");
    self thread ShowControls(controls);
    if(named) self thread wo_FirstSelect();
    else IPrintLn("Wisp Order Practice: couldn't match the wisp names, first wisp is random");
    self thread wo_ZombiesSelect();
    level thread wo_GoAgainWatch();

    self thread wo_RunStep(targets, first, named);
}

wo_OnOff(value)
{
    if(value) return "On";
    return "Off";
}

wo_GiveStormBow()
{
    bow = GetWeapon("elemental_bow_storm");
    if(self HasWeapon(bow)) return;
    self zm_weapons::weapon_give(bow);
    wait 0.5;
    if(!self HasWeapon(bow))
    {
        // fall back to the storm quest the other DE patches use
        self FinishStorm();
        while(!self HasWeapon(bow)) wait 0.05;
    }
    self SwitchToWeapon(bow);
}

// Puts the player in front of the Wrath of the Ancients (base bow) pedestal with their back to it,
// facing the stairs: the start of the wisp route. Picks the side of the pedestal that has walkable ground.
wo_TeleportToBowPedestal()
{
    pedestal = struct::get("base_bow_pickup_struct", "targetname");
    if(!IsDefined(pedestal)) return;
    angles = (0, 0, 0);
    if(IsDefined(pedestal.angles)) angles = pedestal.angles;
    forward = AnglesToForward((0, angles[1], 0));
    right = AnglesToRight((0, angles[1], 0));
    dirs = Array(forward, forward * -1, right, right * -1);
    spot = undefined;
    foreach(dir in dirs)
    {
        spot = GetClosestPointOnNavMesh(pedestal.origin + dir * 64, 48);
        if(IsDefined(spot)) break;
    }
    if(!IsDefined(spot)) spot = GetClosestPointOnNavMesh(pedestal.origin, 200);
    if(!IsDefined(spot)) return;
    self SetOrigin(spot);
    // turned 180 from the pedestal so the player faces the stairs
    facing = VectorToAngles(pedestal.origin - spot);
    self SetPlayerAngles((0, AngleClamp180(facing[1] + 180), 0));
}

wo_Names()
{
    return Array("Clock", "Radio", "Power", "Globe", "Clocktower", "Boxes", "Car", "Spawn");
}

wo_FirstName(first)
{
    if(first <= 0 || first > 8) return "Random";
    names = wo_Names();
    return names[first - 1];
}

// action1 steps Random -> Clock -> Radio -> ... -> Spawn -> Random, applied on fast restart
// (saved in pt_de_wisp_first).
wo_FirstSelect()
{
    for(;;)
    {
        WaitAction(1);
        first = GetDvarInt("pt_de_wisp_first") + 1;
        if(first > 8 || first < 0) first = 0;
        SetDvar("pt_de_wisp_first", first);
        thread WriteToScreen("Next First Wisp: " + wo_FirstName(first) + " - Fast Restart To Use It");
    }
}

// action2 toggles zombies for the next fast restart (saved in pt_de_wisp_zombies)
wo_ZombiesSelect()
{
    for(;;)
    {
        WaitAction(2);
        zombies = 1;
        if(GetDvarInt("pt_de_wisp_zombies")) zombies = 0;
        SetDvar("pt_de_wisp_zombies", zombies);
        thread WriteToScreen("Next Zombies: " + wo_OnOff(zombies) + " - Fast Restart To Use It");
    }
}

// action3 (ADS+Reload / F7; the bow never reloads so it can't go off by accident): drop the current attempt (or the finished one) and start again from the pedestal
wo_GoAgainWatch()
{
    for(;;)
    {
        WaitAction(3);
        if(IsTrue(level.wo_round_ended))
        {
            thread WriteToScreen("Round Ended - Fast Restart To Get Round 7 And The 2 Zombies Back");
            continue;
        }
        if(IsDefined(level.wo_round7_ready) && !level.wo_round7_ready) continue;
        level.wo_go_again = true;
        thread WriteToScreen("Going Again");
    }
}

// Zombies on: round 7 with the last 2 zombies of the round left, like near the end of the round in a
// run. Round 1 is ended right away with the round number set so the next round is 7, and round 7's
// zombie count is set to 2 before anything spawns. They're normal round 7 zombies. The wisp step
// waits for this (level.wo_round7_ready). If round 7 ends anyway the attempt stops and the player is
// told to fast restart (that puts round 7 and the 2 zombies back).
// (Doesn't use SkipToRound: EndRound's endon("end_of_round") ends the calling thread, so the
// zombies-left count after it never got set.)
wo_Round7TwoZombies()
{
    level.wo_round7_ready = false;
    level flag::wait_till("start_zombie_round_logic");
    level.next_dog_round = 256; // no dog round in the way
    level flag::clear("spawn_zombies");
    // round 1 has to be running (its zombie count set) before it can be ended
    while(!level.zombie_total && !zombie_utility::get_round_enemy_array().size) wait 0.05;
    zm::set_round_number(6);
    level.zombie_total = 0;
    level thread wo_KillUntilRoundEnd();
    level waittill("end_of_round");
    level waittill("zombie_total_set");
    level.zombie_total = 2;
    level flag::set("spawn_zombies");
    wait 1;
    level.wo_round7_ready = true;
    level waittill("end_of_round");
    level.wo_round_ended = true;
}

wo_KillUntilRoundEnd()
{
    level endon("end_of_round");
    for(;;)
    {
        level.zombie_total = 0;
        foreach(zombie in GetAITeamArray(level.zombie_team)) zombie Kill();
        wait 0.5;
    }
}

// wait, but stop early (false) if go again was pressed
wo_Sleep(time)
{
    end = GetTime() + Int(time * 1000);
    while(GetTime() < end)
    {
        if(IsTrue(level.wo_go_again) || IsTrue(level.wo_round_ended)) return false;
        wait 0.05;
    }
    return true;
}

wo_RunStep(targets, first, named)
{
    foreach(target in targets)
    {
        target SetCanDamage(1);
        target.health = 999999;
    }
    level.wo_go_again = false;
    // zombies on: wait for round 7 and its 2 zombies before the first wisp
    if(IsDefined(level.wo_round7_ready))
    {
        thread WriteToScreen("Getting Round 7 Ready...");
        while(!level.wo_round7_ready) wait 0.05;
        self wo_TeleportToBowPedestal();
        thread WriteToScreen("Round 7 - Last 2 Zombies - First Wisp Coming Up");
        level.wo_go_again = false;
    }
    for(;;)
    {
        result = self wo_Attempt(targets, first, named);
        wo_TimerStop();
        if(result == "round_ended")
        {
            PlaySoundAtPosition("zmb_object_fail", (0, 0, 0));
            thread WriteToScreen("Round Ended - Fast Restart To Get Round 7 And The 2 Zombies Back");
            thread WriteToScreen("Route: " + wo_RouteText());
            return;
        }
        if(result == "done")
        {
            PlaySoundAtPosition("zmb_object_final_success", (0, 0, 0));
            time = level.wo_end_time - level.wo_start_time;
            pb = GetDvarInt("pt_de_wisp_pb");
            if(!pb || time < pb)
            {
                SetDvar("pt_de_wisp_pb", time);
                thread WriteToScreen("Wisp Step Complete: " + CalcTime(time) + " - New PB!");
            }
            else thread WriteToScreen("Wisp Step Complete: " + CalcTime(time) + " (PB " + CalcTime(pb) + ")");
            thread WriteToScreen("Route: " + wo_RouteText());
            thread WriteToScreen("Go Again Or Fast Restart To Run It Again");
            while(!IsTrue(level.wo_go_again) && !IsTrue(level.wo_round_ended)) wait 0.05;
            if(IsTrue(level.wo_round_ended))
            {
                thread WriteToScreen("Round Ended - Fast Restart To Get Round 7 And The 2 Zombies Back");
                return;
            }
        }
        else if(result == "fail")
        {
            thread WriteToScreen("Route: " + wo_RouteText());
            // give the player 5 seconds to read what went wrong (go again skips it)
            wo_Sleep(5);
        }
        level.wo_go_again = false;
        self wo_TeleportToBowPedestal();
        thread WriteToScreen("Back To The Start - First Wisp Coming Up");
        wo_Sleep(5);
        level.wo_go_again = false;
    }
}

wo_RouteText()
{
    text = "";
    foreach(index, target in level.wo_route)
    {
        if(index > 0) text += " > ";
        if(IsDefined(target.wo_name)) text += target.wo_name;
        else text += "Wisp " + (index + 1);
    }
    if(text == "") text = "-";
    return text;
}

// One go at the step: "done" once 4 wisps are shot, "fail" if one fails, "restart" for go again
wo_Attempt(targets, first, named)
{
    foreach(target in targets) target.wo_shot = 0;
    level.wo_route = [];
    current = undefined;
    for(count = 0; count < 4; count++)
    {
        current = wo_PickNext(targets, current, first);
        level.wo_route[level.wo_route.size] = current;
        if(count == 0) wo_TimerStart();
        result = wo_WaitShot(targets, current, count, named);
        if(result != "hit") return result;
        current.wo_shot = 1;
        // the game waits 9 seconds before the next wisp shows
        if(count < 3 && !wo_Sleep(9))
        {
            if(IsTrue(level.wo_round_ended)) return "round_ended";
            return "restart";
        }
    }
    level.wo_end_time = GetTime();
    return "done";
}

// live step timer, top right
wo_TimerStart()
{
    level.wo_start_time = GetTime();
    wo_TimerStop();
    timer = NewHudElem();
    timer.alignx = "right";
    timer.aligny = "top";
    timer.horzalign = "user_right";
    timer.vertalign = "user_top";
    timer.x = -15;
    timer.y = 35;
    timer.fontscale = 1.5;
    timer.hidewheninmenu = 1;
    timer.label = &"^3Wisp Step: ^2";
    timer SetTenthsTimerUp(0.05);
    level.wo_timer = timer;
}

wo_TimerStop()
{
    if(IsDefined(level.wo_timer)) level.wo_timer Destroy();
    level.wo_timer = undefined;
}

wo_WaitShot(targets, current, count, named)
{
    s_fx = struct::get(current.target, "targetname");
    if(IsDefined(s_fx)) s_fx fx::play("battery_charge", s_fx.origin, undefined, "delete_fx", 0, undefined, 1);
    PlaySoundAtPosition("zmb_object_success", (0, 0, 0));

    level.wo_result = undefined;
    foreach(target in targets) target thread wo_WatchTarget(target == current);
    level thread wo_Timeout();
    while(!IsDefined(level.wo_result))
    {
        if(IsTrue(level.wo_round_ended)) level.wo_result = "round_ended";
        else if(IsTrue(level.wo_go_again)) level.wo_result = "restart";
        wait 0.05;
    }
    level notify("wo_wisp_done");
    if(IsDefined(s_fx)) s_fx notify("delete_fx");

    if(level.wo_result == "restart" || level.wo_result == "round_ended") return level.wo_result;
    if(level.wo_result == "hit")
    {
        IPrintLnBold("Hit (" + (count + 1) + "/4)");
        return "hit";
    }
    PlaySoundAtPosition("zmb_object_fail", (0, 0, 0));
    // after a wrong spot or a time out, say where the wisp actually was
    where = "";
    if(named && IsDefined(current.wo_name) && (level.wo_result == "Wrong Spot" || level.wo_result == "Timed Out")) where = " - It Was At " + current.wo_name;
    thread WriteToScreen(level.wo_result + where + " - Starting Over");
    return "fail";
}

// Same pick as zm_castle_ee::function_ee0ff0d1
wo_PickNext(targets, current, first)
{
    if(!IsDefined(current))
    {
        if(first > 0 && IsDefined(level.wo_by_name) && IsDefined(level.wo_by_name[first - 1])) return level.wo_by_name[first - 1];
        return array::random(targets);
    }
    left = [];
    foreach(target in targets)
    {
        if(!IsTrue(target.wo_shot) && target != current) left[left.size] = target;
    }
    players = level.activeplayers.size;
    if(players < 1) players = 1;
    if(left.size > players)
    {
        left = ArraySort(left, current.origin);
        options = [];
        for(i = 0; i < players + 1; i++) options[options.size] = left[i];
        return array::random(options);
    }
    return array::random(left);
}

wo_WatchTarget(is_current)
{
    level endon("wo_wisp_done");
    self waittill("damage", n_damage, e_attacker, v_direction, v_point, str_means_of_death, str_tag_name, str_model_name, str_part_name, w_weapon);
    if(IsDefined(level.wo_result)) return;
    if(!is_current)
    {
        level.wo_result = "Wrong Spot";
        return;
    }
    if(wo_IsUpgradedBow(w_weapon)) level.wo_result = "hit";
    else level.wo_result = "Needs An Upgraded Bow";
}

wo_Timeout()
{
    level endon("wo_wisp_done");
    wait 111;
    if(!IsDefined(level.wo_result)) level.wo_result = "Timed Out";
}

wo_IsUpgradedBow(weapon)
{
    if(!IsDefined(weapon)) return false;
    name = weapon.name;
    return IsSubStr(name, "elemental_bow_demongate") || IsSubStr(name, "elemental_bow_rune_prison") || IsSubStr(name, "elemental_bow_storm") || IsSubStr(name, "elemental_bow_wolf_howl");
}

// ---- naming the 8 spots ----
// Each row is a spot's closest spots, nearest first (from the wisp table). The game's 50/50 is always
// the first two not shot yet, so every spot's first two must be its 2 closest targets. That pins down
// which target is which; the ordering of the rest breaks any tie.
wo_MatchNames(targets)
{
    // indexes into wo_Names(): Clock 0, Radio 1, Power 2, Globe 3, Clocktower 4, Boxes 5, Car 6, Spawn 7
    level.wo_rows = Array(
        Array(1, 2, 3, 4),   // Clock: Radio, Power, Globe, Clocktower
        Array(0, 2, 3, 4),   // Radio: Clock, Power, Globe, Clocktower
        Array(1, 3, 0, 6),   // Power: Radio, Globe, Clock, Car
        Array(1, 2, 0, 5),   // Globe: Radio, Power, Clock, Boxes
        Array(1, 2, 0, 7),   // Clocktower: Radio, Power, Clock, Spawn
        Array(6, 2, 3, 7),   // Boxes: Car, Power, Globe, Spawn
        Array(5, 7, 2, 3),   // Car: Boxes, Spawn, Power, Globe
        Array(6, 5, 4, 2));  // Spawn: Car, Boxes, Clocktower, Power

    foreach(index, target in targets) target.wo_index = index;
    level.wo_near = [];
    foreach(index, target in targets)
    {
        others = [];
        foreach(other in targets)
        {
            if(other != target) others[others.size] = other;
        }
        others = ArraySort(others, target.origin);
        near = [];
        foreach(other in others) near[near.size] = other.wo_index;
        level.wo_near[index] = near;
    }

    level.wo_assign = [];
    level.wo_used = [];
    for(i = 0; i < 8; i++) level.wo_used[i] = 0;
    level.wo_best = undefined;
    level.wo_best_score = -1;
    wo_Assign(0);
    if(!IsDefined(level.wo_best)) return false;

    names = wo_Names();
    level.wo_by_name = [];
    for(n = 0; n < 8; n++)
    {
        target = targets[level.wo_best[n]];
        target.wo_name = names[n];
        level.wo_by_name[n] = target;
    }
    return true;
}

wo_Assign(n)
{
    if(n == 8)
    {
        score = 0;
        for(m = 0; m < 8; m++)
        {
            near = level.wo_near[level.wo_assign[m]];
            for(k = 0; k < 4; k++)
            {
                if(near[k] == level.wo_assign[level.wo_rows[m][k]]) score++;
            }
        }
        if(score > level.wo_best_score)
        {
            level.wo_best_score = score;
            level.wo_best = [];
            for(m = 0; m < 8; m++) level.wo_best[m] = level.wo_assign[m];
        }
        return;
    }
    for(e = 0; e < 8; e++)
    {
        if(level.wo_used[e]) continue;
        level.wo_assign[n] = e;
        level.wo_used[e] = 1;
        if(wo_Consistent(n)) wo_Assign(n + 1);
        level.wo_used[e] = 0;
    }
    level.wo_assign[n] = undefined;
}

// Names 0..n are placed: each placed name's 50/50 pair must be its target's 2 closest targets
wo_Consistent(n)
{
    for(m = 0; m <= n; m++)
    {
        near = level.wo_near[level.wo_assign[m]];
        for(k = 0; k < 2; k++)
        {
            r = level.wo_rows[m][k];
            if(r > n) continue;
            e = level.wo_assign[r];
            if(e != near[0] && e != near[1]) return false;
        }
    }
    return true;
}
