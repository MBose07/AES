// CBC Mode Test
// Based on NIST SP 800-38A vectors

`timescale 1ns/1ps

module tb_aes128_cbc;

    reg clk, rst_n;
    
    // Testbench signals
    wire [127:0] cipher_out;
    wire cipher_valid;
    wire busy;
    
    reg [127:0] key;
    reg key_valid;
    reg [127:0] iv;
    reg iv_valid;
    reg [127:0] plaintext;
    reg plaintext_valid;
    
    // Test vectors (NIST SP 800-38A, Example 1)
    // Key: 2b7e151628aed2a6abf7158809cf4f3c
    // IV:  000102030405060708090a0b0c0d0e0f
    // Plaintext blocks (4 blocks):
    //   6bc1bee22e409f96e93d7e117393172a
    //   ae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411
    //   e5fbc1191a0a52eff69f2445df4f9b17b5b91ff7c3cc4b20
    
    // Expected ciphertext:
    //   7649abac8119b246cee98e9b12e9197d
    //   5086cb9b507219ee95db113a917678b2
    //   73bed6b8e3c1743b7ee6d7d6d7d6b8e3
    
    reg [127:0] iv_vec = 128'h000102030405060708090a0b0c0d0e0f;
    
    reg [127:0] key_vec = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    
    // Block 1: plaintext
    reg [127:0] pt_1 = 128'h6bc1bee22e409f96e93d7e117393172a;
    reg [127:0] ct_1_exp = 128'h7649abac8119b246cee98e9b12e9197d;
    
    // Block 2: plaintext
    reg [127:0] pt_2 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    reg [127:0] ct_2_exp = 128'h5086cb9b507219ee95db113a917678b2;
    
    // Block 3: plaintext
    reg [127:0] pt_3 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
    reg [127:0] ct_3_exp = 128'h73bed6b8e3c1743b7116e69e22229516;
    
    // Block 4: plaintext
    reg [127:0] pt_4 = 128'hf69f2445df4f9b17ad2b417be66c3710;
    reg [127:0] ct_4_exp = 128'h3ff1caa1681fac09120eca307586e1a7;
    
    // Instantiate CBC/CTR wrapper
    aes128_cbc_ctr dut (
        .clk(clk), .rst_n(rst_n),
        .mode_i(2'd1),  // CBC mode
        .start_i(1'b1), .stop_i(1'b0), .soft_reset_i(1'b0),
        .key_i(key), .key_valid_i(key_valid),
        .iv_i(iv), .iv_valid_i(iv_valid),
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
        $dumpfile("tb_aes128_cbc.vcd");
        $dumpvars(0, tb_aes128_cbc);
        
        rst_n = 1'b0;
        key_valid = 1'b0;
        iv_valid = 1'b0;
        plaintext_valid = 1'b0;
        #20 rst_n = 1'b1;
        #10;
        
        // Load key
        key = key_vec;
        key_valid = 1'b1;
        #10 key_valid = 1'b0;
        #50;
        
        // Load IV
        iv = iv_vec;
        iv_valid = 1'b1;
        #10 iv_valid = 1'b0;
        #50;
        
        // Block 1
        plaintext = pt_1;
        plaintext_valid = 1'b1;
        #10 plaintext_valid = 1'b0;
        wait (cipher_valid);
        #10 @(posedge clk);
        if (cipher_out === ct_1_exp)
            $display("CBC Block 3: PASS (got %h, expected %h)   %h", cipher_out, ct_1_exp  , dut.pipeline_input);
        else
            $display("CBC Block 1: FAIL (got %h, expected %h)", cipher_out, ct_1_exp);
        
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
            $display("CBC Block 3: PASS (got %h, expected %h)   %h", cipher_out, ct_2_exp  , dut.pipeline_input);
        else
            $display("CBC Block 2: FAIL (got %h, expected %h)", cipher_out, ct_2_exp);
        
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
            $display("CBC Block 3: PASS (got %h, expected %h)   %h", cipher_out, ct_3_exp  , dut.pipeline_input);
        else
            $display("CBC Block 3: FAIL (got %h, expected %h)   %h", cipher_out, ct_3_exp  , dut.pipeline_input);
        
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
            $display("CBC Block 3: PASS (got %h, expected %h)   %h", cipher_out, ct_4_exp  , dut.pipeline_input);
        else
            $display("CBC Block 3: FAIL (got %h, expected %h)   %h", cipher_out, ct_4_exp  , dut.pipeline_input);
        
        $display("=== CBC MODE TEST COMPLETE ===");
        $finish;
    end

endmodule
