% File: check_ifft_output.m
% Brief: Check iFFT output
%%
clc;
clearvars;
close all;

copyfile('../prj/project_1.sim/sim_1/behav/xsim/lowphy_ifft_output.txt', ...
    '.');

%%
ref_raw = readmatrix("lowphy_ifft_ref.txt", "OutputType", "char");
ref_raw = char(ref_raw);

ref_i = ref_raw(:, 5:8);
ref_q = ref_raw(:, 1:4);

ref_i = hex2dec(ref_i);
ref_q = hex2dec(ref_q);

ref_i(ref_i >= 2^15) = ref_i(ref_i >= 2^15) - 2^16;
ref_q(ref_q >= 2^15) = ref_q(ref_q >= 2^15) - 2^16;

ref = ref_i + 1j * ref_q;

%
out_raw = readmatrix("lowphy_ifft_output.txt", "OutputType", "char");
out_raw = char(out_raw);

out_i = out_raw(:, 5:8);
out_q = out_raw(:, 1:4);

out_i = hex2dec(out_i);
out_q = hex2dec(out_q);

out_i(out_i >= 2^15) = out_i(out_i >= 2^15) - 2^16;
out_q(out_q >= 2^15) = out_q(out_q >= 2^15) - 2^16;

out = out_i + 1j * out_q;

%
figure();
hold on;
plot(abs(ref));
plot(abs(out));
plot(abs(ref- out));
legend('Ref', 'Out');

rmse = rms(ref-out) / rms(ref);
fprintf('RMS Error: %.2f %%\n', 100*rmse);
