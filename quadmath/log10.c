/*
 * Script to calculate log10(x), where x may be a 32, 64 or 128-bit float.
 *
 * The script takes one positional argument: the input in hex format.
 * E.g. './log10 0x40400000' calculates log10(3). The result is output (to stdout)
 * in the same format. The input must contain either 8, 16, or 32 hex digits,
 * from which the float size is determined.
 *
 * Compile with:
 *    gcc log10.c util.c -lm -lquadmath -o log10
 */

#include <math.h>
#include <quadmath.h>

#include "util.h"


int
main (int         argc,
      const char *argv[])
{
    single_input_funcs_t funcs = {log10f, log10, log10q};

    return single_input_func_main(argc, argv, funcs);
}
