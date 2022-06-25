library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity interrupt_reg is
  generic (
    PERIOD  : integer := 6;
    ID      : std_logic_vector(11 downto 0) := (others => '0')
  );
  port (
    -- only one burst write clock is allowed
    clk     : in std_logic;
    rst     : in std_logic;

    addr    : in std_logic_vector(15 downto 0);
    din     : in std_logic_vector(31 downto 0);
    we      : in std_logic;

    oint    : out std_logic
  );
end entity interrupt_reg;

architecture bh of interrupt_reg is
  signal stat       : std_logic;
  signal cnt        : integer range 0 to PERIOD + 2;
  constant ID2      : std_logic_vector(15 downto 0) := "0001" & ID;
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        stat <= '0';
      elsif stat = '0' and addr = ID2 and we = '1' and din(0) = '1' then
        stat <= '1';
      elsif stat = '1' and cnt = PERIOD then
        stat <= '0';
      end if;

      if rst = '1' then
        cnt <= 0;
      elsif stat = '1' and cnt = PERIOD then
        cnt <= 0;
      elsif stat = '1' then
        cnt <= cnt + 1;
      end if;

    end if;
  end process;

  oint <= stat;

end bh;
