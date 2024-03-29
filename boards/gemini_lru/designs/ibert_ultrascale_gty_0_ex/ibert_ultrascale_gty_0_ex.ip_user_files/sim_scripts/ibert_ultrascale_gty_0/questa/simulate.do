onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib ibert_ultrascale_gty_0_opt

do {wave.do}

view wave
view structure
view signals

do {ibert_ultrascale_gty_0.udo}

run -all

quit -force
