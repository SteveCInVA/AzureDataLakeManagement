# Migration Guide: AzureAD to Microsoft.Graph

## Overview
Version 2025.11.2 of the AzureDataLakeManagement module migrates from the deprecated AzureAD PowerShell module to the Microsoft.Graph PowerShell SDK. This change is necessary for PowerShell 7+ compatibility and aligns with Microsoft's recommendations.

## Why This Change?
- **AzureAD module is deprecated**: Microsoft announced the deprecation of the AzureAD and MSOnline modules with retirement scheduled for late 2025
- **PowerShell 7+ incompatibility**: The AzureAD module only works with Windows PowerShell 5.1 and is not compatible with PowerShell Core (7+)
- **Modern authentication**: Microsoft Graph SDK uses MSAL (Microsoft Authentication Library) with better security and support for modern authentication methods
- **Future-proof**: Microsoft Graph is the unified endpoint for all Microsoft 365 services with regular updates

## Breaking Changes

### Module Dependencies
**Before (v2025.11.1 and earlier):**
```powershell
# Required modules
- Az.Storage
- AzureAD
- Az.Accounts

```

**After (v2025.11.2 and later):**
```powershell
# Required modules
- Az.Storage
- Microsoft.Graph.Applications
- Microsoft.Graph.Users
- Microsoft.Graph.Groups
- Microsoft.Graph.DirectoryObjects

```

### Authentication
**Before:**
```powershell
Connect-AzAccount
Connect-AzureAD
```

**After:**
```powershell
Connect-AzAccount
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All"
```

## Migration Steps

### Step 1: Install New Dependencies
```powershell
# Uninstall old AzureAD module (optional)
Uninstall-Module -Name AzureAD

# Install Microsoft Graph modules
Install-Module -Name Microsoft.Graph.Applications -Force
Install-Module -Name Microsoft.Graph.Users -Force
Install-Module -Name Microsoft.Graph.Groups -Force
Install-Module -Name Microsoft.Graph.DirectoryObjects -Force

# Or use the module's built-in dependency management
Import-Module AzureDataLakeManagement
Test-ModuleDependencies -AutoInstall
```

### Step 2: Update Authentication in Scripts
Replace all instances of `Connect-AzureAD` with:
```powershell
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All"
```

**Note on Scopes:**
- `User.Read.All`: Required for reading user information
- `Group.Read.All`: Required for reading group information
- `Application.Read.All`: Required for reading service principal information

For production/automation scenarios, consider using certificate-based authentication:
```powershell
Connect-MgGraph -ClientId "YOUR_CLIENT_ID" -TenantId "YOUR_TENANT_ID" -CertificateThumbprint "YOUR_CERT_THUMBPRINT"
```

### Step 3: Update Module Version
```powershell
# Update to the latest version
Update-Module -Name AzureDataLakeManagement

# Verify version
Get-Module -Name AzureDataLakeManagement -ListAvailable | Select-Object Name, Version
```

## Function Changes

### No Changes to Function Signatures
All public functions maintain the same parameters and behavior:
- `Get-AADObjectId`
- `Get-AzureSubscriptionInfo`
- `Add-DataLakeFolder`
- `Remove-DataLakeFolder`
- `Set-DataLakeFolderACL`
- `Get-DataLakeFolderACL`
- `Move-DataLakeFolder`
- `Remove-DataLakeFolderACL`

### Internal Changes
The following cmdlet replacements were made internally:
- `Get-AzureADUser` → `Get-MgUser`
- `Get-AzureADGroup` → `Get-MgGroup`
- `Get-AzureADServicePrincipal` → `Get-MgServicePrincipal`
- `Get-AzureADObjectByObjectId` → `Get-MgDirectoryObject`

## Troubleshooting

### Error: "Module not found"
```powershell
# Solution: Install the required modules
Test-ModuleDependencies -AutoInstall
```

### Error: "Authentication needed"
```powershell
# Solution: Connect to Microsoft Graph with appropriate scopes
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All"
```

### Error: "Insufficient privileges"
```powershell
# Solution: Ensure your account has the required permissions
# Or use delegated permissions with admin consent
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All"
```

### Compatibility Issues
If you experience issues:
1. Verify PowerShell version: `$PSVersionTable.PSVersion`
2. Check installed modules: `Get-Module -ListAvailable | Where-Object Name -match "Graph|Az"`
3. Update all Az modules: `Update-Module -Name Az.*`
4. Restart PowerShell session

## Testing Your Migration

### Test Basic Functionality
```powershell
# Import module
Import-Module AzureDataLakeManagement

# Check dependencies
Test-ModuleDependencies

# Authenticate
Connect-AzAccount
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Application.Read.All"

# Test object lookup
Get-AADObjectId -Identity "user@yourdomain.com"
```

### Verify ACL Operations
```powershell
# Test ACL retrieval (replace with your values)
Get-DataLakeFolderACL -SubscriptionName "YourSubscription" `
    -ResourceGroupName "YourResourceGroup" `
    -StorageAccountName "yourstorageaccount" `
    -ContainerName "yourcontainer" `
    -FolderPath "yourfolder"
```

## Support and Resources

### Documentation
- [Microsoft Graph PowerShell SDK Documentation](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Upgrade from Azure AD PowerShell to Microsoft Graph PowerShell](https://learn.microsoft.com/en-us/powershell/microsoftgraph/migration-steps)

### Common Use Cases

#### Finding a User
```powershell
# Old way (AzureAD)
Get-AzureADUser -Filter "UserPrincipalName eq 'user@domain.com'"

# New way (Microsoft Graph)
Get-MgUser -Filter "UserPrincipalName eq 'user@domain.com'"

# Using the module (unchanged)
Get-AADObjectId -Identity "user@domain.com"
```

#### Finding a Group
```powershell
# Old way (AzureAD)
Get-AzureADGroup -Filter "DisplayName eq 'GroupName'"

# New way (Microsoft Graph)
Get-MgGroup -Filter "DisplayName eq 'GroupName'"

# Using the module (unchanged)
Get-AADObjectId -Identity "GroupName"
```

## Feedback and Issues
If you encounter any issues with the migration, please:
1. Review this migration guide
2. Check the [GitHub Issues](https://github.com/SteveCInVA/AzureDataLakeManagement/issues)
3. Create a new issue with details about your environment and the error

## Rollback (Not Recommended)
If you need to temporarily roll back to the old version:
```powershell
# Install specific old version
Install-Module -Name AzureDataLakeManagement -RequiredVersion 2025.11.1 -Force

# Note: This is only a temporary solution as AzureAD module will be retired
```

**Important**: The rollback is only temporary. You should plan to migrate to Microsoft.Graph as the AzureAD module will stop working when Microsoft completes the retirement.
