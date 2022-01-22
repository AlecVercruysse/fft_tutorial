onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fft_testbench/clk
add wave -noupdate /fft_testbench/start
add wave -noupdate /fft_testbench/load
add wave -noupdate /fft_testbench/done
add wave -noupdate /fft_testbench/reset
add wave -noupdate /fft_testbench/rd
add wave -noupdate /fft_testbench/expected_re
add wave -noupdate /fft_testbench/expected_im
add wave -noupdate /fft_testbench/wd_re
add wave -noupdate /fft_testbench/wd_im
add wave -noupdate /fft_testbench/wd
add wave -noupdate -radix unsigned /fft_testbench/idx
add wave -noupdate /fft_testbench/out_idx
add wave -noupdate /fft_testbench/expected
add wave -noupdate -radix unsigned /fft_testbench/dut/control/fft_agu/fftLevel
add wave -noupdate -radix unsigned /fft_testbench/dut/control/fft_agu/flyInd
add wave -noupdate -expand -group {AGU addrs out} -radix unsigned /fft_testbench/dut/control/fft_agu/adrA
add wave -noupdate -expand -group {AGU addrs out} -radix unsigned /fft_testbench/dut/control/fft_agu/adrB
add wave -noupdate -expand -group {AGU addrs out} -radix unsigned /fft_testbench/dut/control/fft_agu/twiddleadr
add wave -noupdate -expand -group a -radix unsigned /fft_testbench/dut/bgu/a_re
add wave -noupdate -expand -group a -radix unsigned /fft_testbench/dut/bgu/a_im
add wave -noupdate -expand -group b /fft_testbench/dut/bgu/twiddle_mult/a_re
add wave -noupdate -expand -group b /fft_testbench/dut/bgu/twiddle_mult/a_im
add wave -noupdate -expand -group twiddle /fft_testbench/dut/bgu/twiddle_mult/b_re
add wave -noupdate -expand -group twiddle /fft_testbench/dut/bgu/twiddle_mult/b_im
add wave -noupdate -expand -group {b * twiddle} /fft_testbench/dut/bgu/twiddle_mult/out_re
add wave -noupdate -expand -group {b * twiddle} /fft_testbench/dut/bgu/twiddle_mult/out_im
add wave -noupdate -expand -group a' -radix unsigned /fft_testbench/dut/bgu/aout_re
add wave -noupdate -expand -group a' -radix unsigned /fft_testbench/dut/bgu/aout_im
add wave -noupdate -expand -group b' -radix unsigned /fft_testbench/dut/bgu/bout_re
add wave -noupdate -expand -group b' -radix unsigned /fft_testbench/dut/bgu/bout_im
add wave -noupdate -expand -group mem /fft_testbench/dut/ram1/we
add wave -noupdate -expand -group mem /fft_testbench/dut/ram0/we
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1557 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 308
configure wave -valuecolwidth 205
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1650 ps} {2988 ps}
