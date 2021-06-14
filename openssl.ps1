Add-PathVariable $(Resolve-Path -Path "${env:ProgramFiles}\OpenSSL*\")

# See https://stackoverflow.com/questions/14459078/unable-To-Load-Config-Info-From-Usr-Local-Ssl-Openssl-Cnf
 $env:OPENSSL_CONF = (Get-ChildItem -Filter openssl.cnf -Path $(Resolve-Path -Path "${env:ProgramFiles}\OpenSSL*\") -Recurse).FullName

# $env:RANDFILE="${env:LOCALAPPDATA}\openssl.rnd"

# From https://certsimple.com/blog/openssl-Shortcuts
function Read-Certificate ($file) {
	write-Output "openssl x509 -text -noout -in $file"
	openssl x509 -text -noout -in $file
}

function Read-Csr ($file) {
	write-Output "openssl req -text -noout -verify -in $file"
	openssl req -text -noout -verify -in $file
}

function Read-RsaKey ($file) {
	write-Output openssl rsa -check -in $file
	openssl rsa -check -in $file
}

function Read-RsaKey ($file) {
	write-Output "openssl rsa -check -in $file"
	openssl rsa -check -in $file
}

function Read-EccKey ($file) {
	write-Output "openssl ec -check -in $file"
	openssl ec -check -in $file
}

function Read-Pkcs12 ($file) {
	write-Output "openssl pkcs12 -info -in $file"
	openssl pkcs12 -info -in $file
}

# Connecting to a server (Ctrl C exits)
function Test-OpensslClient ($server) {
	write-Output "openssl s_client -status -connect $server:443"
	openssl s_client -status -connect $server:443
}

# Convert PEM private key, PEM certificate and PEM CA certificate (used by nginx, Apache, and other openssl apps)
# to a PKCS12 file (typically for use with Windows or Tomcat)
function Convert-PemToP12 ($key, $cert, $cacert, $output) {
	write-Output "openssl pkcs12 -export -inkey $key -in $cert -certfile $cacert -out $output"
	openssl pkcs12 -export -inkey $key -in $cert -certfile $cacert -out $output
}

# Convert a PKCS12 file to PEM
function Convert-P12ToPem ($p12file, $pem) {
	write-Output "openssl pkcs12 -nodes -in $p12file -out $pemfile"
	openssl pkcs12 -nodes -in $p12file -out $pemfile
}

# Convert a crt to a pem file
function Convert-CrtToPem($crtfile) {
	write-Output "openssl x509 -in $crtfile -out $basename.pem -outform PEM"
	openssl x509 -in $crtfile -out $basename.pem -outform PEM
}

# Check the modulus of an RSA certificate (to see if it matches a key)
function Show-RsaCertificateModulus {
	write-Output "openssl x509 -noout -modulus -in "${1}" | shasum -a 256"
	openssl x509 -noout -modulus -in "${1}" | shasum -a 256
}

# Check the public point value of an ECDSA certificate (to see if it matches a key)
# See https://security.stackexchange.com/questions/73127/how-Can-You-Check-If-A-Private-Key-And-Certificate-Match-In-Openssl-With-Ecdsa
function Show-EcdsaCertificatePpv-And-Curve {
	write-Output "openssl x509 -in "${1}" -pubkey | shasum -a 256"
	openssl x509 -noout -pubkey -in "${1}" | shasum -a 256
}

# Check the modulus of an RSA key (to see if it matches a certificate)
function Show-RsaKeyModulus {
	write-Output "openssl rsa -noout -modulus -in "${1}" | shasum -a 256"
	openssl rsa -noout -modulus -in "${1}" | shasum -a 256
}

# Check the public point value of an ECDSA key (to see if it matches a certificate)
# See https://security.stackexchange.com/questions/73127/how-Can-You-Check-If-A-Private-Key-And-Certificate-Match-In-Openssl-With-Ecdsa
function Show-EccKeyPpv-And-Curve {
	write-Output "openssl ec -in "${1}" -pubout | shasum -a 256"openssl ec -in key -pubout
	openssl pkey -pubout -in "${1}" | shasum -a 256
}

# Check the modulus of a certificate request
function Show-RsaCsrModulus {
	write-Output openssl req -noout -modulus -in "${1}" | shasum -a 256
	openssl req -noout -modulus -in "${1}" | shasum -a 256
}

# Encrypt a file (because zip crypto isn't secure)
function Protect-File () {
	write-Output openssl aes-256-Cbc -in "${1}" -out "${2}"
	openssl aes-256-Cbc -in "${1}" -out "${2}"
}

# Decrypt a file
function Unprotect-File () {
	write-Output aes-256-Cbc -d -in "${1}" -out "${2}"
	openssl aes-256-Cbc -d -in "${1}" -out "${2}"
}

# For setting up public key pinning
function Convert-KeyToHpkp-Pin() {
	write-Output openssl rsa -in "${1}" -outform der -pubout | openssl dgst -sha256 -binary | openssl enc -base64
	openssl rsa -in "${1}" -outform der -pubout | openssl dgst -sha256 -binary | openssl enc -base64
}

# For setting up public key pinning (directly from the site)
function Convert-WebsiteToHpkp-Pin() {
	write-Output openssl s_client -connect "${1}":443 | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
	openssl s_client -connect "${1}":443 | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
}
