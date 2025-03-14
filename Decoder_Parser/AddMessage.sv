module mkAddMessage #(
    parameter PRICE_WIDTH=15,
    parameter ID_WIDTH=15,
    parameter QUANT_WIDTH=7,
    parameter STOCK_WIDTH=7,
    parameter DATA_WIDTH=31
)(
    input clk_in,
    input reset_in,
    input [DATA_WIDTH:0] data_in,
    input [2:0] mess_type_in,
    input enable_in,
    input valid_in,
    output logic [2:0] operation_out,
    output logic [STOCK_WIDTH:0] stock_symbol_out,
    output logic [ID_WIDTH:0] order_id_out,
    output logic order_type_out,
    output logic [PRICE_WIDTH:0] price_out,
    output logic [QUANT_WIDTH:0] quantity_out,
    output logic ready_out
);

    parameter MESSAGE_TYPE = 0; 
    parameter STOCK_LOCATE = 2;
    parameter TRACKING_NUMBER = 2;
    parameter TIMESTAMP = 6;
    parameter ORDER_REF_NUM = 8;
    parameter BUY_SELL_IND = 1;
    parameter SHARES = 4;
    parameter STOCK = 8;
    parameter PRICE = 4;
    parameter ATTRIBUTION = 4;
    parameter TOTAL = MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + BUY_SELL_IND + SHARES + STOCK + PRICE;

    logic [(TOTAL) * 8 - 1 : 0] parsed_data = {0};
    logic [10:0] count;
    logic enable_in_reg;
    logic ready_out_reg;
    logic mess_type_reg;

    assign operation_out = 3'b1;

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
                    0: begin
                        if (valid_in && ~ready_out_reg) begin // don't update parsed_data until ready_out_reg is pulled low
                            count <= count + 1;
                            parsed_data <= {data_in, parsed_data[TOTAL * 8 - 1 : DATA_WIDTH]};
                        end
                        if (count == MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + BUY_SELL_IND + SHARES + STOCK + PRICE - 1 && ~ready_out_reg) begin
                            ready_out_reg <= 1;
                            order_id_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP) * 8 +: ORDER_REF_NUM * 8];
                            order_type_out <= (parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM) * 8 +: BUY_SELL_IND * 8] == 8'h41) ? 1'b0 : 1'b1;
                            quantity_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + BUY_SELL_IND) * 8 +: SHARES * 8];
                            stock_symbol_out <= parsed_data[(MESSAGE_TYPE) * 8 +: STOCK_LOCATE * 8];
                            price_out <= parsed_data[(MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + BUY_SELL_IND + SHARES + STOCK) * 8 +: PRICE * 8];
                        end
                    end
                    default: begin
                        if (count > MESSAGE_TYPE + STOCK_LOCATE + TRACKING_NUMBER + TIMESTAMP + ORDER_REF_NUM + BUY_SELL_IND + SHARES + STOCK + PRICE + ATTRIBUTION) begin
                            ready_out_reg <= 1;
                            price_out <= 10;
                            quantity_out <= 20;
                            order_id_out <= 24;
                            stock_symbol_out <= 23;
                        end else begin
                            count <= count + 1;
                        end
                    end
                endcase
            end
        end
    end

endmodule
