This readme is an introduction to py_args_lib.

Contents:
1) Demo of py_args_lib
2) How to develop new tool scripts that use py_args_lib
3) Examples of tool scripts that use py_args_lib



1) Demo of py_args_lib

./args_demo.py -h                                 # help
./args_demo.py -s unb1_minimal_sopc -v INFO       # show system.yaml contents
./args_demo.py -p unb1_board dp -v INFO           # show peripheral.yaml contents



2) How to develop new tool scripts that use py_args_lib

# import all from py_args_lib
from py_args_lib import *

# logger is automaticly included (unit_logger), only logfile and level must be set,
# if 'unit_logger.set_logfile_name()' is not called no log file is made, 
# in the calling directory there must be a directory called log
# valid levels are ERROR, WARNING, INFO or DEBUG 
unit_logger.set_logfile_name(name=[program_name])
unit_logger.set_file_log_level('DEBUG')   # if not called the default is 'DEBUG'
unit_logger.set_stdout_log_level('INFO')  # if not called the default is 'INFO'


# assign System class with requested *.system.yaml filename
# this will load all existing peripherals and include the system peripherals modified with the 
# system settings to the system class
system = System(filename=[*.system.yaml])

# now the dictonary system.peripherals holds all the peripheral classes
peripheral = system.peripherals['peripheral_name']



3) Examples of tool scripts that use py_args_lib

a) Create pdf documentation (very draft)

./args_documentation.py -s unb1_minimal_sopc       # system with all it peripherals
okular unb1_minimal_sopc.pdf

./args_documentation.py -p unb1_board dp           # only the peripheral
okular unb1_board.pdf


b) Create ROM system info for Uniboard

./uniboard_rom_system_info.py -s unb1_minimal_sopc            # with self generated base addresses
more unb1_minimal_sopc.reg

./uniboard_rom_system_info.py -s unb1_minimal_sopc -q         # using base addresses from sopc file (via -q)
more unb1_minimal_sopc.reg
