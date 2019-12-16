----------------------------------------------------------------------------------
-- Company: CSIRO - CASS 
-- Engineer: David Humphrey
-- 
-- Create Date: 15.11.2018 09:30:43
-- Module Name: fb_mem - Behavioral
-- Description: 
--  Memories for the Correlator Filterbank.
-- Notes:
--  * The number of taps is semi-configurable; some modification is required if "TAPS" is not set to 12.
--  * Read data is staggered by one clock for each of the 12 samples, so that the FIR filter can use the adders in the DSPs.
--
----------------------------------------------------------------------------------

library IEEE, common_lib, filterbanks_lib;
use common_lib.common_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
--library UNISIM;
--use UNISIM.VComponents.all;

entity correlatorFBMem is
    generic (
        TAPS : integer := 12  -- Note only partially parameterized; modification needed to support anything other than 12.
    );
    port(
        clk    : in std_logic;
        -- Write data for the start of the chain
        wrData_i : in std_logic_vector(63 downto 0);
        wrEn_i   : in std_logic; -- should be a burst of 4096 clocks.
        -- Read data, comes out 2 clocks after the first write.
        rd_data_o  : out t_slv_64_arr(TAPS-1 downto 0);   -- 64 bits wide, 12 taps simultaneously; First sample is wr_data_i delayed by 1 clock. 
        coef_o     : out t_slv_18_arr(TAPS-1 downto 0);   -- 18 bits per filter tap.
        -- Writing FIR Taps
        FIRTapData_i : in std_logic_vector(17 downto 0);  -- For register writes of the filtertaps.
        FIRTapData_o : out std_logic_vector(17 downto 0); -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
        FIRTapAddr_i : in std_logic_vector(15 downto 0);  -- 4096 * 12 filter taps = 49152 total.
        FIRTapWE_i   : in std_logic;
        FIRTapClk    : in std_logic
    );
end correlatorFBMem;

architecture Behavioral of correlatorFBMem is
    
    -- ok, it's not a ROM, but it's used that way most of the time.
    component CFB_ROM1
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM2
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component CFB_ROM3
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component CFB_ROM4
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM5
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM6
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM7
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component CFB_ROM8
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component CFB_ROM9
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM10
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;

    component CFB_ROM11
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    component CFB_ROM12
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(11 downto 0);
        dina  : in std_logic_vector(17 downto 0);
        douta : out std_logic_vector(17 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(11 downto 0);
        dinb  : in std_logic_vector(17 downto 0);
        doutb : out std_logic_vector(17 downto 0));
    end component;
    
    -- Tcl to create the FIR coefficient memories.
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM1 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps1.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM1]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM1/correlatorROM1.xci]
        
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM2 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps2.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM2]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM2/correlatorROM2.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM3 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps3.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM3]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM3/correlatorROM3.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM4 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps4.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM4]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM4/correlatorROM4.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM5 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps5.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM5]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM5/correlatorROM5.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM6 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps6.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM6]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM6/correlatorROM6.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM7 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps7.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM7]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM7/correlatorROM7.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM8 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps8.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM8]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM8/correlatorROM8.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM9 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps9.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM9]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM9/correlatorROM9.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM10 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps10.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM10]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM10/correlatorROM10.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM11 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps11.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM11]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM11/correlatorROM11.xci]
    
    --create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name correlatorROM12 -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --set_property -dict [list CONFIG.Component_Name {correlatorROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/projects/perentie/xilinx_test_projects/filterbank_matlab/correlatorFIRTaps12.coe} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips correlatorROM12]
    --generate_target all [get_files  c:/projects/perentie/xilinx_test_projects/filterbank_ip/correlatorROM12/correlatorROM12.xci]

    signal FIRTapsWE : t_slv_1_arr((TAPS-1) downto 0);
    signal FIRTapRegAddr : std_logic_vector(11 downto 0);
    signal FIRTapRegWrData : std_logic_vector(17 downto 0);
    signal FIRTapRegRdData : t_slv_18_arr((TAPS-1) downto 0);
    signal dummy0SLV : std_logic_vector(0 downto 0);
    signal FIRTapAddrDel1, FIRTapAddrDel2, FIRTapAddrDel3 : std_logic_vector(3 downto 0) := "0000";
    signal dummy0_18 : std_logic_vector(17 downto 0);
    signal romRdAddr : t_slv_12_arr((TAPS-1) downto 0);
    
    signal rdAddr : std_logic_vector(11 downto 0);
    signal rdAddrDel : t_slv_12_arr((TAPS) downto 0) := (others => (others => '0'));
    signal wrDataDel1 : std_logic_vector(63 downto 0);
    signal wrEnDel1 : std_logic := '0';
    
    signal wr_en_slv : std_logic_vector(0 downto 0);
    
    signal romAddrDel : t_slv_12_arr((TAPS-1) downto 0):= (others => (others => '0'));
    signal wrEnDel : std_logic_vector((TAPS) downto 0) := (others => '0');
    signal rdDataDel : t_slv_64_arr((TAPS-1) downto 0);
    
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
        
            wrDataDel1 <= wrData_i;      -- Extra Delay on the the input data so that the read data from the first coefficient ROM matches the first data output.
            rdDataDel(0) <= wrDataDel1;  -- Two cycle latency for the first data; Each memory has a 2 cycle latency so second data has 3 cycle latency.
        
            wrEnDel1 <= wrEn_i;
            wrEnDel(1) <= wrEnDel1;
            if wrEn_i = '0' then
                rdAddr <= (others => '0');
            else
                rdAddr <= std_logic_vector(unsigned(rdAddr) + 1);
            end if;
            
            rdAddrDel(TAPS downto 1) <= rdAddrDel(TAPS-1 downto 0);
            romAddrDel((TAPS-1) downto 1) <= romAddrDel((TAPS-2) downto 0);
            wrEnDel(TAPS downto 2) <= wrEnDel(TAPS-1 downto 1);
        end if;
    end process;
    
    rdAddrDel(0) <= rdAddr;
    romAddrDel(0) <= rdAddr;
    
    dataMem : for i in 1 to (TAPS-1) generate
        
        urams : entity filterbanks_lib.URAMWrapper
        port map (
            clk => clk, -- in std_logic;
            -- write side
            wrAddr => rdAddrDel(i+1), -- in(11:0)
            din    => rdDataDel(i-1), -- in(63:0)
            we     => wrEnDel(i),     -- in std_logic
            -- read side
            rdAddr => rdAddrDel(i),   -- in(11:0)
            dout   => rdDataDel(i)    -- out(63:0)
        );
        
        rd_data_o(i) <= rdDataDel(i);
        
    end generate;
    
    rd_data_o(0) <= rdDataDel(0);
    
    --------------------------------------------------------------------------------------
    -- Filter Coefficients
    -- 12 memories, each 18 bits wide, 4096 deep, dual port.
    -- Port A used to write new coefficients
    -- Port B used to read.

    -- Note register ports are 
    --  FIRTapData_i : in std_logic_vector(17 downto 0);
    --  FIRTapData_o : out std_logic_vector(17 downto 0);
    --  FIRTapAddr_i : in std_logic_vector(15 downto 0);  -- 4096 * 12 filter taps = 49152 total.
    --  FIRTapWE_i   : in std_logic;
    --  FIRTapClk    : in std_logic
    
    process(FIRTapClk)
    begin
        if rising_edge(FIRTapClk) then
            for ft in 0 to (TAPS-1) loop
                if (FIRTapWE_i = '1' and FIRTapAddr_i(15 downto 12) = std_logic_vector(to_unsigned(ft,4))) then
                    FIRTapsWE(ft)(0) <= '1';
                else
                    FIRTapsWE(ft)(0) <= '0';
                end if; 
            end loop;
            FIRTapRegAddr <= FIRTapAddr_i(11 downto 0);
            FIRTapRegWrData <= FIRTapData_i;
            
            FIRTapAddrDel1 <= FIRTapAddr_i(15 downto 12);  -- del1 aligns with FIRTapRegAddr 
            FIRTapAddrDel2 <= FIRTapAddrDel1; 
            FIRTapAddrDel3 <= FIRTapAddrDel2;              -- del3 aligns with the read data in FIRTapRegRdData
            
            FIRTapData_o <= FIRTapRegRdData(to_integer(unsigned(FIRTapAddrDel3)));
        end if;
    end process;
    
    dummy0SLV(0) <= '0';
    dummy0_18 <= (others => '0');
    
    -- Every memory has a different name so they can have different default contents.
    -- Beware this assumes the generic "TAPS" is 12.
    FIRTaps1 : CFB_ROM12
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(0),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(0),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(0),
        dinb  => dummy0_18,
        doutb => coef_o(0)
    );

    FIRTaps2 : CFB_ROM11
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(1),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(1),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(1),
        dinb  => dummy0_18,
        doutb => coef_o(1)
    );

    FIRTaps3 : CFB_ROM10
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(2),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(2),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(2),
        dinb  => dummy0_18,
        doutb => coef_o(2)
    );

    FIRTaps4 : CFB_ROM9
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(3),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(3),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(3),
        dinb  => dummy0_18,
        doutb => coef_o(3)
    );

    FIRTaps5 : CFB_ROM8
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(4),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(4),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(4),
        dinb  => dummy0_18,
        doutb => coef_o(4)
    );

    FIRTaps6 : CFB_ROM7
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(5),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(5),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(5),
        dinb  => dummy0_18,
        doutb => coef_o(5)
    );

    FIRTaps7 : CFB_ROM6
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(6),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(6),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(6),
        dinb  => dummy0_18,
        doutb => coef_o(6)
    );

    FIRTaps8 : CFB_ROM5
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(7),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(7),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(7),
        dinb  => dummy0_18,
        doutb => coef_o(7)
    );

    FIRTaps9 : CFB_ROM4
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(8),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(8),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(8),
        dinb  => dummy0_18,
        doutb => coef_o(8)
    );

    FIRTaps10 : CFB_ROM3
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(9),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(9),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(9),
        dinb  => dummy0_18,
        doutb => coef_o(9)
    );

    FIRTaps11 : CFB_ROM2
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(10),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(10),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(10),
        dinb  => dummy0_18,
        doutb => coef_o(10)
    );

    FIRTaps12 : CFB_ROM1
    port map (
        -- Port A, register reads and writes 
        clka => FIRTapClk,
        wea  => FIRTapsWE(11),
        addra => FIRTapRegAddr,
        dina  => FIRTapRegWrData,
        douta => FIRTapRegRdData(11),
        -- Port B, read by the filterbank. 
        clkb  => clk,
        web   => dummy0SLV,
        addrb => romAddrDel(11),
        dinb  => dummy0_18,
        doutb => coef_o(11)
    );
    
    
end Behavioral;

