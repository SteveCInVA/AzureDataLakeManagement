
$parameters = @{
    NuGetApiKey = $env:PSGalleryKey
    Path        = "$PSScriptRoot\AzureDataLakeManagement"
}
Publish-Module @parameters

