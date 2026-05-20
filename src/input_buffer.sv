module input_buffer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs,
    input  logic [7:0]  data_in,
    output logic [63:0] data_out,
    output logic        ready
);
    logic [63:0] shift_reg;
    logic [2:0]  counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 64'd0;
            counter   <= 3'd0;
            ready     <= 1'b0;
        end else if (cs) begin
            // Shift the new 8-bit byte into the top, push everything down
            shift_reg <= {data_in, shift_reg[63:8]};
            counter   <= counter + 1'b1;
            
            // Pulse ready when the buffer is completely full (8 bytes)
            if (counter == 3'd7)
                ready <= 1'b1;
            else
                ready <= 1'b0;
        end else begin
            ready <= 1'b0;
        end
    end
    
    assign data_out = shift_reg;

endmodule
