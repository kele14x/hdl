library ieee;
use ieee.std_logic_1164.all;

library work;
use work.pd_path_def.all;

entity apwr_lut is
  generic (USED : integer := 1);       -- DELAY > 2
  port (
    clk     : in std_logic;
    clr     : in std_logic;
    
    pwrin   : in std_logic_vector(31 downto 0);
    step    : in std_logic_vector(24 downto 0);
    ramsel  : in std_logic;
    
    ci      : out std_logic_vector(17 downto 0);
    cq      : out std_logic_vector(17 downto 0);
    
    iir_addr: out std_logic_vector( 7 downto 0);
    
    -- LUT per bus
    per_clk     : in std_logic;
    per_rst     : in std_logic;

    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic
  );
end entity apwr_lut;

architecture bh of apwr_lut is

  component pwr_iir is
  port (
    clk     : in std_logic;

    clr     : in std_logic;
    pwrin   : in std_logic_vector(31 downto 0);
    step    : in std_logic_vector(24 downto 0);

    iir_addr: out std_logic_vector(7 downto 0)  
  );
  end component pwr_iir;

  component lut_ram is
  generic ( LUT_ID : integer := 0 );
  port (
    -- signal
    clk     : in std_logic := '0';

    addr    : in std_logic_vector(9 downto 0);
    ci      : out std_logic_vector(17 downto 0);
    cq      : out std_logic_vector(17 downto 0);

    ramsel  : in std_logic;     -- 0&1, select active RAM

    -- per_bus
    per_clk     : in std_logic;
    per_addr    : in std_logic_vector(19 downto 0);
    per_din     : in std_logic_vector(31 downto 0);
    per_we      : in std_logic
  );
  end component lut_ram;
  
  signal addr   : std_logic_vector(7 downto 0);
  signal addr2  : std_logic_vector(9 downto 0);

begin
  
  -- existed
  ifx : if USED = 1 generate
  
  iir : pwr_iir
  port map(
    clk     => clk,

    clr     => clr,
    pwrin   => pwrin,
    step    => step,

    iir_addr=> addr
  );
  
  -- luts data
  addr2 <= "00" & addr;

  ram : lut_ram
  generic map( LUT_ID => DYNLUT_ID )
  port map(
    -- signal
    clk     => clk,

    addr    => addr2,
    ci      => ci,
    cq      => cq,

    ramsel  => ramsel,

    -- per_bus
    per_clk     => per_clk,
    per_addr    => full_addr,
    per_din     => full_din,
    per_we      => full_wren
  );
  end generate;

  -- not existed
  ifn : if USED = 0 generate
  
  ci <= (others => '0');
  cq <= (others => '0');
  
  iir_addr <= (others => '0');
  end generate;

end bh;