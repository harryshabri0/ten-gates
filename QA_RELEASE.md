# P12 release QA checklist

## Automated gates

- [ ] Run `tools/validate_data.gd` and resolve every data error.
- [ ] Run `tools/balance_sim.gd`; archive `reports/balance_sim_results.csv` and review `reports/balance_sim_report.md`.
- [ ] Re-run the simulator whenever tower, enemy, boss, wave, or difficulty data changes.
- [ ] Keep each level/mode result near the PRD target: Easy 90% (boss 80%), Normal 65% (boss 50%), Hard 35% (boss 20%).

## Android release gates

- [ ] Create a private release keystore outside this repository and store its password in a password manager or CI secret store.
- [ ] In Godot's Android export preset, enter the local keystore password. The path and intended alias are documented in `RELEASE_SIGNING.md`; do not commit credentials.
- [ ] Export a signed AAB, upload it to an internal Play testing track, then install the generated APK on-device for smoke testing.
- [ ] Verify launcher icon and splash on a physical device.
- [ ] Test one 2-3 GB RAM phone and one high-end phone: 200 Swarmlings at 3x, Void boss clones, and 12 active fire zones.
- [ ] Verify 60 FPS or stable 30 FPS in battery saver, level load below 2 seconds, autosave after backgrounding/screen lock, and no crash after returning.
- [ ] Confirm APK is below 120 MB, landscape orientation is locked, and release signing identity matches the Play Console application.

## Campaign acceptance

- [ ] All 100 levels are present and playable in Easy, Normal, and Hard.
- [ ] Stars, Skill Points, difficulty rewards, save migration, and resume snapshots are verified.
- [ ] Each boss telegraph is readable before damage or disruption occurs.
- [ ] Credits and asset licences are complete before external distribution.
