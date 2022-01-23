library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity adress_generator is
        port(
                instruction  : in std_logic_vector(17 downto 0);
                pc_vector    : out std_logic_vector(11 downto 0)
        );
end adress_generator;

architecture arch of adress_generator is

begin
        address_loop: for i in 0 to 11 generate
        begin
                output_data: if (i rem 2) = 0 generate
                begin
                        pc_vector_mux_lut: LUT3
                        generic map (INIT => X"0A")
                        port map(
                                        I0 => instruction(i),
                                        I1 => instruction(i+1),
                                        I2 => instruction(12),
                                        O  => pc_vector(i)
                        );

                        pc_vector_mux_lut_nxt: LUT3
                        generic map (INIT => X"0C")
                        port map(
                                        I0 => instruction(i),
                                        I1 => instruction(i+1),
                                        I2 => instruction(12),
                                        O  => pc_vector(i+1)
                        );
                end generate output_data;
        end generate address_loop;
end arch;

