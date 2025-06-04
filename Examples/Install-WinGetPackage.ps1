[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Name,
    [Parameter(Mandatory = $false)]
    [string]$Id,
    [Parameter(Mandatory = $false)]
    [string]$Override,
    [ValidateSet("System", "User", "Any", "SystemOrUnknown", "UserOrUnknown", "", $null, IgnoreCase = $true)]
    [Parameter(Mandatory = $false)]
    [string]$Scope = "SystemOrUnknown",
    [ValidateSet("Default", "Interactive", "Silent", "", $null, IgnoreCase = $true)]
    [Parameter(Mandatory = $false)]
    [string]$Mode = 'Default',
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    [Parameter(Mandatory = $false)]
    [switch]$AllowHashMismatch,
    [Parameter(Mandatory = $false)]
    [string]$Source = "winget",
    [ValidateSet('SilentlyContinue', 'Continue', 'Inquire', 'Break', 'Stop', IgnoreCase = $true)]
    [Parameter(Mandatory = $false)]
    [string]$ProgressPreference = 'SilentlyContinue'
)

# Set $ProgressPreference
$global:ProgressPreference = $ProgressPreference

# Check for the Microsoft.WinGet.Client module
if (-not (Get-Module -Name Microsoft.WinGet.Client -ListAvailable)) {
    Write-Error "Microsoft.WinGet.Client module is not installed. Please install it first."
    exit 1
}

# You can't use both -Name and -Id at the same time
if ($Name -and $Id) {
    Write-Error "Cannot specify both -Name and -Id. Please use one or the other."
    exit 1
}

# Check if the user has provided at least one of -Name or -Id
if (-not $Name -and -not $Id) {
    Write-Error "You must specify either -Name or -Id."
    exit 1
}

# Import the Microsoft.WinGet.Client module
try {
    Write-Verbose "Importing Microsoft.WinGet.Client module"
    Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import module: $_"
    exit 1
}

# Construct the arguments for the Install-WinGetPackage command
if ($Name) {
    $Arguments = "-Name `"$Name`""
}

if ($Id) {
    $Arguments = "-Id `"$Id`" -MatchOption Equals"
}

if ($Override) {
    $Arguments += " -Override `"$Override`""
}

if ($Force) {
    $Arguments += " -Force"
}

if ($AllowHashMismatch) {
    $Arguments += " -AllowHashMismatch"
}

if ($Scope -ne $null -and $Scope -ne "") {
    $Arguments += " -Scope `"$Scope`""
}

if ($Mode -ne $null -and $Mode -ne "") {
    $Arguments += " -Mode `"$Mode`""
}

# Add on the default parameters
$Arguments += " -Source `"$Source`" -Confirm:`$false"

# Check if -Verbose is set
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
    $Arguments += " -Verbose"
}

# Run the Install-WinGetPackage command with the constructed arguments
try {
    Write-Verbose "Installing package with arguments: $Arguments"
    Invoke-Expression "Install-WinGetPackage $Arguments" -ErrorAction Stop
} catch {
    Write-Error "Failed to install package: $_"
    exit 1
}
