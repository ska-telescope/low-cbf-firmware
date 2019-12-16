# Change default strategy
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

# Setup Extra Run for the heater design
#create_run lru_heater_synth -flow {Vivado Synthesis 2017}
#set_property strategy Flow_PerfOptimized_high [get_runs lru_heater_synth]
#create_run lru_heater_impl -parent_run lru_heater_synth -flow {Vivado Implementation 2017}
#set_property strategy Performance_ExtraTimingOpt [get_runs lru_heater_impl]
#set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-generic g_heater=1'b1} -objects [get_runs lru_heater_synth]
