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

package arch is
  -- "1" for modelsim simulation
  constant  IS_SIMULATION   : integer := 0;
  constant  SIGK  : integer := 512*26 + 300;

  -- FPGA type
  constant  DSP_TYPE    : string := "DSPE1";
  constant  FPGA_DEVICE : string := "7SERIES";
  
  constant  RLS_DATE    : std_logic_vector(31 downto 0) := X"20180816";

  -- algorithm
  constant  SPLUTS_NUM  : integer := 3;

  constant  DATA_DEPTH  : integer := 4096;
  constant  DATA_DEPTH2 : integer := DATA_DEPTH;    -- 32768 fixed on 8842 code
  
  constant  DATA_PWRSEL : std_logic_vector(0 to 7) := "11000000";

end;
 
