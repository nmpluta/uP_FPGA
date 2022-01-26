library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity state_control is
        port(
                clk : in std_logic;
                t_state_out : out std_logic_vector(2 downto 1);
                internal_reset_out : out std_logic;
                reset : in std_logic
        );
end state_control;

architecture arch of state_control is

        signal internal_reset           : std_logic;
        signal internal_reset_value     : std_logic;
        signal run                      : std_logic;
        signal run_value                : std_logic;
        signal t_state                  : std_logic_vector(2 downto 1);
        signal t_state_value            : std_logic_vector(2 downto 1);

begin

        reset_lut: LUT6_2
        generic map (INIT => X"FFFFF55500000EEE")
        port map(
                        I0 => run,
                        I1 => internal_reset,
                        I2 => '0',
                        I3 => t_state(2),
                        I4 => reset,
                        I5 => '1',
                        O5 => run_value,
                        O6 => internal_reset_value
                );

        run_flop: FD
        port map (
                        D => run_value,
                        Q => run,
                        C => clk
                );

        internal_reset_flop: FD
        port map (
                        D => internal_reset_value,
                        Q => internal_reset,
                        C => clk
                );

        t_state_lut: LUT6_2
        generic map (INIT => X"0083000B00C4004C")
        port map(
                        I0 => t_state(1),
                        I1 => t_state(2),
                        I2 => '0',
                        I3 => internal_reset,
                        I4 => '0',
                        I5 => '1',
                        O5 => t_state_value(1),
                        O6 => t_state_value(2)
                );

        t_state1_flop: FD
        port map (
                        D => t_state_value(1),
                        Q => t_state(1),
                        C => clk
                );

        t_state2_flop: FD
        port map (
                        D => t_state_value(2),
                        Q => t_state(2),
                        C => clk
                );

        internal_reset_out      <= internal_reset;
        t_state_out             <= t_state;
end arch;

