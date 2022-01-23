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

    --
    -------------------------------------------------------------------------------------------
    --
    -- Program Counter
    --
    -- Reset by internal_reset has highest priority.
    -- Enabled by t_state(1) has second priority.
    --
    -- The function performed is defined by pc_mode(2:0).
    --
    -- pc_mode (2) (1) (0)
    --          0   0   1  pc+1 for normal program flow.
    --          1   0   0  Forces interrupt vector value (+0) during active interrupt.
    --                     The vector is defined by a generic with default value FF0 hex.
    --          1   1   0  register_vector (+0) for 'JUMP (sX, sY)' and 'CALL (sX, sY)'.
    --          0   1   0  pc_vector (+0) for 'JUMP/CALL aaa' and 'RETURNI'.
    --          0   1   1  pc_vector+1 for 'RETURN'.
    --
    -- Note that pc_mode(0) is High during operations that require an increment to occur.
    -- The LUT6 associated with the LSB must invert pc or pc_vector in these cases and
    -- pc_mode(0) also has to be connected to the start of the carry chain.
    --
    -- 3 Slices
    --     12 x LUT6
    --     11 x MUXCY
    --     12 x XORCY
    --     12 x FDRE
    --
    --------

--**********************************************************************************
--
-------------------------------------------------------------------------------------------
--
-- Start of program_counter circuit description
--
-------------------------------------------------------------------------------------------
--
begin
  address_loop: for i in 0 to 11 generate
    begin
    -- 
    -- Program Counter
    --
    
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

      --
      -- Carry chain implementing remainder of increment function
      --
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
