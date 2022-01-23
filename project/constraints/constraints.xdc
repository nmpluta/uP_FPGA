## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

set_property PACKAGE_PIN V17 [get_ports {Sw[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {Sw[1]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {Sw[2]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {Sw[3]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {Sw[4]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {Sw[5]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {Sw[6]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {Sw[7]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw[7]}]
# LED
set_property PACKAGE_PIN U16 [get_ports {Ld[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[0]}]
set_property PACKAGE_PIN E19 [get_ports {Ld[1]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[1]}]
set_property PACKAGE_PIN U19 [get_ports {Ld[2]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[2]}]
set_property PACKAGE_PIN V19 [get_ports {Ld[3]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[3]}]
set_property PACKAGE_PIN W18 [get_ports {Ld[4]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[4]}]
set_property PACKAGE_PIN U15 [get_ports {Ld[5]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[5]}]
set_property PACKAGE_PIN U14 [get_ports {Ld[6]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[6]}]
set_property PACKAGE_PIN V14 [get_ports {Ld[7]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld[7]}]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]