library ieee;
use ieee.std_logic_1164.all;

entity async_regs_def is
  generic (WIDTH : integer := 0);       -- WIDTH > 1
  port (
    clk     : in std_logic;
    regin   : in std_logic_vector(WIDTH-1 downto 0);
    regout  : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity async_regs_def;

architecture bh of async_regs_def is
  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component;

begin
  reg_group : for i in 0 to WIDTH - 1 generate
    inst_reg : async_reg_def
    port map(
      clk     => clk ,
      regin   => regin(i) ,
      regout  => regout(i)
    );
  end generate reg_group;
  
end bh;