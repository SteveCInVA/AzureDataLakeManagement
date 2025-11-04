#Requires -Modules Pester

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psd1'
    Import-Module $ModulePath -Force
}

Describe 'AzureDataLakeManagement Microsoft.Graph Migration' {
    
    Context 'Module Dependencies' {
        It 'Should not reference AzureAD module in dependencies' {
            $moduleContent = Get-Content (Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psm1') -Raw
            # Should not have AzureAD as a standalone module reference (but AzureDataLakeManagement is OK)
            $moduleContent | Should -Not -Match "@\('Az\.Storage',\s*'AzureAD'"
        }
        
        It 'Should reference Microsoft.Graph.Users in dependencies' {
            $moduleContent = Get-Content (Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psm1') -Raw
            $moduleContent | Should -Match "Microsoft\.Graph\.Users"
        }
        
        It 'Should reference Microsoft.Graph.Groups in dependencies' {
            $moduleContent = Get-Content (Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psm1') -Raw
            $moduleContent | Should -Match "Microsoft\.Graph\.Groups"
        }
    }
    
    Context 'Get-AADObjectId Function Migration' {
        It 'Should use Get-MgUser instead of Get-AzureADUser' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "Get-MgUser"
            $functionContent | Should -Not -Match "Get-AzureADUser"
        }
        
        It 'Should use Get-MgGroup instead of Get-AzureADGroup' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "Get-MgGroup"
            $functionContent | Should -Not -Match "Get-AzureADGroup"
        }
        
        It 'Should use Get-MgServicePrincipal instead of Get-AzureADServicePrincipal' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "Get-MgServicePrincipal"
            $functionContent | Should -Not -Match "Get-AzureADServicePrincipal"
        }
        
        It 'Should use .Id property instead of .ObjectId' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            # Check that we assign to objectId from .Id property
            $functionContent | Should -Match '\$objectId\s*=\s*\$\w+\.Id'
        }
        
        It 'Should reference Connect-MgGraph in help/comments' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "Connect-MgGraph"
        }
    }
    
    Context 'Get-DataLakeFolderACL Function Migration' {
        It 'Should use Get-MgDirectoryObject instead of Get-AzureADObjectByObjectId' {
            $functionContent = (Get-Command Get-DataLakeFolderACL).Definition
            $functionContent | Should -Match "Get-MgDirectoryObject"
            $functionContent | Should -Not -Match "Get-AzureADObjectByObjectId"
        }
        
        It 'Should require Microsoft.Graph modules' {
            $functionContent = (Get-Command Get-DataLakeFolderACL).Definition
            $functionContent | Should -Match "Microsoft\.Graph\.Users"
            $functionContent | Should -Match "Microsoft\.Graph\.Groups"
        }
    }
    
    Context 'ACL Functions Dependencies' {
        It 'Set-DataLakeFolderACL should require Microsoft.Graph modules' {
            $functionContent = (Get-Command Set-DataLakeFolderACL).Definition
            $functionContent | Should -Match "Microsoft\.Graph\.Users"
            $functionContent | Should -Match "Microsoft\.Graph\.Groups"
        }
        
        It 'Remove-DataLakeFolderACL should require Microsoft.Graph modules' {
            $functionContent = (Get-Command Remove-DataLakeFolderACL).Definition
            $functionContent | Should -Match "Microsoft\.Graph\.Users"
            $functionContent | Should -Match "Microsoft\.Graph\.Groups"
        }
    }
    
    Context 'Documentation Updates' {
        It 'README should mention Microsoft.Graph modules' {
            $readmeContent = Get-Content (Join-Path $PSScriptRoot '..' 'README.md') -Raw
            $readmeContent | Should -Match "Microsoft\.Graph"
        }
        
        It 'README should mention Connect-MgGraph' {
            $readmeContent = Get-Content (Join-Path $PSScriptRoot '..' 'README.md') -Raw
            $readmeContent | Should -Match "Connect-MgGraph"
        }
        
        It 'example.ps1 should use Connect-MgGraph' {
            $exampleContent = Get-Content (Join-Path $PSScriptRoot '..' 'example.ps1') -Raw
            $exampleContent | Should -Match "Connect-MgGraph"
            # The comment is OK, but we should not have an actual Connect-AzureAD command
            $exampleContent | Should -Not -Match "^Connect-AzureAD" -Because "Connect-AzureAD should be commented out or replaced"
        }
        
        It 'Module version should be updated to 2025.11.2 or higher' {
            $manifest = Test-ModuleManifest -Path $ModulePath
            $manifest.Version.Major | Should -BeGreaterOrEqual 2025
            $manifest.Version.Minor | Should -BeGreaterOrEqual 11
            $manifest.Version.Build | Should -BeGreaterOrEqual 2
        }
    }
    
    Context 'Backward Compatibility' {
        It 'Get-AADObjectId should still return ObjectId property' {
            # This ensures backward compatibility - the property name should remain ObjectId
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "ObjectId\s*="
        }
        
        It 'Get-AADObjectId should still return ObjectType property' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "ObjectType\s*="
        }
        
        It 'Get-AADObjectId should still return DisplayName property' {
            $functionContent = (Get-Command Get-AADObjectId).Definition
            $functionContent | Should -Match "DisplayName\s*="
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module 'AzureDataLakeManagement' -Force -ErrorAction SilentlyContinue
}
