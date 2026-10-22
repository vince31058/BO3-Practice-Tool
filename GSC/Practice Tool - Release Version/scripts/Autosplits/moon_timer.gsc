// ---------------------------------------------------------------------------
// Moon autosplits (same splits as the Moon timer mod)
//
// Built on the game's own Easter egg flow (zm_moon_sq.gsc::sidequest_logic):
//   Power On -> Samantha Says (ss1) -> Terminals (osc) -> Vril Sphere
//   (vg_charged) -> Canister #1 / #2 (tanks charged) -> Samantha Says 2 -> egg (be2)
//   -> Earth Boom
// ---------------------------------------------------------------------------

// Some steps only send a one-time notify. Listen for those from match start so a
// split still completes if its step happened before that split was reached.
TrackMoonQuest()
{
    if(IsTrue(level.tracking_moon_quest)) return;
    level.tracking_moon_quest = true;
    level.moon_quest_done = [];
    level thread TrackMoonNotify("sq_osc_over");
    level thread TrackMoonNotify("sq_ss2_over");
    level thread TrackMoonEarthBoom();
}

// Earth Boom timing is tracked from the start, so the end split still lands on the explosion even if
// it only starts waiting after "rl" (e.g. the split before it waits for a round to end).
// do_launch starts once the egg is delivered (be2), notifies "rl" 10s later and blows up the Earth 60s after that.
TrackMoonEarthBoom()
{
    level flag::wait_till("be2");
    level waittill("rl");
    wait 60;
    level.moon_end_reached = true;
    level notify("pt_moon_end");
}

TrackMoonNotify(msg)
{
    level waittill(msg);
    level.moon_quest_done[msg] = true;
    level notify("pt_" + msg);
}

WaitMoonNotify(msg)
{
    TrackMoonQuest();
    if(IsTrue(level.moon_quest_done[msg])) return;
    level waittill("pt_" + msg);
}

// Power switch flipped (zm_moon.gsc waits on the same flag)
SplitMoonPowerOn()
{
    level flag::wait_till("power_on");
}

// Samantha Says (first Simon Says) complete
SplitMoonSimonSays()
{
    level flag::wait_till("ss1");
}

// Terminals (security override / hacker stage "osc") complete
SplitMoonSecurityOverride()
{
    WaitMoonNotify("sq_osc_over");
}

// Vril Sphere: vril generator charged at the computer
SplitMoonFocus()
{
    level flag::wait_till("vg_charged");
}

SplitMoonFirstTank()
{
    level flag::wait_till("first_tanks_charged");
}

SplitMoonSecondTank()
{
    level flag::wait_till("second_tanks_charged");
}

// Earth Boom: the Earth explodes (see TrackMoonEarthBoom). Safe to use as both a split and the
// Egg End: once the Earth has exploded every call returns right away.
WaitMoonEnd()
{
    TrackMoonQuest();
    if(IsTrue(level.moon_end_reached)) return;
    level waittill("pt_moon_end");
}
