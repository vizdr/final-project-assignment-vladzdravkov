#!/bin/bash
# Script to build image for raspberry pi 4 using Yocto Project
# Author: Siddhant Jajoo, Vladimir Zdravkov.

############################################################
# Add required layers

add_layer_if_missing() {
    LAYER_NAME=$1
    LAYER_PATH=$2

    # Convert to absolute path
    LAYER_ABS_PATH=$(readlink -f "$LAYER_PATH")
    
    if [ ! -d "$LAYER_ABS_PATH" ]; then
        echo "Error: Layer path $LAYER_ABS_PATH not found!"
        exit 1
    fi

    if ! bitbake-layers show-layers | grep -q "$LAYER_ABS_PATH"; then
        echo "Adding $LAYER_NAME layer..."
        bitbake-layers add-layer "$LAYER_ABS_PATH"
    else
        echo "$LAYER_NAME layer already added."
    fi
}

############################################################
# Append to local.conf if missing

append_line_if_missing() {
    local line="$1"
    if ! grep -qF "$line" conf/local.conf; then
        echo "Appending: $line"
        echo "$line" >> conf/local.conf
    fi
}

############################################################
# Clean command

if [ "$1" = "clean" ]; then
    echo "Cleaning Yocto build directories..."
    rm -rf tmp sstate-cache downloads cache
    echo "Cleanup complete."
    exit 0
fi
############################################################
# Main script starts here

PROJECT_ROOT="$(pwd)"
set -e
UPDATE_LAYERS=false

# Optional flag: ./build.sh --update to force layer sync
if [[ "$1" == "--update" ]]; then
    UPDATE_LAYERS=true
    echo "Forcing Yocto layer update..."
fi

# Define desired versions/tags/commits
POKY_TAG="yocto-4.0.29"
META_RPI_COMMIT="255500dd9f6a01a3445ac491d1abc401801e3bad"
META_OE_COMMIT="96fbc156364fd78530d2bfbe1b8a77789f52997d"

declare -A LAYER_VERSION_MAP=(
  [poky]="$POKY_TAG"
  [meta-raspberrypi]="$META_RPI_COMMIT"
  [meta-openembedded]="$META_OE_COMMIT"
)

# Initialize submodules only if missing
if [ ! -d "poky" ]; then
    echo "Initializing and updating git submodules..."
    git submodule sync
    git submodule update
else
    echo "✅ Submodules already initialized."
fi

# Loop through and pin each layer
for layer in "${!LAYER_VERSION_MAP[@]}"; do
    if [ -d "$layer" ]; then
        cd "$layer"
        current_commit=$(git rev-parse HEAD)
        target="${LAYER_VERSION_MAP[$layer]}"

        if $UPDATE_LAYERS; then
            echo "→ Updating $layer to $target ..."
            git fetch --all --tags
            git checkout "$target"
        else
            # Only checkout if current commit doesn't match
            if ! git merge-base --is-ancestor "$target" "$current_commit" 2>/dev/null; then
                echo "→ Checking out $layer to pinned version $target ..."
                git fetch --all --tags
                git checkout "$target"
            else
                echo "✅ $layer already at desired version ($target)"
            fi
        fi
        cd "$PROJECT_ROOT"
    else
        echo "⚠️  Layer $layer not found!"
    fi
done

############################################################
# local.conf won't exist until this step on first execution
source poky/oe-init-build-env

############################################################
# Configuration variables for local.conf
############################################################

# Machine & image
MACHINE_LINE='MACHINE = "raspberrypi0-2w-64"'
IMAGE_LINE='IMAGE_FSTYPES = "wic.bz2"'

# GPU memory
GPU_MEM_LINE='GPU_MEM = "16"'

# License
LICENSE_LINE='LICENSE_FLAGS_ACCEPTED = "commercial"'

# Extra image features
EXTRA_FEATURES_LINE='EXTRA_IMAGE_FEATURES = "debug-tweaks ssh-server-openssh"'

# Distribution features
DISTRO_FEATURES_LINE='DISTRO_FEATURES:append = " wifi systemd gpio"'

# UART
UART_LINE='ENABLE_UART = "1"'

# Wireless runtime fix
# WIRELESS_RUNTIME_LINE='VIRTUAL-RUNTIME_wireless-tools = ""'

# Packages
# Consolidated IMAGE_INSTALL_APPEND line
IMAGE_INSTALL_APPEND='IMAGE_INSTALL:append = " linux-firmware-bcm43430 wpa-supplicant iw openssh libgpiod libgpiod-tools sound-sensor can-utils iproute2 can-init "'

#----------------------------------------------------------
# CAN-related configuration for Waveshare RS485 CAN HAT Rev 2.1
# (12 MHz crystal, interrupt on GPIO25)
ENABLE_SPI_LINE='ENABLE_SPI = "1"'
CAN_DTO='RPI_EXTRA_CONFIG = "dtoverlay=mcp2515-can0,oscillator=12000000,interrupt=25,spimaxfrequency=5000000 dtoverlay=spi1-1cs"'
CAN_TOOLS='IMAGE_INSTALL:append = " can-utils iproute2 "'
CAN_INIT='IMAGE_INSTALL:append = " can-init "'

############################################################
# Append configuration lines to local.conf
############################################################
# -------------------------

append_line_if_missing "$MACHINE_LINE"
append_line_if_missing "$IMAGE_LINE"
append_line_if_missing "$GPU_MEM_LINE"
append_line_if_missing "$LICENSE_LINE"
append_line_if_missing "$EXTRA_FEATURES_LINE"
append_line_if_missing "$DISTRO_FEATURES_LINE"
append_line_if_missing "$UART_LINE"
append_line_if_missing "$ENABLE_SPI_LINE"
append_line_if_missing "$CAN_DTO"
append_line_if_missing "$IMAGE_INSTALL_APPEND"

# -------------------------
# Add required layers
# -------------------------
add_layer_if_missing "meta-raspberrypi" "$PROJECT_ROOT/meta-raspberrypi"
add_layer_if_missing "meta-openembedded" "$PROJECT_ROOT/meta-openembedded/meta-oe"
add_layer_if_missing "meta-python" "$PROJECT_ROOT/meta-openembedded/meta-python"
add_layer_if_missing "meta-networking" "$PROJECT_ROOT/meta-openembedded/meta-networking"
add_layer_if_missing "meta-aesd" "$PROJECT_ROOT/meta-aesd"
add_layer_if_missing "meta-sound-sensor" "$PROJECT_ROOT/meta-sound-sensor"
add_layer_if_missing "meta-can" "$PROJECT_ROOT/meta-can"
add_layer_if_missing "meta-can-server" "$PROJECT_ROOT/meta-can-server"

############################################################
# Build summary
############################################################
echo "=============================================="
echo "Yocto build configuration summary:"
echo "Machine:        raspberrypi0-2w-64"
echo "Layers:         meta-raspberrypi, meta-openembedded, meta-python, meta-networking, meta-aesd, meta-sound-sensor, meta-can"
echo "Image type:     wic.bz2"
echo "Wi-Fi:          enabled (bcm43430 firmware)"
echo "SSH:            enabled (OpenSSH)"
echo "GPIO support:   enabled (libgpiod tools)"
echo "Sound sensor:   enabled (sound_detect C program)"
echo "UART:           enabled"
echo "CAN bus:        enabled (Waveshare RS485 CAN HAT Rev 2.1)"
echo "Extra features: debug-tweaks"
echo "=============================================="
echo ""
echo "Current layers:"
bitbake-layers show-layers
###########################################################
# bitbake core-image-aesd
bitbake core-image-base