# Azure Data Lake Management PowerShell Module

Always follow these instructions first and only search or use bash commands when you encounter information that contradicts what is documented here or when these instructions are incomplete.

This repository contains a PowerShell module for managing Azure Data Lake Storage Gen 2 folders and Access Control Lists (ACLs). The module simplifies ACL management by using object names rather than IDs and provides functions to create, delete, move folders and manage permissions recursively.

## Working Effectively

### Prerequisites and Environment Setup
- Install PowerShell 7+ (PowerShell Core): Download from https://github.com/PowerShell/PowerShell/releases
- Install required Azure PowerShell modules:
  ```powershell
  Install-Module -Name Az.Storage -Scope CurrentUser -Force
  Install-Module -Name AzureAD -Scope CurrentUser -Force  
  Install-Module -Name Az.Accounts -Scope CurrentUser -Force
  ```
- Authenticate to Azure before testing:
  ```powershell
  Connect-AzAccount
  Connect-AzureAD
  ```

### Code Quality and Validation
- Run PSScriptAnalyzer for code quality checks (takes ~3 seconds):
  ```powershell
  Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1
  ```
- Test module manifest (takes ~1 second):
  ```powershell
  Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1
  ```
  **Note**: Will show warnings about missing Az.Storage, AzureAD, and Az.Accounts modules if they're not installed. This is expected in offline environments.
- ALWAYS run PSScriptAnalyzer before committing changes or the code quality will deteriorate.

### Offline Development and Testing
When Azure modules or connectivity is not available:
- Module import will work but functions will fail at runtime
- PSScriptAnalyzer and manifest testing work completely offline
- Function syntax and help documentation can be validated offline
- Use these commands for offline validation:
  ```powershell
  # These work without Azure connectivity
  Import-Module -Force './AzureDataLakeManagement/AzureDataLakeManagement.psm1'
  Get-Command -Module AzureDataLakeManagement
  Get-Help Add-DataLakeFolder -Examples
  Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1
  Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1
  ```

### Module Development and Testing
- Import the module for testing (~1 second):
  ```powershell
  Import-Module -Force './AzureDataLakeManagement/AzureDataLakeManagement.psm1'
  ```
- Get available functions:
  ```powershell
  Get-Command -Module AzureDataLakeManagement
  ```
- Access function help and examples (~1 second per function):
  ```powershell
  Get-Help Add-DataLakeFolder -Examples
  Get-Help Set-DataLakeFolderACL -Full
  ```
- **CRITICAL**: Test functions only with test/development Azure resources. Never test against production data.

### Publishing Process
- **Prerequisites for Publishing**: 
  - PowerShell Gallery API Key (set as environment variable `PSGalleryKey`)
  - Module version updated in `.psd1` file
  - All PSScriptAnalyzer warnings addressed
  - Manual validation completed
  
- **Manual publish to PowerShell Gallery** (~30 seconds):
  ```powershell
  # Set your API key first
  $env:PSGalleryKey = "your-api-key-here"
  .\publish.ps1
  ```
  
- **GitHub Actions publish**:
  - Workflow: `.github/workflows/manual_publish.yml` 
  - Requires `PSGalleryKey` secret configured in repository
  - Manually triggered via GitHub Actions UI
  - Uses `workflow_dispatch` trigger (not automatic)
  
- **Pre-publish validation checklist**:
  ```powershell
  # 1. Code quality check
  Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1
  
  # 2. Module manifest validation  
  Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1
  
  # 3. Module import test
  Import-Module -Force './AzureDataLakeManagement/AzureDataLakeManagement.psm1'
  Get-Command -Module AzureDataLakeManagement
  
  # 4. Verify version number is updated in .psd1
  # 5. Complete manual validation scenarios with test Azure resources
  ```

## Key Module Components

### Primary Functions (8 total):
1. **Get-AADObjectId** - Retrieve Azure AD object details by name/UPN
2. **Get-AzureSubscriptionInfo** - Get subscription information
3. **Add-DataLakeFolder** - Create folder structures in Data Lake Storage
4. **Remove-DataLakeFolder** - Delete folders from Data Lake Storage
5. **Set-DataLakeFolderACL** - Apply ACL permissions to folders (recursively)
6. **Get-DataLakeFolderACL** - Retrieve current ACL permissions
7. **Move-DataLakeFolder** - Move/rename folders between containers
8. **Remove-DataLakeFolderACL** - Remove ACL permissions from folders

### Core Files:
- `AzureDataLakeManagement/AzureDataLakeManagement.psm1` - Main module (1026 lines, 8 functions)
- `AzureDataLakeManagement/AzureDataLakeManagement.psd1` - Module manifest and metadata
- `example.ps1` - Complete usage examples showing folder creation and ACL management
- `publish.ps1` - PowerShell Gallery publishing script

## Validation and Testing

### Code Quality Validation
Run these before every commit:
```powershell
# Static analysis (3 seconds) - NEVER CANCEL
Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1

# Module manifest validation (1 second)
Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1
```

### Manual Validation Scenarios
**CRITICAL**: Always test against development/test Azure resources only. Complete these scenarios after making changes:

1. **Authentication and Module Import Test** (1-2 minutes):
   ```powershell
   Connect-AzAccount
   Connect-AzureAD
   Import-Module -Force './AzureDataLakeManagement/AzureDataLakeManagement.psm1'
   Get-Command -Module AzureDataLakeManagement
   # Should show all 8 functions
   ```

2. **Basic Folder Operations Test** (5-10 minutes):
   ```powershell
   # Use test subscription and storage account
   $subName = 'your-test-subscription'
   $rgName = 'test-resource-group'
   $storageAccountName = 'teststorageaccount'
   $containerName = 'test-container'
   
   # Create test folder structure
   Add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'test-dataset\sample-folder'
   
   # Verify folder exists in Azure Storage Explorer or portal
   
   # Test folder move operation
   Move-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -SourceContainerName $containerName -sourceFolderPath 'test-dataset\sample-folder' -DestinationContainerName $containerName -destinationFolderPath 'test-dataset\moved-folder'
   
   # Clean up
   Remove-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'test-dataset'
   ```

3. **ACL Management Test** (5-10 minutes):
   ```powershell
   # Create test folder
   Add-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'acl-test'
   
   # Apply test ACL (use test user/group)
   Set-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'acl-test' -Identity 'test-user@domain.com' -accessControlType Read
   
   # Verify ACL was applied
   Get-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'acl-test'
   
   # Test ACL removal
   Remove-DataLakeFolderACL -SubscriptionName $subName -ResourceGroupName $rgName -StorageAccountName $storageAccountName -ContainerName $containerName -folderPath 'acl-test' -Identity 'test-user@domain.com'
   
   # Clean up
   Remove-DataLakeFolder -SubscriptionName $subName -resourceGroup $rgName -storageAccountName $storageAccountName -containerName $containerName -folderPath 'acl-test'
   ```

4. **Azure AD Object Resolution Test** (2-3 minutes):
   ```powershell
   # Test user lookup
   Get-AADObjectId -Identity 'test-user@domain.com'
   
   # Test group lookup  
   Get-AADObjectId -Identity 'Test Group Name'
   
   # Test service principal lookup
   Get-AADObjectId -Identity 'Test Service Principal'
   
   # Should return ObjectId, ObjectType, and DisplayName for each
   ```

5. **Complete example.ps1 Workflow Test** (10-15 minutes):
   ```powershell
   # Modify variables in example.ps1 first, then run:
   .\example.ps1
   
   # Verify in Azure portal:
   # - Multiple folder structures created
   # - ACL permissions applied correctly
   # - Test folders cleaned up properly
   ```

### Development Workflow Timing
- PSScriptAnalyzer execution: ~3 seconds - NEVER CANCEL
- Module manifest testing: ~1 second
- Module import: ~1 second (without Azure dependencies)
- Module import with Azure modules: ~2-5 seconds (depends on Azure module loading)
- Single folder operation: ~3-10 seconds (depends on Azure latency)
- ACL operations: ~5-15 seconds (depends on Azure AD latency and hierarchy depth)
- Full validation scenario: ~10-20 minutes total
- Complete example.ps1 workflow: ~5-15 minutes (creates multiple folders and ACLs)

### Using example.ps1 for Learning
The `example.ps1` file demonstrates a complete workflow:
1. Authentication to Azure and Azure AD
2. Creating hierarchical folder structures
3. Setting various ACL types (user, group, service principal)
4. Error handling scenarios
5. Cleanup operations

**CRITICAL**: Always modify the variables in example.ps1 before running:
```powershell
$subName = 'your-test-subscription'        # Change this
$rgName = 'your-test-resource-group'       # Change this  
$storageAccountName = 'your-test-storage'  # Change this
$containerName = 'test-container'          # Change this
```

## Common Development Tasks

### Adding New Functions
1. Add function to `AzureDataLakeManagement.psm1`
2. Update `FunctionsToExport` in `AzureDataLakeManagement.psd1`
3. Add usage example to `example.ps1`
4. Run PSScriptAnalyzer validation
5. Test with manual validation scenarios

### Debugging Issues
- Use VS Code with PowerShell extension for debugging
- Import module with `-Force` to reload changes
- Use `-Verbose` parameter on functions for detailed output
- Check Azure portal/Storage Explorer to verify actual changes

### Common Error Scenarios
1. **Missing Azure Authentication**: Functions fail with authentication errors
   - Solution: Run `Connect-AzAccount` and `Connect-AzureAD`
   
2. **Module Dependencies Missing**: Import fails with module not found errors
   - Solution: Install Az.Storage, AzureAD, and Az.Accounts modules
   
3. **Path Format Issues**: Functions expect backslash separators in folderPath
   - Correct: `'dataset1\folder1\subfolder'`
   - Incorrect: `'dataset1/folder1/subfolder'`
   
4. **Permissions Issues**: ACL operations fail due to insufficient permissions
   - Ensure Azure AD permissions and Storage Account permissions are configured
   
5. **Storage Account Access**: Operations fail if storage account keys are not accessible
   - Module requires either storage account key access OR proper Azure AD permissions

### Known Code Quality Issues
PSScriptAnalyzer currently identifies 17 warnings that should be addressed in new code:
- 5 instances of `Write-Host` usage (use `Write-Output`, `Write-Verbose`, or `Write-Information`)
- 6 unused parameter warnings (remove unused parameters)
- 3 unused variable warnings (remove unused variables)  
- 3 missing `ShouldProcess` support warnings for state-changing functions (Add-DataLakeFolder, Set-DataLakeFolderACL, Remove-DataLakeFolderACL)

Run `Invoke-ScriptAnalyzer` to see the complete list with line numbers and detailed guidance.

## Repository Structure Reference
```
.
├── .github/
│   └── workflows/
│       └── manual_publish.yml      # GitHub Actions publishing workflow
├── .vscode/
│   ├── launch.json                 # VS Code debugging configuration  
│   └── settings.json               # VS Code settings
├── AzureDataLakeManagement/
│   ├── AzureDataLakeManagement.psd1 # Module manifest
│   └── AzureDataLakeManagement.psm1 # Main module (8 functions)
├── .gitignore
├── LICENSE
├── README.md                       # Project overview and version history
├── example.ps1                     # Complete usage examples
└── publish.ps1                     # PowerShell Gallery publishing script
```

## Quick Reference Commands

### Daily Development
```powershell
# Load and test module
Import-Module -Force './AzureDataLakeManagement/AzureDataLakeManagement.psm1'

# Code quality check (run before commit)
Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement/AzureDataLakeManagement.psm1

# Test manifest
Test-ModuleManifest ./AzureDataLakeManagement/AzureDataLakeManagement.psd1
```

### Azure Authentication
```powershell
Connect-AzAccount
Connect-AzureAD
Get-AzSubscription  # Verify connection
```

### Function Usage Pattern
```powershell
# All functions follow this parameter pattern:
-SubscriptionName    # Azure subscription name
-ResourceGroupName   # Resource group containing storage account  
-StorageAccountName  # Storage account name
-ContainerName       # Container/filesystem name
-folderPath         # Path within container (use backslash separators)
```