library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_decompression_bfp8 is
end entity tb_decompression_bfp8;

architecture rtl of tb_decompression_bfp8 is

  signal aclk    : std_logic;
  signal aresetn : std_logic;

  signal s_defm_tdata  : std_logic_vector(63 downto 0);
  signal s_defm_tkeep  : std_logic_vector(7 downto 0);
  signal s_defm_tlast  : std_logic;
  signal s_defm_tready : std_logic;
  signal s_defm_tuser  : std_logic_vector(30 downto 0);
  signal s_defm_tvalid : std_logic;

  signal m_unpack_tdata  : std_logic_vector(63 downto 0);
  signal m_unpack_tkeep  : std_logic_vector(7 downto 0);
  signal m_unpack_tlast  : std_logic;
  signal m_unpack_tuser  : std_logic_vector(30 downto 0);
  signal m_unpack_tvalid : std_logic;

  component decompression_bfp8 is
    port (
      aclk    : in std_logic;
      aresetn : in std_logic;
      -- Data input
      s_defm_tdata  : in std_logic_vector(63 downto 0);
      s_defm_tkeep  : in std_logic_vector(7 downto 0);
      s_defm_tlast  : in std_logic;
      s_defm_tready : out std_logic;
      s_defm_tuser  : in std_logic_vector(30 downto 0);
      s_defm_tvalid : in std_logic;
      -- Data output
      m_unpack_tdata  : out std_logic_vector(63 downto 0);
      m_unpack_tkeep  : out std_logic_vector(7 downto 0);
      m_unpack_tlast  : out std_logic;
      m_unpack_tuser  : out std_logic_vector(30 downto 0);
      m_unpack_tvalid : out std_logic
    );
  end component;

  procedure send_axis_packet (
    start_prb            : in integer;
    number_prb           : in integer;
    --
    signal s_defm_tdata  : out std_logic_vector(63 downto 0);
    signal s_defm_tkeep  : out std_logic_vector(7 downto 0);
    signal s_defm_tlast  : out std_logic;
    signal s_defm_tready : in  std_logic;
    signal s_defm_tuser  : out std_logic_vector(30 downto 0);
    signal s_defm_tvalid : out std_logic
  ) is
    variable tuser  : std_logic_vector(30 downto 0) := (others => '0');
    variable nbytes : integer := 0;
    variable c      : integer := 0;
  begin

    -- Build the TUSER field
    tuser(9 downto 0)   := std_logic_vector(to_unsigned(start_prb, 10));
    tuser(17 downto 10)  := std_logic_vector(to_unsigned(number_prb, 8));
    tuser(21 downto 18) := x"1"; -- Compression type
    tuser(25 downto 22) := x"8"; -- Bitwidth
    tuser(26)           := '0'; -- RB bit
    tuser(27)           := '0'; -- Start of symbol marker
    tuser(30 downto 28) := "000"; -- Component carrier

    nbytes := number_prb * (8 + 12 * 8 * 2) / 8; -- 200 bits/RB

    -- Sync with posedge of `aclk`
    wait until (aclk'event and aclk = '1');

    -- Send `cnt` AXIS words
    while (c < nbytes) loop

      -- TDATA & TKEEP
      s_defm_tdata  <= (others => '0');
      s_defm_tkeep  <= (others => '0');
      for i in 0 to 7 loop
        s_defm_tdata(i*8+7 downto i*8) <= std_logic_vector(to_signed(-c / 8, 8));
        s_defm_tkeep(i)                <= '1';
      end loop;

      -- TLAST
      if (nbytes - c <= 8) then
        s_defm_tlast <= '1';
      else
        s_defm_tlast <= '0';
      end if;

      -- TUSER
      s_defm_tuser  <= tuser;
      if (c = 0) then
        s_defm_tuser(27) <= '1';
      end if;

      -- TVALID
      s_defm_tvalid <= '1';

      c := c + 8;
      
      loop 
        wait until (aclk'event and aclk = '1');
        -- Check if previous word in accept by slave
        if (s_defm_tready = '1') then
          exit;
        end if;
      end loop;

    end loop;

    -- Reset interface
    s_defm_tdata  <= (others => '0');
    s_defm_tkeep  <= (others => '0');
    s_defm_tlast  <= '0';
    s_defm_tuser  <= (others => '0');
    s_defm_tvalid <= '0';

  end send_axis_packet;


begin

  UUT : decompression_bfp8
  port map(
    aclk    => aclk,
    aresetn => aresetn,
    --
    s_defm_tdata  => s_defm_tdata,
    s_defm_tkeep  => s_defm_tkeep,
    s_defm_tlast  => s_defm_tlast,
    s_defm_tready => s_defm_tready,
    s_defm_tuser  => s_defm_tuser,
    s_defm_tvalid => s_defm_tvalid,
    --
    m_unpack_tdata  => m_unpack_tdata,
    m_unpack_tkeep  => m_unpack_tkeep,
    m_unpack_tlast  => m_unpack_tlast,
    m_unpack_tuser  => m_unpack_tuser,
    m_unpack_tvalid => m_unpack_tvalid
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
    s_defm_tdata  <= (others => '0');
    s_defm_tkeep  <= (others => '1');
    s_defm_tlast  <= '0';
    s_defm_tuser  <= (others => '0');
    s_defm_tvalid <= '0';
    wait until aresetn = '1';

    for i in 1 to 8 loop
      send_axis_packet(0, i, s_defm_tdata, s_defm_tkeep, s_defm_tlast, s_defm_tready, s_defm_tuser, s_defm_tvalid);
      wait for 100 ns;
    end loop;

    wait;
  end process;

end architecture;
