# GitHub Releases and in-game updates

Ten Gates checks the public GitHub Releases API when it starts. If a release tag is newer than the installed game version and contains `TenGates.apk`, the game shows an **UPDATE** button. The button opens the APK download; Android then asks the player to approve the installation. Android does not allow an app to silently replace itself.

## Enable after the repository is published

1. Publish the repository as `harryshabri0/ten-gates`.
2. The included `data/app_update.json` is already configured with `enabled` set to `true` and `github_repo` set to `harryshabri0/ten-gates`.
3. Increase both `config/version` in `project.godot` and `version/name` in `export_presets.cfg` for every release.
4. Export a signed release APK named `TenGates.apk`.
5. Create a public GitHub Release with a tag such as `v1.0.1`, then attach `TenGates.apk`.

Do not commit the signing `.p12` file or its password. The debug APK is suitable for testing only; publish a signed release APK for players.
