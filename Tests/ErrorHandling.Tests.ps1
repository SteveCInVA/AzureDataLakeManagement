#Requires -Modules Pester

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psd1'
    Import-Module $ModulePath -Force
}

Describe 'AzureDataLakeManagement Error Handling' {
    
    Context 'Remove-DataLakeFolderACL Error Handling' {
        It 'Should have enhanced error handling in Remove-DataLakeFolderACL' {
            $functionContent = (Get-Command Remove-DataLakeFolderACL).Definition
            
            # Check for resource lock error detection
            $functionContent | Should -Match 'ScopeLocked|resource.*lock|ReadOnly'
            
            # Check for permission error detection
            $functionContent | Should -Match 'Forbidden|403|AuthorizationFailed'
            
            # Check for enhanced error messages
            $functionContent | Should -Match 'resource lock'
            $functionContent | Should -Match 'Access denied'
        }
        
        It 'Should include documentation about resource locks' {
            $help = Get-Help Remove-DataLakeFolderACL -Full
            $notesText = $help.alertSet.alert.Text -join ' '
            $notesText | Should -Match 'Resource Lock|resource lock'
        }
        
        It 'Should have updated date for resource lock enhancement' {
            $help = Get-Help Remove-DataLakeFolderACL -Full
            $help.alertSet.alert.Text | Should -Match '2025-01-10.*Enhanced error handling'
        }
    }
    
    Context 'Set-DataLakeFolderACL Error Handling' {
        It 'Should have enhanced error handling in Set-DataLakeFolderACL' {
            $functionContent = (Get-Command Set-DataLakeFolderACL).Definition
            
            # Check for resource lock error detection
            $functionContent | Should -Match 'ScopeLocked|resource.*lock|ReadOnly'
            
            # Check for permission error detection
            $functionContent | Should -Match 'Forbidden|403|AuthorizationFailed'
            
            # Check for enhanced error messages
            $functionContent | Should -Match 'resource lock'
            $functionContent | Should -Match 'Access denied'
        }
        
        It 'Should include documentation about resource locks' {
            $help = Get-Help Set-DataLakeFolderACL -Full
            $notesText = $help.alertSet.alert.Text -join ' '
            $notesText | Should -Match 'Resource Lock|resource lock'
        }
        
        It 'Should have updated date for resource lock enhancement' {
            $help = Get-Help Set-DataLakeFolderACL -Full
            $help.alertSet.alert.Text | Should -Match '2025-01-10.*Enhanced error handling'
        }
    }
    
    Context 'Error Message Quality' {
        It 'Remove-DataLakeFolderACL should provide storage account name in error messages' {
            $functionContent = (Get-Command Remove-DataLakeFolderACL).Definition
            $functionContent | Should -Match '\$StorageAccountName'
        }
        
        It 'Set-DataLakeFolderACL should provide storage account name in error messages' {
            $functionContent = (Get-Command Set-DataLakeFolderACL).Definition
            $functionContent | Should -Match '\$StorageAccountName'
        }
        
        It 'Remove-DataLakeFolderACL should provide remediation guidance' {
            $functionContent = (Get-Command Remove-DataLakeFolderACL).Definition
            $functionContent | Should -Match 'remove or modify the resource lock'
        }
        
        It 'Set-DataLakeFolderACL should provide remediation guidance' {
            $functionContent = (Get-Command Set-DataLakeFolderACL).Definition
            $functionContent | Should -Match 'remove or modify the resource lock'
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module 'AzureDataLakeManagement' -Force -ErrorAction SilentlyContinue
}
