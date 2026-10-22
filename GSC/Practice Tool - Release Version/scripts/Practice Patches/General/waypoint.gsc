// Save / load position (universal binds save_pos / load_pos, see wait.gsc)
WaypointSetup(controls = 0)
{
    self thread WaypointSave();
    self thread WaypointLoad();
    if(controls) self thread ShowControls(Array(Array("save_pos", "Save Position"), Array("load_pos", "Load Position")));
}

WaypointSave()
{
    for(;;)
    {
        WaitBind("save_pos");
        thread WriteToScreen("Position Saved");
        self.waypoint = Array(self GetOrigin(), self GetPlayerAngles());
    }
}

WaypointLoad()
{
    for(;;)
    {
        WaitBind("load_pos");
        if(IsDefined(self.waypoint))
        {
            thread WriteToScreen("Position Loaded");
            self SetOrigin(self.waypoint[0]);
            self SetPlayerAngles(self.waypoint[1]);
        }
        else thread WriteToScreen("No Position Saved");
    }
}