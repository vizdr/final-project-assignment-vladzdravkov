# meta-sound-sensor

This Yocto layer adds support for the Waveshare sound sensor on Raspberry Pi.  
It includes a C program (`sound_detect`) that reads digital sound input using `libgpiod`.

## Installation

Add the layer to your build:

```bash
bitbake-layers add-layer ../meta-sound-sensor