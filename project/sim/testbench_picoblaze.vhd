library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity testbench_picoblaze is
end testbench_picoblaze;

architecture behavior of testbench_picoblaze is

        component picoblaze_top
        Port (
                        clk       : in std_logic;
                        Sw        : in std_logic_vector(7 downto 0);
                        Ld        : out std_logic_vector(7 downto 0)
                );
        end component;

        signal clk              : std_logic := '0';
        signal Ld               :  std_logic_vector(7 downto 0);
        signal SW               :  std_logic_vector(7 downto 0) := X"01";

        signal max_cycles       : integer := 5000;
        signal cycle_count      : integer := 1;

begin

        picoblaze_top_tes : picoblaze_top
        port map (
                        clk      => clk,
                        Sw       => Sw,
                        Ld       => Ld
                );

        simulate_clock: process
        begin
        while cycle_count < max_cycles loop

                wait for 2.5 ns;
                clk <= '0';
                wait for 2.5 ns;
                clk <= '1';

                cycle_count <= cycle_count + 1;
                if cycle_count mod 1000 = 0 then
                        Sw <= Sw + 9;
                end if;
        end loop;
        wait;
        end process simulate_clock;
end;

