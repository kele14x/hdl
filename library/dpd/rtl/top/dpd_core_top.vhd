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
    -- AXI BRAM, 64K bytes
    BRAM_1_clk        : in std_logic;
    BRAM_1_rst        : in std_logic;
    BRAM_1_en_i       : in std_logic;
    BRAM_1_addr_i     : in std_logic_vector ( 17 downto 0 );
    BRAM_1_din_i      : in std_logic_vector ( 31 downto 0 );
    BRAM_1_we_i       : in std_logic_vector (  3 downto 0 );
    BRAM_1_dout_o     : out std_logic_vector( 31 downto 0 );
    
    -- per bus
    per_rst     : in std_logic;
    per_clk     : in std_logic;

    per_addr    : in std_logic_vector(19 downto 0);
    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;
    per_rden    : in std_logic;
    
    per_rddata  : out std_logic_vector(31 downto 0);
    per_rdval   : out std_logic;

    rst_i           : in  std_logic;
    clk_491         : in  std_logic;
    clk_245         : in  std_logic;
    clk_122         : in  std_logic;

    tx_valid_i      : in  std_logic;
    align_trig_i    : in  std_logic;
    frame_start     : in  std_logic;
    pa_on           : in  std_logic_vector(15 downto 0);
    
    dpd_data0_i_i   :   in  std_logic_vector(31 downto 0);--inptut data rate 491.52M
    dpd_data0_q_i   :   in  std_logic_vector(31 downto 0);

    dpd_data0_i_o   :   out std_logic_vector(31 downto 0);--output data rate 491.52M
    dpd_data0_q_o   :   out std_logic_vector(31 downto 0);

    tor_path_o      :   out std_logic_vector(3 downto 0);
    tor_din0_i      :   in  std_logic_vector(15 downto 0); -- tor data rate 491.52MHz
    tor_din0_q      :   in  std_logic_vector(15 downto 0)

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
  signal pd_out_i0, pd_out_q0   : std_logic_vector(16*2 - 1 downto 0);

  signal dout_i1s, dout_i0s     : std_logic_vector(16*2 - 1 downto 0);
  signal dout_q1s, dout_q0s     : std_logic_vector(16*2 - 1 downto 0);
  
  -- control
  signal pa_on_s    : std_logic;
  signal sw_int_s   : std_logic_vector(3 downto 0);
  
  -- signal input 2x
  
  signal txi, txq       : std_logic_vector(255 downto 0);
  signal rx_path_s      : std_logic_vector(7 downto 0);
  signal looped, looped2: std_logic;
  
  signal rxi2, rxq2     : std_logic_vector(15 downto 0);

  signal cfr_addr       : std_logic_vector(19 downto 0);
  signal cfr_data       : std_logic_vector(31 downto 0);
  signal cfr_wren, cfr_wren2    : std_logic;
  -- signal TOR
  signal tor_if_s, tor_if_s0, tor_if_s1       : std_logic_vector(15 downto 0);
  signal tor_if_cnt_s   : std_logic_vector(1 downto 0);
begin

  async0 : async_reg_def
  port map(
    clk     => clk_491,
    regin   => looped,
    regout  => looped2
  );
  
  -- 4096 ~ 8192
  words_addr <= BRAM_addr_i(17 downto 2);
  words_wren <= BRAM_en_i and BRAM_we_i(0) and BRAM_we_i(1) and BRAM_we_i(2) and BRAM_we_i(3);

  ifram_addr <= BRAM_addr_i(13 downto 2);
  ifram_din <= BRAM_din_i;
  ifram_we <= words_wren when BRAM_addr_i(17 downto 14) = "0001" else '0';
   
  aum_we <= BRAM_1_en_i and BRAM_1_we_i(0) and BRAM_1_we_i(1) and BRAM_1_we_i(2) and BRAM_1_we_i(3);
  inst_dpd_ram_wrapper : dpd_ram_wrapper
    port map (
      clk1 => BRAM_1_clk,
      wren1 => aum_we,
      addr1 => BRAM_1_addr_i(13 downto 2),
      wrdata1 => BRAM_1_din_i,
      rddata1 => BRAM_1_dout_o,

      clk2    => BRAM_clk,
      addr2   => ifram_addr,
      wrdata2 => ifram_din,
      wren2   => ifram_we,
      rddata2 => ifram_data
    );

  -- make sure that all path have the same [PA_ON] sequence
  pa_on_s <= pa_on(0) or pa_on(1) or pa_on(2) or pa_on(3) or pa_on(4) or pa_on(5) or pa_on(6) or pa_on(7) or pa_on(8) or pa_on(9) or pa_on(10) or pa_on(11) or pa_on(12) or pa_on(13) or pa_on(14) or pa_on(15);

  inst_clk_crx : cross245to491special
  port map (
    clk245      => clk_245 ,
    rst245      => sync_rst245 ,

    clk491      => clk_491 ,
    clk491v2    => clk491_v2 ,
    clk491en2   => clk491_en2
  );
  
  process(clk_245)
  begin
    if rising_edge(clk_245) then
      sync_rst245 <= rst_i;
    end if;
  end process;

  process(clk_491)
  begin
    if rising_edge(clk_491) then
      tor_path_o    <= rx_path_s(3 downto 0);      -- 245.76Msps
      sync_rst491 <= rst_i;
    end if;
  end process;
  
  
  inst_dpd : dpd_v50
  generic map (PROC_CLKF => 100000000, PATH_NUM_DEF => 2, PHASE => 1)
  port map(
    ----------------------------------------------------------------------------
    -- global reset and clock
    rst245      => sync_rst245,
    rst491      => sync_rst491,

    clk245      => clk_245,
    clk491      => clk_491,
    en2s        => '1', -- '1' for 6468, clk491_en2 for 2208

    ----------------------------------------------------------------------------
    -- radio software config
    aum_clk     => BRAM_1_clk,
    aum_rst     => BRAM_1_rst,
    aum_addr    => BRAM_1_addr_i(13 downto 2),
    aum_din     => BRAM_1_din_i,
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
    xi      => dpd_data0_i_i,    -- 491M
    xq      => dpd_data0_q_i,    -- 491M

    -- output IQ signal
    yi0     => pd_out_i0,
    yq0     => pd_out_q0,

    yi1     => open,
    yq1     => open,

    rxi         => tor_din0_i,
    rxq         => tor_din0_q,

    -- Log(N)*bit selector for Tor
    rx_path     => rx_path_s,
    looped      => looped,

    -- DPD status monitor output
    bk_gain     => open,
    status      => open
  );

  dpd_data0_i_o <= pd_out_i0;
  dpd_data0_q_o <= pd_out_q0;


end bh;

