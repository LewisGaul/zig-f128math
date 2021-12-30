#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>


typedef __uint128_t  uint128_t;
typedef float        float32_t;
typedef double       float64_t;
typedef __float128   float128_t;

#define HEX32  "0x%08X"
#define HEX64  "0x%016lX"
#define HEX128 "0x%016lX%016lX"


typedef enum {
    FLOAT_INVALID,
    FLOAT_32,
    FLOAT_64,
    FLOAT_128,
} float_type_t;

typedef union {
    float32_t  f32;
    uint32_t   u32;
    float64_t  f64;
    uint64_t   u64;
    float128_t f128;
    uint128_t  u128;
} anyfloat_t;

typedef struct {
    float_type_t float_size;
    anyfloat_t   input;
} args_t;


typedef struct {
    float32_t (*f32)(float32_t input);
    float64_t (*f64)(float64_t input);
    float128_t (*f128)(float128_t input);
} single_input_funcs_t;


/*
 * Parse a single float argument.
 *
 * Argument: arg
 *   IN  - The input arg.
 *
 * Argument: out_args
 *   OUT - The parsed args.
 *
 * Return:
 *   Return code.
 */
int parse_float_arg(const char *arg, args_t *out_args);


/*
 * Run a function that takes a single input.
 *
 * Argument: input
 *   IN  - The input to the function.
 *
 * Argument: funcs
 *   IN  - The functions for the different float sizes.
 */
void run_single_input_func(args_t input, single_input_funcs_t funcs);


/*
 * Generic main function for a single-input math function.
 */
int single_input_func_main(int argc,
                           const char **argv,
                           single_input_funcs_t funcs);


#endif  // UTIL_H
