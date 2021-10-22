#ifndef UTIL_H
#define UTIL_H

#include <stdarg.h>
#include <stdio.h>


#define HEX32 "0x%08x"
#define HEX64 "0x%016lx"

#define DEBUG_ENABLED 1

#define DEBUG(fmt, ...)             \
    do {                            \
        if (DEBUG_ENABLED)          \
            printf(fmt,__VA_ARGS__);\
    } while (0)


#endif  // UTIL_H
