%%
clc;
clearvars;
close all;

nFFT = 2048;
nPRB = 25;
nSym = 2;

%%
fin = '../../prj/project_1.sim/sim_1/behav/xsim/tb_pdxch_fdv_buffer_input.txt';
x = readmatrix(fin);
x = x(:, 1) + 1j * x(:, 2);
x = x(1:nPRB*12*nSym);
x = reshape(x, nPRB*12, []);

%
r = zeros(nFFT, nSym);
r(2:nPRB*6+1, :) = x(nPRB*6+1:end, :);
r(end-nPRB*6+1:end, :) = x(1:nPRB*6, :);
r = bitrevorder(r);

%%
fout = '../../prj/project_1.sim/sim_1/behav/xsim/tb_pdxch_fdv_buffer_output.txt';
y = readmatrix(fout);
y = y(:, 1) + 1j * y(:, 2);
y = y(1:nFFT*nSym);
y = reshape(y, nFFT, []);

%%
assert(all(y(:) == r(:)));