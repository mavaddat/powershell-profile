$nodePath = Resolve-Path (Join-Path "$("$(nvm root)" -replace ".*([A-Z]:\\)",'$1')" 'v*[0-9]*') | Select-Last -Last 1
if (Test-Path -Path $nodePath) {
	Add-PathVariable "$nodePath"
}
function Update-NodeJS {
	$availNodeVers = New-Object -TypeName System.Collections.ArrayList
	$verPattern = [regex]::new("(?:\d+\.?){3}")

	$addVersJob = (Start-ThreadJob -ScriptBlock {
			param($availNodeVers, $verPattern)
			nvm list available  | ForEach-Object { 
				(Select-String -InputObject $_ -Pattern $verPattern -AllMatches).Matches | ForEach-Object { 
					$ver = New-Object -TypeName version
					if ( [version]::TryParse($_.Value, [ref]$ver) ) { 
						$availNodeVers.Add($ver) | Out-Null 
					} 
				} 
			}
		} -ArgumentList $availNodeVers, $verPattern)

	$currNodeVerJob = Start-ThreadJob -ScriptBlock { 
		param($verPattern)
		(nvm list | Select-String $verPattern).Matches.Value 
	} -ArgumentList $verPattern

	Wait-Job -Job $addVersJob | Out-Null

	$availNodeVers.Sort() | Out-Null
	$newerAvail = $false

	$currNodeVerStr = $currNodeVerJob | Receive-Job -Wait -AutoRemoveJob
	$uninstallJobs = New-Object -TypeName System.Collections.ArrayList
 	foreach ($nodeVerStr in $currNodeVerStr) {
		 $currNodeVer = New-Object -TypeName version
		 
		 	if (-not [version]::TryParse($nodeVerStr, [ref]$currNodeVer)) {
		 		throw New-Object -TypeName System.FormatException -ArgumentList @("Unable to parse '{$nodeVerStr}' as a nodeJS version.")
		 	}
		 
			$availNodeVers | ForEach-Object -Process {
				if (($newerAvail = ($newerAvail -or ($currNodeVer -lt $_) )) ) {
					$uninstallJobs.Add($(Start-Process -FilePath 'nvm' -ArgumentList @("uninstall $currNodeVer") -NoNewWindow -PassThru)) | Out-Null 
					return 
				} 
			}
	 }
			 
	 if ($newerAvail) {
		 Write-Host "Installing nodejs..."
		 $installNodeJob = Start-ThreadJob -ScriptBlock {
			 param($latestNodeVer)
			 nvm install latest
			 nvm use $latestNodeVer
		 } -ArgumentList $availNodeVers[-1]
		 Receive-Job -Job $installNodeJob -Wait -AutoRemoveJob
	 }
}

Update-NodeJS

# yarn bin folder
if (Test-Path "$nodePath\node_modules\yarn\bin") {
	Add-PathVariable "$nodePath\node_modules\yarn\bin"
}
elseif (Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue) {
	Write-Host "Installing yarn..."
	$npmOutFile = New-TemporaryFile
	Start-Process -FilePath "$nodePath\npm.cmd" -ArgumentList @('install', 'yarn', '-g') -Wait -NoNewWindow -PassThru -RedirectStandardOutput $npmOutFile
	$npmUpdateNotice = Get-Content -Path $npmOutFile | Select-String -Pattern "npm notice Run npm install -g npm@(?<version>$verPattern) to update!"
	$npmVer = $npmUpdateNotice.Matches.Groups | Where-Object -Property  Name -EQ 'version'
	if($null -ne $npmVer){
		$npmVer = $npmVer.Value
		Write-Host "Updating npm to $npmVer..."
		Start-Process -FilePath "$nodePath\npm.cmd" -ArgumentList @('install','-g',"npm@$npmVer") -PassThru -NoNewWindow
	}
	
	
}

# npm global bin folder
Add-PathVariable "$nodePath\node_modules\npm\bin"

# Python is used to install binary node modules
# Add-PathVariable $HOME\.windows-build-tools\python27


$env:NODE_PATH = "$nodePath\node_modules\npm\bin"

# We use a locally installed mocha rather than a global one
# Scope private do we don't call mocha recursively (just in case there is one in path)
function Private:mocha() {
	& node "$nodePath\node_modules\mocha\bin\mocha" --ui tdd --bail --exit $args
}

# Scope private do we don't call yarn recursively!
function Private:yarn() {
	$modifiedArgs = @()
	foreach ( $arg in $args ) {
		# yarn broke 'ls'
		if ( $arg -cmatch '^ls' ) {
			$arg = 'list'
		}
		$modifiedArgs += $arg
		# we're using a monorepo, and only add packages to
		# our workspace if we write them ourselves
		if ( $arg -cmatch 'add' ) {
			$modifiedArgs += '--ignore-workspace-root-check'
		}
	}
	& yarn $modifiedArgs
}
