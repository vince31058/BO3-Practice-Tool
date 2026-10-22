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
