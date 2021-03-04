Add-PathVariable "${env:ProgramFiles}\nodejs"

# Add relative node_modules\.bin to PATH - this allows us to easily use local bin files and fewer things installed globally
# Add-PathVariable '.\node_modules\.bin'

# yarn bin folder
if(Test-Path "${env:ProgramFiles}\nodejs\node_modules\yarn\bin"){
	Add-PathVariable "${env:ProgramFiles}\nodejs\node_modules\yarn\bin"
}
elseif(Get-Command nvm.exe -CommandType Application -ErrorAction SilentlyContinue) {
	Write-Host "Installing nodejs..."
	Start-ThreadJob -ScriptBlock {
		$nodejsVer = [version]::new((nvm list | Select-String "(?<=\*\s*)([\d\.]{3,})").Matches.Groups[1].Value)
		$nodejsAvailable = $((nvm list available) -split '\|' | Select-String -Pattern "([\d\.]{3,})" -AllMatches).Matches.Groups.ForEach({[version]::new($_)})
		$nodejsLatest = $nodejsAvailable | Select-First -First 1
		if($nodejsLatest -ne $nodejsVer){
			# install latest
			nvm install latest
			nvm use "$($nodejsLatest.ToString())"
		}
		Start-ThreadJob -ScriptBlock {
			#remove old versions
			nvm list | ForEach-Object {
			if($_ -notmatch '\*') {
					nvm uninstall $_
				}
			}}
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
