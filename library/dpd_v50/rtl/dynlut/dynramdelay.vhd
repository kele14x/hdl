library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dynramdelay is
  generic (MAXDELAY : integer := 1);
  port (
    clk     : in std_logic;
    dn      : in std_logic_vector(15 downto 0);
    
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);
    
    yi      : out std_logic_vector(15 downto 0);
    yq      : out std_logic_vector(15 downto 0)
  );
end entity dynramdelay;

architecture bh of dynramdelay is

  -- ram selection
  function ramdepth (dn : integer) return integer is
  begin
    if dn <= 1024 then
      return 1024;
    else
      return dn;
    end if;
  end ramdepth;
  
  constant depth : integer := ramdepth(MAXDELAY);

  component xilinx_ram32b_macro is
  generic (
    DEPTH       : integer := 1024;  -- 1024, 2048, 4096, 8192, 16384, 32768

    CACHED1     : integer := 0;
    CACHED2     : integer := 0;     -- add input cached registers, 1 clock latency
                                    -- 1, 2, 4, 8, ...
                                    -- add register on every {CACHED} RAM32K

    DREG        : integer := 1      -- 0 or 1
  );
  port (
    -- port1, read
    clk1    : in std_logic := '0';
    addr1   : in std_logic_vector(15 downto 0);
    din1    : in std_logic_vector(31 downto 0);
    we1     : in std_logic;
    dout1   : out std_logic_vector(31 downto 0);

    -- port2, write
    clk2    : in std_logic := '0';
    addr2   : in std_logic_vector(15 downto 0);
    din2    : in std_logic_vector(31 downto 0);
    we2     : in std_logic;
    dout2   : out std_logic_vector(31 downto 0)
  );
  end component xilinx_ram32b_macro;

  -- static delay compensation
  signal static_dn      : std_logic_vector(15 downto 0);

  signal addr_rd        : std_logic_vector(15 downto 0) := (others => '0');
  signal data_rd        : std_logic_vector(31 downto 0):= (others => '0');
  
  signal addr_wr        : std_logic_vector(15 downto 0):= (others => '0');
  signal data_wr        : std_logic_vector(31 downto 0):= (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      yi <= data_rd(15 downto 0);
      yq <= data_rd(31 downto 16);
      
      addr_rd <= addr_rd + X"0001";
      addr_wr <= addr_rd + dn;
    end if;
  end process;
  data_wr <= xq & xi;

  ram0 : xilinx_ram32b_macro
  generic map(
    DEPTH       => depth,
    CACHED1     => 0,
    CACHED2     => 0,
    DREG        => 1
  )
  port map(
    -- port1, read
    clk1    => clk,
    addr1   => addr_rd,
    din1    => (others => '0'),
    we1     => '0',
    dout1   => data_rd,

    -- port2, write
    clk2    => clk,
    addr2   => addr_wr,
    din2    => data_wr,
    we2     => '1',
    dout2   => open
  );

end bh;