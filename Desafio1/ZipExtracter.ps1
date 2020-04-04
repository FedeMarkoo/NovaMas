cls
$ErrorActionPreference = SilentlyContinue
$file = "C:\Users\fmarkowicz\Desktop\NovaMas\Desafio1\Grande.zip"
$salida = $file.Substring(0, $file.LastIndexOf(".")) 


$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
write-host "Started at $(get-date)"
$i=0
$pass = Get-Content .\passwords1.csv
$file
foreach ($line in $pass){
    $i++;
    $line
    $cmd = "& .\7z.exe x $file -p$line -o$salida -mmt -aoa"
    if((Invoke-Expression $cmd)[12].StartsWith("Ever")){
        break
    }
}
$elapsed.Elapsed.ToString()

"Se probaron $i contraseñas"
