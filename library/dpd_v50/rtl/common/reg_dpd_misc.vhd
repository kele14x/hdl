--------------------------------------------------------------------------------
-- reg_dpd_misc.vhd
-- 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.per_regs_def.all;

entity reg_dpd_misc is
  generic (CLK_FREQUENCY : integer := 100000000);
  port (
    clk     : in std_logic;
    rst     : in std_logic;
    
    -- log interrupt
    sw_int_o    : out std_logic_vector(1 downto 0);
    
    -- tx valid, with mask
    frm_start   : in std_logic;
    txval_i     : in std_logic;
    txval_o     : out std_logic;
    
    -- slot5 related signal
    pa_on       : in std_logic;
    cap_trig    : in std_logic;
    
    cap_trig_o  : out std_logic;

    s5_en       : out std_logic;
    s5_sop      : out std_logic;
    s5_eop      : out std_logic;
    s5_nxt      : out std_logic;

    -- Tags from different parts
    hw_tag      : in std_logic_vector(31 downto 0);
    tag_pd_path : in std_logic_vector(31 downto 0);
    tag_datacap : in std_logic_vector(31 downto 0);
    tag_per     : in std_logic_vector(31 downto 0);

    -- pd_path status
    pd_status   : in std_logic_vector(31 downto 0);
    pd_bkgain   : in std_logic_vector(15 downto 0);
    pa3val      : in std_logic_vector(15 downto 0);

    -- path selection
    tor_sw      : out std_logic_vector(7 downto 0);
    pd_txsel    : out std_logic_vector(7 downto 0);

    -- per bus
    per_addr    : in std_logic_vector(11 downto 0);

    per_wrdata  : in std_logic_vector(31 downto 0);
    per_wren    : in std_logic;

    per_rden    : in std_logic;
    per_rddata  : out std_logic_vector(31 downto 0) := (others=>'0');
    per_rdvalid : out std_logic := '0'
  );
end entity reg_dpd_misc;

architecture bh of reg_dpd_misc is
  constant S5DOWN_PERIOD    : integer := CLK_FREQUENCY / 1000 / 1000;      --0.05;       -- 50us = 20
  constant S5DOWN_CLK_TO    : std_logic_vector(23 downto 0) := conv_std_logic_vector(S5DOWN_PERIOD, 24);
  constant S5DOWN_CLK_EQ    : std_logic_vector(23 downto 0) := conv_std_logic_vector(S5DOWN_PERIOD - 2, 24);

  component async_reg_def is
  port (
    clk     : in std_logic;
    regin   : in std_logic;
    regout  : out std_logic
  );
  end component async_reg_def;

  component random_captrig is
  generic (CLK_FREQUENCY : integer := 150000000);
  port (
    clk         : in std_logic;
    rst         : in std_logic;

    captrig_i   : in std_logic;
    fixdelay    : in std_logic_vector(23 downto 0);
    
    -- rising_edge indicate an effective trigger
    captrig_o   : out std_logic
  );
  end component random_captrig;

  component pd_s5ctrl is
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
  end component pd_s5ctrl;

  signal txval_sync         : std_logic;
  
  -- logic clock
  signal val_timer_step     : std_logic_vector(11 downto 0);     -- 0~999
  signal val_timer_full     : std_logic_vector(31 downto 0);
  
  signal timer_high_wr_buffered, timer_low_rd_buffered  : std_logic_vector(31 downto 0);
  
  signal ful_timer_high     : std_logic_vector(31 downto 0);
  signal ful_timer_low      : std_logic_vector(31 downto 0);
  
  -- TX_valid control signal
  signal tx_valid_use, valid_frm_use, always_valid,s5_ignore_s  : std_logic;

  signal frm_cnt, frm0_start, frm0_stop, frm1_start, frm1_stop  : std_logic_vector(23 downto 0);
  
  signal frm0_valid, frm1_valid, valid_frm                      : std_logic;
  signal tx_valid_s, tx_valid_s0                                : std_logic;

  -- capture trigger delay
  signal captrig_dtime_s    : std_logic_vector(23 downto 0);
  signal cap_trig_dl_s      : std_logic;

  -- 10ms frame
  signal frm_start_sync0, frm_start_sync1   : std_logic;

  signal frm_10ms_cnt                       : std_logic_vector(23 downto 0);
  signal paon_up_en                         : std_logic_vector(1 downto 0);
  signal paon_up_edge0, paon_up_edge1       : std_logic_vector(23 downto 0);
  
  signal paon_dcnt, paon_length             : std_logic_vector(23 downto 0);
  
  -- slot5 special configuration
  signal s5_ignore_time_s           : std_logic_vector(23 downto 0);
  signal s5_ignore_cnt_s            : std_logic_vector(23 downto 0);
  signal s5_signore_ind_s           : std_logic;
  
  signal s5en_s, s5active_s         : std_logic;    
  signal s5_captrig                 : std_logic;
  signal s5_capsel                  : std_logic_vector(2 downto 0);

  signal s5_usecnt0, s5_usecnt1, s5_usecnt2, s5_usecnt3, s5_usecnt4 : std_logic_vector(23 downto 0);
  signal s5_capcnt0, s5_capcnt1, s5_capcnt2, s5_capcnt3, s5_capcnt4 : std_logic_vector(23 downto 0);

  -- PA_ON signal
  signal pa_on_s0, pa_on_s1     : std_logic;

begin

  -- synchronization
  inst_sync0 : async_reg_def
  port map (
    clk     => clk ,
    regin   => txval_i ,
    regout  => txval_sync
  );

  inst_sync1 : async_reg_def
  port map (
    clk     => clk ,
    regin   => txval_i ,
    regout  => tx_valid_s
  );
  
  inst_sync2 : async_reg_def
  port map (
    clk     => clk ,
    regin   => pa_on ,
    regout  => pa_on_s0
  );
  
  inst_sync4 : async_reg_def
  port map (
    clk     => clk ,
    regin   => frm_start ,
    regout  => frm_start_sync0
  );
  
  -- timer logic
  process(clk)
  begin
    if rising_edge(clk) then
      if per_addr = X"005" and per_wren = '1' then
        val_timer_full <= per_wrdata;
        val_timer_step <= (others => '0');
      elsif txval_sync = '1' and val_timer_step = X"3E7" then
        val_timer_full <= val_timer_full + X"00000001";
        val_timer_step <= (others => '0');
      elsif txval_sync = '1' then
        val_timer_step <= val_timer_step + X"001";
      end if;

      if per_addr = X"003" and per_wren = '1' then
        timer_high_wr_buffered <= per_wrdata;
      end if;

      if per_addr = X"004" and per_wren = '1' then
        ful_timer_high <= timer_high_wr_buffered;
        ful_timer_low  <= per_wrdata;
      else
        ful_timer_low <= ful_timer_low + X"00000001";
        if ful_timer_low = X"FFFFFFFF" then
          ful_timer_high <= ful_timer_high + X"00000001";
        end if;
      end if;

    end if;
  end process;

  -- per bus write logic
  process(clk)
  begin
    if rising_edge(clk) then

      if per_addr = X"002" and per_wren = '1' then
        tor_sw <= per_wrdata(7 downto 0);
        pd_txsel <= per_wrdata(15 downto 8);
      end if;
      
      if rst = '1' then
        sw_int_o <= "00";
      elsif per_addr = X"007" and per_wren = '1' then
        sw_int_o <= per_wrdata(1 downto 0);
      end if;

      -- valid selection
      if per_addr = X"010" and per_wren='1' then
        tx_valid_use <= per_wrdata(0);
        valid_frm_use <= per_wrdata(1);
        s5_ignore_s <= per_wrdata(2);
        always_valid  <= per_wrdata(8);
      end if;

      if per_addr = X"011" and per_wren='1' then
         frm0_start <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"012" and per_wren='1' then
         frm0_stop <= per_wrdata(23 downto 0);
      end if;

      if per_addr = X"013" and per_wren='1' then
         frm1_start <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"014" and per_wren='1' then
         frm1_stop <= per_wrdata(23 downto 0);
      end if;
      
      -- capture delay
      if per_addr = X"01A" and per_wren='1' then
         captrig_dtime_s <= per_wrdata(23 downto 0);
      end if;
            
      -- ignore time
      if per_addr = X"018" and per_wren='1' then
         s5_ignore_time_s <= per_wrdata(23 downto 0);
      end if;

      if rst = '1' then
        s5en_s <= '0';
        s5active_s <= '0';
      elsif per_addr = X"019" and per_wren='1' then
        s5en_s <= per_wrdata(0);
        s5active_s <= per_wrdata(1);
        s5_capsel <= per_wrdata(6 downto 4);
      end if;

      -- Special LUT usetime and capture delay

      if per_addr = X"020" and per_wren='1' then
         s5_usecnt0 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"021" and per_wren='1' then
         s5_usecnt1 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"022" and per_wren='1' then
         s5_usecnt2 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"023" and per_wren='1' then
         s5_usecnt3 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"024" and per_wren='1' then
         s5_usecnt4 <= per_wrdata(23 downto 0);
      end if;

      if per_addr = X"025" and per_wren='1' then
         s5_capcnt0 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"026" and per_wren='1' then
         s5_capcnt1 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"027" and per_wren='1' then
         s5_capcnt2 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"028" and per_wren='1' then
         s5_capcnt3 <= per_wrdata(23 downto 0);
      end if;
      if per_addr = X"029" and per_wren='1' then
         s5_capcnt4 <= per_wrdata(23 downto 0);
      end if;


    end if;
  end process;

    
  -- per bus read logic
  process(clk)
  begin
    if rising_edge(clk) then
      -- buffered low
      if per_rden = '1' and per_addr = X"003" then
        timer_low_rd_buffered <= ful_timer_low;
      end if;

      -- combined read out
      if per_rden = '1' then
        case per_addr is
          when X"003" =>
            per_rdvalid <= '1';
            per_rddata <= ful_timer_high;

          when X"004" =>
            per_rdvalid <= '1';
            per_rddata <= timer_low_rd_buffered;
          
          when X"005" =>
            per_rdvalid <= '1';
            per_rddata <= val_timer_full;

          when X"050" =>
            per_rdvalid <= '1';
            per_rddata <= hw_tag;

          when X"051" =>
            per_rdvalid <= '1';
            per_rddata <= tag_pd_path;

          when X"052" =>
            per_rdvalid <= '1';
            per_rddata <= tag_datacap;

          when X"053" =>
            per_rdvalid <= '1';
            per_rddata <= tag_per;

          when X"015" =>
            per_rdvalid <= '1';
            per_rddata <= X"00" & paon_up_edge0;

          when X"016" =>
            per_rdvalid <= '1';
            per_rddata <= X"00" & paon_up_edge1;   
          
          when X"017" =>
            per_rdvalid <= '1';
            per_rddata <= X"00" & paon_length;
          
          when ADDR_PA3 =>
            per_rdvalid <= '1';
            per_rddata <= X"0000" & pa3val;
            
          when others => 
            per_rdvalid <= '0';
            per_rddata <= (others => '0');
        end case;
      else
        per_rdvalid <= '0';
        per_rddata <= (others => '0');
      end if;

    end if;    
  end process;

  -- tdd up down counter
  process(clk)
  begin
    if rising_edge(clk) then
      pa_on_s1 <= pa_on_s0;
      
      -- calculate periods from PA_ON to PA_OFF
      if rst = '1' then
        paon_dcnt <= (others => '0');
        paon_length <= (others => '0');
      else
        if pa_on_s1 = '0' and pa_on_s0 = '1' then       -- up edge
          paon_dcnt <= (others => '0');
        elsif pa_on_s1 = '1' and pa_on_s0 = '0' then    -- down edge
          paon_length <= paon_dcnt;
          paon_dcnt <= (others => '0');
        else
          paon_dcnt <= paon_dcnt + X"000001";
        end if;
      end if;
    
      -- record two edges in 10ms when PA_ON
      frm_start_sync1 <= frm_start_sync0;
      
      if frm_start_sync1 = '0' and frm_start_sync0 = '1' then   -- frame start
        frm_10ms_cnt <= (others => '0');
        paon_up_en <= "01";
      else
        frm_10ms_cnt <= frm_10ms_cnt + X"000001";
        if pa_on_s1 = '0' and pa_on_s0 = '1' then     -- PA_ON up edge
          paon_up_en <= paon_up_en(0) & '0';
        end if;
      end if;
      
      -- first PA_ON edge
      if per_addr = X"015" and per_wren='1' then
        paon_up_edge0 <= per_wrdata(23 downto 0);
      elsif pa_on_s1 = '0' and pa_on_s0 = '1' and paon_up_en(0) = '1' then
        paon_up_edge0 <= frm_10ms_cnt;
      end if;

      -- second PA_ON edge
      if per_addr = X"016" and per_wren='1' then
        paon_up_edge1 <= per_wrdata(23 downto 0);
      elsif pa_on_s1 = '0' and pa_on_s0 = '1' and paon_up_en(1) = '1' then
        paon_up_edge1 <= frm_10ms_cnt;
      end if;
      
    end if;
  end process;


  -- TX valid override
  process(clk)
  begin
    if rising_edge(clk) then
      if frm_start_sync1 = '0' and frm_start_sync0 = '1' then   -- frame start
        frm_cnt <= (others => '0');
      else
        frm_cnt <= frm_cnt + X"000001";
      end if;
      
      if frm_cnt > frm0_start and frm_cnt < frm0_stop then
        frm0_valid <= '1';
      else
        frm0_valid <= '0';
      end if;

      if frm_cnt > frm1_start and frm_cnt < frm1_stop then
        frm1_valid <= '1';
      else
        frm1_valid <= '0';
      end if;
      
      valid_frm <= frm0_valid or frm1_valid;
      tx_valid_s0 <= (tx_valid_s and tx_valid_use) or (valid_frm and valid_frm_use) or always_valid;
      
      if s5active_s = '1' then
        txval_o <= tx_valid_s0;
      else
        txval_o <= tx_valid_s0 and (not s5_signore_ind_s);
      end if;

    end if;
  end process;
  

  -- capture trigger selection
  process(clk)
  begin
    if rising_edge(clk) then
      if s5active_s = '1' then
        cap_trig_o <= s5_captrig;
      else
        cap_trig_o <= cap_trig_dl_s;
      end if;

      -- ignore period after PA_ON      
      if s5_ignore_s = '0' then
        s5_signore_ind_s <= '0';
      elsif pa_on_s1 = '1' and pa_on_s0 = '0' then     -- down edge
        s5_signore_ind_s <= '1';
      elsif s5_ignore_cnt_s = s5_ignore_time_s then
        s5_signore_ind_s <= '0';
      end if;

      if pa_on_s1 = '0' and pa_on_s0 = '1' then       -- up edge
        s5_ignore_cnt_s <= (others => '0');
      else
        s5_ignore_cnt_s <= s5_ignore_cnt_s + X"000001";     -- cycle over 10ms
      end if;

    end if;
  end process;

  inst_randtrig : random_captrig
  generic map (CLK_FREQUENCY => CLK_FREQUENCY)
  port map (
    clk         => clk,
    rst         => rst,

    captrig_i   => cap_trig,
    fixdelay    => captrig_dtime_s,
    
    -- rising_edge indicate an effective trigger
    captrig_o   => cap_trig_dl_s
  );
  

  inst_s5ctrl : pd_s5ctrl
  port map (
    clk         => clk ,
    pa_on(0)    => pa_on_s0 ,

    capsel      => s5_capsel ,
    captrig(0)  => s5_captrig ,

    cap_cnt0    => s5_capcnt0 ,
    cap_cnt1    => s5_capcnt1 ,
    cap_cnt2    => s5_capcnt2 ,
    cap_cnt3    => s5_capcnt3 ,
    cap_cnt4    => s5_capcnt4 ,

    use_cnt0    => s5_usecnt0 ,
    use_cnt1    => s5_usecnt1 ,
    use_cnt2    => s5_usecnt2 ,
    use_cnt3    => s5_usecnt3 ,
    use_cnt4    => s5_usecnt4 ,

    sop(0)      => s5_sop ,
    eop(0)      => s5_eop ,
    nxt(0)      => s5_nxt
  );
  s5_en <= s5en_s;

end bh;