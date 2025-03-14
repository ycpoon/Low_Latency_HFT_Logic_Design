module order_book_wrapper(
    input clk_in,
    input rst_in,
    input [STOCK_INDEX:0] stock_to_add,
    input book_entry order_to_add,
    input start,
    input delete,
    input [QUANTITY_INDEX:0] quantity,
    input [2:0] request,
    input [ORDER_INDEX:0] order_id, //should be supplied for a cancel / trade
    output logic is_busy,
    output logic best_price_valid,
    output logic [CANCEL_UPDATE_INDEX:0] cancel_update,
    output logic [PRICE_INDEX:0] best_price_stocks [0:NUM_STOCK_INDEX],
    output logic [0:NUM_STOCK_INDEX] best_prices_valid,
    output logic [SIZE_INDEX:0] size_of_stocks [0:NUM_STOCK_INDEX]
);

    logic [NUM_STOCK_INDEX:0] order_book_start;
    logic [NUM_STOCK_INDEX:0] book_busy;
    logic [STOCK_INDEX:0] stock_latched;

    localparam WAITING = 2'b00;
    localparam INITATE = 2'b01;
    localparam PROGRESS = 2'b10;

    assign best_price_valid = &best_prices_valid;
    logic [2:0] state = WAITING;
    assign is_busy = state != WAITING;

    genvar i;
    generate
        for(i = 0; i < 4; i = i+1) begin
            order_book #(.IS_MAX(MAX)) book (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .order_to_add(order_to_add),
                .request(request),
                .start_book(order_book_start[i]),
                .order_id(order_id),
                .delete(delete),
                .quantity(quantity),
                .is_busy_o(book_busy[i]),
                .best_price_o(best_price_stocks[i]),
                .best_price_valid(best_prices_valid[i]),
                .size_book(size_of_stocks[i])
            );
        end
    endgenerate

    // ila_0 wrapper_ila(.clk(clk_in), .probe0(stock_to_add), .probe1(start), .probe2(state));

    always_ff @(posedge clk_in) begin
        case(state)
            WAITING: begin
                if(start) begin
                    if(stock_to_add < NUM_STOCKS) begin
                        state <= INITATE;
                        stock_latched <= stock_to_add;
                        //stock to add from 0 to 1
                        order_book_start[stock_to_add] <= 1;
                    end
                end
            end

            INITATE: begin
                state <= PROGRESS;
                order_book_start[stock_to_add] <= 0;
            end

            PROGRESS: begin
                if(!book_busy[stock_latched]) begin
                    state <= WAITING;
                end
            end
        endcase
    end

endmodule
