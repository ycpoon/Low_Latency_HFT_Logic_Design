module mkCancelMessage #(
    parameter PRICE_WIDTH = 15,
    parameter ID_WIDTH = 15,
    parameter QUANT_WIDTH = 7,
    parameter STOCK_WIDTH = 7,
    parameter DATA_WIDTH = 31
)(
    input clk_in,
    input reset_in,
    input [DATA_WIDTH:0] data_in,
    input [2:0] mess_type_in,
    input enable_in,
    input valid_in,
    output [2:0] operation_out,
    output logic [STOCK_WIDTH:0] stock_symbol_out,
    output logic [ID_WIDTH:0] order_id_out,
    output logic [PRICE_WIDTH:0] price_out,
    output logic [QUANT_WIDTH:0] quantity_out,
    output logic ready_out
);

parameter MESSAGE_TYPE = 0; // Because we look at messages a cycle after it comes in. It comes in the same cycle (~enable_in_reg && enable_in) == 1.
parameter STOCK_LOCATE = 2;
parameter TRACKING_NUMBER = 2;
parameter TIMESTAMP = 6;
parameter ORDER_REF_NUM = 8;
parameter SHARES = 4;
parameter MATCH_NUMBER = 8;
parameter PRINTABLE = 8;
parameter PRICE = 4;
parameter TOTAL = MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + SHARES;

logic [10:0] count;
logic [(TOTAL) * 8 - 1:0] parsed_data = {0};
assign operation_out = {1'b0, mess_type_in[0], mess_type_in[1]}; // Currently only order cancel and order delete (2,3)

logic enable_in_reg;
logic ready_out_reg;
logic mess_type_reg;

always_comb begin
    if (~enable_in_reg && enable_in) begin
        ready_out = 0;
    end else begin
        ready_out = ready_out_reg;
    end
end

always @(posedge clk_in) begin
    if (reset_in) begin
        count <= 0;
        enable_in_reg <= 0;
        ready_out_reg <= 0;
        mess_type_reg <= 0;
    end else begin
        enable_in_reg <= enable_in;
        if (~enable_in_reg && enable_in) begin
            count <= 0;
            ready_out_reg <= 0;
            price_out <= 0;
            quantity_out <= 0;
            order_id_out <= 0;
            stock_symbol_out <= 0;
            mess_type_reg <= mess_type_in;
        end else begin
            casez (mess_type_reg)
                2: begin
                    if (valid_in && ~ready_out_reg) begin // Don't update parsed_data until ready_out_reg is pulled low
                        count <= count + 1;
                        parsed_data <= {data_in, parsed_data[TOTAL * 8 - 1:DATA_WIDTH]};
                    end
                    if (count == MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + SHARES - 1 && ~ready_out_reg) begin
                        ready_out_reg <= 1;
                        order_id_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP) * 8 +: ORDER_REF_NUM * 8];
                        stock_symbol_out <= parsed_data[(MESSAGE_TYPE) * 8 +: STOCK_LOCATE * 8];
                        quantity_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM) * 8 +: SHARES * 8];
                    end
                end
                0: begin
                    if (valid_in && ~ready_out_reg) begin // Don't update parsed_data until ready_out_reg is pulled low
                        count <= count + 1;
                        parsed_data <= {data_in, parsed_data[TOTAL * 8 - 1:DATA_WIDTH]};
                    end
                    if (count == MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM - 1 && ~ready_out_reg) begin
                        ready_out_reg <= 1;
                        order_id_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP) * 8 +: ORDER_REF_NUM * 8];
                        stock_symbol_out <= parsed_data[(MESSAGE_TYPE) * 8 +: STOCK_LOCATE * 8];
                    end
                end
                default: begin
                    if (count > MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + SHARES + MATCH_NUMBER + PRINTABLE + PRICE) begin
                        ready_out_reg <= 1;
                        price_out <= 56;
                        quantity_out <= 980;
                        order_id_out <= 2894;
                        stock_symbol_out <= 2983;
                    end else begin
                        count <= count + 1;
                    end
                end
            endcase
        end
    end
end

endmodule

