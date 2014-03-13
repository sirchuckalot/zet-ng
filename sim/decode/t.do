quit -sim

echo "Compiling verilog modules..."
make

vsim -t ns decode.test_decode

add wave -label clk        -hex clk
add wave -label rst        -hex rst

add wave -divider test
add wave -hex *

add wave -divider decode
add wave -hex dut/*

add wave -divider opcode_deco
add wave -hex dut/opcode_deco/*

add wave -divider memory_regs
add wave -hex dut/opcode_deco/memory_regs/*

#run 465ns
run 1000ns