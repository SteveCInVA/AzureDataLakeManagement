# AzureDataLakeManagement
This project was created to help simplify the process of managing an Azure Datalake specifically around updating existing ACL's to child objects within the lake.
Yes, this can be accomplished with Azure Storage Explorer, however come customers don't like to install new software.

My goal, is to make a straight forward set of functions that will assist a user in configuring folders and the associated ACL's in an ADLS Gen 2 storage container using the objects names rather than ID's.

To contribute to this project please view the GitHub project at https://github.com/SteveCInVA/AzureDataLakeManagement

## Development Environment

### Using Dev Containers (Recommended)

This repository includes support for Visual Studio Code dev containers, providing a consistent development environment with all required tools pre-installed.

#### Prerequisites
- [Visual Studio Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) for VS Code

#### Getting Started with Dev Containers
1. Clone the repository
2. Open the repository folder in Visual Studio Code
3. When prompted, click "Reopen in Container" (or use Command Palette: `Dev Containers: Reopen in Container`)
4. VS Code will build the container and install all dependencies automatically

#### What's Included
The dev container includes:
- **PowerShell 7+** - Latest version installed automatically
- **Pre-installed VS Code Extensions:**
  - PowerShell - Language support and debugging
  - Pester Test - Testing framework support
  - GitHub Copilot - AI-powered code assistance
  - GitHub Actions - Workflow file support
  - TODO Highlight v2 - Highlight TODO comments
- **PowerShell Modules:**
  - PSScriptAnalyzer - For code quality checks
  - Pester - For testing

#### Working in the Dev Container
Once the container is running, you can:
- Import the module: `Import-Module ./AzureDataLakeManagement/AzureDataLakeManagement.psm1 -Force`
- Run code quality checks: `Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1`
- Test the module: `Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1`
- Run Pester tests: `Invoke-Pester -Path ./Tests`

### Local Development (Without Dev Containers)

If you prefer to develop locally without containers, ensure you have:
- PowerShell 7+ installed
- Required PowerShell modules (see Dependency Management section below)

## Dependency Management

Starting with version 2025.1.1, the module includes improved dependency management features:

### Required Dependencies
The module requires the following PowerShell modules:
- `Az.Storage` - For Azure Storage operations
- `AzureAD` - For Azure Active Directory operations  
- `Az.Accounts` - For Azure authentication

### Automatic Dependency Checking
When you import the module, it automatically checks for missing dependencies and provides helpful guidance:

```powershell
Import-Module AzureDataLakeManagement
# Output: WARNING: AzureDataLakeManagement module loaded with missing dependencies.
# Some functions may not work correctly until required modules are installed.
# Run 'Test-ModuleDependencies -AutoInstall' to install missing dependencies automatically.
```

### Dependency Management Functions

#### Test-ModuleDependencies
Check which dependencies are available:
```powershell
Test-ModuleDependencies
```

Automatically install missing dependencies:
```powershell
Test-ModuleDependencies -AutoInstall
```

#### Install-ModuleDependencies
Install all or specific dependencies:
```powershell
Install-ModuleDependencies
Install-ModuleDependencies -Modules @('Az.Storage')
```

#### Manual Installation
You can also install dependencies manually:
```powershell
Install-Module -Name Az.Storage -Force
Install-Module -Name AzureAD -Force
Install-Module -Name Az.Accounts -Force
```

### Improved Error Handling
Functions now provide clearer error messages when dependencies are missing, guiding users to install the required modules.

***

## Version History:

- 2025.1.1 - 01/09/2025
Issue 27 - Added optional switch to set-DataLakeFolderACL and remove-DataLakeFolderACL functions to enable the user to not recursively apply permissions on children of the path specified.

- 2024.1.1 - 01/09/2024
Issue 22 - Fixed issue where a lack of Azure Permissions to Microsoft.Storage/storageAccounts/listKeys/action would cause failure to execute even with correct AzureAD permissions on objects.

- 2023.12.3 - 12/01/2023
Published via Github Actions to [PowershellGallery.com](https://www.powershellgallery.com/packages/AzureDataLakeManagement)

- 2023.12.2 - 12/01/2023
Removed - Github Action Publish testing

- 2023.12.1 - 12/01/2023
Function optimization and improved consistency of help content.

- 2023.11.2 - 11/13/2023
Added function to remove an ACL from a folder and all inherited children

