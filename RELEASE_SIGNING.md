# Android release signing

The Android release preset references the local PKCS#12 keystore at:

`C:/Users/Harry Shabri/Documents/Ten Gates Signing/ten_gates_release.p12`

The verified alias is `te-58f47353-a2de-4a18-aff6-3d11361b9391`. The password is deliberately not stored in this repository or in `export_presets.cfg`.

Before exporting, open **Project > Export > Android Release** in Godot and enter the keystore password in the local export preset. If the alias is rejected, inspect the local keystore with `keytool -list -keystore <path>` after Java is installed, then update the local alias field. Back up the keystore and its password manager entry before publishing: losing either prevents future updates to the same Android application.
