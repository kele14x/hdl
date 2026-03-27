%%
clc;
clearvars;
close all;

Mu = 0;
RAT = "LTE";
nFFT = 2048;
nPRB = 100;
nSym = 14;

rng(12345);
%%
x = randi([0, 1], nPRB*12*nSym, 1) * 2 * 4120 - 4120 + ...
    1j * (randi([0, 1], nPRB*12*nSym, 1) * 2 * 4120 - 4120);
writematrix([dec2hex(imag(x)), dec2hex(real(x))], "tb_pdxch_top_input.txt");

%%
fout = '../../prj/project_1.sim/sim_1/behav/xsim/tb_pdxch_top_output.txt';
y = readmatrix(fout);
y = y(:, 1) + 1j * y(:, 2);
y = y(1:30720);

figure();
plot(abs(y));

figure();
pwelch(y, [], [], [], 30.72e6, "centered", "power");

fprintf("Power: %.2f dBFS\n", 20*log10(rms(y)/2^15));
%%
x = reshape(x, nPRB*12, []);
cplen = repmat([160, 144 * ones(1, 6)], 1, 2);
r = ofdmmod(x, nFFT, cplen, [1:424, 1025, 1626:2048]');
r = r * nFFT / 2^5;

e = y - r;

figure();
plot(abs(r));
hold on;
plot(abs(y));
plot(abs(e));
legend("Ref", "Out", "Err");
