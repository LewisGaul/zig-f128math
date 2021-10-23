#ifndef UTIL_H
#define UTIL_H


#include <quadmath.h>


typedef __uint128_t  uint128_t;
typedef float        float32_t;
typedef double       float64_t;
typedef __float128   float128_t;

#define HEX32  "0x%08x"
#define HEX64  "0x%016lx"
#define HEX128 "0x%016lx%016lx"

#define DEBUG_ENABLED 1

#define DEBUG(fmt, ...)             \
    do {                            \
        if (DEBUG_ENABLED)          \
            printf(fmt,__VA_ARGS__);\
    } while (0)

// TODO: Not working for some reason... prints nothing with no warnings.
#define quadmath_printf(fmt, ...)                               \
    do {                                                        \
        char buf[256] = {};                                     \
        quadmath_snprintf(buf, sizeof(buf), fmt, __VA_ARGS__);  \
        printf("%s", buf);                                      \
    } while (0)


#endif  // UTIL_H
