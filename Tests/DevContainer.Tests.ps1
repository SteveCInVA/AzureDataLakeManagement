#Requires -Modules Pester

BeforeAll {
    $DevContainerPath = Join-Path $PSScriptRoot '..' '.devcontainer' 'devcontainer.json'
}

Describe 'DevContainer Configuration' {
    
    Context 'File Existence' {
        It 'Should have a devcontainer.json file' {
            Test-Path $DevContainerPath | Should -BeTrue
        }
    }
    
    Context 'Configuration Content' {
        BeforeAll {
            # Read and parse the devcontainer.json file (JSONC - JSON with Comments)
            $content = Get-Content $DevContainerPath -Raw
            # Remove single-line comments more carefully (avoid URLs with //)
            $lines = $content -split "`n"
            $cleanedLines = @()
            foreach ($line in $lines) {
                # Skip comment-only lines
                if ($line -match '^\s*//') {
                    continue
                }
                # Remove trailing comments but preserve URLs and quoted strings
                # Match everything before comment outside of quotes
                elseif ($line -match '^([^"]*"[^"]*"[^"]*)\s*//' -or $line -match '^(.*[^:])\s*//') {
                    # Keep content before comment, but be careful with URLs
                    if ($line -notmatch '"https?://') {
                        $cleanedLines += $matches[1]
                    }
                    else {
                        # Line contains URL, keep it as-is
                        $cleanedLines += $line
                    }
                }
                else {
                    # Keep line as-is
                    $cleanedLines += $line
                }
            }
            $jsonContent = $cleanedLines -join "`n"
            $config = $jsonContent | ConvertFrom-Json
        }
        
        It 'Should have a name property' {
            $config.name | Should -Not -BeNullOrEmpty
        }
        
        It 'Should specify PowerShell feature' {
            $config.features.PSObject.Properties.Name | Should -Contain 'ghcr.io/devcontainers/features/powershell:1'
        }
        
        It 'Should have PowerShell extension configured' {
            $config.customizations.vscode.extensions | Should -Contain 'ms-vscode.powershell'
        }
        
        It 'Should have Pester Test extension configured' {
            $config.customizations.vscode.extensions | Should -Contain 'pspester.pester-test'
        }
        
        It 'Should have GitHub Copilot extension configured' {
            $config.customizations.vscode.extensions | Should -Contain 'github.copilot'
        }
        
        It 'Should have GitHub Actions extension configured' {
            $config.customizations.vscode.extensions | Should -Contain 'github.vscode-github-actions'
        }
        
        It 'Should have TODO Highlight extension configured' {
            $config.customizations.vscode.extensions | Should -Contain 'jgclark.vscode-todo-highlight'
        }
        
        It 'Should install PSScriptAnalyzer and Pester in postCreateCommand' {
            $config.postCreateCommand | Should -Match 'PSScriptAnalyzer'
            $config.postCreateCommand | Should -Match 'Pester'
        }
        
        It 'Should set PowerShell as default terminal' {
            $config.customizations.vscode.settings.'terminal.integrated.defaultProfile.linux' | Should -Be 'pwsh'
        }
    }
}
