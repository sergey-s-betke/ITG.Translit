﻿<#
.Synopsis
   Tests for ITG.Translit.psm1 module
#>

[String] $RootPath = Split-Path -Parent ( Split-Path -Parent $Script:MyInvocation.MyCommand.Path )

$ModulePath = ( Join-Path -Path ( Join-Path -Path $RootPath -ChildPath 'ITG.Translit' ) -ChildPath 'ITG.Translit.psm1' );

# Import-Module $ModulePath -Force;

Describe 'ITG.Translit.psm1' {
	It 'Должен успешно загружаться' {
		{ Import-Module -FullyQualifiedName $ModulePath -Force -ErrorAction 'Stop' } `
		| Should -Not -Throw;
	}
}

Describe 'ConvertTo-Translit' {
	Context 'В случае, когда входные данные передаются через конвейер' {
		It 'Должен вернуть результат транслитерации' {
			'тест' `
			| ConvertTo-Translit `
			| Should -Be 'test'
		}
	}
	Context 'В случае, когда исходная строка передаётся как аргумент' {
		It 'Должен вернуть результат транслитерации' {
			ConvertTo-Translit -SourceString 'тест' `
			| Should -Be 'test'
		}
	}
	Context 'В случае, когда массив входных данных передаётся через конвейер' {
		It 'Должен вернуть массив строк после транслитерации' {
			'Бетке', 'Сергей', 'Сергеевич' `
			| ConvertTo-Translit `
			| Should -Be 'Betke', 'Sergei', 'Sergeevich'
		}
	}
	Context 'В случае, когда строка состоит из одного символа' {
		It 'Должен вернуть строку, в которой только первый символ прописной' {
			'Я', 'Ш', 'Щ' `
			| ConvertTo-Translit `
			| Should -BeExactly 'Ia', 'Sh', 'Shch'
		}
	}
	Context 'В случае, когда все символы в строке прописные' {
		It 'Должен вернуть строку, в которой все символы прописные' {
			'ЩАНОВ' `
			| ConvertTo-Translit `
			| Should -BeExactly 'SHCHANOV'
		}
	}
	Context 'В случае, когда за прописным символом идут строчные' {
		It 'Должен вернуть строку, в которой только первый символ в транслитерации прописного прописной' {
			'Щанов' `
			| ConvertTo-Translit `
			| Should -BeExactly 'Shchanov'
		}
	}
}
