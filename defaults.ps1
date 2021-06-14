# Proper history etc
Import-Module PSReadLine

# Produce UTF-8 by default
# https://news.ycombinator.com/item?id=12991690
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

# https://technet.microsoft.com/en-us/magazine/hh241048.aspx
$MaximumHistoryCount = 10000;

Set-Alias trash Remove-ItemSafely

function open($file) {
  invoke-item $file
}

function explorer {
    if($args.Length -eq 0){
        explorer.exe .
    } else {
        explorer.exe @args
    }
}

function Start-Edge {
  [CmdletBinding(DefaultParameterSetName='Work')]
  param ( 
    [Parameter(Mandatory=$false, Position=0)]
    [String]
    $ProfilePath,
    [Parameter(ParameterSetName='Work', Mandatory=$false)]
    [switch]
    $Work,
    [Parameter(ParameterSetName='Personal', Mandatory=$false)]
    [switch]
    $Personal
  )
  
  begin {
    if($null -ne $ProfilePath -and (Test-Path -Path $ProfilePath)) {
      $TargetProfile = $ProfilePath
    } elseif ($Work){
      $TargetProfile = "Default"
    } elseif ($Personal) {
      $TargetProfile = "Profile 2"
    }
  }
  
  process {
    & "${env:ProgramFiles(x86)}\Microsoft\Edge Beta\Application\msedge.exe" --profile-directory="$TargetProfile"
  }
  
  end {
    
  }
}


function settings {
  start-process ms-setttings:
}

# Oddly, Powershell doesn't have an inbuilt variable for the documents directory. So let's make one:
# From https://stackoverflow.com/questions/3492920/is-there-a-system-defined-environment-variable-for-documents-directory
$env:DOCUMENTS = [Environment]::GetFolderPath("mydocuments")

# PS comes preset with 'HKLM' and 'HKCU' drives but is missing HKCR 
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null

# Truncate homedir to ~
function Limit-HomeDirectory($Path) {
  $Path.Replace("$home", "~")
}

# Must be called 'prompt' to be used by pwsh 
# https://github.com/gummesson/kapow/blob/master/themes/bashlet.ps1


# Make $lastObject save the last object output
# From http://get-powershell.com/post/2008/06/25/Stuffing-the-output-of-the-last-command-into-an-automatic-variable.aspx
function Out-Default {
try{
  $input | Tee-Object -var global:lastobject | Microsoft.PowerShell.Core\out-default
}
Catch [System.Management.Automation.RuntimeException]
{
    'Error: {0}' -f $_.Exception.Message
}
}

# If you prefer oh-my-posh
# Import-Module posh-git
# Import-Module oh-my-posh

function Rename-Extension($newExtension){
  Rename-Item -NewName { [System.IO.Path]::ChangeExtension($_.Name, $newExtension) }
}
function Get-ShortName 
{
<#
.SYNOPSIS

    Get's the ShortName of a directory or file.
.DESCRIPTION

    Get's the ShortName of a directory or file.
.PARAMETER Path

    The path to get the shortname of.  By default, this will return the current directory.
.PARAMETER ReturnObject

    Return a 'Get-Item' object for the output instead of the default string path.
.EXAMPLE

    Get-ShortName
    This will return the shortname, if applicable, to the current directory.
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)"
    Returns:    C:\PROGRA~2
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe"
    Returns:    C:\PROGRA~2\COMMON~1\MICROS~1\MSInfo\msinfo32.exe
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe" -ReturnObject
    Returns:

            Directory: C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo


    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----        7/16/2016   7:42 AM         336896 msinfo32.exe
.EXAMPLE

    Get-ChildItem -Path "C:\Program Files\" | foreach-object {$_.FullName}
    Returns the shortname of each file or folder in 'C:\Program Files'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$Path=(Get-Item ".").FullName,
    [Switch]$ReturnObject
    )
    $Path = (Get-Item $Path).FullName
    $fso = New-Object -ComObject Scripting.FileSystemObject
    $Result = $null
    if ((Get-Item $Path).PSIsContainer){
        $Result = ($fso.GetFolder($Path)).ShortPath
    }else{
        $Result = ($fso.GetFile($Path)).ShortPath
    }
    if ($ReturnObject) {
        $Result = Get-Item $Result
    }
    $Result
}

function Get-FileTail
{
    <#
.SYNOPSIS

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.DESCRIPTION

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.PARAMETER File

    The path of the file to Tail.
.PARAMETER InitialLines

    The amount of lines to load into the console on first read. Default is 0, which will allow for only new content written after the start of the command to be shown.
    Specifying -1 will load all content of the file into the console initially.  This could cause performance impact on larger files.
    Alias:  Lines
.EXAMPLE

    Get-FileTail -File C:\Test.log
    Prints all content of a file that is written after the monitoring starts. 
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines -1
    Prints all existing and new content of a file to the console.
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines 5
    Prints the last 5 lines and new content of a file to the console.
.EXAMPLE

    Tail -File C:\Test.log
    Functions the same as the first example, simply uses the 'Tail' alias for this function.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [Alias("Lines")]
        [int32]$InitialLines=0
    )
    
    if ($InitialLines -eq -1) {
        Write-Host "Starting monitoring of $File with all existing content to be loaded first." -ForegroundColor Yellow
    }else{
        Write-Host "Starting monitoring of $File with $InitialLines initial lines to be loaded first." -ForegroundColor Yellow
    }
    Write-Host "Press CTRL + C to cancel this operation." -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    try {
        Get-Content $File -Wait -Tail $InitialLines
    }
    catch {
        Write-Host "`n`nThe process was interrupted:" -ForegroundColor Red -BackgroundColor Black
        $_.Exception
    }finally{
        Write-Host "`n`nFinished tailing $File" -ForegroundColor Yellow
    }
}
New-Alias -Name Tail -Value Get-FileTail -Scope Global