module processing_element (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               weight_load_en, // 1 to save incoming data as a Weight
    input  logic signed [7:0]  act_in,         // 8-bit Activation from Left
    input  logic signed [31:0] psum_in,        // 32-bit Partial Sum from Top
    output logic signed [7:0]  act_out,        // 8-bit Activation to Right
    output logic signed [31:0] psum_out        // 32-bit Partial Sum to Bottom
);
    logic signed [7:0] weight_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 8'sd0;
            act_out    <= 8'sd0;
            psum_out   <= 32'sd0;
        end else begin
            if (weight_load_en) begin
                weight_reg <= act_in;  
                act_out    <= act_in;  
            end else begin
                act_out  <= act_in;    
                psum_out <= (act_in * weight_reg) + psum_in;
            end
        end
    end
endmodule
