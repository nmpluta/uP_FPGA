library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.VCOMPONENTS.ALL;

entity picoblaze_top is
        Port(
                clk       : in std_logic;
                Sw        : in  std_logic_vector(7 downto 0);
                Ld        : out std_logic_vector(7 downto 0)
        );
end picoblaze_top;

architecture Behavioral of picoblaze_top is

        component picoblaze
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
        end component;

        component program
        generic(
                        C_FAMILY                : string := "S6";
                        C_RAM_SIZE_KWORDS       : integer := 1;
                        C_JTAG_LOADER_ENABLE    : integer := 0);
        Port(
                        clk             : in std_logic;
                        rdl             : out std_logic;
                        enable          : in std_logic;
                        address         : in std_logic_vector(11 downto 0);
                        instruction     : out std_logic_vector(17 downto 0)
                );
        end component;

        signal clk_uP           : std_logic;
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

        processor: picoblaze
        port map(
                        clk                     => clk,
                        reset                   => rdl,
                        in_port                 => in_port,
                        instruction             => instruction,
                        bram_enable             => bram_enable,
                        write_strobe            => write_strobe,
                        read_strobe             => read_strobe,
                        out_port                => out_port,
                        port_id                 => port_id,
                        address                 => address
                );

        program_rom: program
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