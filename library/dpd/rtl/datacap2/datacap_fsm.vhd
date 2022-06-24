library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.arch.all;
use work.conv_pkg.all;
use work.dpd_v50_def.all;
use work.per_regs_def.all;

entity datacap_fsm is
  generic (
    DATAPATH    : integer := 1;
    PWRSEL      : std_logic_vector(0 to 7);  -- select signal into power
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- input signal, multi-paths
    clk         : in std_logic;

    dini        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    dinq        : in std_logic_vector(16*DATAPATH - 1 downto 0);

    dinval      : in std_logic;
    ext_trig    : in std_logic;

    -- per_bus short, same clock with signal data
    ishort_addr : in std_logic_vector(11 downto 0); 
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;
    
    -- signal status
    
    -- module output
    loop_rdy    : out std_logic;
    o_cap_loops : out std_logic_vector(15 downto 0);
    o_val_loops : out std_logic_vector(15 downto 0);
    
    capram_sel  : out std_logic;
    capram_addr : out std_logic_vector(15 downto 0);
    capram_wren : out std_logic;
    
    o_pwr       : out std_logic_vector(31 downto 0)
  );
end entity datacap_fsm;

architecture bh of datacap_fsm is
  constant NUM_WIDTH    : integer := natural(log2(real(DEPTH)));
  component pipedelay is
  generic (DELAY : integer := 2);       -- DELAY > 2
  port (
    clk     : in std_logic;
    d       : in std_logic_vector;
    q       : out std_logic_vector
  );
  end component pipedelay;

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

  -- control signal
  signal reg_rst        : std_logic := '0';
  signal reg_start      : std_logic := '0';
  signal reg_trigsrc    : std_logic := '0';
  signal reg_timeout    : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_rcnt       : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_mode       : std_logic_vector( 3 downto 0) := (others => '0');
  signal reg_stop       : std_logic := '0';
  signal reg_pwrsel     : std_logic_vector( 7 downto 0) := (others => '0');
  
  -- trigger fsm signal
  signal upd0, upd1, upd2, upd3 : std_logic := '0';
  signal start0, regen0 : std_logic := '0';
  
  signal up_start       : std_logic := '0';
  signal up_intrig      : std_logic := '0';
  signal up_extrig      : std_logic := '0';
  
  signal start_edge     : std_logic := '0';
  signal sync_trig0, sync_trig  : std_logic := '0';
  
  -- one loop signal
  signal capcnt         : integer range 0 to DEPTH - 1;
  signal oneloopstat    : std_logic := '0';
  
  -- whole loop control
  signal cap_loops      : std_logic_vector(15 downto 0) := (others => '0');
  signal val_loops      : std_logic_vector(15 downto 0) := (others => '0');
  
  signal whstat         : std_logic := '0';
  signal whcnt          : std_logic_vector(23 downto 0) := (others => '0');
  signal whrdy          : std_logic := '0';
  
  signal round_rdy      : std_logic := '0';
  signal round_tval     : std_logic := '0';
  signal nval_reg       : std_logic := '0';
  
  -- ram {new} & {old}
  signal ram_ind        : std_logic := '0';
  signal cap_pwr        : std_logic_vector(31 downto 0) := (others => '0');
  signal maxp_dis       : std_logic := '0';
  
  -- signal power
  signal pwr_new        : std_logic_vector(31 downto 0) := (others => '0');
 
  type dspb_array is array(0 to DATAPATH-1) of std_logic_vector(17 downto 0);
  type dspa_array is array(0 to DATAPATH-1) of std_logic_vector(24 downto 0);
  type dspr_array is array(0 to DATAPATH-1) of std_logic_vector(47 downto 0);
  type pwr_array is array(0 to DATAPATH) of std_logic_vector(31 downto 0);
  
  signal ipwr_dsp_b     : dspb_array := (others => (others => '0'));
  signal qpwr_dsp_b     : dspb_array := (others => (others => '0'));

  signal ipwr_dsp_a     : dspa_array := (others => (others => '0'));
  signal qpwr_dsp_a     : dspa_array := (others => (others => '0'));
  
  signal ipwr_dsp_p     : dspr_array := (others => (others => '0'));
  signal qpwr_dsp_p     : dspr_array := (others => (others => '0'));

  signal pwr_result     : pwr_array := (others => (others => '0'));
  signal pwr_ores       : pwr_array := (others => (others => '0'));
 
  -- inter-connections
  signal intrig         : std_logic := '0';
  signal trig_en        : std_logic := '0';
  
begin

  ------------------------------------------------------------------------------
  -- trigger generation fsm control
  process(clk)
  begin
    if rising_edge(clk) then
      upd0 <= reg_start;
      upd1 <= intrig;
      upd2 <= ext_trig;
    end if;
  end process;
  
  up_start <= reg_start and (not upd0);
  up_intrig <= intrig and (not upd1);
  up_extrig <= ext_trig and (not upd2);
  
  process(clk)
  begin
    if rising_edge(clk) then
      start_edge <= up_start;

      if reg_rst = '1' then
        start0 <= '0';
        regen0 <= '0';
      elsif reg_trigsrc = '0' then
        start0 <= up_start;
        regen0 <= up_intrig;
      else
        start0 <= '0';
        regen0 <= up_extrig;
      end if;
    end if;
  end process;
  
  -- trigger re-generation
  sync_trig0 <= (regen0 and trig_en) or start0;
  delay0 : pipedelay
  generic map (DELAY => 6)
  port map(
    clk     => clk,
    d(0)    => sync_trig0,
    q(0)    => sync_trig
  );

  ------------------------------------------------------------------------------
  -- one loop for data capture
  intrig <= round_rdy;

  process(clk)
  begin
    if rising_edge(clk) then
      -- one loop status
      if reg_rst = '1' or capcnt = DEPTH-1 then
        oneloopstat <= '0';
      elsif sync_trig = '1' then
        oneloopstat <= '1';
      end if;

      -- one loop counter
      if reg_rst = '1' or capcnt = DEPTH-1 then
        capcnt <= 0;
      elsif oneloopstat = '1' then
        capcnt <= capcnt + 1;
      end if;
      
      -- one loop ready
      if reg_rst = '1' then
        round_rdy <= '0';
      elsif capcnt = DEPTH-1 then
        round_rdy <= '1';
      else
        round_rdy <= '0';
      end if;
      
      -- check if this round is valid
      if sync_trig = '1' then
        nval_reg <= '0';
      elsif dinval = '0' then
        nval_reg <= '1';
      end if;
      
      if reg_rst = '1' then
        round_tval <= '0';
      elsif capcnt = DEPTH-1 and nval_reg = '0' then
        round_tval <= '1';
      else
        round_tval <= '0';
      end if;

    end if;
  end process;
    
  ------------------------------------------------------------------------------
  -- whole loop control status
  trig_en <= whstat;

  process(clk)
  begin
    if rising_edge(clk) then
      -- one loop status
      if reg_rst = '1' or whcnt = reg_timeout(23 downto 0) or reg_stop = '1' then
        whstat <= '0';
      elsif start_edge = '1' then
        whstat <= '1';
      end if;
      
      if reg_rst = '1' or whcnt = reg_timeout(23 downto 0) or reg_stop = '1' then
        whcnt <= (others => '0');
      --elsif whstat = '1' then     -- changed without valid for whole loop
      elsif whstat = '1' and dinval = '1' then
        whcnt <= whcnt + X"000001";
      end if;
      
      if reg_rst = '1' then
        whrdy <= '0';
      elsif whcnt = reg_timeout(23 downto 0) or reg_stop = '1' then
        whrdy <= '1';
      end if;
      
      if reg_rst = '1' then
        cap_loops <= (others => '0');
      elsif round_rdy = '1' then
        cap_loops <= cap_loops + X"0001";
      end if;

      if reg_rst = '1' then
        val_loops <= (others => '0');
      elsif round_tval = '1' then
        val_loops <= val_loops + X"0001";
      end if;
      
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- ram {new} & {old} selection
  process(clk)
  begin
    if rising_edge(clk) then
      if reg_rst = '1' then
        cap_pwr <= (others => '0');
        ram_ind <= '0';
      elsif (pwr_new > cap_pwr or maxp_dis = '1') and round_tval = '1' then
        cap_pwr <= pwr_new;
        ram_ind <= not ram_ind;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- captured signal power
  pwrs : for k in 0 to DATAPATH - 1 generate
    ifx : if PWRSEL(k) = '1' generate

    ipwr_dsp_b(k) <= sign_extended(dini(k*16+15 downto k*16), 18);
    ipwr_dsp_a(k) <= sign_extended(dini(k*16+15 downto k*16), 25);
    
    qpwr_dsp_b(k) <= sign_extended(dinq(k*16+15 downto k*16), 18);
    qpwr_dsp_a(k) <= sign_extended(dinq(k*16+15 downto k*16), 25);

    idsp : xilinx_dsp_compact
    generic map(
      TYPES       => 10
    )
    port map(
      clk     => clk,
      rstp    => sync_trig,
      cep     => oneloopstat,

      -- basic port
      b       => ipwr_dsp_b(k),
      a       => ipwr_dsp_a(k),
      p       => ipwr_dsp_p(k)
    );

    qdsp : xilinx_dsp_compact
    generic map(
      TYPES       => 10
    )
    port map(
      clk     => clk,
      rstp    => sync_trig,
      cep     => oneloopstat,

      -- basic port
      b       => qpwr_dsp_b(k),
      a       => qpwr_dsp_a(k),
      p       => qpwr_dsp_p(k)
    );

    process(clk)
    begin
      if rising_edge(clk) then
        if reg_pwrsel(k) = '1' then
          pwr_result(k) <= ipwr_dsp_p(k)(31 + NUM_WIDTH downto 0 + NUM_WIDTH) + qpwr_dsp_p(k)(31 + NUM_WIDTH downto 0 + NUM_WIDTH);
        else
          pwr_result(k) <= (others => '0');
        end if;

        pwr_ores(k+1) <= pwr_ores(k) + pwr_result(k);
      end if;
    end process;
    end generate;
    
    ifn : if PWRSEL(k) = '0' generate
      pwr_ores(k+1) <= pwr_ores(k);
    end generate;
    
  end generate;
  
  pwr_new <= pwr_ores(DATAPATH);

  -- this module output is:
  loop_rdy    <= whrdy;
  o_cap_loops <= cap_loops;
  o_val_loops <= val_loops;
    
  capram_sel  <= ram_ind;
  capram_addr <= conv_std_logic_vector(capcnt, 16);
  capram_wren <= oneloopstat;
    
  o_pwr       <= cap_pwr;

  -- register configuration
  process(clk)
  begin
    if rising_edge(clk) then

      if ishort_addr = ADDR_DATACAP_RST and ishort_wren = '1' then
        reg_rst <= ishort_din(1);
      end if;

      if ishort_addr = ADDR_DATACAP_START and ishort_wren = '1' then
        reg_start <= ishort_din(2);
      end if;

      if ishort_addr = ADDR_DATACAP_TRIGSRC and ishort_wren = '1' then
        reg_trigsrc <= ishort_din(0);
      end if;

      if ishort_addr = ADDR_DATACAP_TIMEOUT and ishort_wren = '1' then
        reg_timeout <= ishort_din;
      end if;

      if ishort_addr = ADDR_DATACAP_RCNT  and ishort_wren = '1' then
        reg_rcnt <= ishort_din;
      end if;

      if ishort_addr = ADDR_DATACAP_MODE and ishort_wren = '1' then
        reg_mode <= ishort_din(7 downto 4);
      end if;

      if ishort_addr = ADDR_DATACAP_PSEL and ishort_wren = '1' then
        reg_pwrsel <= ishort_din(15 downto 8);
      end if;
      
      if ishort_addr = ADDR_DATACAP_STOP and ishort_wren = '1' then
        reg_stop <= ishort_din(3);
      end if;

    end if;
  end process;


end bh;

