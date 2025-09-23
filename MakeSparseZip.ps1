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
    [switch]   $RandomContent,
    [int]      $RandomSeed = 0,
    [string]   $RandomSize = '',
    [ValidateSet('ru-RU', 'en-US')]
    [string]   $Culture = 'ru-RU'
)

#region Localization
$uiStrings = @{
    # Banner
    BannerTitle = @{ 'ru-RU' = 'Генератор ZIP'; 'en-US' = 'ZIP Generator' }
    # Interactive Prompts
    PromptFileCount       = @{ 'ru-RU' = '1) Сколько файлов (по умолчанию 1)?'; 'en-US' = '1) Number of files (default 1)?' }
    PromptFileCountHelp   = @{ 'ru-RU' = '   (Количество пустых файлов, которые будут помещены в архив)'; 'en-US' = '   (The number of empty files that will be placed in the archive)' }
    PromptPathPrefix      = @{ 'ru-RU' = '2) Папка внутри архива (по умолчанию корень)?'; 'en-US' = '2) Folder inside archive (default is root)?' }
    PromptPathPrefixHelp  = @{ 'ru-RU' = '   (Каталог, в который будут помещены файлы внутри ZIP. Пример: data/)'; 'en-US' = '   (Directory where files will be placed inside the ZIP. Example: data/)'}
    PromptAutoSize        = @{ 'ru-RU' = '3) Авторазмер? Y/N (по умолчанию N)'; 'en-US' = '3) Auto-size? Y/N (default N)' }
    PromptAutoSizeHelp    = @{ 'ru-RU' = '   (Автоматически рассчитывает размер файла по доступному месту)'; 'en-US' = '   (Automatically calculates file size based on available space)'}
    PromptType            = @{ 'ru-RU' = "4) Расширение файлов (по умолчанию {0})?"; 'en-US' = "4) File extension (default {0})?" }
    PromptTypeHelp        = @{ 'ru-RU' = '   (Тип создаваемых файлов: bin, txt, dat и т.д.)'; 'en-US' = '   (Type of files to create: bin, txt, dat, etc.)'}
    PromptRandomSize      = @{ 'ru-RU' = '5a) Случайный размер (min:max, например 10M:100M)?'; 'en-US' = '5a) Random size (min:max, e.g. 10M:100M)?' }
    PromptRandomSizeHelp  = @{ 'ru-RU' = '   (Устанавливает случайный размер для каждого файла в диапазоне. Оставьте пустым для фиксированного размера)'; 'en-US' = '   (Sets a random size for each file in a range. Leave empty for fixed size)'}
    PromptSize            = @{ 'ru-RU' = "5b) Размер файла (по умолчанию {0})?"; 'en-US' = "5b) File size (default {0})?" }
    PromptSizeHelp        = @{ 'ru-RU' = '   (Размер одного файла. Пример: 100M, 1G)'; 'en-US' = '   (Size of a single file. Example: 100M, 1G)'}
    PromptChunkSize       = @{ 'ru-RU' = "6) Размер буфера MB (по умолчанию {0})?"; 'en-US' = "6) Buffer size MB (default {0})?" }
    PromptChunkSizeHelp   = @{ 'ru-RU' = '   (Объем памяти, используемый для записи. Влияет на производительность)'; 'en-US' = '   (Amount of memory used for writing. Affects performance)'}
    PromptCompression     = @{ 'ru-RU' = '7) Сжатие (Optimal, Fastest, NoCompression)?'; 'en-US' = '7) Compression (Optimal, Fastest, NoCompression)?' }
    PromptCompressionHelp = @{ 'ru-RU' = '   (Метод сжатия. Optimal — максимальное, Fastest — быстрое, NoCompression — без сжатия)'; 'en-US' = '   (Compression method. Optimal - maximum, Fastest - fast, NoCompression - none)'}
    PromptOutput          = @{ 'ru-RU' = "8) Имя архива (по умолчанию {0})?"; 'en-US' = "8) Archive name (default {0})?" }
    PromptOutputHelp      = @{ 'ru-RU' = '   (Полное имя выходного ZIP-файла)'; 'en-US' = '   (Full name of the output ZIP file)'}
    PromptTimestamp       = @{ 'ru-RU' = '9) Timestamp (YYYY-MM-DDTHH:MM:SS)?'; 'en-US' = '9) Timestamp (YYYY-MM-DDTHH:MM:SS)?' }
    PromptTimestampHelp   = @{ 'ru-RU' = '   (Дата и время для файлов внутри архива)'; 'en-US' = '   (Date and time for files inside the archive)'}
    PromptAttributes      = @{ 'ru-RU' = '10) Атрибуты файлов (ReadOnly, Hidden, System, Archive)?'; 'en-US' = '10) File attributes (ReadOnly, Hidden, System, Archive)?' }
    PromptAttributesHelp  = @{ 'ru-RU' = '   (Через запятую: Hidden,System и т.п.)'; 'en-US' = '   (Comma-separated: Hidden,System, etc.)'}
    PromptOverwrite       = @{ 'ru-RU' = '11) Перезаписать существующий архив? Y/N'; 'en-US' = '11) Overwrite existing archive? Y/N' }
    PromptOverwriteHelp   = @{ 'ru-RU' = '   (Удалить уже существующий ZIP, если он есть)'; 'en-US' = '   (Delete the ZIP if it already exists)'}
    PromptChecksum        = @{ 'ru-RU' = '12) Вычислить SHA256 контрольную сумму? Y/N'; 'en-US' = '12) Calculate SHA256 checksum? Y/N' }
    PromptChecksumHelp    = @{ 'ru-RU' = '   (Проверка целостности архива после создания)'; 'en-US' = '   (Verify archive integrity after creation)'}
    PromptVerboseTable    = @{ 'ru-RU' = '13) Вывести детальную таблицу? Y/N'; 'en-US' = '13) Show detailed table? Y/N' }
    PromptVerboseTableHelp= @{ 'ru-RU' = '   (Вывод статистики времени записи каждого файла)'; 'en-US' = '   (Output timing statistics for each file)'}
    PromptRandomContent   = @{ 'ru-RU' = '14) Случайное содержимое файлов? Y/N'; 'en-US' = '14) Random file content? Y/N' }
    PromptRandomContentHelp = @{ 'ru-RU' = '   (Заполнить файлы случайными данными вместо нулей)'; 'en-US' = '   (Fill files with random data instead of zeros)'}
    PromptRandomSeed      = @{ 'ru-RU' = '15) Seed для генератора случайных чисел (0 — нет)?'; 'en-US' = '15) Seed for random number generator (0 for none)?' }
    PromptRandomSeedHelp  = @{ 'ru-RU' = '   (Позволяет генерировать одинаковые "случайные" данные)'; 'en-US' = '   (Allows generating identical "random" data)'}
    # Errors and Messages
    ErrorInvalidSize      = @{ 'ru-RU' = "Неверный формат Size: {0}"; 'en-US' = "Invalid Size format: {0}" }
    ErrorDryRun           = @{ 'ru-RU' = 'Режим DryRun: выход без создания архива.'; 'en-US' = 'DryRun mode: exiting without creating archive.' }
    ErrorCountPositive    = @{ 'ru-RU' = 'Count должен быть > 0'; 'en-US' = 'Count must be > 0' }
    ErrorOutputRequired   = @{ 'ru-RU' = 'Output обязателен'; 'en-US' = 'Output is required' }
    ErrorAutoSizeAndRandom= @{ 'ru-RU' = 'Нельзя использовать -AutoSize и -RandomSize одновременно.'; 'en-US' = 'Cannot use -AutoSize and -RandomSize simultaneously.' }
    ErrorSizeAndRandom    = @{ 'ru-RU' = 'Нельзя использовать -Size и -RandomSize одновременно.'; 'en-US' = 'Cannot use -Size and -RandomSize simultaneously.' }
    ErrorInvalidRandomSize= @{ 'ru-RU' = "Неверный формат RandomSize: {0}. Ожидается 'min:max'."; 'en-US' = "Invalid RandomSize format: {0}. Expected 'min:max'." }
    ErrorMinMaxSize       = @{ 'ru-RU' = 'Минимальный размер должен быть меньше максимального в RandomSize.'; 'en-US' = 'Minimum size must be less than maximum in RandomSize.' }
    ErrorNoDiskSpace      = @{ 'ru-RU' = "Недостаточно места на диске. Требуется: {0}MB, Доступно: {1}MB"; 'en-US' = "Not enough disk space. Required: {0}MB, Available: {1}MB" }
    ErrorFileExists       = @{ 'ru-RU' = "{0} уже существует. Используйте -Overwrite."; 'en-US' = "{0} already exists. Use -Overwrite." }
    MsgReady              = @{ 'ru-RU' = "✔ '{0}' готов: {1} файлов, средний размер ~{2}МБ"; 'en-US' = "✔ '{0}' is ready: {1} files, average size ~{2}MB" }
    MsgCreatingArchive    = @{ 'ru-RU' = 'Создание архива ZIP'; 'en-US' = 'Creating ZIP archive' }
    MsgProgressActivity   = @{ 'ru-RU' = 'Генерация ZIP'; 'en-US' = 'Generating ZIP' }
    # Table Headers
    HeaderCount           = @{ 'ru-RU' = 'Количество'; 'en-US' = 'Count' }
    HeaderPathInArchive   = @{ 'ru-RU' = 'ПутьВАрхиве'; 'en-US' = 'PathInArchive' }
    HeaderAutoSize        = @{ 'ru-RU' = 'Авторазмер'; 'en-US' = 'AutoSize' }
    HeaderExtension       = @{ 'ru-RU' = 'Расширение'; 'en-US' = 'Extension' }
    HeaderSize            = @{ 'ru-RU' = 'Размер'; 'en-US' = 'Size' }
    HeaderRandomSize      = @{ 'ru-RU' = 'СлучайныйРазмер'; 'en-US' = 'RandomSize' }
    HeaderBufferMB        = @{ 'ru-RU' = 'БуферMB'; 'en-US' = 'BufferMB' }
    HeaderCompression     = @{ 'ru-RU' = 'Сжатие'; 'en-US' = 'Compression' }
    HeaderArchive         = @{ 'ru-RU' = 'Архив'; 'en-US' = 'Archive' }
    HeaderTimestamp       = @{ 'ru-RU' = 'МеткаВремени'; 'en-US' = 'Timestamp' }
    HeaderAttributes      = @{ 'ru-RU' = 'Атрибуты'; 'en-US' = 'Attributes' }
    HeaderOverwrite       = @{ 'ru-RU' = 'Перезапись'; 'en-US' = 'Overwrite' }
    HeaderChecksum        = @{ 'ru-RU' = 'КонтрольнаяСумма'; 'en-US' = 'Checksum' }
    HeaderVerbose         = @{ 'ru-RU' = 'ДетальныйВывод'; 'en-US' = 'VerboseOutput' }
    HeaderRandomContent   = @{ 'ru-RU' = 'СлучайноеСодержимое'; 'en-US' = 'RandomContent' }
    HeaderSeed            = @{ 'ru-RU' = 'Seed'; 'en-US' = 'Seed' }
    HeaderLogParameters   = @{ 'ru-RU' = 'Параметры'; 'en-US' = 'Parameters' }
    StatsHeaderFile       = @{ 'ru-RU' = 'Файл'; 'en-US' = 'File' }
    StatsHeaderSizeMB     = @{ 'ru-RU' = 'РазмерМБ'; 'en-US' = 'SizeMB' }
    StatsHeaderTimeSec    = @{ 'ru-RU' = 'ВремяСек'; 'en-US' = 'TimeSec' }
    StatsHeaderSpeed      = @{ 'ru-RU' = 'Скорость'; 'en-US' = 'Speed' }
    StatsHeaderSpeedVerbose = @{ 'ru-RU' = 'Время(с) | Скорость(МБ/с)'; 'en-US' = 'Time(s) | Speed(MB/s)' }
}

function Get-String { param($Key)
    if ($uiStrings.ContainsKey($Key) -and $uiStrings[$Key].ContainsKey($Culture)) {
        return $uiStrings[$Key][$Culture]
    }
    return "!!$Key!!" # Return key as fallback
}
#endregion

#region Helper Functions
function Show-Banner {
    Clear-Host
    Write-Host "╔════ $(Get-String 'BannerTitle') ═════════╗" -ForegroundColor Cyan
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
    throw ((Get-String 'ErrorInvalidSize') -f $s)
}
#endregion

#region Interactive Parameter Input
function Get-InteractiveParameters {
    param(
        [hashtable]$Defaults
    )
    $Params = $Defaults.Clone()

    Write-Host '1) Сколько файлов (по умолчанию 1)?' -ForegroundColor White
    Write-Host '   (Количество пустых файлов, которые будут помещены в архив)' -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.Count = [int]$raw }

    Write-Host (Get-String 'PromptPathPrefix') -ForegroundColor White
    Write-Host (Get-String 'PromptPathPrefixHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.PathPrefix = $raw }

    Write-Host (Get-String 'PromptAutoSize') -ForegroundColor White
    Write-Host (Get-String 'PromptAutoSizeHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Params.AutoSize = $true } else { $Params.AutoSize = $false }

    Write-Host ((Get-String 'PromptType') -f $Params.Type) -ForegroundColor White
    Write-Host (Get-String 'PromptTypeHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.Type = $raw }

    if (-not $Params.AutoSize) {
        Write-Host (Get-String 'PromptRandomSize') -ForegroundColor White
        Write-Host (Get-String 'PromptRandomSizeHelp') -ForegroundColor DarkGray
        $raw = Read-Host '→'
        if ($raw) { $Params.RandomSize = $raw }

        if (-not $Params.RandomSize) {
            Write-Host ((Get-String 'PromptSize') -f $Params.Size) -ForegroundColor White
            Write-Host (Get-String 'PromptSizeHelp') -ForegroundColor DarkGray
            $raw = Read-Host '→'
            if ($raw) { $Params.Size = $raw }
        }
    }

    Write-Host ((Get-String 'PromptChunkSize') -f $Params.ChunkSizeMB) -ForegroundColor White
    Write-Host (Get-String 'PromptChunkSizeHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.ChunkSizeMB = [int]$raw }

    Write-Host (Get-String 'PromptCompression') -ForegroundColor White
    Write-Host (Get-String 'PromptCompressionHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -in 'Optimal','Fastest','NoCompression') { $Params.Compression = $raw }

    Write-Host ((Get-String 'PromptOutput') -f $Params.Output) -ForegroundColor White
    Write-Host (Get-String 'PromptOutputHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.Output = $raw }

    Write-Host (Get-String 'PromptTimestamp') -ForegroundColor White
    Write-Host (Get-String 'PromptTimestampHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.Timestamp = [datetime]$raw }

    Write-Host (Get-String 'PromptAttributes') -ForegroundColor White
    Write-Host (Get-String 'PromptAttributesHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw) { $Params.Attributes = $raw -split ',' }

    Write-Host (Get-String 'PromptOverwrite') -ForegroundColor White
    Write-Host (Get-String 'PromptOverwriteHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Params.Overwrite = $true }

    Write-Host (Get-String 'PromptChecksum') -ForegroundColor White
    Write-Host (Get-String 'PromptChecksumHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Params.Checksum = $true }

    Write-Host (Get-String 'PromptVerboseTable') -ForegroundColor White
    Write-Host (Get-String 'PromptVerboseTableHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Params.VerboseTable = $true }

    Write-Host (Get-String 'PromptRandomContent') -ForegroundColor White
    Write-Host (Get-String 'PromptRandomContentHelp') -ForegroundColor DarkGray
    $raw = Read-Host '→'
    if ($raw -match '^[Yy]') { $Params.RandomContent = $true }

    if ($Params.RandomContent) {
        Write-Host (Get-String 'PromptRandomSeed') -ForegroundColor White
        Write-Host (Get-String 'PromptRandomSeedHelp') -ForegroundColor DarkGray
        $raw = Read-Host '→'
        if ($raw) { $Params.RandomSeed = [int]$raw }
    }

    return $Params
}
#endregion

#region Main Logic
function Invoke-ZipGeneration {
    param(
        [hashtable]$Params
    )

    # Динамическое создание объекта для локализованных заголовков
    $summaryProps = [ordered]@{
        (Get-String 'HeaderCount')         = $Params.Count
        (Get-String 'HeaderPathInArchive') = $Params.PathPrefix
        (Get-String 'HeaderAutoSize')      = $Params.AutoSize
        (Get-String 'HeaderExtension')     = $Params.Type
        (Get-String 'HeaderSize')          = $Params.Size
        (Get-String 'HeaderRandomSize')    = $Params.RandomSize
        (Get-String 'HeaderBufferMB')      = $Params.ChunkSizeMB
        (Get-String 'HeaderCompression')   = $Params.Compression
        (Get-String 'HeaderArchive')       = $Params.Output
        (Get-String 'HeaderTimestamp')     = $Params.Timestamp
        (Get-String 'HeaderAttributes')    = $Params.Attributes
        (Get-String 'HeaderOverwrite')     = $Params.Overwrite
        (Get-String 'HeaderChecksum')      = $Params.Checksum
        (Get-String 'HeaderVerbose')       = $Params.VerboseTable
        (Get-String 'HeaderRandomContent') = $Params.RandomContent
        (Get-String 'HeaderSeed')          = $Params.RandomSeed
    }
    $summary = New-Object PSObject -Property $summaryProps
    $summary | Format-Table -AutoSize
    Write-Log "$((Get-String 'HeaderLogParameters')): $($summary|Out-String)"

    if ($Params.DryRun) { Write-Host (Get-String 'ErrorDryRun'); return }

    # --- Валидация и подготовка параметров ---
    if ($Params.Count -lt 1) { throw (Get-String 'ErrorCountPositive') }
    if (-not $Params.Output) { throw (Get-String 'ErrorOutputRequired') }
    if ($Params.AutoSize -and $Params.RandomSize) { throw (Get-String 'ErrorAutoSizeAndRandom') }
    if ($Params.Size -ne '1G' -and $Params.RandomSize) { throw (Get-String 'ErrorSizeAndRandom') }

    # Инициализация генератора случайных чисел (нужен и для размера, и для контента)
    $randomGen = if ($Params.RandomContent -or $Params.RandomSize) {
        if ($Params.RandomSeed -ne 0) { New-Object Random -ArgumentList $Params.RandomSeed }
        else { New-Object Random }
    }

    # Определение диска для проверки свободного места
    $drivePath = if ($Params.Output -match '[\\/]') { Split-Path $Params.Output -Qualifier } else { (Get-Location).Drive.Name + ':' }
    $drive = Get-PSDrive -Name $drivePath.TrimEnd(':')
    $freeSpace = $drive.Free

    # --- Определение размеров файлов ---
    $fileSizes = New-Object 'System.Collections.Generic.List[long]'
    if ($Params.RandomSize) {
        $parts = $Params.RandomSize -split ':'
        if ($parts.Length -ne 2) { throw ((Get-String 'ErrorInvalidRandomSize') -f $Params.RandomSize) }
        $minSize = Convert-SizeToBytes $parts[0]
        $maxSize = Convert-SizeToBytes $parts[1]
        if ($minSize -ge $maxSize) { throw (Get-String 'ErrorMinMaxSize') }

        1..$Params.Count | ForEach-Object { $fileSizes.Add($randomGen.Next($minSize, $maxSize)) }
    } else {
        $sizeBytes = if ($Params.AutoSize) { [math]::Floor(($freeSpace - 1MB) / $Params.Count) } else { Convert-SizeToBytes $Params.Size }
        1..$Params.Count | ForEach-Object { $fileSizes.Add($sizeBytes) }
    }

    $totalBytes = $fileSizes | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    if ($freeSpace -lt $totalBytes) { throw ((Get-String 'ErrorNoDiskSpace') -f ($totalBytes/1MB), ($freeSpace/1MB)) }
    Write-Log "TotalSizeBytes=$totalBytes"

    # Удаление существующего архива при необходимости
    if (Test-Path $Params.Output) {
        if ($Params.Overwrite) { Remove-Item $Params.Output -Force } else { throw ((Get-String 'ErrorFileExists') -f $Params.Output) }
    }

    # Создание архива
    if ($PSCmdlet.ShouldProcess($Params.Output,(Get-String 'MsgCreatingArchive'))) {
        try {
            Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
            $fs = [IO.File]::Open($Params.Output, 'Create')
            $zip = [IO.Compression.ZipArchive]::new($fs, 'Create', $false)

            # Основной цикл создания файлов
            $stats = @()
            $done = 0
            for ($i = 0; $i -lt $Params.Count; $i++) {
                $currentFileSize = $fileSizes[$i]
                $name = "dummy_{0:D3}.{1}" -f ($i+1), $Params.Type
                if ($Params.PathPrefix) { $name = "$($Params.PathPrefix)/$name" }
                $entry = $zip.CreateEntry($name)
                if ($Params.Timestamp) { $entry.LastWriteTime = $Params.Timestamp }
                $stream = $entry.Open()
                $buf = New-Object byte[] ($Params.ChunkSizeMB * 1MB)

                if (-not ($Params.RandomContent)) {
                    [void][Array]::Clear($buf, 0, $buf.Length) # Заполняем нулями один раз, если контент не случайный
                }

                $rem = $currentFileSize; $fileStart = Get-Date
                while ($rem -gt 0) {
                    if ($Params.RandomContent) {
                        $randomGen.NextBytes($buf) # Генерируем новый блок случайных данных на каждой итерации
                    }
                    $w = [math]::Min($buf.Length, $rem)
                    $stream.Write($buf, 0, $w); $rem -= $w; $done += $w
                    $pct = if ($totalBytes -gt 0) { [int](100 * $done / $totalBytes) } else { 0 }
                    Write-Progress -Activity (Get-String 'MsgProgressActivity') -Status "$pct%" -PercentComplete $pct
                }
                $stream.Dispose()
                $dur = (Get-Date).Subtract($fileStart).TotalSeconds

                $statProps = [ordered]@{
                    (Get-String 'StatsHeaderFile')    = $name
                    (Get-String 'StatsHeaderSizeMB')  = [math]::Round($currentFileSize/1MB,2)
                    (Get-String 'StatsHeaderTimeSec') = [math]::Round($dur,2)
                    (Get-String 'StatsHeaderSpeed')   = [math]::Round((($currentFileSize/1MB)/$dur),2)
                }
                $stats += New-Object PSObject -Property $statProps
            }
            $zip.Dispose(); $fs.Dispose()

            # Контрольная сумма
            if ($Params.Checksum) { $hash = Get-FileHash -Algorithm SHA256 $Params.Output | Select-Object -ExpandProperty Hash; Write-Host "SHA256: $hash" }

            $avgSizeMB = if($Params.Count -gt 0) { [math]::Round(($totalBytes / $Params.Count)/1MB, 2) } else { 0 }
            Write-Host ((Get-String 'MsgReady') -f $Params.Output, $Params.Count, $avgSizeMB)
            $stats | Format-Table -AutoSize
            if ($Params.VerboseTable) {
                Write-Host (Get-String 'StatsHeaderSpeedVerbose')
                $timeHeader = Get-String 'StatsHeaderTimeSec'
                $speedHeader = Get-String 'StatsHeaderSpeed'
                $stats | ForEach-Object { "{0,7:N2} | {1,7:N2}" -f $_.$timeHeader, $_.$speedHeader }
            }
        } catch {
            if (Test-Path $Params.Output) { Remove-Item $Params.Output -ErrorAction SilentlyContinue }
            throw
        }
    }
}
#endregion

# Script Body
Show-Banner

# Collect parameters
$scriptParams = @{
    Count = $Count; PathPrefix = $PathPrefix; AutoSize = $AutoSize; Type = $Type; Size = $Size;
    ChunkSizeMB = $ChunkSizeMB; Compression = $Compression; Output = $Output; LogFile = $LogFile;
    DryRun = $DryRun; Timestamp = $Timestamp; Attributes = $Attributes; Overwrite = $Overwrite;
    Checksum = $Checksum; VerboseTable = $VerboseTable; RandomContent = $RandomContent; RandomSeed = $RandomSeed;
    RandomSize = $RandomSize; Culture = $Culture
}

if (-not $PSBoundParameters.Count) {
    # Interactive mode
    $userParams = Get-InteractiveParameters -Defaults $scriptParams
    $scriptParams.GetEnumerator() | ForEach-Object { $scriptParams[$_.Name] = $userParams[$_.Name] }
}

# Run main logic
Invoke-ZipGeneration -Params $scriptParams
