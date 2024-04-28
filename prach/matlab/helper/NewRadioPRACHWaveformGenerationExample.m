%% 5G NR PRACH Waveform Generation 
% This example implements a 5G NR PRACH waveform generator using 5G
% Toolbox(TM). The example shows how to parameterize and generate a 5G New
% Radio (NR) physical random access channel (PRACH) waveform, as defined in
% TS 38.211 [ <#7 1> ]. The example demonstrates the parameterization and
% generation of one PRACH configuration in a single carrier, and displays
% the positions of the PRACH preambles in the resource grid. You can define
% the length of the waveform, in terms of subframes, and set the pattern of
% the active PRACH preambles in the generated waveform.

% Copyright 2019-2020 The MathWorks, Inc.

%% Waveform and Carrier Configuration
% Configure one carrier and set the length of the generated waveform in
% terms of 1 ms subframes. Visualize the generated resource grid by setting
% the |DisplayGrids| field to 1.
%
% Use the |waveconfig| structure to store configuration parameters needed
% for the PRACH waveform generation. The |waveconfig| structure contains
% these fields:
%
% * |NumSubframes|:  Number of 1 ms subframes in generated waveform.
% * |DisplayGrids|:  If set to 1, the example displays the resource grid.
% * |Windowing|:     Number of time-domain samples over which to apply
%                    windowing and overlapping of OFDM symbols. For more
%                    information, see <docid:5g_ref#mw_function_nrPRACHOFDMModulate nrPRACHOFDMModulate>.
% * |Carriers|:      Carrier-specific configuration object, as described in
%                    <docid:5g_ref#mw_object_nrCarrierConfig nrCarrierConfig>.
% * |PRACH|:         Structure containing the PRACH-related configuration,
%                    as described in detail in the <#2 PRACH Configuration>
%                    section.

waveconfig = [];
waveconfig.NumSubframes = 10; % Number of 1 ms subframes in generated waveform
waveconfig.DisplayGrids = 1;  % Display the resource grid
waveconfig.Windowing = [];    % Use the default windowing

% Define a carrier configuration object
carrier = nrCarrierConfig;
carrier.SubcarrierSpacing = 15;
carrier.NSizeGrid = 52;

% Store the carrier into the waveconfig structure
waveconfig.Carriers = carrier;

%% PRACH Configuration
% Set the parameters for the PRACH, taking into account that the numerology
% of the PRACH can be different from that of the carrier.
% This example sets the PRACH configuration corresponding to a PRACH short
% preamble format B2 with 15 kHz subcarrier spacing.
%
% You can also set additional PRACH parameters. For more information, see
% <docid:5g_ref#mw_object_nrPRACHConfig nrPRACHConfig>.
%
% Add the field |PRACH| to the |waveconfig| structure to store the PRACH
% configuration and related parameters. The field |PRACH| is a structure
% containing these fields:
%
% * |Config|:             PRACH configuration object
% * |AllocatedPreambles|: Index (0-based) of the allocated PRACH preambles
%                         to transmit. This field considers only the active
%                         PRACH preambles. Set this value to 'all' to
%                         include all the active PRACH preambles in the
%                         waveform.
% * |Power|:              PRACH power scaling in dB. This parameter
%                         represents $\beta_{PRACH}$ (in dB) in TS 38.211
%                         Section 6.3.3.2.

% PRACH configuration
prach = nrPRACHConfig;
prach.FrequencyRange = 'FR1';   % Frequency range ('FR1', 'FR2')
prach.DuplexMode = 'FDD';       % Duplex mode ('FDD', 'TDD', 'SUL')
prach.ConfigurationIndex = 145; % Configuration index (0...255)
prach.SubcarrierSpacing = 15;   % Subcarrier spacing (1.25, 5, 15, 30, 60, 120)
prach.FrequencyIndex = 0;       % Index of the PRACH transmission occasions in frequency domain (0...7)
prach.TimeIndex = 2;            % Index of the PRACH transmission occasions in time domain (0...6)
prach.ActivePRACHSlot = 0;      % Active PRACH slot number within a subframe or a 60 kHz slot (0, 1)

% Store the PRACH configuration and additional parameters in the
% waveconfig structure
waveconfig.PRACH.Config = prach;
waveconfig.PRACH.AllocatedPreambles = 'all'; % Index of the allocated PRACH preambles
waveconfig.PRACH.Power = 0;                  % PRACH power scaling in dB

%% Waveform Generation
% Generate the PRACH complex baseband waveform by using the parameters
% stored in the |waveconfig| structure.

[waveform,gridset,winfo] = hNRPRACHWaveformGenerator(waveconfig);

%%
% When |waveconfig.DisplayGrids| is set to |1|, the waveform generator also
% plots the PRACH resource grid, in PRACH numerology. For more information
% on the number of OFDM symbols in the resource grid, see 5G NR PRACH
% Configuration.
%
% The waveform generator function returns the time domain waveform, and two
% structures: |gridset| and |winfo|.
%
% The structure |winfo| contains these fields:
%
% * |NPRACHSlot|:       PRACH slot numbers of each allocated PRACH preamble
% * |PRACHSymbols|:     PRACH symbols corresponding to each allocated PRACH slot
% * |PRACHSymbolsInfo|: Additional information associated with PRACH symbols
% * |PRACHIndices|:     PRACH indices corresponding to each allocated PRACH slot
% * |PRACHIndicesInfo|: Additional information associated with PRACH indices
%
% The structure |gridset| contains these fields: 
%
% * |ResourceGrid|: Resource grid corresponding to this carrier
% * |Info|:         Structure with information corresponding to the PRACH
%                   OFDM modulation. If the PRACH is configured for FR2 or
%                   the PRACH slot for the current configuration spans more
%                   than one subframe, some of the OFDM-related information
%                   may be different between PRACH slots. In this case, the
%                   info structure is an array of the same length as the
%                   number of PRACH slots in the waveform.

disp('Information associated with PRACH OFDM modulation for the first PRACH slot:')
disp(gridset.Info(1))

%% Summary and Further Exploration
% This example shows how to generate a time-domain waveform for a single
% PRACH configuration on a single carrier. You can set the length of the
% generated waveform in terms of number of subframes. You can also set the
% pattern of PRACH preambles in the generated waveform. The example also
% shows the OFDM-related information for the PRACH.
%
% To generate a waveform containing multiple PRACH configurations in the
% same carrier, run this example for several PRACH configurations and add
% the generated waveforms together.
%
% For more information about the PRACH configuration and the PRACH resource
% grid, see <docid:5g_ug#mw_7e1bde29-e4fc-415a-bb59-2120d912ebe3 5G NR PRACH Configuration>.

%% Appendix
% This example uses these helper functions:
% 
% * <matlab:edit('hNRPRACHWaveformGenerator.m') hNRPRACHWaveformGenerator.m>

%% Selected Bibliography
% # 3GPP TS 38.211. "NR; Physical channels and modulation." _3rd Generation
% Partnership Project; Technical Specification Group Radio Access Network_.
