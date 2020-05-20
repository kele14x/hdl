#ifndef __FIR_LP_H
#define __FIR_LP_H

#include <ap_int.h>

const ap_int<16> coef[6] = {
    -118, 223, -431, 796, -1581, 5161
};

void fir_lp(ap_uint<32> din, ap_uint<32> *dout);

#endif
