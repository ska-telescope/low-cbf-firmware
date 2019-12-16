
library ieee, axi4_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use axi4_lib.axi4_lite_pkg.ALL;
-------------------------------------------------------------------------------
package lru_wr_exdes_top_pkg is

    TYPE gty_vio_debug_ro IS RECORD
        gtpowergood     : std_logic_vector(0 downto 0);
        rxbufstatus     : std_logic_vector(2 downto 0);  
        rxbyterealign: std_logic_vector(0 downto 0);  
        rxclkcorcnt: std_logic_vector(1 downto 0);  

        rxpmaresetdone  : std_logic_vector(0 downto 0);     
        txpmaresetdone  : std_logic_vector(0 downto 0);    

        everything_ready    : std_logic;
        txpll_lockdet       : std_logic;
        rxpll_lockdet        : std_logic;
        cpll_lockdet         : std_logic;
        
        rx_synced           : std_logic;
    END RECORD;
    
    TYPE gty_vio_debug_wo IS RECORD
        rxslide_en          : std_logic;
    END RECORD;
    
end lru_wr_exdes_top_pkg;

package body lru_wr_exdes_top_pkg is 

end lru_wr_exdes_top_pkg;