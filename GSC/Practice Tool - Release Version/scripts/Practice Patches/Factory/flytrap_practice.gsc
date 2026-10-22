FlytrapPractice()
{
    WaitFadeIn();
    if(level.script != "zm_factory")
    {
        level flag::wait_till("initial_blackscreen_passed");
        thread WriteToScreen("Wrong Map - This Patch Is For The Giant");
        return;
    }

    level flag::wait_till("initial_blackscreen_passed");
    thread WriteToScreen("Flytrap Practice Loaded");

    self thread OpenAllDoors();
    self.score = 50000;
    self thread InfiniteAmmo(1);
    level flag::clear("spawn_zombies");
    thread HideAndSeek("ee_exp_monkey");
    thread HideAndSeek("ee_bowie_bear");
    thread HideAndSeek("ee_perk_bear");

    self thread ShowFlytrapControls();
    self thread WaypointSave();
    self thread WaypointLoad();
    self thread CameraPos(2);
    self thread CameraToggle(3);

    for(;;)
    {
        WaitAction(1);
        self SetPlayerAngles(VectortoAngles(GetEnt("trig_ee_perk_bear", "targetname").origin - self GetTagOrigin("j_head")));
    }
}

HideAndSeek(targetname)
{
    obj_array = GetEntArray(targetname, "targetname");
    trig = GetEnt("trig_" + targetname, "targetname");
    foreach(obj in obj_array)
	{
		obj Show();
	}
    trig TriggerEnable(1);
    for(;;)
    {
        trig waittill("trigger");
        thread WriteToScreen("Triggered: " + targetname);
    }
}

ShowFlytrapControls()
{
    self ShowControls(Array(Array("action1", "Target Bear"), Array("action2", "Set Camera Position"), Array("action3", "Toggle Camera"), Array("save_pos", "Save Position"), Array("load_pos", "Load Position")));
}