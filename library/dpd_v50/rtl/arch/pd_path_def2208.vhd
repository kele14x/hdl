-------------------------------------------------------------------------------
-- copyright (c) ericsson ab, 2011
-- the copyright to the document(s) herein is the property of
-- ericsson ab, sweden.
--
-- the document(s) may be used and/or copied only with the written
-- permission from ericsson ab, or in accordance with the terms and
-- conditions stipulated in the agreement/contract under which
-- the document(s) have been supplied.
--
-- all rights reserved.
-------------------------------------------------------------------------------
--
-- author:     qeliwik
-- created:    2011-03-16
--
-------------------------------------------------------------------------------
-- description: type declarations for xios_i.
--
-------------------------------------------------------------------------------
-- vhdl version: vhdl '93
--
-------------------------------------------------------------------------------
-- modified:
--
-- renamed package
-------------------------------------------------------------------------------

library ieee;  
use ieee.std_logic_1164.all;

package pd_path_def is
  -- input 2x sample, symmetrical
  constant IN2X_COEF0       : integer := 1370;
  constant IN2X_COEF1       : integer := -7802;
  constant IN2X_COEF2       : integer := 39237;
  
  -- vector bits
  type vector_48b_t  is array (integer range <>) of std_logic_vector(47 downto 0);
  type vector_18b_t  is array (integer range <>) of std_logic_vector(17 downto 0);
  type vector_16b_t  is array (integer range <>) of std_logic_vector(15 downto 0);
  type vector_10b_t  is array (integer range <>) of std_logic_vector( 9 downto 0);
  
  -- algorithm GMP model definition
  constant FBIT_LUT         : integer := 14;    -- 14 bits fractional for LUTS

  ------------------------------------------------------------------------------
  -- GMP definition
  constant GMP_PIPES        : integer := 116;    -- maximum delays
  
  type vector_spluts is array(0 to 3) of integer;
  constant SPLUTS_ID        : vector_spluts := (25, 26, 27, 28);
  
  constant DYNLUT_ID        : integer := 30;

  -- auto-generated code begin -------------------------------------------------
  -- GMP model matrix taps
  constant GMP_UTAPS        : integer := 5;

  type vector_integer  is array(0 to GMP_UTAPS-1) of integer;
  type vector_integer2 is array(0 to GMP_UTAPS-1) of vector_integer;
  type vector32 is array(0 to 31) of integer;

  -- 0, 1, 2, ..., UTAPS-1; main tap for signal
  constant MAIN_TAP         : integer := 2;

  -- TDD luts delay selection
  constant TDD_ADRDELAY     : integer := 28;

  -- passing signal delay
  constant GMP_SIGDELAY     : integer := 96;

  -- Adder chain position, 0 ~ GMP_UTAPS-1
  constant FIRST_LUT        : vector_integer := ( 0,  1,  0,  2,  2);

  -- first MACC, 0 ~ GMP_UTAPS-1
  constant FIRST_MACC       : integer := 0;

  -- last MACC, 0 ~ GMP_UTAPS-1
  constant LAST_MACC        : integer := 4;

  -- MACC definition, 1: exist;
  constant MACC_DEF         : vector_integer := ( 1,  1,  1,  1,  1);

  -- Signal delay, basic + matching + macc
  constant DELAYS_SIG       : vector_integer := (64, 72, 78, 84, 92);

  -- Signal delay, basic + matching + macc
  constant DELAYS_SIG2      : vector_integer := (42, 60, 78, 96, 114);

  -- LUTs address delay, basic + adder chain + macc
  constant DELAYS_ADR       : vector_integer2 := (  (24, 30, 32, 34, 38),
                                                    (30, 32, 36, 38, 42),
                                                    (26, 32, 36, 40, 46),
                                                    (38, 42, 42, 46, 50),
                                                    (42, 46, 46, 50, 54) );

  -- LUTs address delay, basic + adder chain + macc
  constant DELAYS_ADR2      : vector_integer2 := (  ( 2, 18, 32, 46, 60),
                                                    ( 8, 20, 36, 50, 64),
                                                    ( 4, 20, 36, 52, 68),
                                                    (16, 30, 42, 58, 72),
                                                    (20, 34, 46, 62, 76) );

  -- LUTs ID, 0, 1, 2, ...
  constant LUTS_ID          : vector_integer2 := (  ( 0, 31,  1, 31, 31),
                                                    (31,  2,  3, 31, 31),
                                                    ( 4,  5,  6,  7,  8),
                                                    (31, 31,  9, 10, 31),
                                                    (31, 31, 11, 31, 12) );

  -- GMP definition matrix
  constant GMP_DEF          : vector_integer2 := (  ( 1,  0,  1,  0,  0),
                                                    ( 0,  1,  1,  0,  0),
                                                    ( 1,  1,  1,  1,  1),
                                                    ( 0,  0,  1,  1,  0),
                                                    ( 0,  0,  1,  0,  1) );

  -- terms ID, signal delay, address delay
  constant TERMS_ID         : vector32 := ( 6,  0,  1,  2,  3,  4,  5,  7,  8,  9, 10, 11, 12, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31);
  constant TERMS_SIG        : vector32 := ( 0, 250, 250, 254, 254,  0,  0,  0,  0,  2,  2,  6,  6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0);
  constant TERMS_ADR        : vector32 := ( 0, 250,  0, 254,  0, 250, 254,  2,  6,  0,  2,  0,  6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0);

  constant TERMS_SIG2       : vector32 := ( 0, 228, 228, 242, 242,  0,  0,  0,  0, 14, 14, 28, 28,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0);
  constant TERMS_ADR2       : vector32 := ( 0, 228,  0, 242,  0, 228, 242, 14, 28,  0, 14,  0, 28,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0);


  -- auto-generated code end ---------------------------------------------------

end;
 
