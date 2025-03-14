module market_parser # (
    parameter PRICE_WIDTH = 15,
    parameter ID_WIDTH = 15,
    parameter QUANT_WIDTH = 7,
    parameter STOCK_WIDTH = 7,
    parameter DATA_WIDTH = 7
)(
    input clk_in,
    input reset_in,
    input [DATA_WIDTH:0] data_in,
    input enable_in,
    input valid_in,
    input valid_master_in,
    output logic [2:0] operation_out,
    output [STOCK_WIDTH:0] stock_symbol_out_add,
    output [ID_WIDTH:0] order_id_out_add,
    output order_type_out_add,
    output [PRICE_WIDTH:0] price_out_add,
    output [QUANT_WIDTH:0] quantity_out_add,
    output [STOCK_WIDTH:0] stock_symbol_out_cancel,
    output [ID_WIDTH:0] order_id_out_cancel,
    output [PRICE_WIDTH:0] price_out_cancel,
    output [QUANT_WIDTH:0] quantity_out_cancel,
    output logic ready_out
);

    logic enable_add;
    logic enable_cancel;
    logic enable_dummy;
    logic [2:0] mess_type;
    logic [2:0] operation_out_add;
    logic [2:0] operation_out_cancel;
    logic [2:0] operation_out_dummy;
    logic [STOCK_WIDTH:0] stock_symbol_out_dummy;
    logic [ID_WIDTH:0] order_id_out_dummy;
    logic [PRICE_WIDTH:0] price_out_dummy;
    logic [QUANT_WIDTH:0] quantity_out_dummy;
    logic ready_add_out;
    logic ready_cancel_out;
    logic ready_dummy_out;
    logic [DATA_WIDTH:0] data_reg;
    logic [7:0] message;
    logic [DATA_WIDTH:0] data_last;
    logic [DATA_WIDTH:0] data_last2;
    logic [DATA_WIDTH:0] data_message_size;
    logic get_length;

    parameter MESSAGE_TYPE = DATA_WIDTH - 7;

    mkAddMessage #(
        .PRICE_WIDTH(PRICE_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .QUANT_WIDTH(QUANT_WIDTH),
        .STOCK_WIDTH(STOCK_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) addMessage (
        .clk_in(clk_in),
        .reset_in(reset_in),
        .data_in(data_reg),
        .mess_type_in(mess_type),
        .enable_in(enable_add),
        .valid_in(valid_in),
        .operation_out(operation_out_add),
        .stock_symbol_out(stock_symbol_out_add),
        .order_id_out(order_id_out_add),
        .price_out(price_out_add),
        .quantity_out(quantity_out_add),
        .order_type_out(order_type_out_add),
        .ready_out(ready_add_out)
    );

    mkCancelMessage #(
        .PRICE_WIDTH(PRICE_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .QUANT_WIDTH(QUANT_WIDTH),
        .STOCK_WIDTH(STOCK_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cancelMessage (
        .clk_in(clk_in),
        .reset_in(reset_in),
        .data_in(data_reg),
        .mess_type_in(mess_type),
        .enable_in(enable_cancel),
        .valid_in(valid_in),
        .operation_out(operation_out_cancel),
        .stock_symbol_out(stock_symbol_out_cancel),
        .order_id_out(order_id_out_cancel),
        .price_out(price_out_cancel),
        .quantity_out(quantity_out_cancel),
        .ready_out(ready_cancel_out)
    );

    mkDummyMessage #(
        .PRICE_WIDTH(PRICE_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .QUANT_WIDTH(QUANT_WIDTH),
        .STOCK_WIDTH(STOCK_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dummyMessage (
        .clk_in(clk_in),
        .reset_in(reset_in),
        .data_in(data_message_size),
        .enable_in(enable_dummy),
        .valid_in(valid_in),
        .operation_out(operation_out_dummy),
        .stock_symbol_out(stock_symbol_out_dummy),
        .order_id_out(order_id_out_dummy),
        .price_out(price_out_dummy),
        .quantity_out(quantity_out_dummy),
        .ready_out(ready_dummy_out)
    );

    always_comb begin
        for (integer i = 0; i <= DATA_WIDTH; i = i + 1) begin
            message[i] = data_in[DATA_WIDTH - i];
        end
    end

    always @(posedge clk_in) begin
        casez ({reset_in, valid_in, message, ready_out || ready_dummy_out, valid_master_in || ready_dummy_out, get_length, enable_add, enable_cancel, enable_dummy})
            {16'b1_?_????_????_?_?_?_???}: begin
                data_reg <= 0;
                enable_add <= 0;
                enable_cancel <= 0;
                enable_dummy <= 0;
                mess_type <= 0;
                get_length <= 1;
            end
            {1'b0, 1'b1, 8'h00, 1'b0, 1'b?, 1'b?, 3'b0_0_0}: begin
                data_reg <= data_reg;
                enable_add <= enable_add;
                enable_cancel <= enable_cancel;
                enable_dummy <= enable_dummy;
                mess_type <= mess_type;
            end
            {1'b0, 1'b1, 8'h??, 1'b0, 1'b?, 1'b1, 3'b0_0_0}: begin
                data_message_size <= data_in;
                get_length <= 0;
            end
            {1'b0, 1'b1, 8'h82, 1'b0, 1'b?, 1'b0, 3'b0_0_0}: begin
                data_reg <= message;
                enable_add <= 1;
                mess_type <= 0;
            end
            {16'b0_????_????_1_1_0_???}: begin
                data_reg <= 0;
                mess_type <= 0;
                enable_add <= 0;
                enable_cancel <= 0;
                get_length <= 1;
                enable_dummy <= 0;
            end
            default: begin
                data_reg <= data_reg;
                get_length <= get_length;
                enable_add <= enable_add;
                enable_cancel <= enable_cancel;
                enable_dummy <= enable_dummy;
                mess_type <= mess_type;
            end
        endcase
    end

    always_comb begin
        case ({enable_add, enable_cancel, enable_dummy})
            
            3'b1_0_0: begin
                ready_out = ready_add_out;
                operation_out = operation_out_add;
            end

            3'b0_1_0: begin
                ready_out = ready_cancel_out;
                operation_out = operation_out_cancel;
            end

            3'b0_0_1: ready_out = 0;
            default: begin
                ready_out = 0;
                operation_out = 0;
            end

        endcase
    end

endmodule
