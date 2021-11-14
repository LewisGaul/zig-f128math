/*
 * Script to calculate exp2(x), where x may be a 32, 64 or 128-bit float.
 *
 * The script takes one positional argument: the input in hex format.
 * E.g. './exp2 0x40400000' calculates 2^3. The result is output (to stdout)
 * in the same format, i.e. in this case '0x41000000'. The input must contain
 * either 8, 16, or 32 hex digits, from which the float size is determined.
 *
 * Compile with:
 *    gcc exp2.c util.c -lm -lquadmath -o exp2
 */

#include <math.h>
#include <quadmath.h>

#include "util.h"


int
main (int         argc,
      const char *argv[])
{
    single_input_funcs_t funcs = {exp2f, exp2, exp2q};

    return single_input_func_main(argc, argv, funcs);
}
