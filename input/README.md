# input

Put each app in its own folder here, for example:

```
input\
  7-Zip\
    7z2408-x64.msi
  Notepad++\
    npp.8.7.Installer.x64.exe
```

Then double-click `Start-Packaging.bat` in the repo root. Each folder is packaged into `output\<folder name>.intunewin`.

Everything in an app's folder goes into its package, so keep only that app's setup files there. See [Packaging apps with Build-IntuneWin](../README.md#packaging-apps-with-build-intunewin) for how the setup file is picked.

Nothing in this folder except this README is committed to git.
