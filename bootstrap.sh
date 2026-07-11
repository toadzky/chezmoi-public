#!/bin/sh
read -p -s "Enter your private GitHub PAT: " TOKEN
read -p -s "Enter your Age Secret Key: " AGE_KEY

mkdir -p "$HOME/.config/chezmoi"
echo "$AGE_KEY" > "$HOME/.config/chezmoi/key.txt"
chmod 600 "$HOME/.config/chezmoi/key.txt"

sh -c "$(curl -fsLS https://chezmoi.io)" -- init --apply "https://${TOKEN}@github.com/toadzky/chezmoi-private"
