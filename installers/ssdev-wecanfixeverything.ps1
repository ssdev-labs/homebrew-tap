[CmdletBinding()]
param(
    [string]$Version = "0.6.0",
    [switch]$Uninstall
)

& {
    param(
        [string]$ReleaseVersion,
        [bool]$RemoveRequested
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        throw "WeCanFixEverything requires PowerShell 5.1 or later."
    }
    if ($env:OS -ne "Windows_NT") {
        throw "This installer only supports Windows."
    }

    $nativeArchitecture = if ([string]::IsNullOrWhiteSpace($env:PROCESSOR_ARCHITEW6432)) {
        $env:PROCESSOR_ARCHITECTURE
    } else {
        $env:PROCESSOR_ARCHITEW6432
    }
    if ($nativeArchitecture.ToUpperInvariant() -ne "AMD64") {
        throw "This release only supports Windows x64; detected $nativeArchitecture."
    }

    $programFiles64 = if ([string]::IsNullOrWhiteSpace($env:ProgramW6432)) {
        ${env:ProgramFiles}
    } else {
        $env:ProgramW6432
    }
    if ([string]::IsNullOrWhiteSpace($programFiles64)) {
        throw "The 64-bit Program Files directory is not available."
    }

    $installDirectory = Join-Path $programFiles64 "WeCanFixEverything"
    $installedApplication = Join-Path $installDirectory "WeCanFixEverything.exe"
    $installedCLI = Join-Path $installDirectory "resources\bin\ssdev-wecanfixeverything-cli.exe"
    $installedSkill = Join-Path $installDirectory "resources\Skills\ssdev-wecanfixeverything\SKILL.md"
    $uninstaller = Join-Path $installDirectory "uninstall.exe"

    if ($RemoveRequested) {
        if (-not (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
            if (Test-Path -LiteralPath $installDirectory) {
                throw "The installation exists but uninstall.exe is missing: $installDirectory"
            }
            Write-Output "WeCanFixEverything is not installed."
            return
        }

        $runningApplication = Get-Process -Name "WeCanFixEverything" -ErrorAction SilentlyContinue
        if ($null -ne $runningApplication) {
            throw "Close WeCanFixEverything before uninstalling it."
        }

        $process = Start-Process -FilePath $uninstaller -ArgumentList "/S" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "The uninstaller exited with code $($process.ExitCode)."
        }
        for ($attempt = 0; $attempt -lt 20 -and (Test-Path -LiteralPath $installDirectory); $attempt++) {
            Start-Sleep -Milliseconds 250
        }
        if (Test-Path -LiteralPath $installDirectory) {
            throw "The installation directory still exists after uninstall: $installDirectory"
        }
        Write-Output "Uninstalled WeCanFixEverything from $installDirectory"
        return
    }

    $ReleaseVersion = $ReleaseVersion.Trim().TrimStart("v")
    if ($ReleaseVersion -notmatch "^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$") {
        throw "The installer does not contain a valid release version."
    }

    $runningApplication = Get-Process -Name "WeCanFixEverything" -ErrorAction SilentlyContinue
    if ($null -ne $runningApplication) {
        throw "Close WeCanFixEverything before installing or upgrading it."
    }

    $installerName = "ssdev-wecanfixanything-windows-x64-setup.exe"
    $releaseBaseUrl = "https://github.com/ssdev-labs/homebrew-tap/releases/download/ssdev-wecanfixeverything-v$ReleaseVersion"
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("ssdev-wecanfixeverything-" + [Guid]::NewGuid().ToString("N"))
    $installerPath = Join-Path $temporaryDirectory $installerName
    $checksumsPath = Join-Path $temporaryDirectory "SHA256SUMS.txt"

    $originalProgressPreference = $ProgressPreference
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        $ProgressPreference = "SilentlyContinue"
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri "$releaseBaseUrl/$installerName" -OutFile $installerPath
        Invoke-WebRequest -UseBasicParsing -Uri "$releaseBaseUrl/SHA256SUMS.txt" -OutFile $checksumsPath

        $checksumPattern = "^([0-9a-fA-F]{64})\s+\*?" + [Regex]::Escape($installerName) + "$"
        $checksumLines = @(Get-Content -LiteralPath $checksumsPath | Where-Object { $_ -match $checksumPattern })
        if ($checksumLines.Count -ne 1) {
            throw "SHA256SUMS.txt does not contain exactly one entry for $installerName."
        }
        $expectedHash = [Regex]::Match($checksumLines[0], $checksumPattern).Groups[1].Value
        $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash
        if (-not [string]::Equals($expectedHash, $actualHash, [StringComparison]::OrdinalIgnoreCase)) {
            throw "SHA-256 mismatch for $installerName. Expected $expectedHash, got $actualHash."
        }

        $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "The installer exited with code $($process.ExitCode)."
        }

        if (-not (Test-Path -LiteralPath $installedApplication -PathType Leaf)) {
            throw "The installed application is missing: $installedApplication"
        }
        if (-not (Test-Path -LiteralPath $installedCLI -PathType Leaf)) {
            throw "The installed CLI is missing: $installedCLI"
        }
        if (-not (Test-Path -LiteralPath $installedSkill -PathType Leaf)) {
            throw "The installed Agent Skill is missing: $installedSkill"
        }

        $versionResult = (& $installedCLI --json version | Out-String | ConvertFrom-Json)
        if (-not $versionResult.ok -or $versionResult.data.version -ne $ReleaseVersion) {
            throw "The installed CLI reported an unexpected version."
        }

        Write-Output "Installed WeCanFixEverything $ReleaseVersion to $installDirectory"
    } finally {
        $ProgressPreference = $originalProgressPreference
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
} $Version $Uninstall.IsPresent
