// the width is the bit width (e.g. if width=16, 16 real and 16 im bits).
// the input should be width-5 to account for bit growth.
// N_2 is log base 2 of N (points in the FFT). e.g. N_2=5 for 32-point FFT.
module fft
  #(parameter width=16, N_2=5)
   (input logic                clk,
    input logic                reset,
    input logic                start,
    input logic                load,
    input logic [width-1:0]    rd, // real    read data in
    output logic [2*width-1:0] wd, // complex write data out
    output logic               done);

   logic                       enable;  // for AGU operation
   logic                       rdsel;   // read from RAM0 or RAM1
   logic                       we0_agu, we0, we1; // RAMx write enable
   logic [N_2 - 1:0]           adr0a, adr0b, adr0a_agu, adr1a, adr1b, adr1a_agu;
   logic [N_2 - 2:0]           twiddleadr; // twiddle ROM adr
   logic [2*width-1:0]         twiddle, a, b, writea, writeb, aout, bout, rd0a, rd0b, rd1a, rd1b, val_in;

   // LOAD LOGIC
   assign val_in = {rd, {width{1'b0}} }; // real input data
   assign writea = load ? val_in : aout;
   assign writeb = load ? val_in : bout;

   // AGU ENABLE LOGIC
   always_ff @(posedge clk)
     begin
	if      (start) enable <= 1;
	else if (done || reset)  enable <= 0;
     end

   // OUTPUT LOGIC
   logic [N_2-1:0] out_idx;
   assign wd    = N_2[0] ? rd1a : rd0a; // ram holding results depends on even-ness of log2(N-points)s?
   assign adr0a = done ? out_idx : adr0a_agu;
   assign adr1a = done ? out_idx : adr1a_agu;

   always_ff @(posedge clk)
     begin
	if      (reset) out_idx <= 0;
	else if (done)  out_idx <= out_idx + 1'b1;
     end

   fft_agu        #(width, N_2) agu(clk, enable, reset, load, rd, done, rdsel, we0, adr0a_agu, adr0b, we1, adr1a_agu, adr1b, twiddleadr);
   fft_twiddleROM #(width, N_2) twiddlerom(twiddleadr, twiddle);

   twoport_RAM #(width, N_2) ram0(clk, we0, adr0a, adr0b, writea, writeb, rd0a, rd0b);
   twoport_RAM #(width, N_2) ram1(clk, we1, adr1a, adr1b,   aout,   bout, rd1a, rd1b);
   assign a = rdsel ? rd1a : rd0a;
   assign b = rdsel ? rd1b : rd0b;

   fft_butterfly #(width) bgu(twiddle, a, b, aout, bout);

endmodule // fft

module fft_load
  #(parameter width=16, N_2=5)
   (input logic clk,
    input logic                reset,
    input logic                load,
    input logic [width-1:0]    rd,
    output logic [N_2-1:0]     adr0a_load,
    output logic [N_2-1:0]     adr0b_load);

   // index of input sample
   // note that this is assuming the address of `rd` (computed in the testbench) is the same as `idx`.
   // TODO: refactor so this assumptison is not made? e.g. output `idx` to address our testbench vectors?
   //       AV - I don't think this is necessary since in a real use-case where live data is being streamed
   //            into the loader, the live data won't have or require an 'idx' to address.
   
   logic [N_2-1:0]             idx;
   always_ff @(posedge clk)
     begin
	if (reset) begin
	   idx <= 0;
	end else if (load) begin
	   idx <= idx + 1'b1;
	end
     end

   bit_reverse #(N_2) reverseaddr(idx, adr0a_load);
   assign adr0b_load = adr0a_load;
   
endmodule // fft_load


// 32-point FFT address generation unit
module fft_agu
  #(parameter width=16, N_2=5)
   (input logic             clk,
    input logic             enable,
    input logic             reset,
    input logic             load,
    input logic [width-1:0] rd,
    output logic            done,
    output logic            rdsel,
    output logic            we0,
    output logic [N_2-1:0]  adr0a,
    output logic [N_2-1:0]  adr0b,
    output logic            we1,
    output logic [N_2-1:0]  adr1a,
    output logic [N_2-1:0]  adr1b,
    output logic [N_2-2:0]  twiddleadr);

   logic [N_2-1:0]         fftLevel = 0;
   logic [N_2-1:0]         flyInd = 0;

   logic [N_2-1:0]         adrA;
   logic [N_2-1:0]         adrB;

   always_ff @(posedge clk) begin
      if (reset) begin
         fftLevel <= 0;
         flyInd <= 0;
      end
      // Increment fftLevel and flyInd
      else if(enable === 1 & ~done) begin
         if(flyInd < 2**(N_2 - 1) - 1) begin
            flyInd <= flyInd + 1'd1;
         end else begin
            flyInd <= 0;
            fftLevel <= fftLevel + 1'd1;
         end
      end
   end

   // sets done when we are finished with the fft
   assign done = (fftLevel == (N_2));
   calcAddr #(width, N_2) adrCalc(fftLevel, flyInd, adrA, adrB, twiddleadr);

   logic [N_2 - 1:0]     adr0a_load, adr0b_load; // if loading, use addr from loader to load RAM0
   assign adr0a = load ? adr0a_load : adrA;
   assign adr1a =                     adrA;

   assign adr0b = load ? adr0b_load : adrB;
   assign adr1b =                     adrB;

   // flips every cycle
   assign we0 = (fftLevel[0] & enable) | load;
   assign we1 = ~fftLevel[0] & enable;

   // flips every cycle
   assign rdsel = fftLevel[0];

   // load logic: see adr0a and adr0b, and we0
   fft_load #(width, N_2) loader(clk, reset, load, rd, adr0a_load, adr0b_load);
  
endmodule // fft_agu


// todo: parameterize for more than 32-point FFT.
module calcAddr
  #(parameter width=16, N_2=5)
   (input logic  [N_2-1:0] fftLevel,
    input logic  [N_2-1:0] flyInd,
    output logic [N_2-1:0] adrA,
    output logic [N_2-1:0] adrB,
    output logic [N_2-2:0] twiddleadr);

   logic [N_2-1:0]         tempA;
   logic [N_2-1:0]         tempB;

   always_comb begin

      // implement the rotations with shifting
      tempA = flyInd << 1'd1;
      tempB = tempA  +  1'd1;
      adrA = ((tempA << fftLevel) | (tempA >> (N_2 - fftLevel)));
      adrB = ((tempB << fftLevel) | (tempB >> (N_2 - fftLevel)));

      // replication operator to create the mask that gets shifted
      twiddleadr = ({ {2**N_2-N_2-1{1'b1}}, {N_2-1{1'b0}} } >> fftLevel) & flyInd;
      
   end
endmodule // calcAddr


module fft_butterfly
  #(parameter width=16)
   (input logic [2*width-1:0] twiddle,
    input logic [2*width-1:0]  a,
    input logic [2*width-1:0]  b,
    output logic [2*width-1:0] aout,
    output logic [2*width-1:0] bout);

   logic signed [width-1:0]    a_re, a_im, aout_re, aout_im, bout_re, bout_im;
   logic signed [width-1:0]    b_re_mult, b_im_mult;
   logic [2*width-1:0]         b_mult;

   // expand to re and im components
   assign a_re = a[2*width-1:width];
   assign a_im = a[width-1:0];
   
   // perform computation
   complex_mult #(width) twiddle_mult(b, twiddle, b_mult);
   assign b_re_mult = b_mult[2*width-1:width];
   assign b_im_mult = b_mult[width-1:0];

   assign aout_re = a_re + b_re_mult;
   assign aout_im = a_im + b_im_mult;

   assign bout_re = a_re - b_re_mult;
   assign bout_im = a_im - b_im_mult;

   // pack re and im outputs
   assign aout = {aout_re, aout_im};
   assign bout = {bout_re, bout_im};
   
endmodule // fft_butterfly
