transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Apps/Quartus/User/Source_verilog {D:/Apps/Quartus/User/Source_verilog/bin_to_7seg.v}
vlog -vlog01compat -work work +incdir+D:/Apps/Quartus/User/Source_verilog {D:/Apps/Quartus/User/Source_verilog/mux2_1_nb.v}
vlog -vlog01compat -work work +incdir+D:/Apps/Quartus/User/Source_verilog {D:/Apps/Quartus/User/Source_verilog/led7_2digit.v}

vlog -vlog01compat -work work +incdir+D:/Apps/Quartus/User/led7_2digit/../Source_verilog {D:/Apps/Quartus/User/led7_2digit/../Source_verilog/led7_2digit_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  led7_2digit_tb

add wave *
view structure
view signals
run -all
