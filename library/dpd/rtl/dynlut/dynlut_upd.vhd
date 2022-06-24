library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.conv_pkg.all;
use work.dpd_v50_def.all;
use work.per_regs_def.all;

entity dynlut_upd is
  generic (USED : integer := 1; MAXDELAY : integer := 1);
  port (
    clk     : in std_logic;
    
    txi0    : in std_logic_vector(15 downto 0);
    txq0    : in std_logic_vector(15 downto 0);
    txi1    : in std_logic_vector(15 downto 0);
    txq1    : in std_logic_vector(15 downto 0);

    rxi     : in std_logic_vector(15 downto 0);
    rxq     : in std_logic_vector(15 downto 0);
    
    iir_addr: in std_logic_vector( 7 downto 0);
    txval   : in std_logic;

    -- per short on same clock with signal
    ishort_addr : in std_logic_vector(11 downto 0);
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;

    -- configuration per_bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;
    
    full_addr   : in std_logic_vector(19 downto 0);
    full_rden   : in std_logic;
    full_dout   : out std_logic_vector(31 downto 0)    
  );
end entity dynlut_upd;

architecture bh of dynlut_upd is
  constant RESBIT   : integer := 12;
  
  component dynramdelay is
  generic (MAXDELAY : integer := 1);
  port (
    clk     : in std_logic;
    dn      : in std_logic_vector(15 downto 0);
    
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);
    
    yi      : in std_logic_vector(15 downto 0);
    yq      : in std_logic_vector(15 downto 0)
  );
  end component dynramdelay;

  component xilinx_ram32d is
  generic (WIDTH       : integer := 1);     -- data width
  port (
    -- port1, read
    clk     : in std_logic := '0';

    rdaddr  : in std_logic_vector(4 downto 0);
    rddata  : out std_logic_vector(WIDTH-1 downto 0);
    
    wraddr  : in std_logic_vector(4 downto 0);
    wrdata  : in std_logic_vector(WIDTH-1 downto 0);
    wren    : in std_logic
  );
  end component xilinx_ram32d;

  component delay5tap is
  port (
    clk     : in std_logic;
    q       : out std_logic_vector(15 downto 0);
    
    d0      : in std_logic_vector(15 downto 0);
    d1      : in std_logic_vector(15 downto 0);
    d2      : in std_logic_vector(15 downto 0);
    d3      : in std_logic_vector(15 downto 0);
    d4      : in std_logic_vector(15 downto 0);

    c0      : in std_logic_vector(15 downto 0);
    c1      : in std_logic_vector(15 downto 0);
    c2      : in std_logic_vector(15 downto 0);
    c3      : in std_logic_vector(15 downto 0);
    c4      : in std_logic_vector(15 downto 0)
  );
  end component delay5tap;

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero; on for DSPE2
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';
    cep     : in std_logic := '1';

    -- basic port
    b       : in  std_logic_vector(17 downto 0) := (others => '0');
    a       : in  std_logic_vector(24 downto 0) := (others => '0');
    d       : in  std_logic_vector(24 downto 0) := (others => '0');

    c       : in  std_logic_vector(47 downto 0) := (others => '0');
    p       : out std_logic_vector(47 downto 0);

    -- cascaded port, optional
    pcin    : in  std_logic_vector(47 downto 0) := (others => '0');
    pcout   : out std_logic_vector(47 downto 0)
  );
  end component xilinx_dsp_compact;

  component dynresram is
  port (
    clk     : in std_logic;

    wraddr  : in std_logic_vector(15 downto 0);
    wrdata  : in std_logic_vector(31 downto 0);
    wren    : in std_logic;
    
    rdaddr  : in std_logic_vector(15 downto 0);
    rddata  : out std_logic_vector(31 downto 0)
  );
  end component dynresram;

  -- static delay compensation
  signal static_dn      : std_logic_vector(15 downto 0);
  signal txi0d, txq0d   : std_logic_vector(15 downto 0);
  signal txi1d, txq1d   : std_logic_vector(15 downto 0);

  -- fractional delay comp
  signal txim0, txim1, txim2, txim3, txim4  : std_logic_vector(15 downto 0);
  signal txqm0, txqm1, txqm2, txqm3, txqm4  : std_logic_vector(15 downto 0);
  signal frac_coef0, frac_coef1, frac_coef2, frac_coef3, frac_coef4 : std_logic_vector(15 downto 0);
    
  -- fsm control
  signal fsm_start      : std_logic := '0';

  constant CYCLES       : integer := 2047;
  signal whstat         : std_logic := '0';
  signal whcnt          : integer range 0 to CYCLES := 0;
  
  signal cyclecnt       : std_logic_vector(11 downto 0) := (others => '0');
  signal cycletar       : std_logic_vector(11 downto 0) := (others => '0'); 
  
  signal corr_rst       : std_logic_vector(7 downto 0) := (others => '0'); 
  signal corr_rdy       : std_logic := '0';
  
  signal buf_wraddr     : std_logic_vector(15 downto 0) := (others => '0');
  signal tog_rdy        : std_logic := '0';
  
  signal cycleval       : std_logic := '0';
  signal buf_txval      : std_logic := '0';
  signal buf_iir        : std_logic_vector( 7 downto 0) := (others => '0');
  
  -- result of signal
  signal corr_r0, corr_r1, corr_r2, corr_r3     : std_logic_vector(31 downto 0) := (others => '0');
  signal corr_r4, corr_r5, corr_r6, corr_r7     : std_logic_vector(31 downto 0) := (others => '0');
  signal txif, txqf     : std_logic_vector(15 downto 0) := (others => '0');
  
  -- correlation & tx power & rx power
  signal dsp_a0, dsp_a1, dsp_a2, dsp_a3, dsp_a4, dsp_a5, dsp_a6, dsp_a7     : std_logic_vector(24 downto 0) := (others => '0');
  signal dsp_b0, dsp_b1, dsp_b2, dsp_b3, dsp_b4, dsp_b5, dsp_b6, dsp_b7     : std_logic_vector(17 downto 0) := (others => '0');
  signal dsp_r0, dsp_r1, dsp_r2, dsp_r3, dsp_r4, dsp_r5, dsp_r6, dsp_r7     : std_logic_vector(47 downto 0) := (others => '0');
  
  -- result to store into ram
  signal tog_rdy0       : std_logic_vector(3 downto 0) := (others => '0');
  signal reswr_en       : std_logic := '0';
  signal reswr_addr     : std_logic_vector(15 downto 0) := (others => '0');
  
  signal result_ci, result_cq, result_tx, result_rx     : std_logic_vector(31 downto 0) := (others => '0');
  signal per_rddata0, per_rddata1, per_rddata2, per_rddata3, per_rddata4    : std_logic_vector(31 downto 0) := (others => '0');
  
  -- flag: [valid] & [addr]; 0-7: iir_addr; 8: valid;
  signal new_flag       : std_logic_vector(31 downto 0) := (others => '0');
  
  -- keep registers
  attribute keep : string;
  attribute keep of corr_rst    : signal is "true";


begin

  inst_delay_comp0 : dynramdelay
  generic map(MAXDELAY => MAXDELAY)
  port map(
    clk     => clk,
    dn      => static_dn,
    
    xi      => txi0,
    xq      => txq0,

    yi      => txi0d,
    yq      => txq0d
  );

  inst_delay_comp1 : dynramdelay
  generic map(MAXDELAY => MAXDELAY)
  port map(
    clk     => clk,
    dn      => static_dn,
    
    xi      => txi1,
    xq      => txq1,
    
    yi      => txi1d,
    yq      => txq1d
  );
  
  -- 5x filter
  fraci : delay5tap
  port map(
    clk     => clk,
    q       => txif,
    
    d0      => txim0,
    d1      => txim1,
    d2      => txim2,
    d3      => txim3,
    d4      => txim4,

    c0      => frac_coef0,
    c1      => frac_coef1,
    c2      => frac_coef2,
    c3      => frac_coef3,
    c4      => frac_coef4
  );

  fracq : delay5tap
  port map(
    clk     => clk,
    q       => txqf,

    d0      => txqm0,
    d1      => txqm1,
    d2      => txqm2,
    d3      => txqm3,
    d4      => txqm4,

    c0      => frac_coef0,
    c1      => frac_coef1,
    c2      => frac_coef2,
    c3      => frac_coef3,
    c4      => frac_coef4
  );
  
  -- correlation control
  -- [0, N-1] correlation
  -- [N] result output, restart
  process(clk)
    variable cycletar2 : std_logic_vector(11 downto 0);
  begin
    if rising_edge(clk) then
      -- whole loop
      if fsm_start = '1' then
        whstat <= '1';
      elsif (whstat = '1') and (whcnt = CYCLES-1) and (cyclecnt = cycletar) then
        whstat <= '0';
      end if;
      
      if fsm_start = '1' then
        whcnt <= 0;
      elsif (whstat = '1') and (cyclecnt = cycletar) then
        whcnt <= whcnt + 1;
      end if;
      
      if (fsm_start = '1') or ( whstat='1' and cyclecnt = cycletar) then
        cyclecnt <= (others => '0');
      elsif whstat = '1' then
        cyclecnt <= cyclecnt + X"001";
      end if;
      
      if (fsm_start = '1') or ( whstat='1' and cyclecnt = cycletar) then
        cycleval <= '1';
      elsif txval = '0' then
        cycleval <= '0';
      end if;
      
      if (whstat = '1') and (cyclecnt = X"000") then
        corr_rst <= (others => '1');
      else
        corr_rst <= (others => '0');
      end if;

      if (whstat = '1') and (cyclecnt = cycletar) then
        corr_rdy <= '1';
        buf_wraddr <= conv_std_logic_vector(whcnt, 16);
        buf_txval  <= cycleval;
      else
        corr_rdy <= '0';
      end if;
      
      cycletar2 := '0' & cycletar(11 downto 1);
      if (whstat = '1') and (cyclecnt = cycletar2) then
        buf_iir <= iir_addr;
      end if;
      
      -- register the correlation result
      if corr_rdy = '1' then
        -- 0: [ti*ri], 1: [tq*rq], 2: [ti*rq], 3: [tq*ri]
        -- 4: [ti*ti], 5: [tq*tq], 6: [ri*ri], 7: [rq*rq] 
        corr_r0 <= dsp_r0(31+RESBIT downto RESBIT);
        corr_r1 <= dsp_r1(31+RESBIT downto RESBIT);
        corr_r2 <= dsp_r2(31+RESBIT downto RESBIT);
        corr_r3 <= dsp_r3(31+RESBIT downto RESBIT);

        corr_r4 <= dsp_r4(31+RESBIT downto RESBIT);
        corr_r5 <= dsp_r5(31+RESBIT downto RESBIT);
        corr_r6 <= dsp_r6(31+RESBIT downto RESBIT);
        corr_r7 <= dsp_r7(31+RESBIT downto RESBIT);
      end if;
      
      -- to the other clock
      if corr_rdy = '1' then
        tog_rdy <= not tog_rdy;
      end if;

    end if;
  end process;
  
  -- read result in another clock
  process(per_clk)
  begin
    if rising_edge(per_clk) then
      tog_rdy0(0) <= tog_rdy;
      tog_rdy0(3 downto 1) <= tog_rdy0(2 downto 0);
      
      if tog_rdy0(3) /= tog_rdy0(2) then
        reswr_en <= '1';
        reswr_addr <= buf_wraddr;
        
        result_ci <= corr_r0 + corr_r1;
        result_cq <= corr_r3 - corr_r2;
        
        result_tx <= corr_r4 + corr_r5;
        result_rx <= corr_r6 + corr_r7;
        
        new_flag <= X"0000" & "0000000" & buf_txval & buf_iir;
      else
        reswr_en <= '0';
      end if;

    end if;
  end process;
  
  -- [tx] & [rx] correlation
  dsp_a0 <= sign_extended(txif, 25);
  dsp_b0 <= sign_extended(rxi , 18);
  
  dsp_a1 <= sign_extended(txqf, 25);
  dsp_b1 <= sign_extended(rxq , 18);

  dsp_a2 <= sign_extended(txif, 25);
  dsp_b2 <= sign_extended(rxq , 18);

  dsp_a3 <= sign_extended(txqf, 25);
  dsp_b3 <= sign_extended(rxi , 18);

  dsp_a4 <= sign_extended(txif, 25);
  dsp_b4 <= sign_extended(txif, 18);

  dsp_a5 <= sign_extended(txqf, 25);
  dsp_b5 <= sign_extended(txqf, 18);

  dsp_a6 <= sign_extended(rxi , 25);
  dsp_b6 <= sign_extended(rxi , 18);

  dsp_a7 <= sign_extended(rxq , 25);
  dsp_b7 <= sign_extended(rxq , 18);

  
  store_icorr : dynresram
  port map(
    clk     => clk,

    wraddr  => reswr_addr,
    wrdata  => result_ci,
    wren    => reswr_en,
    
    rdaddr  => full_addr(15 downto 0),
    rddata  => per_rddata0
  );

  store_qcorr : dynresram
  port map(
    clk     => clk,

    wraddr  => reswr_addr,
    wrdata  => result_cq,
    wren    => reswr_en,
    
    rdaddr  => full_addr(15 downto 0),
    rddata  => per_rddata1
  );

  store_tx : dynresram
  port map(
    clk     => clk,

    wraddr  => reswr_addr,
    wrdata  => result_tx,
    wren    => reswr_en,
    
    rdaddr  => full_addr(15 downto 0),
    rddata  => per_rddata2
  );

  store_rx : dynresram
  port map(
    clk     => clk,

    wraddr  => reswr_addr,
    wrdata  => result_rx,
    wren    => reswr_en,
    
    rdaddr  => full_addr(15 downto 0),
    rddata  => per_rddata3
  );

  store_flag : dynresram
  port map(
    clk     => clk,

    wraddr  => reswr_addr,
    wrdata  => new_flag,
    wren    => reswr_en,
    
    rdaddr  => full_addr(15 downto 0),
    rddata  => per_rddata4
  );

  -- correlation DSP
  corr0 : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(0),

    -- basic port
    b       => dsp_b0,
    a       => dsp_a0,
    p       => dsp_r0
  );

  corr1 : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(1),

    -- basic port
    b       => dsp_b1,
    a       => dsp_a1,
    p       => dsp_r1
  );

  corr2 : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(2),

    -- basic port
    b       => dsp_b2,
    a       => dsp_a2,
    p       => dsp_r2
  );

  corr3 : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(3),

    -- basic port
    b       => dsp_b3,
    a       => dsp_a3,
    p       => dsp_r3
  );

  txpwri : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(4),

    -- basic port
    b       => dsp_b4,
    a       => dsp_a4,
    p       => dsp_r4
  );

  txpwrq : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(5),

    -- basic port
    b       => dsp_b5,
    a       => dsp_a5,
    p       => dsp_r5
  );

  rxpwri : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(6),

    -- basic port
    b       => dsp_b6,
    a       => dsp_a6,
    p       => dsp_r6
  );

  rxpwrq : xilinx_dsp_compact
  generic map(TYPES => 10)
  port map(
    clk     => clk,
    rstp    => corr_rst(7),

    -- basic port
    b       => dsp_b7,
    a       => dsp_a7,
    p       => dsp_r7
  );
  
  -- configuration
  process(clk)
  begin
    if rising_edge(clk) then
      if ishort_addr = ADDR_DYNLUT_DELAY and ishort_wren = '1' then
        static_dn <= ishort_din(15 downto 0);
      end if;
      
      if ishort_addr = (ADDR_DYNLUT_DLCOEF + X"000") and ishort_wren = '1' then
        frac_coef0 <= ishort_din(15 downto 0);
      end if;
      if ishort_addr = (ADDR_DYNLUT_DLCOEF + X"001") and ishort_wren = '1' then
        frac_coef1 <= ishort_din(15 downto 0);
      end if;
      if ishort_addr = (ADDR_DYNLUT_DLCOEF + X"002") and ishort_wren = '1' then
        frac_coef2 <= ishort_din(15 downto 0);
      end if;
      if ishort_addr = (ADDR_DYNLUT_DLCOEF + X"003") and ishort_wren = '1' then
        frac_coef3 <= ishort_din(15 downto 0);
      end if;
      if ishort_addr = (ADDR_DYNLUT_DLCOEF + X"004") and ishort_wren = '1' then
        frac_coef4 <= ishort_din(15 downto 0);
      end if;

      if ishort_addr = ADDR_DYNLUT_CYCLE and ishort_wren = '1' then
        cycletar <= ishort_din(11 downto 0);
      end if;


    end if;
  end process;



end bh;