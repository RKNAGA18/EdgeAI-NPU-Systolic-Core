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
    logic weight_load_en = uio_in[0];
    logic buffer_cs      = uio_in[1];
    logic [2:0] col_sel  = uio_in[4:2]; 
    logic [1:0] byte_sel = uio_in[6:5]; 

    
    logic [63:0] buffered_activations;
    logic        buffer_ready;
    logic signed [7:0]  act_in_array [0:7];
    logic signed [31:0] psum_in_array [0:7];
    logic signed [31:0] psum_out_array [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign psum_in_array[i] = 32'sd0;
            assign act_in_array[i]  = buffered_activations[(i*8)+7 : (i*8)];
        end
    endgenerate
  
    input_buffer INPUT_STAGE (
        .clk        (clk),
        .rst_n      (rst_n),
        .cs         (buffer_cs),
        .data_in    (ui_in),
        .data_out   (buffered_activations),
        .ready      (buffer_ready)
    );

    
    systolic_array_8x8 CORE_ENGINE (
        .clk             (clk),
        .rst_n           (rst_n),
        .weight_load_en  (weight_load_en && buffer_ready),
        .act_in_left     (act_in_array),
        .psum_in_top     (psum_in_array),
        .psum_out_bottom (psum_out_array)
    );

    logic [31:0] selected_psum;
    assign selected_psum = psum_out_array[col_sel];

    always_comb begin
        case (byte_sel)
            2'b00: uo_out = selected_psum[7:0];  
            2'b01: uo_out = selected_psum[15:8];  
            2'b10: uo_out = selected_psum[23:16]; 
            2'b11: uo_out = selected_psum[31:24];
            default: uo_out = 8'b0;
        endcase
    end

endmodule
