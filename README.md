# WinGetBootstrap

[![Language: PowerShell](https://img.shields.io/badge/language-PowerShell-blue.svg)](https://docs.microsoft.com/powershell/)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-%5E5.1%20%7C%20%5E7-blue.svg)](https://docs.microsoft.com/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight PowerShell module to **bootstrap the NuGet provider** and **install/repair the Microsoft.WinGet.Client** module on Windows systems.

## Features

* **Install-NuGetProvider**: Ensures TLS 1.2, installs or updates the NuGet PackageProvider, and imports it.
* **Install-WinGetModule**: Uses the NuGet provider to install or update the WinGet PowerShell module, imports it, and repairs the underlying WinGet package manager.

## Requirements

* **PowerShell 5.1+** (Windows PowerShell) or **PowerShell 7+** (PowerShell Core)
* **Administrative privileges** to install modules and package providers
* **Internet connectivity** for module downloads

## Installation

Since this module is not published to PSGallery, install it directly from GitHub:

1. **Clone the repository**

   ```powershell
   git clone https://github.com/yourrepo/WinGetBootstrap.git
   ```

2. **Copy the module folder** to one of your PowerShell module paths:

   * **All users:**

     ```powershell
     Copy-Item -Path .\WinGetBootstrap -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Recurse -Force
     ```
   * **Current user only:**

     ```powershell
     Copy-Item -Path .\WinGetBootstrap -Destination "$HOME\Documents\WindowsPowerShell\Modules" -Recurse -Force
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

## Contributing

Contributions, issues, and feature requests are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch: `git checkout -b feature/my-new-feature`.
3. Commit your changes: `git commit -am 'Add some feature'`.
4. Push to the branch: `git push origin feature/my-new-feature`.
5. Open a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE).
