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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.arch.all;
use work.pd_path_def.all;
use work.dpd_v50_def.all;
use work.per_regs_def.all;

entity pd_path_v50 is
  generic (
    PHASE   : integer := 1
  );
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';
    
    rst    : in std_logic := '0';

    -- IQ signal input
    tddsel  : in std_logic_vector(2 downto 0);  -- tdd LUT sel, "111" disabled

    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    -- IQ signal output, signal goes as [IQ0, IQ1, ...]
    yi0     : out std_logic_vector(15 downto 0);
    yq0     : out std_logic_vector(15 downto 0);

    yi1     : out std_logic_vector(15 downto 0);
    yq1     : out std_logic_vector(15 downto 0);

    -- external path gain, after PD output
    path_gain   : std_logic_vector(15 downto 0);

    -- monitor status
    status      : out std_logic_vector(31 downto 0);

    -- observed IQ signal output
    srci        : out std_logic_vector(15 downto 0);
    srcq        : out std_logic_vector(15 downto 0);

    -- per_bus clock domains ------------------------
    per_clk     : in std_logic;
    per_rst     : in std_logic;
    
    -- per_bus short
    ishort_addr : in std_logic_vector(11 downto 0);
    ishort_din  : in std_logic_vector(31 downto 0);
    ishort_wren : in std_logic;
    
    chnsel      : in std_logic_vector(7 downto 0);
    chn_id      : in std_logic_vector(7 downto 0);

    -- per_bus full
    full_addr   : in std_logic_vector(19 downto 0);
    full_din    : in std_logic_vector(31 downto 0);
    full_wren   : in std_logic;
    full_rden   : in std_logic;
    full_dout   : out std_logic_vector(31 downto 0)
  );
end pd_path_v50;

architecture bh of pd_path_v50 is

  component gmp_model is
  port (
    -- clock
    clk         : in std_logic := '0';

    -- per_bus, LUT access
    per_clk     : in std_logic;
    per_addr    : in std_logic_vector(19 downto 0);
    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;

    per_rden    : in std_logic;
    per_rdval   : out std_logic;
    per_rddata  : out std_logic_vector(31 downto 0);

    -- signal input
    xi0     : in std_logic_vector(15 downto 0);
    xq0     : in std_logic_vector(15 downto 0);
    addr0   : in std_logic_vector(9 downto 0);

    xi1     : in std_logic_vector(15 downto 0);
    xq1     : in std_logic_vector(15 downto 0);
    addr1   : in std_logic_vector(9 downto 0);

    ramsel  : in std_logic;
    tddsel  : in std_logic_vector(2 downto 0);
    tapsel  : in std_logic_vector(31 downto 0);

    -- signal output
    si      : out std_logic_vector(15 downto 0);
    sq      : out std_logic_vector(15 downto 0);

    di      : out std_logic_vector(17 downto 0);
    dq      : out std_logic_vector(17 downto 0)
  );
  end component gmp_model;

  component input_up2 is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    -- signal input
    x       : in std_logic_vector(15 downto 0);

    -- signal output, signal goes as [y0, y1, ...]
    y0      : out std_logic_vector(15 downto 0);
    y1      : out std_logic_vector(15 downto 0)
  );
  end component input_up2;
  
  component abs_map is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    -- signal input
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    -- scaling, default 1024
    gscale  : in std_logic_vector(15 downto 0);

    -- mapped addres
    addr    : out std_logic_vector(15 downto 0)
  );
  end component abs_map;

  component addr_map is
  port (
    -- clock & enable
    clk    : in std_logic := '0';
    ce     : in std_logic := '0';

    -- signal input
    xi      : in std_logic_vector(15 downto 0);
    xq      : in std_logic_vector(15 downto 0);

    -- scaling, default 1024
    gscale  : in std_logic_vector(15 downto 0);

    -- mapped addres
    addr    : out std_logic_vector(15 downto 0)
  );
  end component addr_map;
  
  component outsw is
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
  end component outsw;

  -- input sampling
  signal xi0, xi1       : std_logic_vector(15 downto 0);
  signal xq0, xq1       : std_logic_vector(15 downto 0);

  -- address mapping
  signal gscale         : std_logic_vector(15 downto 0) := (others => '0');
  signal amp0, amp1     : std_logic_vector(15 downto 0);
  signal addr0, addr1   : std_logic_vector(9 downto 0) := (others => '0');
  signal tapsel         : std_logic_vector(31 downto 0) := (others => '0');
  
  -- polyphase distribute
  signal p0xi0, p0xi1   : std_logic_vector(15 downto 0);
  signal p0xq0, p0xq1   : std_logic_vector(15 downto 0);
  
  signal p1xi0, p1xi1   : std_logic_vector(15 downto 0);
  signal p1xq0, p1xq1   : std_logic_vector(15 downto 0);
  
  signal p0addr0, p0addr1   : std_logic_vector(9 downto 0);
  signal p1addr0, p1addr1   : std_logic_vector(9 downto 0);
  
  signal si0, sq0       : std_logic_vector(17 downto 0);
  signal di0, dq0       : std_logic_vector(17 downto 0);

  signal si1, sq1       : std_logic_vector(17 downto 0);
  signal di1, dq1       : std_logic_vector(17 downto 0);

  -- output
  signal ri0, rq0       : std_logic_vector(15 downto 0) := (others => '0');
  signal ri1, rq1       : std_logic_vector(15 downto 0) := (others => '0');

  -- alarm configuration
  signal iq_gain        : std_logic_vector(15 downto 0);

  signal srlimit        : std_logic_vector(15 downto 0) := (others => '0');
  signal pklimit        : std_logic_vector(15 downto 0) := (others => '0');
  signal gainlimit      : std_logic_vector(15 downto 0) := (others => '0');
  
  signal sren, pwren    : std_logic;
  signal shutdown       : std_logic;
  signal alarm_clr      : std_logic;
  signal pdon           : std_logic := '0';
  signal saten          : std_logic := '0';
  
  signal alarms         : std_logic_vector(1 downto 0);
  signal alarm_status   : std_logic_vector(31 downto 0);
  
  -- per_bus configurations
  signal reg_ramsel     : std_logic := '0';

  -- register per_bus
  signal short_addr : std_logic_vector(11 downto 0);
  signal short_din  : std_logic_vector(31 downto 0);
  signal short_wren : std_logic;

  -- timing optimization
  attribute keep : string;
  attribute keep of short_addr : signal is "true";
  attribute keep of short_din  : signal is "true";
  attribute keep of short_wren : signal is "true";
  
  attribute max_fanout : integer;

  -- debug
  component writeres is
  generic (NAME : string; WIDTH : integer := 2; FROM : integer := 0; LEN : integer := 0);
  port (
    clk     : in std_logic;
    data    : in std_logic_vector(WIDTH-1 downto 0)
  );
  end component writeres;
  
begin

  ------------------------------------------------------------------------------
  -- input sampling
  inst_up2i : input_up2
  port map(
    -- clock & enable
    clk    => clk,
    ce     => '1',

    -- signal input
    x       => xi,

    -- signal output, signal goes as [y0, y1, ...]
    y0      => xi0, 
    y1      => xi1
  );

  inst_up2q : input_up2
  port map(
    -- clock & enable
    clk    => clk,
    ce     => '1',

    -- signal input
    x       => xq,

    -- signal output, signal goes as [y0, y1, ...]
    y0      => xq0, 
    y1      => xq1
  );

  ------------------------------------------------------------------------------
  -- address mapping
  inst_amp0 : addr_map
  port map(
    -- clock & enable
    clk    => clk,
    ce     => '1',

    -- signal input
    xi      => xi0,
    xq      => xq0,

    -- scaling, default 1024
    gscale  => gscale,

    -- mapped addres
    addr    => amp0
  );

  inst_amp1 : addr_map
  port map(
    -- clock & enable
    clk    => clk,
    ce     => '1',

    -- signal input
    xi      => xi1,
    xq      => xq1,

    -- scaling, default 1024
    gscale  => gscale,

    -- mapped addres
    addr    => amp1
  );

  addr0 <= amp0(9 downto 0);
  addr1 <= amp1(9 downto 0);

  ------------------------------------------------------------------------------
  -- poly phase GMP modeling, 1 sample delay for each phase

  process(clk)
  begin
    if rising_edge(clk) then
      p0xi0 <= xi0;
      p0xi1 <= xi1;
      
      p0xq0 <= xq0;
      p0xq1 <= xq1;
      
      p0addr0 <= addr0;
      p0addr1 <= addr1;
    end if;
  end process;
  
  p1xi0 <= p0xi1;
  p1xi1 <= xi0;
  
  p1xq0 <= p0xq1;
  p1xq1 <= xq0;
  
  p1addr0 <= p0addr1;
  p1addr1 <= addr0;
  
  -- debug, simulation GMP
  -- shutdown <= '0'; -- pdon and (not alarms(0)) and (not alarms(1));

  shutdown <= (not pdon) or alarms(0) or alarms(1);

  -- first phase
  inst_gmp0 : gmp_model
  port map(
    -- clock
    clk         => clk,

    -- per_bus, LUT access
    per_clk     => per_clk,
    per_addr    => full_addr,
    per_wrdata  => full_din,
    per_wren    => full_wren,

    per_rden    => full_rden,
    per_rdval   => open,
    per_rddata  => open,

    -- signal input
    xi0     => p0xi0,
    xq0     => p0xq0,
    addr0   => p0addr0,

    xi1     => p0xi1,
    xq1     => p0xq1,
    addr1   => p0addr1,

    ramsel  => reg_ramsel,
    tddsel  => tddsel,
    tapsel  => tapsel,
    
    -- signal output
    si      => si0(15 downto 0),
    sq      => sq0(15 downto 0),

    di      => di0,
    dq      => dq0
  );
  si0(17 downto 16) <= (others => si0(15));
  sq0(17 downto 16) <= (others => sq0(15));
  
  sw0 : outsw
  port map(
    -- clock & enable
    clk    => clk,
    rst    => rst,

    -- IQ signal input
    xi      => si0,
    xq      => sq0,

    -- IQ delta
    di      => di0,
    dq      => dq0,
    
    -- IQ output, with delta & Gain
    yi      => ri0,
    yq      => rq0,

    -- control
    iq_gain     => path_gain,

    srlimit     => srlimit,
    pklimit     => pklimit,
    gainlimit   => gainlimit,
    
    sren        => sren,
    pwren       => pwren,
    saten       => saten,

    -- alarm & status
    shutdown    => shutdown,
    o_alarm     => alarms(0),

    alarm_clr   => alarm_clr,
    alarm_status=> alarm_status
  );
  
  -- phase1
  phase1 : if PHASE > 1 generate

  inst_gmp1 : gmp_model
  port map(
    -- clock
    clk         => clk,

    -- per_bus, LUT access
    per_clk     => per_clk,
    per_addr    => full_addr,
    per_wrdata  => full_din,
    per_wren    => full_wren,

    per_rden    => full_rden,
    per_rdval   => open,
    per_rddata  => open,

    -- signal input
    xi0     => p1xi0,
    xq0     => p1xq0,
    addr0   => p1addr0,

    xi1     => p1xi1,
    xq1     => p1xq1,
    addr1   => p1addr1,

    ramsel  => reg_ramsel,
    tddsel  => tddsel,
    tapsel  => tapsel,
    
    -- signal output
    si      => si1(15 downto 0),
    sq      => sq1(15 downto 0),

    di      => di1,
    dq      => dq1
  );
  si1(17 downto 16) <= (others => si1(15));
  sq1(17 downto 16) <= (others => sq1(15));
  
  sw1 : outsw
  port map(
    -- clock & enable
    clk    => clk,
    rst    => rst,

    -- IQ signal input
    xi      => si1,
    xq      => sq1,

    -- IQ delta
    di      => di1,
    dq      => dq1,

    -- IQ output, with delta & Gain
    yi      => ri1,
    yq      => rq1,

    -- control
    iq_gain     => path_gain,

    srlimit     => srlimit,
    pklimit     => pklimit,
    gainlimit   => gainlimit,

    sren        => sren,
    pwren       => pwren,
    saten       => saten,

    -- alarm & status
    shutdown    => shutdown,
    o_alarm     => alarms(1),

    alarm_clr   => alarm_clr,
    alarm_status=> open
  );

  end generate;
  
  -- final output
  yi0 <= ri0;
  yq0 <= rq0;
  
  yi1 <= ri1;
  yq1 <= rq1;
  
  -- register configuration
  process(per_clk)
  begin
    if rising_edge(per_clk) then
      if chnsel = chn_id then
        short_addr <= ishort_addr;
        short_din <= ishort_din;
        short_wren <= ishort_wren;
      else
        short_addr <= (others => '0');
        short_din <= (others => '0');
        short_wren <= '0';
      end if;
      
      -- ADDR_RAMSEL
      if short_addr = ADDR_RAMSEL and short_wren = '1' then
        reg_ramsel <= short_din(0);
      end if;
            
      -- ADDR_GSCALE
      if short_addr = ADDR_GSCALE and short_wren = '1' then
        gscale <= short_din(15 downto 0);
      end if;
      
      -- ADDR_TAPSEL
      if short_addr = ADDR_TAPSEL and short_wren = '1' then
        tapsel <= short_din(31 downto 0);
      end if;
      
      -- ADDR_CLR
      if short_addr = ADDR_CLR and short_wren = '1' then
        alarm_clr <= short_din(0);
      end if;      
      
      -- ADDR_PDON
      if short_addr = ADDR_PDON and short_wren = '1' then
        pdon <= short_din(0);
      end if;  

      -- ADDR_ALARM_EN
      if short_addr = ADDR_ALARM_EN and short_wren = '1' then
        sren <= short_din(0);
        saten<= short_din(1);
        pwren<= short_din(2);
      end if; 

      -- ADDR_SRLIMIT
      if short_addr = ADDR_SRLIMIT and short_wren = '1' then
        srlimit <= short_din(15 downto 0);
      end if;  
 
      -- ADDR_PKLIMIT
      if short_addr = ADDR_PKLIMIT and short_wren = '1' then
        pklimit <= short_din(15 downto 0);
      end if; 

      -- ADDR_GAINLIMIT
      if short_addr = ADDR_GAINLIMIT and short_wren = '1' then
        gainlimit <= short_din(15 downto 0);
      end if; 
 
    end if;
  end process;

  -- not used
  srci   <= si0(15 downto 0);
  srcq   <= sq0(15 downto 0);
  status <= (others => '0');
  full_dout <= (others => '0');
  

  -- simulation, save result
  inst_result : if IS_SIMULATION = 1 generate  ---->

  res0 : writeres
  generic map (NAME => "../pdpath/output/xi0.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => xi0);  

  res1 : writeres
  generic map (NAME => "../pdpath/output/xq0.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => xq0);  

  res2 : writeres
  generic map (NAME => "../pdpath/output/xi1.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => xi1);  

  res3 : writeres
  generic map (NAME => "../pdpath/output/xq1.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => xq1);  

  res4 : writeres
  generic map (NAME => "../pdpath/output/amp0.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => amp0); 
    
  res5 : writeres
  generic map (NAME => "../pdpath/output/amp1.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => amp1); 

  res6 : writeres
  generic map (NAME => "../pdpath/output/yi0.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => ri0);  

  res7 : writeres
  generic map (NAME => "../pdpath/output/yq0.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => rq0);  

  res8 : writeres
  generic map (NAME => "../pdpath/output/yi1.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => ri1);  

  res9 : writeres
  generic map (NAME => "../pdpath/output/yq1.txt", WIDTH => 16, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => rq1);
  
  -- x & d
  aaa0 : writeres
  generic map (NAME => "../pdpath/output/mi0.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => si0);
  
  aaa1 : writeres
  generic map (NAME => "../pdpath/output/mq0.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => sq0);

  aaa2 : writeres
  generic map (NAME => "../pdpath/output/mi1.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => si1);
  
  aaa3 : writeres
  generic map (NAME => "../pdpath/output/mq1.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => sq1);

  aaa4 : writeres
  generic map (NAME => "../pdpath/output/di0.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => di0);
  
  aaa5 : writeres
  generic map (NAME => "../pdpath/output/dq0.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => dq0);

  aaa6 : writeres
  generic map (NAME => "../pdpath/output/di1.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => di1);
  
  aaa7 : writeres
  generic map (NAME => "../pdpath/output/dq1.txt", WIDTH => 18, FROM => SIGK, LEN => 2048)
  port map(clk => clk, data => dq1);
  
  end generate;             ---->
  
  
end bh;