# Ten Gates

Godot 4 prototype for the Android landscape tower-defense game described in the PRD. It currently contains P0-P12: core gameplay, campaign content, performance profiles, and a headless balance-simulation workflow.

## Fantasy asset pass

- Terrain, towers, decorative props, and projectile fire now use selected files from Tiny Swords Free Pack.
- Enemy and boss circles have been replaced with CC0 fantasy sprite variants: goblins, orcs, mages, undead, demons, slimes, minotaurs, yeti, and dragons.
- The two-family visual policy, original source links, and current licence notes live in [ASSET_STRATEGY.md](ASSET_STRATEGY.md), [CREDITS.md](CREDITS.md), and [assets_license.csv](assets_license.csv).

## P1 prototype

- One hand-authored polyline path, updated by a centralized `EnemyManager` at a fixed 30 Hz.
- Spatial hash grid with 128 px cells for tower target queries.
- Pooled enemies (220 cap) and projectiles (256 cap), with no per-enemy or per-projectile `_process`.
- Archer, Cannon, and Barracks; the Cannon applies splash damage, while Barracks applies a short blocking slow.
- Gold, base HP, and a six-wave JSON level at `data/levels/world01/prototype.json`.
- Tap an empty slot, choose a tower, and use **NEXT WAVE**. The top-right **STRESS** button forces 3× speed and queues 200 Swarmlings.

For stress-test measurement, open the Debug Overlay and record its FPS and draw-call values while the 200-enemy test is active. The benchmark hides unused build-slot markers only during the stress run so the render budget measures enemy simulation rather than setup UI.

## P2 tower system

- Tower definitions for Archer, Cannon, Barracks, Ice Tower, and Arcane Tower live in `data/towers/*.json`; balance values are not hardcoded in gameplay scripts.
- Each tower has levels L1-L5, with costs `1.0 / 0.7 / 1.1 / 1.6 / 2.4 × base cost`, branch selection at L4, branch tint/overlay, and a distinct L5 recurring ability.
- Slots now demonstrate Standard, Highland, Rune, Roadside, and Locked behaviour. Highland increases range and build cost; Rune rewards elemental towers; Roadside is limited to Barracks; Locked slots cost 75 gold to open.
- Tap an empty slot for the radial build menu. Tap a placed tower for its range ring, upgrade/branch, sell, target mode, and 3-second undo controls.
- The six available target modes are First, Last, Strongest, Weakest, Fastest, and Nearest.

P2 includes lightweight movement hooks for Slow, Freeze, and Stun so the Ice and Arcane branches can be playtested. Full status stacking, duration rules, and elemental reactions are intentionally deferred to P3.

## P3 status and reactions

- `StatusSystem` processes Burn, Poison, Slow, Freeze, Stun, Mark, Armor Break, Weaken, and Root in one centralized 10 Hz tick.
- Poison stacks to five. Burn and Poison deal periodic damage; Slow/Freeze/Stun/Root change movement; Mark and Armor Break modify incoming damage.
- Elite and boss crowd control duration is reduced by 50% for each consecutive CC, with an 8-second reset window.
- Reactions: Shatter, Toxic Blast, Overload, Corrode, and Thermal Shock. Each has a per-enemy cooldown.
- Run [status_debug.tscn](scenes/game/status_debug.tscn) to spawn a target and manually trigger every status/reaction. The P0 Debug Overlay now also reports active-status count and StatusSystem tick time.

Desktop logic benchmark: running [status_bench.tscn](scenes/game/status_bench.tscn) with 120 enemies and four active statuses measured **1.484 ms per simulation tick** and **2.760 ms per status tick**. This is a development-machine result only; record the overlay values on the Android target before treating it as a device-performance result.

## P4 enemy framework

- All 24 regular enemies are defined as individual files in `data/enemies/`, with HP, speed, armor, physical/magic resistance, flying, stealth, leak weight, bounty, and ability data.
- `EnemyAbilitySystem` uses `on_spawn`, `on_timer`, `on_hit`, `on_death`, and `on_reach_tower` hooks. The implemented data hooks cover burrow/jump, healing aura, split, tower weaken, revive, stealth, bomb-on-reach, repair, EMP, carrier drop, teleport, leech, and enrage.
- Elite affixes rotate through Layered, Agile, Regenerative, Shielded, Vengeful, Hunter, and Cursed. The World 1-3 debug scene can enable elite spawning.
- Run [enemy_debug.tscn](scenes/game/enemy_debug.tscn) to spawn each World 1-3 enemy and exercise those abilities without wave data.

## P5 levels, modes, and stars

- [difficulty.json](data/difficulty.json) contains Easy, Normal, and Hard parameters. The HUD mode button cycles them; restart before beginning a wave to apply a new mode's starting gold/base HP.
- `LevelLoader` loads level JSON, while `WaveGenerator` can build World 1 waves from a point budget and templates (`intro`, `rush`, `tank`, `mixed`). Hard adds two extra waves.
- [level01.json](data/levels/world01/level01.json) through [level04.json](data/levels/world01/level04.json) provide the first four World 1 levels, each with 12 waves and a distinct star challenge.
- `StarProgress` awards one Skill Point only for each newly achieved best star count. Easy caps at two stars; Normal and Hard cap at three (the Hard crown remains a later cosmetic feature).
- Implemented modifier hooks: Fog, Gold Scarce, Tower Limited, Fast Waves, and Elite Dominant. Dual Gate and Shadow Boss remain level-data placeholders pending their dedicated map encounters.

## P6 boss framework

- `BossController` transitions phase at configured HP thresholds, drives timer/condition abilities, renders red telegraphs, and supports a Hard-only phase.
- The framework owns sub-target and map-object HP tables for future Hydra/Lich encounters without requiring boss-specific inheritance.
- [gorvak.json](data/bosses/gorvak.json) implements Gorvak's idle regeneration, Rock Throw telegraph/slot disable, Roar summon, and Hard enrage.
- [orc_chief.json](data/bosses/orc_chief.json) implements the World 1 mini-boss Charge and Grunt summon.
- Run [boss_debug.tscn](scenes/game/boss_debug.tscn) to start either encounter and force phase transitions.

## P7 spells and loadout

- [spells.json](data/spells.json) defines all six active spells: Meteor Shower, Time Freeze, Reinforcements, Overcharge, Gold Rush, and Holy Barrier. Cooldowns are adjusted by the selected difficulty.
- The lower-right spell controls show two equipped spells. Open **Loadout** to pick any two of the six; the system accepts a third slot when it is unlocked by the future Skill Tree flow.
- Meteor Shower and Reinforcements enter map-targeting mode. Time Freeze applies reduced duration to elites/bosses; Overcharge affects tower attack speed; Gold Rush multiplies bounty; Holy Barrier prevents three leaks.
- World 4+ loadout rules are handled by `LoadoutManager`: a maximum of six towers, including any mandatory borrowed tower. The Loadout panel demonstrates the World 4 roster and an automatic borrowed-tower slot.
- Run [spell_loadout_debug.tscn](scenes/game/spell_loadout_debug.tscn) for a smoke test that casts each spell path and checks the six-tower World 4 limit.

## P8 campaign, save, and skill tree

- `Campaign` models ten worlds with ten sequential levels each. A new world requires its previous boss defeated and at least 15 of that world's 30 stars; best stars across modes convert to a maximum of 300 Skill Points.
- `SaveManager` writes versioned JSON to `user://save.json`, copies the prior save to `user://save.bak`, migrates legacy shapes, persists settings/campaign/skill tree/codex/statistics, and stores a level snapshot at the start of each wave. Reloading the game restores the saved tower layout, gold, base HP, difficulty, and pending wave.
- [skilltree.json](data/skilltree.json) defines the complete 70-node, seven-branch tree. Tier I/II/III costs are 3/6/12 SP; Tier II requires World 3 plus 9 SP in its branch, Tier III requires World 6 plus 24 SP, and each branch permits one keystone. Three presets and free respec are supported.
- `StatModifierStack` provides the data-driven modifier pipeline. The currently represented tower, economy, and spell modifiers are applied when a game starts; later tower families can consume the same stack without changing persistence.
- Run [campaign_map.tscn](scenes/meta/campaign_map.tscn) for the draggable ten-gate grid and [skill_tree.tscn](scenes/meta/skill_tree.tscn) for the horizontal tree with preview, unlock, respec, and presets. Hold Shift while clicking a preset to save it; click normally to apply it.
- Run [meta_debug.tscn](scenes/meta/meta_debug.tscn) for campaign, save, and skill-tree smoke coverage.

## P9 UI/UX and polish

- The gameplay HUD now has Pause, Auto-Next, next-wave preview, difficulty, speed, spell controls, modal victory/defeat summaries, and a hold-for-0.5-second sell control.
- The Settings panel (top-right) persists graphics quality, 30/60 FPS cap, battery saver, left-handed spell controls, colorblind contrast, font scale, reduce flash, haptics, and music/SFX volume separately.
- Contextual tutorial copy appears for 1-1 through 1-3. Towers and enemies automatically enter the persisted Codex on first encounter; run [codex.tscn](scenes/meta/codex.tscn) to browse discoveries.
- Feedback includes accessibility-aware hit flash and optional haptic boss-telegraph feedback. Loss reports identify the most common leak source and offer a counter suggestion.
- Run [ui_debug.tscn](scenes/ui/ui_debug.tscn) for UI smoke coverage.

## P10 - World 2: Sunscar Desert

- Four playable data layouts live in `data/layouts/world02/`: Layout A (2-1 to 2-3), B (2-4 to 2-6), C (2-7 to 2-9), and the Khepri boss arena (2-10). Oasis slots are Rune slots for Ice and Arcane towers.
- `WorldRuleController` reads `world_rule` from the level data. The Sunscar sandstorm runs every 30 seconds for 8 seconds and reduces all tower range by 25%.
- World 2 has ten levels in `data/levels/world02/`, with Fog, Gold Scarce, Tower Limited, and Fast Waves assigned to 2-6 through 2-9. Level 2-5 calls Ratu Scarab; 2-10 calls Khepri.
- Bats are flying targets; Scarabs retain 60% physical resistance; Diggers burrow for 3 seconds then jump 10% of the path. Cannon and Barracks now read their ground-only targeting from tower data, so Bats demonstrate the intended counter choice.
- Ratu Scarab has 70 armor and summons Scarabs every 6 seconds. Khepri dives every 20 seconds, then adds personal sandstorms and worms across its phases; Hard repeats dive more often.
- `tools/validate_data.gd` passed all ten level files, four layouts, and both boss definitions. `tools/world02_balance_smoke.gd` produced a preliminary heuristic 100% rate for Easy/Normal/Hard (10/10 each), which is well above the PRD's target rates (90%/65%/35%). Treat that as a tuning warning, not a playtest result; the P12 full battle simulator and device playtests should increase late-wave pressure before release.
- Run [world02_debug.tscn](scenes/game/world02_debug.tscn) to load 2-1 through `GameController` and verify the sandstorm cycle.

## P10 - World 3: Poison Swamp

- Four World 3 layouts live in `data/layouts/world03/`, with layouts A/B/C and Mother Hydra's arena assigned to 3-1..3-10.
- `WorldRuleController` now supports the swamp bridge rule from level data: mud applies a 0.80 enemy-speed multiplier, and the **BRIDGE LEVER** switches to the alternate route with a 20-second cooldown.
- Lab Racun and Menara Tesla are data-driven World 3 towers. Poison Lab applies Poison (and Armor Break on its Acid branch); Tesla chains magic damage and short stun through nearby targets.
- Shaman Rawa, Splitter Spora, and Spitter Racun are used across all ten World 3 levels. 3-5 starts Penyihir Rawa, while 3-10 starts Mother Hydra with three data-defined sub-target heads and poison-cloud phases.
- Fog, Gold Scarce, Tower Limited, and Elite Dominant cover 3-6 through 3-9. The shared validator now passes Worlds 2-3: 20 levels, 8 layouts, and 4 boss definitions.
- The World 3 heuristic balance smoke check reports 100% for Easy/Normal/Hard (10/10 each), again above the PRD targets. This is only a no-render pressure estimate; increase late-wave pressure after P12's battle simulator/device playtests.
- Run [world03_debug.tscn](scenes/game/world03_debug.tscn) to load 3-1, validate the mud multiplier, and operate the bridge lever.

## P10 - World 4: Ice Peaks

- Four `ice_peak` layouts provide the A/B/C progression and Glacier Titan arena. Each includes snow-covered Locked slots that use the existing gold unlock flow.
- The data-driven `ice_slippery` rule applies a 1.30 enemy speed multiplier to World 4 levels.
- Skyfang is an air-only anti-air tower; Menara Koin skips attacking and produces gold at every completed wave. Both have two data-defined branches and L1-L5 values.
- Ice Wolf and Ice Knight form World 4's enemy pressure. 4-5 triggers Penjaga Es; 4-10 triggers Glacier Titan, including Frostbite tower weaken and Avalanche telegraphs.
- World 4 contains Fog, Gold Scarce, Tower Limited, and Fast Waves on levels 4-6 through 4-9. The shared validator passes Worlds 2-4: 30 levels, 12 layouts, and 6 bosses.
- World 4's no-render estimate is 100% in Easy/Normal/Hard (10/10 each), so late-wave pressure remains a required P12 tuning task rather than a released balance claim.
- Run [world04_debug.tscn](scenes/game/world04_debug.tscn) to load 4-1, verify ice speed, and inspect snow-locked slots.

## P10 - World 5: Forgotten Graveyard

- Four `forgotten_graveyard` layouts provide the A/B/C progression and Morthal arena across 5-1 through 5-10. The day/night rule begins in daylight: Fire and Holy towers receive 20% damage; every 20 seconds it shifts to night, when active enemies regenerate 1% of maximum HP per second.
- Balista is the World 5 single-target tower with Penetrator and Harpoon branches. Wraiths retain 80% physical resistance and take normal magic damage, while Akolit Nekro resurrects a recently defeated nearby enemy at 30% HP every eight seconds.
- 5-5 triggers Bone Colossus, which returns once at 40% HP. 5-10 triggers Morthal: its three spawned phylactery pillars make the boss untargetable until they are destroyed; it revives up to five nearby corpses every 15 seconds and uses a 3-second area Death Nova in phase three.
- Fog, Gold Scarce, Tower Limited, and Elite Dominant cover 5-6 through 5-9. The shared validator passes Worlds 2-5: 40 levels, 16 layouts, and 8 boss definitions.
- World 5's no-render estimate is 100%/100%/40% in Easy/Normal/Hard. It is only a coarse pressure estimate, so P12 battle simulation and device playtests still need to tune it against the PRD targets (90%/65%/35%).
- Run [world05_debug.tscn](scenes/game/world05_debug.tscn) to load 5-1, switch the day/night cycle, and verify the World 5 tower data.

## P10 - World 6: Volcano

- Four `volcano` layouts provide the A/B/C progression and Ignis arena. Every level configures the map's 45-second eruption from level data: two marked slots become red and disabled for 6 seconds, while lava temporarily redirects enemies over the alternate path.
- Menara Api is a short-range multi-target fire tower that applies Burn. Inferno Beam/Sunfire favor escalating damage, while Napalm/Hellfire widen the burning area. Golem Magma is immune to Burn and applies its heat aura; Penyelinap is stealthy; Imp Pengebom disables a nearby tower on reaching the base.
- 6-5 triggers Brute Lahar. 6-10 triggers Ignis: 90 starting armor represents three plates, each 25% HP threshold removes 30 armor and telegraphs a lava burst; Lava Rain cuts the nearest marked tower's damage by 50% for 8 seconds; at 20% HP Ignis gains 40% speed and Burn immunity.
- Fog, Gold Scarce, Tower Limited, and Fast Waves cover 6-6 through 6-9. The shared validator now covers Worlds 2-6: 50 levels, 20 layouts, and 10 boss definitions.
- The World 6 no-render pressure estimate is 100%/100%/50% in Easy/Normal/Hard. It remains a preliminary signal only; P12 simulation and device playtests must tune it toward the PRD targets (90%/65%/35%).
- Run [world06_debug.tscn](scenes/game/world06_debug.tscn) to validate the eruption route, marked-slot duration, Fire Tower loading, and the first Ignis armor plate.

## P10 - World 7: Clockwork City

- Four `clockwork_city` layouts provide A/B/C progression and the Overseer arena. The **CONVEYOR GATE** switches between a short route that moves enemies at 120% speed and a long route that moves them at 80%, with a 20-second cooldown.
- Bengkel Mekanik has Minefield and Turret Foundry branches. Minefield performs an area detonation with stun; Turret Foundry fires paired projectiles. Prajurit Mesin repairs when idle, Swarm Drone is flying and emits EMP, while Tesla Bot is stun-immune and magic-resistant.
- 7-5 triggers Siege Walker, whose shot disables the farthest built tower for 5 seconds. 7-10 triggers Overseer Automaton with a 2-second EMP telegraph, Repair Bots that heal nearby units, air-drone summons, and phase-three minion Overclock.
- Fog, Gold Scarce, Tower Limited, and Elite Dominant cover 7-6 through 7-9. The shared validator now covers Worlds 2-7: 60 levels, 24 layouts, and 12 boss definitions.
- The World 7 no-render pressure estimate is 100%/90%/30% in Easy/Normal/Hard. It is only a coarse signal; P12 battle simulation and device playtests must confirm tuning against the PRD targets (90%/65%/35%).
- Run [world07_debug.tscn](scenes/game/world07_debug.tscn) to check conveyor route/speed switching, workshop loading, and Overseer spawning.

## P10 - World 8: Sky Islands

- Four `sky_islands` layouts provide A/B/C progression and Zephyra's arena. Air enemies move 20% faster; every third wave, level-data offsets move the build islands and any towers placed on them.
- Totem Perang now applies data-defined range and attack-speed auras. War Drum emphasizes attack speed; Oracle extends range and reveals stealth enemies within its aura.
- Sky Carrier drops three ground units, while Matron Harpy uses Gust to speed active enemies. 8-10 triggers Zephyra: it initially accepts only anti-air targeting, disables three towers with Lightning Strike, Gusts enemies forward, then dive-bombs to become ground-targetable for six seconds while disabling one tower for 20 seconds.
- Fog, Gold Scarce, Tower Limited, and Fast Waves cover 8-6 through 8-9. The shared validator now covers Worlds 2-8: 70 levels, 28 layouts, and 14 boss definitions.
- The World 8 no-render pressure estimate is 100%/90%/30% in Easy/Normal/Hard. This remains a coarse signal; P12 battle simulation and device playtests must confirm tuning against the PRD targets (90%/65%/35%).
- Run [world08_debug.tscn](scenes/game/world08_debug.tscn) to check air wind, three-wave island movement, Totem loading, and Zephyra's anti-air state.

## P10 - World 9: Void Rift

- Four `void_rift` layouts provide A/B/C progression and Eclipse Weaver's arena. Portal-pair data moves every three waves; crossing a portal advances an enemy to its paired exit once per spawn.
- Menara Void supplies Singularity area slow/damage and Rift Gate's 15% backward displacement for non-boss enemies. Void Walker teleports forward every five seconds, while Void Leech disables the nearest Totem aura for six seconds.
- 9-5 triggers Bayangan Cermin, which spawns three illusions. 9-10 triggers Eclipse Weaver with clone summons, a 15-second path teleport, and a phase-three Gravity Well telegraph.
- Fog, Gold Scarce, Tower Limited, and Elite Dominant cover 9-6 through 9-9. The shared validator now covers Worlds 2-9: 80 levels, 32 layouts, and 16 boss definitions.
- The World 9 no-render pressure estimate is 100%/40%/20% in Easy/Normal/Hard. This is below the PRD's Normal target, so P12 battle simulation and device playtests must retune pressure before release.
- Run [world09_debug.tscn](scenes/game/world09_debug.tscn) to check portal-pair rotation, Void Tower loading, and Eclipse Weaver spawning.

## P10 - World 10: Demon Citadel

- Four `demon_citadel` layouts complete the campaign. Levels 10-1 through 10-9 remix the established desert, swamp, ice, graveyard, volcano, clockwork, sky-island, and void map rules; 10-10 is the final arena.
- Iblis Berserker accelerates whenever allied enemies die. The final roster mixes the strongest previous-world enemies to require a complete tower loadout.
- Dread Sovereign has four normal phases plus a Hard-only final pressure phase: elite Berserker summons, three Dread Echoes, area Death Nova, and a low-health enrage/resurrection sequence.
- The shared validator now covers Worlds 2-10: 90 levels, 36 layouts, and 17 boss definitions. Run [world10_debug.tscn](scenes/game/world10_debug.tscn) to verify the remix level and final boss spawn.
- The World 10 no-render pressure estimate is 100%/70%/20% in Easy/Normal/Hard. Hard is still below the PRD target, requiring P12 battle simulation and device-tuning before release.

## P11 - Performance pass

- The pooled enemy stress capacity is now 220, enabling the PRD's 200-Swarmling stress run at 3× speed. Projectiles are pooled at 256.
- Quality settings are now functional: High renders every enemy/projectile; Medium renders every second visual; Low renders every third enemy and every fourth projectile, while disabling hit flashes and boss shake. Simulation, collision, and game rules remain unchanged at all quality levels.
- Desktop smoke coverage confirms 200 simultaneous active enemies and quality-profile changes. Run [performance_debug.tscn](scenes/game/performance_debug.tscn). Android before/after FPS, draw calls, thermal behavior, and the Void-clone/fire-zone scenarios still require measurement on a representative physical device.

| P11 check | Before | After |
| --- | --- | --- |
| Stress capacity | 120 enemies | 220 pooled enemies; 200-enemy stress run |
| Enemy visuals (Low) | All active enemies drawn | One in three enemies drawn |
| Projectile visuals (Low) | All active projectiles drawn | One in four projectiles drawn |
| Hit/telegraph feedback (Low) | Always rendered | Flash and shake omitted |

## P12 - Balance simulator and release preparation

- Run `Godot --headless --path . -s res://tools/balance_sim.gd` to execute 10 deterministic seeds for each of three fixed strategies, across every available level and all three difficulty modes.
- The tool writes per-run data to `reports/balance_sim_results.csv` (win, remaining base HP, duration, loss wave, seed) and a PRD-target comparison with concrete data-file recommendations to `reports/balance_sim_report.md`.
- Android release preparation includes `export_presets.cfg`, launcher/boot-splash art in `assets/release/`, licence records, and [QA_RELEASE.md](QA_RELEASE.md). Keep release-keystore credentials outside the repository; this machine has no Android build tools configured and therefore cannot produce a signed AAB yet.

## Run in the editor

1. Install Godot 4.3 or newer with Android build support.
2. Import this folder by opening `project.godot` in Godot.
3. Press F6/F5. The P0 screen should show the title and the debug metrics panel.
4. On desktop, left-click simulates a tap. On Android, use tap, drag, and pinch; the input controller emits signals for the later camera/gameplay systems.

## Android debug export

The current playable debug build is written to `build/TenGates-debug.apk`. It is signed with Godot's debug certificate and is suitable for direct installation on an Android device, not Play Store distribution.

1. In Godot, install Android export templates via **Editor > Manage Export Templates**.
2. Install Android Studio, its Android SDK Platform 35 or newer, Build-Tools, Platform-Tools, and the OpenJDK version supported by your Godot release.
3. In **Editor > Editor Settings > Export > Android**, set the Android SDK path and Java SDK path. Godot should show both paths as valid.
4. In **Project > Export**, add an **Android** preset. Keep the debug export setting enabled. The project is configured for landscape, a 1920×1080 base viewport, `canvas_items` stretch mode, and the Mobile renderer.
5. Connect an Android 8+ device, enable Developer options and USB debugging, then approve the computer’s RSA prompt on the device.
6. Select the device in Godot’s run target menu and press F6/F5, or use **Project > Export > Android > Export Project** to create a debug APK.

Godot uses its debug keystore automatically for debug builds. Do not use a release keystore until P12.

## P0 validation checklist

- Project opens without parser errors.
- Title screen is landscape at the expected aspect ratio.
- Debug Overlay shows FPS, enemies, projectiles, and draw calls.
- Taps, drags, and pinch gestures reach `EventBus`.
- Android debug build installs and launches on a physical device.

