library ieee;
use ieee.std_logic_1164.all;

entity async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
end entity async_reg_def;

architecture bh of async_reg_def is
  signal async_regto_umxjdkq        : std_logic; 
  signal reg2 : std_logic;

  -- behave as set_property ASYNC_REG TRUE
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of async_regto_umxjdkq: signal is "TRUE";
  attribute ASYNC_REG of reg2: signal is "TRUE";

begin
  
  process(clk)
  begin
    if rising_edge(clk) then
	  async_regto_umxjdkq <= regin;
	  reg2 <= async_regto_umxjdkq;
	end if;
  end process;  
  regout <= reg2;
  
end bh;
