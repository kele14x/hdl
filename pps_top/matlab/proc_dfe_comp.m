%%
clc;
clearvars;
close all;

%% Config & Reference
SCS = 30e3;
nFFT = 1024;
Fs = SCS * nFFT;

nSlot = 20;
nSymbol = nSlot * 14;
nSample = nSymbol * nFFT * (15 / 14);

M = 4;

nPRB = 51;
nRE = nPRB * 12;

cpLen = [88, 72 * ones(1, 13)] * nFFT / 1024;
cpLen = repmat(cpLen, [1, nSlot]);

tv = (0:nSample - 1).';

inBit = randi([0, M - 1], [nRE, nSymbol]);
inSym = qammod(inBit, 4) * modnorm(qammod(0:M-1, M), 'avpow', 1);
nullIdx = [1:(nFFT - nRE) / 2, nFFT / 2 + nRE / 2 + 1:nFFT].';

wvRef = ofdmmod(inSym, nFFT, cpLen, nullIdx);

%%
% freq = 1 + -100e-6;      % 100 ppm
freq = 1 + 100e-6; % 100 ppm
% freq = 1;

% Number of sample points
nPts = ceil(nSample/freq);

samplePhase = (0:nPts - 1) * freq;
for i = [1, 2, 3, nPts]
    fprintf('Phase[%d] = %.6f\n', i, samplePhase(i))
end

sofPhase = cumsum(circshift(cpLen, 1)+nFFT) - nFFT - cpLen(2);
sofIdx = zeros(1, nSymbol);

k = 1;
i = 1;
while i <= nPts && k <= nSymbol
    if samplePhase(i) >= sofPhase(k)
        sofIdx(k) = i;
        k = k + 1;
    end
    i = i + 1;
end
sofFrac = samplePhase(sofIdx) - sofPhase;

wv = zeros(nPts, 1);
for i = 1:nSymbol
    outWv = dl_ifft(inSym(:, i), nFFT, cpLen(i), sofFrac(i));
    wv(sofIdx(i):sofIdx(i)+length(outWv)-1) = outWv;
end

plot(fft(wv(89:89+1023)), 'x')

%%
figure();
plot(real(wvRef));
hold on;
plot(real(wv));

legend('Ref', 'Out');

%%
figure();
pwelch(wvRef, [], [], [], Fs, 'center');
hold on;
pwelch(wv, [], [], [], Fs, 'center');
