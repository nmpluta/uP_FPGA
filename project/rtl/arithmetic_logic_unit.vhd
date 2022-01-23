-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity arithmetic_logic_unit is
  port(
    clk : in std_logic;
    sy_or_kk : in std_logic_vector(7 downto 0);
    sx : in std_logic_vector(7 downto 0);
    arith_logical_sel : in std_logic_vector(2 downto 0);
    arith_carry_in : in std_logic;
    arith_logical_result : out std_logic_vector(7 downto 0);
    carry_arith_logical : out std_logic_vector(7 downto 0));
  end arithmetic_logic_unit;

architecture arch of arithmetic_logic_unit is

-- internal signal
signal logical_carry_mask : std_logic_vector(7 downto 0);
signal half_arith_logical : std_logic_vector(7 downto 0);
signal arith_logical_value : std_logic_vector(7 downto 0);
signal carry_arith_logical_internal : std_logic_vector(7 downto 0);

--**********************************************************************************
--
-------------------------------------------------------------------------------------------
--
-- Start of arithmetic_logic_unit circuit description
--
-------------------------------------------------------------------------------------------
--
begin
  --
  -------------------------------------------------------------------------------------------
  --
  -- 8-bit Data Path
  --
  -------------------------------------------------------------------------------------------
  --
  data_path_loop: for i in 0 to 7 generate
  begin
    -------------------------------------------------------------------------------------------
    --
    -- Arithmetic and Logical operations
    --
    -- Definition of....
    --    ADD and SUB also used for ADDCY, SUBCY, COMPARE and COMPARECY.
    --    LOAD, AND, OR and XOR also used for LOAD*, RETURN&LOAD, TEST and TESTCY.
    --
    -- arith_logical_sel (2) (1) (0)
    --                    0   0   0  - LOAD
    --                    0   0   1  - AND
    --                    0   1   0  - OR
    --                    0   1   1  - XOR
    --                    1   X   0  - SUB
    --                    1   X   1  - ADD
    --
    -- Includes pipeline stage.
    --
    -- 2 Slices
    --     8 x LUT6_2
    --     8 x MUXCY
    --     8 x XORCY
    --     8 x FD
    --
    -------------------------------------------------------------------------------------------
    --

    arith_logical_lut: LUT6_2
    generic map (INIT => X"69696E8ACCCC0000")
    port map( I0 => sy_or_kk(i),
              I1 => sx(i),
              I2 => arith_logical_sel(0),
              I3 => arith_logical_sel(1),
              I4 => arith_logical_sel(2),
              I5 => '1',
              O5 => logical_carry_mask(i),
              O6 => half_arith_logical(i));

    arith_logical_flop: FD
    port map ( D => arith_logical_value(i),
               Q => arith_logical_result(i),
               C => clk);

    lsb_arith_logical: if i=0 generate
    begin
      arith_logical_muxcy: MUXCY
      port map( DI => logical_carry_mask(i),
                CI => arith_carry_in,
                 S => half_arith_logical(i),
                 O => carry_arith_logical_internal(i));

      arith_logical_xorcy: XORCY
      port map( LI => half_arith_logical(i),
                CI => arith_carry_in,
                 O => arith_logical_value(i));

    end generate lsb_arith_logical;

    upper_arith_logical: if i>0 generate
    begin

      arith_logical_muxcy: MUXCY
      port map( DI => logical_carry_mask(i),
                CI => carry_arith_logical_internal(i-1),
                 S => half_arith_logical(i),
                 O => carry_arith_logical_internal(i));

      arith_logical_xorcy: XORCY
      port map( LI => half_arith_logical(i),
                CI => carry_arith_logical_internal(i-1),
                 O => arith_logical_value(i));

    end generate upper_arith_logical;
  end generate data_path_loop;
  carry_arith_logical <= carry_arith_logical_internal;
end arch;