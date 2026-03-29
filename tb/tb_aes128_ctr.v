// CTR Mode Test
// Based on NIST SP 800-38A vectors

`timescale 1ns/1ps

module tb_aes128_ctr;

    reg clk, rst_n;
    
    // Testbench signals
    wire [127:0] cipher_out;
    wire cipher_valid;
    wire busy;
    
    reg [127:0] key;
    reg key_valid;
    reg [127:0] nonce;
    reg nonce_valid;
    reg [127:0] plaintext;
    reg plaintext_valid;
    
    // Test vectors (NIST SP 800-38A Example 5 - CTR mode)
    // Key: 2b7e151628aed2a6abf7158809cf4f3c
    // Nonce/IV: f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
    // Initial counter: 00000001
    
    // Plaintext blocks (4 blocks):
    //   6bc1bee22e409f96e93d7e117393172a
    //   ae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411
    //   e5fbc1191a0a52eff69f2445df4f9b17b5b91ff7c3cc4b20
    
    // Expected ciphertext:
    //   874d6191b620e3261bef6864990db6ce
    //   9806f66b7970fdff8617187bb9fffdff5ae4df3edbd5d35e5b4f09020db03e46
    
    reg [127:0] nonce_vec = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
    
    reg [127:0] key_vec = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    
    // Block 1: plaintext
    reg [127:0] pt_1 = 128'h6bc1bee22e409f96e93d7e117393172a;
    reg [127:0] ct_1_exp = 128'h874d6191b620e3261bef6864990db6ce;
    
    // Block 2: plaintext
    reg [127:0] pt_2 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    reg [127:0] ct_2_exp = 128'h9806f66b7970fdff8617187bb9fffdff;
    
    // Block 3: plaintext
    reg [127:0] pt_3 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
    reg [127:0] ct_3_exp = 128'h5ae4df3edbd5d35e5b4f09020db03eab;
    
    // Block 4: plaintext
    reg [127:0] pt_4 = 128'hf69f2445df4f9b17ad2b417be66c3710;
    reg [127:0] ct_4_exp = 128'h1e031dda2fbe03d1792170a0f3009cee;
    
    // Instantiate CBC/CTR wrapper in CTR mode
    aes128_cbc_ctr dut (
        .clk(clk), .rst_n(rst_n),
        .mode_i(2'd2),  // CTR mode
        .start_i(1'b1), .stop_i(1'b0), .soft_reset_i(1'b0),
        .key_i(key), .key_valid_i(key_valid),
        .iv_i(nonce), .iv_valid_i(nonce_valid),
        .plaintext_i(plaintext), .plaintext_valid_i(plaintext_valid),
        .ciphertext_o(cipher_out), .ciphertext_valid_o(cipher_valid),
        .busy_o(busy)
    );
    
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 100 MHz
    end
    
    // Test sequence
    initial begin
        $dumpfile("tb_aes128_ctr.vcd");
        $dumpvars(0, tb_aes128_ctr);
        
        rst_n = 1'b0;
        key_valid = 1'b0;
        nonce_valid = 1'b0;
        plaintext_valid = 1'b0;
        #20 rst_n = 1'b1;
        #10;
        
        // Load key
        key = key_vec;
        key_valid = 1'b1;
        #10 key_valid = 1'b0;
        #50;
        
        // Load nonce (with counter initialized to 0)
        nonce = nonce_vec;  // Initial counter = 0, will increment to 1 before first E()
        nonce_valid = 1'b1;
        #10 nonce_valid = 1'b0;
        #50;
        
        // Block 1
        plaintext = pt_1;
        plaintext_valid = 1'b1;
        #10 plaintext_valid = 1'b0;
        wait (cipher_valid);
        #10 @(posedge clk);
        if (cipher_out === ct_1_exp)
            $display("CTR Block 1: PASS (got %h)", cipher_out);
        else
            $display("CTR Block 1: FAIL (got %h, expected %h)", cipher_out, ct_1_exp);
        
        #50;
        wait (~cipher_valid);  // Wait for valid to drop
        #50;
        
        // Block 2
        plaintext = pt_2;
        plaintext_valid = 1'b1;
        #10 plaintext_valid = 1'b0;
        wait (cipher_valid);
        #10 @(posedge clk);
        if (cipher_out === ct_2_exp)
            $display("CTR Block 2: PASS (got %h)", cipher_out);
        else
            $display("CTR Block 2: FAIL (got %h, expected %h)", cipher_out, ct_2_exp);
        
        #50;
        wait (~cipher_valid);  // Wait for valid to drop
        #50;
        
        // Block 3
        plaintext = pt_3;
        plaintext_valid = 1'b1;
        #10 plaintext_valid = 1'b0;
        wait (cipher_valid);
        #10 @(posedge clk);
        if (cipher_out === ct_3_exp)
            $display("CTR Block 3: PASS (got %h)", cipher_out);
        else
            $display("CTR Block 3: FAIL (got %h, expected %h)", cipher_out, ct_3_exp);
        
        #50;
        wait (~cipher_valid);  // Wait for valid to drop
        #50;
        
        // Block 4
        plaintext = pt_4;
        plaintext_valid = 1'b1;
        #10 plaintext_valid = 1'b0;
        wait (cipher_valid);
        #10 @(posedge clk);
        if (cipher_out === ct_4_exp)
            $display("CTR Block 4: PASS (got %h)", cipher_out);
        else
            $display("CTR Block 4: FAIL (got %h, expected %h)", cipher_out, ct_4_exp);
        
        $display("=== CTR MODE TEST COMPLETE ===");
        $finish;
    end

endmodule
