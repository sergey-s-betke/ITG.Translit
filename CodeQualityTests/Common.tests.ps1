<#
.Synopsis
   PSScriptAnalyzer tests
#>

[String] $RootPath = Split-Path -Parent ( Split-Path -Parent $Script:MyInvocation.MyCommand.Path )

$ModuleDirPath = Join-Path -Path $RootPath -ChildPath 'ITG.Translit';

Describe 'PSScriptAnalyzer' {    
	It '<RuleName>' -TestCases @(
		Get-ScriptAnalyzerRule `
		| ForEach-Object { @{ RuleName = $_.RuleName; Rule = $_; } } 
	) {
		param( $Rule )
		Invoke-ScriptAnalyzer `
			-Path ( Join-Path -Path $ModuleDirPath -ChildPath '*.*' ) `
			-IncludeRule $Rule.RuleName `
		| ForEach-Object {
			@"

$($_.Message)
$($_.SuggestedCorrections.Description)

$($_.ScriptName): строка $($_.Line)

"@
		} `
		| Should BeNullOrEmpty
	}
}
