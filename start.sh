#!/bin/bash
set -e

CONFIG_URL="https://raw.githubusercontent.com/adityapandey189/EulerOsWeb/main/emulator.env"

CONFIG_FILE="/tmp/emulator.env"
DATA_DIR="/data"
IMAGE_DIR="$DATA_DIR/android-image"
PRODUCT="$IMAGE_DIR/x86_64"
VERSION_FILE="$DATA_DIR/installed-version"

AVD_HOME="$DATA_DIR/avd"
AVD_NAME="EulerOS_Tablet"
AVD_DIR="$AVD_HOME/${AVD_NAME}.avd"

echo "======================================"
echo " EulerOS Android 10 Tablet"
echo "======================================"

echo "Fetching configuration..."

curl -fsSL "$CONFIG_URL" -o "$CONFIG_FILE"
source "$CONFIG_FILE"

echo "Latest image version: $IMAGE_VERSION"
echo "Image name:           $IMAGE_NAME"

INSTALLED_VERSION=""

if [ -f "$VERSION_FILE" ]; then
    INSTALLED_VERSION=$(cat "$VERSION_FILE")
fi

echo "Installed version:    ${INSTALLED_VERSION:-none}"

# -------------------------------------------------------
# Download/update EulerOS
# -------------------------------------------------------

if [ "$INSTALLED_VERSION" != "$IMAGE_VERSION" ]; then

    echo "New EulerOS image detected."

    ZIP_FILE="$DATA_DIR/$IMAGE_NAME"

    echo "Downloading EulerOS image..."

    gdown "$IMAGE_URL" -O "$ZIP_FILE"

    echo "Download complete."

    rm -rf "$IMAGE_DIR"
    mkdir -p "$IMAGE_DIR"

    echo "Extracting image..."

    unzip -q "$ZIP_FILE" -d "$IMAGE_DIR"

    rm -f "$ZIP_FILE"

    echo "$IMAGE_VERSION" > "$VERSION_FILE"

    echo "Installed EulerOS version $IMAGE_VERSION."

else

    echo "EulerOS image already up to date."

fi

# -------------------------------------------------------
# Validate required Android images
# -------------------------------------------------------

echo ""
echo "Checking Android images..."

REQUIRED_FILES=(
    "kernel-ranchu"
    "ramdisk.img"
    "system.img"
    "vendor.img"
    "userdata.img"
)

for FILE in "${REQUIRED_FILES[@]}"; do

    if [ ! -f "$PRODUCT/$FILE" ]; then
        echo "ERROR: Missing:"
        echo "$PRODUCT/$FILE"
        exit 1
    fi

done

echo "Android images found."

# -------------------------------------------------------
# Create Android 10 Tablet AVD
# -------------------------------------------------------

echo ""
echo "Creating Android 10 tablet AVD..."

mkdir -p "$AVD_HOME"
mkdir -p "$AVD_DIR"

cat > "$AVD_HOME/${AVD_NAME}.ini" <<EOF
avd.ini.encoding=UTF-8
path=$AVD_DIR
target=android-29
EOF

cat > "$AVD_DIR/config.ini" <<EOF
AvdId=$AVD_NAME
avd.ini.displayname=EulerOS Android 10 Tablet

abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=2

hw.ramSize=2048

hw.lcd.width=1920
hw.lcd.height=1200
hw.lcd.density=240

hw.keyboard=yes
hw.mainKeys=no

hw.gpu.enabled=no
hw.gpu.mode=off

disk.dataPartition.size=4G

image.sysdir.1=$PRODUCT/

tag.display=EulerOS
tag.id=default
EOF

export ANDROID_AVD_HOME="$AVD_HOME"

echo "AVD created:"
/opt/android-sdk/emulator/emulator -list-avds

# -------------------------------------------------------
# Check KVM
# -------------------------------------------------------

echo ""
echo "Checking KVM..."

if [ ! -e /dev/kvm ]; then
    echo "ERROR: /dev/kvm is not available."
    echo "Start Docker with:"
    echo "  --device=/dev/kvm:/dev/kvm"
    exit 1
fi

/opt/android-sdk/emulator/emulator -accel-check || true

# -------------------------------------------------------
# Start ADB
# -------------------------------------------------------

echo ""
echo "Starting ADB..."

adb start-server

# -------------------------------------------------------
# Start Android Emulator
# -------------------------------------------------------

echo ""
echo "======================================"
echo " Starting EulerOS Android 10 Tablet"
echo " Resolution: 1920x1200"
echo " Density:    240 dpi"
echo " API:        29"
echo " ABI:        x86_64"
echo "======================================"

exec /opt/android-sdk/emulator/emulator \
    @"$AVD_NAME" \
    -sysdir "$PRODUCT" \
    -kernel "$PRODUCT/kernel-ranchu" \
    -ramdisk "$PRODUCT/ramdisk.img" \
    -system "$PRODUCT/system.img" \
    -vendor "$PRODUCT/vendor.img" \
    -initdata "$PRODUCT/userdata.img" \
    -no-window \
    -no-audio \
    -no-snapshot \
    -accel on \
    -gpu off \
    -verbose
