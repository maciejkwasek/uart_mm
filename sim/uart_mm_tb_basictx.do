vlib work
vmap work work

vcom ../../rtl/nco32.vhd
vcom ../../rtl/fifo.vhd
vcom ../../rtl/uart_tx.vhd
vcom ../../rtl/uart_rx.vhd
vcom ../../rtl/uart_mm.vhd

vcom ../../tb/uart_mm_helper.vhd
vcom ../../tb/uart_mm_tb_basictx.vhd

vsim work.uart_mm_tb_basictx

add wave *

run 70 us

