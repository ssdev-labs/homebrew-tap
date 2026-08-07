[CmdletBinding()]
param(
    [string]$Version = "0.4.0"
)

& {
    param([string]$ReleaseVersion)

    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        throw "ssdev-cairn requires PowerShell 5.1 or later."
    }
    if ($env:OS -ne "Windows_NT") {
        throw "This installer only supports Windows."
    }

    $ReleaseVersion = $ReleaseVersion.Trim().TrimStart("v")
    if ($ReleaseVersion -notmatch "^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$") {
        throw "The installer does not contain a valid release version."
    }

    $nativeArchitecture = if ([string]::IsNullOrWhiteSpace($env:PROCESSOR_ARCHITEW6432)) {
        $env:PROCESSOR_ARCHITECTURE
    } else {
        $env:PROCESSOR_ARCHITEW6432
    }
    $architecture = switch ($nativeArchitecture.ToUpperInvariant()) {
        "AMD64" { "amd64" }
        "ARM64" { "arm64" }
        default { throw "Unsupported Windows architecture: $nativeArchitecture" }
    }

    $git = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $git) {
        throw "Git for Windows is required. Install it from https://git-scm.com/download/win and try again."
    }
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw "LOCALAPPDATA is not available."
    }

    $archiveName = "ssdev-cairn_${ReleaseVersion}_windows_${architecture}.zip"
    $releaseBaseUrl = "https://github.com/yahuo/homebrew-tap/releases/download/ssdev-cairn-v$ReleaseVersion"
    $installDirectory = Join-Path $env:LOCALAPPDATA "Programs\ssdev-cairn"
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("ssdev-cairn-" + [Guid]::NewGuid().ToString("N"))
    $archivePath = Join-Path $temporaryDirectory $archiveName
    $checksumsPath = Join-Path $temporaryDirectory "checksums.txt"
    $extractDirectory = Join-Path $temporaryDirectory "archive"

    $originalProgressPreference = $ProgressPreference
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        $ProgressPreference = "SilentlyContinue"
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri "$releaseBaseUrl/$archiveName" -OutFile $archivePath
        Invoke-WebRequest -UseBasicParsing -Uri "$releaseBaseUrl/checksums.txt" -OutFile $checksumsPath

        $checksumPattern = "^([0-9a-fA-F]{64})\s+\*?" + [Regex]::Escape($archiveName) + "$"
        $checksumLines = @(Get-Content -LiteralPath $checksumsPath | Where-Object { $_ -match $checksumPattern })
        if ($checksumLines.Count -ne 1) {
            throw "checksums.txt does not contain exactly one entry for $archiveName."
        }
        $expectedHash = [Regex]::Match($checksumLines[0], $checksumPattern).Groups[1].Value
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        if (-not [string]::Equals($expectedHash, $actualHash, [StringComparison]::OrdinalIgnoreCase)) {
            throw "SHA-256 mismatch for $archiveName. Expected $expectedHash, got $actualHash."
        }

        Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDirectory -Force
        $stagedExecutable = Join-Path $extractDirectory "git-cairn.exe"
        if (-not (Test-Path -LiteralPath $stagedExecutable -PathType Leaf)) {
            throw "$archiveName does not contain git-cairn.exe."
        }

        $stagedVersionOutput = @(& $stagedExecutable version 2>&1)
        $stagedVersionExitCode = $LASTEXITCODE
        $stagedVersion = ($stagedVersionOutput -join [Environment]::NewLine).Trim()
        if ($stagedVersionExitCode -ne 0 -or $stagedVersion -ne $ReleaseVersion) {
            throw "Downloaded git-cairn.exe reported version '$stagedVersion'; expected '$ReleaseVersion'."
        }

        New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null
        Copy-Item -LiteralPath $stagedExecutable -Destination (Join-Path $installDirectory "git-cairn.exe") -Force
        $stagedReadme = Join-Path $extractDirectory "README.md"
        if (Test-Path -LiteralPath $stagedReadme -PathType Leaf) {
            Copy-Item -LiteralPath $stagedReadme -Destination (Join-Path $installDirectory "README.md") -Force
        }

        function Get-NormalizedPathEntry {
            param([string]$PathEntry)

            if ([string]::IsNullOrWhiteSpace($PathEntry)) {
                return ""
            }
            $trimmed = $PathEntry.Trim()
            if ($trimmed.Length -ge 2 -and $trimmed[0] -eq '"' -and $trimmed[$trimmed.Length - 1] -eq '"') {
                $trimmed = $trimmed.Substring(1, $trimmed.Length - 2)
            }
            return [Environment]::ExpandEnvironmentVariables($trimmed).TrimEnd([char[]]"\/")
        }

        function Test-PathContainsEntry {
            param(
                [AllowNull()][string]$PathValue,
                [string]$ExpectedEntry
            )

            $normalizedExpected = Get-NormalizedPathEntry $ExpectedEntry
            foreach ($entry in @($PathValue -split ";")) {
                if ((Get-NormalizedPathEntry $entry) -ieq $normalizedExpected) {
                    return $true
                }
            }
            return $false
        }

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not (Test-PathContainsEntry $userPath $installDirectory)) {
            $updatedUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
                $installDirectory
            } else {
                $userPath.TrimEnd(";") + ";" + $installDirectory
            }
            [Environment]::SetEnvironmentVariable("Path", $updatedUserPath, "User")
        }
        if (-not (Test-PathContainsEntry $env:Path $installDirectory)) {
            $env:Path = $installDirectory + ";" + $env:Path
        }

        $installedVersionOutput = @(& $git.Source cairn version 2>&1)
        $installedVersionExitCode = $LASTEXITCODE
        $installedVersion = ($installedVersionOutput -join [Environment]::NewLine).Trim()
        if ($installedVersionExitCode -ne 0 -or $installedVersion -ne $ReleaseVersion) {
            throw "git cairn version reported '$installedVersion'; expected '$ReleaseVersion'."
        }

        Write-Output "Installed ssdev-cairn $ReleaseVersion to $installDirectory"
    } finally {
        $ProgressPreference = $originalProgressPreference
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
} $Version
