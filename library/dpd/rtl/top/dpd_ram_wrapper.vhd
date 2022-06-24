library ieee;
use ieee.std_logic_1164.all;


entity dpd_ram_wrapper is 
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
end entity dpd_ram_wrapper;

architecture bh of dpd_ram_wrapper is

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
  
  signal addr1a, addr2b    : std_logic_vector(15 downto 0) := (others => '0');

begin
  addr1a(11 downto 0) <= addr1;
  addr2b(11 downto 0) <= addr2;
  
  inst_ram : xilinx_ram32b_macro
  generic map(
    DEPTH       => 4096,
    CACHED1     => 0,
    CACHED2     => 0,
    DREG        => 0
  )
  port map(
    -- port1, read
    clk1    => clk1,
    addr1   => addr1a,
    din1    => wrdata1,
    we1     => wren1,
    dout1   => rddata1,

    -- port2, write
    clk2    => clk2,
    addr2   => addr2b,
    din2    => wrdata2,
    we2     => wren2,
    dout2   => rddata2
  );

end bh;
