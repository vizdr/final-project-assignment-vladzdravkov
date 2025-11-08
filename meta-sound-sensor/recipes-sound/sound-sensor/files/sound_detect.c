// sound_detect.c
#include <stdio.h>
#include <unistd.h>
#include <gpiod.h>

#define GPIO_CHIP "/dev/gpiochip0"
#define SOUND_PIN 17

int main(void) {
    struct gpiod_chip *chip;
    struct gpiod_line *line;
    int value;

    printf("Starting sound detection...\n");

    chip = gpiod_chip_open(GPIO_CHIP);
    if (!chip) {
        perror("Open chip failed");
        return 1;
    }

    line = gpiod_chip_get_line(chip, SOUND_PIN);
    if (!line) {
        perror("Get line failed");
        gpiod_chip_close(chip);
        return 1;
    }

    if (gpiod_line_request_input(line, "sound_detect") < 0) {
        perror("Request line as input failed");
        gpiod_chip_close(chip);
        return 1;
    }

    while (1) {
        value = gpiod_line_get_value(line);
        if (value < 0) {
            perror("Read line failed");
            break;
        }
        printf("Sound detected: %s\n", value ? "YES" : "NO");
        printf("Raw GPIO value: %d\n", value);

        usleep(500000); // 0.5s delay
    }

    gpiod_chip_close(chip);
    return 0;
}
// End of sound_detect.c