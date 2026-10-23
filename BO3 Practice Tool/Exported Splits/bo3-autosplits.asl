// BO3 Practice Tool autosplitter
// Works with both the downpatched BlackOps3.exe (March 2023) and the current Steam exe (2026 updates).
// The 2026 updates moved the game's globals down by 0x7F000 or 0x7EF80; both are tried and the one
// holding a real value is kept.
state("blackops3")
{
}

startup
{
    vars.time_offset = 0;
    vars.offset_pending = false;
    timer.CurrentTimingMethod = TimingMethod.GameTime;

    vars.ValidMap = (Func<string, bool>)((name) => {
        if (string.IsNullOrEmpty(name) || name.Length < 4) return false;
        foreach (char c in name) {
            if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')) return false;
        }
        return name.StartsWith("zm_") || name.StartsWith("cp_") || name.StartsWith("mp_") || name.StartsWith("core_");
    });
}

init
{
    IntPtr b = modules.First().BaseAddress;
    int pe = memory.ReadValue<int>(b + 0x3C);
    uint stamp = memory.ReadValue<uint>(b + pe + 8);
    vars.is2026 = stamp >= 1767225600u; // linked on/after 1 Jan 2026
    vars.b = b;
    // "high" = map name + split dvar, "low" = round + level time
    vars.shiftHigh = 0;
    vars.shiftLow = 0;
    vars.highFound = !vars.is2026;
    vars.lowFound = !vars.is2026;
    print("[BO3 Practice Tool] " + (vars.is2026 ? "Current Steam exe (2026)" : "Downpatched exe (2023)"));

    current.round_counter = 0;
    current.level_time = 0;
    current.map_name = "";
    current.split = 0;
}

update
{
    IntPtr b = vars.b;
    int[] shifts = { 0x7EF80, 0x7F000 };

    if (!vars.highFound) {
        foreach (int s in shifts) {
            string name = (memory.ReadString(b + 0x179DF840 - s, 13) ?? "").Split('\0')[0];
            if (vars.ValidMap(name)) {
                vars.shiftHigh = s;
                vars.highFound = true;
                print("[BO3 Practice Tool] map name shift 0x" + s.ToString("X"));
                break;
            }
        }
    }
    current.map_name = vars.highFound ? (memory.ReadString(b + 0x179DF840 - (int)vars.shiftHigh, 13) ?? "").Split('\0')[0] : "";
    current.split = vars.highFound ? memory.ReadValue<int>(b + 0x17B3C3C8 - (int)vars.shiftHigh) : 0;

    if (!vars.lowFound && current.map_name.StartsWith("zm_")) {
        foreach (int s in new int[] { 0x7F000, 0x7EF80 }) {
            byte r = memory.ReadValue<byte>(b + 0xA55BDEC - s);
            if (r >= 1) {
                vars.shiftLow = s;
                vars.lowFound = true;
                print("[BO3 Practice Tool] round shift 0x" + s.ToString("X"));
                break;
            }
        }
    }
    current.round_counter = vars.lowFound ? memory.ReadValue<byte>(b + 0xA55BDEC - (int)vars.shiftLow) : (byte)0;
    current.level_time = vars.lowFound ? memory.ReadValue<int>(b + 0xA6424FC - (int)vars.shiftLow) : 0;

    // the timer started before the round address was found: take the start time now
    if (vars.offset_pending && vars.lowFound) {
        vars.time_offset = current.level_time;
        vars.offset_pending = false;
    }
}

start
{
    if (current.split > 0 && current.split > old.split)
    {
        vars.time_offset = current.level_time;
        vars.offset_pending = !vars.lowFound;
        return true;
    }
}

split
{
    return current.split > 1 && current.split > old.split;
}

gameTime
{
    if (vars.offset_pending) return TimeSpan.Zero;
    return new TimeSpan(0, 0, 0, 0, current.level_time - vars.time_offset);
}

reset
{
    return (current.round_counter == 0 && old.round_counter != 0 || current.split == 0 && old.split != 0 || current.map_name.Equals("core_frontend"));
}

isLoading
{
    return true;
}
