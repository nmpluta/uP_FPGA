-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity program_counter is
  port(
    clk : in std_logic;
    internal_reset : in std_logic;
    t_state : in std_logic_vector(2 downto 1);
    pc_mode : in std_logic_vector(2 downto 0);
    pc_vector : in std_logic_vector(11 downto 0);
    register_vector : in std_logic_vector(11 downto 0);

    pc : out std_logic_vector(11 downto 0));
  end program_counter;

architecture arch of program_counter is

-- internal signal
signal  pc_value : std_logic_vector(11 downto 0);
signal  pc_buffer : std_logic_vector(11 downto 0);
signal  half_pc : std_logic_vector(11 downto 0);
signal  carry_pc : std_logic_vector(10 downto 0);

-- Program Counter

begin
  address_loop: for i in 0 to 11 generate
    begin
    
    pc_flop: FDRE
    port map (  D => pc_value(i),
                Q => pc_buffer(i),
                R => internal_reset,
               CE => t_state(1),
                C => clk);

    lsb_pc: if i=0 generate
    begin
        pc_lut: LUT6
        generic map (INIT => X"00AA000033CC0F00")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc_buffer(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      pc_xorcy: XORCY
      port map( LI => half_pc(i),
                CI => '0',
                 O => pc_value(i));

      pc_muxcy: MUXCY
      port map( DI => pc_mode(0),
                CI => '0',
                 S => half_pc(i),
                 O => carry_pc(i));

    end generate lsb_pc;

    upper_pc: if i>0 generate
    begin
        pc_lut: LUT6
        generic map (INIT => X"00AA0000CCCCF000")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc_buffer(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      -- Carry chain implementing remainder of increment function

      pc_xorcy: XORCY
      port map( LI => half_pc(i),
                CI => carry_pc(i-1),
                 O => pc_value(i));

      mid_pc: if i<11 generate
      begin
        pc_muxcy: MUXCY
        port map( DI => '0',
                  CI => carry_pc(i-1),
                   S => half_pc(i),
                   O => carry_pc(i));

      end generate mid_pc;

    end generate upper_pc;
  end generate address_loop;
  pc <= pc_buffer;

end arch;
