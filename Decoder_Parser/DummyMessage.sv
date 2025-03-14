module mkDummyMessage #(
  parameter PRICE_WIDTH = 15,
  parameter ID_WIDTH = 15,
  parameter QUANT_WIDTH = 7,
  parameter STOCK_WIDTH = 7,
  parameter DATA_WIDTH = 31
)(
  input clk_in,
  input reset_in,
  input [DATA_WIDTH:0] data_in,
  input enable_in,
  input valid_in,
  output [2:0] operation_out,
  output [STOCK_WIDTH:0] stock_symbol_out,
  output [ID_WIDTH:0] order_id_out,
  output [PRICE_WIDTH:0] price_out,
  output [QUANT_WIDTH:0] quantity_out,
  output logic ready_out
);

    logic start;
    logic [7:0] count;

    always @(posedge clk_in) begin
        if (reset_in) begin
            start <= 0;
            count <= 0;
            ready_out <= 0;
        end else begin
            if (~start && enable_in) begin
                start <= 1;
                count <= data_in;
            end else begin
                if (start && valid_in) begin
                    count <= count - 1;
                    if (count <= 3) begin
                        start <= 0;
                        ready_out <= 1;
                    end
                end else begin
                    ready_out <= 0;
                end
            end
        end
    end

endmodule
