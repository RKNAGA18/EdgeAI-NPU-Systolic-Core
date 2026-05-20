module input_buffer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs,         
    input  logic [7:0]  data_in,    
    
    output logic [63:0] data_out,   
    output logic        ready       
);
    logic [3:0]  cycle_count;       
    logic [63:0] shift_reg;         
    assign data_out = shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg   <= 64'b0;
            cycle_count <= 4'b0;
            ready       <= 1'b0;
        end 
        else begin
            ready <= 1'b0;
            if (cs) begin
                shift_reg <= {shift_reg[55:0], data_in};
                
                if (cycle_count == 4'd7) begin
                    cycle_count <= 4'd0; 
                    ready       <= 1'b1; 
                end 
                else begin
                    cycle_count <= cycle_count + 1'b1; 
                end
            end
        end
    end

endmodule
