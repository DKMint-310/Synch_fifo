param(
    [ValidateRange(1, 2147483647)][int]$DataWidth = 8,
    [ValidateRange(1, 2147483647)][int]$Depth = 16,
    [ValidateRange(1, 2147483647)][int]$Seed = 1
)

$ErrorActionPreference = 'Stop'
$buildDir = Join-Path $PSScriptRoot "build/w${DataWidth}_d${Depth}_s${Seed}"
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

function Invoke-SimulatorTool {
    param([string]$Tool, [string[]]$ToolArgs, [string]$Log)
    $command = Get-Command $Tool -ErrorAction Stop
    $previousPreference = $ErrorActionPreference
    try {
        # Windows PowerShell represents native stderr as non-terminating errors.
        # Check the native exit code and the test summary explicitly below.
        $ErrorActionPreference = 'Continue'
        & $command.Source @ToolArgs *> $Log
        $toolExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($toolExit -ne 0) {
        Get-Content -LiteralPath $Log -Tail 20 | Write-Host
        throw "$Tool failed (exit $toolExit). Log: $buildDir/$Log"
    }
}

# Resolve the shared file list relative to sim/, regardless of caller's cwd.
$compileArgs = @('--sv')
foreach ($line in Get-Content -LiteralPath (Join-Path $PSScriptRoot 'filelist.f')) {
    $entry = $line.Trim()
    if (!$entry -or $entry.StartsWith('#')) { continue }
    if ($entry.StartsWith('-i ')) {
        $compileArgs += '-i'
        $compileArgs += (Resolve-Path (Join-Path $PSScriptRoot $entry.Substring(3).Trim())).Path
    } else {
        $compileArgs += (Resolve-Path (Join-Path $PSScriptRoot $entry)).Path
    }
}

Push-Location -LiteralPath $buildDir
try {
    Invoke-SimulatorTool 'xvlog.bat' $compileArgs 'xvlog.console.log'
    Invoke-SimulatorTool 'xelab.bat' @(
        'synch_fifo_tb', '-s', 'fifo_sim', '-debug', 'typical', '-mt', '2',
        # Preserve quotes through the Vivado .bat wrapper: cmd treats '=' as a delimiter.
        '-generic_top', ('"DATA_WIDTH={0}"' -f $DataWidth),
        '-generic_top', ('"DEPTH={0}"' -f $Depth)
    ) 'xelab.console.log'
    Invoke-SimulatorTool 'xsim.bat' @(
        'fifo_sim', '-runall', '-sv_seed', "$Seed"
    ) 'xsim.console.log'

    $logText = Get-Content -LiteralPath 'xsim.console.log' -Raw
    if (($logText -notmatch 'STATUS\s*:\s*TEST PASSED') -or
        ($logText -match '\[SCB FAIL\]|Fatal:|TEST FAILED|\[TIMEOUT\]')) {
        Get-Content -LiteralPath 'xsim.console.log' -Tail 20 | Write-Host
        throw "Simulation did not pass. Log: $buildDir/xsim.console.log"
    }
    Select-String -LiteralPath 'xsim.console.log' -Pattern (
        'Accepted reads|Errors Found|STATUS'
    ) | ForEach-Object { Write-Host $_.Line }
    Write-Host "PASS: DATA_WIDTH=$DataWidth DEPTH=$Depth SEED=$Seed"
    Write-Host "Logs and waveform: $buildDir"
} finally {
    Pop-Location
}
