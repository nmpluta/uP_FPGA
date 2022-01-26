library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity decode_instructions is
  port(
    clk : in std_logic;

    instruction :       in std_logic_vector(17 downto 0);
    carry_flag :        in std_logic;
    zero_flag :         in std_logic;
    t_state :           in std_logic_vector(2 downto 1);
    strobe_type :       in std_logic;


    pc_mode :           out std_logic_vector(2 downto 0);
    arith_logical_sel : out std_logic_vector(2 downto 0);
    arith_carry_in :    out std_logic;
    alu_mux_sel :       out std_logic_vector(1 downto 0);
    flag_enable :       out std_logic;
    register_enable :   out std_logic;
    read_strobe :       out std_logic;
    write_strobe :      out std_logic);
  end decode_instructions;

architecture arch of decode_instructions is
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

begin

  dec_PC: program_counter_decode
    port map(
      clk => clk,

      instruction => instruction,
      carry_flag => carry_flag,
      zero_flag => zero_flag,
      pc_mode => pc_mode);

  -- Decoding for ALU

  dec_alu: alu_decode
    port map(
      clk => clk,
      instruction => instruction,
      carry_flag => carry_flag,
      arith_logical_sel => arith_logical_sel,
      arith_carry_in => arith_carry_in,
      alu_mux_sel => alu_mux_sel);

  -- Decoding for strobes and enables

  dec_str_en: strobe_enables_decode
    port map(
      clk             => clk,
      instruction     => instruction,
      t_state         => t_state,
      strobe_type     => strobe_type,

      flag_enable     => flag_enable,
      register_enable => register_enable,
      read_strobe     => read_strobe,
      write_strobe    => write_strobe);

end arch;

