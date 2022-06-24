library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

-- USE IEEE.STD_LOGIC_ARITH.ALL;

entity dpd_signal_path is 
  generic (PATH_NUM : integer := 0; PHASE : integer := 0);
  port (
    -- per_bus, directly to LUT RAM, raw clock
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    per_addr    : in std_logic_vector( 19 downto 0 );
    per_din     : in std_logic_vector( 31 downto 0 );
    per_we      : in std_logic;

    short_per_addr  : in std_logic_vector( 11 downto 0 );
    short_per_din   : in std_logic_vector( 31 downto 0 );
    short_per_we    : in std_logic;

    chnsel          : in std_logic_vector( 7 downto 0 );  -- maximum 256TX
    srcsel          : in std_logic_vector( 7 downto 0 );  -- select which TX for data capture

    ----------------------------------------------------------------------------
    -- 491MHz clock
    rst     : in std_logic;
    clk     : in std_logic;
    
    -- input signal
    xi      : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    xq      : in std_logic_vector( 16*PATH_NUM-1 downto 0 );

    -- output IQ signal
    yi0     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);
    yq0     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);

    yi1     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);
    yq1     : out std_logic_vector(PATH_NUM*16 - 1 downto 0);

    -- VCA gain
    vca_gain:  in std_logic_vector(PATH_NUM*16 - 1 downto 0);

    -- special LUT control
    s5_en   : in std_logic;
    s5_sop  : in std_logic;
    s5_eop  : in std_logic;
    s5_nxt  : in std_logic;

    -- signal for dpd_upd
    srci    : out std_logic_vector( 15 downto 0 );
    srcq    : out std_logic_vector( 15 downto 0 );
    
    status  : out std_logic_vector(31 downto 0);
    tag     : out std_logic_vector(31 downto 0)
  );
end entity dpd_signal_path;

architecture bh of dpd_signal_path is
  constant PATH_BITN : integer := natural(log2(real(PATH_NUM)));
  
  component pd_path_v50 is
  generic (
    PHASE   : integer := 1
  );
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';
    
    rst    : in std_logic := '0';

    -- IQ signal input
    tddsel  : in std_logic_vector(2 downto 0);  -- tdd LUT sel, "111" disabled
    
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    -- IQ signal output, signal goes as [IQ0, IQ1, ...]
    yi0     : out std_logic_vector(15 downto 0);
    yq0     : out std_logic_vector(15 downto 0);

    yi1     : out std_logic_vector(15 downto 0);
    yq1     : out std_logic_vector(15 downto 0);

    -- external path gain, after PD output
    path_gain   : std_logic_vector(15 downto 0);

    -- monitor status
    status      : out std_logic_vector(31 downto 0);

    -- observed IQ signal output
    srci        : out std_logic_vector(15 downto 0);
    srcq        : out std_logic_vector(15 downto 0);

    -- per_bus clock domains ------------------------
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    -- per_bus short, same clock with IQ signal
    ishort_addr : in std_logic_vector(11 downto 0);
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;
    
    chnsel      : in std_logic_vector(7 downto 0);
    chn_id      : in std_logic_vector(7 downto 0);

    -- per_bus full, different clock with IQ signal
    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic;
    full_rden   : in std_logic;
    full_dout   : out std_logic_vector(31 downto 0)
  );
  end component pd_path_v50;
  
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

  component async_per_in is 
  generic (STAGE : integer := 2);   -- >=2
  port (
    -- port 1
    clk1    : in std_logic := '0';
    rst1    : in std_logic := '0';
    addr1   : in std_logic_vector;
    wrdata1 : in std_logic_vector(31 downto 0);
    wren1   : in std_logic;
    rden1   : in std_logic;

    -- port 2
    clk2  : in std_logic := '0';
    rst2  : in std_logic := '0';
    addr2   : out std_logic_vector;
    wrdata2 : out std_logic_vector(31 downto 0);
    wren2   : out std_logic;
    rden2   : out std_logic
  );
  end component async_per_in;

  ------------------------------------------------------------------------------
  -- clock & reset --
  signal pd_path_clk        : std_logic;
  signal pd_path_rst        : std_logic;

  ------------------------------------------------------------------------------
  -- per_bus inter-connect
  signal per_we2        : std_logic_vector(PATH_NUM-1 downto 0);
    
  ------------------------------------------------------------------------------
  -------------------------- pd_path related -----------------------------------
  -- pre-distortion LUT read & write
  type ARRAY00 is array(PATH_NUM-1 downto 0) of std_logic_vector(0  downto 0);
  type ARRAY08 is array(PATH_NUM-1 downto 0) of std_logic_vector(8  downto 0);
  type ARRAY31 is array(PATH_NUM-1 downto 0) of std_logic_vector(31 downto 0);
  type ARRAY15 is array(PATH_NUM-1 downto 0) of std_logic_vector(15 downto 0);
  type ARRAY19 is array(PATH_NUM-1 downto 0) of std_logic_vector(19 downto 0);

  -- IQ signal
  signal pd_path_xi_in      : ARRAY15;
  signal pd_path_xq_in      : ARRAY15;
  
  signal pd_path_yi0_out    : ARRAY15;
  signal pd_path_yq0_out    : ARRAY15;
  signal pd_path_yi1_out    : ARRAY15;
  signal pd_path_yq1_out    : ARRAY15;
  
  signal pd_path_srci_out   : ARRAY15;
  signal pd_path_srcq_out   : ARRAY15;

  -- vca gain
  signal pd_path_vcagain    : ARRAY15;

  -- source select
  signal chnsel_sync        : std_logic_vector(7 downto 0);
  signal chnsel_sync2       : std_logic_vector(7 downto 0);

  signal srcsel_sync        : std_logic_vector(7 downto 0);
  signal srcsel_sync2       : std_logic_vector(7 downto 0);
  
  -- tdd LUT selection
  signal sop1, nxt1     : std_logic;
  signal sop_detect     : std_logic;
  signal nxt_detect     : std_logic;
  
  signal cntsel, tddsel : std_logic_vector(2 downto 0);

  -- maximum 16 groups
  type ARRAYSRC is array(15 downto 0) of std_logic_vector(15 downto 0);
  type DATA32SRC is array(15 downto 0) of std_logic_vector(31 downto 0);

  signal srci_group     : ARRAYSRC;
  signal srcq_group     : ARRAYSRC;

  signal srci_group2    : ARRAYSRC;
  signal srcq_group2    : ARRAYSRC;
  
  signal pd_path_status : DATA32SRC;
  signal pd_path_status2: DATA32SRC;

  attribute max_fanout : integer;
  --attribute max_fanout of chnsel_int_iclk : signal is 8;
  --attribute max_fanout of chnsel_int_pclk : signal is 8;

  attribute max_fanout of chnsel_sync : signal is 30;
  attribute max_fanout of srcsel_sync : signal is 30;

begin
  ------------------------------------------------------------------------------
  -- pre-distortion clock and reset
  pd_path_clk <= clk;

  inst_async0 : async_reg_def
  port map(
    clk     => pd_path_clk ,
    regin   => rst ,
    regout  => pd_path_rst
  );

  inst_async1 : async_regs_def
  port map(
    clk     => pd_path_clk ,
    regin   => chnsel ,
    regout  => chnsel_sync2
  );

  inst_async2 : async_regs_def
  port map(
    clk     => pd_path_clk ,
    regin   => srcsel ,
    regout  => srcsel_sync2
  );
  
  process(pd_path_clk)
  begin
    if rising_edge(pd_path_clk) then
      chnsel_sync <= chnsel_sync2;
      srcsel_sync <= srcsel_sync2;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- generate all TX --
  tag <= (others => '0');
  PD_PATH_GENERATE : for i in 0 to PATH_NUM-1 generate
    
    pd_path_xi_in(i) <= xi(i*16 + 15 downto i*16 + 0);
    pd_path_xq_in(i) <= xq(i*16 + 15 downto i*16 + 0);

    pd_path_vcagain(i) <= vca_gain(i*16 + 15 downto i*16 + 0);
    per_we2(i) <= per_we when chnsel = conv_std_logic_vector(i, 8) else '0';

    inst_pd : pd_path_v50
    generic map(PHASE   => PHASE)
    port map(
      -- clock & enable
      clk    => pd_path_clk,
      ce     => '1',
      rst    => pd_path_rst,
    
      -- IQ signal input
      tddsel  => tddsel,
    
      xi      => pd_path_xi_in(i),
      xq      => pd_path_xq_in(i),
    
      -- IQ signal output, signal goes as [IQ0, IQ1, ...]
      yi0         => pd_path_yi0_out(i),
      yq0         => pd_path_yq0_out(i),

      yi1         => pd_path_yi1_out(i),
      yq1         => pd_path_yq1_out(i),
    
      -- external path gain, after PD output
      path_gain   => pd_path_vcagain(i),

      -- monitor status
      status      => pd_path_status(i),
    
      -- observed IQ signal output
      srci        => srci_group(i),
      srcq        => srcq_group(i),
    
      -- per_bus clock domains ------------------------
      per_clk     => per_clk,
      per_rst     => per_rst,

      -- per_bus short, same clock with IQ signal
      ishort_addr => short_per_addr,
      ishort_din  => short_per_din,
      ishort_wren => short_per_we,

      chnsel      => chnsel,
      chn_id      => conv_std_logic_vector(i, 8),
      
      -- per_bus full, different clock with IQ signal
      full_addr   => per_addr,
      full_din    => per_din,
      full_wren   => per_we2(i),
      full_rden   => '0',
      full_dout   => open
    );

    yi0(i*16 + 15 downto i*16 +  0) <= pd_path_yi0_out(i);
    yq0(i*16 + 15 downto i*16 +  0) <= pd_path_yq0_out(i);
    
    yi1(i*16 + 15 downto i*16 +  0) <= pd_path_yi1_out(i);
    yq1(i*16 + 15 downto i*16 +  0) <= pd_path_yq1_out(i);

  end generate PD_PATH_GENERATE;

  -- TDD luts control
  process(pd_path_clk)
  begin
    if rising_edge(pd_path_clk) then
      sop1 <= s5_sop;
      nxt1 <= s5_nxt;
      
      sop_detect <= sop1 xor s5_sop;
      nxt_detect <= nxt1 xor s5_nxt;
      
      if sop_detect = '1' then
        cntsel <= "000";
      elsif nxt_detect = '1' then
        cntsel <= cntsel + "001";
      end if;

      if s5_en = '1' then
        tddsel <= cntsel;
      else
        tddsel <= "111";
      end if;
    end if;
  end process;

  paded : if PATH_NUM < 16 generate
    srci_group(15 downto PATH_NUM) <= (others => (others => '0'));
    srcq_group(15 downto PATH_NUM) <= (others => (others => '0'));
  end generate;

  -- source select
  process(pd_path_clk)
  begin
    if rising_edge(pd_path_clk) then
      case srcsel_sync(1 downto 0) is
        when "00"   => 
          srci_group2(0) <= srci_group(0);
          srci_group2(1) <= srci_group(4);
          srci_group2(2) <= srci_group(8);
          srci_group2(3) <= srci_group(12);

          srcq_group2(0) <= srcq_group(0);
          srcq_group2(1) <= srcq_group(4);
          srcq_group2(2) <= srcq_group(8);
          srcq_group2(3) <= srcq_group(12);

        when "01"   => 
          srci_group2(0) <= srci_group(1);
          srci_group2(1) <= srci_group(5);
          srci_group2(2) <= srci_group(9);
          srci_group2(3) <= srci_group(13);

          srcq_group2(0) <= srcq_group(1);
          srcq_group2(1) <= srcq_group(5);
          srcq_group2(2) <= srcq_group(9);
          srcq_group2(3) <= srcq_group(13);
          
        when "10"   => 
          srci_group2(0) <= srci_group(2);
          srci_group2(1) <= srci_group(6);
          srci_group2(2) <= srci_group(10);
          srci_group2(3) <= srci_group(14);

          srcq_group2(0) <= srcq_group(2);
          srcq_group2(1) <= srcq_group(6);
          srcq_group2(2) <= srcq_group(10);
          srcq_group2(3) <= srcq_group(14);
          
        when others => 
          srci_group2(0) <= srci_group(3);
          srci_group2(1) <= srci_group(7);
          srci_group2(2) <= srci_group(11);
          srci_group2(3) <= srci_group(15);

          srcq_group2(0) <= srcq_group(3);
          srcq_group2(1) <= srcq_group(7);
          srcq_group2(2) <= srcq_group(11);
          srcq_group2(3) <= srcq_group(15);
          
      end case;

      case srcsel_sync(3 downto 2) is
        when "00"   => srci <= srci_group2(0); srcq <= srcq_group2(0);
        when "01"   => srci <= srci_group2(1); srcq <= srcq_group2(1);
        when "10"   => srci <= srci_group2(2); srcq <= srcq_group2(2);
        when others => srci <= srci_group2(3); srcq <= srcq_group2(3);
      end case;

    end if;
  end process;

  process(pd_path_clk)
  begin
    if rising_edge(pd_path_clk) then
      case chnsel_sync(1 downto 0) is
        when "00"   => 
          pd_path_status2(0) <= pd_path_status(0);
          pd_path_status2(1) <= pd_path_status(4);
          pd_path_status2(2) <= pd_path_status(8);
          pd_path_status2(3) <= pd_path_status(12);

        when "01"   => 
          pd_path_status2(0) <= pd_path_status(1);
          pd_path_status2(1) <= pd_path_status(5);
          pd_path_status2(2) <= pd_path_status(9);
          pd_path_status2(3) <= pd_path_status(13);

        when "10"   => 
          pd_path_status2(0) <= pd_path_status(2);
          pd_path_status2(1) <= pd_path_status(6);
          pd_path_status2(2) <= pd_path_status(10);
          pd_path_status2(3) <= pd_path_status(14);

        when others => 
          pd_path_status2(0) <= pd_path_status(3);
          pd_path_status2(1) <= pd_path_status(7);
          pd_path_status2(2) <= pd_path_status(11);
          pd_path_status2(3) <= pd_path_status(15);

      end case;

      case chnsel_sync(3 downto 2) is
        when "00"   => status <= pd_path_status2(0);
        when "01"   => status <= pd_path_status2(1);
        when "10"   => status <= pd_path_status2(2);
        when others => status <= pd_path_status2(3);
      end case;

    end if;
  end process;

end bh;
