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

append_if_missing() {
    local pattern="$1"
    local line="$2"
    if ! grep -qF "$pattern" conf/local.conf; then
        echo "Appending: $line"
        echo "$line" | tee -a conf/local.conf
    else
        echo "Already present: $pattern"
    fi
}
############################################################

if [ "$1" = "clean" ]; then
    echo "Cleaning Yocto build directories..."
    rm -rf tmp sstate-cache downloads cache
    echo "Cleanup complete."
    exit 0
fi

# Main script starts here

PROJECT_ROOT="$(pwd)"

set -e

git submodule init
git submodule sync
git submodule update

# Ensure all submodules are on kirkstone branch
for layer in poky meta-raspberrypi meta-openembedded; do
    if [ -d "$layer" ]; then
        echo "Checking out $layer to kirkstone branch..."
        cd "$layer"
        git fetch --all --tags
        git checkout kirkstone || git checkout -b kirkstone origin/kirkstone
        git pull origin kirkstone || true
        cd "$PROJECT_ROOT"
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
WIRELESS_RUNTIME_LINE='VIRTUAL-RUNTIME_wireless-tools = ""'

# Packages
WIFI_PKGS='IMAGE_INSTALL:append = " linux-firmware-bcm43430 wpa-supplicant iw openssh "'
GPIO_PKGS='IMAGE_INSTALL:append = " libgpiod libgpiod-tools "'
SOUND_SENSOR_PKGS='IMAGE_INSTALL:append = " sound-sensor "'

############################################################
# Append configuration lines to local.conf
############################################################
append_if_missing "$MACHINE_LINE" "$MACHINE_LINE"
append_if_missing "$IMAGE_LINE" "$IMAGE_LINE"
append_if_missing "$GPU_MEM_LINE" "$GPU_MEM_LINE"
append_if_missing "$LICENSE_LINE" "$LICENSE_LINE"
append_if_missing "$EXTRA_FEATURES_LINE" "$EXTRA_FEATURES_LINE"
append_if_missing "$DISTRO_FEATURES_LINE" "$DISTRO_FEATURES_LINE"
append_if_missing "$UART_LINE" "$UART_LINE"
append_if_missing "$WIRELESS_RUNTIME_LINE" "$WIRELESS_RUNTIME_LINE"

# Packages
append_if_missing 'IMAGE_INSTALL:append = " linux-firmware-bcm43430 wpa-supplicant iw openssh "' "$WIFI_PKGS"
append_if_missing 'IMAGE_INSTALL:append = " libgpiod libgpiod-tools "' "$GPIO_PKGS"
append_if_missing 'IMAGE_INSTALL:append = " sound-sensor "' "$SOUND_SENSOR_PKGS"

############################################################
# Add required layers
############################################################
add_layer_if_missing "meta-raspberrypi" "../meta-raspberrypi"
add_layer_if_missing "meta-openembedded" "../meta-openembedded/meta-oe"
add_layer_if_missing "meta-python" "../meta-openembedded/meta-python"
add_layer_if_missing "meta-networking" "../meta-openembedded/meta-networking"
add_layer_if_missing "meta-aesd" "../meta-aesd"
add_layer_if_missing "meta-sound-sensor" "../meta-sound-sensor"

############################################################
# Build summary
############################################################
echo "=============================================="
echo "Yocto build configuration summary:"
echo "Machine:        raspberrypi0-2w-64"
echo "Layers:         meta-raspberrypi, meta-openembedded, meta-python, meta-networking, meta-aesd, meta-sound-sensor"
echo "Image type:     wic.bz2"
echo "Wi-Fi:          enabled (bcm43430 firmware)"
echo "SSH:            enabled (OpenSSH)"
echo "GPIO support:   enabled (libgpiod tools)"
echo "Sound sensor:   enabled (sound_detect C program)"
echo "UART:           enabled"
echo "Extra features: debug-tweaks"
echo "=============================================="
echo ""
echo "Current layers:"
bitbake-layers show-layers
###########################################################
# bitbake core-image-aesd
bitbake core-image-base