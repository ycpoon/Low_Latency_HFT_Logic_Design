module memory_manager_for_tree_based_rep(
    input clk_in,
    input logic start,
    input logic is_write,
    input logic [ADDRESS_INDEX:0] addr,
    input book_entry data_i,
    output book_entry data_o,
    output logic valid
);

    logic [10:0] counter = 0;
    logic write;

    localparam WAITING = 0;
    localparam STARTED = 1;

    logic [2:0] state = WAITING;
    logic enable = 0;

    blk_mem_gen_0 mem (
        .clka(clk_in),
        .addra(addr),
        .douta(data_o),
        .dina(data_i),
        .ena(enable),
        .wea(write)
    );

    // ila_0 my_ila(.clk(clk_in), .probe0(start_book), .probe1(best_price_o), .probe2(current_size));

    always_ff @(posedge clk_in) begin
        case (state)
            WAITING: begin
                valid <= 0;
                if (start) begin
                    write <= is_write;
                    state <= STARTED;
                    counter <= 1;
                    enable <= 1;
                end
            end
            STARTED: begin
                if (counter < BRAM_LATENCY + 1) begin
                    counter <= counter + 1;
                end else begin
                    state <= WAITING;
                    counter <= 0;
                    valid <= 1;
                    enable <= 0;
                    write <= 0;
                end
            end
        endcase
    end

endmodule

module memory_manager(
    input clk_in,
    input logic start,
    input logic is_write,
    input logic [ADDRESS_INDEX:0] addr,
    input book_entry data_i,
    output book_entry data_o,
    output logic valid
);

    logic [10:0] counter = 0;
    logic write;

    localparam WAITING = 0;
    localparam STARTED = 1;

    logic [2:0] state = WAITING;
    logic enable = 0;

    blk_mem_gen_0 mem (
        .clka(clk_in),
        .addra(addr),
        .douta(data_o),
        .dina(data_i),
        .ena(enable),
        .wea(write)
    );

    // ila_0 my_ila(.clk(clk_in), .probe0(start_book), .probe1(best_price_o), .probe2(current_size));

    always_ff @(posedge clk_in) begin
        case (state)
            WAITING: begin
                valid <= 0;
                if (start) begin
                    write <= is_write;
                    state <= STARTED;
                    counter <= 1;
                    enable <= 1;
                end
            end
            STARTED: begin
                if (counter < BRAM_LATENCY) begin
                    counter <= counter + 1;
                end else begin
                    state <= WAITING;
                    counter <= 0;
                    valid <= 1;
                    enable <= 0;
                    write <= 0;
                end
            end
        endcase
    end

endmodule

