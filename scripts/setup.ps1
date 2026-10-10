# ---------------------------------------------------------------------------------------------
#   Copyright (c) Microsoft Corporation. All rights reserved.
#   Licensed under the MIT License. See License.txt in the project root for license information.
# ---------------------------------------------------------------------------------------------

# Checks what you need to build Remnants from source on Windows and prints the command
# for anything missing. It installs nothing and builds nothing.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1

$nextSteps = @(
	'$env:VSCODE_SKIP_NODE_VERSION_CHECK = "1"'
	'npm ci'
	'npm run transpile-client'
	'npm run build-fast-extensions'
	'.\scripts\code.bat'
)

Set-StrictMode -Version Latest

$script:missing = 0

function Write-Ok([string]$name) {
	Write-Host ('ok       ' + $name)
}

function Write-Missing([string]$name, [string[]]$fix) {
	$script:missing++
	Write-Host ('missing  ' + $name) -ForegroundColor Yellow
	foreach ($line in $fix) {
		Write-Host ('         ' + $line)
	}
}

function Get-Output([string]$command, [string[]]$arguments) {
	if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
		return ''
	}
	return (@(& $command @arguments 2>$null) -join ' ').Trim()
}

$gitVersion = Get-Output 'git' @('--version')
if ($gitVersion) {
	Write-Ok "Git ($gitVersion)"
} else {
	Write-Missing 'Git' @('winget install --id Git.Git -e')
}

# The release build uses Node 22 with npm 10. npm 11 (Node 24) rejects npm ci on this
# lockfile, so the .nvmrc version is skipped with VSCODE_SKIP_NODE_VERSION_CHECK.
$nodeFix = 'winget install --id OpenJS.NodeJS.22 -e'
$nodeVersion = Get-Output 'node' @('--version')
if (-not $nodeVersion) {
	Write-Missing 'Node.js 22' @($nodeFix)
} elseif ($nodeVersion -notmatch '^v22\.') {
	Write-Missing "Node.js 22 (found $nodeVersion; Node 22 is the version that works with npm ci here)" @($nodeFix)
} else {
	Write-Ok "Node.js $nodeVersion"
	$npmVersion = Get-Output 'npm.cmd' @('--version')
	if ($npmVersion -match '^10\.') {
		Write-Ok "npm $npmVersion"
	} elseif ($npmVersion) {
		Write-Missing "npm 10 (found $npmVersion)" @('npm install -g npm@10')
	} else {
		Write-Missing 'npm 10' @($nodeFix)
	}
}

# node-gyp needs Python. The release build uses 3.13; 3.11 and newer also work.
$pythonFix = 'winget install --id Python.Python.3.13 -e'
$pythonVersion = Get-Output 'py' @('-3.13', '--version')
if ($pythonVersion -notmatch '^Python 3\.13\.') {
	$pythonVersion = Get-Output 'python' @('--version')
}
if ($pythonVersion -match '^Python 3\.(\d+)\.' -and [int]$Matches[1] -ge 11) {
	Write-Ok $pythonVersion
} elseif ($pythonVersion -match '^Python \d') {
	Write-Missing "Python 3.13 (found $pythonVersion)" @($pythonFix)
} else {
	Write-Missing 'Python 3.13' @($pythonFix)
}

# node-gyp here only works with Visual Studio 2022 (version 17), so newer versions do not count.
$vsName = 'Visual Studio 2022 C++ build tools'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsPath = ''
$vsScore = -1
$hasVc = $false
$hasSdk = $false
$hasSpectre = $false
if (Test-Path $vswhere) {
	$json = (@(& $vswhere -products '*' -version '[17.0,18.0)' -format json -include packages 2>$null) -join "`n").Trim()
	if ($json) {
		foreach ($instance in (ConvertFrom-Json $json)) {
			$ids = @($instance.packages | ForEach-Object { $_.id })
			$vc = $ids -contains 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
			$sdk = @($ids -match '^Microsoft\.VisualStudio\.Component\.Windows1[01]SDK').Count -gt 0
			$spectre = $ids -contains 'Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre'
			$score = [int]$vc * 4 + [int]$sdk * 2 + [int]$spectre
			if ($score -gt $vsScore) {
				$vsScore = $score
				$vsPath = [string]$instance.installationPath
				$hasVc = $vc
				$hasSdk = $sdk
				$hasSpectre = $spectre
			}
		}
	}
}
if (-not $vsPath) {
	Write-Missing $vsName @('winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --includeRecommended"')
} else {
	$lacking = @()
	$add = ''
	if (-not $hasVc) {
		$lacking += 'MSVC v143'
		$add += ' --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
	}
	if (-not $hasSpectre) {
		$lacking += 'Spectre-mitigated libraries'
		$add += ' --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre'
	}
	if (-not $hasSdk) {
		$lacking += 'Windows SDK'
		$add += ' --add Microsoft.VisualStudio.Component.Windows11SDK.26100'
	}
	if ($lacking.Count -eq 0) {
		Write-Ok "$vsName ($vsPath)"
	} else {
		$modify = '& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe" modify --installPath "' + $vsPath + '"' + $add + ' --passive --wait'
		Write-Missing "$vsName (no $($lacking -join ', ') in $vsPath)" @($modify)
	}
}

# npm starts through npm.ps1 in PowerShell, which Restricted and AllSigned block. The
# Process scope is skipped because this script is usually started with -ExecutionPolicy Bypass.
$policy = ''
foreach ($scope in @('MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine')) {
	$value = [string](Get-ExecutionPolicy -Scope $scope)
	if ($value -ne 'Undefined') {
		$policy = $value
		break
	}
}
if (-not $policy) {
	if ($PSVersionTable.PSEdition -eq 'Core') {
		$policy = 'RemoteSigned'
	} else {
		$policy = 'Restricted'
	}
}
if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
	Write-Missing "PowerShell execution policy (found $policy, which blocks npm.ps1)" @('Set-ExecutionPolicy -Scope CurrentUser RemoteSigned')
} else {
	Write-Ok "PowerShell execution policy ($policy)"
}

if (-not [Environment]::GetEnvironmentVariable('GITHUB_TOKEN')) {
	Write-Host 'note     GITHUB_TOKEN is not set. npm ci downloads tools from GitHub; if it stops with a rate limit error, set a token first:'
	Write-Host '         $env:GITHUB_TOKEN = "<token>"'
	Write-Host '         (a token with no scopes is enough, or $env:GITHUB_TOKEN = gh auth token if GitHub CLI is signed in)'
}

Write-Host ''
if ($script:missing -gt 0) {
	Write-Host 'Install what is missing, open a new terminal, and run this script again.'
	exit 1
}

Write-Host ('All set. From ' + (Split-Path -Parent $PSScriptRoot) + ', run:')
Write-Host ''
foreach ($step in $nextSteps) {
	Write-Host ('  ' + $step)
}
exit 0
