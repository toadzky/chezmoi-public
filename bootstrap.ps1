#!/=pwsh

$Local = "$HOME\AppData\Local"
$LocalBin = "$Local\bin"
$Config = "$HOME\AppData\Config"

# Update PATH environment variable for the current session
if ($env:PATH -notlike "*$LocalBin*") {
    $env:PATH = "$LocalBin$([IO.Path]::PathSeparator)$env:PATH"
}

if (Test-Path "Env:\XDG_CONFIG_HOME") {
    Write-Host "Config directory already set, proceeding..."
} else {
    Write-Host "Setting global config directory..."
    [System.Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $Config)
    $env:XDG_CONFIG_HOME = $Config
}

# Ensure Dashlane CLI is installed
if (Get-Command dcli -ErrorAction SilentlyContinue) {
    Write-Host "Dashlane CLI already installed, proceeding..."
} else {
    Write-Host "Installing Dashlane CLI..."
    $null = New-Item -ItemType Directory -Force -Path $LocalBin
    
    # Fetch latest release download URL via GitHub API
    $ReleaseUri = "https://api.github.com/repos/Dashlane/dashlane-cli/releases/latest"
    $Response = Invoke-RestMethod -Uri $ReleaseUri
    
    # Select the Windows x64 binary
    $DownloadUrl = ($Response.assets | Where-Object { $_.name -like "*win-x64*" }).browser_download_url
    $DcliPath = Join-Path $LocalBin "dcli.exe"

    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DcliPath
}

# should force login (Windows handles credentials natively via DPAPI/Credential Manager)
& dcli sync

# Retrieve note details and parse the inner JSON structure
$NoteJson = & dcli note chezmoi -o json | ConvertFrom-Json
$Content = $NoteJson.content | ConvertFrom-Json

$ChezmoiConfigDir = "$Config\chezmoi"
$null = New-Item -ItemType Directory -Force -Path $ChezmoiConfigDir

# Write the ageKey to key.txt
$KeyPath = "$ChezmoiConfigDir/key.txt"
$AgeKey = $Content.ageKey
$AgeKey | Out-File -FilePath $KeyPath -Encoding utf8NoBOM

# Secure key.txt using Windows Access Control Lists (ACL) - Remove all inheritance and give FullControl exclusively to current user
$Acl = Get-Acl -Path $KeyPath
$Acl.SetAccessRuleProtection($true, $false) # Enable protection, don't copy inherited rules
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurrentUser, "FullControl", "Allow")
$Acl.AddAccessRule($AccessRule)
Set-Acl -Path $KeyPath -AclObject $Acl

# Install chezmoi using its native Windows installation script
$Token = $Content.githubToken
Write-Host "Installing chezmoi..."
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$LocalBin'"


Write-Host "Initializing and applying chezmoi configuration..."
& chezmoi init --apply "https://$Token@github.com/toadzky/chezmoi-private"
