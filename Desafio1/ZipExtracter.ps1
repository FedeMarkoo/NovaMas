cls



    $ErrorActionPreference = "SilentlyContinue"  #para que deje de mostrar mensajes de error : los prints consumen recursos
    $file = "C:\Users\fmarkowicz\Desktop\NovaMas\Desafio1\Archivo#S1.zip"
    $salida = $file.Substring(0, $file.LastIndexOf(".")) 


    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo

    write-host "Started at $(get-date)"
    $i=0
    $pass = Get-Content .\passwords-1M.csv # | Sort-Object {Get-Random}
    $file
    "tiempo consiguiendo "+$pass.Length +" contraseñas: "+$elapsed.Elapsed.ToString()
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()  #contador de tiempo
   
    $desde = 0;

    # the number of threads
    $count = 3
    $cantXJob = [int]($pass.Length/$count)+1

    $dir = (dir)[0].DirectoryName

    
# the pool will manage the parallel execution
$pool = [RunspaceFactory]::CreateRunspacePool(1, $count)

try {    
    $pool.Open()



    # create and run the jobs to be run in parallel
    $jobs = New-Object object[] $count
 
    "Creando "+($count)+" jobs de $cantXJob palabras"
    for ($jobsNumber = 0; $jobsNumber -lt $count; $jobsNumber++) {
        $ps = [PowerShell]::Create()
        $ps.RunspacePool = $pool
       
        # add the script block to run
        [void]$ps.AddScript({
            param($pass, $jobNumber, $file, $salida, $cantXJob, $dir, $jobs)
            
            $ErrorActionPreference = "SilentlyContinue"  #para que deje de mostrar mensajes de error : los prints consumen recursos
    
            $dir="C:\tempUnZiper$jobNumber"

            New-Item -Path $dir -ItemType Directory | %{$_.Attributes = "hidden"}
            #attrib +h "tempUnZiper$jobNumber" 

            $pudoDescomprimir = $false
            $i=0
            
            $init = "& C:\Users\fmarkowicz\Desktop\NovaMas\Desafio1\7z.exe x $file -p"
            
            $end = " -o$dir -mmt -aoa"
            #crear hilos para enviar secciones de 50 contraseñas (cant thread = $pass.Length/50) para mejorar esa performance
            foreach ($line in $pass){
                $i++;
                
                $cmd = $init + $line + $end
                $result = Invoke-Expression $cmd
                if(($result)[12].StartsWith("Ever")){  #el mensaje completo es "Everything is ok" pero cuando mas caracteres valida, mas consume aunque al primer fallo deja de comparar
                    $pudoDescomprimir = $true
                    "ok"
                    $line
                    break
                }
                if($i -ge $cantXJob){
                    "false"
                    break
                }
            }
            if($pudoDescomprimir){
                $index = $salida.LastIndexOf("\");
                $name = $salida.Substring($index+1)
                $salida = $salida.Substring(0,$index)
                Remove-Item "$salida\$name" -Force -Recurse
                Rename-Item -Path $dir -NewName "$name"
                attrib -h "C:\$name"                
                Move-Item -path "C:\$name" -Destination $salida 
            }
        })

        
        $desde = $cantXJob * $jobsNumber
        $hasta = $desde+$cantXJob-1
        $copy = $pass[$desde..$hasta]


        # optional: add parameters
        [void]$ps.AddParameter("pass", $copy)
        [void]$ps.AddParameter("jobNumber", $jobsNumber)
        [void]$ps.AddParameter("file", $file)
        [void]$ps.AddParameter("salida", $salida)
        [void]$ps.AddParameter("cantXJob", $cantXJob)
        [void]$ps.AddParameter("dir", $dir)
        [void]$ps.AddParameter("jobs", $jobs)


        # start async execution
        $jobs[$jobsNumber] = [PSCustomObject]@{
            PowerShell = $ps
            AsyncResult = $ps.BeginInvoke()
        }
    }

    $isAllCompl = $false
    $isCompleted = $false
    while(-not $isCompleted -and -not $isAllCompl ){
        sleep -Milliseconds 500
        $isAllCompl = $true
        foreach ($job in $jobs) {
            try {
                if($job.AsyncResult.IsCompleted){
                    $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                    $isCompleted = $result[0].StartsWith("ok")
                }else{
                    $isAllCompl = $false
                }
                if($isCompleted){
                    $jobNum = $job.PowerShell.Commands.Commands.parameters.GetValue(1).value
                    "Se logro descomprimir el archivo en el Job $jobNum con contraseña "+$result[1]
                    break
                }
            }catch {}
        }
    }
    $elapsed.Elapsed.ToString()
    foreach ($job in $jobs) {
        $job.PowerShell.Dispose()
    }
    Remove-Item "C:\tempUnZiper*" -Force -Recurse
}
finally {
    $pool.Dispose()
}
$elapsed.Elapsed.ToString()
