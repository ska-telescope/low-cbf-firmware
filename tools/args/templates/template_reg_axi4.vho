---------------------------------------------------------------------------------------
--
--  This file was automatically generated from ARGS config file <lib>.peripheral.yaml
--  and template file template_reg_axi4.vho
--
--  This is the instantiation template for the <lib_name> register slave.
--
--
---------------------------------------------------------------------------------------
LIBRARY <lib>_lib;
USE <lib>_lib.<lib_name>_reg_pkg.ALL;

ENTITY <lib>_lib.<lib_name>_reg 
    PORT MAP (
        CLK            <tabs>=> ,
        RST            <tabs>=> ,
        SLA_IN.awaddr  <tabs>=> ,
        SLA_IN.awvalid <tabs>=> ,
        SLA_IN.wdata   <tabs>=> ,
        SLA_IN.wstrb   <tabs>=> ,
        SLA_IN.wvalid  <tabs>=> ,
        SLA_IN.bready  <tabs>=> ,
        SLA_IN.araddr  <tabs>=> ,
        SLA_IN.arvalid <tabs>=> ,
        SLA_IN.rready  <tabs>=> ,
        SLA_OUT.awready<tabs>=> ,
        SLA_OUT.wready <tabs>=> ,
        SLA_OUT.bresp  <tabs>=> ,
        SLA_OUT.bvalid <tabs>=> ,
        SLA_OUT.arready<tabs>=> ,
        SLA_OUT.rdata  <tabs>=> ,
        SLA_OUT.rresp  <tabs>=> ,
        SLA_OUT.rvalid <tabs>=> ,
        <{slave_ports}>             

        );
