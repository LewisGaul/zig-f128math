#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"


static int
parse_one_arg (const char *arg,
               args_t     *out_args)
{
    int      rc      = 0;
    uint32_t arg_len = strlen(arg);

    // Set to zero as e.g. strol uses this to communicate success/failure.
    errno = 0;

    if (strncmp(arg, "0x", 2) != 0) {
        fprintf(stderr, "Expected input to start with '0x'\n");
        rc = 1;
    } else if (arg_len == 10) {
        uint32_t val = (uint32_t)strtoul(arg, NULL, 16);
        rc = errno;
        if (rc == 0) {
            out_args->float_size = FLOAT_32;
            out_args->input.u32 = val;
        }
    } else if (arg_len == 18) {
        uint64_t val = strtoul(arg, NULL, 16);
        rc = errno;
        if (rc == 0) {
            out_args->float_size = FLOAT_64;
            out_args->input.u64 = val;
        }
    } else if (arg_len == 34) {
        uint64_t high_bits, low_bits;
        char *argcpy = strdup(arg);
        argcpy[18] = '\0';
        high_bits = strtoul(argcpy, NULL, 16);
        free(argcpy);
        rc = errno;
        if (rc == 0) {
            low_bits = strtoul(&arg[18], NULL, 16);
        }
        uint128_t val = ((uint128_t)high_bits << 64) + low_bits;
        rc = errno;
        if (rc == 0) {
            out_args->float_size = FLOAT_128;
            out_args->input.u128 = val;
        }
    } else {
        fprintf(stderr,
                "Unexpected input length %d - expected a 32, 64, or 128-bit hex int",
                // "Unexpected input length %d - expected a 32 or 64-bit hex int\n",
                arg_len);
        rc = 1;
    }

    return rc;
}


/*
 * See util.h
 */
int
parse_args (int          argc,
            const char **argv,
            args_t      *out_args)
{
    int rc = 0;

    assert(out_args != NULL);

    if (argc == 1) {
        fprintf(stderr, "Expected an input argument\n");
        rc = 1;
    } else if (argc > 2) {
        fprintf(stderr, "Expected exactly one input argument, got %d\n", argc - 1);
        rc = 1;
    } else {
        rc = parse_one_arg(argv[1], out_args);
    }

    return rc;
}


/*
 * See util.h
 */
void
run_single_input_func (args_t               args,
                       single_input_funcs_t funcs)
{
    anyfloat_t result;

    switch (args.float_size) {
    case FLOAT_32:
        result.f32 = funcs.f32(args.input.f32);
        fprintf(stdout, HEX32, result.u32);
        break;
    case FLOAT_64:
        result.f64 = funcs.f64(args.input.f64);
        fprintf(stdout, HEX64, result.u64);
        break;
    case FLOAT_128:
        result.f128 = funcs.f128(args.input.f128);
        fprintf(stdout,
                HEX128,
                (uint64_t)(result.u128 >> 64),
                (uint64_t)result.u128);
        break;
    default:
        assert(false);
        break;
    }
}


/*
 * See util.h
 */
int
single_input_func_main (int                    argc,
                        const char           **argv,
                        single_input_funcs_t   funcs)
{
    int    rc   = 0;
    args_t args = {};

    rc = parse_args(argc, argv, &args);

    if (rc == 0) {
        run_single_input_func(args, funcs);
    }

    return rc;
}
