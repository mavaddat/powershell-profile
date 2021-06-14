Function Add-PathVariable {
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[String]$AddPath,
		[String[]][AllowNull()]
		[Parameter(Position = 1, ValueFromRemainingArguments)]
		$Remaining
	)
	if (Test-Path $AddPath) {
		$regexAddPath = [regex]::Escape($AddPath)
		$ArrPath = $env:Path -split ';' | Where-Object { $_ -notMatch 
			"^$regexAddPath\\?" }
		$env:Path = ($ArrPath + $AddPath) -join ';'
	}
 else {
	 	$throwMessage = "'$AddPath' is not a valid path."
		if($null -ne ($BetterPath = Resolve-Path -Path (Join-Path $AddPath '*' -ErrorAction SilentlyContinue)  -ErrorAction SilentlyContinue) -and (Test-Path -Path $BetterPath)) {
			Write-Error -Category ObjectNotFound -Message ($throwMessage + "`nDid you mean '$BetterPath'?")
		} else {
			Write-Error -Category ObjectNotFound -Message $throwMessage
		}
	}
	
	if($null -ne $Remaining){
		ForEach-Object -InputObject $Remaining -Process {Add-PathVariable($_)}
	}
}

# Note foreach can be a keyword or an alias to foreach-object
# https://stackoverflow.com/questions/29148462/difference-between-foreach-and-foreach-object-in-powershell

# Set-ExecutionPolicy unrestricted

# So we can launch pwsh in subshells if we need
Add-PathVariable (Resolve-Path "${env:ProgramFiles}\PowerShell\*-Preview")

$profileDir = $PSScriptRoot;

# From https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil#97599
function Test-Administrator {  
	$user = [Security.Principal.WindowsIdentity]::GetCurrent();
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

# Edit whole dir, so we can edit included files etc
function Edit-PowershellProfile {
	edit $profileDir
}

function Update-PowershellProfile {
	& $profile
}

# https://blogs.technet.microsoft.com/heyscriptingguy/2012/12/30/powertip-change-the-powershell-console-title
function Set-Title([string]$newtitle) {
	$host.ui.RawUI.WindowTitle = $newtitle + ' – ' + $host.ui.RawUI.WindowTitle
}

# From http://stackoverflow.com/questions/7330187/how-to-find-the-windows-version-from-the-powershell-command-line
function Get-WindowsBuild {
	[Environment]::OSVersion
}

function Get-WifiPassword {
	# Get current Wifi SSID
	$ssid = $(netsh wlan show interfaces | Select-String -Pattern ".*Profile\s+:\s*(.*?)(?: \d+)?\s*$").Matches.Groups[1].Value
	# Get Wifi key and set it to clipboard
	$( &netsh.exe @("wlan", "show", "profile", "$ssid", "key=clear") | Select-String -Pattern ".*?key content\s+:\s*(.*)$").Matches.Groups[1].Value | Set-Clipboard
}

<# function Disable-WindowsSearch {
	Set-Service wsearch -StartupType disabled
	stop-Service wsearch
} #>

# http://mohundro.com/blog/2009/03/31/quickly-extract-files-with-powershell/
# and https://stackoverflow.com/questions/1359793/programmatically-extract-tar-gz-in-a-single-step-on-windows-with-7zip
<# function Expand-Archive([string]$file, [string]$outputDir = '') {
	if (-not (Test-Path $file)) {
		$file = Resolve-Path $file
	}

	$baseName = Get-Childitem $file | Select-Object -ExpandProperty "BaseName"

	if ($outputDir -eq '') {
		$outputDir = $baseName
	}

	# Check if there's a tar inside
	# We use the .net method as this file (x.tar) doesn't exist!
	$secondExtension = [System.IO.Path]::GetExtension($baseName)
	$secondBaseName = [System.IO.Path]::GetFileNameWithoutExtension($baseName)

	if ( $secondExtension -eq '.tar' ) {
		# This is a tarball
		$outputDir = $secondBaseName
		Write-Output "Output dir will be $outputDir"		
		7z x $file -so | 7z x -aoa -si -ttar -o"$outputDir"
		return
	} 
	# Just extract the file
	7z x "-o$outputDir" $file	
}
#>

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

<# function Get-SerialNumber {
  Get-CimInstance -ClassName Win32_Bios | Select-Object serialnumber
} #>

# https://stackoverflow.com/questions/14970079/how-to-recursively-enumerate-through-properties-of-object
function Get-Properties($Object, $MaxLevels="5", $PathName = "`$_", $Level=0)
{
    <#
        .SYNOPSIS
        Returns a list of all properties of the input object

        .DESCRIPTION
        Recursively 

        .PARAMETER Object
        Mandatory - The object to list properties of

        .PARAMETER MaxLevels
        Specifies how many levels deep to list

        .PARAMETER PathName
        Specifies the path name to use as the root. If not specified, all properties will start with "."

        .PARAMETER Level
        Specifies which level the function is currently processing. Should not be used manually.

        .EXAMPLE
        $v = Get-View -ViewType VirtualMachine -Filter @{"Name" = "MyVM"}
        Get-Properties $v | ? {$_ -match "Host"}

        .NOTES
            FunctionName : 
            Created by   : KevinD
            Date Coded   : 02/19/2013 12:54:52
        .LINK
            http://stackoverflow.com/users/1298933/kevind
     #>

    if ($Level -eq 0) 
    { 
        $oldErrorPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
    }

    #Initialize an array to store properties
    $props = @()

    # Get all properties of this level
    $rootProps = $Object | Get-Member -ErrorAction SilentlyContinue | Where-Object { $_.MemberType -match "Property"} 

    # Add all properties from this level to the array.
    $rootProps | ForEach-Object { $props += "$PathName.$($_.Name)" }

    # Make sure we're not exceeding the MaxLevels
    if ($Level -lt $MaxLevels)
    {

        # We don't care about the sub-properties of the following types:
        $typesToExclude = "System.Boolean", "System.String", "System.Int32", "System.Char"

        #Loop through the root properties
        $props += $rootProps | ForEach-Object {

                    #Base name of property
                    $propName = $_.Name;

                    #Object to process
                    $obj = $($Object.$propName)

                    # Get the type, and only recurse into it if it is not one of our excluded types
                    $type = ($obj.GetType()).ToString()

                    # Only recurse if it's not of a type in our list
                    if (!($typesToExclude.Contains($type)))
                    {

                        #Path to property
                        $childPathName = "$PathName.$propName"

                        # Make sure it's not null, then recurse, incrementing $Level                        
                        if ($null -ne $obj)
                        {
                            Get-Properties -Object $obj -PathName $childPathName -Level ($Level + 1) -MaxLevels $MaxLevels }
                        }
                    }
    }

    if ($Level -eq 0) {$ErrorActionPreference = $oldErrorPreference}
    $props
}

function Get-ProcessForPort($port) {
	Get-Process -Id (Get-NetTCPConnection -LocalPort $port).OwningProcess
}

foreach ( $includeFile in ("aws", "defaults", "openssl", "aws", "unix", "development", "node") ) {
	Unblock-File $profileDir\$includeFile.ps1
	. "$profileDir\$includeFile.ps1"
}

Set-Location "$env:USERPROFILE\Documents\GitHub"

Write-Output "$env:USERNAME profile loaded"