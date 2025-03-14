`timescale 1ns / 1ns

module parser_test();
    parameter PRICE_WIDTH=15;
    parameter ID_WIDTH=15;
    parameter QUANT_WIDTH=7;
    parameter STOCK_WIDTH=7;
    parameter DATA_WIDTH=31;
    logic clk_in;
    logic reset_in;
    logic [DATA_WIDTH:0] data_in;
    logic valid_microblaze_in;
    logic ready_to_microblaze_out;
    logic enable_in;
    logic [2:0] operation_out;
    logic [STOCK_WIDTH:0] stock_symbol_out_add;
    logic [ID_WIDTH:0] order_id_out_add;
    logic [PRICE_WIDTH:0] price_out_add;
    logic [QUANT_WIDTH:0] quantity_out_add;
    logic [STOCK_WIDTH:0] stock_symbol_out_cancel;
    logic [ID_WIDTH:0] order_id_out_cancel;
    logic [PRICE_WIDTH:0] price_out_cancel;
    logic [QUANT_WIDTH:0] quantity_out_cancel;
    logic delete_out;
    // logic [STOCK_WIDTH: 0] stock_symbol_out;
    // logic [ID_WIDTH: 0] order_id_out;
    // logic [PRICE_WIDTH: 0] price_out;
    // logic [QUANT_WIDTH: 0] quantity_out;
    logic valid_master_in;
    logic last_master_out;
    logic ready_out;
    logic enable_parser;
    // assign ready_to_microblaze_out = ~ready_out;
    // assign last_master_out = ready_out;
    // assign enable_parser = 1; //have to think about this
    // assign delete_out = (operation_out == 3'b000) && ready_out;
    parser_top parser(
        .clk_in(clk_in), 
        .reset_in(reset_in), 
        .data_in(data_in[7:0]),
        .enable_in(enable_in), 
        .valid_microblaze_in(valid_microblaze_in),
        .ready_to_microblaze_out(ready_to_microblaze_out),
        .operation_out(operation_out),
        .stock_symbol_out_add(stock_symbol_out_add), 
        .order_id_out_add(order_id_out_add),
        .price_out_add(price_out_add), 
        .quantity_out_add(quantity_out_add),
        .stock_symbol_out_cancel(stock_symbol_out_cancel), 
        .order_id_out_cancel(order_id_out_cancel),
        .price_out_cancel(price_out_cancel), 
        .quantity_out_cancel(quantity_out_cancel),
        .delete_out(delete_out),
        .valid_master_in(valid_master_in), 
        .last_master_out(last_master_out), .ready_out(ready_out)
    );

    parameter size = 304;
    logic [303: 0] test_data; //36 bytes == add
    //type, stocklocate, trackingnumber, timestamp, order_ref, buySell, shares, stock, price
    logic [7:0] test;
    logic [7:0] test_1;
    logic [7:0] test_2;
    logic [7:0] test_3;

    always begin #10
        clk_in = ~clk_in;
    end

    initial begin
        clk_in = 1'b0;
        reset_in = 1'b1;
        valid_microblaze_in = 1'b1;
        enable_in = 1'b1; //not really needed
        valid_master_in = 1'b1;
        //test_data =
        312'h3253_1238__3253_1238_A242_A242__3253_1238__41__3253_1238_A242_A242__3253_1238_A242_0043__32AD__1400_test_data = 304'h2441_0000000000000000000a000000000000000142000000014141504c202020200186a000;
        test = 8'hBA;
        test_1 = test[7-:8];
        test_2 = test[0+:8];
        for(integer i =0; i <= 7; i = i + 1) begin
            test_3[i] = test[7 - i];
        end
        #20
        enable_in = 1'b1;
        #20
        reset_in = 1'b0;
        data_in = test_data[size - 1 -:8];
        for(integer i = size - 1 - 8; i >= 7 ; i = i - 8) begin
            #20
            data_in = test_data[i-:8];
        end
        // #10
        // data_in = 32'hAF_32_13_45;
        // #600
        // data_in = 32'hAF_32_13_41;
        // #600
        // data_in = 32'hAF_32_13_41;
        // #600
        // data_in = 32'hAF_32_13_44;
        end
endmodule