<#
.SYNOPSIS
  Интерактивный генератор «пустых» ZIP‑архивов с расширенными возможностями.
.DESCRIPTION
  Пошаговый ввод при отсутствии параметров. Логирование, вывод итоговой таблицы и ASCII‑графика.
.PARAMETER Count
  Количество файлов для создания внутри архива.
.PARAMETER PathPrefix
  Префикс пути внутри архива (директория).
.PARAMETER AutoSize
  Автоматический расчет размера файла по свободному месту.
.PARAMETER Type
  Расширение создаваемых файлов.
.PARAMETER Size
  Размер каждого файла (с суффиксом K/M/G).
.PARAMETER ChunkSizeMB
  Размер буфера для записи в мегабайтах.
.PARAMETER Compression
  Метод сжатия: Optimal, Fastest или NoCompression.
.PARAMETER Output
  Имя выходного ZIP‑файла.
.PARAMETER LogFile
  Путь к файлу логирования.
.PARAMETER DryRun
  Только вывод параметров без создания архива.
.PARAMETER Timestamp
  Установка даты и времени для файлов внутри архива.
.PARAMETER Attributes
  Список атрибутов (ReadOnly, Hidden, System, Archive) для файлов.
.PARAMETER Overwrite
  Удалить существующий архив перед созданием нового.
.PARAMETER Checksum
  Рассчитать и вывести SHA256 контрольную сумму архива.
.PARAMETER VerboseTable
  Вывести детальную таблицу с временем и скоростью записи файлов.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low', HelpUri='https://github.com/TheKilloboy/MakeSparseZip-Interactive')]
param(
    [int]      $Count = $null,
    [string]   $PathPrefix = '',
    [switch]   $AutoSize,
    [string]   $Type = 'bin',
    [string]   $Size = '1G',
    [int]      $ChunkSizeMB = 1,
    [ValidateSet('Optimal','Fastest','NoCompression')]
    [string]   $Compression = 'Optimal',
    [string]   $Output = 'output.zip',
    [string]   $LogFile = "$PSScriptRoot\MakeSparseZip.log",
    [switch]   $DryRun,
    [datetime] $Timestamp,
    [ValidateSet('ReadOnly','Hidden','System','Archive')]
    [string[]] $Attributes,
    [switch]   $Overwrite,
    [switch]   $Checksum,
    [switch]   $VerboseTable
)

function Show-Banner {
    Clear-Host
    Write-Host '╔════ Генератор ZIP ═════════╗' -ForegroundColor Cyan
    Write-Host '║  MakeSparseZip Interactive ║' -ForegroundColor Cyan
    Write-Host '╚════════════════════════════╝' -ForegroundColor Cyan
}

function Write-Log { param($Msg)
    "$((Get-Date).ToString('s')) $Msg" | Tee-Object -FilePath $LogFile -Append | Write-Verbose
}

function Convert-SizeToBytes { param($s)
    if ($s -match '^\d+$') { $s += 'M' }
    $unitChar = [string]$s.Substring($s.Length - 1, 1)
    $unit = $unitChar.ToUpper()
    $num  = [double]$s.Substring(0, $s.Length - 1)
    $map  = @{ K = 1KB; M = 1MB; G = 1GB }
    if ($map.ContainsKey($unit)) { return [int64]($num * $map[$unit]) }
    throw "Неверный формат Size: $s"
}

Show-Banner
if (-not $PSBoundParameters.Count) {
    Write-Host '1) Сколько файлов (по умолчанию 1)?' -ForegroundColor White
    Write-Host '   (Количество пустых файлов, которые будут помещены в архив)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    $Count = if ($raw) { [int]$raw } else { 1 }

    Write-Host '2) Папка внутри архива (по умолчанию корень)?' -ForegroundColor White
    Write-Host '   (Каталог, в который будут помещены файлы внутри ZIP. Пример: data/)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $PathPrefix = $raw }

    Write-Host '3) Авторазмер? Y/N (по умолчанию N)' -ForegroundColor White
    Write-Host '   (Автоматически рассчитывает размер файла по доступному месту)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $AutoSize = $true }

    Write-Host "4) Расширение файлов (по умолчанию $Type)?" -ForegroundColor White
    Write-Host '   (Тип создаваемых файлов: bin, txt, dat и т.д.)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $Type = $raw }

    if (-not $AutoSize) {
        Write-Host "5) Размер файла (по умолчанию $Size)?" -ForegroundColor White
        Write-Host '   (Размер одного файла. Пример: 100M, 1G)' -ForegroundColor DarkGray 
        $raw = Read-Host '→'
        if ($raw) { $Size = $raw }
    }

    Write-Host "6) Размер буфера MB (по умолчанию $ChunkSizeMB)?" -ForegroundColor White
    Write-Host '   (Объем памяти, используемый для записи. Влияет на производительность)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $ChunkSizeMB = [int]$raw }

    Write-Host "7) Сжатие (Optimal, Fastest, NoCompression)?" -ForegroundColor White
    Write-Host '   (Метод сжатия. Optimal — максимальное, Fastest — быстрое, NoCompression — без сжатия)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw -in 'Optimal','Fastest','NoCompression') { $Compression = $raw }

    Write-Host "8) Имя архива (по умолчанию $Output)?" -ForegroundColor White
    Write-Host '   (Полное имя выходного ZIP-файла)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $Output = $raw }

    Write-Host "9) Timestamp (YYYY-MM-DDTHH:MM:SS)?" -ForegroundColor White
    Write-Host '   (Дата и время для файлов внутри архива)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $Timestamp = [datetime]$raw }

    Write-Host "10) Атрибуты файлов (ReadOnly, Hidden, System, Archive)?" -ForegroundColor White
    Write-Host '   (Через запятую: Hidden,System и т.п.)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw) { $Attributes = $raw -split ',' }

    Write-Host '11) Перезаписать существующий архив? Y/N' -ForegroundColor White
    Write-Host '   (Удалить уже существующий ZIP, если он есть)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Overwrite = $true }

    Write-Host '12) Вычислить SHA256 контрольную сумму? Y/N' -ForegroundColor White
    Write-Host '   (Проверка целостности архива после создания)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Checksum = $true }

    Write-Host '13) Вывести детальную таблицу? Y/N' -ForegroundColor White
    Write-Host '   (Вывод статистики времени записи каждого файла)' -ForegroundColor DarkGray 
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $VerboseTable = $true }
}

# Вывод введённых параметров
$summary = [PSCustomObject]@{
    Количество=$Count; ПутьВАрхиве=$PathPrefix; Авторазмер=$AutoSize;
    Расширение=$Type; Размер=$Size; БуферMB=$ChunkSizeMB;
    Сжатие=$Compression; Архив=$Output;
    МеткаВремени=$Timestamp; Атрибуты=$Attributes;
    Перезапись=$Overwrite; КонтрольнаяСумма=$Checksum;
    ДетальныйВывод=$VerboseTable
}
$summary | Format-Table -AutoSize
Write-Log "Параметры: $($summary|Out-String)"

if ($DryRun) { Write-Host 'Режим DryRun: выход без создания архива.'; return }

# Проверка параметров и места на диске
if ($Count -lt 1) { throw 'Count должен быть > 0' }
if (-not $Output) { throw 'Output обязателен' }

# Определение диска для проверки свободного места
if ($Output -match '[\\/]') { $qual=Split-Path $Output -Qualifier } else { $qual=(Get-Location).Drive.Name+':' }
$drv=Get-PSDrive -Name $qual.TrimEnd(':')
$free=$drv.Free
if ($AutoSize) { $sizeBytes=[math]::Floor(($free-1MB)/$Count) } else { $sizeBytes=Convert-SizeToBytes $Size }
if ($free -lt ($sizeBytes*$Count)) { throw 'Недостаточно места на диске' }
Write-Log "SizeBytes=$sizeBytes"

# Удаление существующего архива при необходимости
if (Test-Path $Output) {
    if ($Overwrite) { Remove-Item $Output -Force } else { throw "$Output уже существует. Используйте -Overwrite." }
}

# Создание архива
if ($PSCmdlet.ShouldProcess($Output,'Создание архива ZIP')) {
    try {
        Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
        $fs=[IO.File]::Open($Output,'Create')
        $zip=[IO.Compression.ZipArchive]::new($fs,'Create',$false)

        # Основной цикл создания файлов
        $stats=@(); $totalBytes=$sizeBytes*$Count; $done=0
        for ($i=1; $i -le $Count; $i++) {
            $name="dummy_{0:D3}.{1}" -f $i,$Type
            if ($PathPrefix) { $name="$PathPrefix/$name" }
            $entry=$zip.CreateEntry($name)
            if ($Timestamp) { $entry.LastWriteTime=$Timestamp }
            $stream=$entry.Open()
            $buf=New-Object byte[] ($ChunkSizeMB*1MB); [void][Array]::Clear($buf,0,$buf.Length)

            $rem=$sizeBytes; $fileStart=Get-Date
            while ($rem -gt 0) {
                $w=[math]::Min($buf.Length,$rem)
                $stream.Write($buf,0,$w); $rem-=$w; $done+=$w
                $pct=[int](100*$done/$totalBytes)
                Write-Progress -Activity 'Генерация ZIP' -Status "$pct%" -PercentComplete $pct
            }
            $stream.Dispose()
            $dur=(Get-Date).Subtract($fileStart).TotalSeconds
            $stats+=[PSCustomObject]@{ Файл=$name; РазмерМБ=[math]::Round($sizeBytes/1MB,2); ВремяСек=[math]::Round($dur,2); Скорость=[math]::Round((($sizeBytes/1MB)/$dur),2) }
        }
        $zip.Dispose(); $fs.Dispose()

        # Контрольная сумма
        if ($Checksum) { $hash=Get-FileHash -Algorithm SHA256 $Output|Select-Object -Expand Hash; Write-Host "SHA256: $hash" }

        Write-Host "✔ '$Output' готов: $Count файлов по ~$([math]::Round($sizeBytes/1MB,2))МБ"
        $stats|Format-Table -AutoSize
        if ($VerboseTable) {
            Write-Host 'Время(с) | Скорость(МБ/с)'
            $stats|ForEach-Object{"{0,7:N2} | {1,7:N2}" -f $_.ВремяСек,$_.Скорость}
        }
    } catch {
        if (Test-Path $Output) { Remove-Item $Output -ErrorAction SilentlyContinue }
        throw
    }
}
