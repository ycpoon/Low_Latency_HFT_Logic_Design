module debounce (
        input reset_in, clock_in, noisy_in,
        output reg clean_out
    );

        reg [19:0] count; reg new_input;
    
        always_ff @(posedge clock_in) begin
            if (reset_in) begin
                new_input <= noisy_in; clean_out <= noisy_in; count <= 0; end
            else if (noisy_in != new_input) begin 
                new_input<=noisy_in; count <= 0; 
            end else if (count == 650000) begin
                clean_out <= new_input;
            end else begin 
                count <= count+1;
            end
        end

endmodule

module seg_display(
    input	clk_in,
    input	rst_in,
 
    input [31:0]	val_in,
    output logic [6:0] cat_out, // was 7:0 for some reason
    output logic [7:0] an_out
);
    logic [7:0]	segment_state;
    logic [31:0]	segment_counter;
    logic [3:0]	routed_vals;
    logic [6:0]	led_out;

    binary_to_seven_seg my_converter ( .in(routed_vals), .out(led_out)); 

    assign cat_out = ~led_out;
    assign an_out = ~segment_state;

    always_comb begin 
        case(segment_state)
            8'b0000_0001:	routed_vals = val_in[3:0]; 
            8'b0000_0010:   routed_vals = val_in[7:4]; 
            8'b0000_0100:	routed_vals = val_in[11:8]; 
            8'b0000_1000:	routed_vals = val_in[15:12]; 
            8'b0001_0000:	routed_vals = val_in[19:16]; 
            8'b0010_0000:	routed_vals = val_in[23:20]; 
            8'b0100_0000:	routed_vals = val_in[27:24]; 
            8'b1000_0000:	routed_vals = val_in[31:28]; 
            default:	routed_vals = val_in[3:0];
        endcase 
    end

    always_ff @(posedge clk_in)begin 
        if (rst_in)begin
            segment_state <= 8'b0000_0001; segment_counter <= 32'b0;
        end else begin

            if (segment_counter == 32'd100_000)begin //changed from 100_000
                segment_counter <= 32'd0;
                segment_state <= {segment_state[6:0],segment_state[7]}; 
            end else begin
                segment_counter <= segment_counter +1; 
            end
        end 
    end

endmodule

module binary_to_seven_seg (in, out);
    input [3:0]	in;
    output logic [6:0]	out;

    assign	out[0]	=	~((in	==	1)	|	(in	==	4)	|	(in	==	11)	|	(in	==	13));	
    assign	out[1]	=	~((in	==	5)	|	(in	==	6)	|	(in	==	11)	|	(in	==	12) |	(in	==	14) | (in == 15));
    assign	out[2]	=	~((in	==	2)	|	(in	==	12)	|	(in	==	14)	|	(in	==	15));			
    assign	out[3]	=	~((in	==	1)	|	(in	==	4)	|	(in	==	7)	|	(in	==	10) |	(in	==	15));
    assign	out[4]	=	~((in	==	1)	|	(in	==	3)	|	(in	==	4)	|	(in	==	5)	|	(in	==	7)	| (in == 9 ));
    assign	out[5]	=	~((in	==	1)	|	(in	==	2)	|	(in	==	3)	|	(in	==	7)	|	(in	==	13));
    
    assign out[6] = ~((in == 0)	| (in == 1)	| (in == 7)	| (in == 12));

endmodule