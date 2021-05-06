Add-PathVariable "${env:ProgramFiles}\nodejs"

# Add relative node_modules\.bin to PATH - this allows us to easily use local bin files and fewer things installed globally
# Add-PathVariable '.\node_modules\.bin'

$availNodeVers = New-Object -TypeName System.Collections.ArrayList
$verPattern = [regex]::new("(\d+\.\d+\.\d+)")
$currNodeVer = New-Object -TypeName version -ArgumentList @((nvm list | Select-String $verPattern).Matches.Value)

nvm list available  | ForEach-Object{ (Select-String -InputObject $_ -Pattern $verPattern -AllMatches).Matches | ForEach-Object{ $ver = New-Object -TypeName version; if ([version]::TryParse($_.Value, [ref]$ver)) {$availNodeVers.Add($ver) | Out-Null }  } }

$availNodeVers.Sort() | Out-Null

$newerAvail = ($availNodeVers | ForEach-Object -Begin {$newerAvail = $false} -Process {if($newerAvail){return} $newerAvail = $newerAvail -or ($currNodeVer -lt $_)} -End {$newerAvail})

if($newerAvail){
	Write-Host "Installing nodejs..."
	Start-ThreadJob -ScriptBlock {
		nvm install latest
		nvm use $availNodeVers[-1]
		nvm uninstall $currNodeVer
	}
}

# yarn bin folder
if(Test-Path "${env:ProgramFiles}\nodejs\node_modules\yarn\bin"){
	Add-PathVariable "${env:ProgramFiles}\nodejs\node_modules\yarn\bin"
}
elseif(Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue) {
	Write-Host "Installing yarn..."
	Start-ThreadJob -ScriptBlock {
		npm install yarn -g
	}
	
}

# npm global bin folder
Add-PathVariable "${env:ProgramFiles}\nodejs\node_modules\npm\bin"

# Python is used to install binary node modules
# Add-PathVariable $HOME\.windows-build-tools\python27


$env:NODE_PATH = "${env:ProgramFiles}\nodejs\node_modules\npm\bin"

# We use a locally installed mocha rather than a global one
# Scope private do we don't call mocha recursively (just in case there is one in path)
function Private:mocha() {
	& node "${env:ProgramFiles}\nodejs\node_modules\mocha\bin\mocha" --ui tdd --bail --exit $args
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
