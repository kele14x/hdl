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
    variable cnt : integer := 0;
  begin
    s_defm_tdata  <= (others => '0');
    s_defm_tkeep  <= (others => '1');
    s_defm_tlast  <= '0';
    s_defm_tuser  <= (others => '0');
    s_defm_tvalid <= '0';
    wait until aresetn = '1';

    while (cnt < 25) loop
      wait until aclk'event and aclk = '1';
      s_defm_tdata  <= x"0123456789ABCDEF";
      s_defm_tvalid <= '1';
      s_defm_tuser  <= "000" & x"ABCDEF0";
      if (cnt = 24) then
        s_defm_tlast <= '1';
      end if;
      if (s_defm_tready = '1' and s_defm_tvalid = '1') then
        cnt := cnt + 1;
      end if;
    end loop;

    wait until aclk'event and aclk = '1';
    s_defm_tdata  <= (others => '0');
    s_defm_tkeep  <= (others => '1');
    s_defm_tlast  <= '0';
    s_defm_tuser  <= (others => '0');
    s_defm_tvalid <= '0';

    wait;
  end process;

end architecture;
