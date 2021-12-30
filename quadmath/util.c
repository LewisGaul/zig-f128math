#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <quadmath.h>

#include "util.h"


/*
 * See util.h
 */
int
parse_float_arg (const char *arg,
                 args_t     *out_args)
{
    int       rc      = 0;
    uint32_t  arg_len = strlen(arg);
    char     *endptr  = NULL;

    // Set to zero as e.g. strol uses this to communicate success/failure.
    errno = 0;

    uint32_t val = (uint32_t)strtoul(arg, NULL, 16);
    rc = errno;

    if (strncmp(arg, "0x", 2) == 0 && strchr(arg, 'p') == NULL && strchr(arg, 'P') == NULL) { // uint bits
        if (arg_len == 10) {
            uint32_t val = (uint32_t)strtoul(arg, &endptr, 16);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_32;
                out_args->input.u32 = val;
            }
        } else if (arg_len == 18) {
            uint64_t val = strtoul(arg, &endptr, 16);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_64;
                out_args->input.u64 = val;
            }
        } else if (arg_len == 34) {
            uint64_t high_bits, low_bits;
            char *argcpy = strdup(arg);
            argcpy[18] = '\0';
            high_bits = strtoul(argcpy, &endptr, 16);
            free(argcpy);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                low_bits = strtoul(&arg[18], &endptr, 16);
                rc = errno;
            }
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_128;
                out_args->input.u128 = ((uint128_t)high_bits << 64) + low_bits;
            }
        } else {
            fprintf(stderr,
                    "Unexpected input length %d - expected a 32, 64, or 128-bit hex int",
                    arg_len);
            rc = 1;
        }
    } else { // Regular float, any format
        bool is_hex = strncmp(arg, "0x", 2) || strncmp(arg, "-0x", 3);
        if (is_hex && arg_len >= 11 && arg_len <= 16) {
            float32_t val = strtof(arg, &endptr);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_32;
                out_args->input.f32 = val;
            }
        } else if (is_hex && arg_len >= 19 && arg_len <= 24) {
            float64_t val = strtod(arg, &endptr);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_64;
                out_args->input.f64 = val;
            }
        } else if (is_hex && arg_len >= 34 && arg_len <= 40) {
            float128_t val = strtoflt128(arg, &endptr);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_128;
                out_args->input.f128 = val;
            }
        } else { // Default to 64-bit
            float64_t val = strtod(arg, &endptr);
            rc = errno;
            if (rc == 0 && *endptr != '\0') {
                rc = 1;
            }
            if (rc == 0) {
                out_args->float_size = FLOAT_64;
                out_args->input.f64 = val;
            }
        }
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
    char       buf[256];

    switch (args.float_size) {
    case FLOAT_32:
        fprintf(stderr,
                "IN:  "HEX32"  %+-a  %+-f\n",
                args.input.u32, args.input.f32, args.input.f32);
        result.f32 = funcs.f32(args.input.f32);
        fprintf(stderr,
                "OUT: "HEX32"  %+-a  %+-f\n",
                result.u32, result.f32, result.f32);
        fprintf(stdout, HEX32, result.u32);
        break;
    case FLOAT_64:
        fprintf(stderr,
                "IN:  "HEX64"  %+-a  %+-f\n",
                args.input.u64, args.input.f64, args.input.f64);
        result.f64 = funcs.f64(args.input.f64);
        fprintf(stderr,
                "OUT: "HEX64"  %+-a  %+-f\n",
                result.u64, result.f64, result.f64);
        fprintf(stdout, HEX64, result.u64);
        break;
    case FLOAT_128:
        fprintf(stderr,
                "IN:  "HEX128,
                (uint64_t)(args.input.u128 >> 64),
                (uint64_t)args.input.u128);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qa", args.input.f128);
        fprintf(stderr,"  %s", buf);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qf", args.input.f128);
        fprintf(stderr,"  %s\n", buf);
        result.f128 = funcs.f128(args.input.f128);
        fprintf(stderr,
                "OUT: "HEX128,
                (uint64_t)(result.u128 >> 64),
                (uint64_t)result.u128);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qa", result.f128);
        fprintf(stderr, "  %s", buf);
        quadmath_snprintf(buf, sizeof(buf), "%+-Qf", result.f128);
        fprintf(stderr, "  %s\n", buf);
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
