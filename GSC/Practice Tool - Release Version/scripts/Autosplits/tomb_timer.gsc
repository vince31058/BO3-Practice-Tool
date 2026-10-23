WaitStaffCraft(num)
{
    stalves = Array("water", "air", "fire", "lightning");
    level waittill("elemental_staff_" + stalves[num] + "_crafted", player);
}

WaitUpgrade()
{
    level flag::wait_till("ee_all_staffs_upgraded");
    for(;;)
    {
        foreach(player in GetPlayers()) if(player.teleporting) return;
        wait 0.05;
    }
}

WaitBoxes()
{
	array::thread_all(GetEntArray("foot_box", "script_noteworthy"), ::WaitBoxDone);
    level waittill("all_boxes_completed");
}

WaitBoxDone()
{
    level endon("all_boxes_completed");
    if(!IsDefined(self)) return;
    self waittill("movedone");
    if(level.n_soul_boxes_completed == 4) level notify("all_boxes_completed");
}

WaitFists()
{
    level flag::wait_till("ee_all_players_upgraded_punch");
}

WaitTombEnd()
{
    self waittill("_screen_fade_starting_ee_screen");
}

// Portals. Teleporter numbers: 1 = Fire, 2 = Wind, 3 = Lightning, 4 = Ice.
// Each portal split waits for the next time that portal is used after the split before it.

// Enter: a teleporter pad in the overworld takes a player into the Crazy Place
WaitPortalEnter(n)
{
    for(;;)
    {
        level waittill("player_teleported", player, script_int);
        if(script_int === n) return;
    }
}

// Leave: a portal in the Crazy Place takes a player back out. The game sends no message for
// these, so this watches for a player starting a teleport right at one of the Crazy Place portals.
WaitPortalLeave(n)
{
    TrackTombPortalLeaves();
    for(;;)
    {
        level waittill("pt_portal_leave", portal);
        if(portal == n) return;
    }
}

TrackTombPortalLeaves()
{
    if(IsTrue(level.tracking_portal_leaves)) return;
    level.tracking_portal_leaves = true;
    level thread TrackTombPortalLeavesLoop();
}

TrackTombPortalLeavesLoop()
{
    level endon("end_game");
    level flag::wait_till("start_zombie_round_logic");
    for(;;)
    {
        foreach(player in GetPlayers())
        {
            teleporting = IsTrue(player.teleporting);
            if(teleporting && !IsTrue(player.pt_was_teleporting) && IsDefined(level.a_teleport_exits))
            {
                for(n = 1; n <= 4; n++)
                {
                    portal = level.a_teleport_exits[n];
                    if(IsDefined(portal) && DistanceSquared(player.origin, portal.origin) < 40000) // within 200 units
                    {
                        level notify("pt_portal_leave", n);
                        break;
                    }
                }
            }
            player.pt_was_teleporting = teleporting;
        }
        wait 0.05;
    }
}
