////------------------------------------------------------------------------------
////  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
////
////  This file contains confidential and proprietary information
////  of Xilinx, Inc. and is protected under U.S. and
////  international copyright and other intellectual property
////  laws.
////
////  DISCLAIMER
////  This disclaimer is not a license and does not grant any
////  rights to the materials distributed herewith. Except as
////  otherwise provided in a valid license issued to you by
////  Xilinx, and to the maximum extent permitted by applicable
////  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
////  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
////  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
////  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
////  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
////  (2) Xilinx shall not be liable (whether in contract or tort,
////  including negligence, or under any other theory of
////  liability) for any loss or damage of any kind or nature
////  related to, arising under or in connection with these
////  materials, including for any direct, or any indirect,
////  special, incidental, or consequential loss or damage
////  (including loss of data, profits, goodwill, or any type of
////  loss or damage suffered as a result of any action brought
////  by a third party) even if such damage or loss was
////  reasonably foreseeable or Xilinx had been advised of the
////  possibility of the same.
////
////  CRITICAL APPLICATIONS
////  Xilinx products are not designed or intended to be fail-
////  safe, or for use in any application requiring fail-safe
////  performance, such as life-support or safety devices or
////  systems, Class III medical devices, nuclear facilities,
////  applications related to the deployment of airbags, or any
////  other applications that could lead to death, personal
////  injury, or severe property or environmental damage
////  (individually and collectively, "Critical
////  Applications"). Customer assumes the sole risk and
////  liability of any use of Xilinx products in Critical
////  Applications, subject only to applicable laws and
////  regulations governing limitations on product liability.
////
////  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
////  PART OF THIS FILE AT ALL TIMES.
////------------------------------------------------------------------------------

`timescale 1fs/1fs
(* DowngradeIPIdentifiedWarnings="yes" *)
module ip_xcku040_mac10g_noaxi_axis_pkt_gen
 (
  input  wire        clk,
  input  wire        enable,
  input  wire        reset,
  input  wire tx_ovfout,
  input  wire tx_rdyout,
  output reg [64-1:0] tx_datain,
  output reg  tx_enain,
  output reg  tx_sopin,
  output reg  tx_eopin,
  output reg  tx_errin,
  output reg [3-1:0] tx_mtyin,
  input  wire [31:0] packet_count,
  input  wire        rx_lane_align,
  input  wire        insert_crc,
  output wire        time_out,
  output reg         busy,
  output wire        done,
  input wire [511:0] packet,
  input wire packet_avail,
  output wire packet_avail_reset,
  output wire [15:0] nof_tx_packets
);


  parameter integer FIXED_PACKET_LENGTH = 9_000;
  parameter integer TRAF_MIN_LENGTH     = 64;
  parameter integer TRAF_MAX_LENGTH     = 9000;
               
  reg [1:0] dly_cntr;
  reg dly_rdyout;
  reg tx_enain_reg;
  reg [63:0] tx_datain_reg;
  reg tx_sopin_reg;
  reg tx_eopin_reg;
  reg tx_errin_reg;
  reg [2:0] tx_mtyin_reg;
  reg [15:0] nof_tx_packets_reg;

//  assign tx_reset                   = 1'b0;



  reg [1:0] q_en;
  reg [31:0] payload;
  wire [31:0] nxt_payload;
  wire [63:0] nxt_d;
  reg [63:0] d_buff;
  reg [31:0] counter;
  reg [2:0] bsy_cntr;
  
  reg  lane_mask;
  
  reg [29:0] op_timer;
  reg [31:0] packet_counter;
  reg en_stop;

  //leon: choose 1
  //wire ready =  rx_lane_align && tx_rdyout && ~tx_ovfout && packet_avail;
  wire ready =  rx_lane_align && tx_rdyout && ~tx_ovfout;
  
  
  localparam [31:0] init_data = 32'h21_22_23_24; // '!' '"' '#' '$'

/*
sudo nping -v4 -c 1 --icmp --icmp-seq 1 10.32.1.1 -S 10.32.1.2 --dest-mac 00:60:DD:46:DE:E3 --source-mac 1A:2B:3C:4D:5E:6F  --data-string "gemini0123456789abcdef"

Starting Nping 0.7.01 ( https://nmap.org/nping ) at 2017-08-22 12:28 AEST
SENT (0.0025s) ICMP [10.32.1.2 > 10.32.1.1 Echo request (type=8/code=0) id=36899 seq=1] IP [ver=4 ihl=5 tos=0x00 iplen=50 id=24876 foff=0 ttl=64 proto=1 csum=0x035d]
0000   00 60 dd 46 de e3 1a 2b  3c 4d 5e 6f 08 00 45 00  .`.F...+<M^o..E.
0010   00 32 61 2c 00 00 40 01  03 5d 0a 20 01 02 0a 20  .2a,..@..]......
0020   01 01 08 00 f5 6b 90 23  00 01 67 65 6d 69 6e 69  .....k.#..gemini
0030   30 31 32 33 34 35 36 37  38 39 61 62 63 64 65 66  0123456789abcdef

sudo nping -v4 -c 1 --udp -p 30000 10.32.1.2 -S 10.32.1.1 --source-mac 00:60:DD:46:DE:E3 --dest-mac 1A:2B:3C:4D:5E:6F  --data-string "gemini0123456789abcdef"

Starting Nping 0.7.01 ( https://nmap.org/nping ) at 2017-09-29 19:53 AEST
SENT (0.0023s) UDP [10.32.1.1:53 > 10.32.1.2:30000 len=30 csum=0x019B] IP [ver=4 ihl=5 tos=0x00 iplen=50 id=13751 foff=0 ttl=64 proto=17 csum=0x2ec2]
0000   1a 2b 3c 4d 5e 6f 00 60  dd 46 de e3 08 00 45 00  .+<M^o.`.F....E.
0010   00 32 35 b7 00 00 40 11  2e c2 0a 20 01 01 0a 20  .25...@.........
0020   01 02 00 35 75 30 00 1e  01 9b 67 65 6d 69 6e 69  ...5u0....gemini
0030   30 31 32 33 34 35 36 37  38 39 61 62 63 64 65 66  0123456789abcdef

*/


  localparam [47:0] source_addr = 48'h00_60_DD_46_DE_E3;  // perseus.atnf.csiro.au  (10G NIC on eth6)
  localparam [47:0] dest_addr   = 48'h1A_2B_3C_4D_5E_6F;  // me
  localparam [31:0] vlan_hdr    = 32'h81001234;           // 
  localparam [15:0] eth_type    = 16'h0800;               // eth type = IP
  localparam [15:0] iphdr       = 16'h4500;               // 
  localparam [15:0] iplen       = 16'h0032;               // 
  localparam [63:0] ipstuff     = 64'h61_2C_00_00_40_01_03_5D;
  localparam [63:0] ipstuff_udp = 64'h35_b7_00_00_40_11_2e_c2;
  localparam [31:0] ipsource    = 32'h0A_20_01_01;        // IP address source
  localparam [31:0] ipdest      = 32'h0A_20_01_02;        // IP address destination
  localparam [63:0] udphdr      = 64'h00_35_75_30_00_1e_01_9b;  // UDP header
  localparam [63:0] icmphdr     = 64'h08_00_F5_6B_90_23_00_01;  // ICMP header
  localparam [47:0] icmpdata    = 48'h67_65_6D_69_6E_69;        // ICMP data
  localparam [63:0] icmpdata1   = 64'h30_31_32_33_34_35_36_37;  // ICMP data
  localparam [63:0] icmpdata2   = 64'h38_39_61_62_63_64_65_66;  // ICMP data
  localparam [31:0] icmpdata3   = 32'h38_39_61_62;              // ICMP data


  localparam [511:0] eth_header = { dest_addr, source_addr, eth_type,             // without vlan   
  //localparam [511:0] eth_header = { dest_addr, source_addr, vlan_hdr, eth_type, // with vlan
  
  //                                  iphdr, iplen, ipstuff, ipsource, ipdest, // icmp 
                                    iphdr, iplen, ipstuff_udp, ipsource, ipdest, // udp
                                    
                                    
//                                    icmphdr, icmpdata, icmpdata1, icmpdata2} ; // icmp without vlan
//  //                                icmphdr, icmpdata, icmpdata1, icmpdata3} ; // icmp with vlan
  
                                    udphdr, icmpdata, icmpdata1, icmpdata2} ; // udp without vlan
//                                udphdr, icmpdata, icmpdata1, icmpdata3} ; // udp with vlan


  /* Parameter definitions of STATE variables for 2 bit state machine */
  localparam [2:0]  S0 = 3'b000,
                    S1 = 3'b001,
                    S2 = 3'b011,
                    S3 = 3'b010,
                    S4 = 3'b110,
                    S5 = 3'b111,
                    S6 = 3'b101,
                    S7 = 3'b100;
  
  reg [2:0] state;

ip_xcku040_mac10g_noaxi_payload_gen #(
  .BIT_COUNT(64)
) i_ip_xcku040_mac10g_noaxi_PAYLOAD_GEN (
  .ip(payload),
  .op(nxt_payload),
  .datout(nxt_d)
);

reg [8:0] header_bit_count ;

wire [16:0] pkt_len;
reg set_eop;
reg set_sop;
reg packet_avail_reset_reg;


ip_xcku040_mac10g_noaxi_pkt_len_gen
 #(
 .min(TRAF_MIN_LENGTH),
 .max(TRAF_MAX_LENGTH)
 ) i_ip_xcku040_mac10g_noaxi_PKT_LEN_GEN  (
  .clk      ( clk ),
  .reset   ( reset ),
  .enable   ( 1'b1 ),
  .pkt_len  ( pkt_len )
  );

assign time_out = ~|op_timer,
       done     = (state==S7);
assign packet_avail_reset = packet_avail_reset_reg;
assign nof_tx_packets = nof_tx_packets_reg;

always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 ) begin
    tx_datain <= 64'd0 ;
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;
    state <= S0;
    q_en <= 0;
    payload <= init_data;
    counter <= 0;
    d_buff <= 64'd0 ;
    op_timer <= 30'd390625000 ;
    set_eop <= 0;
    set_sop <= 0;
    lane_mask <= 0;
    packet_counter <= 0;
    bsy_cntr <= 0;
    en_stop <= 0;
    header_bit_count <= 0;
    packet_avail_reset_reg <= 0;
    nof_tx_packets_reg <= 0;
  end
  else begin
    tx_datain <= 64'd0 ;                // default to zero
    tx_enain <= 0 ;
    tx_sopin <= 0 ;
    tx_eopin <= 0 ;
    tx_errin <= 0 ;
    tx_mtyin <= 0 ;

    q_en <= {q_en, enable};

    case(state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: if (ready) state <= S2;
      S2: begin
            packet_avail_reset_reg <= 1;
            packet_counter <= packet_count;
            en_stop <= ~&packet_count;
            payload <= init_data;
            state <= S3;
          end
      S3: begin
            counter <= pkt_len-8;
            set_eop <= pkt_len<8;
            set_sop <= 1'b1;
            d_buff <= nxt_d;
            payload <= nxt_payload;
            state <= |packet_count ? S4 : S7;
             if ( en_stop ) packet_counter <= packet_counter-1;
            header_bit_count <= 9'd511;
          end
      S4: if (tx_rdyout) begin :zulu
            payload <= nxt_payload;
            d_buff <= nxt_d;
            tx_sopin <= set_sop;
            tx_eopin <= set_eop;
            tx_enain <= 1'b1;
            tx_datain <= d_buff;
            if(header_bit_count > 0) begin
                // leon: choose 1:
                tx_datain <= eth_header[header_bit_count-:64] ; // send request
                //tx_datain <= packet[header_bit_count-:64] ; // send reply
                header_bit_count <= header_bit_count - 64;
            end
            set_sop <= 0;
            if(set_eop)begin
              state <= (|packet_counter && |q_en) ? S3 : S7;
              packet_avail_reset_reg <= 0;
              counter <= pkt_len-8;
              set_eop <= pkt_len<8;
              header_bit_count <= 9'd511;
              tx_mtyin <= 8 - counter;
              nof_tx_packets_reg <= nof_tx_packets_reg +1;
            end
            else begin
              state <= S4;
              counter <= counter - 8;
              set_eop <= counter < 2*8;
            end
          end
          
      //S7: state <= |q_en ? S7 : S0;
      S7: begin
            q_en <= 0;
            state <= S0;
          end

    endcase

    case(state)
      S0,S7:   op_timer <= 30'd390625000 ;
      S4:      if(tx_rdyout) op_timer <= 30'd390625000 ;
      default: op_timer <= |op_timer ? op_timer - 1 : op_timer ;
    endcase

    if ( state <= S0 ) begin
      bsy_cntr <= |bsy_cntr ? bsy_cntr - 1 : bsy_cntr ;             // Hold the busy signal for 8 additional cycles.
      busy <= |bsy_cntr;
    end
    else begin
      busy <= 1'b1;
      bsy_cntr <= {3{1'b1}};
    end

  end
end


endmodule
