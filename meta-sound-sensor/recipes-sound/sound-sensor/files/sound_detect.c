// sound_detect.c
#include <stdio.h>
#include <unistd.h>
#include <gpiod.h>
#include <sys/file.h>

// Missing required POSIX headers:
#include <signal.h>       // sig_atomic_t, siginfo_t, sigaction, SIGALRM
#include <string.h>       // memset()
#include <sys/time.h>     // struct itimerval, setitimer()
#include <errno.h>
#include <stdlib.h>

#define GPIO_CHIP "/dev/gpiochip0"
#define SOUND_PIN 17
#define READWRITEFILETPATH "/var/tmp/audio_detection"

volatile sig_atomic_t timer_fired = 0;
volatile sig_atomic_t reset_counter = 0;

#include <sys/file.h>

void write_count_safe(FILE *file, int number)
{
    int fd = fileno(file);

    // Exclusive lock
    flock(fd, LOCK_EX);

    fseek(file, 0, SEEK_SET);
    fprintf(file, "%d\n", number);
    fflush(file);
    ftruncate(fd, ftell(file));

    // Unlock
    flock(fd, LOCK_UN);
}


// ========== Timer functions ==========
void alarm_handler(int signo, siginfo_t *info, void *context)
{
    (void)signo;
    (void)info;
    (void)context;
    timer_fired = 1; // flag for periodic work outside signal context
}

void launch_periodic_timer()
{
    struct sigaction sa;
    struct itimerval timer_val;

    // Install timer_handler as the signal handler for SIGALRM.
    memset(&sa, 0, sizeof(sa));
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = alarm_handler;
    sigaction(SIGALRM, &sa, NULL);

    // Configure the timer to expire after 5 sec... */
    timer_val.it_value.tv_sec = 5;
    timer_val.it_value.tv_usec = 0;
    // ... and every 5 sec after that.
    timer_val.it_interval.tv_sec = 5;
    timer_val.it_interval.tv_usec = 0;
    // Start a real timer.
    if (setitimer(ITIMER_REAL, &timer_val, NULL) == -1)
    {
        perror("Error calling setitimer");
        return;
    }
    return;
}


int main(void) {
    struct gpiod_chip *chip;
    struct gpiod_line *line;
    int value;
    int detection_count = 0;
    FILE *file_count;

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

    file_count = fopen(READWRITEFILETPATH, "w+");
    if (!file_count) {
        perror("Open file failed");
        gpiod_chip_close(chip);
        return 1;
    }
    write_count_safe(file_count, 0);

    launch_periodic_timer();

    while (1) {

        if (timer_fired)
        {
            reset_counter++;
            if (reset_counter >= 12) // every minute
            {
                detection_count = 0; // reset counter
                reset_counter = 0;
                printf("Detection count reset.\n");
            }
            // Write detection count to file
            fseek(file_count, 0, SEEK_SET);
            fprintf(file_count, "%d\n", detection_count);
            fflush(file_count);
            ftruncate(fileno(file_count), ftell(file_count));
            printf("Written to file count of detections: %d\n", detection_count);
            timer_fired = 0; // reset flag
        }

        value = gpiod_line_get_value(line);
        if (value < 0) {
            perror("Read line failed");
            break;
        }
        printf("Sound detected: %s\n", value ? "YES" : "NO");
        printf("Raw GPIO value: %d\n", value);
        if (value) {
            detection_count++;
            printf("Total detections: %d\n", detection_count);
        }
        usleep(500000); // 0.5s delay
    }

    fclose(file_count);
    gpiod_chip_close(chip);
    return 0;
}
// End of sound_detect.c