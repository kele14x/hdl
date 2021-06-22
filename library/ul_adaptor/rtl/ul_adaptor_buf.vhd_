--------------------------------------------------------------------------------
-- company        :    Zillnk
-- engineer       :    --
-- create date    :    2021.04.27
-- top name       :    ZU19 TOP
-- module name    :    ul_adaptor_buf
-- project name   :    AAS 64T64R
-- target devices :    xczu19eg 
-- tool versions  :    vivado 
-- description    :    ul adaptor buffer module
--                      
--------------------------------------------------------------------------------
-- revision       :
-- date           editor      description
-- 2021.04.27                 first version
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

entity ul_adaptor_buf is
generic (
    LAYER_NUMBER_C         : integer := 8
    ); 
port
(   -- AXI clk&rst
    clk_axi                       : in     std_logic;  
    rst_axi                       : in     std_logic; 
    
    --clock & reset
    clk_491m_i                    : in std_logic;  -- 491M clk
    rst_491m_i                    : in std_logic;  -- reset of 491m clock domain, high active
    clk_491m_gating_ul_i          : in std_logic;  -- 491M gaitng clock, clock works in UL time slot
    clk_491m_gating_ul_flush_i    : in std_logic;  -- 491M gaitng clock related flush signal, indicator for UL zero flushing, not used
    
    -- RAT and bandwidth configuration
    bw_mode_i                     : in std_logic_vector(4-1 downto 0);  -- carrier bandwidth mode, 0 for 100M, 1 for 80M, 2 for 60M, 3 for 50M, 4 for 40M, 5 for 30M, 6 for 20M, 7 for 15M, 8 for 10M, others for 100M
    rat_mode_i                    : in std_logic_vector( 2-1 downto 0 ); --RAT mode, 0 for NR scs 30khz mode, 1 for NR scs 60khz mode, 2 for LTE scs 15khz mode 3 for NR scs 15khz mode
    
    buffer_mem_ctrl_en            : in  std_logic_vector( 2-1 downto 0 );  -- AXI override mode for adaptor buffer URAM, "00" for normal ORAN data mode, "10" AXI override mode for URAM lower 32 bit data, "11" AXi override mode for URAM higher 32 bit data
    buffer_mem_addr_i             : in  vector_12b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_data_i             : in  vector_32b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_we                 : in  vector_1b_t(LAYER_NUMBER_C-1 downto 0);
    buffer_mem_data_o             : out  vector_32b_t(LAYER_NUMBER_C-1 downto 0);

    -- data bus & valid & sop & sof & index input
    ul_di_i                       : in   vector_16b_t(LAYER_NUMBER_C-1 downto 0);
    ul_dq_i                       : in   vector_16b_t(LAYER_NUMBER_C-1 downto 0);
    ul_sof_ahead_3_i              : in   std_logic;
    ul_sop_ahead_3_i              : in   std_logic;
                                  
    ul_buf_ready_o                : out   std_logic;                              -- ul adaptor buffer ready for data read out
    buffer_rd_addr_i              : in    vector_12b_t(LAYER_NUMBER_C-1 downto 0);  -- ul adaptor buffer read address
    buffer_rd_en_i                : in    vector_1b_t(LAYER_NUMBER_C-1 downto 0);  -- ul adaptor buffer read enable
                                  
    ul_data_o                     : out  vector_64b_t(LAYER_NUMBER_C-1 downto 0);  --  64 bits valid for non-compressed format, Q odd[63:48], I odd[47:32], Q even [31:16], I even [15:0]; 
    ul_data_sop_o                 : out  std_logic_vector(LAYER_NUMBER_C-1 downto 0); --OFDM symbol start indicator
    ul_data_valid_o               : out  std_logic_vector(LAYER_NUMBER_C-1 downto 0)
    
);
end ul_adaptor_buf;

architecture bh of ul_adaptor_buf is
 
component ul_adaptor_ctrl is
  port (
    clk              : in std_logic;
    bw_sel_i         : in std_logic_vector( 4-1 downto 0 );
    rat_mode_i       : in std_logic_vector( 2-1 downto 0 );
    ul_sof_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    ul_sop_ahead_3_i : in std_logic_vector( 1-1 downto 0 );
    buffer_wr_ctrl   : out std_logic_vector( 14-1 downto 0 );
    symbol_no_o      : out std_logic_vector( 9-1 downto 0 );
    ul_buf_ready_o   : out std_logic_vector( 1-1 downto 0 )
  );
end component;
 
component ul_adaptor_data is
  port (
    clk                : in std_logic;
    buffer_mem_addr_i  : in std_logic_vector( 12-1 downto 0 );
    buffer_mem_ctrl_en : in std_logic_vector( 2-1 downto 0 );
    buffer_mem_data_i  : in std_logic_vector( 32-1 downto 0 );
    buffer_mem_we      : in std_logic_vector( 1-1 downto 0 );
    buffer_mem_data_o  : out std_logic_vector( 32-1 downto 0 );
    buffer_wr_ctrl_i   : in std_logic_vector( 14-1 downto 0 );
    buffer_rd_addr_i   : in std_logic_vector( 13-1 downto 0 );
    buffer_rd_en_i     : in std_logic_vector( 1-1 downto 0 );
    idata_i            : in std_logic_vector( 16-1 downto 0 );
    qdata_i            : in std_logic_vector( 16-1 downto 0 );
    data_o             : out std_logic_vector( 64-1 downto 0 );
    sop_o              : out std_logic_vector( 1-1 downto 0 );
    valid_o            : out std_logic_vector( 1-1 downto 0 )
  );
end component;

 
   signal buffer_wr_ctrl           : vector_14b_t(8-1 downto 0);
   signal buffer_rd_addr_s         : vector_13b_t(LAYER_NUMBER_C-1 downto 0 );
   --attribute mark_debug: string;                                     
   --attribute mark_debug of ul_bfp_data_i         : signal is "true";   
   --attribute mark_debug of ul_bfp_sof_s         : signal is "true";   
   --attribute mark_debug of ul_bfp_sop_s         : signal is "true";   
    
    begin
      
    inst_ul_adaptor_ctrl : ul_adaptor_ctrl
      port map(
        clk                    => clk_491m_i,
        bw_sel_i               => bw_mode_i,
        rat_mode_i             => rat_mode_i, 
        ul_sof_ahead_3_i(0)    => ul_sof_ahead_3_i,
        ul_sop_ahead_3_i(0)    => ul_sop_ahead_3_i,
        buffer_wr_ctrl         => buffer_wr_ctrl(0),
        symbol_no_o            => open,
        ul_buf_ready_o         => open
      );  
      
 buffer_rd_addr_gen: for ii in 0 to LAYER_NUMBER_C-1 generate   
    buffer_rd_addr_s(ii) <= '0' & buffer_rd_addr_i(ii);
 end generate; 

 buffer_wr_ctrl_delay: for ii in 0 to 2 generate   
  process (clk_491m_i)
  begin
    if rising_edge (clk_491m_i) then
        buffer_wr_ctrl(ii+1) <= buffer_wr_ctrl(ii);
    end if;
  end process;        
 end generate; 
 
 buffer_wr_ctrl_copy: for ii in 0 to 4-1 generate   
     buffer_wr_ctrl(ii+4) <= buffer_wr_ctrl(ii);
 end generate; 
 
   ul_adaptor_data_layer_inst: for ii in 0 to LAYER_NUMBER_C-1 generate   
         inst_ul_adaptor_data : ul_adaptor_data
          port map(
           clk                => clk_491m_gating_ul_i,
           buffer_mem_addr_i  => buffer_mem_addr_i(ii), 
           buffer_mem_ctrl_en => buffer_mem_ctrl_en,
           buffer_mem_data_i  => buffer_mem_data_i(ii),
           buffer_mem_we      => buffer_mem_we(ii),    
           buffer_mem_data_o  => buffer_mem_data_o(ii),
           buffer_wr_ctrl_i   => buffer_wr_ctrl(ii),
           buffer_rd_addr_i   => buffer_rd_addr_s(ii),
           buffer_rd_en_i     => buffer_rd_en_i(ii),
           idata_i            => ul_di_i(ii),
           qdata_i            => ul_dq_i(ii),
           data_o             =>  ul_data_o(ii),      
           sop_o(0)           =>  ul_data_sop_o(ii),  
           valid_o(0)         =>  ul_data_valid_o(ii)
          );
     end generate;  
  
end bh; 
                             
                         