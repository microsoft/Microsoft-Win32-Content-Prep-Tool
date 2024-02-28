# Microsoft Win32 Content Prep Tool

Manage Windows Apps (.intunewin) with Intune

[Version 1.8.6](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases/tag/v1.8.6)

[See release notes for more information.](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/releases)

Use the Microsoft Win32 Content Prep Tool to pre-process Windows Classic apps. The packaging tool converts application installation files into the .intunewin format. The packaging tool also detects the parameters required by Intune to determine the application installation state. After you use this tool on your apps, you will be able to upload and assign the apps in the Microsoft Intune console.

**Prerequisites**

.NET Framework 4.7.2

Before you install and use the Microsoft Win32 Content Prep Tool, you **must**:

- Review the [Microsoft License Terms for Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/blob/master/Microsoft%20License%20Terms%20For%20Win32%20Content%20Prep%20Tool.pdf). Print and retain a copy of the license terms for your records. By downloading and using Microsoft Win32 Content Prep Tool, you agree to such license terms. If you do not accept them, do not use the software.
- Review the [Privacy and personal data in Intune](https://learn.microsoft.com/mem/intune/protect/privacy-personal-data) for information on the privacy policy of the Microsoft Win32 Content Prep Tool.

Sample commands to use for the Microsoft Win32 Content Prep Tool:

- IntuneWinAppUtil -v
  - This will show the tool version (Only available starting version 1.8.2).
- IntuneWinAppUtil -h
  - This will show usage information for the tool.
- IntuneWinAppUtil -c <setup_folder> -s <source_setup_file> -o <output_folder> <-q>
  - This will generate the .intunewin file from the specified source folder and setup file.
  - For MSI setup file, this tool will retrieve required information for Intune.
  - If -a is specified, all catalog files in that folder will be bundled into the .intunewin file.
  - If -q is specified, it will be in quiet mode. If the output file already exists, it will be overwritten.
  - Also, if the output folder does not exist, it will be created automatically.
- IntuneWinAppUtil
  - If no parameter is specified, this tool will guide you to input the required parameters step by step.

Command-line parameters available

- -h Help
- -v Tool version (Only available starting version 1.8.2).
- -c <setup_folder> Setup folder for all setup files. All files in this folder will be compressed into .intunewin file.
  - Only the setup files for this app should be in this folder.
- -s <setup_file> Setup file (e.g. setup.exe or setup.msi).
- -o <output_file> Output folder for the generated .intunewin file.
- -a <catalog_folder> Catalog folder for all catalog files. All files in this folder will be treated as catalog file for Win10 S mode.

**Note: The generated .intunewin file contains all compressed and encrypted source setup files and the encryption information to decrypt it. Please keep it in the safe place as your source setup files.**
