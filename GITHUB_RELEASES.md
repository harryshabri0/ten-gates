# GitHub Releases and in-game updates

Ten Gates checks the public GitHub Releases API when it starts. If a release tag is newer than the installed game version and contains `TenGates.apk`, the game shows an **UPDATE** button. The button opens the APK download; Android then asks the player to approve the installation. Android does not allow an app to silently replace itself.

## Enable after the repository is published

1. Create or publish the repository as `OWNER/ten-gates`.
2. In `data/app_update.json`, set `enabled` to `true` and set `github_repo` to `OWNER/ten-gates`.
3. Increase both `config/version` in `project.godot` and `version/name` in `export_presets.cfg` for every release.
4. Export a signed release APK named `TenGates.apk`.
5. Create a public GitHub Release with a tag such as `v1.0.1`, then attach `TenGates.apk`.

Do not commit the signing `.p12` file or its password. The debug APK is suitable for testing only; publish a signed release APK for players.
