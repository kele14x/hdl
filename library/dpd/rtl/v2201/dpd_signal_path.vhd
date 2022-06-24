library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- USE IEEE.STD_LOGIC_ARITH.ALL;

entity dpd_signal_path is 
  generic (PATH_NUM : integer := 0; PATH_BITN : integer := 0);
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
    clk245  : in std_logic;     -- 245.76MHz
    clk491    : in std_logic;     -- 491.52MHz
    en2s    : in std_logic;
    
    -- input signal
    axi         : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    axq         : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    bxi         : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    bxq         : in std_logic_vector( 16*PATH_NUM-1 downto 0 );
    chnseq      : in std_logic_vector( PATH_NUM-1 downto 0 );
    iq_valid    : in std_logic_vector( PATH_NUM-1 downto 0 );
    
    -- output IQ signal
    yi          : out std_logic_vector(2*PATH_NUM*16 - 1 downto 0);
    yq          : out std_logic_vector(2*PATH_NUM*16 - 1 downto 0);
    
    -- VCA gain
    vca_gain    : in std_logic_vector(2*PATH_NUM*16 - 1 downto 0);

    -- special table control
    s5_en       : in std_logic;
    s5_sop      : in std_logic;
    s5_eop      : in std_logic;
    s5_nxt      : in std_logic;

    ----------------------------------------------------------------------------
    -- [245.76MHz], signal for dpd_upd
    asrci       : out std_logic_vector( 15 downto 0 );
    asrcq       : out std_logic_vector( 15 downto 0 );
    bsrci       : out std_logic_vector( 15 downto 0 );
    bsrcq       : out std_logic_vector( 15 downto 0 );
    
    -- [245.76MHz], signal for dpd_upd
    pdout_ai     : out std_logic_vector( 15 downto 0 );
    pdout_aq     : out std_logic_vector( 15 downto 0 );
    pdout_bi     : out std_logic_vector( 15 downto 0 );
    pdout_bq     : out std_logic_vector( 15 downto 0 );

    tag         : out std_logic_vector(31 downto 0)
  );
end entity dpd_signal_path;

architecture bh of dpd_signal_path is

  component pd_path_2x is
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
    
    -- to capture, 245.76Msps, [0,0,1,1,2,2, ...]
    pdout_ai     : out std_logic_vector( 16-1 downto 0 );
    pdout_aq     : out std_logic_vector( 16-1 downto 0 );
    pdout_bi     : out std_logic_vector( 16-1 downto 0 );
    pdout_bq     : out std_logic_vector( 16-1 downto 0 );

    -- check this tag
    tag         : out std_logic_vector( 32-1 downto 0 )
  );
  end component pd_path_2x;

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
  signal short_addr_2pd : std_logic_vector( 11 downto 0 );
  signal short_din_2pd  : std_logic_vector( 31 downto 0 );
  signal short_we_2pd   : std_logic;
    
  ------------------------------------------------------------------------------
  -------------------------- pd_path related -----------------------------------
  -- pre-distortion LUT read & write
  type ARRAY00 is array(PATH_NUM-1 downto 0) of std_logic_vector(0  downto 0);
  type ARRAY08 is array(PATH_NUM-1 downto 0) of std_logic_vector(8  downto 0);
  type ARRAY31 is array(PATH_NUM-1 downto 0) of std_logic_vector(31 downto 0);
  type ARRAY15 is array(PATH_NUM-1 downto 0) of std_logic_vector(15 downto 0);
  type ARRAY16 is array(PATH_NUM-1 downto 0) of std_logic_vector(16 downto 0);
  type ARRAY19 is array(PATH_NUM-1 downto 0) of std_logic_vector(19 downto 0);

  -- IQ signal
  signal pd_path_axi_in     : ARRAY15;
  signal pd_path_axq_in     : ARRAY15;
  signal pd_path_bxi_in     : ARRAY15;
  signal pd_path_bxq_in     : ARRAY15;
  
  signal pd_path_yi0_out    : ARRAY15;
  signal pd_path_yq0_out    : ARRAY15;
  signal pd_path_yi1_out    : ARRAY15;
  signal pd_path_yq1_out    : ARRAY15;
  
  signal pd_path_asrci_out  : ARRAY15;
  signal pd_path_asrcq_out  : ARRAY15;
  signal pd_path_bsrci_out  : ARRAY15;
  signal pd_path_bsrcq_out  : ARRAY15;
  
  signal pd_path_pdout_ai_out  : ARRAY15;
  signal pd_path_pdout_aq_out  : ARRAY15;
  signal pd_path_pdout_bi_out  : ARRAY15;
  signal pd_path_pdout_bq_out  : ARRAY15;

  signal pd_path_tags       : ARRAY31;

  -- vca gain
  signal pd_path_vcagain0   : ARRAY15;
  signal pd_path_vcagain1   : ARRAY15;

  -- source A&B select
  signal srcsel_int_clk245  : integer range 0 to PATH_NUM-1;
  signal srcsel_sync245     : std_logic_vector(7 downto 0);
  signal srcsel_sync491     : std_logic_vector(7 downto 0);

  signal asrci_sp2          : ARRAY15;
  signal asrcq_sp2          : ARRAY15;
  signal bsrci_sp2          : ARRAY15;
  signal bsrcq_sp2          : ARRAY15;
  
  signal pdout_ai_sp2          : ARRAY15;
  signal pdout_aq_sp2          : ARRAY15;
  signal pdout_bi_sp2          : ARRAY15;
  signal pdout_bq_sp2          : ARRAY15;



  attribute max_fanout : integer;
  --attribute mark_debug : string ;
  --attribute mark_debug of   en2s         : signal is "true" ;
  
  --attribute max_fanout of chnsel_int_iclk : signal is 8;
  --attribute max_fanout of chnsel_int_pclk : signal is 8;
  
begin
  ------------------------------------------------------------------------------
  -- pre-distortion clock and reset
  pd_path_clk <= clk491;

  inst_async0 : async_reg_def
  port map(
    clk     => pd_path_clk ,
    regin   => rst ,
    regout  => pd_path_rst
  );

  inst_async1 : async_regs_def
  port map(
    clk     => clk245,
    regin   => srcsel,
    regout  => srcsel_sync245
  );

  inst_async2 : async_regs_def
  port map(
    clk     => clk491,
    regin   => srcsel,
    regout  => srcsel_sync491
  );
  
  inst_short : async_per_in
  generic map (STAGE => 3)
  port map(
    -- port 1
    clk1    => per_clk,
    rst1    => per_rst,
    addr1   => short_per_addr,
    wrdata1 => short_per_din,
    wren1   => short_per_we,
    rden1   => '0',

    -- port 2
    clk2    => clk491,
    rst2    => pd_path_rst,
    addr2   => short_addr_2pd,
    wrdata2 => short_din_2pd,
    wren2   => short_we_2pd,
    rden2   => open
  );

  ------------------------------------------------------------------------------
  -- generate all TX --
  tag <= pd_path_tags(0);
  
  PD_PATH_GENERATE : for i in 0 to PATH_NUM-1 generate
    pd_path_axi_in(i) <= axi(i*16 + 15 downto i*16 + 0);
    pd_path_axq_in(i) <= axq(i*16 + 15 downto i*16 + 0);
    pd_path_bxi_in(i) <= bxi(i*16 + 15 downto i*16 + 0);
    pd_path_bxq_in(i) <= bxq(i*16 + 15 downto i*16 + 0);
    
    pd_path_vcagain0(i) <= vca_gain(i*32 + 15 downto i*32 + 0);
    pd_path_vcagain1(i) <= vca_gain(i*32 + 31 downto i*32 + 16);

    inst_pd : pd_path_2x
    port map (
      -- per_bus, directly to LUT RAM, raw clock
      per_addr    => per_addr,
      per_din     => per_din,
      per_we(0)   => per_we,
      per_clk(0)  => per_clk,

      srcsel      => srcsel_sync491,
      chnsel      => chnsel,
      this_tx     => conv_std_logic_vector(i*2, 8),

      -- 491MHz clock
      short_per_addr  => short_addr_2pd,
      short_per_din   => short_din_2pd,
      short_per_we(0) => short_we_2pd,

      -- signal 491.52MHz clock
      clk         => pd_path_clk,
      rstp(0)     => pd_path_rst,

      axi         => pd_path_axi_in(i),
      axq         => pd_path_axq_in(i),
      bxi         => pd_path_bxi_in(i),
      bxq         => pd_path_bxq_in(i),
      chnseq(0)   => chnseq(i),
      iq_valid(0) => iq_valid(i),
    
      yi0         => pd_path_yi0_out(i),
      yi1         => pd_path_yi1_out(i),
      yq0         => pd_path_yq0_out(i),
      yq1         => pd_path_yq1_out(i),
    
      -- special table control
      s5_en(0)    => s5_en ,
      s5_eop(0)   => s5_eop ,
      s5_nxt(0)   => s5_nxt ,
      s5_sop(0)   => s5_sop ,
    
      -- external controlled VCA gain
      vca_gain0   => pd_path_vcagain0(i),
      vca_gain1   => pd_path_vcagain1(i),

      -- to capture, 245.76Msps, [0,0,1,1,2,2, ...]
      asrci       => pd_path_asrci_out(i),
      asrcq       => pd_path_asrcq_out(i),
      bsrci       => pd_path_bsrci_out(i),
      bsrcq       => pd_path_bsrcq_out(i),
      srcval      => open,
      -- to capture, 245.76Msps, [0,0,1,1,2,2, ...]
      pdout_ai       => pd_path_pdout_ai_out(i),
      pdout_aq       => pd_path_pdout_aq_out(i),
      pdout_bi       => pd_path_pdout_bi_out(i),
      pdout_bq       => pd_path_pdout_bq_out(i),
      
      -- check this tag
      tag         => pd_path_tags(i)
    );

    yi(i*32 + 15 downto i*32 +  0) <= pd_path_yi0_out(i);
    yq(i*32 + 15 downto i*32 +  0) <= pd_path_yq0_out(i);
    yi(i*32 + 31 downto i*32 + 16) <= pd_path_yi1_out(i);
    yq(i*32 + 31 downto i*32 + 16) <= pd_path_yq1_out(i);

  end generate PD_PATH_GENERATE;

  -- aligned to 245MHz clock
  process(clk491)
  begin
    if rising_edge(clk491) then
      if en2s = '1' then
        asrci_sp2 <= pd_path_asrci_out;
        asrcq_sp2 <= pd_path_asrcq_out;
        bsrci_sp2 <= pd_path_bsrci_out;
        bsrcq_sp2 <= pd_path_bsrcq_out;
        
        pdout_ai_sp2 <= pd_path_pdout_ai_out;
        pdout_aq_sp2 <= pd_path_pdout_aq_out;
        pdout_bi_sp2 <= pd_path_pdout_bi_out;
        pdout_bq_sp2 <= pd_path_pdout_bq_out;
        
      end if;      
    end if;
  end process;

  -- source select
  process(clk245)
  begin
    if rising_edge(clk245) then
      srcsel_int_clk245 <= conv_integer(srcsel_sync245(PATH_BITN downto 1));

      asrci <= asrci_sp2(srcsel_int_clk245);
      asrcq <= asrcq_sp2(srcsel_int_clk245);
      bsrci <= bsrci_sp2(srcsel_int_clk245);
      bsrcq <= bsrcq_sp2(srcsel_int_clk245);
      
      pdout_ai <= pdout_ai_sp2(srcsel_int_clk245);
      pdout_aq <= pdout_aq_sp2(srcsel_int_clk245);
      pdout_bi <= pdout_bi_sp2(srcsel_int_clk245);
      pdout_bq <= pdout_bq_sp2(srcsel_int_clk245);
    end if;
  end process;

end bh;
