// detour so bow script error doesn't occur
detour zm_weap_elemental_bow<scripts\zm\_zm_weap_elemental_bow.gsc>::function_7bc6b9d(var_6ab83514, var_8f9bdf29, var_332bb697 = undefined)
{
	self endon("death");
	while(true)
	{
		self waittill("projectile_impact", weapon, v_position, radius, e_projectile, normal);
		var_48369d98 = [[ @zm_weap_elemental_bow<scripts\zm\_zm_weap_elemental_bow.gsc>::function_1796e73 ]](weapon.name);
		if(var_48369d98 == var_6ab83514 || var_48369d98 == var_8f9bdf29)
		{
			if(var_48369d98 != "elemental_bow" && var_48369d98 != "elemental_bow_wolf_howl4" && IsDefined(e_projectile.birthtime))
			{
				if((GetTime() - e_projectile.birthtime) <= 150)
				{
					RadiusDamage(v_position, 32, level.zombie_health, level.zombie_health, self, "MOD_UNKNOWN", weapon);
				}
			}
			self thread [[ @zm_weap_elemental_bow<scripts\zm\_zm_weap_elemental_bow.gsc>::function_d2e32ed2 ]](var_48369d98, v_position);
			if(IsDefined(var_332bb697))
			{
				if(IsDefined(e_projectile)) self thread [[var_332bb697]](weapon, v_position, radius, e_projectile, normal);
			}
			self thread [[ @zm_weap_elemental_bow<scripts\zm\_zm_weap_elemental_bow.gsc>::function_9c5946ba ]](weapon, v_position);
		}
	}
}


// Crash fix: a charged Storm Bow shot on a panzer that's still landing started the "lifted by the
// storm" scene on top of its landing scene, and the game crashed. The game marks the panzer as landed
// partway through the landing animation (b_flyin_done), while the landing scene is still playing, so
// checking b_flyin_done isn't enough: a panzer still in any scene is skipped here.
detour _zm_weap_elemental_bow_storm<scripts\zm\_zm_weap_elemental_bow_storm.gsc>::function_23c30f35(e_player, var_126c274b, var_337b3336)
{
	self endon("death");
	if((IsDefined(self.b_flyin_done) && !self.b_flyin_done) || IsDefined(self.current_scene))
	{
		self.var_789ebfb2 = 0;
		return;
	}
	if(!(IsDefined(self.var_38fc90ba) && self.var_38fc90ba) && var_337b3336.n_lifetime > 2.5)
	{
		self.var_98056717 = 1;
		self.var_38fc90ba = 1;
		self.var_ab0efcf6 = self.origin;
		self thread scene::play("cin_zm_dlc1_mechz_dth_deathray_01", self);
		self thread [[ @_zm_weap_elemental_bow_storm<scripts\zm\_zm_weap_elemental_bow_storm.gsc>::function_ef25be5 ]](var_337b3336);
		self thread [[ @_zm_weap_elemental_bow_storm<scripts\zm\_zm_weap_elemental_bow_storm.gsc>::function_bffbed67 ]](e_player, var_337b3336);
		util::waittill_any_ents_two(self, "mechz_zap_lift_end", var_337b3336, "elem_storm_whirlwind_done");
		wait(0.1);
		self scene::stop("cin_zm_dlc1_mechz_dth_deathray_01");
		self thread [[ @zm_ai_mechz<scripts\zm\_zm_ai_mechz.gsc>::function_bb84a54 ]](self);
		self.var_789ebfb2 = 0;
		self.var_98056717 = 0;
		self.var_d3c478a0 = 1;
		wait(16);
		self.var_d3c478a0 = 0;
		self.var_38fc90ba = 0;
	}
	else
	{
		self.var_789ebfb2 = 0;
	}
}


// Same crash, earlier: Der Eisendrache's bow target filter (every bow uses it to pick what to zap or
// grab) now also skips a panzer that's still in a scene (its landing), so the storm never picks it
// until it's fully down. Otherwise the same as the game's.
detour zm_castle<scripts\zm\zm_castle.gsc>::function_f9a3207d(ai_enemy)
{
	if(!IsDefined(ai_enemy)) return false;
	if(IsSubStr(ai_enemy.classname, "keeper")) return false;
	if(ai_enemy.archetype === "mechz")
	{
		if(!(IsDefined(ai_enemy.b_flyin_done) && ai_enemy.b_flyin_done)) return false;
		if(IsDefined(ai_enemy.current_scene)) return false;
	}
	if(IsDefined(ai_enemy.var_1ea49cd7) && ai_enemy.var_1ea49cd7) return false;
	if(IsDefined(ai_enemy.var_bce6e774) && ai_enemy.var_bce6e774) return false;
	if(IsDefined(ai_enemy.in_gravity_trap) && ai_enemy.in_gravity_trap) return false;
	if(IsDefined(ai_enemy.b_melee_kill) && ai_enemy.b_melee_kill) return false;
	return true;
}

// Crash fix (confirmed): in Wisp 2 and Keeper Practice a charged Storm Bow shot on a panzer crashes the game,
// even one that's fully landed. The only panzer-only part of a charged shot is the "lifted by the
// storm" scene, so this turns that lift off for every panzer: the game skips the lift when a panzer
// was lifted recently (var_38fc90ba), so every panzer is kept marked as recently lifted. The storm
// still damages it like normal. This doesn't rely on the detour above actually being used.
DE_NoPanzerLift()
{
    level endon("end_game");
    for(;;)
    {
        foreach(mechz in GetAIArchetypeArray("mechz")) if(IsAlive(mechz)) mechz.var_38fc90ba = 1;
        wait 0.05;
    }
}

// Coming back from time travel: put the Storm Bow in the player's hands.
HoldStormBowOnReturn()
{
    self endon("disconnect");
    bow = GetWeapon("elemental_bow_storm");
    wait 0.5;
    if(!self HasWeapon(bow)) return;
    self SwitchToWeaponImmediate(bow);
    wait 0.5;
    if(self GetCurrentWeapon() != bow) self SwitchToWeapon(bow);
}

// Known crash (not fixed yet): in Wisp 2 and Keeper Practice a charged Lightning Bow shot can crash
// the game. Warn the player front and center when they're back from time travel.
ChargedBowWarning()
{
    for(i = 0; i < 3; i++)
    {
        IPrintLnBold("^1Don't Use Charged Lightning Bow Shots - Known Crash");
        wait 3;
    }
}
