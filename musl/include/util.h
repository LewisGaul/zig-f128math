#ifndef UTIL_H
#define UTIL_H


#include <math.h>
#include <quadmath.h>


typedef __uint128_t  uint128_t;
typedef float        float32_t;
typedef double       float64_t;
typedef __float128   float128_t;

#define HEX32  "0x%08X"
#define HEX64  "0x%016lX"
#define HEX128 "0x%016lX%016lX"


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


/* From FreeBSD's fpmath.h */
union IEEEl2bits {
  float128_t e;
  struct {
    unsigned long manl  :64;
    unsigned long manh  :48;
    unsigned int  exp   :15;
    unsigned int  sign  :1;
  } bits;
  struct {
    unsigned long manl     :64;
    unsigned long manh     :48;
    unsigned int  expsign  :16;
  } xbits;
};

static inline float32_t
float32FromBits(uint32_t x)
{
    return *(float32_t *)&x;
}

static inline float64_t
float64FromBits(uint64_t x)
{
    return *(float64_t *)&x;
}

static inline float128_t
float128FromBits(uint128_t x)
{
    return *(float128_t *)&x;
}

#endif  // UTIL_H
