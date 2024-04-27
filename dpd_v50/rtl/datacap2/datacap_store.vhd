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

entity datacap_store is
  generic (
    DATAPATH    : integer := 1;
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- input signal, multi-paths
    clk         : in std_logic;

    dini        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    dinq        : in std_logic_vector(16*DATAPATH - 1 downto 0);
    
    -- ram control
    ramsel      : in std_logic;
    capaddr     : in std_logic_vector(15 downto 0);
    capwren     : in std_logic;

    -- configuration per_bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    -- per_bus full
    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic;
    full_rden   : in std_logic;
    
    full_rdval  : out std_logic;
    full_dout   : out std_logic_vector(31 downto 0)
  );
end entity datacap_store;

architecture bh of datacap_store is
  constant NUM_WIDTH    : integer := natural(log2(real(DEPTH)));
  constant PER_RDBIT    : integer := natural(ceil(log2(real(DATAPATH))));
  constant DATAPATH2    : integer := 2**PER_RDBIT;

  component capram is
  generic (
    DEPTH       : integer := 4096   -- 4096, 8192, 16384, 32768
  );
  port (
    -- port1, fast
    clk1        : in std_logic;
    addr1       : in std_logic_vector(15 downto 0);
    din1        : in std_logic_vector(31 downto 0);
    wren1       : in std_logic;
    dout1       : out std_logic_vector(31 downto 0);

    -- port2, slow
    clk2        : in std_logic;
    addr2       : in std_logic_vector(15 downto 0);
    din2        : in std_logic_vector(31 downto 0);
    wren2       : in std_logic;
    dout2       : out std_logic_vector(31 downto 0)
  );
  end component capram;

  component pipedelay is
  generic (DELAY : integer := 2);       -- DELAY > 2
  port (
    clk     : in std_logic;
    d       : in std_logic_vector;
    q       : out std_logic_vector
  );
  end component pipedelay;
  
  type addr_group is array(0 to DATAPATH-1) of std_logic_vector(15 downto 0);
  type data_group is array(0 to DATAPATH-1) of std_logic_vector(31 downto 0);
  type data_full  is array(0 to DATAPATH2 - 1) of std_logic_vector(31 downto 0);
  
  signal capaddr_s      : addr_group := (others => (others => '0'));
  signal capdata_s      : data_group := (others => (others => '0'));
  signal capwren_s      : std_logic_vector(DATAPATH-1 downto 0);
  
  signal peraddr_s      : addr_group := (others => (others => '0'));
  signal perdin_s       : data_group := (others => (others => '0'));
  signal perwren_s      : std_logic_vector(DATAPATH-1 downto 0);
  signal perdout_s      : data_full := (others => (others => '0'));
    
  signal peraddr_d      : std_logic_vector(19 downto 0) := (others => '0');
  signal perrden_d      : std_logic;
  
begin
  
  rams : for k in 0 to DATAPATH-1 generate
  process(clk)
  begin
    if rising_edge(clk) then
      capaddr_s(k)(NUM_WIDTH-1 downto 0) <= capaddr(NUM_WIDTH-1 downto 0);
      capaddr_s(k)(NUM_WIDTH) <= ramsel;

      capwren_s(k) <= capwren;
    end if;
  end process;
  capdata_s(k) <= dinq(16*k+15 downto 16*k) & dini(16*k+15 downto 16*k);

  peraddr_s(k)(NUM_WIDTH-1 downto 0) <= full_addr(NUM_WIDTH-1 downto 0);
  peraddr_s(k)(NUM_WIDTH) <= not ramsel;
  perdin_s(k) <= full_din;

  process(full_addr, full_wren)
    variable addr_comp1     : std_logic_vector(19-NUM_WIDTH downto 0);
    variable addr_comp2     : std_logic_vector(19-NUM_WIDTH downto 0);
  begin
    addr_comp1 := full_addr(19 downto NUM_WIDTH);
    addr_comp2 := ADDR_DATA_STORE(19 downto NUM_WIDTH) + conv_std_logic_vector(k, 20-NUM_WIDTH);
    if (full_wren = '1') and (addr_comp1 = addr_comp2) then
      perwren_s(k) <= '1';
    else
      perwren_s(k) <= '0';
    end if;
  end process;
  
  one : capram
  generic map(DEPTH => 2 * DEPTH)
  port map(
    -- port1, fast
    clk1        => clk,
    addr1       => capaddr_s(k),
    din1        => capdata_s(k),
    wren1       => capwren_s(k),
    dout1       => open,

    -- port2, slow
    clk2        => per_clk,
    addr2       => peraddr_s(k),
    din2        => perdin_s(k),
    wren2       => perwren_s(k),
    dout2       => perdout_s(k)
  );
  end generate;

  -- per bus read
  adrdelay : pipedelay
  generic map(DELAY => 2)
  port map(
    clk     => per_clk,
    d       => full_addr,
    q       => peraddr_d
  );

  wrdelay : pipedelay
  generic map(DELAY => 2)
  port map(
    clk     => per_clk,
    d(0)    => full_rden,
    q(0)    => perrden_d
  );

  process(per_clk)
    variable addr_sel : std_logic_vector(PER_RDBIT-1 downto 0);
  begin
    if rising_edge(per_clk) then
      addr_sel := peraddr_d(PER_RDBIT-1 + NUM_WIDTH downto NUM_WIDTH);

      if (peraddr_d >= ADDR_DATA_STORE) and (peraddr_d < ADDR_DATA_STORE+X"20000") and perrden_d = '1' then
        full_rdval <= '1';
        full_dout <= perdout_s(conv_integer(addr_sel));
      else
        full_rdval <= '0';
        full_dout <= (others => '0');
      end if;
    end if;
  end process;

end bh;

