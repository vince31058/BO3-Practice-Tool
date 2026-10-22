// ---------------------------------------------------------------------------
// Keyboard input
//
// compiler::waitkey(vk) is edge-triggered and keeps ONE "already down" flag per
// key, shared by every caller. When several threads poll the same key (F3 is
// used by the zombie counter and most practice patches at once), the first
// thread to poll after a press consumes it and every other thread misses it.
//
// Instead, one dispatcher thread polls each key that anything is listening
// for, once per server frame, and notifies everyone waiting on that key.
// Any number of threads can wait on the same key and all of them react.
//
// Virtual-key codes: https://learn.microsoft.com/windows/win32/inputdev/virtual-key-codes
// ---------------------------------------------------------------------------

#define VK_PRIOR = 0x21; // Page Up
#define VK_NEXT = 0x22; // Page Down
#define VK_END = 0x23;
#define VK_HOME = 0x24;
#define VK_ADD = 0x6B; // numpad +
#define VK_F3 = 0x72;
#define VK_F5 = 0x74;
#define VK_F6 = 0x75;
#define VK_F7 = 0x76;
#define VK_F8 = 0x77;
#define VK_F9 = 0x78;
#define VK_OEM_PLUS = 0xBB; // = / + key

// Block until `key` is pressed (one press = one return).
WaitKey(key)
{
    RegisterKey(key);
    level waittill("pt_key_" + key);
}

// Block until either key is pressed.
WaitKeyEither(key1, key2)
{
    RegisterKey(key1);
    RegisterKey(key2);
    level util::waittill_any("pt_key_" + key1, "pt_key_" + key2);
}

RegisterKey(key)
{
    if(!IsDefined(level.pt_watched_keys)) level.pt_watched_keys = [];
    level.pt_watched_keys[key] = true;

    if(IsTrue(level.pt_key_dispatcher_running)) return;
    level.pt_key_dispatcher_running = true;
    level thread KeyDispatcher();
}

KeyDispatcher()
{
    for(;;)
    {
        foreach(key, unused in level.pt_watched_keys)
        {
            if(compiler::waitkey(key)) level notify("pt_key_" + key);
        }
        wait 0.05;
    }
}

// Shows `hud_elem` and toggles its visibility every time `key` is pressed.
// Replaces the copy-pasted "controls.alpha = 1; WaitF3(); controls.alpha = 0; WaitF3();" loops.
ToggleHudOnKey(hud_elem, key = 0x72) // default F3
{
    for(;;)
    {
        hud_elem.alpha = 1;
        WaitKey(key);
        hud_elem.alpha = 0;
        WaitKey(key);
    }
}

WaitF3()     { WaitKey(VK_F3); }
WaitF5()     { WaitKey(VK_F5); }
WaitF6()     { WaitKey(VK_F6); }
WaitF7()     { WaitKey(VK_F7); }
WaitF8()     { WaitKey(VK_F8); }
WaitF9()     { WaitKey(VK_F9); }
WaitPgUp()   { WaitKey(VK_PRIOR); }
WaitPgDown() { WaitKey(VK_NEXT); }
WaitEnd()    { WaitKey(VK_END); }
WaitHome()   { WaitKey(VK_HOME); }
WaitPlus()   { WaitKeyEither(VK_OEM_PLUS, VK_ADD); }

// ---------------------------------------------------------------------------
// Universal patch controls - the same binds in every practice patch.
// Each one works with a controller-style button combo or a keyboard key:
//
//   action1        ADS + Melee      or F5
//   action2        ADS + Crouch     or F6
//   action3        ADS + Jump       or F7
//   action4        ADS + Reload     or F8
//   action5        ADS + Grenade    or F9
//   save_pos       Melee + Crouch   or [      (hold both for half a second)
//   load_pos       Melee + Jump     or ]      (hold both for half a second)
//   hide_controls  ADS + Use        or F3
//   reset_patch    Melee + Grenade            (hold both for half a second)
//
// ADS combos fire when the second button is pressed while aiming. Combos without ADS have to be
// held, so jump-knifing or crouch-knifing in normal play doesn't set them off.
// Patches with options (robot cycle, Fire Enter) change them with action binds and apply them
// on the next fast restart.
// ---------------------------------------------------------------------------

InitBinds()
{
    if(IsDefined(level.pt_binds)) return;
    level.pt_binds = [];
    AddBind("action1", "melee", true, 0x74, "ADS+Melee/F5");
    AddBind("action2", "crouch", true, 0x75, "ADS+Crouch/F6");
    AddBind("action3", "jump", true, 0x76, "ADS+Jump/F7");
    AddBind("action4", "reload", true, 0x77, "ADS+Reload/F8");
    AddBind("action5", "frag", true, 0x78, "ADS+Grenade/F9");
    AddBind("save_pos", "melee+crouch", false, 0xDB, "Melee+Crouch/[");
    AddBind("load_pos", "melee+jump", false, 0xDD, "Melee+Jump/]");
    AddBind("hide_controls", "use", true, 0x72, "ADS+Use/F3");
    AddBind("reset_patch", "melee+frag", false, undefined, "Melee+Grenade");
}

AddBind(name, buttons, ads, key, text)
{
    bind = SpawnStruct();
    bind.name = name;
    bind.buttons = StrTok(buttons, "+");
    bind.ads = ads;
    bind.key = key;
    bind.text = text;
    bind.down = false;
    bind.held = 0;
    level.pt_binds[name] = bind;
}

// Block until the bind is used (one use = one return).
WaitBind(name)
{
    StartBinds();
    level waittill("pt_bind_" + name);
}

// Text for a controls list, e.g. "ADS+Melee/F5"
BindText(name)
{
    InitBinds();
    return level.pt_binds[name].text;
}

WaitAction(n)
{
    WaitBind("action" + n);
}

StartBinds()
{
    InitBinds();
    if(IsTrue(level.pt_binds_running)) return;
    level.pt_binds_running = true;
    foreach(bind in level.pt_binds)
    {
        if(IsDefined(bind.key)) level thread BindKeyWatcher(bind.name, bind.key);
    }
    level thread BindButtonWatcher();
}

BindKeyWatcher(name, key)
{
    for(;;)
    {
        WaitKey(key);
        level notify("pt_bind_" + name);
    }
}

BindButtonWatcher()
{
    for(;;)
    {
        wait 0.05;
        player = GetPlayers()[0];
        if(!IsDefined(player) || !IsAlive(player)) continue;
        ads = player AdsButtonPressed();
        foreach(bind in level.pt_binds)
        {
            down = true;
            foreach(button in bind.buttons)
            {
                if(!player BindButtonDown(button))
                {
                    down = false;
                    break;
                }
            }
            if(bind.ads)
            {
                down = down && ads;
                if(down && !bind.down) level notify("pt_bind_" + bind.name);
                bind.down = down;
                continue;
            }
            if(!down)
            {
                bind.held = 0;
                continue;
            }
            bind.held++;
            if(bind.held == 10) level notify("pt_bind_" + bind.name); // held for half a second
        }
    }
}

BindButtonDown(button)
{
    switch(button)
    {
        case "melee": return self MeleeButtonPressed();
        case "crouch": return self StanceButtonPressed();
        case "jump": return self JumpButtonPressed();
        case "reload": return self ReloadButtonPressed();
        case "frag": return self FragButtonPressed();
        case "use": return self UseButtonPressed();
    }
    return false;
}

// The standard controls line for a practice patch: small, faded text at the top of the screen,
// labeled with what each bind does (three per row), e.g. "ADS+Melee/F5: Force Lock".
// entries: Array of Array(bind, label), e.g. Array(Array("action1", "Target Bear")).
// The last item is always the hide bind; hide_controls (ADS+Use / F3) hides and shows the line.
ShowControls(entries)
{
    entries[entries.size] = Array("hide_controls", "Hide");
    text = "";
    foreach(index, entry in entries)
    {
        if(index > 0)
        {
            if(index % 3 == 0) text += "\n";
            else text += "     ";
        }
        text += ShortBindText(entry[0]) + ": " + entry[1];
    }
    controls = NewHudElem();
    controls.alignx = "center";
    controls.aligny = "top";
    controls.horzalign = "center";
    controls.vertalign = "top";
    controls.y = 4;
    controls.fontscale = 1.0;
    controls.hidewheninmenu = 1;
    controls SetText(text);
    for(;;)
    {
        controls.alpha = 0.85;
        WaitBind("hide_controls");
        controls.alpha = 0;
        WaitBind("hide_controls");
    }
}

// "ADS+Melee / F5" -> "ADS+Melee/F5" for the compact controls line
ShortBindText(name)
{
    parts = StrTok(BindText(name), " ");
    text = "";
    foreach(part in parts) text += part;
    return text;
}
