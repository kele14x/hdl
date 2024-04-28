function hPRACHPreamblePlot(carrier,prach)
%hPRACHPreamblePlot Plot the time-domain structure of the current PRACH preamble
%
%   hPRACHPreamblePlot(CARRIER,PRACH) plots the time-domain illustration of
%   the current PRACH preamble, containing the cyclic prefix (CP), the
%   actual PRACH preamble divided into blocks of length T_SEQ, and a final
%   guard period (GP). If the PRACH subcarrier spacing is either 30 kHz or
%   120 kHz, this function plots two PRACH preambles.
%
%   CARRIER is a carrier-specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%
%   SubcarrierSpacing   - Subcarrier spacing in kHz (15, 30, 60, 120, 240)
%   NSizeGrid           - Number of resource blocks in carrier resource
%                         grid (1...275)
%
%   Only frequency-related aspect of the carrier configuration object are
%   considered. Time-related aspects of the carrier, such as NSlot and
%   NFrame, are not relevant in the time-domain structure of the PRACH
%   preamble. Assuming that the carrier and PRACH start at the same time,
%   the PRACH slot numbering drives the time in the PRACH preamble
%   generation.
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
%   ActivePRACHSlot     - Active PRACH slot number within a subframe or
%                         a 60 kHz slot
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
%   % Plot the time-domain structure of the selected PRACH configuration
%   hPRACHPreamblePlot(carrier,prach);
%
%   See also nrPRACHOFDMInfo, hPRACHInfoDisplay, hPRACHResourceGridPlot,
%   nrPRACH.

% Copyright 2019-2021 The MathWorks, Inc.

    % Get the right format for the plot title
    switch upper(prach.FrequencyRange)
        case 'FR1'
            if strcmpi(prach.DuplexMode,'TDD') % TS 38.211 Table 6.3.3.2-3
                configTable = prach.Tables.ConfigurationsFR1Unpaired;
            else % TS 38.211 Table 6.3.3.2-2
                configTable = prach.Tables.ConfigurationsFR1PairedSUL;
            end
        otherwise % TS 38.211 Table 6.3.3.2-4
            configTable = prach.Tables.ConfigurationsFR2;
    end
    preambleFormat = configTable.PreambleFormat{prach.ConfigurationIndex+1};
    
    % Set up the figure data
    ph = 0.3; % Height of the plot
    lh = 0.2; % Height left blank in the plot for the legend
    f = figure('Name','Time-Domain Structure of the Current PRACH Preamble');
    ax = axes(f);
    yticks(ax,[]);
    ax.YColor = 'w';
    xlabel(ax,'Time  [ms]')
    titleTxt{1} = ['Time-Domain Structure of PRACH Preamble Format ' preambleFormat];
    if prach.LRA~=839
        % Add information about the carrier slot only for short PRACH
        % preambles
        if any(carrier.SubcarrierSpacing==[15,60])
            titleTxt{2} = ['within One ' num2str(carrier.SubcarrierSpacing) ' kHz Carrier Slot '];
        else
            titleTxt{2} = ['within Two ' num2str(carrier.SubcarrierSpacing) ' kHz Carrier Slots '];
        end
    else
        titleTxt{2} = '';
    end
    
    hold(ax,'on');
    plotHeights = [0 0 ph ph];
    lineWidth = 1;
    showLegendOthers = false; % By default, do not show the legend for occasions corresponding to all other configurations in time
    showLegendGPCurrent = false; % By default, do not show the legend for GP (current configuration)
    showLegendGPOthers = false; % By default, do not show the legend for GP (all other configurations in time)
    
    % Generate PRACH symbols to verify whether the PRACH is active in the
    % current slot(s). For 30 and 120 kHz, always plot two PRACH slots.
    % This makes the reference to TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4
    % clearer, as the PRACH is defined active based on a 15 or 60 kHz slot.
    scs30_120 = any(prach.SubcarrierSpacing==[30,120]);
    if scs30_120
        % Since the PRACH slots are 0-based, the first plotted slot is
        % always the one for which mod(prach.NPRACHSlot,2)==0.
        nprachSlot = fix(prach.NPRACHSlot/2)*2;
        prach.NPRACHSlot = nprachSlot;
        prachSymbols = nrPRACH(carrier,prach);
        prach.NPRACHSlot = nprachSlot + 1;
        prachSymbols = [prachSymbols; nrPRACH(carrier,prach)];
        prach.NPRACHSlot = nprachSlot + prach.ActivePRACHSlot; % Select NPRACHSlot in which there is a PRACH preamble
        titleTxt{2} = [titleTxt{2} '(NPRACHSlot = [' num2str(nprachSlot) ', ' num2str(nprachSlot+1) '])'];
    else
        prachSymbols = nrPRACH(carrier,prach);
        titleTxt{2} = [titleTxt{2} '(NPRACHSlot = ' num2str(prach.NPRACHSlot) ')'];
    end
    title(ax,titleTxt)
    
    % Display the PRACH preamble if the PRACH is active in the current
    % slot(s).
    if ~isempty(prachSymbols)
        % Loop over all the possible PRACH time occasions
        prach0 = prach; % Save the input configuration
        for timeOccasion = 0:prach.NumTimeOccasions - 1

            prach.TimeIndex = timeOccasion;

            % Generate the actual data to plot
            [plotCP, plotSEQ, plotGP] = getDataToPlotPreamble(carrier, prach);

            if prach.TimeIndex == prach0.TimeIndex
                % For the active PRACH occasion, use darker colors and add
                % the legend
                pCPCurrent  = cellfun(@(x) patch(ax, x, plotHeights,[0.88,0.35,0.13],'LineWidth',lineWidth), plotCP); % Cyclic prefix
                pSEQCurrent = cellfun(@(x) patch(ax, x, plotHeights,[0.13,0.57,0.86],'LineWidth',lineWidth), plotSEQ); % Sequence
                pGPCurrent  = cellfun(@(x) patch(ax, x, plotHeights,[0.47,0.67,0.19],'LineWidth',lineWidth), plotGP); % Guard period
                if plotGP{end}(2) > plotGP{end}(1) % Show legend for current GP
                    showLegendGPCurrent = true;
                end
            else
                % For the inactive PRACH occasion, use lighter colors
                pCPOthers = cellfun(@(x) patch(ax, x, plotHeights,[0.96,0.78,0.71],'LineWidth',lineWidth), plotCP); % Cyclic prefix
                pSEQOthers = cellfun(@(x) patch(ax, x, plotHeights,[0.71,0.8567,0.9533],'LineWidth',lineWidth), plotSEQ); % Sequence
                pGPOthers = cellfun(@(x) patch(ax, x, plotHeights,[0.8233,0.89,0.73],'LineWidth',lineWidth), plotGP); % Guard period
                if plotGP{end}(2) > plotGP{end}(1) % Show legend for GP (all other configurations in time) 
                    showLegendGPOthers = true;
                end
                showLegendOthers = true;
            end
        end
        % Display the legend
        if showLegendOthers % Show legend for all PRACH occasions
            if showLegendGPCurrent && showLegendGPOthers % Show legend for active and inactive GP
                hLeg = legend([pCPCurrent(1) pSEQCurrent(1) pGPCurrent(1) pCPOthers(1) pSEQOthers(1) pGPOthers(1)],...
                    'Cyclic Prefix - current','Sequence - current','Guard Period - current','Cyclic Prefix','Sequence','Guard Period','Location','north');
            elseif showLegendGPCurrent && ~showLegendGPOthers % Show legend for active GP only
                hLeg = legend([pCPCurrent(1) pSEQCurrent(1) pGPCurrent(1) pCPOthers(1) pSEQOthers(1)],...
                    'Cyclic Prefix - current','Sequence - current','Guard Period - current','Cyclic Prefix','Sequence','Location','north');
            elseif ~showLegendGPCurrent && showLegendGPOthers % Show legend for inactive GP only
                hLeg = legend([pCPCurrent(1) pSEQCurrent(1) pCPOthers(1) pSEQOthers(1) pGPOthers(1)],...
                    'Cyclic Prefix - current','Sequence - current','Cyclic Prefix','Sequence','Guard Period','Location','north');
            else % Do not show legend for GP
                hLeg = legend([pCPCurrent(1) pSEQCurrent(1) pCPOthers(1) pSEQOthers(1)],...
                    'Cyclic Prefix - current','Sequence - current','Cyclic Prefix','Sequence','Location','north');
            end
            hLeg.NumColumns = 2;
        else % Show the legend only for current occasion
            legend([pCPCurrent(1) pSEQCurrent(1) pGPCurrent(1)],...
                'Cyclic Prefix','Sequence','Guard Period','Location','north');
        end
        NumSubframes = ceil((plotGP{end}(2) - plotCP{1}(1))*4)/4;
        
        % Hold off and adjust the axes limits
        hold(ax,'off');
        axis(ax,[0 max(NumSubframes,prach.SubframesPerPRACHSlot*(1+scs30_120)) 0 (ph+lh)])
    else
        % PRACH preamble is not active in the current slot(s). Leave the
        % plot blank
        
        % Hold off and adjust the axes limits
        hold(ax,'off');
        axis(ax,[0 prach.SubframesPerPRACHSlot*(1+scs30_120) 0 (ph+lh)])
    end
    ax.PlotBoxAspectRatio = [2 1 2];
end

function [plotCP, plotSEQ, plotGP] = getDataToPlotPreamble(carrier, prach)
%getDataToPlotPreamble Generate the data for the plot
%
%   [PLOTCP,PLOTSEQ,PLOTGP] = getDataToPlotPreamble(CARRIER,PRACH)
%   generates the data to be used in hPRACHPreamblePlot to plot the
%   time-domain illustration of the current PRACH preamble.
%
%   All the outputs are cell arrays, in which the number of elements is
%   given by the value of PRACHDuration in TS 38.211 Table 6.3.3.2-2,
%   6.3.3.2-3 or 6.3.3.2-4. Each element of the cell array is a 4-element
%   set containing the vertices of the current instance to plot.
%   PLOTCP contains the data for the cyclic prefix(CP).
%   PLOTSEQ contains the data for the actual PRACH preamble divided into
%   blocks of length T_SEQ.
%   PLOTGP contains the data for the guard period (GP).
%
%   Note that only the frequency-related aspect of the carrier
%   configuration object are used here, whereas the time-related aspects of
%   it (i.e., NSlot and NFrame) are not considered. In the assumption that
%   both carrier and PRACH have the same starting time, the generation of a
%   PRACH preamble in the carrier is be done by letting the PRACH slot
%   numbering drive the time.
    
    % Current symbol location in a PRACH slot
    % Note that SymbolLocation refers to the location of the first PRACH
    % OFDM symbol in the current active occasion, according to the
    % definition of 'l' in TS 38.211 Section 5.3.2. That is, this value can
    % be outside of one PRACH slot, if prach.ActivePRACHSlot is set to 1.
    % In the case of format C0, each preamble has one active sequence
    % period (see TS 38.211 Table 6.3.3.1-2) but including the guard and
    % the cyclic prefix, the preamble spans two OFDM symbols (given by
    % PRACHDuration in the configuration tables above). For this reason,
    % the slot grid related to format C0 has 7 OFDM symbols, rather than
    % 14, and each value related to it that is derived directly from
    % TS 38.211 is halved.
    if strcmpi(prach.Format,'C0')
        numOFDMSymbPerSlot = 7;
    else
        % Note that numOFDMSymbPerSlot does not influence the value of
        % SymbolLocation for those cases in which ActivePRACHSlot is zero.
        numOFDMSymbPerSlot = 14;
    end
    symbLoc = prach.SymbolLocation - numOFDMSymbPerSlot*prach.ActivePRACHSlot; % Consider a single PRACH slot
    
    % Calculate OFDM information for the current PRACH occasion
    prachInfo = nrPRACHOFDMInfo(carrier,prach);
    PRACHDuration = prach.PRACHDuration;
    
    % For long sequences (LRA=839), only one PRACH occasion is allowed.
    % That is, symbLoc has the same meaning as the parameter StartingSymbol
    % from TS 38.211 Tables 6.3.3.2-2 and 6.3.3.2-3.
    % For long sequences and non-zero symbLoc, the starting position is
    % implemented as an initial guard length N_offset in the internal
    % function OFDMInfo. Thus, symbLoc is set to zero for the sake of the
    % plot.
    if prach.LRA==839
        symbLoc = 0;
    end
    
    % Calculate cyclic prefix length, guard period, and length of one
    % sequence for the current PRACH time occasion
    TCP = prachInfo.CyclicPrefixLengths / prachInfo.SampleRate *1e3; % Cyclic prefix time [ms]
    GP = prachInfo.GuardLengths / prachInfo.SampleRate *1e3; % Guard period [ms] 
    TSEQ = repmat(prachInfo.Nfft/prachInfo.SampleRate*1e3,1,length(TCP)); % Sequence time [ms]
    
    if (strcmpi(prach.Format,'C2'))
       % For format C2, the OFDM information is adjusted as follows:
       % * The first OFDM symbol of the occasion is removed and its 
       %   duration is added to the cyclic prefix
       % * The last OFDM symbol of the occasion is removed and its
       %   duration is added to the guard interval
       idx = [1 PRACHDuration].' + [0 PRACHDuration];
       TCP(idx(1,:)) = TCP(idx(1,:)) + TSEQ(idx(1,:));
       GP(idx(2,:)) = GP(idx(2,:)) + TSEQ(idx(2,:));
       idx = idx + [1; -1];
       TCP(idx) = [];
       GP(idx) = [];
       TSEQ(idx) = [];
       PRACHDuration = PRACHDuration - 2;
       if (symbLoc > 0)
           symbLoc = symbLoc - 2;
       end
    end
    
    TSequence = TCP + TSEQ + GP; % Length of one sequence, with the corresponding CP and GP [ms]
    
    % Generate data for the plots
    TCP = num2cell(TCP(symbLoc+1:symbLoc+PRACHDuration));
    GP = num2cell(GP(symbLoc+1:symbLoc+PRACHDuration));
    TSequenceSum = num2cell([0 cumsum(TSequence(symbLoc+1:symbLoc+PRACHDuration-1))]);
    
    plotOffset = sum(TSequence(1:symbLoc)) + mod(prachInfo.OffsetLength/prachInfo.SampleRate*1e3,15/carrier.SubcarrierSpacing);
    if prach.LRA~=839 && any(prach.SubcarrierSpacing==[30,120]) && ...
            (mod(prach.NPRACHSlot,2) && prach.ActivePRACHSlot)
        % If ActivePRACHSlot is 1, add an empty PRACH slot to plotOffset so
        % that the PRACH preamble is displayed in the second half of the
        % subframe/60 kHz slot
        emptySlot = sum(TSequence);
        plotOffset = plotOffset + emptySlot;
    end
    
    plotCP    = cellfun(@(x,y)([plotOffset+x, plotOffset+x+y, plotOffset+x+y, plotOffset+x]), TSequenceSum, TCP, 'UniformOutput', false); % Cyclic prefix
    plotSEQ   = cellfun(@(x)([x(2), x(2)+TSEQ(symbLoc+1), x(2)+TSEQ(symbLoc+1), x(2)]), plotCP, 'UniformOutput', false); % Sequence
    plotGP    = cellfun(@(x,y)([x(2), x(2)+y, x(2)+y, x(2)]), plotSEQ, GP, 'UniformOutput', false); % Guard period
end