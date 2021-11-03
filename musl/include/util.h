#ifndef UTIL_H
#define UTIL_H


#include <math.h>
#include <quadmath.h>


typedef __uint128_t  uint128_t;
typedef float        float32_t;
typedef double       float64_t;
typedef __float128   float128_t;

#define HEX32  "0x%08x"
#define HEX64  "0x%016lx"
#define HEX128 "0x%016lx%016lx"


#define DEBUG_ENABLED 0

#define DEBUG(fmt, ...)             \
    do {                            \
        if (DEBUG_ENABLED)          \
            printf(fmt,__VA_ARGS__);\
    } while(0)


#define FORCE_EVAL(x) do {                        \
    if (sizeof(x) == sizeof(float32_t)) {         \
        volatile float32_t __x;                   \
        __x = (x);                                \
    } else if (sizeof(x) == sizeof(float64_t)) {  \
        volatile float64_t __x;                   \
        __x = (x);                                \
    } else {                                      \
        volatile float128_t __x;                  \
        __x = (x);                                \
    }                                             \
} while(0)


/* Get a 32 bit int from a float.  */
#define GET_FLOAT_WORD(w,d)                       \
do {                                              \
  union {float32_t f; uint32_t i;} __u;           \
  __u.f = (d);                                    \
  (w) = __u.i;                                    \
} while (0)

/* Get the more significant 32 bit int from a double.  */
#define GET_HIGH_WORD(hi,d)                       \
do {                                              \
  union {float64_t f; uint64_t i;} __u;           \
  __u.f = (d);                                    \
  (hi) = __u.i >> 32;                             \
} while (0)

#endif  // UTIL_H
