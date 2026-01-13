/*------------------------------------------------------------------------------
 * File          : ram_sp_sr_sw.sv
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 22, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

//-----------------------------------------------------
// Design Name : ram_sp_sr_sw
// File Name   : ram_sp_sr_sw.sv
// Function    : Synchronous read/write single-port RAM
// Coder       : Deepak Kumar Tala. Converted to SystemVerilog syntax
//-----------------------------------------------------
module ram_sp_sr_sw #(
	parameter int DATA_WIDTH = `RAM_DATA_WIDTH,
	parameter int ADDR_WIDTH = `RAM_ADDR_WIDTH,
	parameter int RAM_DEPTH  = 1 << ADDR_WIDTH
) (
	input  logic                   clk,       // Clock Input
	input  logic [ADDR_WIDTH-1:0]  address,   // Address Input
	input  logic                   cs,        // Chip Select
	input  logic                   we,        // Write Enable (1=write, 0=read)
	input  logic                   oe,        // Output Enable
	inout  wire  [DATA_WIDTH-1:0]  data       // Bi-directional Data Bus
);

	// Internal variables
	logic [DATA_WIDTH-1:0] data_out;
	logic [DATA_WIDTH-1:0] mem [RAM_DEPTH];
	logic                  oe_r;

	// Tri-State Buffer control
	// Output when we=0, oe=1, cs=1
	assign data = (cs && oe && !we) ? data_out : 'z;

	// Memory Write Block
	// Write Operation: When we=1, cs=1
	always_ff @(posedge clk) begin
		if (cs && we)
			mem[address] <= data;
	end

	// Memory Read Block
	// Read Operation: When we=0, oe=1, cs=1
	always_ff @(posedge clk) begin
		if (cs && !we && oe) begin
			data_out <= mem[address];
			oe_r     <= 1'b1;
		end
		else begin
			oe_r     <= 1'b0;
		end
	end

endmodule