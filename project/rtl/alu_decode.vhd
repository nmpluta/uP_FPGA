-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity alu_decode is
  port(
    clk : in std_logic;

    instruction :       in std_logic_vector(17 downto 0);
    carry_flag :        in std_logic;
    arith_logical_sel : out std_logic_vector(2 downto 0);
    arith_carry_in :    out std_logic;
    alu_mux_sel :       out std_logic_vector(1 downto 0));
  end alu_decode;

architecture arch of alu_decode is

-- internal signal
signal      alu_mux_sel_value : std_logic_vector(1 downto 0);

--**********************************************************************************
--
--
-------------------------------------------------------------------------------------------
--
-- WebTalk Attributes
--

-- attribute CORE_GENERATION_INFO : string;
-- attribute CORE_GENERATION_INFO of low_level_definition : ARCHITECTURE IS 
--     "kcpsm6,kcpsm6_v1_3,{component_name=kcpsm6}";

-- --
-- -- Attributes to guide mapping of logic into Slices.
-- --
-- attribute hblknm of          alu_decode0_lut : label is "kcpsm6_decode2";
-- attribute hblknm of        alu_mux_sel0_flop : label is "kcpsm6_decode2";
-- attribute hblknm of          alu_decode1_lut : label is "kcpsm6_decode1";
-- attribute hblknm of        alu_mux_sel1_flop : label is "kcpsm6_decode1";
-- attribute hblknm of          alu_decode2_lut : label is "kcpsm6_decode2";

--
-------------------------------------------------------------------------------------------
--
-- Start of decode_alu circuit description
--
-------------------------------------------------------------------------------------------
--
begin

  --
  -- Decoding for ALU
  --

  alu_decode0_lut: LUT6_2
  generic map (INIT => X"03CA000004200000")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => '1',
            I5 => '1',
            O5 => alu_mux_sel_value(0),
            O6 => arith_logical_sel(0));

  alu_mux_sel0_flop: FD
  port map (  D => alu_mux_sel_value(0),
              Q => alu_mux_sel(0),
              C => clk);

  alu_decode1_lut: LUT6_2
  generic map (INIT => X"7708000000000F00")
  port map( I0 => carry_flag,
            I1 => instruction(13),
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => '1',
            O5 => alu_mux_sel_value(1),
            O6 => arith_carry_in);                     

  alu_mux_sel1_flop: FD
  port map (  D => alu_mux_sel_value(1),
              Q => alu_mux_sel(1),
              C => clk);


  alu_decode2_lut: LUT6_2
  generic map (INIT => X"D000000002000000")
  port map( I0 => instruction(14),
            I1 => instruction(15),
            I2 => instruction(16),
            I3 => '1',
            I4 => '1',
            I5 => '1',
            O5 => arith_logical_sel(1),
            O6 => arith_logical_sel(2));


end arch;

