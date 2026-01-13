/*------------------------------------------------------------------------------
 * File          : gbdt_top.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps

module gbdt_top(cpu_p_write, p_addr, p_wdata, p_rdata, p_ready, done, p_sel, DMA_data, DMA_valid, 
		   gbdt_clk, gbdt_rst_n);

// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

input logic 	gbdt_clk;
input logic 	gbdt_rst_n;
output logic	done;

// -----------------------------------------------------------       
//                  APB Interface 
// -----------------------------------------------------------  

output logic  [`DATA_WIDTH-1:0]  p_rdata; //c_tso_obus
output logic  	 	             p_ready; //c_tso_rdy



input logic                      cpu_p_write;  
input logic  [`ADDR_WIDTH-1:0]   p_addr; //c_add
input logic  [`DATA_WIDTH-1:0]   p_wdata;  //c_bus_in
input logic					  	 p_sel;

// -----------------------------------------------------------       
//                  DMA Interface 
// ----------------------------------------------------------- 

input logic	   [`DMA_RATE-1:0]	 DMA_data;
input logic						 DMA_valid;

 // ----------------------------------------------------------------------
 //                   Internal logic
 // ----------------------------------------------------------------------

logic   [31:0] new_max_result;
logic   [31:0] old_max_result;
logic   [4:0]  new_max_class;
logic   [4:0]  old_max_class;
logic   [31:0]  used_classes;
logic          gbdt_start;
 
logic		   oe;
logic		   we;
logic		   cs;
logic   [1:0]  round;

wire  [`RAM_DATA_WIDTH-1:0] data_from_rams [7:0];
logic   [`RAM_ADDR_WIDTH-1:0] ram_address [7:0];
 // ----------------------------------------------------------------------
 //                   Instantiation
 // ----------------------------------------------------------------------
 gbdt_regfile_LABRAMS gbdt_regfile(   
			.gbdt_clk		(gbdt_clk),
			.gbdt_rst_n		(gbdt_rst_n),
			.gbdt_start     (gbdt_start),
			.p_rdata		(p_rdata[`DATA_WIDTH-1:0]),
			.p_write		(cpu_p_write),
			.p_sel			(p_sel),
			.p_ready		(p_ready),
			.p_addr			(p_addr[`ADDR_WIDTH-1:0]),
			.p_wdata		(p_wdata[`DATA_WIDTH-1:0]),
			.used_classes	(used_classes),
			.new_max_result	(new_max_result),
			.new_max_class	(new_max_class),
			.old_max_result	(old_max_result),
			.old_max_class	(old_max_class),
			.data_from_rams	(data_from_rams),
			.we				(we),
			.cs				(cs),
			.oe				(oe),
			.round			(round),
			.ram_address	(ram_address)
	   );
 
 gbdt_core gbdt_core(
			.gbdt_clk		(gbdt_clk),
			.gbdt_rst_n		(gbdt_rst_n),
			
			.data_from_rams (data_from_rams),
			
			.gbdt_start     (gbdt_start),
			.old_max_result	(old_max_result),
			.old_max_class	(old_max_class),
			.new_max_result	(new_max_result),
			.new_max_class	(new_max_class),
			.done			(done),
			.used_classes	(used_classes),
			
			.DMA_valid		(DMA_valid),
			.DMA_data		(DMA_data),
			
			.oe				(oe),
			.we				(we),
			.cs				(cs),
			.round			(round),
			
			.ram_address	(ram_address)
 );

endmodule