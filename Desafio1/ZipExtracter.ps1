cls
$ErrorActionPreference = "SilentlyContinue"  #para que deje de mostrar mensajes de error : los prints consumen recursos
$file = "C:\Users\fmarkowicz\Desktop\NovaMas\Desafio1\Desafio2.zip"
$salida = $file.Substring(0, $file.LastIndexOf(".")) 


$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo

write-host "Started at $(get-date)"
$i=0
$pass = Get-Content .\passwords1.csv
$file
$cantXJob = 50
"tiempo consiguiendo "+$pass.Length +" contraseñas: "+$elapsed.Elapsed.ToString()
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo
$jobsNumber = 1;
$desde = 0;
while($desde -lt $pass.Length){
    [array]$copy;
    $pass.CopyTo($copy,$desde);
    "creando job $jobsNumber"
    Start-ThreadJob -ScriptBlock {
        "corriendo job $jobNumber"
        $pudoDescomprimir = $false
        #crear hilos para enviar secciones de 50 contraseñas (cant thread = $pass.Length/50) para mejorar esa performance
        foreach ($line in $pass){
            $i++;
            $cmd = "& .\7z.exe x $file -p$line -o$salida -mmt -aoa"
            if((Invoke-Expression $cmd)[12].StartsWith("Ever")){  #el mensaje completo es "Everything is ok" pero cuando mas caracteres valida, mas consume aunque al primer fallo deja de comparar
                $pudoDescomprimir = $true
                #matas todos los hilos del array
                break
            }
            if($i -eq 50){
                break
            }
        }
        if($pudoDescomprimir){
            "Se probaron $i contraseñas en el job numero $jobNumber, siendo $line la correcta"
        }else{
            "Se probaron $i contraseñas en el job numero $jobNumber sin exito"
        }

        return $pudoDescomprimir
    } -ThrottleLimit 2  |Wait-Job
    $desde = $cantXJob * $jobsNumber 
    $jobsNumber++;
}

$elapsed.Elapsed.ToString()






function unZip($pass, $jobNumber){
"corriendo job $jobNumber"
    $pudoDescomprimir = $false
    #crear hilos para enviar secciones de 50 contraseñas (cant thread = $pass.Length/50) para mejorar esa performance
    foreach ($line in $pass){
        $i++;
        $cmd = "& .\7z.exe x $file -p$line -o$salida -mmt -aoa"
        if((Invoke-Expression $cmd)[12].StartsWith("Ever")){  #el mensaje completo es "Everything is ok" pero cuando mas caracteres valida, mas consume aunque al primer fallo deja de comparar
            $pudoDescomprimir = $true
            #matas todos los hilos del array
            break
        }
        if($i -eq 50){
            break
        }
    }
    if($pudoDescomprimir){
        "Se probaron $i contraseñas en el job numero $jobNumber, siendo $line la correcta"
    }else{
        "Se probaron $i contraseñas en el job numero $jobNumber sin exito"
    }

    return $pudoDescomprimir
}