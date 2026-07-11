$TOKEN   = Read-Host -Prompt "Enter your private GitHub PAT" -AsSecureString
$AGE_KEY =  Read-Host -Prompt "Enter your Age Secret Key (age1...)" -AsSecureString


New-Item -ItemType Directory -Force -Path "$HOME\.config\chezmoi"
Set-Content -Path "$HOME\.config\chezmoi\key.txt" -Value $AGE_KEY

irm https://chezmoi.io | iex
chezmoi init --apply "https://${TOKEN}github.com/toadzky/chezmoi-private"
