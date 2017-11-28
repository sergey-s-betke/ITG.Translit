---
external help file: ITG.Translit-help.xml
Module Name: ITG.Translit
online version: 
schema: 2.0.0
---

# ConvertFrom-TranslitRules

## SYNOPSIS
Конвертация таблицы транслитерации (да и не только) в массив объектов с целью дальнейшей сериализации.

## SYNTAX

```
ConvertFrom-TranslitRules [-InputObject] <Object> [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### -------------------------- ПРИМЕР 1 --------------------------
```
$GOST_R_52535_A1 | ConvertFrom-TranslitRules | ConvertTo-HTML -Fragment
```

## PARAMETERS

### -InputObject
Таблица транслитерации.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

