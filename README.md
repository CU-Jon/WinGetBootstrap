# WinGetBootstrap

[![Language: PowerShell](https://img.shields.io/badge/language-PowerShell-blue.svg)](https://docs.microsoft.com/powershell/)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-%5E5.1%20%7C%20%5E7-blue.svg)](https://docs.microsoft.com/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight PowerShell module to **bootstrap the NuGet provider** and **install/repair the Microsoft.WinGet.Client** module on Windows systems.  
This module is especially useful for installing WinGet on server-based operating systems, or for leveraging WinGet during Microsoft Endpoint Configuration Manager task sequences, since the SYSTEM account that task sequences run under doesn't have access to a working version of WinGet out-of-the-box. Although untested, this should also assist with deploying WinGet apps via Intune.

## Features

* **Install-NuGetProvider**: Ensures TLS 1.2, installs or updates the NuGet PackageProvider, and imports it.
* **Install-WinGetModule**: Uses the NuGet provider to install or update the WinGet PowerShell module, imports it, and installs/repairs the underlying WinGet package manager. If the NuGet provider is unavailable, this will install/update the provider before proceeding.

## Requirements

* **PowerShell 5.1+** (Windows PowerShell) or **PowerShell 7+** (PowerShell Core)
* **Administrative privileges** to install modules and package providers
* **Internet connectivity** for module downloads

## Installation

Since this module is not published to PSGallery, install it directly from GitHub:

1. **Clone the repository**

   ```
   git clone https://github.com/CU-Jon/WinGetBootstrap.git
   ```

2. **Copy the module folder** to one of your PowerShell module paths:

   * **All users:**

     ```powershell
     Copy-Item -Path .\WinGetBootstrap -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Recurse -Force
     ```
   * **Current user only:**

     ```powershell
     Copy-Item -Path .\WinGetBootstrap -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules" -Recurse -Force
     ```

3. **(Optional) Import directly** from the cloned location without copying:

   ```powershell
   Import-Module .\WinGetBootstrap\WinGetBootstrap.psm1
   ```

4. **Verify installation**:

   ```powershell
   Get-Module -ListAvailable WinGetBootstrap
   ```

## Usage

Import the module and call the functions:

```powershell
Import-Module WinGetBootstrap

# 1) Bootstrap NuGet provider
Install-NuGetProvider -Verbose

# 2) Install (or repair) the WinGet module and engine
Install-WinGetModule -Verbose
```

Both functions are **advanced** cmdlets and support common parameters like `-Verbose`, `-Debug`, and `-WhatIf`.

### Function Details

| Function                  | Description                                                              |
| ------------------------- | ------------------------------------------------------------------------ |
| **Install-NuGetProvider** | Ensures TLS 1.2 is enabled, installs/updates NuGet provider, imports it. |
| **Install-WinGetModule**  | Installs/imports `Microsoft.WinGet.Client` module and repairs WinGet.    |

## Examples

```powershell
# Ensure package management is ready
Install-NuGetProvider -Verbose

# Install or repair WinGet module
Install-WinGetModule -Verbose
```

---

## Example Scripts

### [`Examples/Invoke-Bootstrap.ps1`](Examples/Invoke-Bootstrap.ps1)

This script imports the `WinGetBootstrap` module and runs `Install-WinGetModule` with error handling and optional progress reporting.  
It is useful for automating the full WinGet bootstrap process in a deployment or provisioning scenario.

**Parameters:**

- `-ModulePath <string>`  
  Optional. Path to the `WinGetBootstrap.psm1` file. If not specified, the script will auto-detect the module location relative to itself.

- `-ProgressPreference <string>`  
  Optional. Sets `$ProgressPreference` for the session. Accepts: `SilentlyContinue`, `Continue`, `Inquire`, `Break`, `Stop`.  
  Default: `SilentlyContinue`.

**Example usage:**
```powershell
# Run with default options
.\Examples\Invoke-Bootstrap.ps1

# Specify a custom module path and show progress
.\Examples\Invoke-Bootstrap.ps1 -ModulePath 'C:\Modules\WinGetBootstrap.psm1' -ProgressPreference Continue -Verbose
```

---

### [`Examples/Install-WinGetPackage.ps1`](Examples/Install-WinGetPackage.ps1)

This script installs a package using the `Microsoft.WinGet.Client` PowerShell module.  
It checks for the module, imports it, and then calls `Install-WinGetPackage` with the provided parameters.

**Parameters:**

- `-Name <string>`  
  The name of the package to install (mutually exclusive with `-Id`).

- `-Id <string>`  
  The package ID to install (mutually exclusive with `-Name`).

- `-Override <string>`  
  Optional. Passes an override string to the installer.

- `-Scope <string>`  
  Optional. Installation scope. Accepts: `System`, `User`, `Any`, `SystemOrUnknown`, `UserOrUnknown`.  
  Default: `SystemOrUnknown`.

- `-Mode <string>`  
  Optional. Installation mode. Accepts: `Default`, `Interactive`, `Silent`.  
  Default: `Default`.

- `-Force`  
  Optional. Forces installation even if the package is already installed.

- `-AllowHashMismatch`  
  Optional. Allows installation even if the hash does not match.

- `-Source <string>`  
  Optional. The package source. Default: `winget`.

- `-ProgressPreference <string>`  
  Optional. Sets `$ProgressPreference` for the session. Accepts: `SilentlyContinue`, `Continue`, `Inquire`, `Break`, `Stop`.  
  Default: `SilentlyContinue`.

**Usage examples:**
```powershell
# Install by name
.\Examples\Install-WinGetPackage.ps1 -Name '7zip.7zip' -Verbose

# Install by ID, silently, for all users
.\Examples\Install-WinGetPackage.ps1 -Id 'Microsoft.Edge' -Mode Silent -Scope System -Verbose

# Install with an override and allow hash mismatch
.\Examples\Install-WinGetPackage.ps1 -Name 'SomeApp' -Override '/S' -AllowHashMismatch
```

**Notes:**
- You must specify either `-Name` or `-Id`, but not both.
- The script will error if the `Microsoft.WinGet.Client` module is not installed.
- All parameters are optional except for `-Name` or `-Id`.

---

## Contributing

Contributions, issues, and feature requests are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch: `git checkout -b feature/my-new-feature`.
3. Commit your changes: `git commit -am 'Add some feature'`.
4. Push to the branch: `git push origin feature/my-new-feature`.
5. Open a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE).
