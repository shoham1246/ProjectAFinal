/*------------------------------------------------------------------------------
 * File          : gbdt_tb.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 8, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

/*************************************************************************************

GBDT Test-Bench

*************************************************************************************/
`include "/users/ephssm/Project/design/gbdt_define.sv"
`timescale 1ns/100ps
module gbdt_tb;

// -----------------------------------------------------------       
//                  APB Logic
// ----------------------------------------------------------- 

logic [`DATA_WIDTH-1:0]   	gbdt_cpu_p_rdata;	
logic						gbdt_cpu_p_ready;    
logic						gbdt_cpu_p_write;	  
logic [`ADDR_WIDTH-1:0] 	cpu_gbdt_p_addr;
logic [`DATA_WIDTH-1:0] 	cpu_gbdt_p_wdata;
logic                       cpu_gbdt_p_sel;

// -----------------------------------------------------------       
//                  DMA Logic
// ----------------------------------------------------------- 

logic [`DMA_RATE-1:0]		DMA_data;
logic						DMA_valid;

// -----------------------------------------------------------       
//                  General Logic
// ----------------------------------------------------------- 

logic 						gbdt_clk;	
logic 						gbdt_rst_n;
logic 						done;

// ----------------------------------------------------------------------
//                   Instantiation
// ----------------------------------------------------------------------
gbdt_top gbdt_top(   
		   .gbdt_clk		(gbdt_clk),
		   .gbdt_rst_n		(gbdt_rst_n),
		   .p_rdata			(gbdt_cpu_p_rdata[`DATA_WIDTH-1:0]),
		   .p_ready		    (gbdt_cpu_p_ready),
		   .cpu_p_write		(gbdt_cpu_p_write),
		   .p_addr			(cpu_gbdt_p_addr[`ADDR_WIDTH-1:0]),
		   .p_wdata			(cpu_gbdt_p_wdata[`DATA_WIDTH-1:0]),
		   .done			(done),
		   .p_sel           (cpu_gbdt_p_sel),
		   .DMA_data		(DMA_data),
		   .DMA_valid		(DMA_valid)
	  );

// Clock generation: 5ns period (200 MHz)
always begin
	#2.5 gbdt_clk = ~gbdt_clk;  // toggles every 2.5 ns
	//$display("[%0t] Clock toggled to %b", $time, gbdt_clk);
end

// --- Parameters for part 0 ---
parameter int NUM_TREES = 32;
parameter int NODES_PER_TREE = 7;
parameter int TOTAL_NODES = NUM_TREES * NODES_PER_TREE; // 224

// --- Storage for all node data ---
// This array will hold all 32*7=224 nodes read from the file.
logic [31:0] all_nodes [TOTAL_NODES];
logic [31:0] selector_value;

// --- Main Stimulus Block ---
initial begin
	
	//============ PART 0: RESET, FILLING THE RAMS ===============
	initiate_all;                                 // Initiates all input signals to '0' (& class_num=32) and open necessary files 
	#5	
	$display("Testbench started: Loading node data...");
	$readmemh("tree_nodesT1_updated.txt", all_nodes);
	$display("Node data loaded. Starting APB write sequence...");
	@(posedge gbdt_clk);

	selector_value = 32'b0;
	// --- Outer loop: Iterates per tree (0 to 31) ---
	for (int tree_idx = 0; tree_idx < NUM_TREES; tree_idx++) begin
	  $display("Time %0t: --- Writing Tree %0d ---", $time, tree_idx);
	  selector_value = (1 << tree_idx);
	  @(posedge gbdt_clk);
		apb_write(`GBDT_SEL_ADDR, selector_value); 		// selector: start writing for ram: 0->0, 2->1, 4->2, 8->3, ...
	  //selector_value = (1 << tree_idx);
	  // --- Inner loop: Iterates per node (0 to 6) ---
	  for (int node_idx = 0; node_idx < NODES_PER_TREE; node_idx++) begin
		logic [31:0] node_data;
		int global_node_index;
		global_node_index = (tree_idx * NODES_PER_TREE) + node_idx; 	// Calculate the global index into all_nodes array
		node_data = all_nodes[global_node_index];
		@(posedge gbdt_clk);
		  apb_write(`GBDT_RAM_ADDR_ADDR, node_idx); // CPU write 14-bits ram address (0, 1, 2, ... 6)
		@(posedge gbdt_clk);
		  apb_write(`GBDT_RAM_DATA_ADDR, node_data); // CPU write 32-bits of node data
	  end  
	  @(posedge gbdt_clk); // delay of 1 cycle before next ram
	end
	$display("Time %0t: --- All nodes written", $time);
	
	//=========== PART A: SENDING INPUT ===================
	
	#50 
	@(posedge gbdt_clk); 
		apb_write(`GBDT_USEDCLASS_ADDR, 32'hffffffff); 			   //using 32 classifications
	@(posedge gbdt_clk); 
		apb_write(`GBDT_START_ADDR, 32'h00000001);             // CPU WRITE 1 to start - moving to input_features
	// Send 16 DMA pulses. assuming DMA_RATE=144
	for (int i = 0; i < 16; i++) begin
		//send_dma_data({$urandom, $urandom, $urandom, $urandom, $urandom});
		// Each $urandom is 32 bits. 5*32=160. extra bits will be truncated.
		send_dma_data({9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01, 9'b01});
	end
	DMA_valid = 1'b0;
	
	//=========== PART B: REST & LET CORE WORK ============
	#300
	//=========== PART C: READ RESULT&FINISH ============
	// core should have ended already (sent done=1)
	@(posedge gbdt_clk); 
		apb_read(`REG_MAX_CLASS);
			 
	#20 $finish;
	
 end
	

 // ----------------------------------------------------------------------
 //                   Tasks
 // ----------------------------------------------------------------------

  
  task initiate_all;        // sets all tso inputs to '0'.
	  begin
	  gbdt_clk = 1'b0;	 
	  gbdt_rst_n = 1'b0;   

	  gbdt_cpu_p_write = 1'b0;     
	  cpu_gbdt_p_addr = 8'b0;
	  cpu_gbdt_p_wdata = 32'b0;
	  
	  DMA_data = '0;
	  DMA_valid = 1'b0;
	   
	  #2 gbdt_rst_n = 1'b1;     // Disable Reset signal.	 
	   end
  endtask



  task apb_write(
	  input [`ADDR_WIDTH-1:0] p_addr,
	  input [`DATA_WIDTH-1:0] p_wdata);
	  
	  @(posedge gbdt_clk); 
		  //$display("[%0t] writing task", $time); //add psel, penable
		  cpu_gbdt_p_addr  = p_addr;
		  gbdt_cpu_p_write = 1'b1;
		  cpu_gbdt_p_sel = 1'b1;
		  cpu_gbdt_p_wdata = p_wdata;

	  @(posedge gbdt_clk);  
		  gbdt_cpu_p_write = 1'b0;
		  cpu_gbdt_p_addr  = '0;
		  cpu_gbdt_p_wdata   = 32'h0;
		  cpu_gbdt_p_sel = 1'b0;
  endtask	
  
  
  task apb_read(
		  input [`ADDR_WIDTH-1:0] p_addr);
	  
	  @(posedge gbdt_clk); 
		 $display("[%0t] reading task", $time);
		 cpu_gbdt_p_addr = p_addr;
		 gbdt_cpu_p_write = 1'b0;
		 cpu_gbdt_p_sel = 1'b1;

	 @(posedge gbdt_clk);
		 cpu_gbdt_p_sel = 1'b0;
		 cpu_gbdt_p_addr = '0;
  endtask
  
  task send_dma_data(
		  input [`DMA_RATE-1:0] data);
		 DMA_data  = data;
		 DMA_valid = 1'b1;
		@(posedge gbdt_clk); 
  endtask

endmodule