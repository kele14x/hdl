%%
% File: phase_comp.m
% Brief: This script calculates the Phase Compression value for RU
clc;
clear;
close all;

%%
F0 = 3401.01e6; % Carrier Frequency in Hz

nFFT = 4096;
cplen = [352, 288*ones(1, 13)];
SymbolPhase = -2*pi*(cumsum(cplen+nFFT)-4096)*F0/122.88e6;
PhaseComp = exp(1j*SymbolPhase);
PhaseComp = round(PhaseComp*2^15);

fprintf('# %.2fM DL\n', F0/1e6);
for i = 0:13
    addr = hex2dec('70100') + i * 4;
    fprintf('ru fpga 0x%s 0x%s%s\n', dec2hex(addr, 8), ...
        dec2hex(min(imag(PhaseComp(i+1)), 2^15-1), 4), ...
        dec2hex(min(real(PhaseComp(i+1)), 2^15-1), 4) ...
    );
end

fprintf('\n');
fprintf('# %.2fM UL\n', F0/1e6);
for i = 0:13
    addr = hex2dec('70140') + i * 4;
    fprintf('ru fpga 0x%s 0x%s%s\n', dec2hex(addr, 8), ...
        dec2hex(min(-imag(PhaseComp(i+1)), 2^15-1), 4), ...
        dec2hex(min(real(PhaseComp(i+1)), 2^15-1), 4) ...
    );
end
