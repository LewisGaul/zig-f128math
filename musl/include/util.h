#ifndef UTIL_H
#define UTIL_H


typedef long long unsigned uint128_t;
typedef float              float32_t;
typedef double             float64_t;
typedef long double        float128_t;

#define HEX32  "0x%08x"
#define HEX64  "0x%016lx"
#define HEX128 "0x%032llx"

#define DEBUG_ENABLED 1

#define DEBUG(fmt, ...)             \
    do {                            \
        if (DEBUG_ENABLED)          \
            printf(fmt,__VA_ARGS__);\
    } while (0)


#endif  // UTIL_H
