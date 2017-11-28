---
external help file: ITG.Translit-help.xml
Module Name: ITG.Translit
online version: 
schema: 2.0.0
---

# ConvertTo-Translit

## SYNOPSIS
Выполняет транслитерацию исходной строки в соответствии с выбранными правилами транслитерации.

## SYNTAX

```
ConvertTo-Translit [-InputObject] <String> [-TranslitRules <Object>] [<CommonParameters>]
```

## DESCRIPTION
Данная функция выполняет транслитерацию исходной строки в соответствии с выбранными правилами транслитерации.

## EXAMPLES

### -------------------------- ПРИМЕР 1 --------------------------
```
Транслитерация массива строк:
```

"Бетке","Сергей","Сергеевич" | ConvertTo-Translit

## PARAMETERS

### -InputObject
Исходная строка, к которой будут применены правила транслитерации.

```yaml
Type: String
Parameter Sets: (All)
Aliases: String, SourceString

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TranslitRules
Таблица транслитерации.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: $GOST_R_52535_A1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

