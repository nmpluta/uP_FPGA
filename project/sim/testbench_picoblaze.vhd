library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity testbench_picoblaze is
end testbench_picoblaze;

architecture behavior of testbench_picoblaze is

        component picoblaze_top
        Port (
                        Sw        : in std_logic_vector(7 downto 0);
                        Ld        : out std_logic_vector(7 downto 0);
                        clk200_p : in std_logic;
                        clk200_n : in std_logic
                );
        end component;

        signal clk200_p         : std_logic := '0';
        signal clk200_n         : std_logic := '1';
        signal Ld               :  std_logic_vector(7 downto 0);
        signal SW               :  std_logic_vector(7 downto 0) := X"01";

        signal max_cycles       : integer := 5000;
        signal cycle_count      : integer := 1;

begin

        picoblaze_top_tes : picoblaze_top
        port map (
                Sw       => Sw,
                Ld       => Ld,
                clk200_p => clk200_p,
                clk200_n => clk200_n
                );

        simulate_clock: process
        begin
        while cycle_count < max_cycles loop

                wait for 2.5 ns;
                clk200_p <= '1';
                clk200_n <= '0';
                wait for 2.5 ns;
                clk200_p <= '0';
                clk200_n <= '1';

                cycle_count <= cycle_count + 1;
                if cycle_count mod 1000 = 0 then
                        Sw <= Sw + 9;
                end if;
        end loop;
        wait;
        end process simulate_clock;
end;

