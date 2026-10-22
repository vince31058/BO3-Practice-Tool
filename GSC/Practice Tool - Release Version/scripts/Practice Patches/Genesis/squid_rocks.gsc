SquidShardsPractice()
{
    level flag::wait_till("initial_blackscreen_passed");
    if(level.script != "zm_genesis")
    {
        thread WriteToScreen("Wrong Map - This Patch Is For Revelations");
        return;
    }
    thread WriteToScreen("Squid Shards Practice Loaded");

    self thread DebugTesting();
    level flag::clear("spawn_zombies");
    self zm_weapons::weapon_give(level.var_9727e47e);
    self thread ShowSquidRocksControls();
    self thread ToggleBugFog();
    self thread WaypointSave();
    self thread WaypointLoad();

    IPrintLnBold("Initializing Shards");
    shards = struct::get_array("shard_piece", "targetname");
    array::thread_all(shards, ::ShardDamageCheck);
    foreach(shard in shards)
    {
        level notify(#"hash_2751215d", GetEnt(shard.target, "targetname").origin, level.var_9727e47e, self);
        wait 0.05;
    }
    level flag::wait_till("shards_done");
    wait 1;
    IPrintLnBold("All Shards Done");
}

ShardDamageCheck()
{
    target = GetEnt(self.target, "targetname");
    origin = target.origin;
    angles = target.angles;
    level flag::wait_till("shards_done");
    wait 1;
    target.origin = origin;
    target.angles = angles;
    target SetScale(1);
    target Show();
    for(;;)
    {
        [[ @zm_genesis_ee_quest<scripts\zm\zm_genesis_ee_quest.gsc>::function_4e44f01 ]](target.origin, 0);
        IPrintLnBold("Shard Shot");
    }
}

ToggleBugFog()
{
    for(;;)
    {
        WaitAction(1);
        level clientfield::set("chaos_fog_bank_switch", 1);
        IPrintLnBold("Fog Start");
        WaitAction(1);
        level clientfield::set("chaos_fog_bank_switch", 0);
        IPrintLnBold("Fog Stop");
    }
}

ShowSquidRocksControls()
{
    self ShowControls(Array(Array("action1", "Toggle Fog"), Array("save_pos", "Save Position"), Array("load_pos", "Load Position")));
}