#!/bin/bash
set -e

CONFIG_URL="https://raw.githubusercontent.com/adityapandey189/EulerOsWeb/main/emulator.env"

CONFIG_FILE="/tmp/emulator.env"
DATA_DIR="/data"
IMAGE_DIR="$DATA_DIR/android-image"
VERSION_FILE="$DATA_DIR/installed-version"

echo "======================================"
echo " EulerOS Emulator Image Manager"
echo "======================================"

echo "Fetching configuration from GitHub..."

curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE"

source "$CONFIG_FILE"

echo "Latest version: $IMAGE_VERSION"
echo "Image name:     $IMAGE_NAME"

INSTALLED_VERSION=""

if [ -f "$VERSION_FILE" ]; then
    INSTALLED_VERSION=$(cat "$VERSION_FILE")
fi

echo "Installed:      ${INSTALLED_VERSION:-none}"

if [ "$INSTALLED_VERSION" != "$IMAGE_VERSION" ]; then

    echo "New emulator image detected."

    ZIP_FILE="$DATA_DIR/$IMAGE_NAME"

    echo "Downloading from Google Drive..."

    gdown \
        --fuzzy \
        "$IMAGE_URL" \
        -O "$ZIP_FILE"

    echo "Download complete."

    rm -rf "$IMAGE_DIR"
    mkdir -p "$IMAGE_DIR"

    echo "Extracting image..."

    unzip -q "$ZIP_FILE" -d "$IMAGE_DIR"

    echo "Extraction complete."

    rm -f "$ZIP_FILE"

    echo "$IMAGE_VERSION" > "$VERSION_FILE"

    echo "Installed version $IMAGE_VERSION."

else

    echo "Image already up to date."

fi

echo ""
echo "===== Android image files ====="

find "$IMAGE_DIR" -maxdepth 2 -type f

echo ""
echo "Container ready."

tail -f /dev/null
