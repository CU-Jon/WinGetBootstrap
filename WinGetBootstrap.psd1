@{
    # Script module manifest for WinGetBootstrap

    RootModule        = 'WinGetBootstrap.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e1b8c2f9-3d4e-4f2b-a4b2-5f88a9d5e8c7'
    Author            = 'Jon Agramonte'
    CompanyName       = 'Clemson University CCIT'
    Description       = 'Bootstraps the NuGet provider and installs/repairs the Microsoft.WinGet.Client module.'

    # Functions to export from this module
    FunctionsToExport = @(
        'Install-NuGetProvider',
        'Install-WinGetModule'
    )

    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()

    # Private data for this module
    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell','NuGet','WinGet','Bootstrap')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/CU-Jon/WinGetBootstrap'
            RepositoryUrl= 'https://github.com/CU-Jon/WinGetBootstrap'
            ReleaseNotes = 'Initial release of WinGetBootstrap module.'
        }
    }
}
