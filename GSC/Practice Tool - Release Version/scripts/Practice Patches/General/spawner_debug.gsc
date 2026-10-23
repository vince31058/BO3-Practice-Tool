SpawnerDebug()
{
    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Spawner Debug Loaded");
    self.score = 50000;
    level flag::clear("spawn_zombies");
    level flag::init("spawner_debug_active");
    self thread Godmode(1);
    DisableDeathBarriers(); // its teleports can drop you outside the playable area
    self thread GiveAllPerks();
    self thread ActiveSpawnersHud();
    self thread ActiveSpawnerTP();
    self thread ActiveZonesHud();
    self thread ActiveZonesTP();
    self thread CurrentZoneHud();
    self thread ABHDebug();
    if(level.script == "zm_zod" || level.script == "zm_factory")
    {
        self thread SpawnManipHud();
        self thread SpawnManipTP();
        if(level.script == "zm_zod") self thread InfiniteBeastStart(0);
    }
    else if(level.script == "zm_castle")
    {
        self thread TramSpawnersMonitor();
    }
    self thread ShowSpawnDebugControls();
    self thread WaypointSave();
    self thread WaypointLoad();
}

ActiveSpawnersHud()
{
    active_spawners = hud::createfontstring("big", 1.25);
    active_spawners hud::setpoint("TOPLEFT", "TOPLEFT", 20, 15);
    active_spawners.label = &"Active Spawners: ";
    last = -1;
    for(;;)
    {
        count = level.zm_loc_types["zombie_location"].size;
        if(count != last)
        {
            last = count;
            active_spawners SetValue(count);
        }
        wait 0.05;
    }
}

ActiveSpawnerTP()
{
    for(;;)
    {
        WaitAction(1);
        if(level flag::get("spawner_debug_active"))
        {
            IPrintLnBold("Debug TP Already Active");
            level flag::wait_till_clear("spawner_debug_active");
            continue;
        }
        level flag::set("spawner_debug_active");
        thread WriteToScreen("Beginning Active Spawners TPs");
		org = self.origin;
		foreach(index, loc in level.zm_loc_types["zombie_location"])
		{
			IPrintLnBold(index + " - " + loc.origin);
			self SetOrigin(loc.origin);
			WaitAction(1);
		}
		IPrintLnBold("Original Location");
		self SetOrigin(org);
        level flag::clear("spawner_debug_active");
    }
}

ActiveZonesHud()
{
    zone_hud = hud::createfontstring("big", 1.25);
    zone_hud hud::setpoint("TOPLEFT", "TOPLEFT", 20, 35);
    zone_hud.label = &"Active Zones: ";
    last = -1;
    for(;;)
    {
        active_zones = 0;
        foreach(zone in level.zones)
        {
            if(zone.is_active) active_zones++;
        }
        if(active_zones != last)
        {
            last = active_zones;
            zone_hud SetValue(active_zones);
        }
        wait 0.05;
    }
}

ActiveZonesTP()
{
    for(;;)
    {
        WaitAction(2);
        if(level flag::get("spawner_debug_active"))
        {
            IPrintLnBold("Debug TP Already Active");
            level flag::wait_till_clear("spawner_debug_active");
            continue;
        }
        level flag::set("spawner_debug_active");
        org = self.origin;
        active_zones = [];
        active_zones_keys = [];
        foreach(index, zone in level.zones)
        {
            if(zone.is_active)
            {
                active_zones[active_zones.size] = zone;
                active_zones_keys[active_zones_keys.size] = index;
            }
        }
        foreach(index, zone in active_zones)
        {
            IPrintLnBold(index + " - " + active_zones_keys[index]);
            self SetOrigin(zone.volumes[0].origin);
            WaitAction(2);
        }
        IPrintLnBold("Original Location");
        self SetOrigin(org);
        level flag::clear("spawner_debug_active");
    }
}

CurrentZoneHud()
{
    zone_hud = hud::createfontstring("big", 1.25);
    zone_hud hud::setpoint("TOPLEFT", "TOPLEFT", 20, 55);
    last = undefined;
    for(;;)
    {
        zone = zm_zonemgr::get_zone_from_position(self.origin + VectorScale((0, 0, 1), 32), 0);
        if(zone !== last)
        {
            last = zone;
            zone_hud SetText("Zone: " + zone);
        }
        wait 0.05;
    }
}

SpawnManipHud()
{
    spawn_manip_hud = hud::createfontstring("big", 1.5);
    spawn_manip_hud hud::setpoint("TOPLEFT", "TOPLEFT", 20, 75);
    spawn_manip_hud.label = &"Respawn Locations: ";
    last = -1;
    for(;;)
    {
        spawn_locs = level.zm_loc_types["zombie_location"];
		if(!IsDefined(level.n_player_spawn_selection_index))
		{
			level.n_player_spawn_selection_index = 0;
		}
		players = GetPlayers();
		level.n_player_spawn_selection_index++;
		if(level.n_player_spawn_selection_index >= players.size)
		{
			level.n_player_spawn_selection_index = 0;
		}
		curr_player = players[level.n_player_spawn_selection_index];
		ArraySortClosest(spawn_locs, curr_player.origin);
		spawn_candidates = [];
		player_angles = AnglesToForward(curr_player.angles);
		for(i = 0; i < spawn_locs.size; i++)
		{
			distance = spawn_locs[i].origin - curr_player.origin;
			dot_product = VectorDot(player_angles, distance);
			if(dot_product >= 0)
			{
				spawn_candidates[spawn_candidates.size] = spawn_locs[i];
				if(spawn_candidates.size > 10)
				{
					break;
				}
			}
		}
		if(spawn_candidates.size != last)
		{
			last = spawn_candidates.size;
			spawn_manip_hud SetValue(last);
		}
		wait 0.05;
    }
}

SpawnManipTP()
{
    for(;;)
    {
        WaitAction(4);
        if(level flag::get("spawner_debug_active"))
        {
            IPrintLnBold("Debug TP Already Active");
            level flag::wait_till_clear("spawner_debug_active");
            continue;
        }
        level flag::set("spawner_debug_active");
        thread WriteToScreen("Beginning Spawn Manip TPs");
        org = self.origin;
        spawn_locs = level.zm_loc_types["zombie_location"];
		if(!IsDefined(level.n_player_spawn_selection_index))
		{
			level.n_player_spawn_selection_index = 0;
		}
		players = GetPlayers();
		level.n_player_spawn_selection_index++;
		if(level.n_player_spawn_selection_index >= players.size)
		{
			level.n_player_spawn_selection_index = 0;
		}
		curr_player = players[level.n_player_spawn_selection_index];
		ArraySortClosest(spawn_locs, curr_player.origin);
		spawn_candidates = [];
		player_angles = AnglesToForward(curr_player.angles);
		for(i = 0; i < spawn_locs.size; i++)
		{
			distance = spawn_locs[i].origin - curr_player.origin;
			dot_product = VectorDot(player_angles, distance);
			if(dot_product >= 0)
			{
				spawn_candidates[spawn_candidates.size] = spawn_locs[i];
				if(spawn_candidates.size > 10)
				{
					break;
				}
			}
		}
        foreach(index, loc in spawn_candidates)
		{
			IPrintLnBold(index + " - " + loc.origin);
			self SetOrigin(loc.origin);
			WaitAction(4);
		}
        IPrintLnBold("Original Location");
		self SetOrigin(org);
        level flag::clear("spawner_debug_active");
    }
}

ABHDebug()
{
    for(;;)
    {
        WaitAction(3);
        if(level flag::get("spawner_debug_active"))
        {
            IPrintLnBold("Debug TP Already Active");
            level flag::wait_till_clear("spawner_debug_active");
            continue;
        }
        level flag::set("spawner_debug_active");
        thread WriteToScreen("Beginning ABH TPs");
        org = self.origin;
        respawn_points = struct::get_array("player_respawn_point", "targetname");
        filtered_respawn_points = [];
        foreach(s_respawn_point in respawn_points)
        {
            if(zm_utility::is_point_inside_enabled_zone(s_respawn_point.origin))
            {
                if(!IsDefined(filtered_respawn_points))
                {
                    filtered_respawn_points = [];
                }
                else if(!isArray(filtered_respawn_points))
                {
                    filtered_respawn_points = Array(filtered_respawn_points);
                }
                filtered_respawn_points[filtered_respawn_points.size] = s_respawn_point;
            }
        }
        if(IsDefined(level.var_2d4e3645))
        {
            filtered_respawn_points = [[level.var_2d4e3645]](filtered_respawn_points);
        }
        s_player_respawn = undefined;
        if(filtered_respawn_points.size > 0)
        {
            foreach(index, point in filtered_respawn_points)
            {
                spots = struct::get_array(point.target, "targetname");
                foreach(spot in spots)
                {
                    n_script_int = self GetEntityNumber() + 1;
                    if(spot.script_int === n_script_int)
                    {
                        s_player_respawn = spot;
                        break;
                    }
                }
                if(IsDefined(s_player_respawn))
                {
                    IPrintLnBold(index + " - " + s_player_respawn.origin);
                    self SetOrigin(s_player_respawn.origin);
                    WaitAction(3);
                }
            }
        }
        IPrintLnBold("Original Location");
        self SetOrigin(org);
        level flag::clear("spawner_debug_active");
    }
}

ShowSpawnDebugControls()
{
    entries = Array(Array("action1", "Active Spawners TP"), Array("action2", "Active Zones TP"), Array("action3", "ABH Locations TP"));
    if(level.script == "zm_zod" || level.script == "zm_factory") entries[entries.size] = Array("action4", "Respawn Locations TP");
    else if(level.script == "zm_castle") entries[entries.size] = Array("action4", "Toggle Tram Spawners");
    entries[entries.size] = Array("save_pos", "Save Position");
    entries[entries.size] = Array("load_pos", "Load Position");
    self ShowControls(entries);
}

TramSpawnersMonitor()
{
    tram_spawners = struct::get_array("zone_start_spawners", "targetname");
    for(;;)
    {
        WaitAction(4);
        foreach(spawner in tram_spawners)
        {
            if(spawner.script_int === 1)
            {
                spawner.is_enabled = 1;
            }
        }
        thread WriteToScreen("Tram Spawners Enabled");
        WaitAction(4);
        foreach(spawner in tram_spawners)
        {
            if(spawner.script_int === 1)
            {
                spawner.is_enabled = 0;
            }
        }
        thread WriteToScreen("Tram Spawners Disabled");
        wait 0.05;
    }
}