// Origins - Soft Patch (Margz's Origins Soft Patch V1.1, ported into the practice tool). What it does:
//   - Snow on rounds 3, 4 and 5
//   - Ice staff digs: Village on dig 1, NML by dig 2, Bunker by dig 3
//   - Two NML dig mounds that always come back
//   - Origins preset gum pack, Reign Drops as the first gum
//   - Recaptures only pick generators 2/3/4/5
//   - Zombie Blood off the Gen 5 souls box
//   - Death barriers on (the practice tool turns them off otherwise)
//   - Robot cycle, picked with action1 then fast restart (saved in pt_tomb_soft_cycle):
//       3 Cycle:   Thor -> Odin -> Freya (right foot), then normal
//       4/5 Cycle: Thor -> Freya -> (free, never Odin as a single) -> Odin -> Odin (left foot), then normal
//     reset_patch puts it back to Normal.
// The robot, dig and recapture changes live in the detours (giant_robot.gsc, fire_enter.gsc and
// below) and only run while this patch is loaded (level.tomb_soft_active).

TombSoftPatch()
{
    if(level.script != "zm_tomb")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Origins");
        return;
    }
    level.tomb_soft_active = true;
    level.player_out_of_playable_area_monitor = 1;
    foreach(player in GetPlayers()) player thread zm::player_out_of_playable_area_monitor();
    level.tomb_soft_cycle = GetDvarInt("pt_tomb_soft_cycle");

    level flag::wait_till("start_zombie_round_logic");
    level thread ms_ForceWeather();
    level thread ms_ForceNmlDigSpots();
    level thread ms_ZombieBloodAtGen5Box();

    level flag::wait_till("initial_blackscreen_passed");
    self SetPresetGums();
    self ms_ReignFirst();
    thread WriteToScreen("Origins Soft Patch Loaded - " + ms_CycleName(level.tomb_soft_cycle));
    self thread ShowControls(Array(
        Array("action1", "Robot Cycle: " + ms_CycleName(level.tomb_soft_cycle)),
        Array("reset_patch", "Normal Robots")));
    self thread ms_CycleSelect();
}

ms_CycleName(cycle)
{
    if(cycle == 3) return "3 Cycle";
    if(cycle == 4) return "4/5 Cycle";
    return "Normal";
}

// action1 steps Normal -> 3 Cycle -> 4/5 Cycle; reset_patch goes back to Normal. Both apply on fast restart.
ms_CycleSelect()
{
    self thread ms_CycleReset();
    for(;;)
    {
        WaitAction(1);
        cycle = GetDvarInt("pt_tomb_soft_cycle");
        if(cycle == 0) cycle = 3;
        else if(cycle == 3) cycle = 4;
        else cycle = 0;
        SetDvar("pt_tomb_soft_cycle", cycle);
        thread WriteToScreen("Next Robot Cycle: " + ms_CycleName(cycle) + " - Fast Restart To Use It");
    }
}

ms_CycleReset()
{
    for(;;)
    {
        WaitBind("reset_patch");
        SetDvar("pt_tomb_soft_cycle", 0);
        thread WriteToScreen("Next Robot Cycle: Normal - Fast Restart To Use It");
    }
}

// Reign Drops first, the other 4 gums of the pack shuffled behind it. After that the game reshuffles normally.
ms_ReignFirst()
{
    if(!IsDefined(self.bgb_pack) || !IsInArray(self.bgb_pack, "zm_bgb_reign_drops")) return;
    rest = [];
    foreach(gum in self.bgb_pack)
    {
        if(gum != "zm_bgb_reign_drops") rest[rest.size] = gum;
    }
    rest = array::randomize(rest);
    self.bgb_pack_randomized = Array("zm_bgb_reign_drops");
    foreach(gum in rest) self.bgb_pack_randomized[self.bgb_pack_randomized.size] = gum;
}

// weather_manager picks the weather at end_of_round before the round number goes up, so
// force_weather[N] is the weather for round N + 1: this gives snow on rounds 3, 4 and 5.
ms_ForceWeather()
{
    while(!IsDefined(level.force_weather)) wait 0.05;
    level.force_weather[2] = "snow";
    level.force_weather[3] = "snow";
    level.force_weather[4] = "snow";
}

// The two NML dig mounds closest to these spots come back as soon as they are dug.
ms_ForceNmlDigSpots()
{
    while(!IsDefined(level.a_dig_spots) || !level.a_dig_spots.size) wait 0.5;
    spots = [];
    foreach(target in Array((570, 783, 80.5), (-2789.38, 552.87, 208.03)))
    {
        closest = undefined;
        closest_dist = undefined;
        foreach(s_dig_spot in level.a_dig_spots)
        {
            dist = DistanceSquared(target, s_dig_spot.origin);
            if(!IsDefined(closest_dist) || dist < closest_dist)
            {
                closest_dist = dist;
                closest = s_dig_spot;
            }
        }
        if(IsDefined(closest)) spots[spots.size] = closest;
    }
    for(;;)
    {
        foreach(s_dig_spot in spots)
        {
            if(IsTrue(s_dig_spot.dug) && level.n_dig_spots_cur <= level.n_dig_spots_max)
            {
                s_dig_spot.dug = undefined;
                s_dig_spot thread [[ @zm_tomb_dig<scripts\zm\zm_tomb_dig.gsc>::dig_spot_spawn ]]();
            }
        }
        wait 1;
    }
}

// After 20-24 souls in the Gen 5 robot footprint box, the next natural powerup drop is Zombie Blood.
ms_ZombieBloodAtGen5Box()
{
    gen5_box = undefined;
    foreach(box in GetEntArray("foot_box", "script_noteworthy"))
    {
        if(IsDefined(box.script_int) && box.script_int == 3)
        {
            gen5_box = box;
            break;
        }
    }
    if(!IsDefined(gen5_box)) return;
    threshold = RandomIntRange(20, 25);
    while(!IsDefined(gen5_box.n_souls_absorbed) || gen5_box.n_souls_absorbed < threshold) wait 0.05;
    level.custom_zombie_powerup_drop = ::ms_GiveZombieBlood;
}

ms_GiveZombieBlood(drop_point)
{
    zm_powerups::specific_powerup_drop("zombie_blood", drop_point);
    level.custom_zombie_powerup_drop = undefined;
    return 1;
}

// Ice staff digs: with this patch loaded the guaranteed dig is per zone (Bunker by dig 3, NML by
// dig 2, Village on dig 1); otherwise this is the game's own dig_spot_get_staff_piece.
detour zm_tomb_main_quest<scripts\zm\zm_tomb_main_quest.gsc>::dig_spot_get_staff_piece(e_player)
{
    level notify("sam_clue_dig", e_player);
    str_zone = self.str_zone;
    foreach(s_staff in level.ice_staff_pieces)
    {
        if(!isdefined(s_staff.num_misses))
        {
            s_staff.num_misses = 0;
        }
        if(issubstr(str_zone, s_staff.zone_substr))
        {
            miss_chance = 100 / (s_staff.num_misses + 1);
            if(level.weather_snow <= 0)
            {
                miss_chance = 101;
            }
            if(IsTrue(level.tomb_soft_active))
            {
                if(randomint(100) > miss_chance || (level.weather_snow > 0 && s_staff.num_misses > ms_IceDigThreshold(s_staff.zone_substr)))
                {
                    return s_staff;
                }
            }
            else if(randomint(100) > miss_chance || (s_staff.num_misses > 3 && miss_chance < 100))
            {
                return s_staff;
            }
            s_staff.num_misses++;
            break;
        }
    }
    return undefined;
}

ms_IceDigThreshold(zone_substr)
{
    if(zone_substr == "bunker") return 1;
    if(zone_substr == "nml") return 0;
    if(zone_substr == "village") return -1;
    return 3;
}

// Robot cycling while this patch is loaded (called from the robot_cycling detour after the intro walk).
// Every robot event - a single robot or a trios round - counts as one step of the chosen cycle.
// Robot ids: 0 = Odin (NML), 1 = Thor (Trenches), 2 = Freya (Village).
TombSoftPatchRobotCycling()
{
    three_robot_round = 0;
    last_robot = -1;
    event = 0;
    while(true)
    {
        if(!(level.round_number % 4) && three_robot_round != level.round_number)
        {
            level flag::set("three_robot_round");
        }
        if(level flag::get("ee_all_staffs_placed") && !level flag::get("ee_mech_zombie_hole_opened"))
        {
            level flag::set("three_robot_round");
        }
        event++;
        level.robot_cycle_foot = undefined;
        forced = ms_ForcedRobot(event);
        if(level flag::get("three_robot_round"))
        {
            level.zombie_ai_limit = 22;
            random_number = RandomInt(3);
            if(forced >= 0) random_number = forced;
            // Odin gets the hatch on every trios round while the ascend from darkness window is open
            if(level flag::get("ee_all_staffs_placed") && !level flag::get("ee_mech_zombie_hole_opened"))
            {
                random_number = 0;
                level.robot_cycle_foot = undefined;
            }
            if(random_number == 2 || level flag::get("all_robot_hatch"))
            {
                if(random_number == 2) level thread RobotForceFoot();
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2);
            }
            else
            {
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2, 0);
            }
            wait(5);
            if(random_number == 0 || level flag::get("all_robot_hatch"))
            {
                if(random_number == 0) level thread RobotForceFoot();
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](0);
            }
            else
            {
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](0, 0);
            }
            wait(5);
            if(random_number == 1 || level flag::get("all_robot_hatch"))
            {
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](1);
            }
            else
            {
                level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](1, 0);
            }
            level waittill("giant_robot_walk_cycle_complete");
            level waittill("giant_robot_walk_cycle_complete");
            level waittill("giant_robot_walk_cycle_complete");
            wait(5);
            level.zombie_ai_limit = 24;
            three_robot_round = level.round_number;
            last_robot = -1;
            level flag::clear("three_robot_round");
        }
        else
        {
            nml = level flag::get("activate_zone_nml");
            if(!nml) random_number = RandomInt(2);
            else random_number = RandomInt(3);
            if(random_number == last_robot)
            {
                if(!nml) random_number = 1 - random_number;
                else random_number = (random_number + 1 + RandomInt(2)) % 3;
            }
            if(forced >= 0) random_number = forced;
            // 4/5 Cycle: the free 3rd robot is never Odin, since Odin comes twice right after it
            if(level.tomb_soft_cycle == 4 && event == 3 && random_number == 0)
            {
                if(!nml) random_number = 1;
                else random_number = RandomIntRange(1, 3);
            }
            if(IsDefined(level.robot_cycle_foot)) level thread RobotForceFoot();
            last_robot = random_number;
            level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](random_number);
            level waittill("giant_robot_walk_cycle_complete");
            wait(5);
        }
    }
}

// Forced robot for this event of the chosen cycle (-1 = not forced). Sets level.robot_cycle_foot when
// the foot is forced too (RobotForceFoot answers the walk's cointoss with it).
ms_ForcedRobot(event)
{
    if(level.tomb_soft_cycle == 3)
    {
        if(event == 1) return 1;
        if(event == 2) return 0;
        if(event == 3)
        {
            level.robot_cycle_foot = "right";
            return 2;
        }
    }
    else if(level.tomb_soft_cycle == 4)
    {
        if(event == 1) return 1;
        if(event == 2) return 2;
        if(event == 4 || event == 5)
        {
            level.robot_cycle_foot = "left";
            return 0;
        }
    }
    return -1;
}
