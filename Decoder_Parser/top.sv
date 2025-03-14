parameter PRICE_INDEX = 15;
parameter ORDER_INDEX = 7;
parameter QUANTITY_INDEX = 7;
parameter PRICE_WIDTH = 15;
parameter ID_WIDTH = 15;
parameter QUANT_WIDTH = 7;

typedef struct packed {
    logic [PRICE_INDEX:0] price;
    logic [ORDER_INDEX:0] order_id;
    logic [QUANTITY_INDEX:0] quantity;
} book_entry;

module top(
    input [ID_WIDTH:0] order_id_out_add,
    input [PRICE_WIDTH:0] price_out_add,
    input [QUANT_WIDTH:0] quantity_out_add,
    input order_type_out_add,
    output book_entry order_to_add
);
    assign order_to_add.price = price_out_add;
    assign order_to_add.order_id = order_id_out_add;
    assign order_to_add.quantity = quantity_out_add;
endmodule