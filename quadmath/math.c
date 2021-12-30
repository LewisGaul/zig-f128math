/*
 * Script to calculate any math function for 32, 64 or 128-bit float input.
 *
 * The script takes two positional arguments: the function name and the input
 * in hex format.
 * E.g. './math exp 0x40400000' calculates e^3 using 32-bit floats. The result
 * is output (to stdout) in the same format. The input must contain either 8,
 * 16, or 32 hex digits, from which the float size is determined.
 *
 * Compile with:
 *    gcc math.c util.c -lm -lquadmath -o math
 */

#include <stdio.h>
#include <string.h>

#include <math.h>
#include <quadmath.h>

#include "util.h"


#define MATH_FUNCS_FROM_NAME(name) \
    (single_input_funcs_t){name ## f, name, name ## q}


static int
math_parse_func_name (const char           *name,
                      single_input_funcs_t *funcs)
{
    int rc = 0;

    if (strcmp("exp", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(exp);
    } else if (strcmp("exp2", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(exp2);
    // } else if (strcmp("exp10", name) == 0) {
    //     *funcs = MATH_FUNCS_FROM_NAME(exp10);
    } else if (strcmp("expm1", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(expm1);
    // } else if (strcmp("expo2", name) == 0) {
    //     *funcs = MATH_FUNCS_FROM_NAME(expo2);
    } else if (strcmp("log", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(log);
    } else if (strcmp("log2", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(log2);
    } else if (strcmp("log10", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(log10);
    } else if (strcmp("log1p", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(log1p);
    } else if (strcmp("sin", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(sin);
    } else if (strcmp("cos", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(cos);
    } else if (strcmp("tan", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(tan);
    } else if (strcmp("asin", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(asin);
    } else if (strcmp("acos", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(acos);
    } else if (strcmp("atan", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(atan);
    } else if (strcmp("sinh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(sinh);
    } else if (strcmp("cosh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(cosh);
    } else if (strcmp("tanh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(tanh);
    } else if (strcmp("asinh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(asinh);
    } else if (strcmp("acosh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(acosh);
    } else if (strcmp("atanh", name) == 0) {
        *funcs = MATH_FUNCS_FROM_NAME(atanh);
    } else {
        rc = 1;
    }

    return rc;
}


int
main (int         argc,
      const char *argv[])
{
    int                  rc   = 0;
    args_t               args = {};
    single_input_funcs_t funcs = {};

    if (argc != 3) {
        fprintf(stderr, "Expected usage: %s exp 0x7f80000\n", argv[0]);
        rc = 1;
    }

    if (rc == 0) {
        rc = math_parse_func_name(argv[1], &funcs);
    }

    if (rc == 0) {
        rc = parse_float_arg(argv[2], &args);
    }

    if (rc == 0) {
        run_single_input_func(args, funcs);
    }

    return rc;
}
