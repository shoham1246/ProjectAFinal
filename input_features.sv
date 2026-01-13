/*------------------------------------------------------------------------------
 * File          : input_features.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 22, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"

module input_features(gbdt_clk, gbdt_rst_n, features_nums, start, dma_data, dma_valid,
					  features_vals);

// ----------------------------------------------------------------------
//                   local params
// ----------------------------------------------------------------------

localparam int DMA_RATE = `DMA_RATE;       	   //expected 144
localparam int CYCLES_NUM = `CYCLES_NUM;  	   //expected 16
localparam int DMA_BITS_NUM = `DMA_BITS_NUM;   //expected 4
localparam int COUNT_BITS_NUM = DMA_BITS_NUM+1;   //expected 5
localparam int GROUPS_PER_CYCLE = DMA_RATE / 9;  // expected 16
localparam int TOTAL_FEATURES   = CYCLES_NUM * GROUPS_PER_CYCLE; // expected 256

// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic [8:0] 			features_vals [7:0];  // 8 features_vals, each 9-bit

input logic 			    gbdt_clk;
input logic 			    gbdt_rst_n;
input logic 	 [7:0] 	    features_nums [7:0];  // 8 features_nums, each 8-bit
input logic 			    start;				 
input logic [`DMA_RATE-1:0] dma_data;
input logic 			    dma_valid;


// ----------------------------------------------------------------------
//                   Internal logic
// ----------------------------------------------------------------------

logic [8:0] features [255:0];    // 256 * 9b
logic [`DMA_BITS_NUM:0] counter; //counts 0..CYCLES_NUM

// ----------------------------------------------------------------------
//                   recieving_state
// ----------------------------------------------------------------------

//counter
always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
		if (!gbdt_rst_n)									counter <= #1 '0;
		else if (start && (counter == '0) && dma_valid)		counter <= #1 COUNT_BITS_NUM'(1);
		else if (counter != '0) begin
			if (counter == COUNT_BITS_NUM'(CYCLES_NUM))		counter <= #1 '0;
			else if (dma_valid) 							counter <= #1 counter + COUNT_BITS_NUM'(1);
			else											counter <= #1 counter;
		end
		else 												counter <= #1 '0;
	end


always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
	if (!gbdt_rst_n) begin
		for (int i = 0; i < TOTAL_FEATURES; i++) begin
			features[i] <= '0;
		end
	end 
	else if ((counter != '0) && dma_valid) begin
			for (int j = 0; j < GROUPS_PER_CYCLE; j++) begin
				features[((int'(counter)-1)*GROUPS_PER_CYCLE) + j] <= dma_data[(9*j) +: 9];
			end
	end
	else features <= features;  
end

// ----------------------------------------------------------------------
// Readout: features_vals[i] = features[ features_nums[i] ]
// ----------------------------------------------------------------------
genvar idx;
generate
	for (idx = 0; idx < 8; idx++) begin : FEATURE_VAL_EXTRACT
		always_comb begin
			features_vals[idx] = features[ features_nums[idx] ];
		end
	end
endgenerate


endmodule