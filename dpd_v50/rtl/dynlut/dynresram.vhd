library ieee;
use ieee.std_logic_1164.all;

entity dynresram is
  port (
    clk     : in std_logic;

    wraddr  : in std_logic_vector(15 downto 0);
    wrdata  : in std_logic_vector(31 downto 0);
    wren    : in std_logic;
    
    rdaddr  : in std_logic_vector(15 downto 0);
    rddata  : out std_logic_vector(31 downto 0)
  );
end entity dynresram;

architecture bh of dynresram is

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
  
  signal rdaddr0, wraddr0   : std_logic_vector(15 downto 0) := (others => '0');

begin
  rdaddr0(10 downto 0) <= rdaddr0(10 downto 0);
  wraddr0(10 downto 0) <= wraddr0(10 downto 0);

  store : xilinx_ram32b_macro
  generic map(
    DEPTH       => 2048,
    DREG        => 1
  )
  port map(
    -- port1, read
    clk1    => clk,
    addr1   => rdaddr0,
    din1    => (others => '0'),
    we1     => '0',
    dout1   => rddata,

    -- port2, write
    clk2    => clk,
    addr2   => wraddr0,
    din2    => wrdata,
    we2     => wren,
    dout2   => open
  );

end bh;