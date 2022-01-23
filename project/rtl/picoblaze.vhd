library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity picoblaze is
        Port(
                        clk             : in std_logic;
                        reset           : in std_logic;
                        in_port         : in std_logic_vector(7 downto 0);
                        instruction     : in std_logic_vector(17 downto 0);
                        bram_enable     : out std_logic;
                        write_strobe    : out std_logic;
                        read_strobe     : out std_logic;
                        out_port        : out std_logic_vector(7 downto 0);
                        port_id         : out std_logic_vector(7 downto 0);
                        address         : out std_logic_vector(11 downto 0)
        );
  end picoblaze;
--
-------------------------------------------------------------------------------------------
--
-- Start of Main Architecture for picoblaze
--
architecture low_level_definition of picoblaze is
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
    port(
      clk : in std_logic;
      internal_reset : in std_logic;
      t_state : in std_logic_vector(2 downto 1);
      pc_mode : in std_logic_vector(2 downto 0);
      pc_vector : in std_logic_vector(11 downto 0);
      register_vector : in std_logic_vector(11 downto 0);

      pc : out std_logic_vector(11 downto 0));
    end component;

    -- Flags
        component flags
        port(
                clk                     : in std_logic;
                carry_arith_logical     : in std_logic;
                flag_enable             : in std_logic;
                internal_reset          : in std_logic;
                alu_result              : in std_logic_vector(7 downto 0);
                instruction             : in std_logic_vector(17 downto 0);
                carry_flag              : out std_logic;
                strobe_type             : out std_logic
        );
        end component;


        component state_control
        port(
                clk                     : in std_logic;
                reset                   : in std_logic;
                internal_reset_out      : out std_logic;
                t_state_out             : out std_logic_vector(2 downto 1)
        );
        end component;

        component adress_generator
        port(
                instruction           : in std_logic_vector(17 downto 0);
                pc_vector             : out std_logic_vector(11 downto 0)
        );
        end component;
        --
        -- State Machine and Interrupt
        --
        signal t_state : std_logic_vector(2 downto 1);
        signal internal_reset : std_logic;

        --
        -- Arithmetic and Logical Functions
        --
        signal arith_logical_sel : std_logic_vector(2 downto 0);
        signal arith_carry_in : std_logic;
        signal arith_carry_value : std_logic;
        signal arith_carry : std_logic;
        signal half_arith_logical : std_logic_vector(7 downto 0);
        signal logical_carry_mask : std_logic_vector(7 downto 0);
        signal carry_arith_logical : std_logic_vector(7 downto 0);
        signal arith_logical_value : std_logic_vector(7 downto 0);
        signal arith_logical_result : std_logic_vector(7 downto 0);
        --
        -- ALU structure
        --
        signal alu_result : std_logic_vector(7 downto 0);
        signal alu_mux_sel : std_logic_vector(1 downto 0);
        --
        -- Strobes
        --
        signal strobe_type : std_logic;
        --
        -- Flags
        --
        signal flag_enable : std_logic;
        signal carry_flag : std_logic;
        signal zero_flag : std_logic;

        --
        -- Registers
        --
        signal register_enable : std_logic;
        signal sx_addr : std_logic_vector(4 downto 0);
        signal sy_addr : std_logic_vector(4 downto 0);
        signal sx : std_logic_vector(7 downto 0);
        signal sy : std_logic_vector(7 downto 0);
        --
        -- Second Operand
        --
        signal sy_or_kk : std_logic_vector(7 downto 0);
        --
        -- Program Counter
        --
        signal pc_mode : std_logic_vector(2 downto 0);
        signal register_vector : std_logic_vector(11 downto 0);
        signal pc : std_logic_vector(11 downto 0);
        signal pc_vector : std_logic_vector(11 downto 0);

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
        my_state_control: state_control
        port map(
                        clk                     => clk,
                        t_state_out             => t_state,
                        internal_reset_out      => internal_reset,
                        reset                   => reset
                );

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
                        clk             => clk,
                        instruction     => instruction,
                        t_state         => t_state,
                        strobe_type     => strobe_type,

                        flag_enable     => flag_enable,
                        register_enable => register_enable,
                        read_strobe     => read_strobe,
                        write_strobe    => write_strobe
                );

        my_flags: flags
        port map(
                        clk                     => clk,
                        internal_reset          => internal_reset,
                        flag_enable             => flag_enable,
                        instruction             => instruction,
                        carry_arith_logical     => carry_arith_logical(7),
                        alu_result              => alu_result,
                        strobe_type             => strobe_type,
                        carry_flag              => carry_flag
                );
  --
  -------------------------------------------------------------------------------------------
  --
  -- 12-bit Program Address Generation
  --
  -------------------------------------------------------------------------------------------
  -- Prepare 12-bit vector from the sX and sY register outputs.
  --

--     --
--     -------------------------------------------------------------------------------------------
--     --
--     -- Selection of vector to load program counter
--     --
--     -- instruction(12)
--     --              0  Constant aaa from instruction(11:0)
--     --              1  Return vector from stack
--     --
--     -- 'aaa' is used during 'JUMP aaa', 'JUMP c, aaa', 'CALL aaa' and 'CALL c, aaa'.
--     -- Return vector is used during 'RETURN', 'RETURN c', 'RETURN&LOAD' and 'RETURNI'.
--     --
--     --     6 x LUT6_2
--     --     12 x FD
--     --
--     -------------------------------------------------------------------------------------------
--     -- Pipeline output of the stack memory
--     --


        my_adress_generator: adress_generator
        port map(
                        instruction     => instruction,
                        pc_vector       => pc_vector
                );

  --
  -------------------------------------------------------------------------------------------
  --
  -- Program Counter
  --
  prog_count: program_counter
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

  sx_addr(3 downto 0) <= instruction(11 downto 8);
  sy_addr <= '0' & instruction(7 downto 4);

  register_vector <= sx(3 downto 0) & sy;
end low_level_definition;