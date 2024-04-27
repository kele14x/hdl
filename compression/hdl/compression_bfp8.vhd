library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.top_type_pkg.all;

library std;
  use std.textio.all;

entity compression_bfp8 is
  port (
    aclk    : in    std_logic;
    aresetn : in    std_logic;
    -- Data input
    s_axis_tdata  : in    std_logic_vector(63 downto 0);
    s_axis_tkeep  : in    std_logic_vector(7 downto 0);
    s_axis_tlast  : in    std_logic;
    s_axis_tready : out   std_logic;
    s_axis_tvalid : in    std_logic;
    -- Data output
    m_axis_tdata  : out   std_logic_vector(63 downto 0);
    m_axis_tkeep  : out   std_logic_vector(7 downto 0);
    m_axis_tlast  : out   std_logic;
    m_axis_tvalid : out   std_logic
  );
end entity compression_bfp8;

architecture rtl of compression_bfp8 is

  -- Signals

  signal comp_mantissa : std_logic_vector(31 downto 0);
  signal comp_exp      : std_logic_vector(3 downto 0);
  signal comp_valid    : std_logic;
  signal comp_last     : std_logic;

begin

  i_comp : entity work.compression_bfp8_comp
    port map (
      aclk    => aclk,
      aresetn => aresetn,
      -- Data input
      s_axis_tdata  => s_axis_tdata,
      s_axis_tkeep  => s_axis_tkeep,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tready => s_axis_tready,
      s_axis_tvalid => s_axis_tvalid,
      --
      comp_mantissa => comp_mantissa,
      comp_exp      => comp_exp,
      comp_valid    => comp_valid,
      comp_last     => comp_last
    );

  i_axis : entity work.compression_bfp8_axis
    port map (
      aclk    => aclk,
      aresetn => aresetn,
      -- Data input
      comp_mantissa => comp_mantissa,
      comp_exp      => comp_exp,
      comp_valid    => comp_valid,
      comp_last     => comp_last,
      -- Data output
      m_axis_tdata  => m_axis_tdata,
      m_axis_tkeep  => m_axis_tkeep,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid
    );

end architecture;
