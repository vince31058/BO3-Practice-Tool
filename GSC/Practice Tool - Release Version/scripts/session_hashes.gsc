// Session hashes and the anti-splice code.
//
// Whenever the Practice Tool is on (with or without a practice patch, on the downpatched 2023 exe and on the
// current 2026 Steam exe), every game start (map load or fast_restart) shows for 10 seconds in the top right of
// the screen:
//   - the hash of the Practice Tool script that was injected, and the app version
//   - the game build
//   - the loaded mod (fs_game) and, on a custom map, the map, each with the hash of its files
//   - this session's ID
// and the bottom left corner always shows the anti-splice line:   PT <game ID> <code>
// The game ID is made once when the game starts and stays the same (through map loads and fast_restarts) until
// the game closes; it's kept in dvars, which last until the game closes. The code next to it changes every second.
//
// GSC can't open files, so the app works out the hashes and writes them to
// "Practice Tool/Settings/Session Hashes.txt" every time the tool is turned on and every time a map loads
// (WriteSessionHashes in ToolData.cpp). The file is numbers only, because compiler::readsettings only reads
// numbers. Positions start at 1:
//   1 format (1)   2-3 random nonce   4-7 tool script SHA-256 (first 8 bytes, 16 bits per number)
//   8 app version (major*10000 + minor*100 + fix)   9 game build (0 unknown, 1 downpatched 2023, 2 Steam 2026)
//   10 entry count, then 6 numbers for every installed mod / custom map (mods, usermaps, Steam Workshop):
//      name key (PtNameKey), kind (1 mod, 2 map), hash of its files (first 8 bytes, 4 numbers)
//   then the end marker 7777777
//
// Anti-splice code. Anyone can recompute it from what is on screen:
//   mix(h, x) = (h*h mod 46337 + 31*h + x + 7) mod 46337
//   the session ID is two numbers a-b (shown in hex in the hash flash), the game ID two numbers c-d (shown in hex
//   bottom left). With A = mix(a, c) and B = mix(b, d), at second t (0, 1, 2, ...) of the attempt the code is
//   mix(mix(mix(A, t mod 46337), B), floor(t / 46337)) * 10 + (t mod 10)
// (the last digit is the second counter). Every code has to follow from the two IDs: a cut skips seconds, and
// footage from another attempt has another session ID. The session ID is new every attempt (map load or
// fast_restart): random (app nonce + RandomInt + game time), also mixing in the tool, mod and map hashes.

PtHashFile()
{
    return "Practice Tool/Settings/Session Hashes.txt";
}

// -1 when the file or the number isn't there. The last argument must stay 0: anything else makes
// readsettings write the file back (it isn't a default value).
PtHashValue(index)
{
    return compiler::readsettings(PtHashFile(), index, 0);
}

PtNonNeg(value)
{
    if(!IsDefined(value) || value < 0) return 0;
    return value;
}

PtHex4(value)
{
    digits = "0123456789abcdef";
    text = "";
    for(i = 0; i < 4; i++)
    {
        d = value % 16;
        text = GetSubStr(digits, d, d + 1) + text;
        value = Int(value / 16);
    }
    return text;
}

// 4 numbers from position start as 16 hex digits, undefined if any is missing
PtHashText(start)
{
    text = "";
    for(i = 0; i < 4; i++)
    {
        part = PtHashValue(start + i);
        if(part < 0) return undefined;
        text += PtHex4(part);
    }
    return text;
}

PtHashTextOr(start)
{
    text = PtHashText(start);
    if(!IsDefined(text)) return "^1no hash";
    return text;
}

// Must match SessionNameKey in ToolData.cpp
PtNameKey(name)
{
    chars = "abcdefghijklmnopqrstuvwxyz0123456789_-. ";
    name = ToLower(name);
    key = 0;
    for(i = 0; i < name.size; i++)
    {
        c = GetSubStr(name, i, i + 1);
        v = 41;
        for(j = 0; j < chars.size; j++)
        {
            if(GetSubStr(chars, j, j + 1) == c)
            {
                v = j + 1;
                break;
            }
        }
        key = (key * 42 + v) % 50000017;
    }
    return key;
}

// The loaded mod's folder name, undefined when no mod is loaded. fs_game can be "name", "mods/name" or a
// Workshop item ID; the app lists Workshop mods under both their folder name and their ID.
PtModName()
{
    mod = GetDvarString("fs_game");
    if(!IsDefined(mod) || mod == "") return undefined;
    tokens = StrTok(ToLower(mod), "/\\");
    if(!tokens.size) return undefined;
    return tokens[tokens.size - 1];
}

PtIsStockMap(map)
{
    stock = Array("zm_zod", "zm_factory", "zm_castle", "zm_island", "zm_stalingrad", "zm_genesis", "zm_moon", "zm_tomb",
        "zm_prototype", "zm_asylum", "zm_sumpf", "zm_theater", "zm_cosmodrome", "zm_temple");
    return IsInArray(stock, map);
}

// Position of the entry's name key in the file, -1 if it isn't listed
PtFindEntry(name, kind)
{
    if(!IsDefined(name)) return -1;
    key = PtNameKey(name);
    count = PtHashValue(10);
    for(i = 0; i < count; i++)
    {
        base = 11 + i * 6;
        if(PtHashValue(base) == key && PtHashValue(base + 1) == kind) return base;
        if(i % 25 == 24) wait 0.05;
    }
    return -1;
}

PtEntryPart(base, i)
{
    if(base < 0) return 0;
    return PtNonNeg(PtHashValue(base + 2 + i));
}

PtMix(h, x)
{
    return ((h * h) % 46337 + h * 31 + x + 7) % 46337;
}

PtCode(a, b, t)
{
    return PtMix(PtMix(PtMix(a, t % 46337), b), Int(t / 46337)) * 10 + (t % 10);
}

// Runs at every game start (main.gsc on_player_connect, host only)
PtSessionStart()
{
    level notify("pt_session_start");
    level endon("pt_session_start");

    ready = PtHashValue(1) == 1;
    mod_name = PtModName();
    custom_map = !PtIsStockMap(level.script);
    mod_base = -1;
    map_base = -1;
    if(ready)
    {
        if(IsDefined(mod_name)) mod_base = PtFindEntry(mod_name, 1);
        if(custom_map) map_base = PtFindEntry(level.script, 2);
    }

    inputs = [];
    for(i = 2; i <= 7; i++) inputs[inputs.size] = PtNonNeg(PtHashValue(i));
    for(i = 0; i < 4; i++) inputs[inputs.size] = PtEntryPart(mod_base, i);
    for(i = 0; i < 4; i++) inputs[inputs.size] = PtEntryPart(map_base, i);
    inputs[inputs.size] = RandomInt(46337);
    inputs[inputs.size] = RandomInt(46337);
    inputs[inputs.size] = GetTime() % 46337;
    a = 7;
    b = 13;
    foreach(x in inputs)
    {
        a = PtMix(a, x);
        b = PtMix(b, (a + x) % 46337);
    }
    level.pt_session_id = PtHex4(a) + "-" + PtHex4(b);

    PtGameId(a, b);
    level thread PtAntiSpliceHud(PtMix(a, level.pt_game_a), PtMix(b, level.pt_game_b));
    level thread PtShowSessionHashes(ready, mod_name, mod_base, custom_map, map_base);
}

// The game ID: made on the first game start after the game opens, then read back from dvars (they last until
// the game closes), so it stays the same through every map load and fast_restart of this game.
PtGameId(a, b)
{
    if(GetDvarInt("pt_game_id_set") != 1)
    {
        c = PtMix(PtMix(7, a), RandomInt(46337));
        d = PtMix(PtMix(c, b), GetTime() % 46337);
        d = PtMix(d, RandomInt(46337));
        SetDvar("pt_game_a", c);
        SetDvar("pt_game_b", d);
        SetDvar("pt_game_id_set", 1);
    }
    level.pt_game_a = GetDvarInt("pt_game_a");
    level.pt_game_b = GetDvarInt("pt_game_b");
    level.pt_game_id = PtHex4(level.pt_game_a) + "-" + PtHex4(level.pt_game_b);
}

PtShowSessionHashes(ready, mod_name, mod_base, custom_map, map_base)
{
    if(ready)
    {
        tool_hash = PtHashText(4);
        version = PtHashValue(8);
        title = "^5Practice Tool";
        if(version > 0) title += " v" + Int(version / 10000) + "." + (Int(version / 100) % 100) + "." + (version % 100);
        if(IsDefined(tool_hash)) text = title + "  ^3" + tool_hash;
        else text = title + "  ^1no hash";

        build = PtHashValue(9);
        if(build == 1) build_text = "Downpatched (2023)";
        else if(build == 2) build_text = "Current Steam (2026)";
        else build_text = "Unknown build";
        text += "\n^5Game: ^7" + build_text;
    }
    else
    {
        text = "^1Session hashes missing: turn the tool on from the Practice Tool app";
    }

    if(!IsDefined(mod_name)) text += "\n^5Mod: ^7none";
    else if(mod_base >= 0) text += "\n^5Mod: ^7" + mod_name + "  ^3" + PtHashTextOr(mod_base + 2);
    else text += "\n^5Mod: ^7" + mod_name + "  ^1no hash (not found)";

    if(!custom_map) text += "\n^5Map: ^7" + level.script + " (stock)";
    else if(map_base >= 0) text += "\n^5Map: ^7" + level.script + "  ^3" + PtHashTextOr(map_base + 2);
    else text += "\n^5Map: ^7" + level.script + "  ^1no hash (not found)";

    text += "\n^5Session: ^7" + level.pt_session_id;

    // top right corner
    hud = NewHudElem();
    hud.alignx = "right";
    hud.aligny = "top";
    hud.horzalign = "user_right";
    hud.vertalign = "user_top";
    hud.x = -15;
    hud.y = 15;
    hud.font = "default";
    hud.fontscale = 1.2;
    hud.color = (1, 1, 1);
    hud.alpha = 1;
    hud.hidewheninmenu = 0;
    hud.foreground = 1;
    hud SetText(text);
    wait 10;
    hud FadeOverTime(2);
    hud.alpha = 0;
    wait 2;
    hud Destroy();
}

PtCornerHud(x)
{
    hud = NewHudElem();
    hud.alignx = "left";
    hud.aligny = "bottom";
    hud.horzalign = "user_left";
    hud.vertalign = "user_bottom";
    hud.x = x;
    hud.y = -2;
    hud.font = "default";
    hud.fontscale = 1;
    hud.color = (1, 1, 1);
    hud.alpha = 0.8;
    hud.hidewheninmenu = 0;
    hud.foreground = 1;
    return hud;
}

// Bottom left corner, always on: "PT <game ID>" (stays until the game closes) and the code next to it, which
// changes every second. Only the number changes (SetValue): changing text with SetText every second would use
// up the game's string slots and crash a long game. Move it with the x values here and y in PtCornerHud.
PtAntiSpliceHud(a, b)
{
    id_hud = PtCornerHud(5);
    id_hud SetText("^7PT " + level.pt_game_id);
    code_hud = PtCornerHud(58);
    code_hud.label = &"^3";

    t = 0;
    for(;;)
    {
        code_hud SetValue(PtCode(a, b, t));
        wait 1;
        t++;
    }
}
