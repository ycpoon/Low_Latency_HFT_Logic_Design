module debounce (
    input reset_in, 
    input clock_in, 
    input noisy_in,
    output reg clean_out
);

    reg [19:0] count;
    reg new_input;

    always_ff @(posedge clock_in) begin
        if (reset_in) begin
            new_input <= noisy_in;
            clean_out <= noisy_in;
            count <= 0;
        end else if (noisy_in != new_input) begin
            new_input <= noisy_in;
            count <= 0;
        end else if (count == 1000000) begin
            clean_out <= new_input;
        end else begin
            count <= count + 1;
        end
    end

endmodule
