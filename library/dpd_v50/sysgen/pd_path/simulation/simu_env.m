
num = 10000;


%% fractional bit definition
BIT_lut_coef = 12;
BIT_addr_scale = 10;
BIT_out_gain = 14;


%% -- parameters
initial;

%% -- signal IQ source
axi = null_item;
axq = null_item;
bxi = null_item;
bxq = null_item;

% signal source
load PDcompare.mat
PDin = round(PDin);

x0a = PDin(1, 1:num);
x0b = PDin(2, 1:num);

x1a = PDin(1, 10000 + (1:num)) * 0;
x1b = PDin(2, 10000 + (1:num)) * 0;

axi.signals.values = zeros(2*num, 1);
axq.signals.values = zeros(2*num, 1);
bxi.signals.values = zeros(2*num, 1);
bxq.signals.values = zeros(2*num, 1);

axi.signals.values(1:4:end) = real(x0a(1:2:end))';
axq.signals.values(1:4:end) = imag(x0a(1:2:end))';
axi.signals.values(2:4:end) = real(x1a(1:2:end))';
axq.signals.values(2:4:end) = imag(x1a(1:2:end))';

bxi.signals.values(1:4:end) = real(x0b(1:2:end))';
bxq.signals.values(1:4:end) = imag(x0b(1:2:end))';
bxi.signals.values(2:4:end) = real(x1b(1:2:end))';
bxq.signals.values(2:4:end) = imag(x1b(1:2:end))';

chnseq = null_item;
chnseq.signals.values = [0 1 0 1]';

iqval = null_item;
iqval.signals.values = [1 1 0 0]';

%% geneerated test source
simu_gen;

%% per_bus control
push_config;

%% C head
gen_chead;
