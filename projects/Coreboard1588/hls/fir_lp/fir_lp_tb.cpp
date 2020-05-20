#include "fir_lp.h"
#include <iostream>

int main()
{

	ap_int<16> x;
	ap_int<16> y;
	ap_uint<5> ch_in;
	ap_uint<5> ch_out;

	ap_uint<32> input;
	ap_uint<32> output;


	for (int i = 0; i < 32; i++)
	{
		std::cout << i << ":";
		for (int j = 0; j < 32; j++) {

			// Build input
			x = (i == 0) ? 32767 : 0;
			ch_in = j;

			input(15, 0) = x;
			input(20, 16) = j;
			input(31, 21) = 0;

			// UUT
			fir_lp(input, &output);

			// Output
			y = output(15, 0);
			ch_out = output(20, 16);

			std::cout << ch_out << ":" << y << ", ";
		}
		std::cout << "\n";

	}
	return 0;
}
