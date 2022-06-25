-- Generated from Simulink block 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity pd_path_2x is
  port (
    -- per_bus, directly to LUT RAM, raw clock
    per_addr    : in std_logic_vector( 20-1 downto 0 );
    per_din     : in std_logic_vector( 32-1 downto 0 );
    per_we      : in std_logic_vector( 1-1 downto 0 );
    per_clk     : in std_logic_vector( 1-1 downto 0 );

    srcsel      : in std_logic_vector( 8-1 downto 0 );
    chnsel      : in std_logic_vector( 8-1 downto 0 );  -- maximum 256TX
    this_tx     : in std_logic_vector( 8-1 downto 0 );

    -- 491MHz clock
    short_per_addr  : in std_logic_vector( 12-1 downto 0 );
    short_per_din   : in std_logic_vector( 32-1 downto 0 );
    short_per_we    : in std_logic_vector( 1-1 downto 0 );

    -- signal 491.52MHz clock
    clk         : in std_logic;
    rstp        : in std_logic_vector( 1-1 downto 0 );

    axi         : in std_logic_vector( 16-1 downto 0 );
    axq         : in std_logic_vector( 16-1 downto 0 );
    bxi         : in std_logic_vector( 16-1 downto 0 );
    bxq         : in std_logic_vector( 16-1 downto 0 );
    chnseq      : in std_logic_vector(  1-1 downto 0 );
    iq_valid    : in std_logic_vector(  1-1 downto 0 );

    yi0         : out std_logic_vector( 16-1 downto 0 );
    yi1         : out std_logic_vector( 16-1 downto 0 );
    yq0         : out std_logic_vector( 16-1 downto 0 );
    yq1         : out std_logic_vector( 16-1 downto 0 );

    -- special table control
    s5_en       : in std_logic_vector( 1-1 downto 0 );
    s5_eop      : in std_logic_vector( 1-1 downto 0 );
    s5_nxt      : in std_logic_vector( 1-1 downto 0 );
    s5_sop      : in std_logic_vector( 1-1 downto 0 );

    -- external controlled VCA gain
    vca_gain0   : in std_logic_vector( 16-1 downto 0 );
    vca_gain1   : in std_logic_vector( 16-1 downto 0 );

    -- to capture, 245.76Msps, [0,0,1,1,2,2, ...]
    asrci       : out std_logic_vector( 16-1 downto 0 );
    asrcq       : out std_logic_vector( 16-1 downto 0 );
    bsrci       : out std_logic_vector( 16-1 downto 0 );
    bsrcq       : out std_logic_vector( 16-1 downto 0 );
    srcval      : out std_logic_vector( 1-1 downto 0 );
    
    -- to capture 245.76Msps
    pdout_ai    : out std_logic_vector( 16-1 downto 0 );
    pdout_aq    : out std_logic_vector( 16-1 downto 0 );
    pdout_bi    : out std_logic_vector( 16-1 downto 0 );
    pdout_bq    : out std_logic_vector( 16-1 downto 0 );

    -- check this tag
    tag         : out std_logic_vector( 32-1 downto 0 )
  );
end pd_path_2x;
architecture bh of pd_path_2x is 

  component pd_path_sg is
  port (
    -- per_bus, directly to LUT RAM
    full_per_addr   : in std_logic_vector( 20-1 downto 0 );
    full_per_din    : in std_logic_vector( 32-1 downto 0 );
    full_per_we     : in std_logic_vector( 1-1 downto 0 );
    per_clk         : in std_logic_vector( 1-1 downto 0 );

    -- signal 491.52MHz clock
    clk         : in std_logic;
    rstp        : in std_logic_vector( 1-1 downto 0 );

    axi         : in std_logic_vector( 16-1 downto 0 );
    axq         : in std_logic_vector( 16-1 downto 0 );
    bxi         : in std_logic_vector( 16-1 downto 0 );
    bxq         : in std_logic_vector( 16-1 downto 0 );
    chnseq      : in std_logic_vector(  1-1 downto 0 );
    iq_valid    : in std_logic_vector(  1-1 downto 0 );

    chnsel      : in std_logic_vector( 1-1 downto 0 );
    srcsel      : in std_logic_vector( 1-1 downto 0 );

    s5_en       : in std_logic_vector( 1-1 downto 0 );
    s5_eop      : in std_logic_vector( 1-1 downto 0 );
    s5_nxt      : in std_logic_vector( 1-1 downto 0 );
    s5_sop      : in std_logic_vector( 1-1 downto 0 );

    short_per_addr  : in std_logic_vector( 12-1 downto 0 );
    short_per_din   : in std_logic_vector( 32-1 downto 0 );
    short_per_we    : in std_logic_vector( 1-1 downto 0 );

    vca_gain0   : in std_logic_vector( 16-1 downto 0 );
    vca_gain1   : in std_logic_vector( 16-1 downto 0 );

    asrci       : out std_logic_vector( 16-1 downto 0 );
    asrcq       : out std_logic_vector( 16-1 downto 0 );
    bsrci       : out std_logic_vector( 16-1 downto 0 );
    bsrcq       : out std_logic_vector( 16-1 downto 0 );
    srcval      : out std_logic_vector( 1-1 downto 0 );
    
    pdout_ai    : out std_logic_vector( 16-1 downto 0 );
    pdout_aq    : out std_logic_vector( 16-1 downto 0 );
    pdout_bi    : out std_logic_vector( 16-1 downto 0 );
    pdout_bq    : out std_logic_vector( 16-1 downto 0 );

    yi0         : out std_logic_vector( 16-1 downto 0 );
    yi1         : out std_logic_vector( 16-1 downto 0 );
    yq0         : out std_logic_vector( 16-1 downto 0 );
    yq1         : out std_logic_vector( 16-1 downto 0 );

    tag         : out std_logic_vector( 32-1 downto 0 )
  );
  end component pd_path_sg;
  
  component async_regs_def is
  generic (WIDTH : integer := 0);       -- WIDTH > 1
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector(WIDTH-1 downto 0);
    regout  : out std_logic_vector(WIDTH-1 downto 0)
  );
  end component async_regs_def;
  
  -- full per_bus
  signal reg_per_addr : std_logic_vector(19 downto 0);
  signal reg_per_din  : std_logic_vector(31 downto 0);
  signal reg_per_we   : std_logic_vector( 0 downto 0);
  signal per_clk_bit  : std_logic;
  
  -- short per_bus
  signal addr0, addr    : std_logic_vector( 12-1 downto 0 );
  signal din0, din      : std_logic_vector( 32-1 downto 0 );
  signal we0, we        : std_logic_vector( 1-1 downto 0 );
  
  signal chnsel491, thistx491   : std_logic_vector(8-1 downto 0);

  attribute max_fanout : integer;
  attribute max_fanout of din : signal is 8;
  attribute max_fanout of addr : signal is 8;
  attribute max_fanout of we : signal is 8;

begin

  inst_sync0 : async_regs_def
  generic map (WIDTH => 8)
  port map(
    clk     => clk,
    regin   => chnsel,
    regout  => chnsel491
  );
  
  inst_sync1 : async_regs_def
  generic map (WIDTH => 8)
  port map(
    clk     => clk,
    regin   => this_tx,
    regout  => thistx491
  );
  
  process(clk)
  begin
    if rising_edge(clk) then
      addr0 <= short_per_addr;
      din0 <= short_per_din;
      
      if chnsel491(7 downto 1) = thistx491(7 downto 1) then
        we0 <= short_per_we;
      else
        we0 <= "0";
      end if;
    
      addr <= addr0;
      din <= din0;
      we <= we0;
    end if;
  end process;

  per_clk_bit <= per_clk(0);
  process(per_clk_bit)
  begin
    if rising_edge(per_clk_bit) then
      reg_per_addr <= per_addr;
      reg_per_din <= per_din;
      if this_tx(7 downto 1) = chnsel(7 downto 1) then
        reg_per_we <= per_we;
      else
        reg_per_we <= "0";
      end if;
    end if;
  end process;

  inst_pd_sg : pd_path_sg
  port map(
    -- per_bus, directly to LUT RAM
    full_per_addr   => reg_per_addr,
    full_per_din    => reg_per_din,
    full_per_we     => reg_per_we,
    per_clk         => per_clk,

    -- signal 491.52MHz clock
    clk         => clk,
    rstp        => rstp,

    axi         => axi,
    axq         => axq,
    bxi         => bxi,
    bxq         => bxq,
    chnseq      => chnseq,
    iq_valid    => iq_valid,

    chnsel      => chnsel491(0 downto 0),
    srcsel      => srcsel(0 downto 0),

    s5_en       => s5_en,
    s5_eop      => s5_eop,
    s5_nxt      => s5_nxt,
    s5_sop      => s5_sop,

    short_per_addr  => addr,
    short_per_din   => din,
    short_per_we    => we,

    vca_gain0   => vca_gain0,
    vca_gain1   => vca_gain1,

    asrci       => asrci,
    asrcq       => asrcq,
    bsrci       => bsrci,
    bsrcq       => bsrcq,
    srcval      => srcval,
    
    pdout_ai    => pdout_ai,
    pdout_aq    => pdout_aq,
    pdout_bi    => pdout_bi,
    pdout_bq    => pdout_bq,

    yi0         => yi0,
    yi1         => yi1,
    yq0         => yq0,
    yq1         => yq1,

    tag         => tag
  );

end bh;
