module decrease_order#(parameter SIDE=BUY_SIDE)
(
    input clk_in,
    input logic [ORDER_INDEX:0] id,
    input [QUANTITY_INDEX:0] quantity,
    input [PRICE_INDEX:0] best_price,
    input delete,
    input mem_valid,
    input [SIZE_INDEX:0] size,
    input start,
    input read_result data_r,
    output mem_struct mem_control,
    output book_entry data_w,
    output logic ready,
    output logic [SIZE_INDEX:0] size_update_o,
    output logic [CANCEL_UPDATE_INDEX:0] update
);

    logic [SIZE_INDEX:0] index;
    logic [SIZE_INDEX:0] size_latched;
    localparam WAITING = 3'b000;
    localparam FIND = 3'b001;
    localparam DELETE = 3'b010;
    localparam UPDATE = 3'b110;
    localparam DONE = 3'b011;
    localparam NOT_FOUND = 3'b111;
    localparam COPY = 2'b00;
    localparam MOVE = 2'b01;
    localparam MEM_IDLE = 0;
    localparam MEM_PROGRESS = 1;

    logic [2:0] mem_state = MEM_IDLE;
    logic [2:0] state = WAITING;
    logic [SIZE_INDEX:0] update_index;
    logic [2:0] delete_state;
    logic [QUANTITY_INDEX:0] quantity_latched;
    logic delete_latched;
    book_entry copy_entry;

    assign size_update_o = size_latched;

    // Debugging signal (commented out, but can be used for monitoring)
    // ila_1 my_ila(.clk(clk_in), .probe0(0), .probe1(data_r), .probe2(mem_valid), .probe3(start), .probe4(mem_control.addr));

    always_ff @(posedge clk_in) begin
        case (state)
            WAITING: begin
                data_w <= 0;
                update <= WAITING;
                if (start) begin
                    index <= 0;
                    state <= FIND;
                    mem_state <= MEM_IDLE;
                    size_latched <= size;
                    quantity_latched <= quantity;
                    delete_latched <= delete;
                    ready <= 0;
                end else begin
                    ready <= 0;
                end
            end

            UPDATE: begin
                case(mem_state)
                    MEM_IDLE: begin
                        mem_control.addr <= update_index;
                        mem_control.is_write <= 1;
                        mem_control.start <= 1;
                        data_w <= '{price: copy_entry.price, order_id: copy_entry.order_id, quantity: copy_entry.quantity - quantity_latched};
                        mem_state <= MEM_PROGRESS;
                    end
                    MEM_PROGRESS: begin
                        mem_control.start <= 0;
                        if (mem_valid) begin
                            mem_state <= MEM_IDLE;
                            state <= WAITING;
                            update <= UPDATE;
                            ready <= 1;
                        end
                    end
                endcase
            end

            FIND: begin
                case(mem_state)
                    MEM_IDLE: begin
                        if (index < size_latched) begin
                            mem_control <= '{addr: index, is_write: 0, start: 1};
                            mem_state <= MEM_PROGRESS;
                        end else begin
                            state <= WAITING;
                            update <= NOT_FOUND;
                            ready <= 1;
                        end
                    end
                    MEM_PROGRESS: begin
                        mem_control.start <= 0;
                        if (mem_valid) begin
                            mem_state <= MEM_IDLE;
                            if (data_r.first.order_id == id) begin
                                update_index <= index;
                                if (data_r.first.quantity <= quantity || delete_latched) begin
                                    state <= DELETE;
                                    delete_state <= COPY;
                                end else begin
                                    state <= UPDATE;
                                    copy_entry <= data_r.first;
                                end
                            end else begin
                                index <= index + 1;
                            end
                        end
                    end
                endcase
            end

            DELETE: begin
                case(delete_state)
                    COPY: begin
                        case(mem_state)
                            MEM_IDLE: begin
                                if (update_index + 1 < size_latched) begin
                                    mem_control.addr <= update_index + 1;
                                    mem_control.is_write <= 0;
                                    mem_control.start <= 1;
                                    mem_state <= MEM_PROGRESS;
                                end else begin
                                    size_latched <= size_latched - 1;
                                    state <= WAITING;
                                    ready <= 1;
                                    update <= DELETE;
                                end
                            end
                            MEM_PROGRESS: begin
                                mem_control.start <= 0;
                                if (mem_valid) begin
                                    copy_entry <= data_r.first;
                                    delete_state <= MOVE;
                                    mem_state <= MEM_IDLE;
                                end
                            end
                        endcase
                    end

                    MOVE: begin
                        case(mem_state)
                            MEM_IDLE: begin
                                mem_control.addr <= update_index;
                                mem_control.is_write <= 1;
                                mem_control.start <= 1;
                                data_w <= copy_entry;
                                mem_state <= MEM_PROGRESS;
                            end
                            MEM_PROGRESS: begin
                                mem_control.start <= 0;
                                if (mem_valid) begin
                                    mem_state <= MEM_IDLE;
                                    delete_state <= COPY;
                                    update_index <= update_index + 1;
                                end
                            end
                        endcase
                    end
                endcase
            end
        endcase
    end
endmodule
