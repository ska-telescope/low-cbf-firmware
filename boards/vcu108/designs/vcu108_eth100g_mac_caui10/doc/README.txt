Status: Tested OK

Purpose: Run the IP example design

Tool: Vivado 2016.2

Quick steps to compile and use design [vcu108_eth100g_mac_caui10, vcu108_eth100g_mac_caui4] in RadionHDL
--------------------------------------------------------------------------------------------------------

-> In case of a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


1. Run the RadioHDL Command:

python $SVN/Firmware/tools/radiohdl/base/vivado_config.py -t vcu108 -v 5 -l vcu108_eth100g_mac_caui4 -r

python $SVN/Firmware/tools/radiohdl/base/vivado_config.py -t vcu108 -v 5 -l vcu108_eth100g_mac_caui10 -r


The python scripts create projectfiles in the [build] directory: $RADIOHDL/build
Also it builds the project completely.

Notes on this design:
---------------------

When downloading the bitstream file in the VCU108 board FPGA:

1. Set the GT ref clock:
- For the [vcu108_eth100g_mac_caui10] design you need to set the Si570 User Clock Frequency to 
  156.25 MHz. (Use the UART tool with serial terminal on PC)
- For the [vcu108_eth100g_mac_caui4] design you need to set the Si570 User Clock Frequency to 
  161.1328125 MHz. (Use the UART tool with serial terminal on PC)

2. Plug in the big CFP2 loopback connector

3. The GPIO LED's show the testing result:
- GPIO_LED_0: done TX
- GPIO_LED_1: NC
- GPIO_LED_2: busy TX
- GPIO_LED_3: locked GT
- GPIO_LED_4: aligned RX
- GPIO_LED_5: done RX
- GPIO_LED_6: fail RX
- GPIO_LED_7: busy RX

4. Try the buttons:
- GPIO_SW_C: restart test
- GPIO_SW_N: system reset

5. See the difference in LED's when unplugging the loopback connector
