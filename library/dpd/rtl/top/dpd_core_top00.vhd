--------------------------------------------------------------------
-- COPYRIGHT (c) Ericsson CBC, 2014
-- The copyright to the document(s) herein is the property of
-- Ericsson CBC.
--
-- The document(s) may be used and/or copied only with the written
-- permission from <Ericsson company>, or in accordance with
-- the terms and conditions stipulated in the agreement/contract
-- under which the document(s) have been supplied.
--
-- All rights reserved.
--------------------------------------------------------------------
--
-- Author
-- Created: NOV. 20,2014
-- [Revision date: 2016-09-30
-- [Revised by: eyonfen
--
--------------------------------------------------------------------
-- Description:
-- dpd_core top
--
--
--
--------------------------------------------------------------------
-- VHDL Version: VHDL
--
--------------------------------------------------------------------
--------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity dpd_core_top is
  port(
    -- AXI BRAM, 64K bytes
    BRAM_clk        : in std_logic;
    BRAM_rst        : in std_logic;

    BRAM_en_i       : in std_logic;
    BRAM_addr_i     : in std_logic_vector ( 17 downto 0 );
    BRAM_din_i      : in std_logic_vector ( 31 downto 0 );
    BRAM_we_i       : in std_logic_vector (  3 downto 0 );
    BRAM_dout_o     : out std_logic_vector( 31 downto 0 );

    -- per bus
    per_rst     : in std_logic;
    per_clk     : in std_logic;

    per_addr    : in std_logic_vector(19 downto 0);
    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;
    per_rden    : in std_logic;
    
    per_rddata  : out std_logic_vector(31 downto 0);
    per_rdval   : out std_logic;
  
    -- microblaze clock
    clk_proc        : in std_logic;
    rst_proc        : in std_logic;

    -- opb bus
    clk_opb         : in  std_logic;
    rst_opb         : in  std_logic;

    opb_select      : in  std_logic;
    opb_fwxfer      : in  std_logic;
    opb_hwxfer      : in  std_logic;
    opb_rnw         : in  std_logic;
    opb_seqaddr     : in  std_logic;
    opb_dbus        : in  std_logic_vector(0 to 31);
    opb_abus        : in  std_logic_vector(0 to 31);
    sl_errack       : out std_logic;
    sl_retry        : out std_logic;
    sl_toutsup      : out std_logic;
    sl_xferack      : out std_logic;
    sl_fwack        : out std_logic;
    sl_hwack        : out std_logic;
    sl_dbusen       : out std_logic;
    sl_dbus         : out std_logic_vector(0 to 31);

    -- power_saving signals
    ps_indicate_dl   : in std_logic; -- low : clock off, high : clock on
    dl_flusher       : in std_logic;
    dpd_ramp         : in std_logic;
    gate_clk_491_dl  : in std_logic;
    gate_clk_245_dl  : in std_logic;
    gate_clk_122_dl  : in std_logic;

    rst_i           : in  std_logic;
    clk_491         : in  std_logic;
    clk_245         : in  std_logic;
    clk_122         : in  std_logic;

    tx_valid_i      : in  std_logic;
    align_trig_i    : in  std_logic;
    frame_start     : in  std_logic;
    pa_on           : in  std_logic_vector(7 downto 0);
    
    dpd_data0_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data1_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data2_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data3_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data4_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data5_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data6_i_i   :   in  std_logic_vector(15 downto 0);
    dpd_data7_i_i   :   in  std_logic_vector(15 downto 0);

    dpd_data0_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data1_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data2_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data3_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data4_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data5_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data6_q_i   :   in  std_logic_vector(15 downto 0);
    dpd_data7_q_i   :   in  std_logic_vector(15 downto 0);

    dpd_data0_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data1_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data2_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data3_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data4_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data5_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data6_odd_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data7_odd_i_o  :   out std_logic_vector(15 downto 0);

    dpd_data0_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data1_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data2_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data3_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data4_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data5_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data6_odd_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data7_odd_q_o  :   out std_logic_vector(15 downto 0);

    dpd_data0_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data1_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data2_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data3_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data4_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data5_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data6_even_i_o  :   out std_logic_vector(15 downto 0);
    dpd_data7_even_i_o  :   out std_logic_vector(15 downto 0);
 
    dpd_data0_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data1_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data2_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data3_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data4_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data5_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data6_even_q_o  :   out std_logic_vector(15 downto 0);
    dpd_data7_even_q_o  :   out std_logic_vector(15 downto 0);
    
    tor_path_o      :   out std_logic_vector(2 downto 0);
    tor_dini_i      :   in  std_logic_vector(15 downto 0);
    tor_dinq_i      :   in  std_logic_vector(15 downto 0);
    tor_dini_i0                : in  std_logic_vector(15 downto 0);
    tor_dinq_i0                : in  std_logic_vector(15 downto 0);
    
    ----------------------------------------------------------------
    -- dpd tap interface --
    -- dbg_port_sel_i = 0: input data, 1: output odd data, 2: output even data
    dbg_port_sel_i      : in  std_logic_vector( 2 downto 0);
    dbg_path_sel_i      : in  std_logic_vector( 3 downto 0);
    dpd_tap_data        : out std_logic_vector(29 downto 0);

    dpd_stimuli_en      : in  std_logic_vector( 7 downto 0);
    dpd_stimuli         : in  std_logic_vector(29 downto 0);

    -- from cfr module, out-band monitor
    wb_flag         : in std_logic_vector(7 downto 0);

    -- internal bus between DPD & CFR
    ram_out_f       : in  std_logic_vector(15 downto 0);
    ram_out_s       : in  std_logic_vector(15 downto 0);
    
    new_per_rst_o   : out std_logic;
    new_per_we_o    : out std_logic;
    new_per_din_o   : out std_logic_vector(31 downto 0);
    new_per_addr_o  : out std_logic_vector(15 downto 0);
    new_per_dout_i  : in  std_logic_vector(31 downto 0);
    
    per_we_cfr_r1        : out std_logic;
    per_we_cfr_r2        : out std_logic;
    per_we_cfr_r3        : out std_logic;
    per_we_cfr_r4        : out std_logic;
    
    per_addr_cfr_r1      : out std_logic_vector(15 downto 0);
    per_addr_cfr_r2      : out std_logic_vector(15 downto 0);
    per_addr_cfr_r3      : out std_logic_vector(15 downto 0);
    per_addr_cfr_r4      : out std_logic_vector(15 downto 0);

    per_din_cfr_r1       : out std_logic_vector(31 downto 0);
    per_din_cfr_r2       : out std_logic_vector(31 downto 0);
    per_din_cfr_r3       : out std_logic_vector(31 downto 0);
    per_din_cfr_r4       : out std_logic_vector(31 downto 0);
    data_valid           : out std_logic;
    sw_int_o             : out std_logic_vector(3 downto 0)
  );
end dpd_core_top;  

architecture bh of  dpd_core_top is
  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  component async_regs_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector;
    regout  : out std_logic_vector
  );
  end component async_regs_def;

  component cross245to491special is
  port (
    clk245      : in std_logic;
    rst245      : in std_logic;

    clk491      : in std_logic;
    clk491v2    : out std_logic;
    clk491en2   : out std_logic
  );
  end component cross245to491special;
  
  component dpd_core_opb_if is
  generic (
    baseaddr_g   : natural := 16#0001000#  -- baseaddr = 0001000
  );
  port (
    clk_opb               : in  std_logic;
    rst_opb               : in  std_logic;

    opb_select            : in  std_logic;
    opb_fwxfer            : in  std_logic;
    opb_hwxfer            : in  std_logic;
    opb_rnw               : in  std_logic;
    opb_seqaddr           : in  std_logic;
    opb_dbus              : in  std_logic_vector(0 to 31);
    opb_abus              : in  std_logic_vector(0 to 31);
    sl_errack             : out std_logic;
    sl_retry              : out std_logic;
    sl_toutsup            : out std_logic;
    sl_xferack            : out std_logic;
    sl_fwack              : out std_logic;
    sl_hwack              : out std_logic;
    sl_dbusen             : out std_logic;
    sl_dbus               : out std_logic_vector(0 to 31);

    dpd_core_ram_busy     : in  std_logic;
    dpd_core_ram_sel      : out std_logic;
    dpd_core_ram_rd       : out std_logic;
    dpd_core_ram_wr       : out std_logic;
    dpd_core_ram_rd_data  : in  std_logic_vector(31 downto 0);
    dpd_core_ram_wr_data  : out std_logic_vector(31 downto 0);
    dpd_core_ram_addr     : out std_logic_vector(10 downto 0)
    );
  end component;

  component async_per_in is 
  generic (STAGE : integer := 2; ADDR_WIDTH : integer := 20);   -- >=2
  port (
    -- port 1
    clk1    : in std_logic := '0';
    rst1    : in std_logic := '0';
    addr1   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    wrdata1 : in std_logic_vector(31 downto 0);
    wren1   : in std_logic;
    rden1   : in std_logic;

    -- port 2
    clk2  : in std_logic := '0';
    rst2  : in std_logic := '0';
    addr2   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    wrdata2 : out std_logic_vector(31 downto 0);
    wren2   : out std_logic;
    rden2   : out std_logic
  );
  end component async_per_in;
  
  component dpd_ram_wrapper is 
    port (
      ----------------------------------------------------------------------------
      -- port 1
      clk1    : in std_logic := '0';
      
      addr1   : in std_logic_vector(11 downto 0);
      wrdata1 : in std_logic_vector(31 downto 0);
      wren1   : in std_logic;
      rddata1 : out std_logic_vector(31 downto 0);
      
      ----------------------------------------------------------------------------
      -- port 2
      clk2    : in std_logic := '0';
      
      addr2   : in std_logic_vector(11 downto 0);
      wrdata2 : in std_logic_vector(31 downto 0);
      wren2   : in std_logic;
      rddata2 : out std_logic_vector(31 downto 0)
    );
  end component dpd_ram_wrapper;

  component in2x is 
    port (
      ----------------------------------------------------------------------------
      -- port 1
      clk     : in std_logic := '0';
      rstx    : in std_logic_vector( 0 downto 0);
      
      xi      : in std_logic_vector(15 downto 0);
      xq      : in std_logic_vector(15 downto 0);
      
      yi      : out std_logic_vector(15 downto 0);
      yq      : out std_logic_vector(15 downto 0)
    );
  end component in2x;
  
  component dpd_v50 is
  generic (PROC_CLKF : integer := 150000000; PATH_NUM_DEF  : integer := 8; PHASE : integer := 1);
  port (
    ----------------------------------------------------------------------------
    -- global reset and clock
    rst245      : in std_logic;   -- async reset, active high
    rst491      : in std_logic;

    clk245      : in std_logic;   -- 245.76MHz clock
    clk491      : in std_logic;   -- 491.52MHz clock
    en2s        : in std_logic;   -- 245 <=> 491, cross enable, aligned with clk245

    ----------------------------------------------------------------------------
    -- radio software config
    aum_clk     : in std_logic;
    aum_rst     : in std_logic;
    aum_addr    : in std_logic_vector(11 downto 0);
    aum_din     : in std_logic_vector(31 downto 0);
    aum_we      : in std_logic;
    
    -- processor interface
    per_clk     : in std_logic;   -- clock for peripheral
    per_rst     : in std_logic;

    per_addr_i  : in std_logic_vector(19 downto 0);
    per_wrdata_i: in std_logic_vector(31 downto 0);
    per_wren_i  : in std_logic;
    per_rden_i  : in std_logic;

    per_rddata_o: out std_logic_vector(31 downto 0);
    per_rdval_o : out std_logic;
    
    -- bram interface
    bram_rst    : in std_logic;
    bram_clk    : in std_logic;

    bram_addr_i : in std_logic_vector(15 downto 0);
    bram_data_i : in std_logic_vector(31 downto 0);
    bram_wren_i : in std_logic;
    bram_data_o : out std_logic_vector(31 downto 0);
    
    interface_ram_rd    : in std_logic_vector(31 downto 0);     -- read from interface ram, combined to BRAM interface
    
    -- interrupt
    sw_int_o        : out std_logic_vector(3 downto 0);     -- Bit 0: elog storage request
                                                            -- BIT 1: not used
                                                            -- BIT 2: VCA gain changed
                                                            -- BIT 3: VCA fault

    ----------------------------------------------------------------------------
    -- signal path, input and output
    frm_start   : in std_logic;     -- frame start
    pa_on       : in std_logic;     -- '1'=on; '0'=off; up_edge: rx to tx; down_edge: tx to rx
    tx_valid    : in std_logic;     -- TX and TOR signal are valid for DPD
    cap_trig    : in std_logic;     -- User defined capture trigger, default '0'

    -- input signal
    xi      : in std_logic_vector( 16*PATH_NUM_DEF-1 downto 0 );
    xq      : in std_logic_vector( 16*PATH_NUM_DEF-1 downto 0 );

    -- output IQ signal
    yi0     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    yq0     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);

    yi1     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    yq1     : out std_logic_vector(PATH_NUM_DEF*16 - 1 downto 0);
    
    rxi         : in std_logic_vector(15 downto 0);     -- 491.52Msps
    rxq         : in std_logic_vector(15 downto 0);     --

    -- Log(N)*bit selector for Tor
    rx_path     : out std_logic_vector(7 downto 0);
    looped      : out std_logic;

    -- DPD status monitor output
    bk_gain     : out std_logic_vector(16*PATH_NUM_DEF-1 downto 0);
    status      : out std_logic_vector(31 downto 0)
  );
  end component dpd_v50;

  -- opb read & write
  signal aum_we          : std_logic;
  signal aum_addr        : std_logic_vector(10 downto 0);
  signal aum_din         : std_logic_vector(31 downto 0);
  signal aum_dout        : std_logic_vector(31 downto 0);
  signal aum_addr12      : std_logic_vector(11 downto 0);

  -- BRAM related
  signal words_addr     : std_logic_vector(15 downto 0);
  signal words_wren     : std_logic;
  signal bram_data_dpd  : std_logic_vector(31 downto 0);
  
  signal ifram_addr     : std_logic_vector(11 downto 0);
  signal ifram_din      : std_logic_vector(31 downto 0);
  signal ifram_we       : std_logic;
  signal ifram_data     : std_logic_vector(31 downto 0);
  
  -- clock sync
  signal sync_rst245    : std_logic;
  signal sync_rst491    : std_logic;
  
  signal clk491_v2    : std_logic;
  signal clk491_en2    : std_logic;

  -- tor
  signal tordata_i0   : std_logic_vector(15 downto 0);
  signal tordata_i1   : std_logic_vector(15 downto 0);
  signal tordata_q0   : std_logic_vector(15 downto 0);
  signal tordata_q1   : std_logic_vector(15 downto 0);
  
  signal rxi, rxq       : std_logic_vector(15 downto 0);

  -- output IQ, from 491 => 2x245
  signal pd_out_i1, pd_out_q1   : std_logic_vector(16*2 - 1 downto 0);
  signal pd_out_i0, pd_out_q0   : std_logic_vector(16*2 - 1 downto 0);

  signal dout_i1s, dout_i0s     : std_logic_vector(16*2 - 1 downto 0);
  signal dout_q1s, dout_q0s     : std_logic_vector(16*2 - 1 downto 0);
  
  signal dout_i_odd      : std_logic_vector(16*2 - 1 downto 0);
  signal dout_q_odd      : std_logic_vector(16*2 - 1 downto 0);
  signal dout_i_even     : std_logic_vector(16*2 - 1 downto 0);
  signal dout_q_even     : std_logic_vector(16*2 - 1 downto 0);
  
  -- control
  signal pa_on_s    : std_logic;
  signal sw_int_s   : std_logic_vector(3 downto 0);
  
  -- signal input 2x
  signal txi0, txq0     : std_logic_vector(15 downto 0);
  signal txi1, txq1     : std_logic_vector(15 downto 0);
    
  signal txi0s, txq0s     : std_logic_vector(15 downto 0);
  signal txi1s, txq1s     : std_logic_vector(15 downto 0);
  
  signal txi, txq       : std_logic_vector(16*2-1 downto 0);
  signal rx_path_s      : std_logic_vector(7 downto 0);
  signal looped, looped2: std_logic;
  
  signal rxi2, rxq2     : std_logic_vector(15 downto 0);

  signal cfr_addr       : std_logic_vector(19 downto 0);
  signal cfr_data       : std_logic_vector(31 downto 0);
  signal cfr_wren, cfr_wren2    : std_logic;
  
begin

  async0 : async_reg_def
  port map(
    clk     => clk_491,
    regin   => looped,
    regout  => looped2
  );
  
  inst_dpd_core_opb_if : dpd_core_opb_if
  port map(
    clk_opb               =>  clk_opb         ,
    rst_opb               =>  rst_opb         ,

    opb_select            =>  opb_select      ,
    opb_fwxfer            =>  opb_fwxfer      ,
    opb_hwxfer            =>  opb_hwxfer      ,
    opb_rnw               =>  opb_rnw         ,
    opb_seqaddr           =>  opb_seqaddr     ,
    opb_dbus              =>  opb_dbus        ,
    opb_abus              =>  opb_abus        ,
    sl_errack             =>  sl_errack       ,
    sl_retry              =>  sl_retry        ,
    sl_toutsup            =>  sl_toutsup      ,
    sl_xferack            =>  sl_xferack      ,
    sl_fwack              =>  sl_fwack        ,
    sl_hwack              =>  sl_hwack        ,
    sl_dbusen             =>  sl_dbusen       ,
    sl_dbus               =>  sl_dbus         ,

    dpd_core_ram_busy     =>  '0'             ,
    dpd_core_ram_sel      =>  open            ,
    dpd_core_ram_rd       =>  open            ,
    dpd_core_ram_wr       =>  aum_we          ,
    dpd_core_ram_rd_data  =>  aum_dout        ,
    dpd_core_ram_wr_data  =>  aum_din         ,
    dpd_core_ram_addr     =>  aum_addr
  );
  aum_addr12 <= "0" & aum_addr;

  -- 4096 ~ 8192
  words_addr <= BRAM_addr_i(17 downto 2);
  words_wren <= BRAM_en_i and BRAM_we_i(0) and BRAM_we_i(1) and BRAM_we_i(2) and BRAM_we_i(3);

  ifram_addr <= BRAM_addr_i(13 downto 2);
  ifram_din <= BRAM_din_i;
  ifram_we <= words_wren when BRAM_addr_i(17 downto 14) = "0001" else '0';

  inst_dpd_ram_wrapper : dpd_ram_wrapper
    port map (
      clk1 => clk_opb,
      wren1 => aum_we,
      addr1 => aum_addr12,
      wrdata1 => aum_din,
      rddata1 => aum_dout,

      clk2    => BRAM_clk,
      addr2   => ifram_addr,
      wrdata2 => ifram_din,
      wren2   => ifram_we,
      rddata2 => ifram_data
    );

  -- make sure that all path have the same [PA_ON] sequence
  pa_on_s <= pa_on(0) or pa_on(1);

  inst_clk_crx : cross245to491special
  port map (
    clk245      => clk_245 ,
    rst245      => sync_rst245 ,

    clk491      => clk_491 ,
    clk491v2    => clk491_v2 ,
    clk491en2   => clk491_en2
  );
  data_valid   <= clk491_en2;  
  sw_int_o   <= sw_int_s;
  process(clk_245)
  begin
    if rising_edge(clk_245) then
      tor_path_o    <= rx_path_s(2 downto 0);      -- 245.76Msps
      
      sync_rst245 <= rst_i;
    end if;
  end process;

  process(clk_491)
  begin
    if rising_edge(clk_491) then
      sync_rst491 <= rst_i;
    end if;
  end process;

  -- TOR conv
  process(clk_491)
  begin
    if rising_edge(clk_491) then
      if clk491_en2 = '0' then
        rxi <= tordata_i0;
        rxq <= tordata_q0;
      else
        rxi <= tordata_i1;
        rxq <= tordata_q1;
      end if;
      
      if clk491_en2 = '1' then
        tordata_i0 <= tor_dini_i0;
        tordata_i1 <= tor_dini_i;

        tordata_q0 <= tor_dinq_i0;
        tordata_q1 <= tor_dinq_i;
      end if;
      
      if looped2 = '0' then
        rxi2 <= rxi;
        rxq2 <= rxq;
      else
        rxi2 <= pd_out_i1(15 downto 0);
        rxq2 <= pd_out_q1(15 downto 0);
      end if;

    end if;
  end process;
  

  -- from 491 to 2x245
  process(clk_491)
  begin
    if rising_edge(clk_491) then
      pd_out_i0 <= pd_out_i1;
      pd_out_q0 <= pd_out_q1;
      
      if clk491_en2 = '1' then
        dout_i0s <= pd_out_i0;
        dout_q0s <= pd_out_q0;
        
        dout_i1s <= pd_out_i1;
        dout_q1s <= pd_out_q1;
      end if;
    end if;
  end process;
  
  process(clk_245)
  begin
    if rising_edge(clk_245) then
      dout_i_even <= dout_i0s;        -- even data goes first
      dout_q_even <= dout_q0s;
        
      dout_i_odd <= dout_i1s;
      dout_q_odd <= dout_q1s;    
    end if;
  end process;
  
  process(clk_491)
  begin
    if rising_edge(clk_491) then
      if clk491_en2 = '1' then
        txi0 <= dpd_data0_i_i;
        txq0 <= dpd_data0_q_i;

        txi1 <= dpd_data1_i_i;
        txq1 <= dpd_data1_q_i;
      end if;
    end if;
  end process;

  in0 : in2x
    port map(
      ----------------------------------------------------------------------------
      -- port 1
      clk     => clk_491,
      rstx(0) => sync_rst491,

      xi      => txi0,
      xq      => txq0,
      
      yi      => txi0s,
      yq      => txq0s
    );

  in1 : in2x
    port map(
      ----------------------------------------------------------------------------
      -- port 1
      clk     => clk_491,
      rstx(0) => sync_rst491,

      xi      => txi1,
      xq      => txq1,
      
      yi      => txi1s,
      yq      => txq1s
    );
  
  txi <= txi1s & txi0s;
  txq <= txq1s & txq0s;
  
  inst_dpd : dpd_v50
  generic map (PROC_CLKF => 50000000, PATH_NUM_DEF => 2, PHASE => 1)
  port map(
    ----------------------------------------------------------------------------
    -- global reset and clock
    rst245      => sync_rst245,
    rst491      => sync_rst491,

    clk245      => clk_245,
    clk491      => clk_491,
    en2s        => clk491_en2,

    ----------------------------------------------------------------------------
    -- radio software config
    aum_clk     => clk_opb,
    aum_rst     => rst_opb,
    aum_addr    => aum_addr12,
    aum_din     => aum_din,
    aum_we      => aum_we,
    
    -- processor interface
    per_clk     => per_clk,
    per_rst     => per_rst,

    per_addr_i  => per_addr,
    per_wrdata_i=> per_wrdata,
    per_wren_i  => per_wren,
    per_rden_i  => per_rden,

    per_rddata_o=> per_rddata,
    per_rdval_o => per_rdval,
    
    -- bram interface
    bram_rst    => BRAM_rst,
    bram_clk    => BRAM_clk,

    bram_addr_i => words_addr,
    bram_data_i => BRAM_din_i,
    bram_wren_i => words_wren,
    bram_data_o => BRAM_dout_o,
    interface_ram_rd    => ifram_data,
    
    -- interrupt
    sw_int_o        => sw_int_s,                            -- Bit 0: elog storage request
                                                            -- BIT 1: not used
                                                            -- BIT 2: VCA gain changed
                                                            -- BIT 3: VCA fault

    ----------------------------------------------------------------------------
    -- signal path, input and output
    frm_start   => frame_start,
    pa_on       => pa_on_s,
    tx_valid    => tx_valid_i,
    cap_trig    => align_trig_i,

    -- input signal
    xi      => txi,
    xq      => txq,

    -- output IQ signal
    yi0     => pd_out_i1,
    yq0     => pd_out_q1,

    yi1     => open,
    yq1     => open,

    rxi         => rxi2,
    rxq         => rxq2,

    -- Log(N)*bit selector for Tor
    rx_path     => rx_path_s,
    looped      => looped,

    -- DPD status monitor output
    bk_gain     => open,
    status      => open
  );

  dpd_data0_even_i_o <= dout_i_even(16*0 + 15 downto 16*0);
  dpd_data0_even_q_o <= dout_q_even(16*0 + 15 downto 16*0);

  dpd_data0_odd_i_o <= dout_i_odd(16*0 + 15 downto 16*0);
  dpd_data0_odd_q_o <= dout_q_odd(16*0 + 15 downto 16*0);

  dpd_data1_even_i_o <= dout_i_even(16*1 + 15 downto 16*1);
  dpd_data1_even_q_o <= dout_q_even(16*1 + 15 downto 16*1);

  dpd_data1_odd_i_o  <= dout_i_odd(16*1 + 15 downto 16*1);
  dpd_data1_odd_q_o  <= dout_q_odd(16*1 + 15 downto 16*1); 

  -- unused ports
    dpd_data2_odd_i_o  <= (others => '0');
    dpd_data3_odd_i_o  <= (others => '0');
    dpd_data4_odd_i_o  <= (others => '0');
    dpd_data5_odd_i_o  <= (others => '0');
    dpd_data6_odd_i_o  <= (others => '0');
    dpd_data7_odd_i_o  <= (others => '0');

    dpd_data2_odd_q_o  <= (others => '0');
    dpd_data3_odd_q_o  <= (others => '0');
    dpd_data4_odd_q_o  <= (others => '0');
    dpd_data5_odd_q_o  <= (others => '0');
    dpd_data6_odd_q_o  <= (others => '0');
    dpd_data7_odd_q_o  <= (others => '0');

    dpd_data2_even_i_o  <= (others => '0');
    dpd_data3_even_i_o  <= (others => '0');
    dpd_data4_even_i_o  <= (others => '0');
    dpd_data5_even_i_o  <= (others => '0');
    dpd_data6_even_i_o  <= (others => '0');
    dpd_data7_even_i_o  <= (others => '0');
 
    dpd_data2_even_q_o  <= (others => '0');
    dpd_data3_even_q_o  <= (others => '0');
    dpd_data4_even_q_o  <= (others => '0');
    dpd_data5_even_q_o  <= (others => '0');
    dpd_data6_even_q_o  <= (others => '0');
    dpd_data7_even_q_o  <= (others => '0');
    

    dpd_tap_data        <= (others => '0');

  -- CFR bus conversion
  async_per : async_per_in
  generic map(STAGE => 2, ADDR_WIDTH => 20)
  port map(
    -- port 1
    clk1    => per_clk ,
    rst1    => per_rst ,
    addr1   => per_addr ,
    wrdata1 => per_wrdata ,
    wren1   => cfr_wren2 ,
    rden1   => '0' ,

    -- port 2
    clk2  => clk_245 ,
    rst2  => sync_rst245 ,
    addr2   => cfr_addr ,
    wrdata2 => cfr_data ,
    wren2   => cfr_wren ,
    rden2   => open
  );

  cfr_wren2 <= '1' when (per_wren = '1') and (per_addr(19 downto 16) = X"8") else '0';

  process(clk_245)
  begin
    if rising_edge(clk_245) then
      new_per_we_o    <= cfr_wren ;
      new_per_din_o   <= cfr_data ;
      new_per_addr_o  <= cfr_addr(15 downto 0) ;
      
      per_we_cfr_r1        <= cfr_wren ;
      per_we_cfr_r2        <= cfr_wren ;
      per_we_cfr_r3        <= cfr_wren ;
      per_we_cfr_r4        <= cfr_wren ;
      
      per_addr_cfr_r1      <= cfr_addr(15 downto 0) ;
      per_addr_cfr_r2      <= cfr_addr(15 downto 0) ;
      per_addr_cfr_r3      <= cfr_addr(15 downto 0) ;
      per_addr_cfr_r4      <= cfr_addr(15 downto 0) ;

      per_din_cfr_r1       <= cfr_data ;
      per_din_cfr_r2       <= cfr_data ;
      per_din_cfr_r3       <= cfr_data ;
      per_din_cfr_r4       <= cfr_data ;
    end if;
  end process;

end bh;

