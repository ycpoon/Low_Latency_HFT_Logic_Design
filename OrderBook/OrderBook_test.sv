

module top_level(input clk_100mhz, input btnu, input [15:0] sw);
    logic pick_next;
    debounce d1(
        .clock_in(clk_100mhz), 
        .reset_in(sw[15]), 
        .noisy_in(btnu), 
        .clean_out(pick_next)
    );

    logic pick_next_previous;
    logic change;

    always_ff @(posedge clk_100mhz) begin
        pick_next_previous <= pick_next;
        change <= pick_next_previous == 0 && pick_next == 1;
    end

    logic busy;
    top_level_fpga_tester fpga_tester(
        .clk_in(clk_100mhz), 
        .next(change), 
        .reset(sw[15]),
        .busy(busy)
    );
endmodule

module top_level_fpga_tester(
    input clk_in, 
    input next, 
    input reset, 
    output busy
);
    logic [STOCK_INDEX:0] stock_to_add;
    book_entry entry;
    reg start;
    logic [2:0] request;
    logic delete;
    logic is_busy;
    logic [ORDER_INDEX:0] order_id;
    logic [QUANTITY_INDEX:0] quantity;
    logic [PRICE_INDEX:0] best_price_stocks [NUM_STOCK_INDEX:0];

    order_book_wrapper top_ (
        .clk_in(clk_in),
        .rst_in(reset),
        .stock_to_add(stock_to_add),
        .order_to_add(entry),
        .start(start),
        .request(request),
        .order_id(order_id),
        .delete(delete), // should be one if cancel
        .quantity(quantity),
        .is_busy(is_busy),
        .best_price_stocks(best_price_stocks) // should be supplied for a trade
    );

    localparam FIRST = 0;
    localparam END = 8;
    localparam WAIT_FIRST = 2'b00;
    localparam WAIT_NEXT = 2'b01;
    localparam PROGRESS = 2'b11;

    logic [1:0] top_level = WAIT_NEXT;
    logic [7:0] state = 0;
    reg pick_next_previous;
    logic [PRICE_INDEX:0] best_price;
    assign best_price = best_price_stocks[1];

    ila_0 top_level_ila (
        .clk(clk_in),
        .probe0(best_price),
        .probe1(top_level),
        .probe2(state)
    );

    logic change_signal;
    assign busy = (top_level == PROGRESS) || is_busy;

    always_ff @(posedge clk_in) begin
        case(top_level)
            PROGRESS: begin
                case(state)
                    1: begin
                        stock_to_add <= 0;
                        start <= 1;
                        entry <= '{price: 2, order_id: 2, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    2: begin
                        stock_to_add <= 0;
                        start <= 1;
                        entry <= '{price: 4, order_id: 3, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    3: begin
                        stock_to_add <= 0;
                        start <= 1;
                        entry <= '{price: 4, order_id: 4, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    4: begin
                        stock_to_add <= 0;
                        start <= 1;
                        order_id <= 4;
                        delete <= 1;
                        request <= CANCEL_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    5: begin
                        stock_to_add <= 0;
                        start <= 1;
                        order_id <= 3;
                        delete <= 1;
                        request <= CANCEL_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                endcase
            end
            WAIT_FIRST: begin
                top_level <= WAIT_NEXT;
            end
            WAIT_NEXT: begin
                start <= 0;
                if(!is_busy && state < END && next) begin
                    state <= state + 1;
                    top_level <= PROGRESS;
                end
            end
        endcase
    end
endmodule


module top_level_fpga_tester_demo(input clk_in, input next, input reset, output busy);
    logic [STOCK_INDEX:0] stock_to_add;
    book_entry entry;
    reg start;
    logic [2:0] request;
    logic delete;
    logic is_busy;
    logic [ORDER_INDEX:0] order_id;
    logic [QUANTITY_INDEX:0] quantity;
    
    localparam num_prices = 1;
    logic [31:0] price_index;
    logic [PRICE_INDEX:0] d_array [num_prices:0] [NUM_STOCK_INDEX:0] = '{'{101, 102, 103, 104},
                                                                                 '{ 105, 107, 108, 110}};
    logic [PRICE_INDEX:0] best_price_stocks [NUM_STOCK_INDEX:0];

    order_book_wrapper top_orderbook(
        .clk_in(clk_in),
        .rst_in(reset),
        .stock_to_add(stock_to_add),
        .order_to_add(entry),
        .start(start),
        .request(request),
        .order_id(order_id),
        .delete(delete), // should be one if cancel
        .quantity(quantity),
        .is_busy(is_busy),
        .best_price_stocks(best_price_stocks) // should be supplied for a trade
    );

    localparam FIRST = 0;
    localparam END = 8;
    logic price_valid = 0;
    localparam WAIT_FIRST = 2'b00;
    localparam WAIT_NEXT = 2'b01;
    localparam PROGRESS = 2'b11;
    logic [1:0] top_level = WAIT_NEXT;
    logic [7:0] state = 0;
    reg pick_next_previous;
    logic [PRICE_INDEX:0] best_price;
    assign best_price = best_price_stocks[1];

    ila_0 top_level_ila(
        .clk(clk_in), 
        .probe0(best_price), 
        .probe1(top_level), 
        .probe2(state)
    );

    logic change_signal;
    assign busy = (top_level == PROGRESS) || is_busy;

    localparam events = 4;

    always_ff @(posedge clk_in) begin
        case(top_level)
            PROGRESS: begin
                case(state)
                    1: begin
                        stock_to_add <= 0;
                        start <= 1;
                        entry <= '{price: 2, order_id: 2, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    2: begin
                        stock_to_add <= 1;
                        start <= 1;
                        entry <= '{price: 4, order_id: 2, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    3: begin
                        stock_to_add <= 0;
                        start <= 1;
                        order_id <= 2;
                        delete <= 1;
                        request <= CANCEL_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                    4: begin
                        stock_to_add <= 1;
                        start <= 1;
                        order_id <= 2;
                        delete <= 1;
                        request <= CANCEL_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                endcase
            end
            WAIT_FIRST: begin
                top_level <= WAIT_NEXT;
            end
            WAIT_NEXT: begin
                start <= 0;
                if(!is_busy && next) begin
                    if(state == events) begin
                        price_index <= price_index + 1;
                        price_valid <= 1;
                    end
                    else begin
                        state <= state + 1;
                        price_valid <= 0;
                    end
                    top_level <= PROGRESS;
                end
            end
        endcase
    end
endmodule

module top_level_simulation(
    input clk_in, 
    input next, 
    input reset, 
    output busy,
    output logic[PRICE_INDEX:0] best_price_stocks [0:NUM_STOCK_INDEX],
    output logic stocks_valid
);

    logic [STOCK_INDEX:0] stock_to_add;
    book_entry entry;
    reg start;
    logic [2:0] request;
    logic delete;
    logic is_busy;
    logic [ORDER_INDEX:0] order_id;
    logic [QUANTITY_INDEX:0] quantity;

    order_book_wrapper top_ (
        .clk_in(clk_in),
        .rst_in(reset),
        .stock_to_add(stock_to_add),
        .order_to_add(entry),
        .start(start),
        .request(request),
        .order_id(order_id),
        .delete(delete), // should be one if cancel
        .quantity(quantity),
        .is_busy(is_busy),
        .best_price_stocks(best_price_stocks),
        .best_prices_valid(stocks_valid) // should be supplied for a trade
    );

    localparam FIRST = 0;
    localparam END = 5;
    localparam WAIT_FIRST = 2'b00;
    localparam WAIT_NEXT = 2'b01;
    localparam PROGRESS = 2'b11;

    logic [1:0] top_level = WAIT_NEXT;
    logic [7:0] state = 0;
    reg pick_next_previous;
    logic [PRICE_INDEX:0] best_price;
    assign best_price = best_price_stocks[0];

    ila_0 top_level_ila (
        .clk(clk_in),
        .probe0(best_price),
        .probe1(top_level),
        .probe2(state)
    );

    logic change_signal;
    assign busy = (top_level == PROGRESS) || is_busy;

    logic [PRICE_INDEX:0] d_array_ [0:END] [0:NUM_STOCK_INDEX] = '{
        '{ 100*2**8, 106*2**8, 107*2**8, 108*2**8},
        '{ 101*2**8, 107*2**8, 108*2**8, 109*2**8},
        '{ 104*2**8, 110*2**8, 109*2**8, 110*2**8},
        '{ 106*2**8, 111*2**8, 111*2**8, 114*2**8},
        '{ 110*2**8, 113*2**8, 114*2**8, 116*2**8},
        '{ 110*2**8, 113*2**8, 114*2**8, 116*2**8}
    };

    logic [PRICE_INDEX:0] d_array [1:0] [NUM_STOCK_INDEX:0] = '{
        '{ 100.0*2**8, 40.0*2**8, 50.0*2**8, 60.0*2**8},
        '{ 115.355298916*2**8, 40.9465656921*2**8, 50.0*2**8, 60.0*2**8}
    };

    logic [PRICE_INDEX:0] price_ [NUM_STOCK_INDEX:0] = { 
        100.0*2**8, 40.0*2**8, 50.0*2**8, 60.0*2**8
    };

    logic [3:0] stock_index = 0;
    logic [3:0] price_index = 0;
    parameter INITIAL = 0;
    parameter ADD = 1;
    parameter DELETE = 2;

    always_ff @(posedge clk_in) begin
        case(top_level)
            PROGRESS: begin
                case(state)
                    ADD: begin
                        stock_to_add <= stock_index;
                        start <= 1;
                        entry <= '{price: d_array_[price_index][stock_index], order_id: 2, quantity: 2};
                        request <= ADD_ORDER;
                        top_level <= WAIT_FIRST;
                    end
                endcase
            end

            WAIT_FIRST: begin
                top_level <= WAIT_NEXT;
            end

            WAIT_NEXT: begin
                start <= 0;
                if(!is_busy && price_index <= END) begin
                    if(next && (state == INITIAL)) begin
                        stock_index <= 0;
                        state <= ADD;
                        top_level <= PROGRESS;
                    end
                    else if(stock_index < NUM_STOCK_INDEX) begin
                        stock_index <= stock_index + 1;
                        state <= ADD;
                        top_level <= PROGRESS;
                    end
                    else if(next && price_index < END) begin
                        stock_index <= 0;
                        state <= ADD;
                        price_index <= price_index + 1;
                        top_level <= PROGRESS;
                    end
                end
            end
        endcase
    end
endmodule

