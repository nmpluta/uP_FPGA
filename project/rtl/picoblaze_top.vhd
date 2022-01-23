library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library unisim;
use unisim.vcomponents.all;

entity picoblaze_top is
        Port(
                        Sw        : in  std_logic_vector(7 downto 0);
                        Ld        : out std_logic_vector(7 downto 0);
                        clk200_p  : in std_logic;
                        clk200_n  : in std_logic
                );
end picoblaze_top;

architecture Behavioral of picoblaze_top is

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
                                read_strobe             : out std_logic;
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

        signal clk              : std_logic;
        signal clk200           : std_logic;
        signal rdl              : std_logic;
        signal bram_enable      : std_logic;
        signal write_strobe     : std_logic;
        signal read_strobe      : std_logic;
        signal interrupt        : std_logic;
        signal interrupt_ack    : std_logic;
        signal kcpsm6_reset     : std_logic;
        signal address          : std_logic_vector(11 downto 0);
        signal instruction      : std_logic_vector(17 downto 0);
        signal in_port          : std_logic_vector(7 downto 0);
        signal out_port         : std_logic_vector(7 downto 0);
        signal port_id          : std_logic_vector(7 downto 0);

begin

        diff_clk_buffer: IBUFGDS
        port map (
                        I => clk200_p,
                        IB => clk200_n,
                        O => clk200
                );

        buffer200: BUFG
        port map (
                        I => clk200,
                        O => clk
                );

        processor: kcpsm6
        generic map(
                        hwbuild                 => X"41",    -- 41 hex is ASCII Character "A"
                        interrupt_vector        => X"7FF",
                        scratch_pad_memory_size => 64
                        )
        port map(
                        address                 => address,
                        instruction             => instruction,
                        bram_enable             => bram_enable,
                        port_id                 => port_id,
                        write_strobe            => write_strobe,
                        out_port                => out_port,
                        read_strobe             => read_strobe,
                        in_port                 => in_port,
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
                if rising_edge(clk) and (write_strobe = '1') then
                        Ld <= out_port;
                end if;
        end process;

        inpput_ports: process(clk)
        begin
                if rising_edge(clk) and (read_strobe = '1') then
                        in_port <= Sw;
                end if;
        end process;
end Behavioral;