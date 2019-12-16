#------------------------------------------------------------------------------
# XXV_ETHERNET exceptions XDC file
# -----------------------------------------------------------------------------

set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 2.560
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 2.560
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/dclk}]] 2.560
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/dclk}]] 2.560
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 18.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad134_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 18.000

