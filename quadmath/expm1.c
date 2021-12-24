/*
 * Script to calculate exp(x) - 1, where x may be a 32, 64 or 128-bit float.
 *
 * The script takes one positional argument: the input in hex format.
 * E.g. './expm1 0x40400000' calculates exp(3) - 1. The result is output (to stdout)
 * in the same format. The input must contain either 8, 16, or 32 hex digits,
 * from which the float size is determined.
 *
 * Compile with:
 *    gcc expm1.c util.c -lm -lquadmath -o expm1
 */

#include <math.h>
#include <quadmath.h>

#include "util.h"


int
main (int         argc,
      const char *argv[])
{
    single_input_funcs_t funcs = {expm1f, expm1, expm1q};

    return single_input_func_main(argc, argv, funcs);
}
