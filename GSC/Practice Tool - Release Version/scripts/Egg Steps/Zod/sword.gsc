ActivateEgg()
{
    level flag::set("keeper_sword_locker");
}

// Statue Order - Canals, Footlight, Initial, Waterfront, Rift
TriggerEgg()
{
    level.egg_triggered = 1;
    level.sword_quest.statues[2].trigger notify("trigger", self);
}

FillEgg(id)
{
    if(!level flag::get("keeper_sword_locker")) ActivateEgg();
    if(!IsDefined(level.egg_triggered)) TriggerEgg();
    statue = level.sword_quest.statues[id];
    if(IsDefined(level.zod_smashables[struct::get(statue.target, "targetname").target].m_a_clip[0]))
    {
        level.zod_smashables[struct::get(statue.target, "targetname").target] .m_e_trigger UseBy(level.players[0]);
        wait 1;
    }

    if(self.sword_quest.all_kills_completed) return;

    self.sword_quest.kills[id] = 12;
    level.sword_quest.statues[id].trigger notify("trigger", self); // for autosplit purposes

    foreach(index, statue in level.sword_quest.statues) if(index != 2 && self.sword_quest.kills[statue.statue_id] < 12) return;

    level.sword_quest.statues[2].trigger notify("trigger", self);
    self.sword_quest.all_kills_completed = 1;
    self.sword_quest.upgrade_stage = 1;
    wait 2;
    level.sword_quest.statues[2].trigger notify("trigger", self);
    wait 2;
    level.sword_quest.statues[2].trigger notify("trigger", self);
    wait 1;
}

FillAllEggs()
{
    self thread FillEgg(0);
    self thread FillEgg(1);
    self thread FillEgg(3);
    self thread FillEgg(4);
}

PickupOvum()
{
    while(level clientfield::get("keeper_quest_state_" + self.characterindex) < 1) wait 0.05;
    level flag::wait_till("ritual_pap_complete");
    org = self.origin;
    self SetOrigin(struct::get_array("player_respawn_point", "targetname")[0].origin);
    wait 1;
    s_loc = struct::get("keeper_spirit_" + self.characterindex, "targetname");
    self BuildAndActivateTrigger(s_loc.unitrigger_stub);
    wait 1;
    self SetOrigin(org);
}

// 0 = junction, 1 = canals, 2 = footlight, 3 = waterfront
FinishAllMagicCircles()
{
    if(level clientfield::get("keeper_quest_state_" + self.characterindex) < 2) self thread PickupOvum();
    while(level clientfield::get("keeper_quest_state_" + self.characterindex) < 2) wait 0.05;
    s_loc = struct::get_array("sword_quest_magic_circle_place", "targetname")[1];
    self BuildAndActivateTrigger(s_loc.unitrigger_stub);
    for(i = 0; i < 4; i++)
	{
		self.sword_quest_2.var_db999762[i] = 1;
	}
    margwas = GetAIArchetypeArray("margwa", level.zombie_team);
    foreach(margwa in margwas)
    {
        if(IsAlive(margwa)) margwa Kill();
    }
}

FinishMagicCircle(num)
{
    if(level clientfield::get("keeper_quest_state_" + self.characterindex) < 2) self thread PickupOvum();
    while(level clientfield::get("keeper_quest_state_" + self.characterindex) < 2) wait 0.05;
    s_loc = struct::get_array("sword_quest_magic_circle_place", "targetname")[num];
    level flag::clear("magic_circle_in_progress");
    self flag::clear("magic_circle_wait_for_round_completed");
    wait 0.25;
    self BuildAndActivateTrigger(s_loc.unitrigger_stub);
    margwas = GetAIArchetypeArray("margwa", level.zombie_team);
    foreach(margwa in margwas)
    {
        if(IsAlive(margwa)) margwa Kill();
    }
}

PickupUpgradedSword()
{
    while(!self.sword_quest_2.all_kills_completed) wait 0.05;
    wait 2;
    s_loc = struct::get("keeper_spirit_" + self.characterindex, "targetname");
    self BuildAndActivateTrigger(s_loc.unitrigger_stub);
    self flag::wait_till_clear("waiting_for_upgraded_sword");
    wait 1;
    self BuildAndActivateTrigger(s_loc.unitrigger_stub);
}

// The SOE patches make you one fixed character (GiveZodCharacter) but you keep your original
// character's swords. This used to swap the sword after you picked it up, which left the game's own
// sword table pointing at the other character's sword: its checks (like the Easter egg waiting for
// everyone to hold the upgraded sword before the book shows up) never saw the sword you held. Now the
// table for your character is pointed at your original character's swords, so the game hands those
// out itself and every check agrees with what you're holding.
FixSwordPickups()
{
    self endon("disconnect");
    while(!IsDefined(self.og_characterindex) || !IsDefined(level.sword_quest) || !IsDefined(level.sword_quest.weapons)) wait 0.05;
    og = self.og_characterindex;
    ci = self.characterindex;
    if(og == ci) return;
    level.sword_quest.weapons[ci][1] = GetWeapon("glaive_apothicon_" + og);
    level.sword_quest.weapons[ci][2] = GetWeapon("glaive_keeper_" + og);
}