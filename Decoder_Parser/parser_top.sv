`include "helper.sv"

module parser_top # (
    parameter PRICE_WIDTH=15,
    parameter ID_WIDTH=15, 
    parameter QUANT_WIDTH=7, 
    parameter STOCK_WIDTH=7, 
    parameter  DATA_WIDTH=31
    )(
    input	clk_in,
    input	reset_in,
    input [DATA_WIDTH:0]	data_in,
    input [15:0]	sw,
    output	ca, cb, cc, cd, ce, cf, cg, dp, // segments a-g, dp
    output [7:0]	an,
    input	valid_microblaze_in,
    output	ready_to_microblaze_out,
    input	enable_in,
    output [STOCK_WIDTH:0]	stock_symbol_out,
    output [2:0]	operation_out, //add = 1, cancel = 2, delete = 0
    // output [STOCK_WIDTH: 0] stock_symbol_out,
    // output [ID_WIDTH: 0]	order_id_out,
    
    // output [PRICE_WIDTH: 0] price_out,
    // output [QUANT_WIDTH: 0] quantity_out,
    output logic [STOCK_WIDTH:0] stock_symbol_out_add, 
    output logic [ID_WIDTH:0]	order_id_out_add, 
    output logic [PRICE_WIDTH:0] price_out_add,
    output logic [QUANT_WIDTH:0] quantity_out_add, 
    output	order_type_out_add,
    output logic [STOCK_WIDTH:0] stock_symbol_out_cancel, 
    output logic [ID_WIDTH:0]	order_id_out_cancel, 
    output logic [PRICE_WIDTH:0] price_out_cancel,
    output logic [QUANT_WIDTH:0] quantity_out_cancel, 
    output	delete_out,
    input	valid_master_in,
    output	last_master_out,
    output	ready_out
    );
    logic	enable_parser;
    //logic[STOCK_WIDTH: 0] stock_symbol_raw_out;
    //logic[ID_WIDTH: 0]	order_id_raw_out;
    //logic[PRICE_WIDTH: 0] price_raw_out;
    //logic[QUANT_WIDTH: 0] quantity_raw_out;
    logic [STOCK_WIDTH:0]	stock_symbol_raw_out_add; logic [ID_WIDTH:0]	order_id_raw_out_add; logic [PRICE_WIDTH:0]	price_raw_out_add;
    logic  [QUANT_WIDTH:0]	quantity_raw_out_add;
    logic [STOCK_WIDTH:0]	stock_symbol_raw_out_cancel; logic [ID_WIDTH:0]	order_id_raw_out_cancel; logic [PRICE_WIDTH:0]	price_raw_out_cancel;
    logic  [QUANT_WIDTH:0]	quantity_raw_out_cancel;

    market_parser parser(
        .clk_in(clk_in), 
        .reset_in(reset_in), 
        .data_in(data_in[7:0]),
        .enable_in(enable_parser),  
        .valid_in(valid_microblaze_in),  
        .valid_master_in(valid_master_in),
        .operation_out(operation_out),
        .stock_symbol_out_add(stock_symbol_raw_out_add),  
        .order_id_out_add(order_id_raw_out_add),
        .price_out_add(price_raw_out_add),
        .quantity_out_add(quantity_raw_out_add),  
        .order_type_out_add(order_type_raw_out_add),
        .stock_symbol_out_cancel(stock_symbol_raw_out_cancel),  
        .order_id_out_cancel(order_id_raw_out_cancel),
        .price_out_cancel(price_raw_out_cancel),  
        .quantity_out_cancel(quantity_raw_out_cancel),
        .ready_out(ready_out)
        );

    always_comb begin
        for(integer i =0; i <= STOCK_WIDTH; i = i + 1) begin 
            stock_symbol_out_add[i] = stock_symbol_raw_out_add[STOCK_WIDTH - i];
            stock_symbol_out_cancel[i] = stock_symbol_raw_out_cancel[STOCK_WIDTH - i];
        end
        for(integer i =0; i <= ID_WIDTH; i = i + 1) begin 
            order_id_out_add[i] = order_id_raw_out_add[ID_WIDTH - i]; 
            order_id_out_cancel[i] = order_id_raw_out_cancel[ID_WIDTH - i];
        end
        for(integer i =0; i <= PRICE_WIDTH; i = i + 1) begin 
            price_out_add[i] = price_raw_out_add[PRICE_WIDTH - i]; 
            price_out_cancel[i] = price_raw_out_cancel[PRICE_WIDTH - i];
        end
        for(integer i =0; i <= QUANT_WIDTH; i = i + 1) begin 
            quantity_out_add[i] = quantity_raw_out_add[QUANT_WIDTH - i]; 
            quantity_out_cancel[i] = quantity_raw_out_cancel[QUANT_WIDTH - i];
        end 
    end

    assign ready_to_microblaze_out = ~ready_out; assign last_master_out = ready_out;
    assign enable_parser = 1; //have to think about this
    assign delete_out = (operation_out == 3'b000) && ready_out;
    assign stock_symbol_out = (operation_out == 3'b000) ? stock_symbol_out_cancel : stock_symbol_out_add;
    // always@(posedge clk_in) begin
    //	if(reset_in)  begin
    //	end else begin
    //	if(ready_out)ready_to_microblaze_out <= 1;
    // end

    logic [31:0] data_to_display ;

    seg_display dis(
        .clk_in(clk_in), 
        .rst_in(reset_in), 
        .val_in(data_to_display), 
        .cat_out({cg, cf, ce, cd, cc, cb, ca}), 
        .an_out(an)
    );

    logic [15:0] sw_debounced;

    assign	dp = 1'b1;	// turn off the period

    debounce deb(
        .clock_in(clk_in), 
        .reset_in(reset_in), 
        .noisy_in(sw), 
        .clean_out(sw_debounced)
    );

    always@(posedge clk_in) begin 
        case(operation_out)
            0 :	case(sw)
                    16'b0_0_0_0_0_0_0 : data_to_display <= price_out_add; 16'b0_0_0_0_0_0_1 : data_to_display <= quantity_out_add; 16'b0_0_0_0_0_1_0 : data_to_display <= order_id_out_add; 16'b0_0_0_0_1_0_0 : data_to_display <= stock_symbol_out_add;
                    16'b0_0_0_1_0_0_0 : data_to_display <= {valid_microblaze_in, ready_to_microblaze_out, valid_master_in, last_master_out, ready_out};
                    16'b0_0_1_0_0_0_0 : data_to_display <= data_in;
                    default : data_to_display <= operation_out; 
                endcase

            1 : case(sw)
                    16'b0_0_0_0_0_0_0 : data_to_display <= price_out_cancel; 16'b0_0_0_0_0_0_1 : data_to_display <= quantity_out_cancel; 16'b0_0_0_0_0_1_0 : data_to_display <= order_id_out_cancel; 16'b0_0_0_0_1_0_0 : data_to_display <= stock_symbol_out_cancel;
                    16'b0_0_0_1_0_0_0 : data_to_display <= {valid_microblaze_in, ready_to_microblaze_out, valid_master_in, last_master_out, ready_out};
                    16'b0_0_1_0_0_0_0 : data_to_display <= data_in;
                    default : data_to_display <= operation_out; 
                endcase

            2 : case(sw)
                    16'b0_0_0_0_0_0_0 : data_to_display <= price_out_cancel; 16'b0_0_0_0_0_0_1 : data_to_display <= quantity_out_cancel; 16'b0_0_0_0_0_1_0 : data_to_display <= order_id_out_cancel; 16'b0_0_0_0_1_0_0 : data_to_display <= stock_symbol_out_cancel;
                    16'b0_0_0_1_0_0_0 : data_to_display <= {valid_microblaze_in, ready_to_microblaze_out, valid_master_in, last_master_out, ready_out};
                    16'b0_0_1_0_0_0_0 : data_to_display <= data_in;
                    default : data_to_display <= operation_out; 
                endcase

            default: case(sw)
                        16'b0_0_0_0_0_0_0 : data_to_display <= price_out_add; 16'b0_0_0_0_0_0_1 : data_to_display <= quantity_out_add; 16'b0_0_0_0_0_1_0 : data_to_display <= order_id_out_add; 16'b0_0_0_0_1_0_0 : data_to_display <= stock_symbol_out_add;
                        16'b0_0_0_1_0_0_0 : data_to_display <= {valid_microblaze_in, ready_to_microblaze_out, valid_master_in, last_master_out, ready_out};
                        16'b0_0_1_0_0_0_0 : data_to_display <= data_in;
                        default : data_to_display <= operation_out; 
                     endcase
        endcase 
    end

    endmodule


