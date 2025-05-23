[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ModulePath
)

if (-not $ModulePath) {
    $ScriptPath = $MyInvocation.MyCommand.Path
    $ScriptDir = Split-Path -Path $ScriptPath -Parent
    $ModulePath = Join-Path -Path $ScriptDir -ChildPath 'WinGetBootstrap.psm1'
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
    $Verbose = "`$true"
} else {
    $Verbose = "`$false"
}

try {
    Write-Verbose "Installing WinGet module"
    Invoke-Expression "Install-WinGetModule -Verbose:$Verbose" -ErrorAction Stop
} catch {
    Write-Error "Failed to install WinGet module: $_"
    exit 1
}