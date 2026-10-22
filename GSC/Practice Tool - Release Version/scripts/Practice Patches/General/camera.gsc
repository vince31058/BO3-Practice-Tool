// Camera (action = which universal action bind sets / toggles it)
CameraPos(action)
{
    pos = (0, 0, 0);
    angles = (0, 0, 0);
    for(;;)
    {
        WaitAction(action);
        pos = self GetTagOrigin("j_head");
        angles = self GetPlayerAngles();
        self CameraSetPosition(pos, angles);
        thread WriteToScreen("Updated Camera Position");
    }
}

CameraToggle(action)
{
    camera_active = false;
    for(;;)
    {
        WaitAction(action);
        camera_active = !camera_active;
        self CameraActivate(camera_active);
        thread WriteToScreen("Camera Toggled");
    }
}