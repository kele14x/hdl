function hPRACHInfoDisplay(carrier,prach,windowing)
%hPRACHInfoDisplay Display PRACH OFDM modulation related information
%   hPRACHInfoDisplay(CARRIER,PRACH,WINDOWING) displays dimensional
%   information related to physical random access channel (PRACH) OFDM
%   modulation, given uplink carrier configuration object CARRIER, PRACH
%   configuration object PRACH, and the WINDOWING parameter.
%
%   CARRIER is a carrier-specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%
%   SubcarrierSpacing   - Subcarrier spacing in kHz (15, 30, 60, 120, 240)
%   CyclicPrefix        - Cyclic prefix ('normal', 'extended')
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
%
%   WINDOWING is a nonnegative scalar that defines the number of
%   time-domain samples over which windowing and overlapping of OFDM
%   symbols is applied. Set WINDOWING to [] to use the default value.
%
%   The information displayed is grouped into two categories:
% 
%   Information associated with PRACH:
%   SubcarrierSpacing         - PRACH subcarrier spacing in kHz
%   Number of subcarriers     - Number of subcarriers
% 
%   Information associated with PRACH OFDM modulation:
%   Nfft                      - The number of FFT points used in the OFDM 
%                               modulator
%   Windowing                 - The number of time-domain samples over
%                               which windowing and overlapping of OFDM
%                               symbols is applied
%   Offset                    - Length (in samples) of the initial time
%                               offset from the start of the configured
%                               PRACH slot period to the start of the
%                               cyclic prefix
%   TCP                       - Cyclic prefix (CP) length (in samples) of
%                               each OFDM symbol
%   TSEQ                      - Active sequence period (in samples) of each
%                               OFDM symbol
%   GP                        - Guard period (GP) length (in samples) of
%                               each OFDM symbol
%   Total samples             - Total number of samples within one PRACH
%                               slot
%   Sample rate               - The sample rate of the OFDM modulator
%   Duration                  - Duration (in ms) of one PRACH slot
%   Total number of subframes - Total number of subframes spanned by one
%                               PRACH slot
% 
%   The information related to the number of samples corresponding to CP,
%   PRACH active sequence period TSEQ, and GP for each OFDM symbol are
%   listed in a tabular format. The table lists all the OFDM symbols that
%   can fit in the resource grid. For short preamble formats, the values
%   marked with an asterisk correspond to all possible PRACH occasions
%   except the current one (which is the PRACH occasion defined by
%   PRACH.TimeIndex). For short preamble formats, the values within angle
%   brackets represent OFDM symbols not used by any PRACH occasion for the
%   current configuration (corresponding to an empty space in time in the
%   resource grid plot).
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
%   % Use the default windowing
%   windowing = [];
%
%   % Display PRACH OFDM information
%   hPRACHInfoDisplay(carrier,prach,windowing)
%
%   See also nrPRACHOFDMInfo, hPRACHPreamblePlot, hPRACHResourceGridPlot,
%   nrPRACHGrid, nrPRACH, nrPRACHIndices.

% Copyright 2019-2020 The MathWorks, Inc.

    % Get the grid to know the number of symbols
    grid = nrPRACHGrid(carrier,prach);
    NSubcarriers = size(grid,1);
    
    % Loop over all the possible PRACH time occasions
    prach0 = prach; % Save the input configuration
    TCP = zeros(size(grid,2),1);
    GP = zeros(size(grid,2),1);
    activeSymbols = zeros(size(grid,2),1);
    for timeOccasion = 0:prach.NumTimeOccasions - 1
        
        prach.TimeIndex = timeOccasion;
        
        % Get OFDM modulation info for this PRACH configuration
        ofdmInfo = nrPRACHOFDMInfo(carrier,prach,'Windowing',windowing);
        
        % Get index of this PRACH occasion
        thisOccasionIndex = timeOccasion*prach.PRACHDuration+1:(timeOccasion+1)*prach.PRACHDuration;
        
        % Get values of cyclic prefix (CP) and guard period (GP)
        TCP(thisOccasionIndex) = ofdmInfo.CyclicPrefixLengths(thisOccasionIndex).';
        GP(thisOccasionIndex) = ofdmInfo.GuardLengths(thisOccasionIndex).';
        
        % Check the active symbols
        %   0: Symbol does not exist
        %   1: Symbol is not active
        %   2: Symbol is active
        prachIndices = nrPRACHIndices(carrier,prach);
        grid(prachIndices) = 1 + (timeOccasion==prach0.TimeIndex);
        activeSymbolsTmp = max(abs(grid),[],1);
        activeSymbols(thisOccasionIndex) = activeSymbolsTmp(thisOccasionIndex);
    end
    
    % Get values of preamble sequence
    TSEQ = repmat(ofdmInfo.Nfft,size(TCP));
    
    % Generate the table containing all OFDM information for each OFDM
    % symbol
    ofdmSymbol = (1:numel(TCP)).'; % OFDM symbol
    totalSamples = sum(ofdmInfo.CyclicPrefixLengths + ofdmInfo.GuardLengths + ofdmInfo.Nfft) + ofdmInfo.OffsetLength;
    
    % Display dimensional information
    fprintf('Information associated with PRACH:\n')
    fprintf('   SubcarrierSpacing:         %g kHz\n', prach.SubcarrierSpacing)
    fprintf('   Number of subcarriers:     %g\n\n', NSubcarriers)
    fprintf('Information associated with PRACH OFDM modulation:\n')
    fprintf('   Nfft:                      %g\n', ofdmInfo.Nfft)
    fprintf('   Windowing:                 %g\n', ofdmInfo.Windowing)
    fprintf('   Offset:                    %g samples\n\n', ofdmInfo.OffsetLength)
    fprintf('   Symbol    TCP     TSEQ       GP\n')
    fprintf('   ------  ------   ------    -----\n')

    for symbol = 1:numel(ofdmSymbol)
        if activeSymbols(symbol)==2
            % This OFDM symbol corresponds to an active PRACH occasion
            fprintf('   %4g   %6g   %6g   %6g\n', symbol-1,TCP(symbol),TSEQ(symbol),GP(symbol))
        elseif activeSymbols(symbol)==1
            % This OFDM symbol corresponds to an inactive PRACH occasion
            fprintf('    %3g*   %5g*   %5g*   %5g*\n', symbol-1,TCP(symbol),TSEQ(symbol),GP(symbol))
        else
            % This OFDM symbol does not exist for the current PRACH
            % configuration
            fprintf('    <%2g>   <%4g>   <%4g>   <%4g>\n', symbol-1,TCP(symbol),TSEQ(symbol),GP(symbol))
        end
    end
    if any(activeSymbols(ofdmSymbol)==1)
        fprintf('\n       *  : OFDM symbols for unused PRACH time occasions\n')
    end
    if any(activeSymbols(ofdmSymbol)==0)
        fprintf('      <#> : OFDM symbols not used by any PRACH time occasion\n')
        fprintf('            for the current configuration\n')
    end
    fprintf('\n   Total samples:             %g\n', totalSamples)
    fprintf('   Sample rate:               %0.3f MHz\n', ofdmInfo.SampleRate/1e6)
    fprintf('   Duration:                  %0.3f ms\n', totalSamples/ofdmInfo.SampleRate*1000)
    fprintf('   Total number of subframes: %g\n', prach.SubframesPerPRACHSlot)
end
