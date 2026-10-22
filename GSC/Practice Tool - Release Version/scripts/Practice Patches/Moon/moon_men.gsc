// Moon Men: the names the Moon astronaut can show, set in the app (Settings > Moon Men).
// The app writes Practice Tool/Settings/Moon Men.txt as character codes (each name's characters,
// then 0; -1 ends the list) because the game script can only read numbers from settings files.
// With no names saved, the astronaut gets its normal name from the game.

detour zm_moon_ai_astro<scripts\zm\zm_moon_ai_astro.gsc>::zombie_set_fake_playername()
{
    names = MoonMenNames();
    if(names.size)
    {
        self setzombiename(names[RandomInt(names.size)]);
        return;
    }
    self setzombiename("SpaceZom");
}

MoonMenNames()
{
    if(IsDefined(level.moon_men)) return level.moon_men;
    level.moon_men = [];
    chars = " !?#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[?]^_`abcdefghijklmnopqrstuvwxyz{|}~"; // character codes 32-126 (quote and backslash are never used in names)
    file = "Practice Tool/Settings/Moon Men.txt";
    name = "";
    for(i = 1; i < 2000; i++)
    {
        code = compiler::readsettings(file, i, -1);
        if(code < 0) break;
        if(code == 0)
        {
            if(name == "") break; // two 0s in a row: no more names (or no file)
            level.moon_men[level.moon_men.size] = name;
            name = "";
            continue;
        }
        if(code >= 32 && code <= 126) name += GetSubStr(chars, code - 32, code - 31);
    }
    return level.moon_men;
}
