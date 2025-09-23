# 🗜️ MakeSparseZip-Interactive

Интерактивный генератор "пустых" ZIP-архивов с множеством опций: логирование, контрольная сумма, псевдослучайные данные, установка атрибутов и многое другое.

## ⚙️ Возможности

- Пошаговый ввод параметров, если не заданы
- Создание ZIP-файла с множеством "пустых" файлов указанного размера
- Поддержка сжатия (Optimal, Fastest, NoCompression)
- Поддержка временных меток и атрибутов файлов
- Подробная статистика генерации
- SHA256-хеш архива
- Режим `DryRun` (без создания)

## 📦 Параметры

| Параметр        | Описание |
|-----------------|----------|
| `-Count`        | Количество файлов |
| `-PathPrefix`   | Подпапка внутри архива |
| `-AutoSize`     | Автоматический расчет размера по свободному месту |
| `-Size`         | Размер файла (например: 100M, 1G) |
| `-ChunkSizeMB`  | Размер буфера записи |
| `-Compression`  | Тип сжатия (`Optimal`, `Fastest`, `NoCompression`) |
| `-Output`       | Имя выходного архива |
| `-Overwrite`    | Перезаписать существующий ZIP |
| `-Checksum`     | Вычислить SHA256-хеш архива |
| `-VerboseTable` | Показать таблицу скорости и времени |
| `-DryRun`       | Только показать параметры, не создавать архив |
| `-Attributes`   | Установить атрибуты файлов (Hidden, ReadOnly...) |
| `-Timestamp`    | Дата/время для файлов |
| `-Language`     | Язык интерфейса (`ru` или `en`) |

## 🖥️ Примеры запуска

```powershell
.\MakeSparseZip.ps1 -Count 5 -Size 100M -Output test.zip -Compression Optimal -Verbose

.\MakeSparseZip.ps1
```

---

# 🗜️ MakeSparseZip-Interactive (English)

An interactive generator for "empty" ZIP archives with many options: logging, checksum, pseudo-random data, setting attributes, and much more.

## ⚙️ Features

- Step-by-step parameter input if none are provided
- Create a ZIP file with many "empty" files of a specified size
- Compression support (Optimal, Fastest, NoCompression)
- Support for timestamps and file attributes
- Detailed generation statistics
- SHA256 hash of the archive
- `DryRun` mode (without creating the file)

## 📦 Parameters

| Parameter        | Description |
|-----------------|----------|
| `-Count`        | Number of files |
| `-PathPrefix`   | Subfolder inside the archive |
| `-AutoSize`     | Automatically calculate size based on free space |
| `-Size`         | File size (e.g., 100M, 1G) |
| `-ChunkSizeMB`  | Write buffer size |
| `-Compression`  | Compression type (`Optimal`, `Fastest`, `NoCompression`) |
| `-Output`       | Output archive name |
| `-Overwrite`    | Overwrite existing ZIP |
| `-Checksum`     | Calculate SHA256 hash of the archive |
| `-VerboseTable` | Show speed and time table |
| `-DryRun`       | Only show parameters, don't create the archive |
| `-Attributes`   | Set file attributes (Hidden, ReadOnly...) |
| `-Timestamp`    | Date/time for files |
| `-Language`     | UI Language (`ru` or `en`) |

## 🖥️ Launch Examples

```powershell
.\MakeSparseZip.ps1 -Count 5 -Size 100M -Output test.zip -Compression Optimal -Verbose -Language en

.\MakeSparseZip.ps1
```
