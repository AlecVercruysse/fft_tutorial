
// top level 32-point FFT test.
// loads input from          rom/test_in.memh,
// compares output to        rom/gt_test_out.memh,
// writes computed output to rom/test_out.memh.
// (see "/sim/verify sim fft.ipynb" to process output)
module fft_testbench
  #(parameter width=16, N_2=5)();
   
   logic clk;
   logic start, load, done, reset;
   logic signed [width-1:0] rd, expected_re, expected_im, wd_re, wd_im;
   logic [2*width-1:0]        wd;
   logic [2*width-1:0]        idx, out_idx, expected;

   logic [N_2-1:0]            rd_adr;
   assign rd_adr = idx[N_2-1:0];
   
   logic [width-1:0]          input_data [0:2**N_2-1];
   logic [2*width-1:0]        expected_out [0:2**N_2-1];

   integer             f; // file pointer

   fft #(width, N_2) dut(clk, reset, start, load, rd_adr, rd, wd, done);
   
   // clk
   always
     begin
	clk = 1; #5; clk=0; #5;
     end
   
   // start of test: load `input_data`, `expected_out`, open output file, reset fft module.
   initial
     begin
	$readmemh("rom/test_in.memh", input_data);
	$readmemh("rom/gt_test_out.memh", expected_out);
        f = $fopen("rom/test_out.memh", "w"); // write computed values.
	idx=0; reset=1; #40; reset=0;
     end	

   // increment testbench counter and derive load/start signals
   always @(posedge clk)
     if (~reset) idx <= idx + 1;
     else idx <= idx;
   assign load =  idx < 2**N_2;
   assign start = idx === 2**N_2;

   // increment output address if done, reset if restarting FFT
   always @(posedge clk)
     if (load) out_idx <= 0;
     else if (done) out_idx <= out_idx + 1;
   
   // load/start logic
   assign rd = load ? input_data[idx[N_2-1:0]] : 0;  // read in test data by addressing `input_data` with `idx`.
   assign expected = expected_out[out_idx[N_2-1:0]]; // get test output by addressing `expected_out` with `idx`.
   assign expected_re = expected[2*width-1:width];   // get real      part of `expected` (gt output)
   assign expected_im = expected[width-1:0];         // get imaginary part of `expected` (gt output)
   assign wd_re = wd[2*width-1:width];               // get real      part of `wd` (computed output)
   assign wd_im = wd[width-1:0];                     // get imaginary part of `wd` (computed output)

   // if FFT is done, compare gt to computed output, and write computed output to file.
   always @(posedge clk)
     if (done) begin
	if (out_idx <= (2**N_2-1)) begin
           $fwrite(f, "%h\n", wd);
	   if (wd !== expected) begin
	      $display("Error @ out_idx %d: expected %b (got %b)    expected: %d+j%d, got %d+j%d", out_idx, expected, wd, expected_re, expected_im, wd_re, wd_im);
	   end
	end else begin
	   $display("Slade FFT test complete.");
           $fclose(f);
           $stop;
	end
     end
endmodule // fft_testbench


module bgu_testbench #(parameter width=16)();
   logic clk;
   logic [2*width-1:0] twiddle;
   logic [2*width-1:0] a;
   logic [2*width-1:0] b;
   logic [2*width-1:0] aout;
   logic [2*width-1:0] bout;

   initial
     forever begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
     end

   initial begin
      twiddle = 0;
      a = 0;
      b = 0;
      aout = 0;
      bout = 0; #10;
      assert (aout===0 && bout===0) else $error("case 1 failed.");

      twiddle = {16'h7FFF, 16'b0}; #10; assert(aout===0 && bout===0) else $error("case 2 failed.");
      b = {16'h7FFF, 16'b0}; #10; assert(aout==={16'h7FFE,16'b0} && bout==={16'h8002, 16'b0}) else $error("case 3 failed.");

      // real test case:
      // real b*w out: 0xEE59 (-4520). im b*w out: 0x58C2 (22722).
      // aout: 141 + j27382. bout:  9179 - j18062.
      twiddle = {16'h471C, 16'h6A6C}; a={16'h1234, 16'h1234}; b={16'h3FFF, 16'h3FFF}; #10;
      assert(aout==={16'h008C, 16'h6AF6} && bout==={16'h23DC, 16'hB972}) else $error("case 4 failed!");

      $display("BGU tests complete.");
   end

   fft_butterfly dut(twiddle, a, b, aout, bout);

endmodule // twiddlerom_testbench

// outdated (reset signal). previously tested working.
module agu_testbench #(parameter width=16, N_2=5)();

   // inputs
   logic clk;
   initial
     forever begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
     end
   logic  start;

   // outputs
   logic  done;
   logic  rdsel;
   logic  we0;
   logic [N_2-1:0] adr0a;
   logic [N_2-1:0] adr0b;
   logic           we1;
   logic [N_2-1:0] adr1a;
   logic [N_2-1:0] adr1b;
   logic [N_2-2:0] twiddleadr;

   fft_agu #(width, N_2) agu(clk, start, done, rdsel, we0, adr0a, adr0b, we1, adr1a, adr1b, twiddleadr);

   initial begin
      // init inputs and outputs to zero/default
      start = 0; done = 0; rdsel = 0; we0 = 0; adr0a = 0; adr0b = 0; we1 = 0; adr1a = 0; adr1b = 0; twiddleadr = 0; #10;

      // init inputs to starting values.
      start = 1; #10;
   end

endmodule // agu_testbench
