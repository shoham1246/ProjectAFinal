/*------------------------------------------------------------------------------
 * File          : max_result.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 8, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps

module max_result (max_done, new_max_result, new_max_class, gbdt_clk, gbdt_rst_n, round, max_enable,
				   results, old_max_result, old_max_class);


// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic        max_done;
output logic [31:0] new_max_result;
output logic [4:0]  new_max_class;

input  logic        gbdt_clk;
input  logic        gbdt_rst_n;
input  logic [1:0]  round;
input  logic        max_enable;
input  logic [31:0] results [7:0];       // 8 results, each 32-bit
input  logic [31:0] old_max_result;
input  logic [4:0]  old_max_class;

// -----------------------------------------------------------       
//                  Internal signals 
// -----------------------------------------------------------  

logic [31:0] max_val;
logic [4:0]  max_class_temp;
logic [4:0]  max_i;
logic 		 max_enable_d;  // delayed enable signal

// ---------------------------------------------------------
// Find the maximum result among the 8 inputs (combinational)
// ---------------------------------------------------------
always_comb begin
	max_i = 5'(round) * 5'd8; //check
	//new_max_result = old_max_result; //default if enable is 0
	//new_max_class  = old_max_class;  //default if enable is 0
	max_val = old_max_result;
	max_class_temp = old_max_class;
	if (max_enable) begin
		for (int i = 0; i < 8; i++) begin
			if (results[i] > max_val) begin
				max_val = results[i];
				max_class_temp = i[4:0];
			end
		end

		//new_max_result = max_val;
		//new_max_class  = max_class_temp;
	end
end

// ---------------------------------------------------------
// Update new_max_result
// ---------------------------------------------------------
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)					new_max_result <= #1 32'b0;
	else if (!max_enable)				new_max_result <= #1 new_max_result; // hold
	else if (max_val > old_max_result)	new_max_result <= #1 max_val;
	else								new_max_result <= #1 old_max_result;
end

// ---------------------------------------------------------
// Update new_max_class
// ---------------------------------------------------------
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)        			new_max_class <= #1 5'b0;
	else if (!max_enable)				new_max_class <= #1 new_max_class; // hold
	else if (max_val > old_max_result)	new_max_class <= #1 max_class_temp + max_i[4:0];
	else								new_max_class <= #1 old_max_class;
end

// ---------------------------------------------------------
// Update max_done
// ---------------------------------------------------------

// Delay enable by one clock to signal completion
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)	max_enable_d <= #1 1'b0;
	else				max_enable_d <= #1 max_enable;
end

// Generate max_done when work is completed (one cycle after enable)
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n)						max_done <= #1 1'b0;
	else if (!max_enable)					max_done <= #1 1'b0;
	else if (max_enable_d && max_enable)	max_done <= #1 1'b1;  // one cycle after the work is done
	else									max_done <= #1 1'b0;
end

endmodule