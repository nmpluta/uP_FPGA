set project uP_picoblaze
set top_module picoblaze_top
set target xc7a35tcpg236-1
# if generate_rtl 1 then during executing bitstream will be created rtl_schematic pdf
set generate_rtl 0
# set path where vivado has to put project and running output
set build_path vivado/build
# set simulation top module
set top_sim_module picoblaze_top

set bitstream_file ${build_path}/${project}.runs/impl_1/${top_module}.bit


proc usage {} {
        puts "usage: vivado -mode tcl -source [info script] -tclargs \[simulation/bitstream/program/run\]"
        exit 1
}

# files for bitstream

proc attach_rtl_files {} {

        remove_files [get_files -quiet]
        read_xdc {
                constraints/constraints.xdc
        }

        read_vhdl {
                rtl/picoblaze_top.vhd
                rtl/picoblaze.vhd
                rtl/program.vhd
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
        # }

        # read_vhdl {
        # }

        # read_verilog {
        # }

        #  read_mem {
        #  }

        add_files -fileset sim_1 {
                sim/testbench_picoblaze.vhd

        }
        #--------------------------------------------------------
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
        add_wave {{/testbench_picoblaze/picoblaze_top_tes/processor/address}} {{/testbench_picoblaze/picoblaze_top_tes/processor/instruction}}
        add_wave {{/testbench_picoblaze/picoblaze_top_tes/processor/in_port}} {{/testbench_picoblaze/picoblaze_top_tes/processor/out_port}} {{/testbench_picoblaze/picoblaze_top_tes/processor/write_strobe}} {{/testbench_picoblaze/picoblaze_top_tes/processor/read_strobe}}
        relaunch_sim
        start_gui
        run all
        # exit

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