function waveform = prach_source(RAT, BW, Debug)

%% PRACH_SOURCE PRACH waveform generation

if nargin < 1
    RAT = 'LTE';
end

if nargin < 2
    BW = '20';
end

if nargin < 3
    Debug = false;
end

datafile = sprintf("./data/prach_%s_%s.mat", RAT, BW);

if exist(datafile, "file") && ~Debug
    % Load from file if requried waveform is already generated, so it's
    % faster
    load(datafile, "waveform");
elseif strcmpi(RAT, 'LTE')
    ue.DuplexMode = 'FDD';
    ue.NULRB = lte_nRB(BW);
    chs.Format = 0; % 0,1,2,3,4
    chs.SeqIdx = 0; % 0 to 837
    % chs.ConfigIdx = 0;  % 0 to 63
    chs.PreambleIdx = 0; % 0 to 63
    chs.CyclicShiftIdx = 0; % 0 to 15
    chs.HighSpeed = 0;
    chs.TimingOffset = 0;
    chs.FreqOffset = 0;

    [waveform, ~] = ltePRACH(ue, chs);
    save(datafile, "waveform");
elseif strcmpi(RAT, 'NR')
    waveconfig.NumSubframes = 1;
    waveconfig.Carriers = nrCarrierConfig;
    waveconfig.Carriers.NSizeGrid = nr_nRB(BW);
    waveconfig.PRACH.Config = nrPRACHConfig;

    [waveform, ~, ~] = hNRPRACHWaveformGenerator(waveconfig);
    save(datafile, "waveform");
else
    error(fprintf('Invalid RAT: %s', RAT));
end

% Resample to 30.72 Msps
Fs = length(waveform) / 30720 * 30.72e6;
waveform = resample(waveform, 30.72e6/Fs, 1);

% Scale power
waveform = waveform * 2;
waveform = round(waveform*2^15);

if Debug
    figure();
    pwelch(waveform, [], [], [], [], 'centered');
    fprintf('Peak Power: %.2f dBFS\n', 20*log10(max(abs(waveform))/2^15));
    fprintf('Average Power: %.2f dBFS\n', 20*log10(mean(abs(waveform))/2^15));

    figure();
    plot(-12288:12287, 20*log10(fftshift(abs(fft(waveform(3169:3169+24575))))));
end

end
