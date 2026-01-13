/*------------------------------------------------------------------------------
 * File          : gbdt_control.v
 * Project       : RTL
 * Author        : ephssm
 * Creation date : Oct 8, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/ephssm/Project/design/gbdt_define.sv"

module gbdt_control(gbdt_clk, gbdt_rst_n, dones, MAXdone, start, used_classes, dma_valid,
				enables, round, done, we, oe, cs);
	input logic  		gbdt_clk;
	input logic			gbdt_rst_n;
	input logic  [7:0] 	dones;
	input logic 		MAXdone;
	input logic			start;
	input logic			dma_valid;
		  
	input logic  [31:0]	used_classes;
	
	output logic [8:0]  enables;
	output logic [1:0]  round;
	output logic  		done;
	output logic		we;
	output logic        oe;
	output logic        cs;
	
logic just_started;
logic  [`DMA_BITS_NUM-1:0] counter; //in the worst case DMA_RATE=1 -> log2(CYCLES_NUM)~ 11.17...
//--------------------------------------------------------------------------
// State definition
//--------------------------------------------------------------------------
	typedef enum logic [3:0] {
		Idle      		= 4'b0000,
		InputRecieving  = 4'b0001,
		Round1p1  		= 4'b0010,
		Round1p2  		= 4'b0011,
		Round2p1  		= 4'b0100,
		Round2p2  		= 4'b0101,
		Round3p1  		= 4'b0110,
		Round3p2  		= 4'b0111,
		Round4p1  		= 4'b1000,
		Round4p2    	= 4'b1001,
		Finish 			= 4'b1010,
		MovingSt12		= 4'b1011, //CHANGE 1
		MovingSt23		= 4'b1100, //same
		MovingSt34		= 4'b1101  //same
	} state_t;

	state_t currentState, nextState;


	//--------------------------------------------------------------------------
	// Sequential block: state register
	//--------------------------------------------------------------------------
	always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
		if (!gbdt_rst_n)	currentState <= #1 Idle;
		else				currentState <= #1 nextState;
	end
	
	always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
		if (!gbdt_rst_n)										counter <= #1 '0;
		else if (currentState == InputRecieving && dma_valid)	counter <= #1 counter + `DMA_BITS_NUM'(1);
		else 													counter <= #1 '0;
	end
	
	always_ff @(posedge gbdt_clk or negedge gbdt_rst_n) begin
		if (!gbdt_rst_n)								just_started <= #1 1'b0;
		//else if	(currentState == InputRecieving || currentState == Round1p2 || currentState == Round2p2 || currentState == Round3p2)   just_started <= #1 1'b1;
		else if	(currentState == InputRecieving || currentState == MovingSt12 || currentState == MovingSt23 || currentState == MovingSt34) just_started <= #1 1'b1; //CHANGE 4
		else											just_started <= #1 1'b0; //TODO: ASK SHAHAR IF LEGAL IN SYNTHESIS `just_started_d
	end
	
	

	//--------------------------------------------------------------------------
	// Combinational block: next state and outputs
	//--------------------------------------------------------------------------
	always_comb begin
		localparam int CYCLES_NUM = `CYCLES_NUM;
		// default assignments to avoid inferred latches
		enables    = 9'b0;
		round      = 2'b0;
		done       = 1'b0;
		we		   = 1'b0;
		oe		   = 1'b0;
		cs		   = 1'b1; //instead of 1'b0. CHANGE 5
		nextState  = currentState;

		case (currentState)
			Idle: begin
				we = 1'b1;
				cs = 1'b1;
				if (start)
					nextState = InputRecieving;
			end
			
			InputRecieving: begin
				cs = 1'b1;
				if (counter == `DMA_BITS_NUM'(CYCLES_NUM - 1))
					nextState = Round1p1;
				else 
					nextState = currentState;					
			end

			Round1p1: begin
				cs = 1'b1;
				oe = 1'b1;
				enables = {used_classes[7:0], 1'b0}; // 9'b111111110
				round   = 2'b00;
				if (dones == 8'hFF && !just_started)
					nextState = Round1p2;
			end

			Round1p2: begin
				enables = 9'b000000001;
				round   = 2'b00;
				if (MAXdone) begin
					if (!used_classes[8])  	   nextState = Finish; // if (used_classes <= 5'b111)
					else 					   nextState = MovingSt12; //CHANGE 2
				end
			end
			
			MovingSt12: begin //CHANGE 3
				round   = 2'b01;
				nextState = Round2p1;
			end

			Round2p1: begin
				cs = 1'b1;
				oe = 1'b1;
				enables = {used_classes[15:8], 1'b0}; // 9'b111111110
				round   = 2'b01;
				if (dones == 8'hFF && !just_started)
					nextState = Round2p2;
			end

			Round2p2: begin
				enables = 9'b000000001;
				round   = 2'b01;
				if (MAXdone) begin
					if (!used_classes[16])  		nextState = Finish; //used_classes <= 5'b1111
					else 						    nextState = MovingSt23; //CHANGE 2
				end
			end
			
			MovingSt23: begin //CHANGE 3
				round   = 2'b10;
				nextState = Round3p1;
			end

			Round3p1: begin
				cs = 1'b1;
				oe = 1'b1;
				enables = {used_classes[23:16], 1'b0}; // 9'b111111110
				round   = 2'b10;
				if (dones == 8'hFF && !just_started)
					nextState = Round3p2;
			end

			Round3p2: begin
				enables = 9'b000000001;
				round   = 2'b10;
				if (MAXdone) begin
					if (!used_classes[24])  		 nextState = Finish; //used_classes <= 5'b10111
					else 						     nextState = MovingSt34;
				end
			end
			
			MovingSt34: begin //CHANGE 3
				round   = 2'b11;
				nextState = Round4p1;
			end

			Round4p1: begin
				cs = 1'b1;
				oe = 1'b1;
				enables = {used_classes[31:24], 1'b0}; //9'b111111110
				round   = 2'b11;
				if (dones == 8'hFF && !just_started)
					nextState = Round4p2;
			end

			Round4p2: begin
				enables = 9'b000000001;
				round   = 2'b11;
				if (MAXdone)
					nextState = Finish;
			end

			Finish: begin
				done      = 1'b1;
				nextState = Idle;   // finish lasts only 1 clk cycle
			end

			default: nextState = Idle;
		endcase
	end

endmodule