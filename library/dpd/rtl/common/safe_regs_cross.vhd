library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity safe_regs_cross is
  port (
    clk1    : in std_logic;
    regin   : in std_logic_vector;
    
    clk2    : in std_logic;
    regout  : out std_logic_vector
  );
end entity safe_regs_cross;

architecture bh of safe_regs_cross is
  constant WIDTH    : integer := regin'length;      --'
  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  signal cnt    : std_logic_vector(7 downto 0) := (others => '0');  
  signal reg1   : std_logic_vector(WIDTH-1 downto 0);
  signal ent1   : std_logic := '0';
  
  signal ent2   : std_logic := '0';
  signal ent2a, ent2b   : std_logic := '0';
  
begin
  
  process(clk1)
  begin
    if rising_edge(clk1) then
      cnt <= cnt + "00000001";

      if cnt = "00000001" then
        reg1 <= regin;
      end if;

      if cnt = "01100000" then
        ent1 <= not ent1;
      end if;
	end if;
  end process;  

  inst_async : async_reg_def
  port map (
    clk     => clk2 ,
    regin   => ent1 ,
    regout  => ent2
  );

  process(clk2)
  begin
    if rising_edge(clk2) then
      ent2a <= ent2;
      ent2b <= ent2a;

      if ent2a /= ent2b then
        regout <= reg1;
      end if;
	end if;
  end process;  

end bh;
