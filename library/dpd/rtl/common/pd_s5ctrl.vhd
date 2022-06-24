library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use ieee.math_real.all;


entity pd_s5ctrl is
  generic (FREQ : integer := 100000000);
  port (
    clk         : in std_logic;
    pa_on       : in std_logic_vector( 1-1 downto 0 );

    capsel      : in std_logic_vector( 3-1 downto 0 );
    captrig     : out std_logic_vector( 1-1 downto 0 );

    cap_cnt0    : in std_logic_vector( 24-1 downto 0 );
    cap_cnt1    : in std_logic_vector( 24-1 downto 0 );
    cap_cnt2    : in std_logic_vector( 24-1 downto 0 );
    cap_cnt3    : in std_logic_vector( 24-1 downto 0 );
    cap_cnt4    : in std_logic_vector( 24-1 downto 0 );

    use_cnt0    : in std_logic_vector( 24-1 downto 0 );
    use_cnt1    : in std_logic_vector( 24-1 downto 0 );
    use_cnt2    : in std_logic_vector( 24-1 downto 0 );
    use_cnt3    : in std_logic_vector( 24-1 downto 0 );
    use_cnt4    : in std_logic_vector( 24-1 downto 0 );

    eop         : out std_logic_vector( 1-1 downto 0 );
    nxt         : out std_logic_vector( 1-1 downto 0 );
    sop         : out std_logic_vector( 1-1 downto 0 )
  );
end entity pd_s5ctrl;

architecture bh of pd_s5ctrl is

  component togbit is 
  port (
    -- port 1
    clk     : in std_logic := '0';
    
    d       : in std_logic := '0';
    q       : out std_logic := '0'
  );
  end component togbit;
  
  signal paon_up, paon_down, paon_d0    : std_logic;
  
  -- a bit delay
  signal cnt_bitdelay   : integer range 0 to natural(31.0 * real(FREQ) * 0.001) := 0;
  constant DELAY_TAR    : integer := natural(0.2 * real(FREQ) * 0.001);     -- 0.2ms

  -- 10ms counter
  signal cnt10ms    : std_logic_vector(23 downto 0) := (others => '0');
  signal stat       : std_logic := '0';
  
  -- output
  signal sop_t      : std_logic := '0';
  signal eop_t      : std_logic := '0';
  signal nxt_t      : std_logic := '0';
  signal cap_t      : std_logic := '0';
  signal caps       : std_logic_vector(2 downto 0) := "000";
  
  signal use0, use1, use2, use3, use4   : std_logic := '0';
  signal cap0, cap1, cap2, cap3, cap4   : std_logic := '0';

  -- 5 sections
  signal endc       : std_logic_vector(23 downto 0) := (others => '0');
  
begin
  endc <= use_cnt4;
  
  process(clk)
  begin
    if rising_edge(clk) then
      -- input edge
      paon_d0 <= pa_on(0);
      paon_up <= pa_on(0) and (not paon_d0);
      paon_down <= (not pa_on(0)) and paon_d0;
      
      -- 0.2ms delay, down edge as [sop]
      if paon_down = '1' then
        cnt_bitdelay <= 0;
      elsif cnt_bitdelay < (DELAY_TAR + 10) then
        cnt_bitdelay <= cnt_bitdelay + 1;
      end if;
      
      if cnt_bitdelay = DELAY_TAR then
        sop_t <= '1';
      else
        sop_t <= '0';
      end if;
      
      -- 5 point
      if paon_up = '1' then
        stat <= '1';
      elsif cnt10ms = endc then
        stat <= '0';
      end if;
      
      if paon_up = '1' then
        cnt10ms <= (others => '0');
      elsif stat = '1' then
        cnt10ms <= cnt10ms + X"000001";
      end if;
      
      if cnt10ms = use_cnt0 then
        use0 <= '1';
      else
        use0 <= '0';
      end if;
      if cnt10ms = use_cnt1 then
        use1 <= '1';
      else
        use1 <= '0';
      end if;
      if cnt10ms = use_cnt2 then
        use2 <= '1';
      else
        use2 <= '0';
      end if;
      if cnt10ms = use_cnt3 then
        use3 <= '1';
      else
        use3 <= '0';
      end if;
      if cnt10ms = use_cnt4 then
        use4 <= '1';
      else
        use4 <= '0';
      end if;

      if cnt10ms = cap_cnt0 then
        cap0 <= '1';
      else
        cap0 <= '0';
      end if;
      if cnt10ms = cap_cnt1 then
        cap1 <= '1';
      else
        cap1 <= '0';
      end if;
      if cnt10ms = cap_cnt2 then
        cap2 <= '1';
      else
        cap2 <= '0';
      end if;
      if cnt10ms = cap_cnt3 then
        cap3 <= '1';
      else
        cap3 <= '0';
      end if;
      if cnt10ms = cap_cnt4 then
        cap4 <= '1';
      else
        cap4 <= '0';
      end if;
      
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      case capsel is
        when "000" => cap_t <= cap0;
        when "001" => cap_t <= cap1;
        when "010" => cap_t <= cap2;
        when "011" => cap_t <= cap3;
        when "100" => cap_t <= cap4;
        when others => cap_t <= '0';
      end case;
      
      caps(2 downto 0) <= caps(1 downto 0) & cap_t;
      captrig(0) <= cap_t or caps(0) or caps(1) or caps(2);    -- 4clocks expand
    end if;
  end process;
  

  nxt_t <= use0 or use1 or use2 or use3 or use4;

  out0 : togbit
  port map(
    clk     => clk,
    
    d       => sop_t,
    q       => sop(0)
  );

  out1 : togbit
  port map(
    clk     => clk,
    
    d       => nxt_t,
    q       => nxt(0)
  );

  eop_t <= '1' when cnt10ms = endc else '0';
  out2 : togbit
  port map(
    clk     => clk,
    
    d       => eop_t,
    q       => eop(0)
  );

end bh;