library ieee;
use ieee.std_logic_1164.all;

entity togbit is 
  port (
    -- port 1
    clk     : in std_logic := '0';
    
    d       : in std_logic := '0';
    q       : out std_logic := '0'
  );
end entity togbit;

architecture bh of togbit is
  signal stat   : std_logic := '0';
begin

  -- lock input data
  process(clk)
  begin
    if rising_edge(clk) then
      if d = '1' then
        stat <= not stat;
      end if;
    end if;
  end process;
  
  q <= stat;
end bh;