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
                       read_strobe : out std_logic;
                             reset : in std_logic;
                               clk : in std_logic);
  end kcpsm6;
--
-------------------------------------------------------------------------------------------
--
-- Start of Main Architecture for kcpsm6
--
architecture low_level_definition of kcpsm6 is
  component program_counter_decode
    port(
      clk : in std_logic;
  
      instruction :   in std_logic_vector(17 downto 0);
      carry_flag :    in std_logic;
      zero_flag :     in std_logic;
      pc_mode :       out std_logic_vector(2 downto 0));
  end component;

  component alu_decode
    port(
      clk : in std_logic;

      instruction :       in std_logic_vector(17 downto 0);
      carry_flag :        in std_logic;
      arith_logical_sel : out std_logic_vector(2 downto 0);
      arith_carry_in :    out std_logic;
      alu_mux_sel :       out std_logic_vector(1 downto 0));
  end component;

  component strobe_enables_decode
    port(
      clk : in std_logic;

      instruction :       in std_logic_vector(17 downto 0);
      t_state :           in std_logic_vector(2 downto 1);
      strobe_type :       in std_logic;

      flag_enable :       out std_logic;
      register_enable :   out std_logic;
      read_strobe :       out std_logic;
      write_strobe :      out std_logic);
    end component;

  component program_counter is
    generic(
      interrupt_vector : std_logic_vector(11 downto 0) := X"3FF");
    port(
      clk : in std_logic;
      internal_reset : in std_logic;
      t_state : in std_logic_vector(2 downto 1);
      pc_mode : in std_logic_vector(2 downto 0);
      pc_vector : in std_logic_vector(11 downto 0);
      register_vector : in std_logic_vector(11 downto 0);

      pc : out std_logic_vector(11 downto 0));
    end component;

--
-- State Machine and Interrupt
--
signal          t_state_value : std_logic_vector(2 downto 1);
signal                t_state : std_logic_vector(2 downto 1);
signal              run_value : std_logic;
signal                    run : std_logic;
signal   internal_reset_value : std_logic;
signal         internal_reset : std_logic;

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
--
-- Flags
--
signal       flag_enable_type : std_logic;
signal      flag_enable_value : std_logic;
signal            flag_enable : std_logic;
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
-- Registers
--
signal           regbank_type : std_logic;
signal             bank_value : std_logic;
signal                   bank : std_logic;
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
signal                pc_mode : std_logic_vector(2 downto 0);
signal        register_vector : std_logic_vector(11 downto 0);
signal                half_pc : std_logic_vector(11 downto 0);
signal               carry_pc : std_logic_vector(10 downto 0);
signal               pc_value : std_logic_vector(11 downto 0);
signal                     pc : std_logic_vector(11 downto 0);
signal              pc_vector : std_logic_vector(11 downto 0);

begin

  --
  -------------------------------------------------------------------------------------------
  --
  -- State Machine and Control
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
            I2 => '0',
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

  t_state_lut: LUT6_2
  generic map (INIT => X"0083000B00C4004C")
  port map( I0 => t_state(1),
            I1 => t_state(2),
            I2 => '0',
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
  -------------------------------------------------------------------------------------------
  --
  -- Decoders
  --
  --     2 x LUT6
  --    10 x LUT6_2
  --     2 x FD
  --     6 x FDR
  --
  -------------------------------------------------------------------------------------------
  --
  -- Decoding for Program Counter
  --
  dec_PC: program_counter_decode
    port map(
      clk => clk,

      instruction => instruction,
      carry_flag => carry_flag, 
      zero_flag => zero_flag, 
      pc_mode => pc_mode); 


  --
  -- Decoding for ALU
  --

  dec_alu: alu_decode
    port map(
      clk => clk,
      instruction => instruction,
      carry_flag => carry_flag,
      arith_logical_sel => arith_logical_sel,
      arith_carry_in => arith_carry_in,
      alu_mux_sel => alu_mux_sel);

  --
  -- Decoding for strobes and enables
  --

  dec_str_en: strobe_enables_decode
    port map(
      clk => clk,
      instruction => instruction,
      t_state => t_state,
      strobe_type => strobe_type,

      flag_enable => flag_enable,
      register_enable => register_enable,
      read_strobe => read_strobe,
      write_strobe => write_strobe);

  --
  -------------------------------------------------------------------------------------------
  -- Register bank control
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
  port map (  D => '0',
              Q => sx_addr(4),
              C => clk);

  sx_addr(3 downto 0) <= instruction(11 downto 8);
  sy_addr <= bank & instruction(7 downto 4);

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

  arith_carry_xorcy: XORCY
  port map( LI => '0',
            CI => carry_arith_logical(7),
             O => arith_carry_value);

  arith_carry_flop: FD
  port map (  D => arith_carry_value,
              Q => arith_carry,
              C => clk);

  carry_flag_lut: LUT6_2
  generic map (INIT => X"3333AACCF0AA0000")
  port map( I0 => '0',
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
    -- Pipeline output of the stack memory
    --


    output_data: if (i rem 2)=0 generate
    begin

      pc_vector_mux_lut: LUT6_2
      generic map (INIT => X"FF00F0F0CCCCAAAA")
      port map( I0 => instruction(i),
                I1 => '0',
                I2 => instruction(i+1),
                I3 => '0',
                I4 => instruction(12),
                I5 => '1',
                O5 => pc_vector(i),
                O6 => pc_vector(i+1));

    end generate output_data;
  end generate address_loop;

  --
  ------------------------------------------------------------------------------------------- 
  -- 
  -- Program Counter
  --
  prog_count: program_counter
  generic map(
    interrupt_vector => X"3FF")
  port map(
    clk => clk,
    internal_reset => internal_reset,
    t_state => t_state,
    pc_mode => pc_mode,
    pc_vector => pc_vector,
    register_vector => register_vector,
    pc => pc);

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
              I3 => '0',
              I4 => alu_mux_sel(0),
              I5 => alu_mux_sel(1),
               O => alu_result(i));

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