    MSTR_OUT_{0}({1}).arvalid        <=  mstr_out_{2}_vec({1}).arvalid(0); 
    MSTR_OUT_{0}({1}).awvalid        <=  mstr_out_{2}_vec({1}).awvalid(0); 
    MSTR_OUT_{0}({1}).wvalid         <=  mstr_out_{2}_vec({1}).wvalid(0) ; 
    MSTR_OUT_{0}({1}).bready         <=  mstr_out_{2}_vec({1}).bready(0) ; 
    MSTR_OUT_{0}({1}).rready         <=  mstr_out_{2}_vec({1}).rready(0) ; 
    MSTR_OUT_{0}({1}).arlock         <=  mstr_out_{2}_vec({1}).arlock(0) ; 
    MSTR_OUT_{0}({1}).awlock         <=  mstr_out_{2}_vec({1}).awlock(0) ; 
    MSTR_OUT_{0}({1}).wlast          <=  mstr_out_{2}_vec({1}).wlast(0) ; 
    
    mstr_in_{2}_vec({1}).wready(0)   <=   MSTR_IN_{0}({1}).wready ;
    mstr_in_{2}_vec({1}).bvalid(0)   <=   MSTR_IN_{0}({1}).bvalid ;
    mstr_in_{2}_vec({1}).arready(0)  <=   MSTR_IN_{0}({1}).arready;
    mstr_in_{2}_vec({1}).awready(0)  <=   MSTR_IN_{0}({1}).awready;
    mstr_in_{2}_vec({1}).rvalid(0)   <=   MSTR_IN_{0}({1}).rvalid ;
    mstr_in_{2}_vec({1}).rlast(0)    <=   MSTR_IN_{0}({1}).rlast ;

