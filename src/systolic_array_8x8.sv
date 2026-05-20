module systolic_array_8x8 (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               weight_load_en,
    input  logic [63:0]        act_in_left_flat, 
    input  logic [255:0]       psum_in_top_flat, 
    output logic [255:0]       psum_out_bottom_flat 
);
    logic signed [7:0]  act_wires  [0:7][0:8]; 
    logic signed [31:0] psum_wires [0:8][0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : edge_wiring
            assign act_wires[i][0]    = act_in_left_flat[(i*8)+7 : i*8];
            assign psum_wires[0][i]   = psum_in_top_flat[(i*32)+31 : i*32];
            assign psum_out_bottom_flat[(i*32)+31 : i*32] = psum_wires[8][i];
        end
    endgenerate

    genvar row, col;
    generate
        for (row = 0; row < 8; row++) begin : row_gen
            for (col = 0; col < 8; col++) begin : col_gen
                processing_element PE (
                    .clk            (clk),
                    .rst_n          (rst_n),
                    .weight_load_en (weight_load_en),
                    .act_in         (act_wires[row][col]),
                    .act_out        (act_wires[row][col+1]),
                    .psum_in        (psum_wires[row][col]),
                    .psum_out       (psum_wires[row+1][col])
                );
            end
        end
    endgenerate
endmodule
