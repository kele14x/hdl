library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.top_type_pkg.all;

entity compression_bfp8_comp is
  port (
    aclk    : in    std_logic;
    aresetn : in    std_logic;
    -- Data input
    s_axis_tdata  : in    std_logic_vector(63 downto 0);
    s_axis_tkeep  : in    std_logic_vector(7 downto 0);
    s_axis_tlast  : in    std_logic;
    s_axis_tready : out   std_logic;
    s_axis_tvalid : in    std_logic;
    --
    comp_mantissa : out   std_logic_vector(31 downto 0);
    comp_exp      : out   std_logic_vector(3 downto 0);
    comp_valid    : out   std_logic;
    comp_last     : out   std_logic
  );
end entity compression_bfp8_comp;

architecture rtl of compression_bfp8_comp is

  constant c_delay_taps : integer := 10;

  signal tready   : std_logic;
  signal tcnt_pre : unsigned(2 downto 0);

  signal tdata_d  : vector_64b_t(0 to c_delay_taps - 2);
  signal tcnt_d   : vector_3b_t(0 to c_delay_taps - 1);
  signal tvalid_d : std_logic_vector(0 to c_delay_taps - 1);
  signal tlast_d  : std_logic_vector(0 to c_delay_taps - 1);

  signal exp_0     : std_logic_vector(3 downto 0);
  signal exp_1     : std_logic_vector(3 downto 0);
  signal exp_2     : std_logic_vector(3 downto 0);
  signal exp_3     : std_logic_vector(3 downto 0);
  signal exp_mt    : std_logic_vector(3 downto 0);
  signal exp_ma    : std_logic_vector(3 downto 0);
  signal exp_pre   : std_logic_vector(3 downto 0);
  signal exp_pre_d : std_logic_vector(3 downto 0);

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

  -- Functions

  -- This function performs byte reverse on the input vector, as required by
  -- AXIS standard

  function byte_reverse (
    vector_in    : in std_logic_vector(63 downto 0)
  ) return std_logic_vector is

    variable ret : std_logic_vector(63 downto 0);

  begin

    for i in 0 to 7 loop
      ret(63 - i * 8 downto 56 - i * 8) := vector_in(7 + i * 8 downto i * 8);
    end loop;
    return ret;

  end function byte_reverse;

begin

  -- Insert one tick gap after we recevie TLAST, this prevents back-to-back
  -- transfier between packets. This gap is need by AXIS BFP bitstream builder.

  p_tready : process (aclk) is
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

  end process p_tready;

  s_axis_tready <= tready;

  -- Counter from 0 to 5, as one RB is compressed together

  p_tcnt : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      -- First tap
      if (aresetn = '0') then
        tcnt_pre <= (others => '0');
      elsif (tready = '1' and s_axis_tvalid = '1' and (s_axis_tlast = '1' or tcnt_pre = 5)) then
        tcnt_pre <= (others => '0');
      elsif (tready = '1' and s_axis_tvalid = '1') then
        tcnt_pre <= tcnt_pre + 1;
      end if;
    end if;

  end process p_tcnt;

  -- Delay data, counter, valid and last for 10 ticks, during those ticks we
  -- are doing exponent extraction

  p_tdata_d : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      tdata_d(0) <= byte_reverse(s_axis_tdata);
      for i in 1 to c_delay_taps - 2 loop
        tdata_d(i) <= tdata_d(i - 1);
      end loop;
    end if;

  end process p_tdata_d;

  p_tcnt_d : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      tcnt_d(0) <= std_logic_vector(tcnt_pre);
      for i in 1 to c_delay_taps - 1 loop
        tcnt_d(i) <= tcnt_d(i - 1);
      end loop;
    end if;

  end process p_tcnt_d;

  p_tvalid_d : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      tvalid_d(0) <= s_axis_tvalid and tready;
      for i in 1 to c_delay_taps - 1 loop
        tvalid_d(i) <= tvalid_d(i - 1);
      end loop;
    end if;

  end process p_tvalid_d;

  p_tlast_d : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      tlast_d(0) <= s_axis_tlast;
      for i in 1 to c_delay_taps - 1 loop
        tlast_d(i) <= tlast_d(i - 1);
      end loop;
    end if;

  end process p_tlast_d;

  -- Exponent and mantissa extraction

  p_exp_x : process (aclk) is

    variable data_reversed : std_logic_vector(63 downto 0);

    -- Get the BFP8 exponent value based on the 16-bit data, for example
    -- 16'b00000000_00000001_ => exp = 0
    -- 16'b00000_010000000_00 => exp = 2
    -- 16'b_01000000_00000000 => exp = 8

    function get_exp (
      data : in std_logic_vector(15 downto 0)
    ) return std_logic_vector is

      variable ret : std_logic_vector(3 downto 0);

    begin

      ret := (others => '0');
      for i in 15 downto 8 loop
        if (data(i) /= data(i - 1)) then
          ret := std_logic_vector(to_unsigned(i - 7, 4));
          return ret;
        end if;
      end loop;
      return ret;

    end function get_exp;

  begin

    if (rising_edge(aclk)) then
      data_reversed := byte_reverse(s_axis_tdata);
      exp_0         <= get_exp(data_reversed(63 downto 48));
      exp_1         <= get_exp(data_reversed(47 downto 32));
      exp_2         <= get_exp(data_reversed(31 downto 16));
      exp_3         <= get_exp(data_reversed(15 downto  0));
    end if;

  end process p_exp_x;

  p_exp_mt : process (aclk) is

    -- This function selectes MAC from 4 input

    function max4 (
      d1, d2, d3, d4 : in std_logic_vector(3 downto 0)
    ) return std_logic_vector is

      variable ret : std_logic_vector(3 downto 0);

    begin

      if (unsigned(d1) > unsigned(d2)) then
        ret := d1;
      else
        ret := d2;
      end if;

      if (unsigned(ret) > unsigned(d3)) then
        ret := ret;
      else
        ret := d3;
      end if;

      if (unsigned(ret) > unsigned(d4)) then
        ret := ret;
      else
        ret := d4;
      end if;

      return ret;

    end function max4;

  begin

    if (rising_edge(aclk)) then
      exp_mt <= max4(exp_0, exp_1, exp_2, exp_3);
    end if;

  end process p_exp_mt;

  -- Go though the 6 ticks and select the largest exponent

  p_exp_ma : process (aclk) is
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

  end process p_exp_ma;

  -- Hold the exponent value for the next 6 ticks

  p_exp_pre : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      if (unsigned(tcnt_d(2)) = 5) then
        exp_pre <= exp_ma;
      end if;
    end if;

  end process p_exp_pre;

  -- Compressing using extracted exponent, it has two steps:
  -- Step 1, shifting the mantissa to the right

  p_comp_mantissa_pre_x : process (aclk) is

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
      tmp   := data & "0";
      ret   := tmp(shift + 8 downto shift);
      return ret;

    end function shifting;

  begin

    if (rising_edge(aclk)) then
      comp_mantissa_pre_0_i <= shifting(tdata_d(c_delay_taps - 2)(63 downto 48), exp_pre);
      comp_mantissa_pre_0_q <= shifting(tdata_d(c_delay_taps - 2)(47 downto 32), exp_pre);
      comp_mantissa_pre_1_i <= shifting(tdata_d(c_delay_taps - 2)(31 downto 16), exp_pre);
      comp_mantissa_pre_1_q <= shifting(tdata_d(c_delay_taps - 2)(15 downto  0), exp_pre);
    end if;

  end process p_comp_mantissa_pre_x;

  -- Step 2, rounding

  p_comp_mantissa_x : process (aclk) is

    -- This function rounds 9-bit data into 8-bit. Rounding based on the LSB.
    -- To avoid overflow, all '1' is not round up

    function rounding (
      data : in std_logic_vector(8 downto 0)
    ) return std_logic_vector is

      variable tmp: std_logic_vector(8 downto 0);
      variable ret: std_logic_vector(7 downto 0);

    begin

      tmp := (others => '1');

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

  end process p_comp_mantissa_x;

  -- comp_* registers for output AXIS build

  comp_mantissa <= comp_mantissa_0_i & comp_mantissa_0_q & comp_mantissa_1_i & comp_mantissa_1_q;

  p_comp_exp : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      exp_pre_d <= exp_pre;
      comp_exp  <= exp_pre_d;
    end if;

  end process p_comp_exp;

  p_comp_valid : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      comp_valid <= tvalid_d(c_delay_taps - 1);
    end if;

  end process p_comp_valid;

  p_comp_last : process (aclk) is
  begin

    if (rising_edge(aclk)) then
      comp_last <= tlast_d(c_delay_taps-1);
    end if;

  end process p_comp_last;

end architecture rtl;
