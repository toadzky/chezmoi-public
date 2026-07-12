#!/bin/sh

export PATH="~/.local/bin:$PATH"
if command -v dcli; then
    echo "Dashlane CLI already installed, proceeding..."
else
    mkdir -p ~/.local/bin
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Dashlane/dashlane-cli/releases/latest | jq '.assets[] | select(.name | contains("linux-x64")) | .url' -r)
    curl -L -o "~/.local/bin/$(basename "$DOWNLOAD_URL")" "dcli"
    chmod +x ~/.local/bin/dcli
fi

# should force login
dcli sync

mkdir -p "$HOME/.config/chezmoi"

dcli note chezmoi -o json | jq '.[0].content | fromjson | .ageKey' -r > "$HOME/.config/chezmoi/key.txt"
chmod 600 "$HOME/.config/chezmoi/key.txt"

TOKEN=$(dcli note chezmoi -o json | jq '.[0].content | fromjson | .githubToken' -r)
sh -c "$(curl -fsLS https://chezmoi.io)" -- init --apply "https://${TOKEN}@github.com/toadzky/chezmoi-private"
