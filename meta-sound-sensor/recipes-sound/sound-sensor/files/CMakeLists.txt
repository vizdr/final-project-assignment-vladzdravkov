cmake_minimum_required(VERSION 3.16)
project(sound_detect C)

# Find gpiod library
find_package(PkgConfig REQUIRED)
pkg_check_modules(GPIOD REQUIRED libgpiod)

# Add executable
add_executable(sound_detect sound_detect.c)

# Include directories and link libraries
target_include_directories(sound_detect PRIVATE ${GPIOD_INCLUDE_DIRS})
target_link_libraries(sound_detect PRIVATE ${GPIOD_LIBRARIES})
target_compile_options(sound_detect PRIVATE ${GPIOD_CFLAGS_OTHER})
