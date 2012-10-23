set-variable `
    -name GOST_R_52535_A1 `
    -option constant `
    -value `
    @{
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
		.Parameter String
		    Исходная строка, к которой будут применены правила транслитерации.
		.Parameter TranslitRules
			Таблица транслитерации.
		.Example
			Создание группы сервисов:
			"Бетке","Сергей","Сергеевич" | ConvertTo-Translit
	#>
	
    
    param (
		[Parameter(
			Mandatory=$true,
			Position=0,
			ValueFromPipeline=$true,
			HelpMessage='Исходная строка, к которой будут применены правила транслитерации.'
		)]
        [string]$String,
		[Parameter(
			Mandatory=$false,
			Position=1,
			ValueFromPipeline=$false,
			HelpMessage='Таблица транслитерации.'
		)]
        $TranslitRules = $GOST_R_52535_A1
	)
	process {
        ( `
            $String -split '' `
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
		.Parameter InputObject
		    Таблица транслитерации.
		.Example
            $GOST_R_52535_A1 | ConvertFrom-TranslitRules | ConvertTo-HTML -Fragment
	#>
	
    
    param (
		[Parameter(
			Mandatory=$true,
			Position=0,
			ValueFromPipeline=$true,
			HelpMessage='Таблица транслитерации.'
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
        | Sort-Object 'Source'
        ;
	}
}  

Export-ModuleMember `
    ConvertTo-Translit `
    , ConvertFrom-TranslitRules `
;
