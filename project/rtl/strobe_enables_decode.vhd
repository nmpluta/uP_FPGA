-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity strobe_enables_decode is
  port(
    clk : in std_logic;

    instruction :       in std_logic_vector(17 downto 0);
    t_state :           in std_logic_vector(2 downto 1);
    strobe_type :       in std_logic;

    flag_enable :       out std_logic;
    register_enable :   out std_logic;
    write_strobe :      out std_logic;
    read_strobe :       out std_logic);
  end strobe_enables_decode;

architecture arch of strobe_enables_decode is

-- internal signal
signal    flag_enable_type :      std_logic;
signal    flag_enable_value :     std_logic;
signal    register_enable_type :  std_logic;
signal    register_enable_value : std_logic;
signal    read_strobe_value :     std_logic;
signal    write_strobe_value :    std_logic;

--**********************************************************************************
--
-------------------------------------------------------------------------------------------
--
-- Start of strobe_enables_decode circuit description
--
-------------------------------------------------------------------------------------------
--
begin

  --
  -- Decoding for strobes and enables
  --

  register_enable_type_lut: LUT6_2
  generic map (INIT => X"00013F3F0010F7CE")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => instruction(17),
            I5 => '1',
            O5 => flag_enable_type,
            O6 => register_enable_type);

  register_enable_lut: LUT6_2
  generic map (INIT => X"C0CC0000A0AA0000")
  port map( I0 => flag_enable_type,
            I1 => register_enable_type,
            I2 => instruction(12),
            I3 => instruction(17),
            I4 => t_state(1),
            I5 => '1',
            O5 => flag_enable_value,
            O6 => register_enable_value);

  flag_enable_flop: FD
  port map (  D => flag_enable_value,
              Q => flag_enable,
              C => clk);

  register_enable_flop: FD
  port map (  D => register_enable_value,
              Q => register_enable,
              C => clk);

  read_strobe_lut: LUT6_2
  generic map (INIT => X"4000000001000000")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(17),
            I3 => strobe_type,
            I4 => t_state(1),
            I5 => '1',
            O5 => read_strobe_value,
            O6 => write_strobe_value);

  write_strobe_flop: FD
  port map (  D => write_strobe_value,
              Q => write_strobe,
              C => clk);

  read_strobe_flop: FD
  port map (  D => read_strobe_value,
              Q => read_strobe,
              C => clk);


end arch;
