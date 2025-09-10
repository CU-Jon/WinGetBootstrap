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
        # Forward -Verbose to everything we run in this scope
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            $PSDefaultParameterValues['*:Verbose'] = $true   # turns verbose on
        }

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
            $prov = Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction Stop
            Write-Verbose "NuGet provider found (v$($prov.Version))."
        } catch {
            Write-Warning 'NuGet provider not found, installing now.'
            try {
                Install-PackageProvider -Name NuGet -ForceBootstrap -Scope AllUsers -Force -Confirm:$false -ErrorAction Stop
                Write-Verbose 'NuGet provider installed successfully.'
            } catch {
                Write-Warning "Initial Install-PackageProvider failed: $_"
                Write-Verbose 'Attempting remediation by updating PowerShellGet & PackageManagement modules.'
                try {
                    Install-Module -Name PowerShellGet,PackageManagement -Scope AllUsers -Force -AllowClobber -Confirm:$false -ErrorAction Stop
                    Write-Verbose 'Updated PowerShellGet & PackageManagement modules.'
                    Install-PackageProvider -Name NuGet -ForceBootstrap -Scope AllUsers -Force -Confirm:$false -ErrorAction Stop
                    Write-Verbose 'NuGet provider installed after remediation.'
                } catch {
                    Write-Error "Failed to install NuGet provider after remediation: $_"
                    throw $_
                }
            }
        }

        # Import the provider
        try {
            Write-Verbose 'Importing NuGet package provider...'
            Import-PackageProvider -Name NuGet -Force -ErrorAction Stop
            Write-Verbose 'NuGet provider imported.'
        } catch {
            Write-Error "Import-PackageProvider failed: $_"
            throw $_
        }
    }

    End {
        Write-Verbose 'Install-NuGetProvider completed.'

        # Remove the explicit -Verbose from the session, keeps the scope clean
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            $PSDefaultParameterValues.Remove('*:Verbose')   # turns verbose off
        }
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
        # Forward -Verbose to everything we run in this scope
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            $PSDefaultParameterValues['*:Verbose'] = $true   # turns verbose on
        }

        $ErrorActionPreference = 'Stop'
        Write-Verbose 'Starting Install-WinGetModule.'
    }

    Process {
        # Ensure NuGet provider is available
        Write-Verbose 'Ensuring NuGet provider is available...'
        Install-NuGetProvider

        # Ensure PSGallery repository exists and is trusted
        $psGalleryConfigured = $false
        try {
            $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if (-not $psGallery) {
                Write-Host 'PSGallery repository not found. Registering default PSGallery with trusted policy.'
                Register-PSRepository -Default -InstallationPolicy Trusted -ErrorAction Stop
                $psGalleryConfigured = $true
            } elseif ($psGallery.InstallationPolicy -ne 'Trusted') {
                Write-Host 'PSGallery repository found but not trusted. Setting installation policy to Trusted.'
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
                $psGalleryConfigured = $true
            } else {
                Write-Host 'PSGallery repository is already configured and trusted.'
                $psGalleryConfigured = $true
            }
        } catch {
            Write-Warning "Failed to configure PSGallery repository: $_. Will use direct download method."
            $psGalleryConfigured = $false
        }

        # Install or verify WinGet module
        Write-Verbose 'Checking for existing Microsoft.WinGet.Client module...'
        $mod = Get-Module -ListAvailable -Name Microsoft.WinGet.Client -ErrorAction SilentlyContinue
        if ($mod) {
            Write-Verbose "WinGet module found (v$($mod.Version))."
        } else {
            Write-Warning 'WinGet module not found, installing now.'
            
            # Install the module from PowerShell Gallery
            if ($psGalleryConfigured) {
                try {
                    Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers -Force -AllowClobber -Confirm:$false -ErrorAction Stop
                    Write-Verbose 'WinGet module installed successfully.'
                } catch {
                    Write-Warning "Install-Module failed: $_. Falling back to direct download method."
                    $psGalleryConfigured = $false
                }
            }
            
            # Fallback: Direct download and installation if PSGallery configuration failed
            if (-not $psGalleryConfigured) {
                Write-Verbose 'Using direct download method to install Microsoft.WinGet.Client module'
                
                # Get latest version info from PowerShell Gallery API
                $apiUrl = 'https://www.powershellgallery.com/api/v2/Packages?$filter=Id%20eq%20%27Microsoft.WinGet.Client%27&$orderby=Version%20desc&$top=1'
                $packageInfo = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
                $latestVersion = $packageInfo.properties.Version
                $downloadUrl = "https://www.powershellgallery.com/api/v2/package/Microsoft.WinGet.Client/$latestVersion"
                
                Write-Verbose "Found latest version: $latestVersion"
                Write-Verbose "Downloading from: $downloadUrl"
                
                # Create temporary directory for download
                $tempDir = Join-Path $env:TEMP "WinGetClient_$(Get-Random)"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                
                try {
                    # Download the package
                    $packagePath = Join-Path $tempDir "Microsoft.WinGet.Client.$latestVersion.nupkg"
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $packagePath -UseBasicParsing
                    
                    # Extract the package (it's a zip file)
                    $extractPath = Join-Path $tempDir "extracted"
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($packagePath, $extractPath)
                    
                    # Determine module installation path
                    $moduleBasePath = "$env:ProgramFiles\WindowsPowerShell\Modules"
                    $moduleInstallPath = Join-Path $moduleBasePath "Microsoft.WinGet.Client\$latestVersion"
                    
                    # Create module directory
                    if (Test-Path $moduleInstallPath) {
                        Remove-Item $moduleInstallPath -Recurse -Force
                    }
                    New-Item -ItemType Directory -Path $moduleInstallPath -Force | Out-Null
                    
                    # Copy module files (exclude package metadata files)
                    $sourceFiles = Get-ChildItem $extractPath -Recurse | Where-Object { 
                        $_.Name -notmatch '\.(nuspec|xml)$' -and 
                        $_.FullName -notlike "*\_rels\*" -and 
                        $_.FullName -notlike "*\package\*" -and
                        $_.Name -ne '_rels' -and 
                        $_.Name -ne 'package'
                    }
                    
                    foreach ($file in $sourceFiles) {
                        if ($file.PSIsContainer) {
                            $destDir = $file.FullName.Replace($extractPath, $moduleInstallPath)
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        } else {
                            $destFile = $file.FullName.Replace($extractPath, $moduleInstallPath)
                            $destDir = Split-Path $destFile -Parent
                            if (-not (Test-Path $destDir)) {
                                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                            }
                            Copy-Item $file.FullName -Destination $destFile -Force
                        }
                    }
                    
                    Write-Verbose "Microsoft.WinGet.Client module installed successfully via direct download to: $moduleInstallPath"
                } catch {
                    Write-Error "Failed to download and install module via direct method: $_"
                    throw
                } finally {
                    # Clean up temporary directory
                    if (Test-Path $tempDir) {
                        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        # Import the module
        try {
            Write-Verbose 'Importing Microsoft.WinGet.Client module...'
            Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop
            Write-Verbose 'Microsoft.WinGet.Client module imported.'
        } catch {
            Write-Error "Import-Module Microsoft.WinGet.Client failed: $_"
            throw $_
        }

        # Repair WinGet package manager
        try {
            Write-Verbose 'Repairing WinGet package manager...'
            Repair-WinGetPackageManager -AllUsers -Force -Latest -ErrorAction Stop
            Write-Verbose 'WinGet package manager repair completed.'
        } catch {
            Write-Warning "Repair-WinGetPackageManager encountered an issue: $_"
            throw $_
        }
    }

    End {
        Write-Verbose 'Install-WinGetModule completed.'

        # Remove the explicit -Verbose from the session, keeps the scope clean
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            $PSDefaultParameterValues.Remove('*:Verbose')   # turns verbose off
        }
    }
}

# Export the public functions
Export-ModuleMember -Function Install-NuGetProvider, Install-WinGetModule
