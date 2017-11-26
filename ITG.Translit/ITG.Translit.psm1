Set-Variable `
	-Name 'GOST_R_52535_A1' `
	-Option ([System.Management.Automation.ScopedItemOptions]::Constant) `
	-Value @{
		'А'='A';
		'Б'='B';
		'В'='V';
		'Г'='G';
		'Д'='D';
		'Е'='E';
		'Ё'='E';
		'Ж'='ZH';
		'З'='Z';
		'И'='I';
		'Й'='I';
		'К'='K';
		'Л'='L';
		'М'='M';
		'Н'='N';
		'О'='O';
		'П'='P';
		'Р'='R';
		'С'='S';
		'Т'='T';
		'У'='U';
		'Ф'='F';
		'Х'='KH';
		'Ц'='TC';
		'Ч'='CH';
		'Ш'='SH';
		'Щ'='SHCH';
		'Ь'='';
		'Ы'='Y';
		'Ъ'='';
		'Э'='E';
		'Ю'='IU';
		'Я'='IA';
	} `
;

function ConvertTo-Translit {
	<#
		.Synopsis
			Выполняет транслитерацию исходной строки в соответствии с выбранными правилами транслитерации.
		.Description
			Данная функция выполняет транслитерацию исходной строки в соответствии с выбранными правилами транслитерации.
		.Example
			Транслитерация массива строк:
			"Бетке","Сергей","Сергеевич" | ConvertTo-Translit
	#>

	param (
		# Исходная строка, к которой будут применены правила транслитерации.
		[Parameter(
			Mandatory=$true,
			Position=0,
			ValueFromPipeline=$true
		)]
		[Alias('SourceString')]
		[Alias('String')]
		[String]$InputObject
	,
		# Таблица транслитерации.
		[Parameter(
			Mandatory=$false,
			ValueFromPipeline=$false
		)]
		$TranslitRules = $GOST_R_52535_A1
	)
	process {
		( `
			$InputObject -split '' `
			| % {
				if ( $TranslitRules.ContainsKey( $_ ) ) {
					$TraslitStr = $TranslitRules[$_];
					if ( [System.Char]::IsUpper( $_ ) ) {
						$TraslitStr.ToUpper();
					} else {
						$TraslitStr.ToLower();
					};
				} else {
					$_;
				};
			} `
		) -join '';
	}
}

function ConvertFrom-TranslitRules {
	<#
		.Synopsis
			Конвертация таблицы транслитерации (да и не только) в массив объектов с целью дальнейшей сериализации.
		.Example
			$GOST_R_52535_A1 | ConvertFrom-TranslitRules | ConvertTo-HTML -Fragment
	#>

	param (
		# Таблица транслитерации.
		[Parameter(
			Mandatory=$true,
			Position=0,
			ValueFromPipeline=$true
		)]
		$InputObject
	)

	process {
		$InputObject.keys `
		| Select-Object -Property @{
			Name='Source';
			Expression={ $_; }
		}, @{
			Name='Translit'
			Expression={ $InputObject[$_]; }
		} `
		| Sort-Object 'Source' `
		;
	}
}

Export-ModuleMember `
	ConvertTo-Translit `
	, ConvertFrom-TranslitRules `
;
