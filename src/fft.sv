// fft top level module.
// the width is the bit width (e.g. if width=16, 16 real and 16 im bits).
// N_2 is log base 2 of N (points in the FFT). e.g. N_2=5 for 32-point FFT.
// the input should be width-N_2 to account for bit growth.
module fft
  #(parameter width=16, N_2=5)
   (input logic                clk,    // clock
    input logic                reset,  // reset
    input logic                start,  // pulse once loading is complete to begin calculation.
    input logic                load,   // when high, sample #`rd_adr` is read from `rd` to mem.
    input logic [N_2 - 1:0]    rd_adr, // index of the input sample.
    input logic [2*width-1:0]  rd,     // read data in
    output logic [2*width-1:0] wd,     // complex write data out
    output logic               done);  // stays high when complete until `reset` pulsed.

   logic                       rdsel;      // read from RAM0 or RAM1
   logic                       we0, we1;   // RAMx write enable
   logic [N_2 - 1:0]           adr0a, adr0b, adr1a, adr1b;
   logic [N_2 - 2:0]           twiddleadr; // twiddle ROM adr
   logic [2*width-1:0]         twiddle, a, b, writea, writeb, aout, bout;
   logic [2*width-1:0]         rd0a, rd0b, rd1a, rd1b, val_in;

   // load logic 
   assign val_in = rd; // complex input data real in top 16 bits, imaginary in bottom 16 bits
   assign writea = load ? val_in : aout; // write ram0 with input data or BFU output
   assign writeb = load ? val_in : bout;

   // output logic
   assign wd = N_2[0] ? rd1a : rd0a;     // ram holding results depends on #fftLevels

   // ping-pong read (BFU input) logic
   assign a = rdsel ? rd1a : rd0a;
   assign b = rdsel ? rd1b : rd0b;

   // submodules
   fft_twiddleROM #(width, N_2) twiddlerom(twiddleadr, twiddle);
   fft_control    #(width, N_2) control(clk, start, reset, load, rd_adr, done, rdsel, 
                                        we0, adr0a, adr0b, we1, adr1a, adr1b, twiddleadr);

   twoport_RAM #(width, N_2) ram0(clk, we0, adr0a, adr0b, writea, writeb, rd0a, rd0b);
   twoport_RAM #(width, N_2) ram1(clk, we1, adr1a, adr1b,   aout,   bout, rd1a, rd1b);

   fft_butterfly #(width) bgu(twiddle, a, b, aout, bout);

endmodule // fft


// fft butterfly unit (BFU).
// performs the butterfly operator given two samples and a
// twiddle value.
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
