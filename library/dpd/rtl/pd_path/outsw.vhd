----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: Mar. 12, 2018
-- Design Name: 
-- Module Name: pd_path_v50.vhd
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity outsw is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    rst    : in std_logic := '0';

    -- IQ signal input
    xi      : in std_logic_vector(17 downto 0);
    xq      : in std_logic_vector(17 downto 0);

    -- IQ delta
    di      : in std_logic_vector(17 downto 0);
    dq      : in std_logic_vector(17 downto 0);
    
    -- IQ output, with delta & Gain
    yi      : out std_logic_vector(15 downto 0);
    yq      : out std_logic_vector(15 downto 0);

    -- control
    iq_gain     : in std_logic_vector(15 downto 0);

    srlimit     : in std_logic_vector(15 downto 0);     -- slew rate detection for I & Q
    pklimit     : in std_logic_vector(15 downto 0);     -- peak saturation for I & Q
    gainlimit   : in std_logic_vector(15 downto 0);     -- path gain limit
    
    sren        : in std_logic;
    pwren       : in std_logic;
    saten       : in std_logic;

    -- alarm & status
    shutdown    : in std_logic;
    o_alarm     : out std_logic;

    alarm_clr   : in std_logic;
    alarm_status: out std_logic_vector(31 downto 0)
  );
end outsw;

architecture bh of outsw is
  component xilinx_dsp_compact is
  generic (
    AREG        : integer := 1;     -- 1 or 2
    BREG        : integer := 1;     -- 1 or 2
    
    RND         : std_logic_vector := X"000000000000";  -- 48bit, default zero
    TYPES       : integer := 1      -- used types
  );
  port (
    clk     : in std_logic := '0';
    rstp    : in std_logic := '0';

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
  
  -- to signed signal
  signal sxi, sxq, sdi, sdq     : signed(17 downto 0);

  -- signal pipes
  signal di0, dq0   : signed(17 downto 0);
  signal di1, dq1   : signed(17 downto 0);
  
  signal xi0, xq0   : signed(17 downto 0);
  signal xi1, xq1   : signed(17 downto 0);

  -- alarm detector
  constant OFFTIME  : integer := 4915;                  -- 10us off time
  signal stat_wait  : std_logic     := '0';             -- 0:normal; 1:waiting 10us;
  signal wait_cnt   : unsigned(15 downto 0);    -- 10us counter
  signal alarm_trig : std_logic     := '0';             -- 1: trigger an alarm
  
  signal alarm_cnt  : unsigned(15 downto 0);
  signal alarm_trig0: std_logic     := '0';     -- delayed alarm trigger
  
  -- slew rate
  signal sr_di      : signed(9 downto 0);
  signal sr_dq      : signed(9 downto 0);
  signal sr_pos     : signed(9 downto 0);
  signal sr_neg     : signed(9 downto 0);
  
  signal sr_flag    : std_logic_vector(3 downto 0);
  signal sr_flag2   : std_logic_vector(3 downto 0);
  
  signal is_sr_alarm    : std_logic := '0';
  
  -- signal peak saturation
  signal pk_pos     : signed(9 downto 0);
  signal pk_neg     : signed(9 downto 0);
  
  signal pk_pos16   : signed(15 downto 0);
  signal pk_neg16   : signed(15 downto 0);
  
  signal pre_yi     : signed(9 downto 0);
  signal pre_yq     : signed(9 downto 0);
  
  signal pre_sati   : std_logic_vector(1 downto 0);
  signal pre_satq   : std_logic_vector(1 downto 0);
  
  -- signal gain limit
  signal is_pwr_alarm   : std_logic;

  -- output selection
  signal sw_isel    : std_logic_vector(2 downto 0);
  signal sw_qsel    : std_logic_vector(2 downto 0);

  signal ri, rq     : signed(15 downto 0);
  
  -- gain
  signal imul_a     : std_logic_vector(24 downto 0);
  signal imul_b     : std_logic_vector(17 downto 0);
  signal imul_p     : std_logic_vector(47 downto 0); 

  signal qmul_a     : std_logic_vector(24 downto 0);
  signal qmul_b     : std_logic_vector(17 downto 0);
  signal qmul_p     : std_logic_vector(47 downto 0);
    
begin
  sxi <= signed(xi);
  sxq <= signed(xq);
  sdi <= signed(di);
  sdq <= signed(dq);

  -- signal delay
  process(clk)
  begin
    if rising_edge(clk) then
      di0 <= sdi;
      dq0 <= sdq;
      
      di1 <= di0;
      dq1 <= dq0;
      
      xi0 <= sxi;
      xq0 <= sxq;
      
      xi1 <= xi0;
      xq1 <= xq0;
      
    end if;
  end process;

  -- sr detector
  sr_pos<= signed("00" & srlimit(15 downto 8));
  
  pk_pos16 <= pk_pos(7 downto 0) & X"00";
  pk_neg16 <= pk_neg(7 downto 0) & X"00";
  
  sr_flag2(0) <= '1' when sr_di > sr_pos else '0';
  sr_flag2(1) <= '1' when sr_di < sr_neg else '0';
  sr_flag2(2) <= '1' when sr_dq > sr_pos else '0';
  sr_flag2(3) <= '1' when sr_dq < sr_neg else '0'; 

  process(clk)
  begin
    if rising_edge(clk) then
      sr_neg <= -sr_pos;
      
      sr_di <= di0(17 downto 8) - sdi(17 downto 8);
      sr_dq <= dq0(17 downto 8) - sdq(17 downto 8);
      
      sr_flag <= sr_flag2;
      is_sr_alarm <= sr_flag(0) or sr_flag(1) or sr_flag(2) or sr_flag(3);
    end if;
  end process;

  -- peak saturation detector
  
  pk_pos <= signed("00" & pklimit(15 downto 8));
  
  process(clk)
  begin
    if rising_edge(clk) then
      pk_neg <= -pk_pos;
      
      pre_yi <= sxi(17 downto 8) + sdi(17 downto 8);
      pre_yq <= sxq(17 downto 8) + sdq(17 downto 8);
      
      if pre_yi > pk_pos then
        pre_sati(0) <= '1';
      else
        pre_sati(0) <= '0';
      end if;

      if pre_yi < pk_neg then
        pre_sati(1) <= '1';
      else
        pre_sati(1) <= '0';
      end if;
      
      if pre_yq > pk_pos then
        pre_satq(0) <= '1';
      else
        pre_satq(0) <= '0';
      end if;

      if pre_yq < pk_neg then
        pre_satq(1) <= '1';
      else
        pre_satq(1) <= '0';
      end if;
    end if;
  end process;

  -- power alarm
  is_pwr_alarm <= '0';      -- not used
  
  -- output select
  sw_isel <= shutdown & ((saten & saten) and pre_sati);
  sw_qsel <= shutdown & ((saten & saten) and pre_satq);
  o_alarm <= (alarm_trig or stat_wait);

  process(clk)
  begin
    if rising_edge(clk) then
      case sw_isel is
        when "100" | "101" | "110" | "111" =>
          ri <= xi0(15 downto 0);
        when "010" | "011" =>
          ri <= pk_neg16;
        when "001" =>
          ri <= pk_pos16;
        when others =>
          ri <= xi0(15 downto 0) + di0(15 downto 0);
      end case;

      case sw_qsel is
        when "100" | "101" | "110" | "111" =>
          rq <= xq0(15 downto 0);
        when "010" | "011" =>
          rq <= pk_neg16;
        when "001" =>
          rq <= pk_pos16;
        when others =>
          rq <= xq0(15 downto 0) + dq0(15 downto 0);
      end case;
    end if;
  end process;
  
  -- alarm detector
  alarm_trig <= (sren and is_sr_alarm) or (pwren and is_pwr_alarm);
  
  alarm_status(15 downto 0 ) <= std_logic_vector(alarm_cnt);
  alarm_status(31 downto 16) <= (others => '0');

  process(clk)
  begin
    if rising_edge(clk) then
      -- wait status, and counter
      if alarm_clr = '1' or (stat_wait = '1' and wait_cnt = OFFTIME) then
        stat_wait <= '0';
      elsif alarm_trig = '1' then
        stat_wait <= '1';
      end if;
      
      if alarm_clr = '1' or alarm_trig = '1' then
        wait_cnt <= (others => '0');
      elsif stat_wait = '1' then
        wait_cnt <= wait_cnt + 1;
      end if;
      
      -- alarm counter
      alarm_trig0 <= alarm_trig;
      
      if alarm_clr = '1' then
        alarm_cnt <= (others => '0');
      elsif alarm_trig0 = '0' and alarm_trig = '1' then
        alarm_cnt <= alarm_cnt + 1;
      end if;
      
    end if;
  end process;
  
  -- output gain
  inst_gi : xilinx_dsp_compact
  generic map(
    TYPES       => 1
  )
  port map(
    clk     => clk,

    -- basic port
    a       => imul_a ,
    b       => imul_b ,
    c       => X"000000002000" ,
    
    p       => imul_p
  );

  inst_gq : xilinx_dsp_compact
  generic map(
    TYPES       => 1
  )
  port map(
    clk     => clk,

    -- basic port
    a       => qmul_a ,
    b       => qmul_b ,
    c       => X"000000002000" ,

    p       => qmul_p
  );

  
  imul_a(15 downto 0) <= std_logic_vector(ri);
  imul_a(24 downto 16) <= (others => ri(15));
  
  qmul_a(15 downto 0) <= std_logic_vector(rq);
  qmul_a(24 downto 16) <= (others => rq(15));
 
  imul_b(15 downto 0) <= iq_gain;
  imul_b(17 downto 16) <= (others => iq_gain(15));
  
  qmul_b <= imul_b;
  
  process(clk)
  begin
    if rising_edge(clk) then
      yi <= imul_p(29 downto 14);
      yq <= qmul_p(29 downto 14);
    end if;
  end process;
  
end bh;