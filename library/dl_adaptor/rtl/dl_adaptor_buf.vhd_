--------------------------------------------------------------------------------
-- company        :    Zillnk
-- engineer       :    --
-- create date    :    2021.04.13
-- top name       :    ZU19 TOP
-- module name    :    dl_adaptor_buf
-- project name   :    AAS 64T64R
-- target devices :    xczu19eg 
-- tool versions  :    vivado 
-- description    :    dl adaptor buffer module
--                      
--------------------------------------------------------------------------------
-- revision       :
-- date           editor      description
-- 2021.04.13                 first version
--****************************************************************************--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
--                         library declaration                                --
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
--****************************************************************************--
--------------------------------------------------------------------
-- Function Description:
--------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
--------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
                    
library work;
use work.zu19_top_type_pkg.all;

entity dl_adaptor_buf is
generic (
    LAYER_NUMBER_C         : integer := 16
    ); 
port
(   -- AXI clk&rst
    clk_axi                       : in     std_logic;  
    rst_axi                       : in     std_logic; 
    
    --clock & reset
    clk_491m_i                    : in std_logic;  -- 491M clk
    rst_491m_i                    : in std_logic;  -- reset of 491m clock domain, high active
    clk_491m_gating_dl_i          : in std_logic;  -- 491M gaitng clock, clock works in DL time slot
    clk_491m_gating_dl_flush_i    : in std_logic;  -- 491M gaitng clock related flush signal, indicator for DL zero flushing, not used
    
    -- RAT and bandwidth configuration
    bw_mode_i                     : in std_logic_vector(4-1 downto 0);  -- carrier bandwidth mode, 0 for 100M, 1 for 80M, 2 for 60M, 3 for 50M, 4 for 40M, 5 for 30M, 6 for 20M, 7 for 15M, 8 for 10M, others for 100M
    rat_mode_i                    : in std_logic_vector( 2-1 downto 0 ); --RAT mode, 0 for NR scs 30khz mode, 1 for NR scs 60khz mode, 2 for LTE scs 15khz mode 3 for NR scs 15khz mode
    s0_rd_trig_i                  : in std_logic;     -- not used.  s0 read out trigger, s0 data will be read out with one symbol delay after the rising edge when s0_rd_trig_en is enabled
    s0_rd_trig_en                 : in std_logic; -- not used.
    compression_mode              : in std_logic_vector( 2-1 downto 0 );  --"00" non-compression mode, "01" BFP 9 compression mode, "10" reserved for modulation compression mode
    
    buffer_mem_ctrl_en            : in  std_logic_vector( 2-1 downto 0 );  -- AXI override mode for adaptor buffer URAM, "00" for normal ORAN data mode, "10" AXI override mode for URAM lower 32 bit data, "11" AXi override mode for URAM higher 32 bit data
    buffer_mem_addr_i             : in  vector_12b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_data_i             : in  vector_32b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_we                 : in  vector_1b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_data_o             : out  vector_32b_t(LAYER_NUMBER_C-1 downto 0);
   
    dl_data_i           : in  vector_64b_t(LAYER_NUMBER_C-1 downto 0);  --  64 bits valid for non-compressed format, Q odd[63:48], I odd[47:32], Q even [31:16], I even [15:0]; 16 bits valid for mudulation compressed format, data odd [39:32], data even[7:0]; 44 bits valid for bfp9 formatl, exponent odd [53:50],  Q odd[49:41], I odd[40:32], exponent even [21:18], Q even [17:9], I even [8:0]: 
    dl_data_sof_i       : in  std_logic_vector(LAYER_NUMBER_C-1 downto 0); --10ms radio frame data start indicator
    dl_data_sop_i       : in  std_logic_vector(LAYER_NUMBER_C-1 downto 0); --OFDM symbol start indicator
    dl_data_valid_i     : in  std_logic_vector(LAYER_NUMBER_C-1 downto 0);
    re_no_i             : in  vector_12b_t(LAYER_NUMBER_C-1 downto 0);  -- re no of data even, should be an even number
    
    -- data bus & valid & sop & sof & index output
    dl_di_o             : out   vector_16b_t(LAYER_NUMBER_C-1 downto 0);
    dl_dq_o             : out   vector_16b_t(LAYER_NUMBER_C-1 downto 0);
    dl_sof_o            : out   std_logic;
    dl_sop_o            : out   std_logic;
    dl_sof_ahead_7_o    : out   std_logic;
    dl_sop_ahead_7_o    : out   std_logic;
    dl_valid_o          : out   std_logic
);
end dl_adaptor_buf;

architecture bh of dl_adaptor_buf is
 
component dl_adaptor_ctrl is
  port (
    clk              : in std_logic;
    bw_sel_i         : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i       : in std_logic_vector( 2-1 downto 0 );
    s0_read_trig     : in std_logic_vector( 1-1 downto 0 );
    s0_read_trig_en  : in std_logic_vector( 1-1 downto 0 );
    sof0_i           : in std_logic_vector( 1-1 downto 0 );
    sof_o            : out std_logic_vector( 1-1 downto 0 );
    sop_o            : out std_logic_vector( 1-1 downto 0 );
    sof_ahead_7_o    : out std_logic_vector( 1-1 downto 0 );
    sop_ahead_7_o    : out std_logic_vector( 1-1 downto 0 );
    valid_o          : out std_logic_vector( 1-1 downto 0 );
    subframe_no_o    : out std_logic_vector( 9-1 downto 0 );
    symbol_no_o      : out std_logic_vector( 9-1 downto 0 );
    buffer_rd_ctrl0  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl1  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl2  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl3  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl4  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl5  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl6  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl7  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl8  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl9  : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl10 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl11 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl12 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl13 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl14 : out std_logic_vector( 15-1 downto 0 );
    buffer_rd_ctrl15 : out std_logic_vector( 15-1 downto 0 )
  );
end component;
 
component dl_adaptor_data is
  port (
    clk                : in std_logic;
    compression_mode   : in std_logic_vector( 2-1 downto 0 );
    buffer_rd_ctrl_i   : in std_logic_vector( 15-1 downto 0 );
    buffer_mem_addr_i  : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i  : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we      : in std_logic_vector( 1-1 downto 0 );
    buffer_mem_data_o  : out std_logic_vector( 32-1 downto 0 );
    data_i             : in std_logic_vector( 64-1 downto 0 );
    sof_i              : in std_logic_vector( 1-1 downto 0 );
    sop_i              : in std_logic_vector( 1-1 downto 0 );
    re_no_i            : in std_logic_vector( 12-1 downto 0 );
    valid_i            : in std_logic_vector( 1-1 downto 0 );
    idata_o            : out std_logic_vector( 16-1 downto 0 );
    qdata_o            : out std_logic_vector( 16-1 downto 0 )
  );
end component;
 
 
 
 
 
   signal buffer_rd_ctrl           : vector_15b_t(16-1 downto 0);
-----------------------END of Xil DPD-------------------------------  
   --attribute mark_debug: string;                                     
   --attribute mark_debug of ul_bfp_data_i         : signal is "true";   
   --attribute mark_debug of ul_bfp_sof_s         : signal is "true";   
   --attribute mark_debug of ul_bfp_sop_s         : signal is "true";   
    
    begin
      
    inst_dl_adaptor_ctrl : dl_adaptor_ctrl
      port map(
        clk                 => clk_491m_i,
        bw_sel_i            => bw_mode_i,
        rat_mode_i          => rat_mode_i, 
        s0_read_trig(0)     => s0_rd_trig_i,
        s0_read_trig_en(0)  => s0_rd_trig_en,
        sof0_i(0)           => dl_data_sof_i(0),
        sof_o(0)            => dl_sof_o,
        sop_o(0)            => dl_sop_o,
        sof_ahead_7_o(0)    => dl_sof_ahead_7_o,
        sop_ahead_7_o(0)    => dl_sop_ahead_7_o,
        valid_o(0)          => dl_valid_o,
        subframe_no_o       => open,
        symbol_no_o         => open,
        buffer_rd_ctrl0     => buffer_rd_ctrl(0), 
        buffer_rd_ctrl1     => buffer_rd_ctrl(1), 
        buffer_rd_ctrl2     => buffer_rd_ctrl(2), 
        buffer_rd_ctrl3     => buffer_rd_ctrl(3), 
        buffer_rd_ctrl4     => buffer_rd_ctrl(4), 
        buffer_rd_ctrl5     => buffer_rd_ctrl(5), 
        buffer_rd_ctrl6     => buffer_rd_ctrl(6), 
        buffer_rd_ctrl7     => buffer_rd_ctrl(7), 
        buffer_rd_ctrl8     => buffer_rd_ctrl(8), 
        buffer_rd_ctrl9     => buffer_rd_ctrl(9), 
        buffer_rd_ctrl10    => buffer_rd_ctrl(10),
        buffer_rd_ctrl11    => buffer_rd_ctrl(11),
        buffer_rd_ctrl12    => buffer_rd_ctrl(12),
        buffer_rd_ctrl13    => buffer_rd_ctrl(13),
        buffer_rd_ctrl14    => buffer_rd_ctrl(14),
        buffer_rd_ctrl15    => buffer_rd_ctrl(15)
      );  
      
   dl_adaptor_data_layer_inst: for ii in 0 to LAYER_NUMBER_C-1 generate   
         inst_dl_adaptor_data : dl_adaptor_data
          port  map(
           clk                => clk_491m_gating_dl_i,
           compression_mode   => compression_mode,
           buffer_rd_ctrl_i   => buffer_rd_ctrl(ii),
           buffer_mem_addr_i  => buffer_mem_addr_i(ii), 
           buffer_mem_ctrl_en => buffer_mem_ctrl_en,
           buffer_mem_data_i  => buffer_mem_data_i(ii), 
           buffer_mem_we      => buffer_mem_we(ii),     
           buffer_mem_data_o  => buffer_mem_data_o(ii), 
           data_i             => dl_data_i(ii),
           sof_i(0)           => dl_data_sof_i(ii),
           sop_i(0)           => dl_data_sop_i(ii),
           valid_i(0)         => dl_data_valid_i(ii),
           re_no_i            => re_no_i(ii),
           idata_o            => dl_di_o(ii),
           qdata_o            => dl_dq_o(ii)
          );
     end generate;  
  
end bh; 
                             
                         