initial;

load data.mat;
siq = round(siq * 0.1);
siq = [siq, siq];

num = length(siq);
siq = siq + [linspace(1, 10000, num/2 + 2000), linspace(10000,1,num/2 - 2000)];

siq_a = siq * 0.2;
siq_b = siq * 0.5;

siq_r = siq * 1.5;
siq_r = [siq_r, siq_r];


xi = real(siq);
xq = imag(siq);


short_per_addr = null_item;
short_per_din = null_item;
short_per_we = null_item;


[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('151'), 16384-1, 1);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('152'), 131072, 1);

[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);

[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('150'), 0*1 + 0*16 + 1*2 + 0*4, 1);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('150'), 0*1 + 0*16 + 0*2 + 0*4, 1);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('150'), 0*1 + 0*16 + 0*2 + 1*4, 1);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, 0, 0, 0);
[short_per_addr, short_per_din, short_per_we] = push_command(short_per_addr, short_per_din, short_per_we, hex2dec('150'), 0*1 + 0*16 + 0*2 + 0*4, 1);

full_per_addr = null_item;
full_per_din = null_item;
full_per_we = null_item;
full_per_rden = null_item;

offsnum = 132000;

full_per_addr.signals.values = zeros(offsnum,1);
full_per_rden.signals.values = zeros(offsnum,1);

full_per_din.signals.values = zeros(5,1);
full_per_we.signals.values = zeros(5,1);

full_per_addr.signals.values = [full_per_addr.signals.values ; (hex2dec('10000') + (0:32768-1))'; (hex2dec('18000') + (0:32768-1))'; (hex2dec('20000') + (0:65536-1))']; 
full_per_rden.signals.values = [full_per_rden.signals.values; ones(32768 + 32768 + 65536, 1) ];

Ai = null_item;
Aq = null_item;
Bi = null_item;
Bq = null_item;

tori0 = null_item;
torq0 = null_item;
tori1 = null_item;
torq1 = null_item;

Ai.signals.values = real(siq_a)';
Aq.signals.values = imag(siq_a)';

Bi.signals.values = real(siq_b)';
Bq.signals.values = imag(siq_b)';

tori0.signals.values = real(siq_r(1:2:end))';
torq0.signals.values = imag(siq_r(1:2:end))';

tori1.signals.values = real(siq_r(2:2:end))';
torq1.signals.values = imag(siq_r(2:2:end))';
