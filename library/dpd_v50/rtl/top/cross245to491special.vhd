library ieee;
use ieee.std_logic_1164.all;

entity cross245to491special is
  port (
    clk245      : in std_logic;
    rst245      : in std_logic;

    clk491      : in std_logic;
    clk491v2    : out std_logic;
    clk491en2   : out std_logic
  );
end entity cross245to491special;

architecture bh of cross245to491special is
  -- duplicate input reset signal, in [clk245]
  signal rstdup, rstdup_t   : std_logic;

  -- reset cross to [clk491]
  signal rst2t_sepcial  : std_logic;
  signal rst2, rst3     : std_logic;

  -- shift registers
  signal shf_reg        : std_logic_vector(1 downto 0);
  signal en_s           : std_logic;
  
  attribute KEEP : string;
  attribute KEEP of rst2t_sepcial: signal is "TRUE";
  attribute KEEP of en_s: signal is "TRUE";
  attribute KEEP of rstdup: signal is "TRUE";

  --attribute max_fanout                      : integer;
  --attribute max_fanout of en_s              : signal is 200;

begin
  process(clk245)
  begin
    if rising_edge(clk245) then
      rstdup_t <= rst245;
      rstdup <= rstdup_t;
    end if;
  end process;
  
  -- reset signal from [clk245] to [clk491]
  process(clk491)
  begin
    if rising_edge(clk491) then
      rst2t_sepcial <= rstdup;
      rst3 <= rst2t_sepcial;        -- if use muticycle, replace this line by [rst2]
      rst2 <= rst3;
    end if;
  end process;

  process(clk491)
  begin
    if rising_edge(clk491) then
      if rst2 = '1' then
        shf_reg <= "01";
        clk491v2 <= '0';
        en_s <= '0';
      else
        shf_reg <= shf_reg(0) & shf_reg(1 downto 1);
        clk491v2 <= shf_reg(0);
        en_s <= shf_reg(1);
      end if;

    end if;
  end process;
  
  clk491en2 <= en_s;

end bh;
