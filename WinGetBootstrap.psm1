<#
.SYNOPSIS
    Bootstraps the NuGet provider for PowerShell package management.
.DESCRIPTION
    Ensures TLS 1.2 is enabled, installs or updates the NuGet PackageProvider,
    and imports it for use in PowerShell.
.EXAMPLE
    Install-NuGetProvider -Verbose
#>
function Install-NuGetProvider {
    [CmdletBinding()]
    param ()

    Begin {
        # Stop on critical errors
        $ErrorActionPreference = 'Stop'
        Write-Verbose 'Starting Install-NuGetProvider.'

        # Enforce TLS 1.2
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Write-Verbose 'Ensured TLS 1.2 for secure downloads.'
        } catch {
            Write-Warning "Could not enforce TLS 1.2: $_"
        }
    }

    Process {
        # Check for existing NuGet provider
        try {
            Write-Verbose 'Checking for existing NuGet provider...'
            $prov = Get-PackageProvider -Name NuGet -ErrorAction Stop
            Write-Verbose "NuGet provider found (v$($prov.Version))."
        } catch {
            Write-Warning 'NuGet provider not found — installing now.'
            try {
                Install-PackageProvider -Name NuGet -ForceBootstrap -Scope AllUsers -ErrorAction Stop -Verbose
                Write-Verbose 'NuGet provider installed successfully.'
            } catch {
                Write-Warning "Initial Install-PackageProvider failed: $_"
                Write-Verbose 'Attempting remediation by updating PowerShellGet & PackageManagement modules.'
                try {
                    Install-Module -Name PowerShellGet,PackageManagement -Scope AllUsers -Force -AllowClobber -ErrorAction Stop -Verbose
                    Write-Verbose 'Updated PowerShellGet & PackageManagement modules.'
                    Install-PackageProvider -Name NuGet -ForceBootstrap -Scope AllUsers -ErrorAction Stop -Verbose
                    Write-Verbose 'NuGet provider installed after remediation.'
                } catch {
                    Write-Error "Failed to install NuGet provider after remediation: $_"
                    throw
                }
            }
        }

        # Import the provider
        try {
            Write-Verbose 'Importing NuGet package provider...'
            Import-PackageProvider -Name NuGet -Force -ErrorAction Stop -Verbose
            Write-Verbose 'NuGet provider imported.'
        } catch {
            Write-Error "Import-PackageProvider failed: $_"
            throw
        }
    }

    End {
        Write-Verbose 'Install-NuGetProvider completed.'
    }
}

<#
.SYNOPSIS
    Installs and repairs the Microsoft.WinGet.Client module.
.DESCRIPTION
    Uses Install-NuGetProvider to ensure package management is ready,
    installs or updates the WinGet PowerShell module, imports it,
    and then repairs the underlying WinGet package manager.
.EXAMPLE
    Install-WinGetModule -Verbose
#>
function Install-WinGetModule {
    [CmdletBinding()]
    param ()

    Begin {
        $ErrorActionPreference = 'Stop'
        Write-Verbose 'Starting Install-WinGetModule.'
    }

    Process {
        # Ensure NuGet provider is available
        Write-Verbose 'Ensuring NuGet provider is available...'
        Install-NuGetProvider

        # Install or verify WinGet module
        try {
            Write-Verbose 'Checking for existing Microsoft.WinGet.Client module...'
            $mod = Get-Module -ListAvailable -Name Microsoft.WinGet.Client -ErrorAction Stop
            Write-Verbose "WinGet module found (v$($mod.Version))."
        } catch {
            Write-Warning 'WinGet module not found — installing now.'
            try {
                Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers -Force -AllowClobber -ErrorAction Stop -Verbose
                Write-Verbose 'WinGet module installed successfully.'
            } catch {
                Write-Error "Install-Module Microsoft.WinGet.Client failed: $_"
                throw
            }
        }

        # Import the module
        try {
            Write-Verbose 'Importing Microsoft.WinGet.Client module...'
            Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop -Verbose
            Write-Verbose 'Microsoft.WinGet.Client module imported.'
        } catch {
            Write-Error "Import-Module Microsoft.WinGet.Client failed: $_"
            throw
        }

        # Repair WinGet package manager
        try {
            Write-Verbose 'Repairing WinGet package manager...'
            Repair-WinGetPackageManager -AllUsers -Force -Latest -ErrorAction Stop -Verbose
            Write-Verbose 'WinGet package manager repair completed.'
        } catch {
            Write-Warning "Repair-WinGetPackageManager encountered an issue: $_"
        }
    }

    End {
        Write-Verbose 'Install-WinGetModule completed.'
    }
}

# Export the public functions
Export-ModuleMember -Function Install-NuGetProvider, Install-WinGetModule
