library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity flags is
        port(
                clk                     : in std_logic;
                internal_reset          : in std_logic;
                flag_enable             : in std_logic;
                instruction             : in std_logic_vector(17 downto 0);
                carry_arith_logical     : in std_logic;
                alu_result              : in std_logic_vector(7 downto 0);
                strobe_type             : out std_logic;
                zero_flag               : out std_logic;
                carry_flag              : out std_logic
        );
end flags;

architecture arch of flags is

        -- internal signal
        signal arith_carry_value        : std_logic;
        signal arith_carry              : std_logic;
        signal drive_carry_in_zero      : std_logic;
        signal carry_flag_value         : std_logic;
        signal carry_in_zero            : std_logic;
        signal use_zero_flag_value      : std_logic;
        signal use_zero_flag            : std_logic;
        signal zero_flag_buf            : std_logic;
        signal middle_zero              : std_logic;
        signal carry_lower_zero         : std_logic;
        signal middle_zero_sel          : std_logic;
        signal carry_middle_zero        : std_logic;
        signal upper_zero_sel           : std_logic;
        signal zero_flag_value          : std_logic;
        signal lower_zero               : std_logic;
        signal lower_zero_sel           : std_logic;

  --
  -------------------------------------------------------------------------------------------
  -- Flags
  --
  --     3 x LUT6
  --     5 x LUT6_2
  --     3 x FD
  --     2 x FDRE
  --     2 x XORCY
  --     5 x MUXCY
  --
  -------------------------------------------------------------------------------------------
  --
begin
        arith_carry_flop: FD
        port map (
                        D => carry_arith_logical,
                        Q => arith_carry,
                        C => clk
                );

        carry_flag_lut: LUT6_2
        generic map (INIT => X"3333AACCF0AA0000")
        port map(
                        I0 => '0',
                        I1 => arith_carry,
                        I2 => '0',
                        I3 => instruction(14),
                        I4 => instruction(15),
                        I5 => instruction(16),
                        O5 => drive_carry_in_zero,
                        O6 => carry_flag_value
                );

        carry_flag_flop: FDRE
        port map (
                        D => carry_flag_value,
                        Q => carry_flag,
                        CE => flag_enable,
                        R => internal_reset,
                        C => clk
                );

        init_zero_muxcy: MUXCY
        port map(
                        DI => drive_carry_in_zero,
                        CI => '0',
                        S => carry_flag_value,
                        O => carry_in_zero
                );

        use_zero_flag_lut: LUT6_2
        generic map (INIT => X"A280000000F000F0")
        port map(
                        I0 => instruction(13),
                        I1 => instruction(14),
                        I2 => instruction(15),
                        I3 => instruction(16),
                        I4 => '1',
                        I5 => '1',
                        O5 => strobe_type,
                        O6 => use_zero_flag_value
                );

        use_zero_flag_flop: FD
        port map (
                        D => use_zero_flag_value,
                        Q => use_zero_flag,
                        C => clk
                );

        lower_zero_lut: LUT6_2
        generic map (INIT => X"0000000000000001")
        port map(
                        I0 => alu_result(0),
                        I1 => alu_result(1),
                        I2 => alu_result(2),
                        I3 => alu_result(3),
                        I4 => alu_result(4),
                        I5 => '1',
                        O5 => lower_zero,
                        O6 => lower_zero_sel
                );

        lower_zero_muxcy: MUXCY
        port map(
                        DI => lower_zero,
                        CI => carry_in_zero,
                        S => lower_zero_sel,
                        O => carry_lower_zero
                );

        middle_zero_lut: LUT6_2
        generic map (INIT => X"0000000D00000000")
        port map(
                        I0 => use_zero_flag,
                        I1 => zero_flag_buf,
                        I2 => alu_result(5),
                        I3 => alu_result(6),
                        I4 => alu_result(7),
                        I5 => '1',
                        O5 => middle_zero,
                        O6 => middle_zero_sel
                );

        middle_zero_muxcy: MUXCY
        port map(
                        DI => middle_zero,
                        CI => carry_lower_zero,
                        S => middle_zero_sel,
                        O => carry_middle_zero
                );

        upper_zero_lut: LUT6
        generic map (INIT => X"FBFF000000000000")
        port map(
                        I0 => instruction(14),
                        I1 => instruction(15),
                        I2 => instruction(16),
                        I3 => '1',
                        I4 => '1',
                        I5 => '1',
                        O => upper_zero_sel
                );

        upper_zero_muxcy: MUXCY
        port map(
                        DI => '0',
                        CI => carry_middle_zero,
                        S => upper_zero_sel,
                        O => zero_flag_value
                );

        zero_flag_flop: FDRE
        port map (
                        D => zero_flag_value,
                        Q => zero_flag_buf,
                        CE => flag_enable,
                        R => internal_reset,
                        C => clk
                );
        zero_flag <= zero_flag_buf;
end arch;

