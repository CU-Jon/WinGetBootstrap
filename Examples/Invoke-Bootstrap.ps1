[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ModulePath,
    [ValidateSet('SilentlyContinue', 'Continue', 'Inquire', 'Break', 'Stop', IgnoreCase = $true)]
    [Parameter(Mandatory = $false)]
    [string]$ProgressPreference = 'SilentlyContinue'
)

# Set $ProgressPreference
$global:ProgressPreference = $ProgressPreference

if (-not $ModulePath) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ModuleDir = Split-Path -Path $ScriptDir -Parent
    $ModulePath = Join-Path -Path $ModuleDir -ChildPath 'WinGetBootstrap.psm1'
}

if (-not (Test-Path -Path $ModulePath -PathType Leaf)) {
    Write-Error "Module file not found: $ModulePath"
    exit 1
}

try {
    Write-Verbose "Importing module from $ModulePath"
    Import-Module -Name $ModulePath -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import module: $_"
    exit 1
}

# Check if -Verbose is set
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
    $Expression = "Install-WinGetModule -Verbose"
} else {
    $Expression = "Install-WinGetModule"
}

try {
    Write-Verbose "Installing WinGet module"
    Invoke-Expression $Expression -ErrorAction Stop
} catch {
    Write-Error "Failed to install WinGet module: $_"
    exit 1
}