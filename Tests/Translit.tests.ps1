<#
.Synopsis
   Tests for ITG.Translit.psm1 module
#>

[String] $RootPath = Split-Path -Parent ( Split-Path -Parent $Script:MyInvocation.MyCommand.Path )

$ModulePath = ( Join-Path -Path ( Join-Path -Path $RootPath -ChildPath 'ITG.Translit' ) -ChildPath 'ITG.Translit.psm1' );

Import-Module $ModulePath -Force;

# Describe 'Модуль' {
	# It 'Должен успешно загружаться' {
		# Import-Module (Join-Path -Path $RootPath -ChildPath 'ITG.Translit.psm1') -Force `
		# | Should be 'test';
	# }
# }

Describe 'Транслитерация простой строки' {
	Context 'В случае, когда исходная строка передаётся через конвейер' {
		It 'Должна вернуть результат транслитерации' {
			'тест' | ConvertTo-Translit `
			| Should be 'test'
		}
	}
	Context 'В случае, когда исходная строка передаётся как аргумент' {
		It 'Должна вернуть результат транслитерации' {
			ConvertTo-Translit -SourceString 'тест' `
			| Should be 'test'
		}
	}
}
