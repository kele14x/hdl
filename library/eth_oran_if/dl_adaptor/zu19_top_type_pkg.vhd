-------------------------------------------------------------------------------
-- Copyright (c) ZILLNK, 2020
-- The copyright to the document(s) herein is the property of
-- ZILLNK, China.
--
-- The document(s) may be used and/or copied only with the written
-- permission from ZILLNK, or in accordance with the terms and conditions
-- stipulated in the agreement/contract under which the document(s) have been
-- supplied.
-- 
-- All rights reserved. 
-------------------------------------------------------------------------------
-- Author     :  
-- Create Date: 10/10/2020 
-- Design Name: 
-- Module Name: Type lib
-- Project Name: 
-- Target Devices:  
-- Tool Versions: Vivado 2018.3
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Version       Date         Description
-- Revision 0.01 2020-10-10   File Created 
-- Revision 
--
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


LIBRARY ieee;  
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE zu19_top_type_pkg IS


  ---------------------- module inst parameter----------   
  CONSTANT  USE_ILINK_TOP                   : BOOLEAN := TRUE;      
  CONSTANT  USE_SERDES_TOP                  : BOOLEAN := TRUE;      
  CONSTANT  USE_TDD_CTRL_TOP                : BOOLEAN := TRUE;      
  CONSTANT  USE_SPI_TOP                     : BOOLEAN := TRUE;      
  CONSTANT  USE_PWR_TOP                     : BOOLEAN := TRUE;     
  CONSTANT  USE_RTS_TOP                     : BOOLEAN := TRUE;     
  CONSTANT  USE_DFE_FUNCTIONS               : BOOLEAN := TRUE;      
  CONSTANT  USE_DL_FUNCTIONS                : BOOLEAN := TRUE;      
  CONSTANT  USE_UL_FUNCTIONS                : BOOLEAN := TRUE;     
  
  

  CONSTANT c_32bit_0        : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000000";        
  CONSTANT c_64bit_0        : STD_LOGIC_VECTOR(63 DOWNTO 0) := X"0000000000000000";
                                                                                   
  -- FPGA Product Number,eg.hex2dec(1A8211) = 1737233 and hex2dec(15)=21.   P1B ZU19 "1B010101"
  CONSTANT c_product_number : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"1B010101";         
                                                                                   
  -- FPGA Version Value: Major.Minor.PATCH  
  CONSTANT c_version_high   : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"21041201";   --00.00.0001   
  -- FPGA Version ASCII Value: R/A.Patch number, R=0x52 for formal Release, Alpha(A=0x41) for debug purpose. patch number is only used in Alpha version. 
  CONSTANT c_version_low    : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"DB230001";   --00R.0000

  CONSTANT logic_high       : STD_LOGIC := '1';                                    
  CONSTANT logic_low        : STD_LOGIC := '0';                                    
                                                                                   
  -- IRQ                                                                           
  CONSTANT int_range        : INTEGER := 31;   
  
  
  
  --design parameter definition         
  constant CARRIER_NUMBER_C        : INTEGER := 2;           
  constant ANT_NUMBER_C            : INTEGER := 64; 
  constant DL_LAYER_NUMBER_C       : INTEGER := 16; 
  constant UL_LAYER_NUMBER_C       : INTEGER := 8; 
  constant INTER_LINK_NUM_C        : INTEGER := 10;     
  constant num_rfs_c : natural := 8;        -- rfs number
  -- SPI device selection
  constant num_slave_cs : natural := 2;        -- at most 32 cs signals, otherwise code revise is needed
  constant num_slave_data_port : natural := 1;  -- at most 8 data ports, otherwise code revise is needed
  
  
  -----------------------------------------------------------------------------
  -- Types
  -----------------------------------------------------------------------------         
  type vector_1b_t   is array (integer range <>) of std_logic_vector( 0 downto 0);
  type vector_2b_t   is array (integer range <>) of std_logic_vector( 1 downto 0);
  type vector_3b_t   is array (integer range <>) of std_logic_vector( 2 downto 0);
  type vector_4b_t   is array (integer range <>) of std_logic_vector( 3 downto 0);
  type vector_5b_t   is array (integer range <>) of std_logic_vector( 4 downto 0);
  type vector_6b_t   is array (integer range <>) of std_logic_vector( 5 downto 0);
  type vector_7b_t   is array (integer range <>) of std_logic_vector( 6 downto 0);
  type vector_8b_t   is array (integer range <>) of std_logic_vector( 7 downto 0);
  type vector_9b_t   is array (integer range <>) of std_logic_vector( 8 downto 0);
  type vector_10b_t  is array (integer range <>) of std_logic_vector( 9 downto 0);
  type vector_11b_t  is array (integer range <>) of std_logic_vector(10 downto 0);
  type vector_12b_t  is array (integer range <>) of std_logic_vector(11 downto 0);
  type vector_13b_t  is array (integer range <>) of std_logic_vector(12 downto 0);
  type vector_14b_t  is array (integer range <>) of std_logic_vector(13 downto 0);
  type vector_15b_t  is array (integer range <>) of std_logic_vector(14 downto 0);
  type vector_16b_t  is array (integer range <>) of std_logic_vector(15 downto 0);
  type vector_17b_t  is array (integer range <>) of std_logic_vector(16 downto 0);
  type vector_18b_t  is array (integer range <>) of std_logic_vector(17 downto 0);
  type vector_19b_t  is array (integer range <>) of std_logic_vector(18 downto 0);
  type vector_20b_t  is array (integer range <>) of std_logic_vector(19 downto 0);              
  type vector_21b_t  is array (integer range <>) of std_logic_vector(20 downto 0);
  type vector_22b_t  is array (integer range <>) of std_logic_vector(21 downto 0);
  type vector_23b_t  is array (integer range <>) of std_logic_vector(22 downto 0);
  type vector_24b_t  is array (integer range <>) of std_logic_vector(23 downto 0);  
  type vector_25b_t  is array (integer range <>) of std_logic_vector(24 downto 0); 
  type vector_26b_t  is array (integer range <>) of std_logic_vector(25 downto 0); 
  type vector_27b_t  is array (integer range <>) of std_logic_vector(26 downto 0);
  type vector_28b_t  is array (integer range <>) of std_logic_vector(27 downto 0);
  type vector_29b_t  is array (integer range <>) of std_logic_vector(28 downto 0);
  type vector_30b_t  is array (integer range <>) of std_logic_vector(29 downto 0);
  type vector_31b_t  is array (integer range <>) of std_logic_vector(30 downto 0);
  type vector_32b_t  is array (integer range <>) of std_logic_vector(31 downto 0);
  type vector_33b_t  is array (integer range <>) of std_logic_vector(32 downto 0);
  type vector_34b_t  is array (integer range <>) of std_logic_vector(33 downto 0);    
  type vector_35b_t  is array (integer range <>) of std_logic_vector(34 downto 0);                
  type vector_36b_t  is array (integer range <>) of std_logic_vector(35 downto 0);    
  type vector_37b_t  is array (integer range <>) of std_logic_vector(36 downto 0);  
  type vector_38b_t  is array (integer range <>) of std_logic_vector(37 downto 0);  
  type vector_39b_t  is array (integer range <>) of std_logic_vector(38 downto 0);
  type vector_40b_t  is array (integer range <>) of std_logic_vector(39 downto 0);
  type vector_41b_t  is array (integer range <>) of std_logic_vector(40 downto 0);
  type vector_42b_t  is array (integer range <>) of std_logic_vector(41 downto 0);
  type vector_43b_t  is array (integer range <>) of std_logic_vector(42 downto 0);
  type vector_44b_t  is array (integer range <>) of std_logic_vector(43 downto 0);
  type vector_45b_t  is array (integer range <>) of std_logic_vector(44 downto 0);
  type vector_46b_t  is array (integer range <>) of std_logic_vector(45 downto 0);
  type vector_47b_t  is array (integer range <>) of std_logic_vector(44 downto 0);
  type vector_48b_t  is array (integer range <>) of std_logic_vector(47 downto 0);
  type vector_54b_t  is array (integer range <>) of std_logic_vector(53 downto 0);
  type vector_52b_t  is array (integer range <>) of std_logic_vector(51 downto 0);
  type vector_55b_t  is array (integer range <>) of std_logic_vector(54 downto 0);
  type vector_58b_t  is array (integer range <>) of std_logic_vector(57 downto 0);
  type vector_60b_t  is array (integer range <>) of std_logic_vector(59 downto 0);
  type vector_63b_t  is array (integer range <>) of std_logic_vector(62 downto 0);
  type vector_64b_t  is array (integer range <>) of std_logic_vector(63 downto 0); 
  type vector_68b_t  is array (integer range <>) of std_logic_vector(67 downto 0); 
  type vector_72b_t  is array (integer range <>) of std_logic_vector(71 downto 0); 
  type vector_80b_t  is array (integer range <>) of std_logic_vector(79 downto 0);
  type vector_92b_t  is array (integer range <>) of std_logic_vector(91 downto 0);
  type vector_96b_t  is array (integer range <>) of std_logic_vector(95 downto 0); 
  type vector_106b_t is array (integer range <>) of std_logic_vector(105 downto 0);   
  type vector_120b_t is array (integer range <>) of std_logic_vector(119 downto 0); 
  type vector_128b_t is array (integer range <>) of std_logic_vector(127 downto 0);  
  type vector_144b_t is array (integer range <>) of std_logic_vector(143 downto 0);   
  type vector_150b_t is array (integer range <>) of std_logic_vector(149 downto 0);  
  type vector_152b_t is array (integer range <>) of std_logic_vector(151 downto 0);  
  type vector_160b_t is array (integer range <>) of std_logic_vector(159 downto 0);  
  type vector_168b_t is array (integer range <>) of std_logic_vector(167 downto 0);   
  type vector_170b_t is array (integer range <>) of std_logic_vector(169 downto 0);              
  type vector_184b_t is array (integer range <>) of std_logic_vector(183 downto 0);                 
  type vector_272b_t is array (integer range <>) of std_logic_vector(271 downto 0); 
  
END;
