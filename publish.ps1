
Install-Module -Name AzureAD -RequiredVersion 2.0.2.140
Install-Module -Name Az.Storage -RequiredVersion 5.5.0
Install-Module -Name Az.Accounts -RequiredVersion 2.12.1

$parameters = @{
    NuGetApiKey = $env:PSGalleryKey
    Path        = "$PSScriptRoot\AzureDataLakeManagement"
}
Publish-Module @parameters

