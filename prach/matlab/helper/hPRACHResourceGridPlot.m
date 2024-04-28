function hPRACHResourceGridPlot(carrier,prach)
%hPRACHPreamblePlot Plots the PRACH resource grid to show the location of the active PRACH
%
%   hPRACHResourceGridPlot(CARRIER,PRACH) plots the PRACH resource grid to
%   show the location of the active PRACH. Note that this function
%   generates a grid that contains all the time occasions in which the
%   PRACH can be transmitted. The plot shows the inactive PRACH occasions
%   in a lighter color and the active PRACH occasion in a darker color.
%
%   CARRIER is a carrier-specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%
%   SubcarrierSpacing   - Subcarrier spacing in kHz (15, 30, 60, 120, 240)
%   NSizeGrid           - Number of resource blocks in carrier resource
%                         grid (1...275)
%
%   PRACH is a PRACH-specific configuration object, as described in
%   <a href="matlab:help('nrPRACHConfig')">nrPRACHConfig</a> with these properties:
%
%   FrequencyRange      - Frequency range (used in combination with
%                         DuplexMode to select a configuration table from
%                         TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4)
%   DuplexMode          - Duplex mode (used in combination with
%                         FrequencyRange to select a configuration table
%                         from TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4)
%   ConfigurationIndex  - Configuration index, as defined in TS 38.211
%                         Tables 6.3.3.2-2 to 6.3.3.2-4
%   SubcarrierSpacing   - PRACH subcarrier spacing in kHz
%   TimeIndex           - Index of the PRACH transmission occasions in
%                         time domain
%   NPRACHSlot          - PRACH slot number
%
%   Example:
%
%   % Configure carrier
%   carrier = nrCarrierConfig;
%
%   % Configure PRACH for format A1
%   prach = nrPRACHConfig;
%   prach.ConfigurationIndex = 106;
%   prach.SubcarrierSpacing = 15;
%
%   % Plot the resource grid for the selected PRACH configuration
%   hPRACHResourceGridPlot(carrier,prach);
%
%   See also hPRACHPreamblePlot, hPRACHInfoDisplay, nrPRACHGrid,
%   nrPRACHIndices.

% Copyright 2019 The MathWorks, Inc.

    grid = nrPRACHGrid(carrier,prach);
    configuredOccasion = prach.TimeIndex;
    for occ = 0:(prach.NumTimeOccasions-1)
        prach.TimeIndex = occ;
        prachIndices = nrPRACHIndices(carrier,prach);
        grid(prachIndices) = 1 + (occ==configuredOccasion);
    end
    prach.TimeIndex = configuredOccasion;
    
    % Set up the figure data
    figure('Name','PRACH Resource Grid');
    image(abs(grid) + 1);
    colormap([1,1,1; 0.71,0.8567,0.9533; 0.13,0.57,0.86]);
    axis('xy');
    xlabel('OFDM symbol');
    ylabel('Subcarrier');
    title(sprintf('PRACH Resource Grid (Size [%s])',strjoin(string(size(grid)),' ')));
    axis('tight');
end
