#!/bin/bash
set -e

err() {
    echo "$1" >&2
    exit 1
}

checkvar() {
    if [ "${!1}" = "" ]; then
        err "$2"
    fi
}

checkvar TARGET 'The $TARGET path is not provided.'

PASSWORD_FILE_PATH="$TARGET.password"
ARCHIVE_PATH="$TARGET.tar.gpg.zstd"

if [ -d "$TARGET" ]; then
    if [ -f "$ARCHIVE_PATH" ]; then
        err 'Both $TARGET and archive exist. This is unexpected. Stopping.'
    fi
    PASSWORD="$(cat "$PASSWORD_FILE_PATH" 2>/dev/null || true)"
    if [ "$PASSWORD" = "" ]; then
        read -p "Password: " PASSWORD
    fi
    if tar -I 'zstd -19' -cf - -C "$TARGET" . | gpg --batch --yes --passphrase "$PASSWORD" --symmetric --cipher-algo AES256 --output "$ARCHIVE_PATH" - ; then
        rm -rf "$TARGET"
        shred -fu "$PASSWORD_FILE_PATH" 2>/dev/null || true
        echo "Encrypted successfully"
    else
        rm "$ARCHIVE_PATH"
    fi
else
    if [ ! -f "$ARCHIVE_PATH" ]; then
        err 'No $TARGET or respective archive found.'
    fi
    read -s -p "Password: " PASSWORD
    echo ""
    mkdir -p "$TARGET"
    if gpg --quiet --batch --yes --passphrase "$PASSWORD" --output - --decrypt "$ARCHIVE_PATH" | tar -I zstd -xf - -C "$TARGET" ; then
        rm "$ARCHIVE_PATH"
        echo "$PASSWORD" > "$PASSWORD_FILE_PATH"
        echo "Decrypted successfully"
    else
        rm -rf "$TARGET"
    fi
fi
