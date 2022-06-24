
Plim = [15000, 13000];                                          % PLIM_A, PLIM_B
Scale = [1, 1];     % [A,B]

dnp_a = [0, -1, +1, -2, +2, -2, +2];        % address delay
dnq_a = [0, -1, +1, -2, +2,  0,  0];        % signal delay

dnp_b = [0, -1, +1, -2, +2, -2, +2] * 3;
dnq_b = [0, -1, +1, -2, +2,  0,  0] * 3;

sr_lim_a = 13000;
sr_lim_b = 12000;

pk_lim_a = 18000;
pk_lim_b = 21000;

tx_gain_a = 1.1;
tx_gain_b = 1.1;

lut_actsel = [0, 1, 1, 0];
lut_bandsel =[0, 1];

% PD coef
load PDcompare.mat;

LUT2D_tx0 = LUT2D / 2 / 2^12;
LUT2D_tx1 = LUT2D / 3.5 / 2^12;

LUT2Ds_tx0 = LUT2D / 17.8 / 2^12;
LUT2Ds_tx1 = LUT2D / 27.8 / 2^12;


% fill test coefficient

% LUT2D_tx0(2,:,:,:) = LUT2D_tx0(2,:,:,:) * 0;
% LUT2Ds_tx0(2,:,:,:) = LUT2Ds_tx0(2,:,:,:) * 0;
% 
% LUT2D_tx1(2,:,:,:) = LUT2D_tx1(2,:,:,:) * 0;
% LUT2Ds_tx1(2,:,:,:) = LUT2Ds_tx1(2,:,:,:) * 0;
    
for k = 1:7
    if k ~= 1 && k~=2 && k~=3 && k~=4 && k~=5 && k~=6 && k~=7
        LUT2D_tx0(1,k,:,:) = LUT2D_tx0(1,k,:,:) * 0;
        LUT2Ds_tx0(1,k,:,:) = LUT2Ds_tx0(1,k,:,:) * 0;

        LUT2D_tx1(1,k,:,:) = LUT2D_tx1(1,k,:,:) * 0;
        LUT2Ds_tx1(1,k,:,:) = LUT2Ds_tx1(1,k,:,:) * 0;
    end
end

% LUT2D_tx0(1, 1, 3, 3) = 0.1 + 0.15i;
% LUT2D_tx0(1, 1, 3, 4) = 0.2 + 0.25i;
% LUT2D_tx0(1, 1, 4, 3) = 0.3 + 0.35i;
% LUT2D_tx0(1, 1, 4, 4) = 0.4 + 0.45i;


LUT2D_tx0 = round(LUT2D_tx0 * 2^12) / 2^12;
LUT2D_tx1 = round(LUT2D_tx1 * 2^12) / 2^12;
