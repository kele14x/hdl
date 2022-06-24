
% additional delay
adr_special_delay = [-2, 0, 0, 0, 0, 0, 0] - 1;     % should always be even number
sig_special_delay = [+0, 0, 0, 0, 0, 0, 0] - 1;


chntx = null_item;
chntx.signals.values = zeros(2e4, 1);


% short per_bus
addr0 = null_item;
din0 = null_item;
we0 = null_item;

[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);

% only for TX0
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('002'), 0, 1);

[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('100'), round(Scale(1)*2^10), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('101'), round(Scale(2)*2^10), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('102'), Plim(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('103'), Plim(2), 1);

% band-A
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 0*1, 1);

for k = 1:length(dnp_a)        % delay taps
    [addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('110') + k-1, (2*dnp_a(k) + 32 + adr_special_delay(k)) * 256 + (2*dnq_a(k) + 32 + sig_special_delay(k)), 1);
    [addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('120') + k-1, (2*dnp_b(k) + 32 + adr_special_delay(k)) * 256 + (2*dnq_b(k) + 32 + sig_special_delay(k)), 1);
end

[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('130'), sr_lim_a, 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('131'), sr_lim_b, 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('132'), pk_lim_a, 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('133'), pk_lim_a, 1);

[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('136'), round(tx_gain_a * 2^14), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('137'), round(tx_gain_b * 2^14), 1);


% full per_bus
addr1 = null_item;
din1 = null_item;
we1 = null_item;

[addr1, din1, we1] = push_command(addr1, din1, we1, 0, 0, 0);
[addr1, din1, we1] = push_command(addr1, din1, we1, 0, 0, 0);

lut_base = hex2dec('1000')    + (0:6)*2048;
lut_base_sp = hex2dec('5000') + (0:2)*2048;

% band-A

%% -------------------------------------------------------------------
% 0A
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 0*16 + 0, 1);
[addr1, din1, we1] = push_zeros(addr1, din1, we1, length(addr0.signals.values) - length(addr1.signals.values) + 8);

% band - 0
band = 0;
for k = 1:7
    lutiq = squeeze(LUT2D_tx0(band+1, k, :, :));
    ramd = to_lut_ram(lutiq);
    
    [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base(k));
end
for k = 1:3
    lutiq = squeeze(LUT2Ds_tx0(band+1, k, :, :));
    ramd = to_lut_ram(lutiq);
    
    [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base_sp(k));
end


% band -1
[addr0, din0, we0] = push_zeros(addr0, din0, we0, length(addr1.signals.values) - length(addr0.signals.values) + 8);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 1*16 + 0, 1);
[addr1, din1, we1] = push_zeros(addr1, din1, we1, length(addr0.signals.values) - length(addr1.signals.values) + 8);

band = 1;
for k = 1:7
    lutiq = squeeze(LUT2D_tx0(band+1, k, :, :));
    ramd = to_lut_ram(lutiq);
    
    [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base(k));
end
for k = 1:3
    lutiq = squeeze(LUT2Ds_tx0(band+1, k, :, :));
    ramd = to_lut_ram(lutiq);
    
    [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base_sp(k));
end


% % change to TX1
% [addr0, din0, we0] = push_zeros(addr0, din0, we0, length(addr1.signals.values) - length(addr0.signals.values) + 8);
% [addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('002'), 1, 1);
% [addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 0*16 + 0, 1);
% 
% chntx.signals.values(length(addr1.signals.values) : end) = 1;
% 
% [addr1, din1, we1] = push_zeros(addr1, din1, we1, length(addr0.signals.values) - length(addr1.signals.values) + 8);
% 
% % band - 0
% band = 0;
% for k = 1:7
%     lutiq = squeeze(LUT2D_tx1(band+1, k, :, :));
%     ramd = to_lut_ram(lutiq);
%     
%     [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base(k));
% end
% for k = 1:3
%     lutiq = squeeze(LUT2Ds_tx0(band+1, k, :, :));
%     ramd = to_lut_ram(lutiq);
%     
%     [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base_sp(k));
% end
% 
% % band -1
% [addr0, din0, we0] = push_zeros(addr0, din0, we0, length(addr1.signals.values) - length(addr0.signals.values) + 8);
% [addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 1*16 + 0, 1);
% [addr1, din1, we1] = push_zeros(addr1, din1, we1, length(addr0.signals.values) - length(addr1.signals.values) + 8);
% 
% band = 1;
% for k = 1:7
%     lutiq = squeeze(LUT2D_tx1(band+1, k, :, :));
%     ramd = to_lut_ram(lutiq);
%     
%     [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base(k));
% end
% for k = 1:3
%     lutiq = squeeze(LUT2Ds_tx0(band+1, k, :, :));
%     ramd = to_lut_ram(lutiq);
%     
%     [addr1, din1, we1] = write_one_lut(addr1, din1, we1, ramd, lut_base_sp(k));
% end


% final change
[addr0, din0, we0] = push_zeros(addr0, din0, we0, length(addr1.signals.values) - length(addr0.signals.values) + 8);
[addr0, din0, we0] = push_command(addr0, din0, we0, hex2dec('140'), 0*16 + 15, 1);


%% output switch

para_pklim = [28000, 28000];
para_srlim = [18000, 18000];
para_txgain = [16384, 16384];

% TX0
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_txgain(1), para_txgain(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_pk_lim(1), para_pklim(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_sr_lim(1), para_srlim(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_txgain(2), para_txgain(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_pk_lim(2), para_pklim(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_sr_lim(2), para_srlim(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);

[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);
inum = length(addr0.signals.values);
chntx.signals.values(inum+1 : end) = 1;
[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);


% TX1
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_txgain(1), para_txgain(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_pk_lim(1), para_pklim(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_sr_lim(1), para_srlim(1), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_txgain(2), para_txgain(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_pk_lim(2), para_pklim(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_sr_lim(2), para_srlim(2), 1);
[addr0, din0, we0] = push_command(addr0, din0, we0, 0, 0, 0);

% clear TX0
[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);
inum = length(addr0.signals.values);
chntx.signals.values(inum+1 : end) = 0;
[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);

[addr0, din0, we0] = push_command(addr0, din0, we0, reg_staclr, 1*1 + 1*2,1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_staclr, 0*1 + 1*2,1);

% clear TX1
[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);
inum = length(addr0.signals.values);
chntx.signals.values(inum+1 : end) = 1;
[addr0, din0, we0] = push_zeros(addr0, din0, we0, 8);

[addr0, din0, we0] = push_command(addr0, din0, we0, reg_staclr, 1*1 + 1*2,1);
[addr0, din0, we0] = push_command(addr0, din0, we0, reg_staclr, 0*1 + 1*2,1);


% chntx = null_item;
% chntx.signals.values = zeros(2e4, 1);

