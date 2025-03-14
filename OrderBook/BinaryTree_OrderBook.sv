module tree_based_rep_order_book #(
  parameter IS_MAX = MAX
)(
  input clk_in,
  input rst_in,
  input book_entry order_to_add,
  input start_book,
  input delete,
  input [2:0] request,
  input [ORDER_INDEX:0] order_id, // should be supplied for a cancel / trade
  input [QUANTITY_INDEX:0] quantity, // should be supplied for a trade
  output logic is_busy_o,
  output logic [CANCEL_UPDATE_INDEX:0] cancel_update,
  output logic [PRICE_INDEX:0] best_price_o,
  output logic best_price_valid,
  output logic price_valid,
  output logic [SIZE_INDEX:0] size_book
);

  localparam START = 0;
  localparam PROGRESS = 1;

  logic start;
  logic [ADDRESS_INDEX:0] addr;
  logic [ADDRESS_INDEX:0] add_addr;
  logic [PRICE_INDEX:0] best_price = 0;
  assign best_price_o = best_price;

  logic [PRICE_INDEX:0] add_best_price;
  logic [PRICE_INDEX:0] decrease_best_price;

  book_entry data_i;
  book_entry data_o;
  book_entry add_data_w;
  book_entry decrease_w;

  logic mem_start;
  logic valid;
  logic is_write;
  logic is_write_add;
  logic add_start;
  logic decrease_start;
  logic add_ready;
  logic decrease_ready;
  logic add_mem_start;

  logic valid_mem;
  logic units_busy;

  logic [QUANTITY_INDEX:0] price_distr [0:MAX_INDEX];
  tree_based_rep order_space [0:MAX_INDEX];

  localparam WAITING_STATE = 2'b00;
  localparam PROGRESS_STATE = 2'b01;

  logic [2:0] request_latched = 0;

  logic [PRICE_INDEX:0] price_tree [0:7][0:100];
  logic is_busy = 0;
  assign is_busy_o = is_busy;

  logic [SIZE_INDEX:0] current_size = 0;
  logic [SIZE_INDEX:0] add_size;
  logic [SIZE_INDEX:0] decrease_size;
  assign size_book = current_size;
  assign best_price_valid = current_size > 0;

  read_result read_output;
  mem_struct mem_control;
  assign read_output.first = data_o;

  logic delete_actual;

  always_comb begin
    if (is_busy) begin
      case (request_latched)
        CANCEL_ORDER, EXECUTE_ORDER: begin
          addr = mem_control.addr;
          is_write = mem_control.is_write;
          mem_start = mem_control.start;
          data_i = decrease_w;
          units_busy = !decrease_ready;
        end
        default: begin
          addr = 0;
          units_busy = 0;
          is_write = 0;
          mem_start = 0;
          data_i = 0;
          units_busy = 0;
        end
      endcase
    end else begin
      addr = 0;
      units_busy = 0;
      is_write = 0;
      mem_start = 0;
      data_i = 0;
      units_busy = 0;
    end
  end

  logic [3:0] add_state;
  logic [1:0] add_mem_state;
  logic [1:0] current_state = WAITING_STATE;

  localparam MEM_IDLE = 0;
  localparam MEM_PROGRESS = 1;

  logic [2:0] mem_state = MEM_IDLE;
  logic [1:0] delete_state;
  logic [8:0] counter;

  always_ff @(posedge clk_in) begin
    if (start_book) begin
      counter <= 1;
      price_valid <= 0;
    end else if (counter <= LEVEL_INDEX) begin
      counter <= counter + 1;
    end else begin
      price_valid <= 1;
    end
  end

  logic [32:0] price_levels [0:MAX_LEVEL_INDEX] = {1, 2, 4, 8, 16, 32, 64};

  always_ff @(posedge clk_in) begin
    for (int i = 0; i < LEVEL_INDEX; i++) begin
      for (int j = 0; j < price_levels[i]; j++) begin
        if (price_tree[i+1][2*j+1] != 0) begin
          price_tree[i][j] <= price_tree[i+1][2*j + 1];
        end else begin
          price_tree[i][j] <= price_tree[i+1][2*j];
        end
      end
    end

    for (int j = 0; j < price_levels[LEVEL_INDEX]; j++) begin
      if (price_distr[2*j+1] != 0) begin
        price_tree[LEVEL_INDEX][j] <= 2*j + 1;
      end else if (price_distr[2*j] != 0) begin
        price_tree[LEVEL_INDEX][j] <= 2*j;
      end else begin
        price_tree[LEVEL_INDEX][j] <= 0;
      end
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      current_size <= 0;
      is_busy <= 0;
      for (integer i = 0; i < MAX_INDEX; i++) begin
        price_distr[i] <= 0;
        order_space[i] <= 0;
      end
    end else begin
      if (is_busy) begin
        add_start <= 0;
        decrease_start <= 0;
        if (!units_busy) begin
          is_busy <= 0;
          case (request_latched)
            CANCEL_ORDER, EXECUTE_ORDER: begin
              case (mem_state)
                MEM_PROGRESS: begin
                  mem_control.start <= 0;
                  if (valid_mem) begin
                    mem_state <= MEM_IDLE;
                  end
                end
              endcase
            end
          endcase
        end
      end else begin
        if (start_book) begin
          request_latched <= request;
          case (request)
            ADD_ORDER: begin
              current_size <= current_size + 1;
              order_space[order_to_add.order_id].quantity <= order_to_add.quantity;
              order_space[order_to_add.order_id].price <= order_to_add.price;
              price_distr[order_to_add.price] <= price_distr[order_to_add.price] + order_to_add.quantity;
            end
            CANCEL_ORDER, EXECUTE_ORDER: begin
              mem_control.addr <= order_id;
              mem_control.is_write <= 1;
              if (order_space[order_id].quantity != 0) begin
                current_size <= current_size - 1;
                if (request == CANCEL_ORDER) begin
                  order_space[order_id].quantity <= 0;
                  price_distr[order_space[order_id].price] <= price_distr[order_space[order_id].price] - order_space[order_id].quantity;
                end
              end
            end
          endcase
        end
      end
    end
  end

endmodule
