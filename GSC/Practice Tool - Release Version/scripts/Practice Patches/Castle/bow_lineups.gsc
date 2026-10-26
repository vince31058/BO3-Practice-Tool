// Bow Lineups (Der Eisendrache) - based on Luisete's SR trainer aim practice
// For finding and repeating bow lineups:
//   - playing as Richtofen, map open, window barricades off, power on, all perks, no zombies, infinite ammo
//   - Wrath of the Ancients and the Storm Bow (upgraded lightning bow)
//   - all 8 time travel wisps glow at once and never go away; shooting one says "Hit" and which spot
//   - the lightning bonfires say "Hit" when an arrow lands on one (they never light)
//   - arrow cam: every arrow you fire takes over the camera and follows the arrow until it lands
//     (your controls are locked while it flies), then puts you back
//   - you start at the death ray trap; save / load position to repeat a lineup
// Nothing here touches the Easter egg or the bow quests.

BowLineupsPractice()
{
    WaitFadeIn();
    if(level.script != "zm_castle")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For Der Eisendrache");
        return;
    }
    level flag::wait_till("initial_blackscreen_passed");
    // always Richtofen (same as the DE soft patch, also after a respawn)
    self GiveCastleCharacter();
    level.givecustomcharacters = ::GiveCastleCharacter;
    level flag::clear("spawn_zombies");
    self thread OpenAllDoors();
    zm_blockers::open_all_zbarriers();
    self thread ActivateAllPower();
    self thread GiveAllPerks();
    self bl_GiveBows();
    self InfiniteAmmo(1);
    wait 0.5;
    self bl_TeleportToDeathRay();

    level.bl_arrow_cam = 1;
    if(GetDvarString("pt_de_arrow_cam") == "0") level.bl_arrow_cam = 0;

    thread WriteToScreen("Bow Lineups Loaded");
    self thread ShowControls(Array(
        Array("action1", "Arrow Cam: " + bl_OnOff(level.bl_arrow_cam)),
        Array("save_pos", "Save Position"),
        Array("load_pos", "Load Position")));
    self thread bl_ArrowCamToggle();
    self thread WaypointSave();
    self thread WaypointLoad();
    self thread bl_ArrowCam();

    // all 8 wisps at once
    targets = GetEntArray("activate_teleporter_object", "targetname");
    named = false;
    if(targets.size == 8) named = wo_MatchNames(targets);
    foreach(index, target in targets)
    {
        target SetCanDamage(1);
        target.health = 999999;
        s_fx = struct::get(target.target, "targetname");
        if(IsDefined(s_fx)) s_fx fx::play("battery_charge", s_fx.origin, undefined, "delete_fx", 0, undefined, 1);
        target thread bl_WatchWisp(index);
    }

    // lightning bonfires
    self thread bl_WatchBonfires();
}

bl_OnOff(value)
{
    if(value) return "On";
    return "Off";
}

bl_GiveBows()
{
    // free both weapon slots first so neither bow replaces the other (the starting pistol / loadout
    // weapons go away)
    foreach(weapon in self GetWeaponsListPrimaries())
    {
        self TakeWeapon(weapon);
        wait 0.1;
    }
    foreach(name in Array("elemental_bow", "elemental_bow_storm"))
    {
        bow = GetWeapon(name);
        if(!self HasWeapon(bow)) self zm_weapons::weapon_give(bow);
        wait 0.5;
    }
    if(!self HasWeapon(GetWeapon("elemental_bow_storm")))
    {
        // fall back to the storm quest the other DE patches use
        self FinishStorm();
        while(!self HasWeapon(GetWeapon("elemental_bow_storm"))) wait 0.05;
    }
    self SwitchToWeapon(GetWeapon("elemental_bow_storm"));
}

// in front of the death ray trap's activation switch
bl_TeleportToDeathRay()
{
    switch_ent = GetEnt("tesla_coil_activate", "targetname");
    if(!IsDefined(switch_ent)) return;
    spot = GetClosestPointOnNavMesh(switch_ent.origin, 128);
    if(!IsDefined(spot)) return;
    self SetOrigin(spot);
    facing = VectorToAngles(switch_ent.origin - spot);
    self SetPlayerAngles((0, facing[1], 0));
}

// a wisp never goes away: every hit just says so
bl_WatchWisp(index)
{
    for(;;)
    {
        self waittill("damage", n_damage, e_attacker, v_direction, v_point, str_means_of_death, str_tag_name, str_model_name, str_part_name, w_weapon);
        name = "Wisp " + (index + 1);
        if(IsDefined(self.wo_name)) name = self.wo_name;
        if(wo_IsUpgradedBow(w_weapon)) IPrintLnBold("Hit - " + name);
        else IPrintLnBold("Hit - " + name + " (needs an upgraded bow in the real step)");
        PlaySoundAtPosition("zmb_object_success", (0, 0, 0));
        wait 0.25;
    }
}

// the bonfires are triggers: an arrow landing inside one counts as a hit (nothing lights)
bl_WatchBonfires()
{
    beacons = GetEntArray("aq_es_beacon_trig", "script_noteworthy");
    for(;;)
    {
        self waittill("projectile_impact", weapon, point, radius, attacker, normal);
        foreach(index, beacon in beacons)
        {
            if(CheckBowHit(point, beacon))
            {
                IPrintLnBold("Hit - Bonfire " + (index + 1));
                break;
            }
        }
    }
}

// action1 turns the arrow cam on / off (kept through fast restarts in pt_de_arrow_cam)
bl_ArrowCamToggle()
{
    for(;;)
    {
        WaitAction(1);
        level.bl_arrow_cam = !level.bl_arrow_cam;
        SetDvar("pt_de_arrow_cam", level.bl_arrow_cam);
        thread WriteToScreen("Arrow Cam: " + bl_OnOff(level.bl_arrow_cam));
    }
}

// every bow arrow takes the camera: it rides with the arrow until it lands, controls locked.
// Bow arrows can come through as either a missile or a grenade, so both are watched.
bl_ArrowCam()
{
    self thread bl_ArrowCamWatch("missile_fire");
    self thread bl_ArrowCamWatch("grenade_fire");
}

bl_ArrowCamWatch(event)
{
    for(;;)
    {
        self waittill(event, projectile, weapon);
        if(!level.bl_arrow_cam || IsTrue(self.bl_following) || !IsDefined(projectile) || !IsDefined(weapon) || !IsSubStr(weapon.name, "elemental_bow")) continue;
        self bl_FollowArrow(projectile);
    }
}

// Only the camera follows the arrow; the player stays where they shot from (controls frozen), so an
// arrow flying out of the map can't set off the death barrier.
// The camera sits on a tag_origin behind and above the arrow (back far enough that the arrow and its
// effects aren't in your face). First choice: the tag is linked to the arrow (placed at the offset, then
// LinkTo with no tag keeps that offset), so the game moves it with the arrow every frame - as smooth as
// the arrow itself. If the link doesn't take (the tag doesn't move with the arrow), it falls back to
// chasing the arrow from script with smoothed MoveTo.
bl_FollowArrow(projectile)
{
    self.bl_following = true;
    back = 70;
    up = (0, 0, 12);
    angles = projectile.angles;
    if(!IsDefined(angles)) angles = self GetPlayerAngles();
    dir = AnglesToForward(angles);
    rider = util::spawn_model("tag_origin", projectile.origin - dir * back + up, angles);
    rider LinkTo(projectile);
    self FreezeControls(1);
    self CameraSetPosition(rider);
    // keep looking at the arrow, so the view tips up and down with its arc (the arrow itself keeps
    // its launch angle, so the linked tag alone never pitched)
    self CameraSetLookAt(projectile);
    self CameraActivate(1);

    start = GetTime();
    linked = true;
    last_origin = projectile.origin;
    wait 0.1;
    if(IsDefined(projectile) && DistanceSquared(rider.origin, projectile.origin) > 250 * 250)
    {
        // the link didn't move it: chase from script instead
        linked = false;
        rider Unlink();
    }
    velocity = (0, 0, 0);
    while(IsDefined(projectile) && GetTime() - start < 6000)
    {
        origin = projectile.origin;
        if(!linked)
        {
            step = origin - last_origin;
            if(LengthSquared(step) > 1)
            {
                dir = VectorNormalize(dir * 0.65 + VectorNormalize(step) * 0.35);
                velocity = velocity * 0.5 + step * 0.5;
                new_angles = VectorToAngles(dir);
                yaw = new_angles[1];
                while(yaw - angles[1] > 180) yaw -= 360;
                while(yaw - angles[1] < -180) yaw += 360;
                angles = (AngleClamp180(new_angles[0]), yaw, 0);
            }
            rider MoveTo(origin + velocity - dir * back + up, 0.05);
            rider RotateTo(angles, 0.05);
        }
        last_origin = origin;
        wait 0.05;
    }
    // hold on the landing spot for a moment, still looking at where it landed
    if(linked) rider Unlink();
    landing = Spawn("script_origin", last_origin);
    self CameraSetLookAt(landing);
    wait 0.75;

    self CameraSetLookAt();
    self CameraActivate(0);
    landing Delete();
    rider Delete();
    self FreezeControls(0);
    self.bl_following = false;
}

// true if a projectile impact point is inside a trigger (also used by Fire Bow Shots)

CheckBowHit(impact, damage)
{
    touching = Spawn("script_origin", impact);
    if(!touching IsTouching(damage))
    {
        touching Delete();
        return false;
    }
    touching Delete();
    return true;
}
