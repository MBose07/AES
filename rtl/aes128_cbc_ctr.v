

module aes128_cbc_ctr (
    input clk, rst_n,
    
    // Mode: 0=ECB, 1=CBC, 2=CTR
    input [1:0] mode_i,
    
    // Control
    input start_i, stop_i, soft_reset_i,
    
    // Key interface
    input [127:0] key_i,
    input key_valid_i,
    
    // IV / Nonce (used by CBC/CTR)
    input [127:0] iv_i,
    input iv_valid_i,
    
    // Data interface (plaintext in, ciphertext out)
    input [127:0] plaintext_i,
    input plaintext_valid_i,
    output [127:0] ciphertext_o,
    output ciphertext_valid_o,
    
    // Status
    output busy_o
);

    // ====== Key Expansion ======
    wire [1407:0] round_keys_flat;
    wire keys_valid;
    
    aes_key_expand_128 key_exp (
        .clk(clk), .rst_n(rst_n),
        .key_in(key_i),
        .key_valid(key_valid_i),
        .round_keys_flat(round_keys_flat),
        .round_keys_valid(keys_valid)
    );
    
    reg [127:0] pipeline_input;
    reg pipeline_input_valid;
    wire [127:0] pipeline_output;
    wire pipeline_output_valid;
    wire [1:0] pipeline_key_epoch_out;
    wire pipeline_in_ready;
    wire pipeline_busy;
    
    aes_pipeline_core ecb_core (
        .clk(clk), .rst_n(rst_n),
        .start(start_i),
        .in_block(pipeline_input),
        .in_valid(pipeline_input_valid),
        .round_keys_flat(round_keys_flat),
        .key_epoch_in(2'b0),
        .in_ready(pipeline_in_ready),
        .out_block(pipeline_output),
        .out_valid(pipeline_output_valid),
        .out_key_epoch(pipeline_key_epoch_out),
        .busy(pipeline_busy)
    );
    reg [127:0] iv_reg;
    reg [127:0] prev_ciphertext;  // For CBC: feedback
    reg [127:0] counter_val;       // For CTR: block counter
    
    reg [127:0] ecb_ciphertext;
    reg [127:0] cbc_ciphertext;
    reg [127:0] ctr_plaintext_xor_enc;
    reg [127:0] plaintext_delayed;
    reg output_valid_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            iv_reg <= 128'b0;
            prev_ciphertext <= 128'b0;
            counter_val <= 128'b0;
            pipeline_input <= 128'b0;
            pipeline_input_valid <= 1'b0;
            plaintext_delayed <= 128'b0;
            ecb_ciphertext <= 128'b0;
            cbc_ciphertext <= 128'b0;
            ctr_plaintext_xor_enc <= 128'b0;
            output_valid_r <= 1'b0;
        end else if (soft_reset_i) begin
            prev_ciphertext <= iv_reg;
            counter_val <= iv_reg;
            pipeline_input <= 128'b0;
            pipeline_input_valid <= 1'b0;
            plaintext_delayed <= 128'b0;
            ecb_ciphertext <= 128'b0;
            cbc_ciphertext <= 128'b0;
            ctr_plaintext_xor_enc <= 128'b0;
            output_valid_r <= 1'b0;
        end else begin
            // Load IV on iv_valid pulse
            if (iv_valid_i) begin
                iv_reg <= iv_i;
                prev_ciphertext <= iv_i;  // CBC: use IV as C_0
                counter_val <= iv_i;       // CTR: use IV as nonce base
            end
            pipeline_input_valid <= 1'b0;
            
            // Pipeline control based on mode
            if (mode_i == 2'd0) begin
                // ECB: plaintext -> ciphertext directly
                if (!stop_i && plaintext_valid_i) begin
                    pipeline_input <= plaintext_i;
                    pipeline_input_valid <= 1'b1;
                end
            end else if (mode_i == 2'd1) begin
                // CBC: P XOR prev_ciphertext -> E -> C
                if (!stop_i && !pipeline_busy && plaintext_valid_i) begin
                    pipeline_input <= plaintext_i ^ prev_ciphertext;
                    pipeline_input_valid <= 1'b1;
                end
            end else if (mode_i == 2'd2) begin
                // CTR: counter -> E -> (E XOR P) = C
                if (!stop_i && plaintext_valid_i) begin
                    pipeline_input <= counter_val;
                    pipeline_input_valid <= 1'b1;
                    plaintext_delayed <= plaintext_i;  // Store for XOR after E
                end
            end
            
            output_valid_r <= pipeline_output_valid;
            
            if (pipeline_output_valid) begin
                ecb_ciphertext <= pipeline_output;
                if (mode_i == 2'd1) begin
                    // CBC: E output = ciphertext (feedback for next block)
                    cbc_ciphertext <= pipeline_output;
                    prev_ciphertext <= pipeline_output;
                end else if (mode_i == 2'd2) begin
                    // CTR: P XOR E(counter) = C
                    ctr_plaintext_xor_enc <= plaintext_delayed ^ pipeline_output;
                    // Increment counter for next block
                    counter_val <= counter_val + 1;
                end
            end
        end
    end
    
    // Output multiplexer 
    assign ciphertext_o = (mode_i == 2'd0) ? ecb_ciphertext :
                          (mode_i == 2'd1) ? cbc_ciphertext : ctr_plaintext_xor_enc;
    assign ciphertext_valid_o = output_valid_r;
    assign busy_o = pipeline_busy;

endmodule

