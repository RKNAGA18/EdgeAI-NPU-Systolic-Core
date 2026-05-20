module input_buffer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs,       // Chip Select: 1 to shift data in
    input  logic [7:0]  data_in,  // 8 bits from the outside world
    output logic [63:0] data_out, // 64 bits (8x8) to the Systolic Array
    output logic        ready     // High for 1 cycle when full
);
    logic [2:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 64'd0;
            counter  <= 3'd0;
            ready    <= 1'b0;
        end else if (cs) begin
            // Shift left by 8 and pull in the new byte
            data_out <= {data_out[55:0], data_in};
            counter  <= counter + 1;
            // Pulse ready when counter hits 7 (meaning 8 bytes loaded)
            ready    <= (counter == 3'd7);
        end else begin
            ready <= 1'b0;
        end
    end
endmodule
