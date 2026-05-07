`default_nettype none

module tt_um_RKNAGA18 (
    input  wire [7:0] ui_in,    // Data Bus
    output wire [7:0] uo_out,   // Result Bus (lower 8 bits of Acc)
    input  wire [7:0] uio_in,   // Control Bus
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // Control signals from uio
    wire weight_load = uio_in[0];
    wire compute_en  = uio_in[1];
    wire acc_clear   = uio_in[2];

    // Configure IOs: uio[0:3] as inputs, others as outputs
    assign uio_oe = 8'b11110000; 
    assign uio_out = 8'b0;

    // Internal connections for 2x2 Array
    wire [7:0] h_wire [2:0][1:0]; // Horizontal data flow
    wire [7:0] v_wire [1:0][2:0]; // Vertical data flow
    wire [31:0] acc_out [1:0][1:0];

    // Boundary Assignments: Feed ui_in to the edges
    assign h_wire[0][0] = ui_in; 
    assign v_wire[0][0] = ui_in;

    // Instantiate 2x2 Array of Processing Elements
    genvar i, j;
    generate
        for (i = 0; i < 2; i = i + 1) begin : rows
            for (j = 0; j < 2; j = j + 1) begin : cols
                mac_pe pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .weight_in(v_wire[i][j]),
                    .activation_in(h_wire[i][j]),
                    .weight_out(v_wire[i][j+1]),
                    .activation_out(h_wire[i+1][j]),
                    .accumulator(acc_out[i][j]),
                    .weight_load(weight_load),
                    .compute_en(compute_en),
                    .acc_clear(acc_clear)
                );
            end
        end
    endgenerate

    // Output the result of the first PE (for testing)
    assign uo_out = acc_out[0][0][7:0];

endmodule

// --- The Heart of the NPU: Processing Element ---
module mac_pe (
    input  wire clk, rst_n,
    input  wire signed [7:0]  weight_in,
    input  wire signed [7:0]  activation_in,
    output reg  signed [7:0]  weight_out,
    output reg  signed [7:0]  activation_out,
    output reg  signed [31:0] accumulator,
    input  wire weight_load, compute_en, acc_clear
);
    reg signed [7:0] weight_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            weight_reg <= 0;
            accumulator <= 0;
            weight_out <= 0;
            activation_out <= 0;
        end else begin
            if (weight_load) weight_reg <= weight_in;
            
            if (acc_clear)   accumulator <= 0;
            else if (compute_en) begin
                accumulator <= accumulator + (weight_reg * activation_in);
                weight_out <= weight_reg; // Pass weight down
                activation_out <= activation_in; // Pass activation right
            end
        end
    end
endmodule
