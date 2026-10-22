// Origins robot cycling (replaces zm_tomb_giant_robot::robot_cycling).
// Robot ids: 0 = Odin, 1 = Thor, 2 = Freya.
//
// Fix: the single-robot reroll used to start from the previous round's number instead of
// rolling first, so right after trios the next single robot was always the trios robot that
// had the hatch. Now it rolls first and only rerolls a repeat of the last single robot.
//
// Fire Enter Practice and the Origins Soft Patch run their own robot order after the intro walk
// (FireEnterRobotCycling / TombSoftPatchRobotCycling).

detour zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::robot_cycling()
{
	three_robot_round = 0;
	last_robot = -1;
	level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_intro_walk ]](1);
	level waittill("giant_robot_intro_complete");
	if(IsTrue(level.fire_enter_active))
	{
		level FireEnterRobotCycling();
		return;
	}
	if(IsTrue(level.tomb_soft_active))
	{
		level TombSoftPatchRobotCycling();
		return;
	}
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
		if(level flag::get("three_robot_round"))
		{
			level.zombie_ai_limit = 22;
			random_number = RandomInt(3);
			if(random_number == 2 || level flag::get("all_robot_hatch"))
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2);
			}
			else
			{
				level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](2, 0);
			}
			wait(5);
			if(random_number == 0 || level flag::get("all_robot_hatch"))
			{
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
			if(!level flag::get("activate_zone_nml"))
			{
				random_number = RandomInt(2);
			}
			else
			{
				// roll first, then reroll only while it repeats the last single robot
				random_number = RandomInt(3);
				while(random_number == last_robot)
				{
					random_number = RandomInt(3);
				}
			}
			last_robot = random_number;
			level thread [[ @zm_tomb_giant_robot<scripts\zm\zm_tomb_giant_robot.gsc>::giant_robot_start_walk ]](random_number);
			level waittill("giant_robot_walk_cycle_complete");
			wait(5);
		}
	}
}

// giant_robot_start_walk picks the hatch foot with math::cointoss() 10 seconds after it
// starts (true = left). When the current cycle step wants a foot, answer that one toss.
RobotForceFoot()
{
	foot = level.robot_cycle_foot;
	if(!IsDefined(foot)) return;
	wait 9.9;
	level.robot_cycle_coin = (foot == "left");
	wait 0.6;
	level.robot_cycle_coin = undefined;
}

detour math<scripts\shared\math_shared.gsc>::cointoss()
{
	if(IsDefined(level.robot_cycle_coin) && self == level)
	{
		result = level.robot_cycle_coin;
		level.robot_cycle_coin = undefined;
		return result;
	}
	return RandomInt(100) >= 50;
}
