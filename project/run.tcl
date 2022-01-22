set project VHDL
set top_module VHDL
set target xc7a35tcpg236-1
# if generate_rtl 1 then during executing bitstream will be created rtl_schematic pdf
set generate_rtl 0
# set path where vivado has to put project and running output
set build_path vivado/build
# set simulation top module
set top_sim_module uart6_kc705

set bitstream_file ${build_path}/${project}.runs/impl_1/${top_module}.bit


proc usage {} {
        puts "usage: vivado -mode tcl -source [info script] -tclargs \[simulation/bitstream/program/run\]"
        exit 1
}

# files for bitstream

proc attach_rtl_files {} {

        remove_files [get_files -quiet]
        read_xdc {
                constraints/uart6_kc705.xdc
        }

        read_vhdl {
                rtl/uart6_kc705.vhd
                rtl/kcpsm6.vhd
                rtl/uart_tx6.vhd
                rtl/uart_rx6.vhd
                rtl/auto_baud_rate_control.vhd
                rtl/alu_decode.vhd
                rtl/strobe_enables_decode.vhd
        }

        # read_verilog {
        # }
}

# files for simulation

proc attach_sim_files {} {

        remove_files [get_files -quiet]

        # if you run simulation for the same top module that bitstream then leave this section otherwise
        # comment attach_rtl_files and uncomment PUT YOUR CODE HERE where you need to add your own sim files

        attach_rtl_files

        #-------------------PUT YOUR CODE HERE-------------------
        # read_xdc {
        #         constraints/Basys3_Master.xdc
        # }

        # read_vhdl {
        #         rtl/sequence_detector_MEALY_FSM.vhd
        # }

        # read_verilog {
        # }

        #  read_mem {
        #          rtl/memory.data
        #  }

        add_files -fileset sim_1 {
                sim/testbench_uart6_kc705.vhd

        }
        #--------------------------------------------------------

        # add_files -fileset sim_1 {
        #         sim/testbench.v
        #         sim/tiff_writer.v
        # }
}

proc check_project {} {
        global project
        global build_path

        set pexist [file exist ${build_path}/${project}.xpr]
        puts "project exists : $pexist"
        if {$pexist == 0} {
                make_project
        } else {
                open_project_f
        }
}

proc make_project {} {
        global project
        global target
        global build_path

        file mkdir ${build_path}
        create_project ${project} ${build_path} -part ${target} -force
}

proc open_project_f {} {
        global project
        global build_path

        open_project ${build_path}/${project}.xpr
}

proc make_bitstream {} {
        global top_module

        attach_rtl_files

        set_property top ${top_module} [current_fileset]
        update_compile_order -fileset sources_1
        update_compile_order -fileset sim_1

        reset_run   synth_1
        launch_runs synth_1 -jobs 8
        wait_on_run synth_1

        reset_run   impl_1
        launch_runs impl_1 -to_step write_bitstream -jobs 8
        wait_on_run impl_1
}

proc program_board {} {
        global bitstream_file

        open_hw
        connect_hw_server
        current_hw_target [get_hw_targets *]
        open_hw_target
        current_hw_device [lindex [get_hw_devices] 0]
        refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

        set_property PROBES.FILE {} [lindex [get_hw_devices] 0]
        set_property FULL_PROBES.FILE {} [lindex [get_hw_devices] 0]
        set_property PROGRAM.FILE ${bitstream_file} [lindex [get_hw_devices] 0]

        program_hw_devices [lindex [get_hw_devices] 0]
        refresh_hw_device [lindex [get_hw_devices] 0]
}
proc clean {} {
        file delete -force .Xil
}

if {($argc != 1) || ([lindex $argv 0] ni {"simulation" "bitstream" "program" "run"})} {
        usage
}

if {[lindex $argv 0] == "program"} {
        program_board
        clean
        exit
} else {
        check_project
}

if {[lindex $argv 0] == "simulation"} {

        attach_sim_files

        set_property top ${top_sim_module} [current_fileset]
        update_compile_order -fileset sources_1
        update_compile_order -fileset sim_1
	launch_simulation
        #run all
        # add_wave {{/testbench_uart6_kc705/uut/set_baud_rate}} {{/testbench_uart6_kc705/uut/en_16_x_baud}}
        add_wave {{/testbench_uart6_kc705/uut/processor/address}} {{/testbench_uart6_kc705/uut/processor/kcpsm6_opcode}} {{/testbench_uart6_kc705/uut/processor/kcpsm6_status}} {{/testbench_uart6_kc705/uut/processor/sim_s0}} {{/testbench_uart6_kc705/uut/processor/sim_s1}} {{/testbench_uart6_kc705/uut/processor/sim_s2}} {{/testbench_uart6_kc705/uut/processor/sim_s3}} {{/testbench_uart6_kc705/uut/processor/sim_s4}} {{/testbench_uart6_kc705/uut/processor/sim_s5}} {{/testbench_uart6_kc705/uut/processor/sim_s6}} {{/testbench_uart6_kc705/uut/processor/sim_s7}} {{/testbench_uart6_kc705/uut/processor/sim_s8}} {{/testbench_uart6_kc705/uut/processor/sim_s9}} {{/testbench_uart6_kc705/uut/processor/sim_sA}} {{/testbench_uart6_kc705/uut/processor/sim_sB}} {{/testbench_uart6_kc705/uut/processor/sim_sC}} {{/testbench_uart6_kc705/uut/processor/sim_sD}} {{/testbench_uart6_kc705/uut/processor/sim_sE}} {{/testbench_uart6_kc705/uut/processor/sim_sF}}

        start_gui
        run all
        # exit
        # add_wave {{/draw_rect_ctl_test/my_draw_rect_ctl/xpos}} {{/draw_rect_ctl_test/my_draw_rect_ctl/ypos}}


} else {
        if {[lindex $argv 0] == "run"} {
                make_bitstream
                program_board
                clean
                exit
        } else {
                make_bitstream

                # Sekwencja pokazujaca i zapisujaca schemat rtl
                if {${generate_rtl} == 0 } {
                        clean
                        exit
                } else {
                        start_gui
                        synth_design -rtl -name rtl_1
                        show_schematic [concat [get_cells] [get_ports]]
                        write_schematic -force -format pdf rtl_schematic.pdf -orientation landscape -scope visible
                        clean
                        exit
                }
        }
}