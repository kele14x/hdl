# Fixed-Point Math

This document summarizes fixed-point representation, arithmetic, and digital power conventions used by the RTL.

## 1. Fixed-Point Representation

The RTL uses a fixed-point notation of the form `fi(signed, width, frac)`.

In this notation:

- the first field indicates whether the number is signed
- the second field is the total bit width, including the sign bit when signed
- the third field is the number of fractional bits

For example, `fi(1, 16, 15)` means:

- `1`: signed number
- `16`: total width is 16 bits
- `15`: fractional width is 15 bits

This corresponds to a signed 16-bit fixed-point value with 15 fractional bits. Its arithmetic range is `-1 <= x < 1`, so `-1` is representable and `+1` is not.

The bit storage for `fi(1, 16, 15)` is shown below.

![Bit storage layout for fi(1, 16, 15)](fi_1_16_15_bit_layout.svg)

For `fi(1, 16, 15)`, the stored bits can be interpreted as:

$$
x = -S \cdot 2^{0} + F_{14} \cdot 2^{-1} + F_{13} \cdot 2^{-2} + \cdots + F_{1} \cdot 2^{-14} + F_{0} \cdot 2^{-15}
$$

where `S`, `F14`, ..., `F0` are the individual stored bits and each bit is either `0` or `1`.

Complex fixed-point values use the notation `cfi(signed, width, frac)`, where the leading `c` means complex.

For example, `cfi(1, 16, 15)` means:

- the real part uses `fi(1, 16, 15)`
- the imaginary part uses `fi(1, 16, 15)`

So a `cfi(1, 16, 15)` sample contains one 16-bit signed fixed-point real value and one 16-bit signed fixed-point imaginary value.

When the complex sample is packed into one 32-bit word, the Q sample occupies the upper 16 bits and the I sample occupies the lower 16 bits. In bit-range notation, this is `Q[31:16]` and `I[15:0]`.

![32-bit storage layout for cfi(1, 16, 15)](cfi_1_16_15_word_layout.svg)

The same complex sample can also be viewed as an I/Q point in the complex plane, where the in-phase and quadrature components are each stored as `fi(1, 16, 15)` values.

![I/Q interpretation for cfi(1, 16, 15)](cfi_1_16_15_iq_plane.svg)

For a constant-envelope complex sinusoid,

$$
x(t) = \cos(2 \pi t) + j \sin(2 \pi t)
$$

the I/Q point lies on a circle of radius `1`. This corresponds to a complex waveform with magnitude `1`, which is a useful reference for `0 dBFS` complex signal power.

Points outside that circle, such as approximately `0.8 + 0.8j`, have magnitude greater than `1` and therefore instantaneous power above `0 dBFS`, even though such operation is usually avoided in a communication system.

This is the most common numeric format used throughout the RTL datapaths.

## 2. Fixed-Point Arithmetic

Arithmetic between fixed-point values follows the same signed-fractional interpretation.

For example, if `a` and `b` are both `fi(1, 16, 15)`, then:

$$
p = a \cdot b
$$

The full-precision product keeps 30 fractional bits, so it can be represented as `fi(1, 31, 30)`.

If the result must be converted back to `fi(1, 16, 15)`, the usual truncation step is to remove the trailing 15 fractional bits.

In bit terms, this is equivalent to taking the full-precision product and shifting it right by 15 bits.

$$
Y_{\mathrm{int}} = P_{\mathrm{int}} \gg 15
$$

$$
y = Y_{\mathrm{int}} \cdot 2^{-15}
$$

where `P_int` is the signed integer bit pattern of the full-precision `fi(1, 31, 30)` product, `>> 15` is an arithmetic right shift that discards the lower 15 fractional bits, and `y` is the reduced-width `fi(1, 16, 15)` result.

This truncation keeps the sign bit and the upper 15 fractional bits, while discarding the lower 15 fractional bits to reduce datapath width.

## 3. Digital Power

Digital power is calculated from the arithmetic value of the fixed-point samples.

The first step is to convert the stored binary data into its arithmetic value by using the fixed-point weight equation described in Section 1.

Once the sample values are interpreted as arithmetic values, the digital power relative to full scale is computed from the average squared magnitude:

$$
P\ [\mathrm{dBFS}] = 10 \cdot \log_{10}\left( \operatorname{average}\left( |x|^2 \right) \right)
$$

For a real-valued sample, `|x|^2 = x^2`. For a complex sample, `|x|^2 = I^2 + Q^2`.

This definition is consistent with the unit-circle interpretation above, where a constant-envelope complex waveform with magnitude `1` corresponds to `0 dBFS` average power.
