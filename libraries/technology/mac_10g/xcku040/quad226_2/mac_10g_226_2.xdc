#------------------------------------------------------------------------------
# XXV_ETHERNET exceptions XDC file
# -----------------------------------------------------------------------------

set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/dclk}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/dclk}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10.000
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad126_2*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10.000