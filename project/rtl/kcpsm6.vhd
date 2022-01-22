library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity kcpsm6 is
  generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                  interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
           scratch_pad_memory_size : integer := 64);
  port (                   address : out std_logic_vector(11 downto 0);
                       instruction : in std_logic_vector(17 downto 0);
                       bram_enable : out std_logic;
                           in_port : in std_logic_vector(7 downto 0);
                          out_port : out std_logic_vector(7 downto 0);
                           port_id : out std_logic_vector(7 downto 0);
                      write_strobe : out std_logic;
                    k_write_strobe : out std_logic;
                       read_strobe : out std_logic;
                         interrupt : in std_logic;
                     interrupt_ack : out std_logic;
                             sleep : in std_logic;
                             reset : in std_logic;
                               clk : in std_logic);
  end kcpsm6;
--
-------------------------------------------------------------------------------------------
--
-- Start of Main Architecture for kcpsm6
--
architecture low_level_definition of kcpsm6 is
--
-------------------------------------------------------------------------------------------
--
-- Components
--
-------------------------------------------------------------------------------------------
--

--
-- declaration of alu_decode
--
  component alu_decode
    port(
      clk : in std_logic;

      instruction :       in std_logic_vector(17 downto 0);
      carry_flag :        in std_logic;
      arith_logical_sel : out std_logic_vector(2 downto 0);
      arith_carry_in :    out std_logic;
      alu_mux_sel :       out std_logic_vector(1 downto 0));
  end component;


--
-------------------------------------------------------------------------------------------
--
-- Signals used in kcpsm6
--
-------------------------------------------------------------------------------------------
--
-- State Machine and Interrupt
--
signal          t_state_value : std_logic_vector(2 downto 1);
signal                t_state : std_logic_vector(2 downto 1);
signal              run_value : std_logic;
signal                    run : std_logic;
signal   internal_reset_value : std_logic;
signal         internal_reset : std_logic;
signal             sync_sleep : std_logic;
signal        int_enable_type : std_logic;
signal interrupt_enable_value : std_logic;
signal       interrupt_enable : std_logic;
signal         sync_interrupt : std_logic;

--
-- Arithmetic and Logical Functions
--
signal      arith_logical_sel : std_logic_vector(2 downto 0);
signal         arith_carry_in : std_logic;
signal      arith_carry_value : std_logic;
signal            arith_carry : std_logic;
signal     half_arith_logical : std_logic_vector(7 downto 0);
signal     logical_carry_mask : std_logic_vector(7 downto 0);
signal    carry_arith_logical : std_logic_vector(7 downto 0);
signal    arith_logical_value : std_logic_vector(7 downto 0);
signal   arith_logical_result : std_logic_vector(7 downto 0);
--
-- ALU structure
--
signal             alu_result : std_logic_vector(7 downto 0);
signal            alu_mux_sel : std_logic_vector(1 downto 0);
--
-- Strobes
--
signal            strobe_type : std_logic;
signal     write_strobe_value : std_logic;
signal   k_write_strobe_value : std_logic;
signal      read_strobe_value : std_logic;
--
-- Flags
--
signal       flag_enable_type : std_logic;
signal      flag_enable_value : std_logic;
signal            flag_enable : std_logic;
signal      shift_carry_value : std_logic;
signal            shift_carry : std_logic;
signal       carry_flag_value : std_logic;
signal             carry_flag : std_logic;

signal    use_zero_flag_value : std_logic;
signal          use_zero_flag : std_logic;
signal    drive_carry_in_zero : std_logic;
signal          carry_in_zero : std_logic;
signal             lower_zero : std_logic;
signal         lower_zero_sel : std_logic;
signal       carry_lower_zero : std_logic;
signal            middle_zero : std_logic;
signal        middle_zero_sel : std_logic;
signal      carry_middle_zero : std_logic;
signal         upper_zero_sel : std_logic;
signal        zero_flag_value : std_logic;
signal              zero_flag : std_logic;
--
-- Scratch Pad Memory
--
signal       spm_enable_value : std_logic;
signal             spm_enable : std_logic;
signal           spm_ram_data : std_logic_vector(7 downto 0);
signal               spm_data : std_logic_vector(7 downto 0);
--
-- Registers
--
signal           regbank_type : std_logic;
signal             bank_value : std_logic;
signal                   bank : std_logic;
signal          loadstar_type : std_logic;
signal         sx_addr4_value : std_logic;
signal   register_enable_type : std_logic;
signal  register_enable_value : std_logic;
signal        register_enable : std_logic;
signal                sx_addr : std_logic_vector(4 downto 0);
signal                sy_addr : std_logic_vector(4 downto 0);
signal                     sx : std_logic_vector(7 downto 0);
signal                     sy : std_logic_vector(7 downto 0);
--
-- Second Operand
--
signal               sy_or_kk : std_logic_vector(7 downto 0);
--
-- Program Counter
--
signal       pc_move_is_valid : std_logic;
signal              move_type : std_logic;
signal           returni_type : std_logic;
signal                pc_mode : std_logic_vector(2 downto 0);
signal        register_vector : std_logic_vector(11 downto 0);
signal                half_pc : std_logic_vector(11 downto 0);
signal               carry_pc : std_logic_vector(10 downto 0);
signal               pc_value : std_logic_vector(11 downto 0);
signal                     pc : std_logic_vector(11 downto 0);
signal              pc_vector : std_logic_vector(11 downto 0);
--
-- Program Counter Stack
--
signal           stack_memory : std_logic_vector(11 downto 0);
signal          return_vector : std_logic_vector(11 downto 0);
signal     half_pointer_value : std_logic_vector(4 downto 0);
signal     feed_pointer_value : std_logic_vector(4 downto 0);
signal    stack_pointer_carry : std_logic_vector(4 downto 0);

begin

  --
  -------------------------------------------------------------------------------------------
  --
  -- State Machine and Control
  --
  --
  --     1 x LUT6
  --     4 x LUT6_2
  --     9 x FD
  --
  -------------------------------------------------------------------------------------------
  --

  reset_lut: LUT6_2
  generic map (INIT => X"FFFFF55500000EEE")
  port map( I0 => run,
            I1 => internal_reset,
            I2 => stack_pointer_carry(4),
            I3 => t_state(2),
            I4 => reset,
            I5 => '1',
            O5 => run_value,
            O6 => internal_reset_value);

  run_flop: FD
  port map (  D => run_value,
              Q => run,
              C => clk);

  internal_reset_flop: FD
  port map (  D => internal_reset_value,
              Q => internal_reset,
              C => clk);

  sync_sleep_flop: FD
  port map (  D => sleep,
              Q => sync_sleep,
              C => clk);

  t_state_lut: LUT6_2
  generic map (INIT => X"0083000B00C4004C")
  port map( I0 => t_state(1),
            I1 => t_state(2),
            I2 => sync_sleep,
            I3 => internal_reset,
            I4 => '0',
            I5 => '1',
            O5 => t_state_value(1),
            O6 => t_state_value(2));

  t_state1_flop: FD
  port map (  D => t_state_value(1),
              Q => t_state(1),
              C => clk);

  t_state2_flop: FD
  port map (  D => t_state_value(2),
              Q => t_state(2),
              C => clk);


  int_enable_type_lut: LUT6_2
  generic map (INIT => X"0010000000000800")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => instruction(17),
            I5 => '1',
            O5 => loadstar_type,
            O6 => int_enable_type);

  interrupt_enable_lut: LUT6
  generic map (INIT => X"000000000000CAAA")
  port map( I0 => interrupt_enable,
            I1 => instruction(0),
            I2 => int_enable_type,
            I3 => t_state(1),
            I4 => '0',
            I5 => internal_reset,
             O => interrupt_enable_value);

  interrupt_enable_flop: FD
  port map (  D => interrupt_enable_value,
              Q => interrupt_enable,
              C => clk);
  active_interrupt_lut: LUT6_2
  generic map (INIT => X"CC33FF0080808080")
  port map( I0 => interrupt_enable,
            I1 => t_state(2),
            I2 => sync_interrupt,
            I3 => bank,
            I4 => loadstar_type,
            I5 => '1',
            O6 => sx_addr4_value);

  -------------------------------------------------------------------------------------------
  --
  -- Decoders
  --
  --
  --     2 x LUT6
  --    10 x LUT6_2
  --     2 x FD
  --     6 x FDR
  --
  -------------------------------------------------------------------------------------------
  --

  --
  -- Decoding for Program Counter and Stack
  --

  pc_move_is_valid_lut: LUT6
  generic map (INIT => X"5A3CFFFF00000000")
  port map( I0 => carry_flag,
            I1 => zero_flag,
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => instruction(17),
             O => pc_move_is_valid);

  move_type_lut: LUT6_2
  generic map (INIT => X"7777027700000200")
  port map( I0 => instruction(12),
            I1 => instruction(13),
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => '1',
            O5 => returni_type,
            O6 => move_type);

  pc_mode1_lut: LUT6_2
  generic map (INIT => X"0000F000000023FF")
  port map( I0 => instruction(12),
            I1 => returni_type,
            I2 => move_type,
            I3 => pc_move_is_valid,
            I4 => '0',
            I5 => '1',
            O5 => pc_mode(0),
            O6 => pc_mode(1));

  pc_mode2_lut: LUT6
  generic map (INIT => X"FFFFFFFF00040000")
  port map( I0 => instruction(12),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => instruction(17),
            I5 => '0',
             O => pc_mode(2));

  --
  -- Decoding for ALU
  --

  decode: alu_decode
    port map(
      clk => clk,
      instruction => instruction,
      carry_flag => carry_flag,
      arith_logical_sel => arith_logical_sel,
      arith_carry_in => arith_carry_in,
      alu_mux_sel => alu_mux_sel);


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

  flag_enable_flop: FDR
  port map (  D => flag_enable_value,
              Q => flag_enable,
              R => '0',
              C => clk);

  register_enable_flop: FDR
  port map (  D => register_enable_value,
              Q => register_enable,
              R => '0',
              C => clk);

  spm_enable_lut: LUT6_2
  generic map (INIT => X"8000000020000000")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(17),
            I3 => strobe_type,
            I4 => t_state(1),
            I5 => '1',
            O5 => k_write_strobe_value,
            O6 => spm_enable_value);

  k_write_strobe_flop: FDR
  port map (  D => k_write_strobe_value,
              Q => k_write_strobe,
              R => '0',
              C => clk);

  spm_enable_flop: FDR
  port map (  D => spm_enable_value,
              Q => spm_enable,
              R => '0',
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

  write_strobe_flop: FDR
  port map (  D => write_strobe_value,
              Q => write_strobe,
              R => '0',
              C => clk);

  read_strobe_flop: FDR
  port map (  D => read_strobe_value,
              Q => read_strobe,
              R => '0',
              C => clk);

  --
  -------------------------------------------------------------------------------------------
  --
  -- Register bank control
  --
  --
  --     2 x LUT6
  --     1 x FDR
  --     1 x FD
  --
  -------------------------------------------------------------------------------------------
  --
  regbank_type_lut: LUT6
  generic map (INIT => X"0080020000000000")
  port map( I0 => instruction(12),
            I1 => instruction(13),
            I2 => instruction(14),
            I3 => instruction(15),
            I4 => instruction(16),
            I5 => instruction(17),
             O => regbank_type);

  bank_lut: LUT6
  generic map (INIT => X"ACACFF00FF00FF00")
  port map( I0 => instruction(0),
            I1 => '0',
            I2 => instruction(16),
            I3 => bank,
            I4 => regbank_type,
            I5 => t_state(1),
             O => bank_value);

  bank_flop: FDR
  port map (  D => bank_value,
              Q => bank,
              R => internal_reset,
              C => clk);

  sx_addr4_flop: FD
  port map (  D => sx_addr4_value,
              Q => sx_addr(4),
              C => clk);

  sx_addr(3 downto 0) <= instruction(11 downto 8);
  sy_addr <= bank & instruction(7 downto 4);

  --
  -------------------------------------------------------------------------------------------
  --
  -- Flags
  --
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

  arith_carry_xorcy: XORCY
  port map( LI => '0',
            CI => carry_arith_logical(7),
             O => arith_carry_value);

  arith_carry_flop: FD
  port map (  D => arith_carry_value,
              Q => arith_carry,
              C => clk);


  shift_carry_lut: LUT6
  generic map (INIT => X"FFFFAACCF0F0F0F0")
  port map( I0 => sx(0),
            I1 => sx(7),
            I2 => '0',
            I3 => instruction(3),
            I4 => instruction(7),
            I5 => instruction(16),
             O => shift_carry_value);

  shift_carry_flop: FD
  port map (  D => shift_carry_value,
              Q => shift_carry,
              C => clk);

  carry_flag_lut: LUT6_2
  generic map (INIT => X"3333AACCF0AA0000")
  port map( I0 => shift_carry,
            I1 => arith_carry,
            I2 => '0',
            I3 => instruction(14),
            I4 => instruction(15),
            I5 => instruction(16),
            O5 => drive_carry_in_zero,
            O6 => carry_flag_value);

  carry_flag_flop: FDRE
  port map (  D => carry_flag_value,
              Q => carry_flag,
             CE => flag_enable,
              R => internal_reset,
              C => clk);

  init_zero_muxcy: MUXCY
  port map( DI => drive_carry_in_zero,
            CI => '0',
             S => carry_flag_value,
             O => carry_in_zero);

  use_zero_flag_lut: LUT6_2
  generic map (INIT => X"A280000000F000F0")
  port map( I0 => instruction(13),
            I1 => instruction(14),
            I2 => instruction(15),
            I3 => instruction(16),
            I4 => '1',
            I5 => '1',
            O5 => strobe_type,
            O6 => use_zero_flag_value);

  use_zero_flag_flop: FD
  port map (  D => use_zero_flag_value,
              Q => use_zero_flag,
              C => clk);

  lower_zero_lut: LUT6_2
  generic map (INIT => X"0000000000000001")
  port map( I0 => alu_result(0),
            I1 => alu_result(1),
            I2 => alu_result(2),
            I3 => alu_result(3),
            I4 => alu_result(4),
            I5 => '1',
            O5 => lower_zero,
            O6 => lower_zero_sel);

  lower_zero_muxcy: MUXCY
  port map( DI => lower_zero,
            CI => carry_in_zero,
             S => lower_zero_sel,
             O => carry_lower_zero);

  middle_zero_lut: LUT6_2
  generic map (INIT => X"0000000D00000000")
  port map( I0 => use_zero_flag,
            I1 => zero_flag,
            I2 => alu_result(5),
            I3 => alu_result(6),
            I4 => alu_result(7),
            I5 => '1',
            O5 => middle_zero,
            O6 => middle_zero_sel);

  middle_zero_muxcy: MUXCY
  port map( DI => middle_zero,
            CI => carry_lower_zero,
             S => middle_zero_sel,
             O => carry_middle_zero);

  upper_zero_lut: LUT6
  generic map (INIT => X"FBFF000000000000")
  port map( I0 => instruction(14),
            I1 => instruction(15),
            I2 => instruction(16),
            I3 => '1',
            I4 => '1',
            I5 => '1',
             O => upper_zero_sel);

  upper_zero_muxcy: MUXCY
  port map( DI => '0',
            CI => carry_middle_zero,
             S => upper_zero_sel,
             O => zero_flag_value);

  zero_flag_flop: FDRE
  port map (  D => zero_flag_value,
              Q => zero_flag,
             CE => flag_enable,
              R => internal_reset,
              C => clk);

  --
  -------------------------------------------------------------------------------------------
  --
  -- 12-bit Program Address Generation
  --
  -------------------------------------------------------------------------------------------
  --

  --
  -- Prepare 12-bit vector from the sX and sY register outputs.
  --

  register_vector <= sx(3 downto 0) & sy;


  address_loop: for i in 0 to 11 generate
  begin

    --
    -------------------------------------------------------------------------------------------
    --
    -- Selection of vector to load program counter
    --
    -- instruction(12)
    --              0  Constant aaa from instruction(11:0)
    --              1  Return vector from stack
    --
    -- 'aaa' is used during 'JUMP aaa', 'JUMP c, aaa', 'CALL aaa' and 'CALL c, aaa'.
    -- Return vector is used during 'RETURN', 'RETURN c', 'RETURN&LOAD' and 'RETURNI'.
    --
    --     6 x LUT6_2
    --     12 x FD
    --
    -------------------------------------------------------------------------------------------
    --

    --
    -- Pipeline output of the stack memory
    --

    return_vector_flop: FD
    port map (  D => stack_memory(i),
                Q => return_vector(i),
                C => clk);

    output_data: if (i rem 2)=0 generate
    begin

      pc_vector_mux_lut: LUT6_2
      generic map (INIT => X"FF00F0F0CCCCAAAA")
      port map( I0 => instruction(i),
                I1 => return_vector(i),
                I2 => instruction(i+1),
                I3 => return_vector(i+1),
                I4 => instruction(12),
                I5 => '1',
                O5 => pc_vector(i),
                O6 => pc_vector(i+1));

    end generate output_data;

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
    -------------------------------------------------------------------------------------------
    --


    pc_flop: FDRE
    port map (  D => pc_value(i),
                Q => pc(i),
                R => internal_reset,
               CE => t_state(1),
                C => clk);


    lsb_pc: if i=0 generate
    begin

      low_int_vector: if interrupt_vector(i)='0' generate
      begin

        pc_lut: LUT6
        generic map (INIT => X"00AA000033CC0F00")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      end generate low_int_vector;

      high_int_vector: if interrupt_vector(i)='1' generate
      begin

        pc_lut: LUT6
        generic map (INIT => X"00AA00FF33CC0F00")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      end generate high_int_vector;

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

      low_int_vector: if interrupt_vector(i)='0' generate
      begin

        pc_lut: LUT6
        generic map (INIT => X"00AA0000CCCCF000")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      end generate low_int_vector;

      high_int_vector: if interrupt_vector(i)='1' generate
      begin

        pc_lut: LUT6
        generic map (INIT => X"00AA00FFCCCCF000")
        port map( I0 => register_vector(i),
                  I1 => pc_vector(i),
                  I2 => pc(i),
                  I3 => pc_mode(0),
                  I4 => pc_mode(1),
                  I5 => pc_mode(2),
                   O => half_pc(i));

      end generate high_int_vector;

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

  stack_loop: for i in 0 to 4 generate
  begin

    lsb_stack: if i=0 generate
    begin
      stack_muxcy: MUXCY
      port map( DI => feed_pointer_value(i),
                CI => '0',
                 S => half_pointer_value(i),
                 O => stack_pointer_carry(i));

    end generate lsb_stack;

    upper_stack: if i>0 generate
    begin
      stack_muxcy: MUXCY
      port map( DI => feed_pointer_value(i),
                CI => stack_pointer_carry(i-1),
                 S => half_pointer_value(i),
                 O => stack_pointer_carry(i));

    end generate upper_stack;
  end generate stack_loop;

  --
  -------------------------------------------------------------------------------------------
  --
  -- 8-bit Data Path
  --
  -------------------------------------------------------------------------------------------
  --
  data_path_loop: for i in 0 to 7 generate
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
    --
    --
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
    --
    --
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

    --
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
                 O => carry_arith_logical(i));

      arith_logical_xorcy: XORCY
      port map( LI => half_arith_logical(i),
                CI => arith_carry_in,
                 O => arith_logical_value(i));

    end generate lsb_arith_logical;

    upper_arith_logical: if i>0 generate
    begin

      arith_logical_muxcy: MUXCY
      port map( DI => logical_carry_mask(i),
                CI => carry_arith_logical(i-1),
                 S => half_arith_logical(i),
                 O => carry_arith_logical(i));

      arith_logical_xorcy: XORCY
      port map( LI => half_arith_logical(i),
                CI => carry_arith_logical(i-1),
                 O => arith_logical_value(i));

    end generate upper_arith_logical;

    --
    -------------------------------------------------------------------------------------------
    --
    -- Multiplex outputs from ALU functions, scratch pad memory and input port.
    --
    -- alu_mux_sel (1) (0)
    --              0   0  Arithmetic and Logical Instructions
    --              0   1  Shift and Rotate Instructions
    --              1   0  Input Port
    --              1   1  Scratch Pad Memory
    --
    --     8 x LUT6
    --
    -------------------------------------------------------------------------------------------
    --

    alu_mux_lut: LUT6
    generic map (INIT => X"FF00F0F0CCCCAAAA")
    port map( I0 => arith_logical_result(i),
              I1 => '0',
              I2 => in_port(i),
              I3 => spm_data(i),
              I4 => alu_mux_sel(0),
              I5 => alu_mux_sel(1),
               O => alu_result(i));

    --
    -------------------------------------------------------------------------------------------
    --
    -- Scratchpad Memory with output register.
    --
    -- The size of the scratch pad memory is defined by the 'scratch_pad_memory_size' generic.
    -- The default size is 64 bytes the same as KCPSM3 but this can be increased to 128 or 256
    -- bytes at an additional cost of 2 and 6 Slices.
    --
    --
    -- 2 x RAM64M    (64 bytes).
    --
    -- 8 x FD.
    --
    -------------------------------------------------------------------------------------------
    --

    small_spm: if scratch_pad_memory_size = 64 generate
    begin

      spm_flop: FD
      port map ( D => spm_ram_data(i),
                 Q => spm_data(i),
                 C => clk);

      small_spm_ram: if (i=0 or i=4) generate
      begin

        spm_ram: RAM64M
        generic map ( INIT_A => X"0000000000000000",
                      INIT_B => X"0000000000000000",
                      INIT_C => X"0000000000000000",
                      INIT_D => X"0000000000000000")
        port map (   DOA => spm_ram_data(i),
                     DOB => spm_ram_data(i+1),
                     DOC => spm_ram_data(i+2),
                     DOD => spm_ram_data(i+3),
                   ADDRA => sy_or_kk(5 downto 0),
                   ADDRB => sy_or_kk(5 downto 0),
                   ADDRC => sy_or_kk(5 downto 0),
                   ADDRD => sy_or_kk(5 downto 0),
                     DIA => sx(i),
                     DIB => sx(i+1),
                     DIC => sx(i+2),
                     DID => sx(i+3),
                      WE => spm_enable,
                    WCLK => clk );
      end generate small_spm_ram;
    end generate small_spm;
  end generate data_path_loop;

  --
  -------------------------------------------------------------------------------------------
  --
  -- Two Banks of 16 General Purpose Registers.
  --
  -- sx_addr - Address for sX is formed by bank select and instruction[11:8]
  -- sy_addr - Address for sY is formed by bank select and instruction[7:4]
  --
  -- 2 Slices
  --     2 x RAM32M
  --
  -------------------------------------------------------------------------------------------
  --

  lower_reg_banks : RAM32M
  generic map (INIT_A => X"0000000000000000",
               INIT_B => X"0000000000000000",
               INIT_C => X"0000000000000000",
               INIT_D => X"0000000000000000")
  port map (    DOA => sy(1 downto 0),
                DOB => sx(1 downto 0),
                DOC => sy(3 downto 2),
                DOD => sx(3 downto 2),
              ADDRA => sy_addr,
              ADDRB => sx_addr,
              ADDRC => sy_addr,
              ADDRD => sx_addr,
                DIA => alu_result(1 downto 0),
                DIB => alu_result(1 downto 0),
                DIC => alu_result(3 downto 2),
                DID => alu_result(3 downto 2),
                 WE => register_enable,
               WCLK => clk );

  upper_reg_banks : RAM32M
  generic map (INIT_A => X"0000000000000000",
               INIT_B => X"0000000000000000",
               INIT_C => X"0000000000000000",
               INIT_D => X"0000000000000000")
  port map (    DOA => sy(5 downto 4),
                DOB => sx(5 downto 4),
                DOC => sy(7 downto 6),
                DOD => sx(7 downto 6),
              ADDRA => sy_addr,
              ADDRB => sx_addr,
              ADDRC => sy_addr,
              ADDRD => sx_addr,
                DIA => alu_result(5 downto 4),
                DIB => alu_result(5 downto 4),
                DIC => alu_result(7 downto 6),
                DID => alu_result(7 downto 6),
                 WE => register_enable,
               WCLK => clk );

  address <= pc;
  bram_enable <= t_state(2);
  port_id <= sy_or_kk;
end low_level_definition;