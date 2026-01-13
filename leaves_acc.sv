/*------------------------------------------------------------------------------
 * File          : leaves_acc.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps

module leaves_acc (gbdt_clk, gbdt_rst_n, is_leaf, leaf_val, enable, finish_condition, start_new_round,
				   done, result);


// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic         done;
output logic [31:0]  result;

input  logic        gbdt_clk;
input  logic        gbdt_rst_n;
input  logic        is_leaf;          //from node_prop[0]
input  logic [15:0] leaf_val;         //from node_prop[31:16]
input  logic        enable;
input  logic        finish_condition;
input  logic        start_new_round;


// Internal signals, registers
logic [31:0] cur_score; //register
logic [31:0] accum_adder_out;

// Accumulator for the 'result' register
assign accum_adder_out = {16'd0, leaf_val} + cur_score;


always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)										done <=  #1 1'b1; 	// We are "done" (idle) at reset
	else if (start_new_round)								done <= #1 1'b0;		// Start working
	else if (enable & !done & finish_condition)				done <= #1 1'b1;       // We just hit the last leaf. Go to idle/done state
end


always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)														cur_score <= #1 32'd0;
	else if (start_new_round)												cur_score <= #1 32'd0;      		// Reset score
	else if (enable & !done & finish_condition)								cur_score <= #1 accum_adder_out; 	// We just hit the last leaf. Store final leaf value 
	else if (enable & !done & !finish_condition & is_leaf)					cur_score <= #1 accum_adder_out; // Accumulate
	// else (non-leaf): result_reg holds
end

assign result = cur_score;

endmodule