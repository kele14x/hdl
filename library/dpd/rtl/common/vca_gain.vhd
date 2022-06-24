library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vca_gain is
  generic (
    STAGE   : integer := 2;
    INIT_VAL: integer := 0;
    ID1     : std_logic_vector(11 downto 0) := (others => '0');
    ID2     : std_logic_vector(11 downto 0) := (others => '0')
  );
  port (
    -- only one burst write clock is allowed
    clk1    : in std_logic;
    rst1    : in std_logic;
    addr1   : in std_logic_vector(11 downto 0);
    din1    : in std_logic_vector(31 downto 0);
    we1     : in std_logic;
    qout1   : out std_logic_vector(15 downto 0);

    clk2    : in std_logic;
    addr2   : in std_logic_vector(11 downto 0);
    din2    : in std_logic_vector(31 downto 0);
    we2     : in std_logic;

    clk     : in std_logic;
    rst     : in std_logic;
    qout    : out std_logic_vector(15 downto 0)
  );
end entity vca_gain;

architecture bh of vca_gain is
  signal we1_tog        : std_logic := '0';
  signal we1_dst        : std_logic_vector(STAGE-1 downto 0) := (others => '0');
  signal we1_chk        : std_logic := '0';
  signal we1_real       : std_logic := '0';
  signal data1reg       : std_logic_vector(15 downto 0);

  signal we2_tog        : std_logic := '0';
  signal we2_dst        : std_logic_vector(STAGE-1 downto 0) := (others => '0');
  signal we2_chk        : std_logic := '0';
  signal we2_real       : std_logic := '0';
  signal data2reg       : std_logic_vector(15 downto 0);
  
  signal qen_flag       : std_logic_vector(2 downto 0);
  
  -- behave as set_property ASYNC_REG TRUE
  attribute ASYNC_REG : string;
  
  attribute ASYNC_REG of we1_dst: signal is "TRUE";
  attribute ASYNC_REG of we2_dst: signal is "TRUE";
  
begin
  
  process(clk1)
  begin
    if rising_edge(clk1) then
      if rst1 = '1' then
        data1reg <= conv_std_logic_vector(INIT_VAL, 16);
      elsif addr1 = ID1 and we1 = '1' then
        we1_tog <= not we1_tog;
        data1reg <= din1(15 downto 0);
      end if;
    end if;
  end process;
  qout1 <= data1reg;

  process(clk2)
  begin
    if rising_edge(clk2) then
      if addr2 = ID2 and we2 = '1' then
        we2_tog <= not we2_tog;
        data2reg <= din2(15 downto 0);
      end if;
    end if;
  end process;
  
  we1_real <= '1' when we1_chk /= we1_dst(STAGE-1) else '0';
  we2_real <= '1' when we2_chk /= we2_dst(STAGE-1) else '0';

  qen_flag <= rst & we1_real & we2_real;

  process(clk)
  begin
    if rising_edge(clk) then
      we1_dst(STAGE-1 downto 1) <= we1_dst(STAGE-2 downto 0);
      we1_dst(0) <= we1_tog;
      we1_chk <= we1_dst(STAGE-1);
      
      we2_dst(STAGE-1 downto 1) <= we2_dst(STAGE-2 downto 0);
      we2_dst(0) <= we2_tog;
      we2_chk <= we2_dst(STAGE-1);

      case qen_flag is  -- CE controled
        when "100" | "101" | "110" | "111" =>
          qout <= conv_std_logic_vector(INIT_VAL, 16);
        when "010" | "011" =>
          qout <= data1reg;
        when "001" =>
          qout <= data2reg;
        when others => 
          NULL;
      end case;

    end if;
  end process;

end bh;
