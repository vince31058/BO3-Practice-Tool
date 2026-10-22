// Moon Soft Patch - standalone mod version (by Vinnie)
//  - Gums: Immolation, Reign, Perkaholic, Dead of Nuclear Winter, Shopping Free; the first gum is
//    a coin flip between Reign Drops and Shopping Free, the rest of the cycle is random.
//  - Excavators: Pi is the only one that can start until it has started once (it can still start
//    early by chance, or on the game's own guaranteed round); after that all three are normal.
//  - Box: Gersh Device by the 10th hit; then Wave Gun and QEDs within the next 10 hits;
//    once the sphere is in the pyramid, the box always gives a Gersh Device (when you can take one).
//  - Timer + splits (top left): Power On, Samantha Says, Terminals, Vril Sphere, Canister #1,
//    Canister #2, Earth Boom. The timer starts when you spawn in and stops when the Earth explodes.

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_magicbox;
#using scripts\zm\_zm_pack_a_punch_util;
#using scripts\zm\_zm_weapons;

#insert scripts\shared\shared.gsh;

#namespace moon_soft_patch;

function main()
{
	if(level.script != "zm_moon")
	{
		return;
	}
	while(!isdefined(level.n_gameplay_start_time))
	{
		wait(0.05);
	}

	level.moon_box_hits = 0;
	level.moon_box_stage = 0;
	level.moon_box_got = [];
	level.customrandomweaponweights = &soft_patch_box;
	level thread track_quest_notifies();
	level thread run_timer();
	level thread pi_first();

	foreach(player in level.players)
	{
		player set_gum_cycle();
		player thread watch_box_weapons();
	}

	level flag::wait_till("initial_blackscreen_passed");
	iprintlnbold("Moon Soft Patch Loaded");
}

function set_gum_cycle()
{
	pack = array("zm_bgb_immolation_liquidation", "zm_bgb_reign_drops", "zm_bgb_perkaholic", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_shopping_free");
	self.bgb_pack = pack;
	mix_random();
	if(randomint(2))
	{
		first = "zm_bgb_reign_drops";
	}
	else
	{
		first = "zm_bgb_shopping_free";
	}
	rest = [];
	foreach(gum in pack)
	{
		if(gum != first)
		{
			rest[rest.size] = gum;
		}
	}
	rest = shuffle(rest);
	self.bgb_pack_randomized = array(first, rest[0], rest[1], rest[2], rest[3]);
}

// Proper Fisher-Yates shuffle (every order equally likely).
function shuffle(arr)
{
	for(i = arr.size - 1; i > 0; i--)
	{
		j = randomint(i + 1);
		temp = arr[i];
		arr[i] = arr[j];
		arr[j] = temp;
	}
	return arr;
}

// The cycle is picked at the same moment of every load, so skip ahead a number of random rolls
// based on the clock first; otherwise the order can come out the same every game.
function mix_random()
{
	n = getutc() % 200;
	for(i = 0; i < n; i++)
	{
		randomint(100);
	}
}

// Excavator Pi (the "teleporter" digger, Tunnel 6) is the only one that can start until it has
// started once. The game picks a random digger from level.diggers, so it only gets Pi until then.
function pi_first()
{
	level endon("end_game");
	if(level flag::get("start_teleporter_digger"))
	{
		return;
	}
	level.diggers = array("teleporter");
	level flag::wait_till("start_teleporter_digger");
	level.diggers = array("teleporter", "hangar", "biodome");
}

// Remembers which of the box weapons a player has had at some point (QEDs replace the Gersh
// Device in the grenade slot, so "has it right now" isn't enough).
function watch_box_weapons()
{
	self endon("disconnect");
	weapons = [];
	foreach(weapon in array(level.w_black_hole_bomb, level.w_quantum_bomb, wave_gun()))
	{
		if(isdefined(weapon))
		{
			weapons[weapons.size] = weapon;
		}
	}
	while(true)
	{
		foreach(weapon in weapons)
		{
			if(self hasweapon(weapon))
			{
				level.moon_box_got[weapon.name] = 1;
			}
		}
		wait(0.25);
	}
}

function wave_gun()
{
	if(isdefined(level.w_microwavegundw) && isdefined(level.zombie_weapons[level.w_microwavegundw]))
	{
		return level.w_microwavegundw;
	}
	return level.w_microwavegun;
}

function got(weapon)
{
	return isdefined(weapon) && IS_TRUE(level.moon_box_got[weapon.name]);
}

// Box hook: the game calls it on the player for every box hit with the shuffled weapon list.
// Putting a weapon first makes the box give it if the player can take it.
function soft_patch_box(keys)
{
	level.moon_box_hits++;
	force = undefined;
	gersh = level.w_black_hole_bomb;
	qed = level.w_quantum_bomb;
	wave = wave_gun();

	if(level flag::exists("complete_be_1") && level flag::get("complete_be_1"))
	{
		force = gersh; // sphere is in the pyramid: Gersh every hit
	}
	else if(level.moon_box_stage == 0)
	{
		if(got(gersh))
		{
			level.moon_box_stage = 1;
			level.moon_box_stage_start = level.moon_box_hits - 1;
		}
		else if(level.moon_box_hits >= 10)
		{
			force = gersh;
		}
	}
	if(!isdefined(force) && level.moon_box_stage == 1)
	{
		n = level.moon_box_hits - level.moon_box_stage_start; // hit number in this 10-hit window
		need = [];
		if(!got(wave))
		{
			need[need.size] = wave;
		}
		if(!got(qed))
		{
			need[need.size] = qed;
		}
		if(!need.size)
		{
			level.moon_box_stage = 2;
		}
		else if(n >= 10 || (n >= 9 && need.size == 2))
		{
			force = need[0];
		}
	}

	if(isdefined(force))
	{
		pap_triggers = zm_pap_util::get_triggers();
		if(zm_magicbox::treasure_chest_canplayerreceiveweapon(self, force, pap_triggers) && zm_weapons::limited_weapon_below_quota(force))
		{
			arrayinsert(keys, force, 0);
		}
	}
	return keys;
}

// ---------------------------------------------------------------------------
// Timer and splits
// ---------------------------------------------------------------------------

// Some Easter egg steps only send a one-time notify; catch those from the start so a split
// still completes if its step happens before the split before it.
function track_quest_notifies()
{
	level.moon_quest_done = [];
	level thread track_notify("sq_osc_over");
	level thread track_notify("sq_ss2_over");
}

function track_notify(msg)
{
	level waittill(msg);
	level.moon_quest_done[msg] = 1;
	level notify("msp_" + msg);
}

function wait_quest_notify(msg)
{
	if(IS_TRUE(level.moon_quest_done[msg]))
	{
		return;
	}
	level waittill("msp_" + msg);
}

function run_timer()
{
	start_time = gettime();
	// (no &"" label strings: the Mod Tools would want them in a localized .str file)
	timer_label = new_hud(5, 1.4);
	timer_label settext("^7Time:");
	timer = new_hud(5, 1.4);
	timer.x = 52;
	timer.color = (0, 1, 0);
	timer settimerup(0);

	names = array("Power On", "Samantha Says", "Terminals", "Vril Sphere", "Canister #1", "Canister #2", "Earth Boom");
	funcs = array(&split_power_on, &split_samantha_says, &split_terminals, &split_vril_sphere, &split_canister_1, &split_canister_2, &split_earth_boom);
	for(i = 0; i < names.size; i++)
	{
		hud = new_hud(25 + (15 * i), 1.2);
		hud settext("^7" + names[i] + ": ^3--");
		[[funcs[i]]]();
		hud settext("^7" + names[i] + ": ^5" + format_time(gettime() - start_time));
	}
	// Earth Boom reached: freeze the main timer on the final time
	final_time = format_time(gettime() - start_time);
	timer destroy();
	timer_label settext("^7Time: ^2" + final_time);
}

function new_hud(y, scale)
{
	hud = newhudelem();
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "user_left";
	hud.vertalign = "user_top";
	hud.x = 5;
	hud.y = y;
	hud.foreground = 1;
	hud.hidewheninmenu = 1;
	hud.fontscale = scale;
	hud.alpha = 1;
	return hud;
}

// milliseconds -> m:ss.cc (or h:mm:ss.cc)
function format_time(ms)
{
	total = int(ms / 10); // hundredths
	cs = total % 100;
	total = int(total / 100);
	sec = total % 60;
	total = int(total / 60);
	minutes = total % 60;
	hours = int(total / 60);
	text = "";
	if(hours > 0)
	{
		text = hours + ":";
		if(minutes < 10)
		{
			text = text + "0";
		}
	}
	text = text + minutes + ":";
	if(sec < 10)
	{
		text = text + "0";
	}
	text = text + sec + ".";
	if(cs < 10)
	{
		text = text + "0";
	}
	return text + cs;
}

function split_power_on()
{
	level flag::wait_till("power_on");
}

// First Simon Says
function split_samantha_says()
{
	level flag::wait_till("ss1");
}

// Security override (hacker stage "osc")
function split_terminals()
{
	wait_quest_notify("sq_osc_over");
}

// Vril generator charged at the computer
function split_vril_sphere()
{
	level flag::wait_till("vg_charged");
}

function split_canister_1()
{
	level flag::wait_till("first_tanks_charged");
}

function split_canister_2()
{
	level flag::wait_till("second_tanks_charged");
}

// The Earth explodes: the game's ending (zm_moon_sq::do_launch) starts when the egg is delivered
// (be2), notifies "rl" 10s later, then blows up the Earth 60s after that.
function split_earth_boom()
{
	wait_quest_notify("sq_ss2_over");
	level flag::wait_till("be2");
	level waittill("rl");
	wait(60);
}
