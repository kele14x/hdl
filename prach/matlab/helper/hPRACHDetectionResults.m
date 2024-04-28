function hPRACHDetectionResults(SNRdB, numSubframes, P)
%hPRACHDetectionResults Display PRACH detection results
%   hPRACHDetectionResults(SNRDB, NUMSUBFRAMES, P) plots the PRACH
%   detection probability P when testing at an SNR of SNRDB for a number of
%   subframes NUMSUBFRAMES. 

%   Copyright 2019-2020 The MathWorks, Inc.

    figure;
    plot(SNRdB,P,'b-o','LineWidth',2,'MarkerSize',7);
    title(['Detection Probability for ', num2str(numSubframes) ' Subframe(s)'] );
    xlabel('SNRdB'); ylabel('Detection Probability');
    grid on;
    hold on;
    plot(-6.0,0.99,'rx','LineWidth',2,'MarkerSize',7);
    legend('Simulation Result', 'Target 99% Probability','Location','SouthEast');
    minP = 0;
    if(~isnan(min(P)))
        minP = min(P);
    end
    axis([SNRdB(1)-0.1 SNRdB(end)+0.1 minP-0.05 1.05]) 

end