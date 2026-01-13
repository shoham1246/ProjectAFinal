/*------------------------------------------------------------------------------
 * File          : node_processing.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module node_processing (feature_val, abs_cur_addr, cmp_value, rel_right_child, rel_left_child,
	nxt_node_abs_addr);


// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic [13:0]  nxt_node_abs_addr;


input  logic  [8:0]  feature_val;
input logic   [13:0] abs_cur_addr;

input  logic  [6:0]  rel_right_child;    //node_prop[7:1]
input  logic  [6:0]  rel_left_child;     //node_prop[14:8]
input  logic  [8:0]  cmp_value;          //node_prop[23:15]

logic comparator_out;
logic [13:0] rel_addr;

// -----------------------------------------------------------       
//                  nxt_node_abs_addr 
// -----------------------------------------------------------  

// (feature_val <= cmp_value)
assign comparator_out = (feature_val <= cmp_value);

// If (feature <= cmp_value) is TRUE, take LEFT path.
// If (feature <= cmp_value) is FALSE, take RIGHT path.
assign rel_addr = (comparator_out) ? {7'd0, rel_left_child}  : {7'd0, rel_right_child};

//assign decision_node_addr = (just_started_d) ? last_node_reg : last_node_reg + addr_offset_mux_out;
assign nxt_node_abs_addr = abs_cur_addr + rel_addr;

endmodule