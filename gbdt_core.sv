/*------------------------------------------------------------------------------
 * File          : gbdt_core.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps


module gbdt_core (gbdt_clk, gbdt_rst_n, old_max_result, old_max_class, used_classes, gbdt_start, DMA_valid, DMA_data, data_from_rams, 
				  new_max_result, new_max_class, done, oe, we, cs, round, ram_address);
// -----------------------------------------------------------       
//                  General Interface 
// -----------------------------------------------------------  

output logic 		[31:0] 			new_max_result;
output logic 		[4:0] 			new_max_class;
output logic						done;

output logic					  	oe;
output logic					  	we;
output logic					  	cs;
output logic 		[1:0] 		    round;

output logic   [`RAM_ADDR_WIDTH-1:0] ram_address [7:0];

input logic 						gbdt_clk;
input logic 						gbdt_rst_n;
input logic  [`RESULT_WIDTH-1:0]	old_max_result;
input logic	[`MAX_CLASS_WIDTH-1:0]	old_max_class;
input logic							gbdt_start;
input logic         [31:0]			used_classes;
input logic							DMA_valid;
input logic	   [`DMA_RATE-1:0]		DMA_data;
input wire   		[31:0]  		data_from_rams [7:0];

// ----------------------------------------------------------------------
//                   Internal logic
// ----------------------------------------------------------------------

logic 		[7:0] 		  class_dones;
logic 					  max_done;
logic [`RESULT_WIDTH-1:0] class_results [7:0];  // 8 results, each 32-bit
logic 		[7:0] 		  class_enable;
logic 					  max_enable;
logic 		[8:0] 		  features_vals [7:0];  // 8 features_vals, each 9-bit
logic 	 	[7:0] 	      features_nums [7:0];  // 8 features_nums, each 8-bit



// ----------------------------------------------------------------------
//                   Instantiation
// ----------------------------------------------------------------------

max_result max_result(   
			.gbdt_clk			(gbdt_clk),
			.gbdt_rst_n			(gbdt_rst_n),

			.round				(round),
			.max_enable			(max_enable),
			.results 			(class_results),
			.old_max_result		(old_max_result),
			.old_max_class		(old_max_class),
			.max_done			(max_done),
			.new_max_result		(new_max_result),
			.new_max_class		(new_max_class)
	   );

gbdt_control gbdt_control (
			.gbdt_clk			(gbdt_clk),
			.gbdt_rst_n			(gbdt_rst_n),
			.dones				(class_dones),
			.MAXdone			(max_done),
			.start				(gbdt_start),
			
			.enables			({class_enable, max_enable}),
			.round				(round),
			.done				(done),
			.used_classes		(used_classes),
			.we					(we),
			.oe					(oe),
			.cs					(cs),
			.dma_valid			(DMA_valid)
		);


input_features input_features(   
			.gbdt_clk			(gbdt_clk),
			.gbdt_rst_n			(gbdt_rst_n),
			.features_nums		(features_nums),
			.start				(gbdt_start),
			.dma_data			(DMA_data),
			.dma_valid			(DMA_valid),
			.features_vals		(features_vals)
	   );

genvar i;

generate
  for (i = 0; i < 8; i++) begin : CLASS_LOOP
	classification class_inst (
	  .gbdt_clk      (gbdt_clk),
	  .gbdt_rst_n    (gbdt_rst_n),
	  .feature_val   (features_vals[i]),               
	  .data_from_rams    (data_from_rams[i]),              
	  .class_done    (class_dones[i]),
	  .class_result  (class_results[i]),
	  .feature_num   (features_nums[i]),
	  .enable		 (class_enable[i]),
	  .ADDRtoRAMs	 (ram_address[i])
	);
  end
endgenerate

/*
genvar i;

generate
  for (i = 0; i < 8; i++) begin : CLASS_LOOP
	  tree_processor class_inst (
	  .gbdt_clk      	(gbdt_clk),
	  .gbdt_rst_n    	(gbdt_rst_n),
	  .feature_val		(features_vals[i]),
	  .data_from_rams	(data_from_rams[i]),
	  .class_done 		(class_dones[i]),
	  .class_result 	(class_results[i]),
	  .feature_num 		(features_nums[i]),
	  .enable		 	(class_enable[i]),
	  .data_to_rams	 	(ram_address[i])
	);
  end
endgenerate
*/

endmodule