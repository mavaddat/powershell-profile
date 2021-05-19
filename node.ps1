Add-PathVariable "$nodePath"

# Add relative node_modules\.bin to PATH - this allows us to easily use local bin files and fewer things installed globally
# Add-PathVariable '.\node_modules\.bin'

$availNodeVers = New-Object -TypeName System.Collections.ArrayList
$verPattern = [regex]::new("(?:\d+\.?){3}")

$addVersJob = (Start-ThreadJob -ScriptBlock {
	param($availNodeVers,$verPattern)
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

$currNodeVer = $currNodeVerJob | Receive-Job -Wait -AutoRemoveJob

$newerAvail = ($availNodeVers | ForEach-Object -Begin { $newerAvail = $false } -Process {
	 if ($newerAvail) { return } $newerAvail = $newerAvail -or ($currNodeVer -lt $_) 
	} -End { $newerAvail })

if ($newerAvail) {
	Write-Host "Installing nodejs..."
	$installNodeJob = Start-ThreadJob -ScriptBlock {
		param($latestNodeVer,$currNodeVer)
		nvm install latest
		nvm use $latestNodeVer
		nvm uninstall $currNodeVer
	} -ArgumentList $availNodeVers[-1], $currNodeVer
}

$nodePath = Resolve-Path (Join-Path "$("$(nvm root)" -replace ".*([A-Z]:\\)",'$1')" 'v*[0-9]*')

# yarn bin folder
if (Test-Path "$nodePath\node_modules\yarn\bin") {
	Add-PathVariable "$nodePath\node_modules\yarn\bin"
}
elseif (Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue) {
	Write-Host "Installing yarn..."
	Start-ThreadJob -ScriptBlock {
		&"$nodePath\npm" install yarn -g
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

Receive-Job -Job $installNodeJob -Wait -AutoRemoveJob