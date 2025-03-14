module add_order#(parameter IS_MAX=MAX)(
    input clk_in, 
    input book_entry order, 
    input start, 
    input valid,
    input [QUANTITY_INDEX:0] price_distr,
    input [SIZE_INDEX:0] size, 
    input [PRICE_INDEX:0] best_price, 
    input price_valid,
    output logic [ADDRESS_INDEX:0] addr, 
    output logic mem_start,
    output book_entry data_w,
    output logic price_update,
    output logic quantity_update,
    output quantity,
    output logic is_write, 
    output logic ready, 
    output logic [SIZE_INDEX:0] size_update_o,
    output logic [PRICE_INDEX:0] add_best_price
);

    logic [1:0] add_mem_state = 0;
    localparam START = 0;
    localparam PROGRESS = 1;

    logic [SIZE_INDEX:0] size_update = 0;
    assign size_update_o = size_update;

    always_ff @(posedge clk_in) begin
        case(add_mem_state)
            START: begin
                ready <= 0;
                if (start) begin
                    if (size < MAX_INDEX) begin
                        addr <= size;
                        is_write <= 1;
                        size_update <= size + 1;
                        add_mem_state <= PROGRESS;
                        data_w <= order;
                        mem_start <= 1;
                        price_update <= order.price;
                        quantity_update <= order.quantity;

                        if (!price_valid || (order.price > best_price) == IS_MAX) begin
                            add_best_price <= order.price;
                        end else begin
                            add_best_price <= best_price;
                        end
                    end
                end
            end

            PROGRESS: begin
                mem_start <= 0;
                if (valid) begin
                    ready <= 1;
                    add_mem_state <= START;
                end
            end
        endcase
    end
endmodule
