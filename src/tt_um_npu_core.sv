module tt_um_npu_core (
    input  logic [7:0] ui_in,    
    output logic [7:0] uo_out,   
    input  logic [7:0] uio_in,   
    output logic [7:0] uio_out,  
    output logic [7:0] uio_oe,   
    input  logic       ena,      
    input  logic       clk,      
    input  logic       rst_n     
);

    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;

    wire weight_load_en = uio_in[0];
    wire buffer_cs      = uio_in[1];
    wire [2:0] col_sel  = uio_in[4:2]; 
    wire [1:0] byte_sel = uio_in[6:5]; 

    logic [63:0] buffered_activations;
    logic        buffer_ready;
    
    // Flat arrays for the core engine
    logic [255:0] psum_in_flat;
    logic [255:0] psum_out_flat;

    // Tie the entire top row of partial sums to 0
    assign psum_in_flat = 256'd0;

    input_buffer INPUT_STAGE (
        .clk        (clk),
        .rst_n      (rst_n),
        .cs         (buffer_cs),
        .data_in    (ui_in),
        .data_out   (buffered_activations),
        .ready      (buffer_ready)
    );

    systolic_array_8x8 CORE_ENGINE (
        .clk                  (clk),
        .rst_n                (rst_n),
        .weight_load_en       (weight_load_en),
        .act_in_left_flat     (buffered_activations),
        .psum_in_top_flat     (psum_in_flat),
        .psum_out_bottom_flat (psum_out_flat)
    );

    // MUX Stage 1: Select the 32-bit column
    logic [31:0] selected_psum;
    assign selected_psum = (col_sel == 3'd0) ? psum_out_flat[31:0]   :
                           (col_sel == 3'd1) ? psum_out_flat[63:32]  :
                           (col_sel == 3'd2) ? psum_out_flat[95:64]  :
                           (col_sel == 3'd3) ? psum_out_flat[127:96] :
                           (col_sel == 3'd4) ? psum_out_flat[159:128]:
                           (col_sel == 3'd5) ? psum_out_flat[191:160]:
                           (col_sel == 3'd6) ? psum_out_flat[223:192]:
                                               psum_out_flat[255:224];

    // MUX Stage 2: Select the 8-bit byte for the output pins
    assign uo_out = (byte_sel == 2'b00) ? selected_psum[7:0]   :
                    (byte_sel == 2'b01) ? selected_psum[15:8]  :
                    (byte_sel == 2'b10) ? selected_psum[23:16] :
                                          selected_psum[31:24] ;

endmodule
