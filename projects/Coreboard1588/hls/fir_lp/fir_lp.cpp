#include "fir_lp.h"

//
// Data for din/dout:
//  din[31:24]: Reserved
//  din[23:16]: N_Channel, 0 ~ 31
//  din[15: 0]: Data, 16-bit
//
void fir_lp(ap_uint<32> din, ap_uint<32> *dout)
{
#pragma HLS INTERFACE axis register both port=dout
#pragma HLS INTERFACE axis register both port=din
	static ap_int<16> x_buf[32][32] = {0};
	static ap_uint<5> addr[32];

	ap_int<16> x, y;
	ap_uint<5> ch;

	ap_int<32> temp;
	ap_uint<5> addra;
	ap_uint<5> addrb;

	ap_uint<32> dout_temp;

	// Data extraction
	x = din(15, 0);
	ch = din(20, 16);

	// Data store
	x_buf[ch][addr[ch]] = x;

	// FIR MAC
	temp = 8192;

	for (int i = 0; i < 6; i++)
	{
		addra = addr[ch] - 2 * i;
		addrb = addr[ch] - 22 + 2 * i;
		temp += (x_buf[ch][addra] + x_buf[ch][addrb]) * coef[i];
	}
	addra = addr[ch] - 11;
	temp += (x_buf[ch][addra] * 8192);

	y = temp >> 14;

	// Address for next loop
	addr[ch]++;

	// Output
	dout_temp(15, 0) = y;
	dout_temp(20, 16) = ch;
	dout_temp(31, 21) = 0;

	*dout = dout_temp;

	return;
}
