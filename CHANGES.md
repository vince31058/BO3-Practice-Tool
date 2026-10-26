# Practice Tool – changes in this build

Changes are in the GSC source (`GSC/Practice Tool - Release Version/scripts/`), plus small C++ changes
for the Moon additions and the build setup. The compiler DLL is untouched.

## Building the .exe (and the mod)

**On your PC:** double-click `build.bat` in the project root. It:
1. compiles the GSC mod and updates `Compiler/Practice Tool.gsc` (stops with the file and line if there's a script error),
2. builds `BO3 Practice Tool.exe` (Release x64),
3. puts a ready-to-run copy in `dist\BO3 Practice Tool\`, opens that folder, and offers to launch it.

One-time requirement: Visual Studio 2022 (Community is free) with the **Desktop development with C++**
workload. Its bundled vcpkg downloads the libraries on the first build (that build takes a few minutes).

**On GitHub:** push the project to a repo and `.github/workflows/build.yml` runs the same steps on a clean
Windows machine. Open the run under **Actions** and download **BO3-Practice-Tool** from Artifacts.

### Why the project needed changes to build
The original project relied on libraries (curl, miniz, rapidjson, rapidxml, glm, Vulkan) installed
machine-wide on the author's PC; none are in the repo. `BO3 Practice Tool/vcpkg.json` now lists them and
the project has vcpkg manifest mode on, so Visual Studio fetches them automatically. The Vulkan SDK is
no longer a separate install.

## Moon additions

### Box Lock Practice (Practice Patches → Moon)
The "Moon God Mod" ported into the tool (`Practice Patches/Moon/box_lock.gsc`), same features:
- Annihilator kept fully charged, 50,000 points, every perk (re-applied after a respawn)
- Mystery Box only rolls QED and Gersh Device; fire sale that never ends
- Box lock trainer: 12s countdown, **PRESS NOW!** cue, lock / missed / grabbed result
- **ADS + Melee**: force-lock nearest open box · **ADS + Jump**: toggle zombie spawns (round can't flip) · **ADS + Crouch**: drop a Death Machine
- Power on at start; teleporter cage and NML bunker gate kept open

Select it in the app under Practice Patches → Moon.

### Moon autosplits
The Moon timer's six splits are now regular autosplits (`Autosplits/moon_timer.gsc`), selectable in the
app's Autosplits tab like every other map, with round conditions, IGT and LiveSplit support:

| Split | Game trigger (zm_moon_sq) |
|---|---|
| Simon Says | flag `ss1` (Simon Says 1 done) |
| Security Override | stage `osc` complete (`sq_osc_over`) |
| Focus | flag `vg_charged` (vril generator charged) |
| First Tank | flag `first_tanks_charged` |
| Second Tank | flag `second_tanks_charged` |
| Moon End | `sq_ss2_over` → flag `be2` → +70.5s (same end as the Moon timer); also used for **Egg End** |

Steps that only send a one-time notify are tracked from match start, so a split still completes if its
step happened before that split came up in your layout.

**How it works without a new compiler DLL:** `t7cinternal.dll` turns split *names* into numbers with a
built-in table that has no Moon entries. The app now also saves each split's number in the preset
(`Settings → "Split Index N"`), and the script uses that when present, falling back to the DLL's name
lookup for older presets. So every existing preset keeps working; re-save a preset to use the new path.

## Performance

| Area | Before | After |
|---|---|---|
| Keyboard input (`wait.gsc`) | Every feature polled its own key with `compiler::waitkey` every frame (20+ threads with practice patches on) | One `KeyDispatcher` thread polls each key once per frame and notifies all listeners |
| Zombie counter | Rebuilt the full AI array up to 5×/frame; `SetText` with a new string for every count | One array build per frame; static label + `SetValue` (no new HUD string per number) |
| Spawner debug HUDs | Re-sent identical text 20×/second (4 HUDs) | Update only when the value changes; numeric HUDs use `SetValue` |
| Revelations timer | Started on **every** map: 3 hidden HUD elements + a per-frame poll for the Keeper | Only started on `zm_genesis` |

## Bugs fixed

- **Shared keys were stolen between features.** `compiler::waitkey` is edge-triggered with one
  "already down" flag per key, shared by every caller (confirmed from `t7cinternal.dll`). With the
  zombie counter and a practice patch both on, F3 toggled only one of them, at random. The key
  dispatcher fixes this; every listener now reacts to every press.
- **Ignore Players OFF never stopped.** Turning it off left a loop forcing `ignoreme = 0` on all
  players every 0.25s for the rest of the game, overriding the game's own use of `ignoreme`.
  It now restores once and exits.
- **Lullaby song split (Zetsubou) fired early.** The match check was inside the comparison loop,
  so it fired once the *first* note matched. It now uses the exact comparison
  `zm_island_side_ee_song` uses. (The old pod-replay branch could never run and was removed.)
- **Open All Doors on Revelations ran the Origins code.** A missing `break` fell through into
  `EnableTeleporters` / `TriggerCrypt`, which errors on a door that doesn't exist on that map.
- **Gorod initialised Origins flags.** A missing `break` in `InitCustomFlags` fell through into
  the `zm_tomb` case.
- **Re-enabling God Mode stacked threads.** Each enable started another refresh loop; it now
  replaces the previous one (and ends on disconnect).

## Cleanup (no behaviour change)

- `wait.gsc`: named key constants (`VK_F3`, `VK_HOME`, …) instead of raw hex; new helpers
  `WaitKey(key)`, `WaitKeyEither(a, b)`, `ToggleHudOnKey(hud, key = F3)`.
- Ten copy-pasted "show controls, F3 hides them" loops replaced with `ToggleHudOnKey(controls)`.
- Direct `while(!compiler::waitkey(key)) wait 0.05;` polls (camera, waypoint, basketball) now use `WaitKey(key)`.
- Simplified two redundant conditions in `basketball.gsc`.

## For your own mods

Wait for keys with `WaitKey(0x..)` (or the `WaitF*` helpers), never by polling
`compiler::waitkey` yourself; direct polling steals presses from everything else listening to that key.

## Works on both game versions (1.0.5)
The tool now injects into both the downpatched BlackOps3.exe (March 2023) and the current Steam exe
(2026 updates), and picks the right one by itself from the exe's link date.
- `Compiler/DebugCompiler26.exe` + `Compiler/t7cintern26.dll`: the same injector with the game addresses
  moved to the 2026 exe (from Scroptss's t7-compiler update, checked against the 2026 exe's function table).
  The originals (`DebugCompiler.exe`, `t7cinternal.dll`) are unchanged and still used for the downpatched exe.
- The app reads the map name and round at the 2026 addresses on the new exe (found and checked at runtime).
- Miscellaneous → Install Location → **Game Version** shows which exe was found and lets you force one.
- `bo3-autosplits.asl` handles both exes; `Vin.bat` picks the right injector for option 1.

## v1.1.0

### New
- **Box Hits counter** – Revelations and Moon autosplit presets can show how many times you've hit the box (top right). Resets on every restart. Turn it on with the checkbox next to the splits table.
- **DE Wisp Trainer** (Resources) – a click-and-guess drill for the time travel wisp table, showing just the 50/50s.
- **Wisp Order Practice** (Der Eisendrache)
  - Practice the time travel wisp step on repeat, with the map open, power on, all perks and the Storm Bow. You start at the base bow pedestal.
  - Wisps glow like the real step but aren't named. Every hit shows "Hit (n/4)", and a fail tells you where the wisp actually was.
  - On a fail you're sent back to the pedestal for another try.
  - Step timer with a PB (kept until you close the game) and a route recap after every attempt.
  - Binds: choose the first wisp, toggle zombies (round 7 with 2 zombies left), and Go Again.
- **Bow Lineups** (Der Eisendrache)
  - Practice bow shots with both the Wrath of the Ancients and the Storm Bow, starting at the death ray. You always play as Richtofen.
  - Every wisp and bonfire is lit and shows "Hit" when you hit it.
  - Optional arrow cam that follows your arrow in flight.
- **Boss Practice** (Gorod Krovi, was Boss Quote Skip) – now gives the full Gorod Krovi loadout (perks, gums, Ray Gun Mark 3, LMG, sniper, Gauntlet, Dragon Strike, shield) and starts on round 14.
- Luisete added to Misc > Credits.

### Changes
- **Binds:** Action 3 is now ADS + Reload / F7 and Action 4 is ADS + Jump / F8. Save / Load Position moved to Numpad 1 / Numpad 2.
- **SOE Infinite Beast** – also opens every door, turns on every power box, gives all perks and unlocks Pack-a-Punch.
- **SOE Flags Practice** – reworked:
  - Puts you right next to the flag with it already spawned, on a fresh round 8.
  - You start with Dead of Nuclear Winter, with the other 4 gums left in the cycle.
  - Revolver, AR and Dagon's Glare.
  - Special rounds work like the base game.
- **SOE Soft Patch** – round 6 is now always a bug round, even if you shoot the Shadowman.
- **Wisp 2 Practice:**
  - Anywhere But Here is the next gum out of the machine.
  - The next wisp is ready when you return from the past.
  - The safe code monitors work.
  - You're holding the Storm Bow when you come back.
- **Keeper Practice** – added a round timer and a Keeper timer (from placing the gold rod until the keeper is done). You're holding the Storm Bow when you come back.
- **Lockdown Practice:**
  - Starts with an unused Anywhere But Here, and all 5 gums are in the cycle.
  - You spawn in front of the Hatchery gum machine.
  - Added a round timer.
  - The generator is already on, so you can go straight into the valve step.
  - A valve list (top right) shows each valve's number and where the password cylinder is. The green valve is left for you to find. Input the valves into your solver; this setup is only for practicing the segment and won't continue the Easter egg.
- Removed Lightning Bow Shots (replaced by Bow Lineups).
- Updated patch credits.
- Small performance improvements.

### Fixes
- Fixed Player Options and Zombie Options buttons sometimes doing nothing.
- Fixed the SOE upgraded sword not counting for the Easter egg (the book and flag now appear).
- Fixed Ovums Practice killing you at Pack-a-Punch, plus similar instant deaths in other patches that teleport you.
- Fixed a crash in Wisp 2 and Keeper Practice when a charged Storm Bow shot lifted a panzer.
- The app now writes In Game commands to `log.txt`, which helps with bug reports.

### Known issues
- Charged Lightning Bow shots can still crash the game in Wisp 2 and Keeper Practice. Both patches show a warning. A rework is planned.
- In Keeper Practice, the Ragnarok piece and the gold rod sometimes won't pick up the normal way. Pressing use near them still picks them up.
