-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity program_counter_decode is
  port(
    clk : in std_logic;

    instruction :   in std_logic_vector(17 downto 0);
    carry_flag :    in std_logic;
    zero_flag :     in std_logic;
    pc_mode :       out std_logic_vector(2 downto 0));
  end program_counter_decode;

architecture arch of program_counter_decode is

-- internal signal
signal       pc_move_is_valid : std_logic;
signal           returni_type : std_logic;
signal              move_type : std_logic;

--**********************************************************************************
--
-------------------------------------------------------------------------------------------
--
-- Start of program_counter_decode circuit description
--
-------------------------------------------------------------------------------------------
--
begin
  --
  -- Decoding for Program Counter
  --
  pc_move_is_valid_lut: LUT6
  generic map (INIT => X"5A3CFFFF00000000")
  port map( I0 => carry_flag,
            I1 => zero_flag,
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => instruction(17),
             O => pc_move_is_valid);

  move_type_lut: LUT6_2
  generic map (INIT => X"7777027700000200")
  port map( I0 => instruction(12),
            I1 => instruction(13),
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => '1',
            O5 => returni_type,
            O6 => move_type);

  pc_mode1_lut: LUT6_2
  generic map (INIT => X"0000F000000023FF")
  port map( I0 => instruction(12),
            I1 => returni_type,
            I2 => move_type,
            I3 => pc_move_is_valid,
            I4 => '0',
            I5 => '1',
            O5 => pc_mode(0),
            O6 => pc_mode(1));

  pc_mode2_lut: LUT6
  generic map (INIT => X"FFFFFFFF00040000")
  port map( I0 => instruction(12),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => instruction(17),
            I5 => '0',
             O => pc_mode(2));

end arch;