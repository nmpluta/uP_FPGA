library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library unisim;
use unisim.vcomponents.all;

entity uart6_kc705 is
        Port    (
                        Ld        : out std_logic_vector(7 downto 0);
                        clk200_p  : in std_logic;
                        clk200_n  : in std_logic
                );
end uart6_kc705;

architecture Behavioral of uart6_kc705 is

  component kcpsm6
        generic(
                        hwbuild                 : std_logic_vector(7 downto 0) := X"00";
                        interrupt_vector        : std_logic_vector(11 downto 0) := X"3FF";
                        scratch_pad_memory_size : integer := 64);
           port(
                        address                 : out std_logic_vector(11 downto 0);
                        instruction             : in std_logic_vector(17 downto 0);
                        bram_enable             : out std_logic;
                        in_port                 : in std_logic_vector(7 downto 0);
                        out_port                : out std_logic_vector(7 downto 0);
                        port_id                 : out std_logic_vector(7 downto 0);
                        write_strobe            : out std_logic;
                        k_write_strobe          : out std_logic;
                        read_strobe             : out std_logic;
                        interrupt               : in std_logic;
                        interrupt_ack           : out std_logic;
                        sleep                   : in std_logic;
                        reset                   : in std_logic;
                        clk                     : in std_logic
                );
  end component;

  component auto_baud_rate_control
    generic(
                C_FAMILY : string := "S6";
                C_RAM_SIZE_KWORDS : integer := 1;
                C_JTAG_LOADER_ENABLE : integer := 0);
    Port(
                address : in std_logic_vector(11 downto 0);
                instruction : out std_logic_vector(17 downto 0);
                enable : in std_logic;
                rdl : out std_logic;
                clk : in std_logic
        );
  end component;

signal               clk200 : std_logic;
signal                  clk : std_logic;
signal              address : std_logic_vector(11 downto 0);
signal          instruction : std_logic_vector(17 downto 0);
signal          bram_enable : std_logic;
signal              in_port : std_logic_vector(7 downto 0);
signal             out_port : std_logic_vector(7 downto 0);
signal              port_id : std_logic_vector(7 downto 0);
signal         write_strobe : std_logic;
signal       k_write_strobe : std_logic;
signal          read_strobe : std_logic;
signal            interrupt : std_logic;
signal        interrupt_ack : std_logic;
signal         kcpsm6_sleep : std_logic;
signal         kcpsm6_reset : std_logic;
signal                  rdl : std_logic;

begin

  diff_clk_buffer: IBUFGDS
    port map (  I => clk200_p,
               IB => clk200_n,
                O => clk200);

  buffer200: BUFG
    port map (   I => clk200,
                 O => clk);

  processor: kcpsm6
    generic map(    hwbuild                 => X"41",    -- 41 hex is ASCII Character "A"
                    interrupt_vector        => X"7FF",
                    scratch_pad_memory_size => 64
                )
    port map(
                    address                 => address,
                    instruction             => instruction,
                    bram_enable             => bram_enable,
                    port_id                 => port_id,
                    write_strobe            => write_strobe,
                    k_write_strobe          => k_write_strobe,
                    out_port                => out_port,
                    read_strobe             => read_strobe,
                    in_port                 => (X"00"),
                    interrupt               => '0',
                    sleep                   => '0',
                    reset                   => rdl,
                    clk                     => clk
              );

  program_rom: auto_baud_rate_control
    generic map(
                    C_FAMILY              => "7S",
                    C_RAM_SIZE_KWORDS     => 2,
                    C_JTAG_LOADER_ENABLE  => 1
                )
    port map(
                    address               => address,
                    instruction           => instruction,
                    enable                => bram_enable,
                    rdl                   => rdl,
                    clk                   => clk
            );


  output_ports: process(clk)
  begin
    if clk'event and clk = '1' then

        -- 'write_strobe' is used to qualify all writes to general output ports.
        if write_strobe = '1' then

          -- Write to UART at port addresses 01 hex
          -- See below this clocked process for the combinatorial decode required.

          -- Write to 'set_baud_rate' at port addresses 02 hex
          -- This value is set by KCPSM6 to define the BAUD rate of the UART.
          -- See the 'UART baud rate' section for details.
          Ld <= out_port;

        end if;
      end if;
      end process;
end Behavioral;