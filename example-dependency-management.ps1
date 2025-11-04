# Example script demonstrating improved dependency management in AzureDataLakeManagement

# Import the module - it will now provide helpful feedback about missing dependencies
Import-Module .\AzureDataLakeManagement\AzureDataLakeManagement.psd1

# Check what dependencies are missing
Test-ModuleDependencies

# To install missing dependencies automatically, you can run:
# Test-ModuleDependencies -AutoInstall

# Or install them manually:
# Install-Module -Name Az.Storage -Force
# Install-Module -Name Microsoft.Graph.Applications -Force
# Install-Module -Name Microsoft.Graph.Users -Force
# Install-Module -Name Microsoft.Graph.Groups -Force
# Install-Module -Name Microsoft.Graph.DirectoryObjects -Force

# The module will now provide better error messages when functions are called without required dependencies
# For example:
# Add-DataLakeFolder -SubscriptionName 'test' -ResourceGroupName 'test' -StorageAccountName 'test' -ContainerName 'test' -FolderPath 'test'

Write-Host "
Dependency Management Features:
- Test-ModuleDependencies: Check which dependencies are available
- Test-ModuleDependencies -AutoInstall: Automatically install missing dependencies
- Install-ModuleDependencies: Install specific dependencies
- Import-ModuleDependencies: Import dependencies with better error handling

The module will automatically check dependencies when imported and provide helpful guidance.
" -ForegroundColor Green