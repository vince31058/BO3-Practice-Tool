// Soft patch gum packs. Each map starts with the preset_gums mod's pack; the app (Settings >
// Soft Patch Gums) can change them. It writes Practice Tool/Settings/Soft Patch Gums.txt as 5 gum
// numbers per map (level.custom_bgb_list order) for zod, factory, castle, island, stalingrad,
// genesis, moon, tomb; -1 means that map uses its default pack.
PresetGumPack()
{
    switch(level.script)
    {
        case "zm_zod":
            return Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here", "zm_bgb_wall_power");
        case "zm_factory":
            return Array("zm_bgb_extra_credit", "zm_bgb_reign_drops", "zm_bgb_ephemeral_enhancement", "zm_bgb_shopping_free", "zm_bgb_wall_power");
        case "zm_castle":
            return Array("zm_bgb_extra_credit", "zm_bgb_reign_drops", "zm_bgb_perkaholic", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_anywhere_but_here");
        case "zm_island":
            return Array("zm_bgb_anywhere_but_here", "zm_bgb_reign_drops", "zm_bgb_extra_credit", "zm_bgb_perkaholic", "zm_bgb_dead_of_nuclear_winter");
        case "zm_stalingrad":
            return Array("zm_bgb_shopping_free", "zm_bgb_reign_drops", "zm_bgb_anywhere_but_here", "zm_bgb_perkaholic", "zm_bgb_dead_of_nuclear_winter");
        case "zm_genesis":
            return Array("zm_bgb_shopping_free", "zm_bgb_reign_drops", "zm_bgb_extra_credit", "zm_bgb_perkaholic", "zm_bgb_immolation_liquidation");
        case "zm_tomb":
            return Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_extra_credit", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_self_medication");
        case "zm_moon":
            return Array("zm_bgb_perkaholic", "zm_bgb_reign_drops", "zm_bgb_shopping_free", "zm_bgb_dead_of_nuclear_winter", "zm_bgb_immolation_liquidation");
        default:
            return undefined;
    }
}

// The pack picked in the app for this map, or undefined when it uses the default.
CustomSoftPatchGums()
{
    maps = Array("zm_zod", "zm_factory", "zm_castle", "zm_island", "zm_stalingrad", "zm_genesis", "zm_moon", "zm_tomb");
    slot = -1;
    foreach(index, map in maps)
    {
        if(map == level.script) slot = index;
    }
    if(slot < 0 || !IsDefined(level.custom_bgb_list)) return undefined;
    file = "Practice Tool/Settings/Soft Patch Gums.txt";
    pack = [];
    for(i = 1; i <= 5; i++)
    {
        num = compiler::readsettings(file, slot * 5 + i, -1);
        if(num < 0 || num >= level.custom_bgb_list.size) return undefined;
        gum = level.custom_bgb_list[num];
        if(IsInArray(pack, gum)) return undefined;
        pack[pack.size] = gum;
    }
    return pack;
}

// Gives every player this map's soft patch pack. Returns true for the default pack (the patch then
// sets its own gum cycle); for a pack picked in the app it shuffles it here, Reign Drops first if
// it is in the pack, and returns false.
SetPresetGums()
{
    pack = CustomSoftPatchGums();
    custom = IsDefined(pack);
    if(!custom) pack = PresetGumPack();
    if(!IsDefined(pack)) return false;
    foreach(player in GetPlayers()) player.bgb_pack = pack;
    self.bgb_pack = pack;
    if(!custom) return true;
    rest = [];
    foreach(gum in pack)
    {
        if(gum != "zm_bgb_reign_drops") rest[rest.size] = gum;
    }
    rest = array::randomize(rest);
    self.bgb_pack_randomized = [];
    if(rest.size < pack.size) self.bgb_pack_randomized[0] = "zm_bgb_reign_drops";
    foreach(gum in rest) self.bgb_pack_randomized[self.bgb_pack_randomized.size] = gum;
    return false;
}
