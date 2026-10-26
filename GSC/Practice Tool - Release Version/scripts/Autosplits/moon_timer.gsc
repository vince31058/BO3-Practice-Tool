// ---------------------------------------------------------------------------
// Moon autosplits (same splits as the Moon timer mod)
//
// Built on the game's own Easter egg flow (zm_moon_sq.gsc::sidequest_logic):
//   Power On -> Samantha Says (ss1) -> Terminals (osc) -> Vril Sphere
//   (sphere in the pyramid, complete_be_1) -> Canister #1 / #2 (tanks charged) -> Samantha Says 2 -> egg (be2)
//   -> Egg End (the Earth explodes; added automatically as the run's end split)
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
// do_launch starts once Samantha Says 2 is over AND the egg is delivered (be2), in either order. It
// notifies "rl" 10s later and blows up the Earth 60s after that.
// "rl" is also sent three times during Samantha Says 2 to raise the rockets, so if the egg was done
// before Samantha Says 2, waiting for be2 + the next "rl" caught a rocket raise and the split came
// about a minute after the rockets started going up instead of on the explosion. Waiting for
// Samantha Says 2 to be over first means the next "rl" is always the launch.
TrackMoonEarthBoom()
{
    while(!IsTrue(level.moon_quest_done["sq_ss2_over"])) level waittill("pt_sq_ss2_over");
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

// Vril Sphere: the sphere (the "black egg" rolling through the tunnels) reaches the pyramid
// (zm_moon_sq_be.gsc sets complete_be_1 at the end of its path). The flag is only made once the
// step starts, so wait for it to exist first.
SplitMoonFocus()
{
    while(!level flag::exists("complete_be_1")) wait 0.05;
    level flag::wait_till("complete_be_1");
}

SplitMoonFirstTank()
{
    level flag::wait_till("first_tanks_charged");
}

SplitMoonSecondTank()
{
    level flag::wait_till("second_tanks_charged");
}

// Egg End: the Earth explodes (see TrackMoonEarthBoom). Once it has exploded every call returns
// right away.
WaitMoonEnd()
{
    TrackMoonQuest();
    if(IsTrue(level.moon_end_reached)) return;
    level waittill("pt_moon_end");
}
