library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pwr_iir is
  port (
    clk     : in std_logic;

    clr     : in std_logic;
    pwrin   : in std_logic_vector(31 downto 0);
    step    : in std_logic_vector(24 downto 0);

    iir_addr: out std_logic_vector(7 downto 0)  
  );
end entity pwr_iir;

architecture bh of pwr_iir is
  constant CUTBIT   : integer := 12;
  constant STEPBIT  : integer := 24;
  constant RSTGAP   : integer := 8;

  constant AVRBIT   : integer := STEPBIT - CUTBIT;

  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2

    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero; on for DSPE2
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';
    cep     : in std_logic := '1';

    -- basic port
    b       : in  std_logic_vector(17 downto 0) := (others => '0');
    a       : in  std_logic_vector(24 downto 0) := (others => '0');
    d       : in  std_logic_vector(24 downto 0) := (others => '0');

    c       : in  std_logic_vector(47 downto 0) := (others => '0');
    p       : out std_logic_vector(47 downto 0);

    -- cascaded port, optional
    pcin    : in  std_logic_vector(47 downto 0) := (others => '0');
    pcout   : out std_logic_vector(47 downto 0)
  );
  end component xilinx_dsp_compact;

  signal pwr_avr    : std_logic_vector(31 downto 0) := (others => '0');
  signal pwr_delta  : std_logic_vector(29-CUTBIT downto 0) := (others => '0');
  
  signal clrstat    : std_logic := '0';
  signal clrcnt     : integer range 0 to RSTGAP + 1 := 0;
  signal clr_safe   : std_logic := '0';

  signal dsp_b  : std_logic_vector(17 downto 0) := (others => '0');
  signal dsp_a  : std_logic_vector(24 downto 0) := (others => '0');
  signal dsp_r  : std_logic_vector(47 downto 0) := (others => '0');
  
  -- power mapping
  type rom_cnst is array(0 to 7) of std_logic_vector(1 downto 0);
  constant rsel_cnst: rom_cnst := ("11", "10", "01", "01", "00", "00", "00", "00");
  constant COMP0    : std_logic_vector(15 downto 0) := X"0040";
  constant COMP1    : std_logic_vector(15 downto 0) := X"0200";
  constant COMP2    : std_logic_vector(15 downto 0) := X"2000";
  
  signal map_pwr0   : std_logic_vector(15 downto 0) := (others => '0');
  signal map_pwr1   : std_logic_vector(15 downto 0) := (others => '0');
  signal map_comp0, map_comp1, map_comp2    : std_logic := '0';
  signal comp_res   : std_logic_vector(2 downto 0) := (others => '0');
  signal rsel       : std_logic_vector(1 downto 0) := (others => '0');
  signal sel0, sel1, sel2       : std_logic_vector(7 downto 0) := (others => '0');

begin
  -- longer clear
  process(clk)
  begin
    if rising_edge(clk) then
      pwr_delta <= pwrin(29 downto CUTBIT) - pwr_avr(29 downto CUTBIT);

      -- longer reset
      if (clr = '1') then
        clrcnt <= 0;
      elsif clrstat = '1' then
        clrcnt <= clrcnt + 1;
      end if;

      if (clrstat = '1') and (clrcnt=RSTGAP) and (clr='0') then
        clrstat <= '0';
      elsif clr='1' then
        clrstat <= '1';
      end if;
    end if;
  end process;
  
  clr_safe <= clrstat;

  -- macc
  dsp_a <= step;
  dsp_b <= pwr_delta;
  pwr_avr <= dsp_r(31+AVRBIT downto AVRBIT);

  dsp : xilinx_dsp_compact
  generic map(
    TYPES       => 10
  )
  port map(
    clk     => clk,
    rstp    => clr_safe,

    -- basic port
    b       => dsp_b ,
    a       => dsp_a ,
    p       => dsp_r
  );

  -- mapped to 0~255
  map_pwr0 <= pwr_avr(27 downto 12);
  map_comp0 <= '1' when (map_pwr0 < COMP0) else '0';
  map_comp1 <= '1' when (map_pwr0 < COMP1) else '0';
  map_comp2 <= '1' when (map_pwr0 < COMP2) else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      comp_res <= map_comp0 & map_comp1 & map_comp2;
      rsel <= rsel_cnst(conv_integer(comp_res));
      
      map_pwr1 <= map_pwr0;
      
      sel0 <= map_pwr1(7 downto 0);
      sel1 <= map_pwr1(7+3 downto 3) + X"38";
      sel2 <= map_pwr1(7+6 downto 6) + X"70";
      
      case rsel is
        when "00" => iir_addr <= sel0;
        when "01" => iir_addr <= sel1;
        when "10" => iir_addr <= sel2;
        when others => iir_addr <= X"F0";
      end case;

    end if;
  end process;
  
  
end bh;