#!/bin/sh

KEYRING_DIR="$HOME/.local/share/keyrings"
DEFAULT_KEYRING="$KEYRING_DIR/login.keyring"
if [ -f "$DEFAULT_KEYRING" ]; then
    echo "Keyring already setup up, proceeding..."
else
    echo "No default keyring found. Creating for Dashlane CLI..."
    mkdir -p "$KEYRING_DIR"

    # Write the login keyring file framework
    printf "[keyring]
display-name=login
lock-on-idle=false
lock-after=false
" > $DEFAULT_KEYRING

    # Ensure permissions are secure (read/write only by owner)
    chmod 700 "$KEYRING_DIR"
    chmod 600 "$DEFAULT_KEYRING"

    gnome-keyring-daemon --replace

    echo "Skeleton 'login' keyring injected. It will prompt for a password upon next application access."
fi

export PATH="$HOME/.local/bin:$PATH"
if command -v dcli; then
    echo "Dashlane CLI already installed, proceeding..."
else
    mkdir -p ~/.local/bin
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Dashlane/dashlane-cli/releases/latest | jq '.assets[] | select(.name | contains("linux-x64")) | .browser_download_url' -r)
    curl -L -o "$HOME/.local/bin/dcli" "$DOWNLOAD_URL"
    chmod +x ~/.local/bin/dcli
fi

# should force login
dcli sync

mkdir -p "$HOME/.config/chezmoi"

dcli note chezmoi -o json | jq '.[0].content | fromjson | .ageKey' -r > "$HOME/.config/chezmoi/key.txt"
chmod 600 "$HOME/.config/chezmoi/key.txt"

TOKEN=$(dcli note chezmoi -o json | jq '.[0].content | fromjson | .githubToken' -r)
echo "Installing chezmoi..."
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)"

echo "Initilizing and applying chezmoi configuration..."
chezmoi init --apply "https://${TOKEN}@github.com/toadzky/chezmoi-private"
