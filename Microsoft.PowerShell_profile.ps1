# Note foreach can be a keyword or an alias to foreach-object
# https://stackoverflow.com/questions/29148462/difference-between-foreach-and-foreach-object-in-powershell

# Set-ExecutionPolicy unrestricted

# So we can launch pwsh in subshells if we need
Add-PathVariable (Resolve-Path "${env:ProgramFiles}\PowerShell\*-Preview")

$profileDir = $PSScriptRoot;

# From https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil#97599
function Test-Administrator  {  
	$user = [Security.Principal.WindowsIdentity]::GetCurrent();
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

# Edit whole dir, so we can edit included files etc
function Edit-Powershell-Profile {
	edit $profileDir
}

function Update-Powershell-Profile {
	& $profile
}

# https://blogs.technet.microsoft.com/heyscriptingguy/2012/12/30/powertip-change-the-powershell-console-title
function Set-Title([string]$newtitle) {
	$host.ui.RawUI.WindowTitle = $newtitle + ' – ' + $host.ui.RawUI.WindowTitle
}

# From http://stackoverflow.com/questions/7330187/how-to-find-the-windows-version-from-the-powershell-command-line
function Get-Windows-Build {
	[Environment]::OSVersion
}

<# function Disable-Windows-Search {
	Set-Service wsearch -StartupType disabled
	stop-Service wsearch
} #>

# http://mohundro.com/blog/2009/03/31/quickly-extract-files-with-powershell/
# and https://stackoverflow.com/questions/1359793/programmatically-extract-tar-gz-in-a-single-step-on-windows-with-7zip
# function Expand-Archive([string]$file, [string]$outputDir = '') {
# 	if (-not (Test-Path $file)) {
# 		$file = Resolve-Path $file
# 	}

# 	$baseName = Get-Childitem $file | Select-Object -ExpandProperty "BaseName"

# 	if ($outputDir -eq '') {
# 		$outputDir = $baseName
# 	}

# 	# Check if there's a tar inside
# 	# We use the .net method as this file (x.tar) doesn't exist!
# 	$secondExtension = [System.IO.Path]::GetExtension($baseName)
# 	$secondBaseName = [System.IO.Path]::GetFileNameWithoutExtension($baseName)

# 	if ( $secondExtension -eq '.tar' ) {
# 		# This is a tarball
# 		$outputDir = $secondBaseName
# 		Write-Output "Output dir will be $outputDir"		
# 		7z x $file -so | 7z x -aoa -si -ttar -o"$outputDir"
# 		return
# 	} 
# 	# Just extract the file
# 	7z x "-o$outputDir" $file	
# }

<# Set-Alias unzip Expand-Archive #>

function Get-Path {
	($Env:Path).Split(";")
}

function Test-FileInSubPath([System.IO.DirectoryInfo]$Child, [System.IO.DirectoryInfo]$Parent) {
	Write-Host $Child.FullName | Select-Object '*'
	$Child.FullName.StartsWith($Parent.FullName)
}

<# function stree {
	$SourceTreeFolder =  Get-Childitem ("${env:LOCALAPPDATA}" + "\SourceTree\app*") | Select-Object -first 1
	& $SourceTreeFolder/SourceTree.exe -f .
} #>

<# function Get-Serial-Number {
  Get-CimInstance -ClassName Win32_Bios | Select-Object serialnumber
} #>

function Get-Process-For-Port($port) {
	Get-Process -Id (Get-NetTCPConnection -LocalPort $port).OwningProcess
}

foreach ( $includeFile in ("aws", "defaults", "openssl", "aws", "unix", "development", "node") ) {
	Unblock-File $profileDir\$includeFile.ps1
. "$profileDir\$includeFile.ps1"
}

Set-Location "$env:USERPROFILE\Documents\GitHub"

Write-Output "$env:USERNAME profile loaded"


