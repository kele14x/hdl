library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_compression_bfp8 is
end entity tb_compression_bfp8;

architecture rtl of tb_compression_bfp8 is

  signal aclk    : std_logic;
  signal aresetn : std_logic;

  signal s_axis_tdata  : std_logic_vector(63 downto 0);
  signal s_axis_tkeep  : std_logic_vector(7 downto 0);
  signal s_axis_tlast  : std_logic;
  signal s_axis_tready : std_logic;
  signal s_axis_tvalid : std_logic;

  signal m_axis_tdata  : std_logic_vector(63 downto 0);
  signal m_axis_tkeep  : std_logic_vector(7 downto 0);
  signal m_axis_tlast  : std_logic;
  signal m_axis_tready : std_logic;
  signal m_axis_tvalid : std_logic;

  procedure send_axis_packet (
    number_prb    : in integer;
    --
    signal tdata  : out std_logic_vector(63 downto 0);
    signal tkeep  : out std_logic_vector(7 downto 0);
    signal tlast  : out std_logic;
    signal tready : in  std_logic;
    signal tvalid : out std_logic
  ) is
  begin

    -- Sync with posedge of `aclk`
    wait until (aclk'event and aclk = '1');

    -- Send `cnt` AXIS words
    for c in 0 to number_prb * 6 - 1 loop

      -- TDATA
      tdata  <= (others => '0');
      for i in 0 to 3 loop
        tdata(i*16+15 downto i*16) <= std_logic_vector(to_signed(c * 4 + i, 16));
      end loop;

      -- TKEEP
      tkeep  <= (others => '1');
      
      -- TLAST
      if (c = number_prb * 6 - 1) then
        tlast <= '1';
      else
        tlast <= '0';
      end if;

      -- TVALID
      tvalid <= '1';

      loop 
        wait until (aclk'event and aclk = '1');
        -- Check if previous word in accept by slave
        if (tready = '1') then
          exit;
        end if;
      end loop;

    end loop;

    -- Reset interface
    tdata  <= (others => '0');
    tkeep  <= (others => '0');
    tlast  <= '0';
    tvalid <= '0';

  end send_axis_packet;


begin

  UUT : entity work.compression_bfp8(rtl)
  port map(
    aclk    => aclk,
    aresetn => aresetn,
    --
    s_axis_tdata  => s_axis_tdata,
    s_axis_tkeep  => s_axis_tkeep,
    s_axis_tlast  => s_axis_tlast,
    s_axis_tready => s_axis_tready,
    s_axis_tvalid => s_axis_tvalid,
    --
    m_axis_tdata  => m_axis_tdata,
    m_axis_tkeep  => m_axis_tkeep,
    m_axis_tlast  => m_axis_tlast,
    m_axis_tready => m_axis_tready,
    m_axis_tvalid => m_axis_tvalid
  );

  process
    constant period : time := 10 ns;
  begin
    aclk <= '0';
    loop
      wait for (period / 2);
      aclk <= not aclk;
    end loop;
  end process;

  process
  begin
    aresetn <= '0';
    wait for 100 ns;
    aresetn <= '1';
    wait;
  end process;

  process is
  begin
    s_axis_tdata  <= (others => '0');
    s_axis_tkeep  <= (others => '1');
    s_axis_tlast  <= '0';
    s_axis_tvalid <= '0';
    wait until aresetn = '1';

    for i in 1 to 8 loop
      send_axis_packet(1, s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tready, s_axis_tvalid);
      wait for 100 ns;
    end loop;

    wait;
  end process;

end architecture;
