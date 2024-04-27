library ieee;
use ieee.std_logic_1164.all;

entity pipedelay is
  generic (DELAY : integer := 2);       -- DELAY > 2
  port (
    clk     : in std_logic;
    d       : in std_logic_vector;
    q       : out std_logic_vector
  );
end entity pipedelay;

architecture bh of pipedelay is
  constant WIDTH : integer := d'length;  --'
  
  type pipes is array(DELAY-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);
  signal delayed    : pipes := (others => (others => '0'));

begin
  inst0 : if DELAY = 1 generate
  process(clk)
  begin
    if rising_edge(clk) then
      delayed(0) <= d;
    end if;
  end process;
  end generate;

  inst1 : if DELAY > 1 generate
  process(clk)
  begin
    if rising_edge(clk) then
      delayed(DELAY-1 downto 0) <= delayed(DELAY-2 downto 0) & d;
    end if;
  end process;
  end generate;
  q <= delayed(DELAY-1);

end bh;