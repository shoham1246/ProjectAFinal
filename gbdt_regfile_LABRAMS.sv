/*------------------------------------------------------------------------------
 * File          : gbdt_regfile.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps

module gbdt_regfile_LABRAMS (p_write, p_addr, p_wdata, gbdt_clk, gbdt_rst_n, new_max_result, new_max_class, p_sel, round, we, cs, oe, ram_address,
					 p_rdata, p_ready, used_classes, old_max_result, old_max_class, data_from_rams, gbdt_start);

// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

input logic		gbdt_clk;
input logic     gbdt_rst_n;


// -----------------------------------------------------------       
//                  APB Interface 
// -----------------------------------------------------------  

 output logic [`DATA_WIDTH-1:0]  p_rdata;
 output logic	 	           	 p_ready;

 input logic                     p_write;  
 input logic  [`ADDR_WIDTH-1:0]  p_addr; 
 input logic  [`DATA_WIDTH-1:0]  p_wdata;
 input logic					 p_sel;
 
 
 // -----------------------------------------------------------       
 //                  core Interface 
 // ----------------------------------------------------------- 
 
output logic  [31:0]  used_classes;
output  logic [31:0] old_max_result;
output  logic [4:0]  old_max_class;
inout wire  [`RAM_DATA_WIDTH-1:0] data_from_rams [7:0];  // 8 group data buses (nets). fix everywhere!!
output logic		 gbdt_start;


input logic   [31:0] new_max_result;
input logic   [4:0]  new_max_class;
input logic   [1:0]  round; // selects which RAM-per-group is active (0..3)
input logic   [`RAM_ADDR_WIDTH-1:0] ram_address [7:0];

input logic  		 we; // global: 1 = write, 0 = read
input logic		     cs; 
input logic		     oe; 

// -----------------------------------------------------------       
//                   Parameters for layout
// ----------------------------------------------------------- 
localparam int NUM_GROUPS = 8;
localparam int RAMS_PER_GROUP = 4;
localparam int TOTAL_RAMS = NUM_GROUPS * RAMS_PER_GROUP;

// -----------------------------------------------------------       
//         Internal registers used by APB interface
// -----------------------------------------------------------  
 logic    [`RAM_ADDR_WIDTH-1:0] gbdt_ram_addr;
 logic    [`RAM_DATA_WIDTH-1:0]	gbdt_ram_data;
 logic    [TOTAL_RAMS-1:0]		gbdt_ram_sel;

// -----------------------------------------------------------       
//         Ram control nets (one per RAM)
// ----------------------------------------------------------- 

 logic [TOTAL_RAMS-1:0] ram_oe, ram_cs;             // control signals


 // -----------------------------------------------------------       
 //            APB I/F
 // -----------------------------------------------------------   
 
//writing phases: wr reg_addr -> wr reg_data -> wr ram access
//reading phases: wr reg_addr -> rd ram access -> rd reg_data 	 
																																														 
 //a. gbdt_ram_addr
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	if (!gbdt_rst_n) 								       			gbdt_ram_addr  <=  #1 '0;                              // REG0 disabled (default).
	else if (p_write && p_sel && (p_addr == `GBDT_RAM_ADDR_ADDR))   gbdt_ram_addr  <=  #1 p_wdata[`RAM_ADDR_WIDTH-1:0]; 
 
 //b. gbdt_ram_data
 // write. must happen in the cycle after the APB transfer to gbdt_ram_addr
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 								   	   			gbdt_ram_data <= #1 '0;                               // REG0 disabled (default).
	 else if (p_write && p_sel && (p_addr == `GBDT_RAM_DATA_ADDR))  gbdt_ram_data <= #1 p_wdata[`RAM_DATA_WIDTH-1:0]; 	 

 // read. must happen 2 cycles after the cycle of APB transfer for gbdt_ram_addr
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 									       		p_rdata <= #1 '0;                        // REG0 disabled (default).
	 else if (!p_write && p_sel && (p_addr == `GBDT_RAM_DATA_ADDR)) p_rdata <= #1 gbdt_ram_data; 
	 else if (!p_write && p_sel && (p_addr == `REG_MAX_CLASS)) 		p_rdata <= #1 {27'b0, old_max_class}; 
	 else if (!p_write && p_sel && (p_addr == `REG_MAX_SCORE)) 		p_rdata <= #1 old_max_result; 
	 else                                 				       		p_rdata <= #1 '0;
 
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 									       		p_ready <= #1 '0;                                                   // REG0 disabled (default).
	 else if (p_sel) 												p_ready <= #1 1'b1;
	 else                               							p_ready <= #1 '0;

//////// start & sel registers:

//start process
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 								       			gbdt_start  <=  #1 '0;                              // REG0 disabled (default).
	 else if (p_write && p_sel && (p_addr == `GBDT_START_ADDR))   	gbdt_start  <=  #1 p_wdata[0]; //mustn't do start=1 till the current input is done
	 else															gbdt_start  <=  #1 '0;
 
//switching ram (while writing)
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 								       			gbdt_ram_sel  <=  #1 '0;                              // REG0 disabled (default).
	 else if (p_write && p_sel && (p_addr == `GBDT_SEL_ADDR))   	gbdt_ram_sel  <=  #1 p_wdata; //changes in every class switching


/* 
 //validity check
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 									  $display("[%0t] reset and REG0 IS %b", $time, REG0);
	 else 												  $display("[%0t] reg0: %b reg1: %b p_rdata: %b", $time, REG0, REG1, p_rdata);//$display("[%0t] REG0 IS %b & REG1 IS %b", $time, REG0, REG1);
*/

// -----------------------------------------------------------       
//            ram I/F
// -----------------------------------------------------------
  
 // -----------------------
 // Instantiate 32 RAMs (4 per group). Each group's 4 RAMs share:
 //   - one address bus (ram_address[g])
 //   - one tri-state data bus (data_from_rams[g])
 // During read mode (we==0) only the selected RAM (per group) enables its output onto the shared bus.
 // During write mode (we==1) we use gbdt_ram_addr / gbdt_ram_data and gbdt_ram_sel selects the target RAM by index.
 // -----------------------
 
 
 genvar g, r, s;
 generate
   for (g = 0; g < NUM_GROUPS; g++) begin : RAMS_CLASS
	 wire [`RAM_DATA_WIDTH-1:0] data_group_bus;
	 
	 // Connect the group bus to the output port
	 assign data_from_rams[g] = data_group_bus;

	 // Loop for the 4 Classes per Group (Total 32 Classes)
	 for (r = 0; r < RAMS_PER_GROUP; r++) begin : RAMS
	   localparam int read_index = g + NUM_GROUPS * r; //maps to: 0,4,8,12 , 1,5,9,13  , 2,6,10,14 , 3,7,11,15 ,

	   wire [`RAM_ADDR_WIDTH-1:0] addr_sel;
	   wire                       cs_sel;
	   wire                       oe_sel;
	   
	   // Select address source: Write (APB) or Read (Core)
	   // Assuming 'addr_sel' holds the full 14 bits (or sufficient width)
	   assign addr_sel = (we) ? gbdt_ram_addr : ram_address[g];

	   // Base Chip Select for the Class
	   assign cs_sel   = (we) ? gbdt_ram_sel[read_index] : ram_cs[read_index];

	   // Output Enable
	   assign oe_sel   = (we) ? oe : ram_oe[read_index];

	   // ---------------------------------------------------------
	   // Sub-RAMs Loop: 4 small RAMs (4096 depth) per Class
	   // ---------------------------------------------------------
	   for (s = 0; s < 4; s++) begin : SUB_RAMS
		 
		 // 1. Address Decoding
		 // Use MSBs [13:12] to select the active sub-RAM
		 wire [1:0]  bank_select;
		 wire [11:0] ram_addr_phys;
		 
		 assign bank_select   = addr_sel[13:12];
		 assign ram_addr_phys = addr_sel[11:0];

		 // 2. Sub-RAM Chip Select
		 // Active only if the Parent Class is selected AND the Bank bits match 's'
		 wire sub_cs;
		 assign sub_cs = cs_sel && (bank_select == s[1:0]);

		 // 3. Separate Output Wire for this RAM
		 wire [`RAM_DATA_WIDTH-1:0] ram_dout;

		 // 4. Instantiation of the new RAM module
		 // "ram32x4096" with separate din/dout
		 spram32x4096_cb ram_inst (
		   .CEB     (!gbdt_clk),
		   .A 		(ram_addr_phys), // 12-bit address
		   .I     	(gbdt_ram_data), // Direct Write Data Input
		   .CSB     (!sub_cs),        // Decoded CS
		   .WEB     (!we),
		   .OEB     (!oe_sel),
		   .O    	(ram_dout)       // Separate Data Output
		   // Add other ports if necessary (e.g., reset)
		 );

		 // 5. Tri-state Logic for the Shared Bus
		 // If this RAM is selected for READ (cs & oe & !we), drive the bus.
		 // Otherwise, high-impedance.
		 assign data_group_bus = (sub_cs && oe_sel && !we) ? ram_dout : 'bz;
		 
	   end // End SUB_RAMS loop
	 end // End RAMS loop
   end // End RAMS_CLASS loop
 endgenerate
 
 /*
 genvar g, r;
 generate
   for (g = 0; g < NUM_GROUPS; g++) begin : RAMS_CLASS
	 wire [`RAM_DATA_WIDTH-1:0] data_group_bus;
	 wire [`RAM_DATA_WIDTH-1:0] d_in;
	 wire [`RAM_DATA_WIDTH-1:0] d_out;
	 // Choose between read and write sources at runtime
	 assign data_group_bus = (we) ? gbdt_ram_data : 'bz; //write uses gbdt_ram_data (driven by APB master), read loading to group data bus (driven by selected RAM)
	 assign data_from_rams[g] = data_group_bus;
	 assign d_in = oe ? 'bz : data_group_bus;
	 assign d_out = oe ? data_group_bus : 'bz;
	 
	 for (r = 0; r < RAMS_PER_GROUP; r++) begin : RAMS
	   localparam int read_index = g + NUM_GROUPS * r; //maps to: 0,4,8,12 , 1,5,9,13  , 2,6,10,14 , 3,7,11,15 , 

	   wire [`RAM_ADDR_WIDTH-1:0] addr_sel;
	   wire                  	 cs_sel;
	   wire                  	 oe_sel;
	   // Choose between read and write sources at runtime
	   assign addr_sel = (we) ? gbdt_ram_addr : ram_address[g];
	   assign cs_sel   = (we) ? gbdt_ram_sel[read_index] : ram_cs[read_index];
	   assign oe_sel   = (we) ? oe : ram_oe[read_index];
	   
	   // Use MSBs [13:12] to select the active sub-RAM
	   wire [11:0] ram_addr_phys;
	   assign ram_addr_phys = addr_sel[11:0];

	   // Instantiate a single RAM per loop iteration
	   spram32x4096_cb ram_inst (
		   .CEB     (!gbdt_clk),
		   .A 		(ram_addr_phys), // 12-bit address
		   .I     	(d_in), // Direct Write Data Input
		   .CSB     (!cs_sel),        // Decoded CS
		   .WEB     (!we),
		   .OEB     (!oe_sel),
		   .O    	(d_out)       // Separate Data Output
		   // Add other ports if necessary (e.g., reset)
		 );
	 end
   end
 endgenerate
 */
  
  // -----------------------------
  // Decode which RAMs are active.
  // round: 2-bit selects which ram-per-group (0..3)
  // For each group g (0..7) set exactly one index: g + (round * NUM_GROUPS)
  // -----------------------------
  always_comb begin
	ram_cs = '0;
	ram_oe = '0;
	for (int group = 0; group < NUM_GROUPS; group++) begin : RAM_CONTROL
	  //active_index = group + int'(round) * NUM_GROUPS;  // selects 0..31
	  ram_cs[group + int'(round) * NUM_GROUPS] = cs;
	  ram_oe[group + int'(round) * NUM_GROUPS] = oe;
	end
  end

// -----------------------------------------------------------       
//            core I/F
// -----------------------------------------------------------  
// ----------------------------       
//            1. class+score
// ----------------------------

 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	 if (!gbdt_rst_n) 		old_max_result <= #1 '0;
	 else				    old_max_result <= #1 new_max_result;
 end

 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	 if (!gbdt_rst_n) 		old_max_class <= #1 '0;
	 else				    old_max_class <= #1 new_max_class;
 end

 // -----------------------------       
 //            2. num of classes
 // -----------------------------
 always_ff @(posedge gbdt_clk or negedge gbdt_rst_n)
	 if (!gbdt_rst_n) 								       			used_classes  <=  #1 32'hffffffff; 		// 32 classifications (default).
	 else if (p_write && p_sel && (p_addr == `GBDT_USEDCLASS_ADDR))  used_classes  <=  #1 p_wdata; 

endmodule