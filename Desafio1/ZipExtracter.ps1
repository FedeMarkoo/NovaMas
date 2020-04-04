cls
$ErrorActionPreference = "SilentlyContinue"  #para que deje de mostrar mensajes de error : los prints consumen recursos
$file = "C:\Users\fmarkowicz\Desktop\NovaMas\Desafio1\Archivo #S1.zip"
$salida = $file.Substring(0, $file.LastIndexOf(".")) 


$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo

write-host "Started at $(get-date)"
$i=0
$pass = Get-Content .\passwords1.csv
$file
$pudoDescomprimir = $false
"tiempo consiguiendo contraseñas: "+$elapsed.Elapsed.ToString()
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo
#crear hilos para enviar secciones de 50 contraseñas (cant thread = $pass.Length/50) para mejorar esa performance
foreach ($line in $pass){
    $i++;
    $cmd = "& .\7z.exe x $file -p$line -o$salida -mmt -aoa"
    if((Invoke-Expression $cmd)[12].StartsWith("Ever")){  #el mensaje completo es "Everything is ok" pero cuando mas caracteres valida, mas consume aunque al primer fallo deja de comparar
        $pudoDescomprimir = $true
        break
    }
}
$elapsed.Elapsed.ToString()
if($pudoDescomprimir){
    "Se probaron $i contraseñas con exito"
}else{
    "Se probaron $i contraseñas sin exito"
}
