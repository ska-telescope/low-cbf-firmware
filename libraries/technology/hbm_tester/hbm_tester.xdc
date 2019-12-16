
set_property IOSTANDARD LVDS [get_ports clk_in_100_p]
set_property IOSTANDARD LVDS [get_ports clk_in_100_n]

#set_property PACKAGE_PIN AR14     [get_ports "pci_clk_100_n"] ;# Bank 225 - MGTREFCLK0N_225
#set_property PACKAGE_PIN AR15     [get_ports "pci_clk_100_p"] ;# Bank 225 - MGTREFCLK0P_225

#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins E_CLK_WIZ/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins E_CLK_WIZ/inst/mmcme4_adv_inst/CLKOUT1]] 2.000
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins E_CLK_WIZ/inst/mmcme4_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins E_CLK_WIZ/inst/mmcme4_adv_inst/CLKOUT0]] 2.000



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list E_CLK_WIZ/inst/clk_450]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 48 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {r_cnt[0]} {r_cnt[1]} {r_cnt[2]} {r_cnt[3]} {r_cnt[4]} {r_cnt[5]} {r_cnt[6]} {r_cnt[7]} {r_cnt[8]} {r_cnt[9]} {r_cnt[10]} {r_cnt[11]} {r_cnt[12]} {r_cnt[13]} {r_cnt[14]} {r_cnt[15]} {r_cnt[16]} {r_cnt[17]} {r_cnt[18]} {r_cnt[19]} {r_cnt[20]} {r_cnt[21]} {r_cnt[22]} {r_cnt[23]} {r_cnt[24]} {r_cnt[25]} {r_cnt[26]} {r_cnt[27]} {r_cnt[28]} {r_cnt[29]} {r_cnt[30]} {r_cnt[31]} {r_cnt[32]} {r_cnt[33]} {r_cnt[34]} {r_cnt[35]} {r_cnt[36]} {r_cnt[37]} {r_cnt[38]} {r_cnt[39]} {r_cnt[40]} {r_cnt[41]} {r_cnt[42]} {r_cnt[43]} {r_cnt[44]} {r_cnt[45]} {r_cnt[46]} {r_cnt[47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {axi_00_in_i[ar][size][0]} {axi_00_in_i[ar][size][1]} {axi_00_in_i[ar][size][2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 256 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {axi_00_out_i[r][data][0]} {axi_00_out_i[r][data][1]} {axi_00_out_i[r][data][2]} {axi_00_out_i[r][data][3]} {axi_00_out_i[r][data][4]} {axi_00_out_i[r][data][5]} {axi_00_out_i[r][data][6]} {axi_00_out_i[r][data][7]} {axi_00_out_i[r][data][8]} {axi_00_out_i[r][data][9]} {axi_00_out_i[r][data][10]} {axi_00_out_i[r][data][11]} {axi_00_out_i[r][data][12]} {axi_00_out_i[r][data][13]} {axi_00_out_i[r][data][14]} {axi_00_out_i[r][data][15]} {axi_00_out_i[r][data][16]} {axi_00_out_i[r][data][17]} {axi_00_out_i[r][data][18]} {axi_00_out_i[r][data][19]} {axi_00_out_i[r][data][20]} {axi_00_out_i[r][data][21]} {axi_00_out_i[r][data][22]} {axi_00_out_i[r][data][23]} {axi_00_out_i[r][data][24]} {axi_00_out_i[r][data][25]} {axi_00_out_i[r][data][26]} {axi_00_out_i[r][data][27]} {axi_00_out_i[r][data][28]} {axi_00_out_i[r][data][29]} {axi_00_out_i[r][data][30]} {axi_00_out_i[r][data][31]} {axi_00_out_i[r][data][32]} {axi_00_out_i[r][data][33]} {axi_00_out_i[r][data][34]} {axi_00_out_i[r][data][35]} {axi_00_out_i[r][data][36]} {axi_00_out_i[r][data][37]} {axi_00_out_i[r][data][38]} {axi_00_out_i[r][data][39]} {axi_00_out_i[r][data][40]} {axi_00_out_i[r][data][41]} {axi_00_out_i[r][data][42]} {axi_00_out_i[r][data][43]} {axi_00_out_i[r][data][44]} {axi_00_out_i[r][data][45]} {axi_00_out_i[r][data][46]} {axi_00_out_i[r][data][47]} {axi_00_out_i[r][data][48]} {axi_00_out_i[r][data][49]} {axi_00_out_i[r][data][50]} {axi_00_out_i[r][data][51]} {axi_00_out_i[r][data][52]} {axi_00_out_i[r][data][53]} {axi_00_out_i[r][data][54]} {axi_00_out_i[r][data][55]} {axi_00_out_i[r][data][56]} {axi_00_out_i[r][data][57]} {axi_00_out_i[r][data][58]} {axi_00_out_i[r][data][59]} {axi_00_out_i[r][data][60]} {axi_00_out_i[r][data][61]} {axi_00_out_i[r][data][62]} {axi_00_out_i[r][data][63]} {axi_00_out_i[r][data][64]} {axi_00_out_i[r][data][65]} {axi_00_out_i[r][data][66]} {axi_00_out_i[r][data][67]} {axi_00_out_i[r][data][68]} {axi_00_out_i[r][data][69]} {axi_00_out_i[r][data][70]} {axi_00_out_i[r][data][71]} {axi_00_out_i[r][data][72]} {axi_00_out_i[r][data][73]} {axi_00_out_i[r][data][74]} {axi_00_out_i[r][data][75]} {axi_00_out_i[r][data][76]} {axi_00_out_i[r][data][77]} {axi_00_out_i[r][data][78]} {axi_00_out_i[r][data][79]} {axi_00_out_i[r][data][80]} {axi_00_out_i[r][data][81]} {axi_00_out_i[r][data][82]} {axi_00_out_i[r][data][83]} {axi_00_out_i[r][data][84]} {axi_00_out_i[r][data][85]} {axi_00_out_i[r][data][86]} {axi_00_out_i[r][data][87]} {axi_00_out_i[r][data][88]} {axi_00_out_i[r][data][89]} {axi_00_out_i[r][data][90]} {axi_00_out_i[r][data][91]} {axi_00_out_i[r][data][92]} {axi_00_out_i[r][data][93]} {axi_00_out_i[r][data][94]} {axi_00_out_i[r][data][95]} {axi_00_out_i[r][data][96]} {axi_00_out_i[r][data][97]} {axi_00_out_i[r][data][98]} {axi_00_out_i[r][data][99]} {axi_00_out_i[r][data][100]} {axi_00_out_i[r][data][101]} {axi_00_out_i[r][data][102]} {axi_00_out_i[r][data][103]} {axi_00_out_i[r][data][104]} {axi_00_out_i[r][data][105]} {axi_00_out_i[r][data][106]} {axi_00_out_i[r][data][107]} {axi_00_out_i[r][data][108]} {axi_00_out_i[r][data][109]} {axi_00_out_i[r][data][110]} {axi_00_out_i[r][data][111]} {axi_00_out_i[r][data][112]} {axi_00_out_i[r][data][113]} {axi_00_out_i[r][data][114]} {axi_00_out_i[r][data][115]} {axi_00_out_i[r][data][116]} {axi_00_out_i[r][data][117]} {axi_00_out_i[r][data][118]} {axi_00_out_i[r][data][119]} {axi_00_out_i[r][data][120]} {axi_00_out_i[r][data][121]} {axi_00_out_i[r][data][122]} {axi_00_out_i[r][data][123]} {axi_00_out_i[r][data][124]} {axi_00_out_i[r][data][125]} {axi_00_out_i[r][data][126]} {axi_00_out_i[r][data][127]} {axi_00_out_i[r][data][128]} {axi_00_out_i[r][data][129]} {axi_00_out_i[r][data][130]} {axi_00_out_i[r][data][131]} {axi_00_out_i[r][data][132]} {axi_00_out_i[r][data][133]} {axi_00_out_i[r][data][134]} {axi_00_out_i[r][data][135]} {axi_00_out_i[r][data][136]} {axi_00_out_i[r][data][137]} {axi_00_out_i[r][data][138]} {axi_00_out_i[r][data][139]} {axi_00_out_i[r][data][140]} {axi_00_out_i[r][data][141]} {axi_00_out_i[r][data][142]} {axi_00_out_i[r][data][143]} {axi_00_out_i[r][data][144]} {axi_00_out_i[r][data][145]} {axi_00_out_i[r][data][146]} {axi_00_out_i[r][data][147]} {axi_00_out_i[r][data][148]} {axi_00_out_i[r][data][149]} {axi_00_out_i[r][data][150]} {axi_00_out_i[r][data][151]} {axi_00_out_i[r][data][152]} {axi_00_out_i[r][data][153]} {axi_00_out_i[r][data][154]} {axi_00_out_i[r][data][155]} {axi_00_out_i[r][data][156]} {axi_00_out_i[r][data][157]} {axi_00_out_i[r][data][158]} {axi_00_out_i[r][data][159]} {axi_00_out_i[r][data][160]} {axi_00_out_i[r][data][161]} {axi_00_out_i[r][data][162]} {axi_00_out_i[r][data][163]} {axi_00_out_i[r][data][164]} {axi_00_out_i[r][data][165]} {axi_00_out_i[r][data][166]} {axi_00_out_i[r][data][167]} {axi_00_out_i[r][data][168]} {axi_00_out_i[r][data][169]} {axi_00_out_i[r][data][170]} {axi_00_out_i[r][data][171]} {axi_00_out_i[r][data][172]} {axi_00_out_i[r][data][173]} {axi_00_out_i[r][data][174]} {axi_00_out_i[r][data][175]} {axi_00_out_i[r][data][176]} {axi_00_out_i[r][data][177]} {axi_00_out_i[r][data][178]} {axi_00_out_i[r][data][179]} {axi_00_out_i[r][data][180]} {axi_00_out_i[r][data][181]} {axi_00_out_i[r][data][182]} {axi_00_out_i[r][data][183]} {axi_00_out_i[r][data][184]} {axi_00_out_i[r][data][185]} {axi_00_out_i[r][data][186]} {axi_00_out_i[r][data][187]} {axi_00_out_i[r][data][188]} {axi_00_out_i[r][data][189]} {axi_00_out_i[r][data][190]} {axi_00_out_i[r][data][191]} {axi_00_out_i[r][data][192]} {axi_00_out_i[r][data][193]} {axi_00_out_i[r][data][194]} {axi_00_out_i[r][data][195]} {axi_00_out_i[r][data][196]} {axi_00_out_i[r][data][197]} {axi_00_out_i[r][data][198]} {axi_00_out_i[r][data][199]} {axi_00_out_i[r][data][200]} {axi_00_out_i[r][data][201]} {axi_00_out_i[r][data][202]} {axi_00_out_i[r][data][203]} {axi_00_out_i[r][data][204]} {axi_00_out_i[r][data][205]} {axi_00_out_i[r][data][206]} {axi_00_out_i[r][data][207]} {axi_00_out_i[r][data][208]} {axi_00_out_i[r][data][209]} {axi_00_out_i[r][data][210]} {axi_00_out_i[r][data][211]} {axi_00_out_i[r][data][212]} {axi_00_out_i[r][data][213]} {axi_00_out_i[r][data][214]} {axi_00_out_i[r][data][215]} {axi_00_out_i[r][data][216]} {axi_00_out_i[r][data][217]} {axi_00_out_i[r][data][218]} {axi_00_out_i[r][data][219]} {axi_00_out_i[r][data][220]} {axi_00_out_i[r][data][221]} {axi_00_out_i[r][data][222]} {axi_00_out_i[r][data][223]} {axi_00_out_i[r][data][224]} {axi_00_out_i[r][data][225]} {axi_00_out_i[r][data][226]} {axi_00_out_i[r][data][227]} {axi_00_out_i[r][data][228]} {axi_00_out_i[r][data][229]} {axi_00_out_i[r][data][230]} {axi_00_out_i[r][data][231]} {axi_00_out_i[r][data][232]} {axi_00_out_i[r][data][233]} {axi_00_out_i[r][data][234]} {axi_00_out_i[r][data][235]} {axi_00_out_i[r][data][236]} {axi_00_out_i[r][data][237]} {axi_00_out_i[r][data][238]} {axi_00_out_i[r][data][239]} {axi_00_out_i[r][data][240]} {axi_00_out_i[r][data][241]} {axi_00_out_i[r][data][242]} {axi_00_out_i[r][data][243]} {axi_00_out_i[r][data][244]} {axi_00_out_i[r][data][245]} {axi_00_out_i[r][data][246]} {axi_00_out_i[r][data][247]} {axi_00_out_i[r][data][248]} {axi_00_out_i[r][data][249]} {axi_00_out_i[r][data][250]} {axi_00_out_i[r][data][251]} {axi_00_out_i[r][data][252]} {axi_00_out_i[r][data][253]} {axi_00_out_i[r][data][254]} {axi_00_out_i[r][data][255]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 256 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {axi_00_in_i[w][data][0]} {axi_00_in_i[w][data][1]} {axi_00_in_i[w][data][2]} {axi_00_in_i[w][data][3]} {axi_00_in_i[w][data][4]} {axi_00_in_i[w][data][5]} {axi_00_in_i[w][data][6]} {axi_00_in_i[w][data][7]} {axi_00_in_i[w][data][8]} {axi_00_in_i[w][data][9]} {axi_00_in_i[w][data][10]} {axi_00_in_i[w][data][11]} {axi_00_in_i[w][data][12]} {axi_00_in_i[w][data][13]} {axi_00_in_i[w][data][14]} {axi_00_in_i[w][data][15]} {axi_00_in_i[w][data][16]} {axi_00_in_i[w][data][17]} {axi_00_in_i[w][data][18]} {axi_00_in_i[w][data][19]} {axi_00_in_i[w][data][20]} {axi_00_in_i[w][data][21]} {axi_00_in_i[w][data][22]} {axi_00_in_i[w][data][23]} {axi_00_in_i[w][data][24]} {axi_00_in_i[w][data][25]} {axi_00_in_i[w][data][26]} {axi_00_in_i[w][data][27]} {axi_00_in_i[w][data][28]} {axi_00_in_i[w][data][29]} {axi_00_in_i[w][data][30]} {axi_00_in_i[w][data][31]} {axi_00_in_i[w][data][32]} {axi_00_in_i[w][data][33]} {axi_00_in_i[w][data][34]} {axi_00_in_i[w][data][35]} {axi_00_in_i[w][data][36]} {axi_00_in_i[w][data][37]} {axi_00_in_i[w][data][38]} {axi_00_in_i[w][data][39]} {axi_00_in_i[w][data][40]} {axi_00_in_i[w][data][41]} {axi_00_in_i[w][data][42]} {axi_00_in_i[w][data][43]} {axi_00_in_i[w][data][44]} {axi_00_in_i[w][data][45]} {axi_00_in_i[w][data][46]} {axi_00_in_i[w][data][47]} {axi_00_in_i[w][data][48]} {axi_00_in_i[w][data][49]} {axi_00_in_i[w][data][50]} {axi_00_in_i[w][data][51]} {axi_00_in_i[w][data][52]} {axi_00_in_i[w][data][53]} {axi_00_in_i[w][data][54]} {axi_00_in_i[w][data][55]} {axi_00_in_i[w][data][56]} {axi_00_in_i[w][data][57]} {axi_00_in_i[w][data][58]} {axi_00_in_i[w][data][59]} {axi_00_in_i[w][data][60]} {axi_00_in_i[w][data][61]} {axi_00_in_i[w][data][62]} {axi_00_in_i[w][data][63]} {axi_00_in_i[w][data][64]} {axi_00_in_i[w][data][65]} {axi_00_in_i[w][data][66]} {axi_00_in_i[w][data][67]} {axi_00_in_i[w][data][68]} {axi_00_in_i[w][data][69]} {axi_00_in_i[w][data][70]} {axi_00_in_i[w][data][71]} {axi_00_in_i[w][data][72]} {axi_00_in_i[w][data][73]} {axi_00_in_i[w][data][74]} {axi_00_in_i[w][data][75]} {axi_00_in_i[w][data][76]} {axi_00_in_i[w][data][77]} {axi_00_in_i[w][data][78]} {axi_00_in_i[w][data][79]} {axi_00_in_i[w][data][80]} {axi_00_in_i[w][data][81]} {axi_00_in_i[w][data][82]} {axi_00_in_i[w][data][83]} {axi_00_in_i[w][data][84]} {axi_00_in_i[w][data][85]} {axi_00_in_i[w][data][86]} {axi_00_in_i[w][data][87]} {axi_00_in_i[w][data][88]} {axi_00_in_i[w][data][89]} {axi_00_in_i[w][data][90]} {axi_00_in_i[w][data][91]} {axi_00_in_i[w][data][92]} {axi_00_in_i[w][data][93]} {axi_00_in_i[w][data][94]} {axi_00_in_i[w][data][95]} {axi_00_in_i[w][data][96]} {axi_00_in_i[w][data][97]} {axi_00_in_i[w][data][98]} {axi_00_in_i[w][data][99]} {axi_00_in_i[w][data][100]} {axi_00_in_i[w][data][101]} {axi_00_in_i[w][data][102]} {axi_00_in_i[w][data][103]} {axi_00_in_i[w][data][104]} {axi_00_in_i[w][data][105]} {axi_00_in_i[w][data][106]} {axi_00_in_i[w][data][107]} {axi_00_in_i[w][data][108]} {axi_00_in_i[w][data][109]} {axi_00_in_i[w][data][110]} {axi_00_in_i[w][data][111]} {axi_00_in_i[w][data][112]} {axi_00_in_i[w][data][113]} {axi_00_in_i[w][data][114]} {axi_00_in_i[w][data][115]} {axi_00_in_i[w][data][116]} {axi_00_in_i[w][data][117]} {axi_00_in_i[w][data][118]} {axi_00_in_i[w][data][119]} {axi_00_in_i[w][data][120]} {axi_00_in_i[w][data][121]} {axi_00_in_i[w][data][122]} {axi_00_in_i[w][data][123]} {axi_00_in_i[w][data][124]} {axi_00_in_i[w][data][125]} {axi_00_in_i[w][data][126]} {axi_00_in_i[w][data][127]} {axi_00_in_i[w][data][128]} {axi_00_in_i[w][data][129]} {axi_00_in_i[w][data][130]} {axi_00_in_i[w][data][131]} {axi_00_in_i[w][data][132]} {axi_00_in_i[w][data][133]} {axi_00_in_i[w][data][134]} {axi_00_in_i[w][data][135]} {axi_00_in_i[w][data][136]} {axi_00_in_i[w][data][137]} {axi_00_in_i[w][data][138]} {axi_00_in_i[w][data][139]} {axi_00_in_i[w][data][140]} {axi_00_in_i[w][data][141]} {axi_00_in_i[w][data][142]} {axi_00_in_i[w][data][143]} {axi_00_in_i[w][data][144]} {axi_00_in_i[w][data][145]} {axi_00_in_i[w][data][146]} {axi_00_in_i[w][data][147]} {axi_00_in_i[w][data][148]} {axi_00_in_i[w][data][149]} {axi_00_in_i[w][data][150]} {axi_00_in_i[w][data][151]} {axi_00_in_i[w][data][152]} {axi_00_in_i[w][data][153]} {axi_00_in_i[w][data][154]} {axi_00_in_i[w][data][155]} {axi_00_in_i[w][data][156]} {axi_00_in_i[w][data][157]} {axi_00_in_i[w][data][158]} {axi_00_in_i[w][data][159]} {axi_00_in_i[w][data][160]} {axi_00_in_i[w][data][161]} {axi_00_in_i[w][data][162]} {axi_00_in_i[w][data][163]} {axi_00_in_i[w][data][164]} {axi_00_in_i[w][data][165]} {axi_00_in_i[w][data][166]} {axi_00_in_i[w][data][167]} {axi_00_in_i[w][data][168]} {axi_00_in_i[w][data][169]} {axi_00_in_i[w][data][170]} {axi_00_in_i[w][data][171]} {axi_00_in_i[w][data][172]} {axi_00_in_i[w][data][173]} {axi_00_in_i[w][data][174]} {axi_00_in_i[w][data][175]} {axi_00_in_i[w][data][176]} {axi_00_in_i[w][data][177]} {axi_00_in_i[w][data][178]} {axi_00_in_i[w][data][179]} {axi_00_in_i[w][data][180]} {axi_00_in_i[w][data][181]} {axi_00_in_i[w][data][182]} {axi_00_in_i[w][data][183]} {axi_00_in_i[w][data][184]} {axi_00_in_i[w][data][185]} {axi_00_in_i[w][data][186]} {axi_00_in_i[w][data][187]} {axi_00_in_i[w][data][188]} {axi_00_in_i[w][data][189]} {axi_00_in_i[w][data][190]} {axi_00_in_i[w][data][191]} {axi_00_in_i[w][data][192]} {axi_00_in_i[w][data][193]} {axi_00_in_i[w][data][194]} {axi_00_in_i[w][data][195]} {axi_00_in_i[w][data][196]} {axi_00_in_i[w][data][197]} {axi_00_in_i[w][data][198]} {axi_00_in_i[w][data][199]} {axi_00_in_i[w][data][200]} {axi_00_in_i[w][data][201]} {axi_00_in_i[w][data][202]} {axi_00_in_i[w][data][203]} {axi_00_in_i[w][data][204]} {axi_00_in_i[w][data][205]} {axi_00_in_i[w][data][206]} {axi_00_in_i[w][data][207]} {axi_00_in_i[w][data][208]} {axi_00_in_i[w][data][209]} {axi_00_in_i[w][data][210]} {axi_00_in_i[w][data][211]} {axi_00_in_i[w][data][212]} {axi_00_in_i[w][data][213]} {axi_00_in_i[w][data][214]} {axi_00_in_i[w][data][215]} {axi_00_in_i[w][data][216]} {axi_00_in_i[w][data][217]} {axi_00_in_i[w][data][218]} {axi_00_in_i[w][data][219]} {axi_00_in_i[w][data][220]} {axi_00_in_i[w][data][221]} {axi_00_in_i[w][data][222]} {axi_00_in_i[w][data][223]} {axi_00_in_i[w][data][224]} {axi_00_in_i[w][data][225]} {axi_00_in_i[w][data][226]} {axi_00_in_i[w][data][227]} {axi_00_in_i[w][data][228]} {axi_00_in_i[w][data][229]} {axi_00_in_i[w][data][230]} {axi_00_in_i[w][data][231]} {axi_00_in_i[w][data][232]} {axi_00_in_i[w][data][233]} {axi_00_in_i[w][data][234]} {axi_00_in_i[w][data][235]} {axi_00_in_i[w][data][236]} {axi_00_in_i[w][data][237]} {axi_00_in_i[w][data][238]} {axi_00_in_i[w][data][239]} {axi_00_in_i[w][data][240]} {axi_00_in_i[w][data][241]} {axi_00_in_i[w][data][242]} {axi_00_in_i[w][data][243]} {axi_00_in_i[w][data][244]} {axi_00_in_i[w][data][245]} {axi_00_in_i[w][data][246]} {axi_00_in_i[w][data][247]} {axi_00_in_i[w][data][248]} {axi_00_in_i[w][data][249]} {axi_00_in_i[w][data][250]} {axi_00_in_i[w][data][251]} {axi_00_in_i[w][data][252]} {axi_00_in_i[w][data][253]} {axi_00_in_i[w][data][254]} {axi_00_in_i[w][data][255]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {axi_00_in_i[ar][burst][0]} {axi_00_in_i[ar][burst][1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 6 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {axi_00_in_i[aw][id][0]} {axi_00_in_i[aw][id][1]} {axi_00_in_i[aw][id][2]} {axi_00_in_i[aw][id][3]} {axi_00_in_i[aw][id][4]} {axi_00_in_i[aw][id][5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 33 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {axi_00_in_i[aw][addr][0]} {axi_00_in_i[aw][addr][1]} {axi_00_in_i[aw][addr][2]} {axi_00_in_i[aw][addr][3]} {axi_00_in_i[aw][addr][4]} {axi_00_in_i[aw][addr][5]} {axi_00_in_i[aw][addr][6]} {axi_00_in_i[aw][addr][7]} {axi_00_in_i[aw][addr][8]} {axi_00_in_i[aw][addr][9]} {axi_00_in_i[aw][addr][10]} {axi_00_in_i[aw][addr][11]} {axi_00_in_i[aw][addr][12]} {axi_00_in_i[aw][addr][13]} {axi_00_in_i[aw][addr][14]} {axi_00_in_i[aw][addr][15]} {axi_00_in_i[aw][addr][16]} {axi_00_in_i[aw][addr][17]} {axi_00_in_i[aw][addr][18]} {axi_00_in_i[aw][addr][19]} {axi_00_in_i[aw][addr][20]} {axi_00_in_i[aw][addr][21]} {axi_00_in_i[aw][addr][22]} {axi_00_in_i[aw][addr][23]} {axi_00_in_i[aw][addr][24]} {axi_00_in_i[aw][addr][25]} {axi_00_in_i[aw][addr][26]} {axi_00_in_i[aw][addr][27]} {axi_00_in_i[aw][addr][28]} {axi_00_in_i[aw][addr][29]} {axi_00_in_i[aw][addr][30]} {axi_00_in_i[aw][addr][31]} {axi_00_in_i[aw][addr][32]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 48 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {w_clk_cnt[0]} {w_clk_cnt[1]} {w_clk_cnt[2]} {w_clk_cnt[3]} {w_clk_cnt[4]} {w_clk_cnt[5]} {w_clk_cnt[6]} {w_clk_cnt[7]} {w_clk_cnt[8]} {w_clk_cnt[9]} {w_clk_cnt[10]} {w_clk_cnt[11]} {w_clk_cnt[12]} {w_clk_cnt[13]} {w_clk_cnt[14]} {w_clk_cnt[15]} {w_clk_cnt[16]} {w_clk_cnt[17]} {w_clk_cnt[18]} {w_clk_cnt[19]} {w_clk_cnt[20]} {w_clk_cnt[21]} {w_clk_cnt[22]} {w_clk_cnt[23]} {w_clk_cnt[24]} {w_clk_cnt[25]} {w_clk_cnt[26]} {w_clk_cnt[27]} {w_clk_cnt[28]} {w_clk_cnt[29]} {w_clk_cnt[30]} {w_clk_cnt[31]} {w_clk_cnt[32]} {w_clk_cnt[33]} {w_clk_cnt[34]} {w_clk_cnt[35]} {w_clk_cnt[36]} {w_clk_cnt[37]} {w_clk_cnt[38]} {w_clk_cnt[39]} {w_clk_cnt[40]} {w_clk_cnt[41]} {w_clk_cnt[42]} {w_clk_cnt[43]} {w_clk_cnt[44]} {w_clk_cnt[45]} {w_clk_cnt[46]} {w_clk_cnt[47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 3 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {axi_00_in_i[aw][size][0]} {axi_00_in_i[aw][size][1]} {axi_00_in_i[aw][size][2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {axi_00_in_i[w][strb][0]} {axi_00_in_i[w][strb][1]} {axi_00_in_i[w][strb][2]} {axi_00_in_i[w][strb][3]} {axi_00_in_i[w][strb][4]} {axi_00_in_i[w][strb][5]} {axi_00_in_i[w][strb][6]} {axi_00_in_i[w][strb][7]} {axi_00_in_i[w][strb][8]} {axi_00_in_i[w][strb][9]} {axi_00_in_i[w][strb][10]} {axi_00_in_i[w][strb][11]} {axi_00_in_i[w][strb][12]} {axi_00_in_i[w][strb][13]} {axi_00_in_i[w][strb][14]} {axi_00_in_i[w][strb][15]} {axi_00_in_i[w][strb][16]} {axi_00_in_i[w][strb][17]} {axi_00_in_i[w][strb][18]} {axi_00_in_i[w][strb][19]} {axi_00_in_i[w][strb][20]} {axi_00_in_i[w][strb][21]} {axi_00_in_i[w][strb][22]} {axi_00_in_i[w][strb][23]} {axi_00_in_i[w][strb][24]} {axi_00_in_i[w][strb][25]} {axi_00_in_i[w][strb][26]} {axi_00_in_i[w][strb][27]} {axi_00_in_i[w][strb][28]} {axi_00_in_i[w][strb][29]} {axi_00_in_i[w][strb][30]} {axi_00_in_i[w][strb][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 48 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {w_cnt[0]} {w_cnt[1]} {w_cnt[2]} {w_cnt[3]} {w_cnt[4]} {w_cnt[5]} {w_cnt[6]} {w_cnt[7]} {w_cnt[8]} {w_cnt[9]} {w_cnt[10]} {w_cnt[11]} {w_cnt[12]} {w_cnt[13]} {w_cnt[14]} {w_cnt[15]} {w_cnt[16]} {w_cnt[17]} {w_cnt[18]} {w_cnt[19]} {w_cnt[20]} {w_cnt[21]} {w_cnt[22]} {w_cnt[23]} {w_cnt[24]} {w_cnt[25]} {w_cnt[26]} {w_cnt[27]} {w_cnt[28]} {w_cnt[29]} {w_cnt[30]} {w_cnt[31]} {w_cnt[32]} {w_cnt[33]} {w_cnt[34]} {w_cnt[35]} {w_cnt[36]} {w_cnt[37]} {w_cnt[38]} {w_cnt[39]} {w_cnt[40]} {w_cnt[41]} {w_cnt[42]} {w_cnt[43]} {w_cnt[44]} {w_cnt[45]} {w_cnt[46]} {w_cnt[47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 32 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {r_frm_cnt[0]} {r_frm_cnt[1]} {r_frm_cnt[2]} {r_frm_cnt[3]} {r_frm_cnt[4]} {r_frm_cnt[5]} {r_frm_cnt[6]} {r_frm_cnt[7]} {r_frm_cnt[8]} {r_frm_cnt[9]} {r_frm_cnt[10]} {r_frm_cnt[11]} {r_frm_cnt[12]} {r_frm_cnt[13]} {r_frm_cnt[14]} {r_frm_cnt[15]} {r_frm_cnt[16]} {r_frm_cnt[17]} {r_frm_cnt[18]} {r_frm_cnt[19]} {r_frm_cnt[20]} {r_frm_cnt[21]} {r_frm_cnt[22]} {r_frm_cnt[23]} {r_frm_cnt[24]} {r_frm_cnt[25]} {r_frm_cnt[26]} {r_frm_cnt[27]} {r_frm_cnt[28]} {r_frm_cnt[29]} {r_frm_cnt[30]} {r_frm_cnt[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 48 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {r_clk_cnt[0]} {r_clk_cnt[1]} {r_clk_cnt[2]} {r_clk_cnt[3]} {r_clk_cnt[4]} {r_clk_cnt[5]} {r_clk_cnt[6]} {r_clk_cnt[7]} {r_clk_cnt[8]} {r_clk_cnt[9]} {r_clk_cnt[10]} {r_clk_cnt[11]} {r_clk_cnt[12]} {r_clk_cnt[13]} {r_clk_cnt[14]} {r_clk_cnt[15]} {r_clk_cnt[16]} {r_clk_cnt[17]} {r_clk_cnt[18]} {r_clk_cnt[19]} {r_clk_cnt[20]} {r_clk_cnt[21]} {r_clk_cnt[22]} {r_clk_cnt[23]} {r_clk_cnt[24]} {r_clk_cnt[25]} {r_clk_cnt[26]} {r_clk_cnt[27]} {r_clk_cnt[28]} {r_clk_cnt[29]} {r_clk_cnt[30]} {r_clk_cnt[31]} {r_clk_cnt[32]} {r_clk_cnt[33]} {r_clk_cnt[34]} {r_clk_cnt[35]} {r_clk_cnt[36]} {r_clk_cnt[37]} {r_clk_cnt[38]} {r_clk_cnt[39]} {r_clk_cnt[40]} {r_clk_cnt[41]} {r_clk_cnt[42]} {r_clk_cnt[43]} {r_clk_cnt[44]} {r_clk_cnt[45]} {r_clk_cnt[46]} {r_clk_cnt[47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 2 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {axi_00_out_i[r][resp][0]} {axi_00_out_i[r][resp][1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 4 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {axi_00_in_i[aw][len][0]} {axi_00_in_i[aw][len][1]} {axi_00_in_i[aw][len][2]} {axi_00_in_i[aw][len][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 2 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {axi_00_in_i[aw][burst][0]} {axi_00_in_i[aw][burst][1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 6 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {axi_00_out_i[b][id][0]} {axi_00_out_i[b][id][1]} {axi_00_out_i[b][id][2]} {axi_00_out_i[b][id][3]} {axi_00_out_i[b][id][4]} {axi_00_out_i[b][id][5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 4 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {axi_00_in_i[ar][len][0]} {axi_00_in_i[ar][len][1]} {axi_00_in_i[ar][len][2]} {axi_00_in_i[ar][len][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 6 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {axi_00_in_i[ar][id][0]} {axi_00_in_i[ar][id][1]} {axi_00_in_i[ar][id][2]} {axi_00_in_i[ar][id][3]} {axi_00_in_i[ar][id][4]} {axi_00_in_i[ar][id][5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 33 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {axi_00_in_i[ar][addr][0]} {axi_00_in_i[ar][addr][1]} {axi_00_in_i[ar][addr][2]} {axi_00_in_i[ar][addr][3]} {axi_00_in_i[ar][addr][4]} {axi_00_in_i[ar][addr][5]} {axi_00_in_i[ar][addr][6]} {axi_00_in_i[ar][addr][7]} {axi_00_in_i[ar][addr][8]} {axi_00_in_i[ar][addr][9]} {axi_00_in_i[ar][addr][10]} {axi_00_in_i[ar][addr][11]} {axi_00_in_i[ar][addr][12]} {axi_00_in_i[ar][addr][13]} {axi_00_in_i[ar][addr][14]} {axi_00_in_i[ar][addr][15]} {axi_00_in_i[ar][addr][16]} {axi_00_in_i[ar][addr][17]} {axi_00_in_i[ar][addr][18]} {axi_00_in_i[ar][addr][19]} {axi_00_in_i[ar][addr][20]} {axi_00_in_i[ar][addr][21]} {axi_00_in_i[ar][addr][22]} {axi_00_in_i[ar][addr][23]} {axi_00_in_i[ar][addr][24]} {axi_00_in_i[ar][addr][25]} {axi_00_in_i[ar][addr][26]} {axi_00_in_i[ar][addr][27]} {axi_00_in_i[ar][addr][28]} {axi_00_in_i[ar][addr][29]} {axi_00_in_i[ar][addr][30]} {axi_00_in_i[ar][addr][31]} {axi_00_in_i[ar][addr][32]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 6 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {axi_00_out_i[r][id][0]} {axi_00_out_i[r][id][1]} {axi_00_out_i[r][id][2]} {axi_00_out_i[r][id][3]} {axi_00_out_i[r][id][4]} {axi_00_out_i[r][id][5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 32 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {w_frm_cnt[0]} {w_frm_cnt[1]} {w_frm_cnt[2]} {w_frm_cnt[3]} {w_frm_cnt[4]} {w_frm_cnt[5]} {w_frm_cnt[6]} {w_frm_cnt[7]} {w_frm_cnt[8]} {w_frm_cnt[9]} {w_frm_cnt[10]} {w_frm_cnt[11]} {w_frm_cnt[12]} {w_frm_cnt[13]} {w_frm_cnt[14]} {w_frm_cnt[15]} {w_frm_cnt[16]} {w_frm_cnt[17]} {w_frm_cnt[18]} {w_frm_cnt[19]} {w_frm_cnt[20]} {w_frm_cnt[21]} {w_frm_cnt[22]} {w_frm_cnt[23]} {w_frm_cnt[24]} {w_frm_cnt[25]} {w_frm_cnt[26]} {w_frm_cnt[27]} {w_frm_cnt[28]} {w_frm_cnt[29]} {w_frm_cnt[30]} {w_frm_cnt[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 2 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {axi_00_out_i[b][resp][0]} {axi_00_out_i[b][resp][1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {axi_00_in_i[ar][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {axi_00_in_i[aw][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {axi_00_in_i[bready]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {axi_00_in_i[rready]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {axi_00_in_i[w][last]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {axi_00_in_i[w][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {axi_00_out_i[arready]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list {axi_00_out_i[awready]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list {axi_00_out_i[b][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list {axi_00_out_i[r][last]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list {axi_00_out_i[r][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list {axi_00_out_i[wready]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list r_clk_cnt_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list read_error]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list rw_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list w_clk_cnt_en]]
set_property C_CLK_INPUT_FREQ_HZ 100000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets apb_clk]
