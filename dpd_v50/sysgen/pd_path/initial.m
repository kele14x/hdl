
THIS_DATE = hex2dec('20180227');

addpath('./simulation');

% input resample
input_samp_bcoef = [
1978
0
-13995
0
77558
131072
77558
0
-13995
0
1978
];

input_samp_dcoffset = 2^16;

% output resample
output_samp_bcoef = [
-1077
0
5629
0
-19239
0
80178
131072
80178
0
-19239
0
5629
0
-1077
];

output_samp_dcoffset = 2^16;

% sqrt address mapping
[a1, b1, a2, b2] = addr_map_coef;
sqrt_map_coefa = round([a1, a2] / 2^16);
sqrt_map_coefb = round([b1, b2]);

% LO modulation
LO_mod_coef = lo_mod_coef();

%% per_bus address definition
% LUT address
lut_address = [
    hex2dec('01000')...
    hex2dec('01800')...
    hex2dec('02000')...
    hex2dec('02800')...
    hex2dec('03000')...
    hex2dec('03800')...
    hex2dec('04000')
    ] / 2048;

lut_address_s5 = [
    hex2dec('05000')...
    hex2dec('05800')...
    hex2dec('06000')
    ] / 2048;

reg_sr_lim = [hex2dec('130'), hex2dec('131')];
reg_pk_lim = [hex2dec('132'), hex2dec('133')];
reg_txgain = [hex2dec('136'), hex2dec('137')];

reg_staclr = [hex2dec('138')];

reg_scale = [hex2dec('100'), hex2dec('101')];
reg_plim = [hex2dec('102'), hex2dec('103')];
reg_dltap = [hex2dec('110'), hex2dec('120')];

% simulation input
axi = null_item;
axq = null_item;
bxi = null_item;
bxq = null_item;

chnseq = null_item;
iqval = null_item;

addr0 = null_item;
din0 = null_item;
we0 = null_item;

addr1 = null_item;
din1 = null_item;
we1 = null_item;

chntx = null_item;
