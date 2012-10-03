Import-Module `
    (join-path `
        -path ( ( [System.IO.FileInfo] ( $myinvocation.mycommand.path ) ).directory ) `
        -childPath 'ITG.Translit' `
    ) `
    -force `
;

'Бетке','Сергей','Сергеевич' | convertTo-Translit