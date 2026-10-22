ZombieCounter()
{
    level endon("end_game");

    last_counted_total = -1;
    last_counted_current = -1;
    total_zombies = hud::createfontstring("big", 1.3);
    current_zombies = hud::createfontstring("big", 1.3);
    total_zombies hud::setpoint("TOPRIGHT", "TOPRIGHT", -5, 20);
    current_zombies hud::setpoint("TOPRIGHT", "TOPRIGHT", -9, 35);
    total_zombies.color = (1, 0, 0);
    current_zombies.color = (0, 1, 0);
    // Static label + SetValue: the number updates without SetText creating a new
    // HUD string for every count (avoids config string growth in long games).
    total_zombies.label = &"Zombies Remaining: ";
    current_zombies.label = &"Zombies Spawned: ";
    thread MonitorAlpha(total_zombies, current_zombies);
    for(;;)
    {
        if(IsTrue(level.custom_spawn_monitor))
        {
            total_zombies Destroy();
            current_zombies Destroy();
            return;
        }
        // get_current_zombie_count() builds a filtered array of every AI on the map,
        // so take it once per frame instead of up to five times.
        current = zombie_utility::get_current_zombie_count();
        total = level.zombie_total + current;
        if(total != last_counted_total)
        {
            if(IsTrue(level.zombie_counter_diagnostic)) compiler::nprintln("Zombies Remaining Changed At " + Int(GetTime() - level.n_gameplay_start_time) + " - " + last_counted_total + " -> " + Int(total));
            last_counted_total = total;
            total_zombies SetValue(total);
        }
        if(current != last_counted_current)
        {
            if(IsTrue(level.zombie_counter_diagnostic)) compiler::nprintln("Zombies Spawned Changed At " + Int(GetTime() - level.n_gameplay_start_time) + " - " + last_counted_current + "/" + last_counted_total + " -> " + current + "/" + last_counted_total);
            last_counted_current = current;
            current_zombies SetValue(current);
        }
        wait 0.05;
    }
}

MonitorAlpha(hud1, hud2)
{
    level endon("end_game");

    for(;;)
    {
        hud1.alpha = 1;
        hud2.alpha = 1;
        WaitF3();
        hud1.alpha = 0;
        hud2.alpha = 0;
        WaitF3();
    }
}
