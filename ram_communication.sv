/*------------------------------------------------------------------------------
 * File          : ram_communication.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps

module ram_communication (gbdt_clk, gbdt_rst_n, data_from_rams, nxt_node_abs_addr, enable, done,
						  abs_cur_addr,is_leaf, rel_right_child, rel_left_child, cmp_value, feature_num, leaf_val, ADDRtoRAMs, finish_condition, start_new_round);

// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic  [13:0] abs_cur_addr;
output logic  [13:0] ADDRtoRAMs;

output logic         is_leaf;          //from node_prop[0]
output logic  [6:0]  rel_right_child;    //node_prop[7:1]
output logic  [6:0]  rel_left_child;     //node_prop[14:8]
output logic  [8:0]  cmp_value;          //node_prop[23:15]
output logic  [7:0]  feature_num;        //from node_prop[31:24]

output logic [15:0]  leaf_val;         //from node_prop[31:16]

output  logic        finish_condition;
output  logic        start_new_round;

input logic          gbdt_clk;
input logic          gbdt_rst_n;

input wire   [31:0]  data_from_rams;

input logic  [13:0]  nxt_node_abs_addr;
input logic			 done;

input logic			 enable;

// -----------------------------------------------------------       
//                  Internal signals 
// ----------------------------------------------------------- 

logic				is_last_tree;
logic        		enable_last_cycle; // reg For edge detection
logic	[13:0]		next_tree;
logic   [13:0]		next_node_addr_mux;


// -----------------------------------------------------------       
//                  logic
// -----------------------------------------------------------

always_comb begin

	is_leaf = data_from_rams[0];
	
	//not leaf
	rel_right_child = data_from_rams[7:1];
	rel_left_child = data_from_rams[14:8];
	cmp_value = data_from_rams[23:15];
	feature_num = data_from_rams[31:24];
	
	//leaf
	is_last_tree = data_from_rams[1];
	next_tree = data_from_rams[15:2];
	leaf_val = data_from_rams[31:16];
	
end




// This logic detects the start of a new round:
// a rising edge of 'enable' when we are 'done'
assign start_new_round = (enable & !enable_last_cycle) & done;     // We were idle, and just got a rising edge on 'enable'.

// 'FINISH' register input
assign finish_condition = is_leaf & is_last_tree;

// Final Mux to select the next node address
assign next_node_addr_mux = (is_leaf) ? next_tree : nxt_node_abs_addr;




 
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)							enable_last_cycle <= #1 1'b0;
	else 										enable_last_cycle <= #1 enable;			// --- ALWAYS Update enable_last_cycle ---
end
 
//abs_cur_addr is register:
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)										abs_cur_addr <= #1 14'd0;
	else if (start_new_round)								abs_cur_addr <= #1 14'd0;      			// Start working from address 0
	else if (enable & !done & finish_condition)			abs_cur_addr <= #1 14'd0;      			// We just hit the last leaf. Go to idle address 
	else if (enable & !done & !finish_condition)		abs_cur_addr <= #1 next_node_addr_mux; 	// finish_reg stays 0 (working). Go to next node
end

// ADDRtoRAMs will not be a register
assign ADDRtoRAMs = (start_new_round || done) ? 14'b0 : next_node_addr_mux;

endmodule