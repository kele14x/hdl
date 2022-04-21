library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.top_type_pkg.all;

entity compression_bfp8_comp is
  port (
    aclk    : in std_logic;
    aresetn : in std_logic;
    -- Data input
    s_axis_tdata  : in std_logic_vector(63 downto 0);
    s_axis_tkeep  : in std_logic_vector(7 downto 0);
    s_axis_tlast  : in std_logic;
    s_axis_tready : out std_logic;
    s_axis_tvalid : in std_logic;
    --
    comp_mantissa : out std_logic_vector(31 downto 0);
    comp_exp      : out std_logic_vector(3 downto 0);
    comp_valid    : out std_logic;
    comp_last     : out std_logic;
    comp_cnt      : out unsigned(5 downto 0)
  );
end compression_bfp8_comp;

architecture rtl of compression_bfp8_comp is

  constant DEBUG : integer := 1;

  constant C_DELAY_TAPS : integer := 10;

  signal tready   : std_logic;
  signal tcnt_pre : std_logic_vector(2 downto 0);

  signal tdata_d  : vector_64b_t(0 to C_DELAY_TAPS-2);
  signal tcnt_d   : vector_3b_t(0 to C_DELAY_TAPS-1);
  signal tvalid_d : std_logic_vector(0 to C_DELAY_TAPS-1);
  signal tlast_d  : std_logic_vector(0 to C_DELAY_TAPS-1);

  signal exp_0, exp_1, exp_2, exp_3, exp_mt, exp_ma, exp_pre, exp_pre_d : std_logic_vector(3 downto 0);

  -- 9-bit, extra 1-bit is used to do rounding
  signal comp_mantissa_pre_0_i : std_logic_vector(8 downto 0);
  signal comp_mantissa_pre_0_q : std_logic_vector(8 downto 0);
  signal comp_mantissa_pre_1_i : std_logic_vector(8 downto 0);
  signal comp_mantissa_pre_1_q : std_logic_vector(8 downto 0);

  -- 8-bit rounded value
  signal comp_mantissa_0_i : std_logic_vector(7 downto 0);
  signal comp_mantissa_0_q : std_logic_vector(7 downto 0);
  signal comp_mantissa_1_i : std_logic_vector(7 downto 0);
  signal comp_mantissa_1_q : std_logic_vector(7 downto 0);

  --
  signal comp_valid_r : std_logic;
  signal comp_last_r  : std_logic;
  signal comp_cnt_r   : unsigned(5 downto 0);

  -- Functions

  -- This function performs byte reverse on the input vector, as required by
  -- AXIS standard
  function byte_reverse (
    vector_in    : in std_logic_vector(63 downto 0)
  ) return std_logic_vector is
    variable ret : std_logic_vector(63 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      ret(63-i*8 downto 56-i*8) := vector_in(7+i*8 downto i*8);
    end loop;
    return ret;
  end function byte_reverse;

  -- This function cacluates number of bits until current state counter
  function total_bits (
    cnt : in unsigned(5 downto 0)
  ) return integer is
    variable ret : integer := 0;
  begin
    ret := to_integer(cnt);
    ret := (ret / 6) * 8 + ret * 32 + 40;
    return ret;
  end function total_bits;

  -- This function cacluates number of words until current state counter
  function total_words (
    cnt : in unsigned(5 downto 0)
  ) return integer is
    variable ret : integer := 0;
  begin
    ret := total_bits(cnt) / 64;
    return ret;
  end function total_words;

  -- This function check if at current state counter, we have a valid word
  -- output
  function valid_word (
    cnt : in unsigned(5 downto 0)
  ) return std_logic is
    variable lut : std_logic_vector(63 downto 0) := (others => '0');
    variable ret : std_logic := '0';
  begin
    for i in 1 to 47 loop
      if (total_words(to_unsigned(i, 6)) > total_words(to_unsigned(i - 1, 6))) then
        lut(i) := '1';
      end if;
    end loop;
    ret := lut(to_integer(cnt));
    return ret;
  end function valid_word;

  -- This function calculates how many bits left after this state
  function left_bytes (
    cnt : in unsigned(5 downto 0)
  ) return unsigned is 
    variable ret : unsigned(2 downto 0) := (others => '0');  
  begin
    ret := to_unsigned((total_bits(cnt) / 8) rem 8, 3);
    return ret;
  end function left_bytes;

begin

  -- DEBUG
  DEBUG_PRINT : if (DEBUG > 0) generate
  begin

    process is
      variable cnt : unsigned(5 downto 0);
    begin
      for c in 0 to 47 loop
        cnt := to_unsigned(c, 6);
        write(output, "cnt: " & integer'image(c));
        write(output, ", total bits: " & integer'image(total_bits(cnt)));
        write(output, ", total words: " & integer'image(total_words(cnt)));
        write(output, ", valid words: " & std_logic'image(valid_word(cnt)));
        write(output, ", left bytes: " & integer'image(to_integer(left_bytes(cnt))));
        write(output, "" & LF);
      end loop;
      wait;
    end process;

  end generate;


  -- Input AXIS

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        tready <= '0';
      elsif (tready = '1' and s_axis_tvalid = '1' and s_axis_tlast = '1') then
        tready <= '0';
      else
        tready <= '1';
      end if;
    end if;
  end process;

  s_axis_tready <= tready;


  -- Counter from 0 to 5, as one RB
  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      -- First tap
      if (aresetn = '0') then
        tcnt_pre <= (others => '0');
      elsif (tready = '1' and s_axis_tvalid = '1' and (s_axis_tlast = '1' or unsigned(tcnt_pre) = 5)) then
        tcnt_pre <= (others => '0');
      elsif (tready = '1' and s_axis_tvalid = '1') then
        tcnt_pre <= std_logic_vector(unsigned(tcnt_pre) + 1);
      end if;
    end if;
  end process;


  -- Delay line

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      tdata_d(0) <= byte_reverse(s_axis_tdata);
      for i in 1 to C_DELAY_TAPS-2 loop
        tdata_d(i) <= tdata_d(i-1);
      end loop;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      tcnt_d(0) <= tcnt_pre;
      for i in 1 to C_DELAY_TAPS-1 loop
        tcnt_d(i) <= tcnt_d(i-1);
      end loop;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      tvalid_d(0) <= s_axis_tvalid and tready;
      for i in 1 to C_DELAY_TAPS-1 loop
        tvalid_d(i) <= tvalid_d(i-1);
      end loop;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      tlast_d(0) <= s_axis_tlast;
      for i in 1 to C_DELAY_TAPS-1 loop
        tlast_d(i) <= tlast_d(i-1);
      end loop;
    end if;
  end process;


  -- Exponent and mantissa extraction

  process (aclk) is
    variable data_reversed : std_logic_vector(63 downto 0);

    -- Get the BFP9 exponent value based on the 16-bit data, for example
    -- 16'b00000000_00000001_ => exp = 0
    -- 16'b00000_010000000_00 => exp = 2
    -- 16'b_01000000_00000000 => exp = 8
    function get_exp (
      data : in std_logic_vector(15 downto 0)
    ) return std_logic_vector is
      variable ret : std_logic_vector(3 downto 0) := (others => '0');
    begin
      for i in 15 downto 8 loop
        if (data(i) /= data(i-1)) then
          ret := std_logic_vector(to_unsigned(i - 7, 4));
          return ret;
        end if;
      end loop;
      return ret;
    end function get_exp;

  begin
    if (rising_edge(aclk)) then
      data_reversed := byte_reverse(s_axis_tdata);
      exp_0 <= get_exp(data_reversed(63 downto 48));
      exp_1 <= get_exp(data_reversed(47 downto 32));
      exp_2 <= get_exp(data_reversed(31 downto 16));
      exp_3 <= get_exp(data_reversed(15 downto  0));
    end if;
  end process;

  process (aclk) is
    -- This function selectes MAC from 4 input
    function max4 (
      d1, d2, d3, d4 : in std_logic_vector(3 downto 0)
    ) return std_logic_vector is
      variable ret : std_logic_vector(3 downto 0) := (others => '0');
    begin
      if unsigned( d1) > unsigned(d2) then ret :=  d1; else ret := d2; end if;
      if unsigned(ret) > unsigned(d3) then ret := ret; else ret := d3; end if;
      if unsigned(ret) > unsigned(d4) then ret := ret; else ret := d4; end if;
      return ret;
    end function max4;
  begin
    if (rising_edge(aclk)) then
      exp_mt <= max4(exp_0, exp_1, exp_2, exp_3);
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (unsigned(tcnt_d(1)) = 0) then
        exp_ma <= exp_mt;
      elsif (unsigned(exp_ma) > unsigned(exp_mt)) then
        exp_ma <= exp_ma;
      else
        exp_ma <= exp_mt;
      end if;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (unsigned(tcnt_d(2)) = 5) then
        exp_pre <= exp_ma;
      end if;
    end if;
  end process;


  -- Compressing using extracted exponent

  process (aclk) is

    -- This function shift right the 16-bit data by number of exponent bits.
    -- We pad one extra bit "0" at LSB for rounding.
    function shifting (
      data : in std_logic_vector(15 downto 0);
      exp  : in std_logic_vector(3 downto 0)
    ) return std_logic_vector is
      variable shift : integer;
      variable tmp   : std_logic_vector(16 downto 0);
      variable ret   : std_logic_vector(8 downto 0);
    begin
      shift := to_integer(unsigned(exp_pre));
      tmp := data & "0";
      ret := tmp(shift+8 downto shift);
      return ret;
    end function shifting;

  begin
    if (rising_edge(aclk)) then
      comp_mantissa_pre_0_i <= shifting(tdata_d(C_DELAY_TAPS-2)(63 downto 48), exp_pre);
      comp_mantissa_pre_0_q <= shifting(tdata_d(C_DELAY_TAPS-2)(47 downto 32), exp_pre);
      comp_mantissa_pre_1_i <= shifting(tdata_d(C_DELAY_TAPS-2)(31 downto 16), exp_pre);
      comp_mantissa_pre_1_q <= shifting(tdata_d(C_DELAY_TAPS-2)(15 downto  0), exp_pre);
    end if;
  end process;

  process (aclk) is

    -- This function rounds 9-bit data into 8-bit. Rounding based on the LSB.
    function rounding (
      data : in std_logic_vector(8 downto 0)
    ) return std_logic_vector is
      variable tmp: std_logic_vector(8 downto 0) := (others => '1');
      variable ret: std_logic_vector(7 downto 0) := (others => '0');
    begin
      if (data /= tmp) then
        tmp := data;
        tmp := std_logic_vector(unsigned(data) + 1);
      end if;
      ret := tmp(8 downto 1);
      return ret;
    end function rounding;

  begin
    if (rising_edge(aclk)) then
      comp_mantissa_0_i <= rounding(comp_mantissa_pre_0_i);
      comp_mantissa_0_q <= rounding(comp_mantissa_pre_0_q);
      comp_mantissa_1_i <= rounding(comp_mantissa_pre_1_i);
      comp_mantissa_1_q <= rounding(comp_mantissa_pre_1_q);
    end if;
  end process;


  -- comp_* registers for output AXIS build

  comp_mantissa <= comp_mantissa_0_i & comp_mantissa_0_q & comp_mantissa_1_i & comp_mantissa_1_q;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      exp_pre_d <= exp_pre;
      comp_exp  <= exp_pre_d;
    end if;
  end process;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      comp_valid_r <= tvalid_d(C_DELAY_TAPS-1);
    end if;
  end process;

  comp_valid <= comp_valid_r;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      comp_last_r <= tlast_d(C_DELAY_TAPS-1);
    end if;
  end process;

  comp_last <= comp_last_r;

  process (aclk) is
  begin
    if (rising_edge(aclk)) then
      if (aresetn = '0') then
        comp_cnt_r <= (others => '0');
      elsif (comp_valid_r = '1' and (comp_last_r = '1' or comp_cnt_r = 47)) then
        comp_cnt_r <= (others => '0');
      elsif (comp_valid_r = '1') then
        comp_cnt_r <= comp_cnt_r + 1;
      end if;
    end if;
  end process;

  comp_cnt <= comp_cnt_r;

end architecture;
