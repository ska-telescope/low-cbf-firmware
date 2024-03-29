onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+ibert_ultrascale_gty_0 -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ibert_ultrascale_gty_0 xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {ibert_ultrascale_gty_0.udo}

run -all

endsim

quit -force
