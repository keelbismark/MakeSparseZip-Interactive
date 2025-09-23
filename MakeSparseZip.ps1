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
    [switch]   $VerboseTable,
    [ValidateSet('ru', 'en')]
    [string]   $Language = 'ru'
)

# --- Localization ---
$uiStrings = @{
    ru = @{
        # Banner
        bannerTitle = 'Генератор ZIP'
        # Prompts
        promptCount_q = '1) Сколько файлов (по умолчанию 1)?'
        promptCount_d = '   (Количество пустых файлов, которые будут помещены в архив)'
        promptPath_q = '2) Папка внутри архива (по умолчанию корень)?'
        promptPath_d = '   (Каталог, в который будут помещены файлы внутри ZIP. Пример: data/)'
        promptAutoSize_q = '3) Авторазмер? Y/N (по умолчанию N)'
        promptAutoSize_d = '   (Автоматически рассчитывает размер файла по доступному месту)'
        promptType_q = "4) Расширение файлов (по умолчанию {0})?"
        promptType_d = '   (Тип создаваемых файлов: bin, txt, dat и т.д.)'
        promptSize_q = "5) Размер файла (по умолчанию {0})?"
        promptSize_d = '   (Размер одного файла. Пример: 100M, 1G)'
        promptChunk_q = "6) Размер буфера MB (по умолчанию {0})?"
        promptChunk_d = '   (Объем памяти, используемый для записи. Влияет на производительность)'
        promptCompression_q = "7) Сжатие (Optimal, Fastest, NoCompression)?"
        promptCompression_d = '   (Метод сжатия. Optimal — максимальное, Fastest — быстрое, NoCompression — без сжатия)'
        promptOutput_q = "8) Имя архива (по умолчанию {0})?"
        promptOutput_d = '   (Полное имя выходного ZIP-файла)'
        promptTimestamp_q = "9) Timestamp (YYYY-MM-DDTHH:MM:SS)?"
        promptTimestamp_d = '   (Дата и время для файлов внутри архива)'
        promptAttributes_q = "10) Атрибуты файлов (ReadOnly, Hidden, System, Archive)?"
        promptAttributes_d = '   (Через запятую: Hidden,System и т.п.)'
        promptOverwrite_q = '11) Перезаписать существующий архив? Y/N'
        promptOverwrite_d = '   (Удалить уже существующий ZIP, если он есть)'
        promptChecksum_q = '12) Вычислить SHA256 контрольную сумму? Y/N'
        promptChecksum_d = '   (Проверка целостности архива после создания)'
        promptVerbose_q = '13) Вывести детальную таблицу? Y/N'
        promptVerbose_d = '   (Вывод статистики времени записи каждого файла)'
        promptArrow = '→'
        # Summary table headers
        summaryCount = 'Количество'
        summaryPath = 'ПутьВАрхиве'
        summaryAutoSize = 'Авторазмер'
        summaryExt = 'Расширение'
        summarySize = 'Размер'
        summaryChunk = 'БуферMB'
        summaryCompression = 'Сжатие'
        summaryArchive = 'Архив'
        summaryTimestamp = 'МеткаВремени'
        summaryAttributes = 'Атрибуты'
        summaryOverwrite = 'Перезапись'
        summaryChecksum = 'КонтрольнаяСумма'
        summaryVerbose = 'ДетальныйВывод'
        # Log messages
        logParams = 'Параметры:'
        # Status messages
        dryRunExit = 'Режим DryRun: выход без создания архива.'
        creatingArchive = 'Создание архива ZIP'
        generatingZip = 'Генерация ZIP'
        sha256sum = 'SHA256'
        doneMessage = "✔ ''{0}'' готов: {1} файлов по ~{2}МБ"
        # Stats table
        statsFile = 'Файл'
        statsSizeMB = 'РазмерМБ'
        statsTimeSec = 'ВремяСек'
        statsSpeed = 'Скорость'
        statsVerboseHeader = 'Время(с) | Скорость(МБ/с)'
        # Errors
        errorInvalidSize = "Неверный формат Size: {0}"
        errorCountPositive = 'Count должен быть > 0'
        errorOutputRequired = 'Output обязателен'
        errorNoSpace = 'Недостаточно места на диске'
        errorExists = "'{0}' уже существует. Используйте -Overwrite."
    }
    en = @{
        # Banner
        bannerTitle = 'ZIP Generator'
        # Prompts
        promptCount_q = '1) How many files (default 1)?'
        promptCount_d = '   (Number of empty files to be placed in the archive)'
        promptPath_q = '2) Folder inside the archive (default root)?'
        promptPath_d = '   (Directory where files will be placed inside the ZIP. Example: data/)'
        promptAutoSize_q = '3) Auto-size? Y/N (default N)'
        promptAutoSize_d = '   (Automatically calculates file size based on available space)'
        promptType_q = "4) File extension (default {0})?"
        promptType_d = '   (Type of files to create: bin, txt, dat, etc.)'
        promptSize_q = "5) File size (default {0})?"
        promptSize_d = '   (Size of a single file. Example: 100M, 1G)'
        promptChunk_q = "6) Buffer size in MB (default {0})?"
        promptChunk_d = '   (Amount of memory used for writing. Affects performance)'
        promptCompression_q = "7) Compression (Optimal, Fastest, NoCompression)?"
        promptCompression_d = '   (Compression method. Optimal - maximum, Fastest - fast, NoCompression - none)'
        promptOutput_q = "8) Archive name (default {0})?"
        promptOutput_d = '   (Full name of the output ZIP file)'
        promptTimestamp_q = "9) Timestamp (YYYY-MM-DDTHH:MM:SS)?"
        promptTimestamp_d = '   (Date and time for files inside the archive)'
        promptAttributes_q = "10) File attributes (ReadOnly, Hidden, System, Archive)?"
        promptAttributes_d = '   (Comma-separated: Hidden,System,etc.)'
        promptOverwrite_q = '11) Overwrite existing archive? Y/N'
        promptOverwrite_d = '   (Delete the existing ZIP file if it exists)'
        promptChecksum_q = '12) Calculate SHA256 checksum? Y/N'
        promptChecksum_d = '   (Verify archive integrity after creation)'
        promptVerbose_q = '13) Display detailed table? Y/N'
        promptVerbose_d = '   (Output statistics of write time for each file)'
        promptArrow = '→'
        # Summary table headers
        summaryCount = 'Count'
        summaryPath = 'PathInArchive'
        summaryAutoSize = 'AutoSize'
        summaryExt = 'Extension'
        summarySize = 'Size'
        summaryChunk = 'BufferMB'
        summaryCompression = 'Compression'
        summaryArchive = 'Archive'
        summaryTimestamp = 'Timestamp'
        summaryAttributes = 'Attributes'
        summaryOverwrite = 'Overwrite'
        summaryChecksum = 'Checksum'
        summaryVerbose = 'VerboseOutput'
        # Log messages
        logParams = 'Parameters:'
        # Status messages
        dryRunExit = 'DryRun mode: exiting without creating archive.'
        creatingArchive = 'Creating ZIP archive'
        generatingZip = 'Generating ZIP'
        sha256sum = 'SHA256'
        doneMessage = "✔ ''{0}'' is ready: {1} files of ~{2}MB each"
        # Stats table
        statsFile = 'File'
        statsSizeMB = 'SizeMB'
        statsTimeSec = 'TimeSec'
        statsSpeed = 'Speed'
        statsVerboseHeader = 'Time(s) | Speed(MB/s)'
        # Errors
        errorInvalidSize = "Invalid Size format: {0}"
        errorCountPositive = 'Count must be > 0'
        errorOutputRequired = 'Output is required'
        errorNoSpace = 'Not enough disk space'
        errorExists = "'{0}' already exists. Use -Overwrite."
    }
}
$s = $uiStrings[$Language]

function Get-String { param([string]$key, [object[]]$formatArgs)
    $template = $s[$key]
    if ($formatArgs) {
        return $template -f $formatArgs
    } else {
        return $template
    }
}
# --- End Localization ---

function Show-Banner {
    Clear-Host
    Write-Host "╔════ $($s.bannerTitle) ═════════╗" -ForegroundColor Cyan
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
    throw (Get-String 'errorInvalidSize' $s)
}

Show-Banner
if (($PSBoundParameters.Count -eq 0) -or ($PSBoundParameters.Count -eq 1 -and $PSBoundParameters.ContainsKey('Language'))) {
    Write-Host (Get-String 'promptCount_q') -ForegroundColor White
    Write-Host (Get-String 'promptCount_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    $Count = if ($raw) { [int]$raw } else { 1 }

    Write-Host (Get-String 'promptPath_q') -ForegroundColor White
    Write-Host (Get-String 'promptPath_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $PathPrefix = $raw }

    Write-Host (Get-String 'promptAutoSize_q') -ForegroundColor White
    Write-Host (Get-String 'promptAutoSize_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw -match '^[Yy]') { $AutoSize = $true }

    Write-Host (Get-String 'promptType_q' $Type) -ForegroundColor White
    Write-Host (Get-String 'promptType_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $Type = $raw }

    if (-not $AutoSize) {
        Write-Host (Get-String 'promptSize_q' $Size) -ForegroundColor White
        Write-Host (Get-String 'promptSize_d') -ForegroundColor DarkGray
        $raw = Read-Host (Get-String 'promptArrow')
        if ($raw) { $Size = $raw }
    }

    Write-Host (Get-String 'promptChunk_q' $ChunkSizeMB) -ForegroundColor White
    Write-Host (Get-String 'promptChunk_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $ChunkSizeMB = [int]$raw }

    Write-Host (Get-String 'promptCompression_q') -ForegroundColor White
    Write-Host (Get-String 'promptCompression_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw -in 'Optimal','Fastest','NoCompression') { $Compression = $raw }

    Write-Host (Get-String 'promptOutput_q' $Output) -ForegroundColor White
    Write-Host (Get-String 'promptOutput_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $Output = $raw }

    Write-Host (Get-String 'promptTimestamp_q') -ForegroundColor White
    Write-Host (Get-String 'promptTimestamp_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $Timestamp = [datetime]$raw }

    Write-Host (Get-String 'promptAttributes_q') -ForegroundColor White
    Write-Host (Get-String 'promptAttributes_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw) { $Attributes = $raw -split ',' }

    Write-Host (Get-String 'promptOverwrite_q') -ForegroundColor White
    Write-Host (Get-String 'promptOverwrite_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw -match '^[Yy]') { $Overwrite = $true }

    Write-Host (Get-String 'promptChecksum_q') -ForegroundColor White
    Write-Host (Get-String 'promptChecksum_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw -match '^[Yy]') { $Checksum = $true }

    Write-Host (Get-String 'promptVerbose_q') -ForegroundColor White
    Write-Host (Get-String 'promptVerbose_d') -ForegroundColor DarkGray
    $raw = Read-Host (Get-String 'promptArrow')
    if ($raw -match '^[Yy]') { $VerboseTable = $true }
}

# Вывод введённых параметров
$summaryHashtable = [ordered]@{
    ($s.summaryCount)       = $Count
    ($s.summaryPath)        = $PathPrefix
    ($s.summaryAutoSize)    = $AutoSize
    ($s.summaryExt)         = $Type
    ($s.summarySize)        = $Size
    ($s.summaryChunk)       = $ChunkSizeMB
    ($s.summaryCompression) = $Compression
    ($s.summaryArchive)     = $Output
    ($s.summaryTimestamp)   = $Timestamp
    ($s.summaryAttributes)  = $Attributes
    ($s.summaryOverwrite)   = $Overwrite
    ($s.summaryChecksum)    = $Checksum
    ($s.summaryVerbose)     = $VerboseTable
}
$summary = [PSCustomObject]$summaryHashtable
$summary | Format-Table -AutoSize
Write-Log ((Get-String 'logParams') + " $($summary|Out-String)")

if ($DryRun) { Write-Host (Get-String 'dryRunExit'); return }

# Проверка параметров и места на диске
if ($Count -lt 1) { throw (Get-String 'errorCountPositive') }
if (-not $Output) { throw (Get-String 'errorOutputRequired') }

# Определение диска для проверки свободного места
if ($Output -match '[\\/]') { $qual=Split-Path $Output -Qualifier } else { $qual=(Get-Location).Drive.Name+':' }
$drv=Get-PSDrive -Name $qual.TrimEnd(':')
$free=$drv.Free
if ($AutoSize) { $sizeBytes=[math]::Floor(($free-1MB)/$Count) } else { $sizeBytes=Convert-SizeToBytes $Size }
if ($free -lt ($sizeBytes*$Count)) { throw (Get-String 'errorNoSpace') }
Write-Log "SizeBytes=$sizeBytes"

# Удаление существующего архива при необходимости
if (Test-Path $Output) {
    if ($Overwrite) { Remove-Item $Output -Force } else { throw (Get-String 'errorExists' $Output) }
}

# Создание архива
if ($PSCmdlet.ShouldProcess($Output, (Get-String 'creatingArchive'))) {
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
                Write-Progress -Activity (Get-String 'generatingZip') -Status "$pct%" -PercentComplete $pct
            }
            $stream.Dispose()
            $dur=(Get-Date).Subtract($fileStart).TotalSeconds

            $statEntry = [ordered]@{
                ($s.statsFile)   = $name
                ($s.statsSizeMB) = [math]::Round($sizeBytes/1MB,2)
                ($s.statsTimeSec) = [math]::Round($dur,2)
                ($s.statsSpeed)  = [math]::Round((($sizeBytes/1MB)/$dur),2)
            }
            $stats += [PSCustomObject]$statEntry
        }
        $zip.Dispose(); $fs.Dispose()

        # Контрольная сумма
        if ($Checksum) { $hash=Get-FileHash -Algorithm SHA256 $Output|Select-Object -Expand Hash; Write-Host "$((Get-String 'sha256sum')): $hash" }

        Write-Host (Get-String 'doneMessage' @($Output, $Count, [math]::Round($sizeBytes/1MB,2)))
        $stats|Format-Table -AutoSize
        if ($VerboseTable) {
            Write-Host (Get-String 'statsVerboseHeader')
            $stats|ForEach-Object{"{0,7:N2} | {1,7:N2}" -f $_.($s.statsTimeSec), $_.($s.statsSpeed)}
        }
    } catch {
        if (Test-Path $Output) { Remove-Item $Output -ErrorAction SilentlyContinue }
        throw
    }
}
