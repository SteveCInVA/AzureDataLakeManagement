#Requires -Modules Pester

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'AzureDataLakeManagement' 'AzureDataLakeManagement.psd1'
    Import-Module $ModulePath -Force
}

Describe 'AzureDataLakeManagement Dependency Management' {
    
    Context 'Test-ModuleDependencies Function' {
        It 'Should export Test-ModuleDependencies function' {
            Get-Command -Name 'Test-ModuleDependencies' -Module 'AzureDataLakeManagement' | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have the correct parameters' {
            $command = Get-Command -Name 'Test-ModuleDependencies'
            $command.Parameters.Keys | Should -Contain 'AutoInstall'
            $command.Parameters.Keys | Should -Contain 'Quiet'
        }
        
        It 'Should return boolean value' {
            Mock Get-Module { $null } -ParameterFilter { $Name -eq 'Az.Storage' }
            Mock Get-Module { $null } -ParameterFilter { $Name -eq 'AzureAD' }  
            Mock Get-Module { $null } -ParameterFilter { $Name -eq 'Az.Accounts' }
            
            $result = Test-ModuleDependencies -Quiet
            $result | Should -BeOfType [System.Boolean]
        }
    }
    
    Context 'Install-ModuleDependencies Function' {
        It 'Should export Install-ModuleDependencies function' {
            Get-Command -Name 'Install-ModuleDependencies' -Module 'AzureDataLakeManagement' | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have the correct parameters' {
            $command = Get-Command -Name 'Install-ModuleDependencies'
            $command.Parameters.Keys | Should -Contain 'Modules'
            $command.Parameters.Keys | Should -Contain 'Quiet'
        }
    }
    
    Context 'Import-ModuleDependencies Function' {
        It 'Should export Import-ModuleDependencies function' {
            Get-Command -Name 'Import-ModuleDependencies' -Module 'AzureDataLakeManagement' | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have the correct parameters' {
            $command = Get-Command -Name 'Import-ModuleDependencies'
            $command.Parameters.Keys | Should -Contain 'RequiredModules'
            $command.Parameters.Keys | Should -Contain 'Quiet'
        }
        
        It 'Should return boolean value' {
            Mock Get-Module { $null } -ParameterFilter { $ListAvailable -eq $true }
            $result = Import-ModuleDependencies -RequiredModules @('NonExistentModule') -Quiet
            $result | Should -BeOfType [System.Boolean]
        }
    }
    
    Context 'Module Manifest' {
        It 'Should declare external module dependencies in manifest' {
            $manifest = Test-ModuleManifest -Path $ModulePath
            $manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Contain 'Az.Storage'
            $manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Contain 'AzureAD'
            $manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Contain 'Az.Accounts'
        }
        
        It 'Should export dependency management functions' {
            $manifest = Test-ModuleManifest -Path $ModulePath
            $manifest.ExportedFunctions.Keys | Should -Contain 'Test-ModuleDependencies'
            $manifest.ExportedFunctions.Keys | Should -Contain 'Install-ModuleDependencies'
            $manifest.ExportedFunctions.Keys | Should -Contain 'Import-ModuleDependencies'
        }
    }
    
    Context 'Integration with Existing Functions' {
        It 'Should have updated Add-DataLakeFolder to use centralized dependency checking' {
            $functionContent = (Get-Command Add-DataLakeFolder).Definition
            $functionContent | Should -Match 'Import-ModuleDependencies'
            $functionContent | Should -Match 'Test-ModuleDependencies -AutoInstall'
        }
        
        It 'Should have updated Set-DataLakeFolderACL to use centralized dependency checking' {
            $functionContent = (Get-Command Set-DataLakeFolderACL).Definition
            $functionContent | Should -Match 'Import-ModuleDependencies'
            $functionContent | Should -Match 'Test-ModuleDependencies -AutoInstall'
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module 'AzureDataLakeManagement' -Force -ErrorAction SilentlyContinue
}