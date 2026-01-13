/*------------------------------------------------------------------------------
 * File          : classification.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module classification (gbdt_clk, gbdt_rst_n, feature_val, data_from_rams, enable, 
					   class_done, class_result, feature_num, ADDRtoRAMs);

// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic 		  class_done;
output logic  [31:0]  class_result;
output logic  [7:0]   feature_num;

output logic  [13:0]  ADDRtoRAMs;

input  logic          gbdt_clk;
input  logic          gbdt_rst_n;
input  logic  [8:0]   feature_val;
input wire   [31:0]   data_from_rams;
input logic			  enable;

// -----------------------------------------------------------       
//                  Internal signals 
// -----------------------------------------------------------

logic         is_leaf;            //from node_prop[0]
logic  [6:0]  rel_right_child;    //node_prop[7:1]
logic  [6:0]  rel_left_child;     //node_prop[14:8]
logic  [8:0]  cmp_value;          //node_prop[23:15]

logic [15:0]  leaf_val;         //from node_prop[31:16]

logic [13:0]  nxt_node_abs_addr;
logic [13:0]  abs_cur_addr;

logic 		  finish_condition;
logic 		  start_new_round;

// ----------------------------------------------------------------------
//                   Instantiation
// ----------------------------------------------------------------------
      

node_processing node_processing(   
			.nxt_node_abs_addr	(nxt_node_abs_addr),
			.feature_val		(feature_val),
			.abs_cur_addr		(abs_cur_addr),
			.rel_right_child 	(rel_right_child),
			.rel_left_child		(rel_left_child),
			.cmp_value			(cmp_value)
	   );

leaves_acc leaves_acc(   
			.gbdt_clk			(gbdt_clk),
			.gbdt_rst_n			(gbdt_rst_n),
			.is_leaf			(is_leaf),
			.leaf_val 			(leaf_val),
			.done				(class_done),
			.result				(class_result),
			.enable				(enable),
			.finish_condition	(finish_condition),
			.start_new_round	(start_new_round)
);

ram_communication ram_communication(   
			.gbdt_clk			(gbdt_clk),
			.gbdt_rst_n			(gbdt_rst_n),
			.is_leaf			(is_leaf),
			.leaf_val 			(leaf_val),
			.data_from_rams		(data_from_rams),
			.nxt_node_abs_addr	(nxt_node_abs_addr),
			.abs_cur_addr		(abs_cur_addr),
			.rel_right_child	(rel_right_child),   
			.rel_left_child		(rel_left_child), 
			.feature_num		(feature_num),
			.cmp_value			(cmp_value),
			.enable				(enable),
			.ADDRtoRAMs			(ADDRtoRAMs),
			.done				(class_done),
			.finish_condition	(finish_condition),
			.start_new_round    (start_new_round)
);

endmodule