library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity in_out_adress_ctl is
        port(
                instruction     : in std_logic_vector(17 downto 0);
                sx              : in std_logic_vector(7 downto 0);
                sy              : in std_logic_vector(7 downto 0);
                sy_or_kk        : out std_logic_vector(7 downto 0);
                out_port        : out std_logic_vector(7 downto 0)
        );
end in_out_adress_ctl;

architecture arch of in_out_adress_ctl is

begin
        data_path_loop1: for i in 0 to 7 generate
        begin

          --
          -------------------------------------------------------------------------------------------
          --
          -- Selection of second operand to ALU and port_id
          --
          -- instruction(12)
          --           0  Register sY
          --           1  Constant kk
          --
          --     4 x LUT6_2
          --
          -------------------------------------------------------------------------------------------
          -- 2 bits per LUT so only generate when 'i' is even
          --

          output_data: if (i rem 2)=0 generate
          begin

            sy_kk_mux_lut: LUT6_2
            generic map (INIT => X"FF00F0F0CCCCAAAA")
            port map( I0 => sy(i),
                      I1 => instruction(i),
                      I2 => sy(i+1),
                      I3 => instruction(i+1),
                      I4 => instruction(12),
                      I5 => '1',
                      O5 => sy_or_kk(i),
                      O6 => sy_or_kk(i+1));

          end generate output_data;

          --
          -------------------------------------------------------------------------------------------
          --
          -- Selection of out_port value
          --
          -- instruction(13)
          --              0  Register sX
          --              1  Constant kk from instruction(11:4)
          --
          --     4 x LUT6_2
          --
          -------------------------------------------------------------------------------------------
          -- 2 bits per LUT so only generate when 'i' is even
          --
          second_operand: if (i rem 2)=0 generate
          begin

            out_port_lut: LUT6_2
            generic map (INIT => X"FF00F0F0CCCCAAAA")
            port map( I0 => sx(i),
                      I1 => instruction(i+4),
                      I2 => sx(i+1),
                      I3 => instruction(i+5),
                      I4 => instruction(13),
                      I5 => '1',
                      O5 => out_port(i),
                      O6 => out_port(i+1));

          end generate second_operand;

          end generate data_path_loop1;


end arch;

