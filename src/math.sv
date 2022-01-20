// explicit so that we control
// the truncation of the output.
module mult
  #(parameter width=16)
   (input logic signed [width-1:0]  a,
    input logic signed [width-1:0]  b,
    output logic signed [width-1:0] out);

   logic [2*width-1:0]              untruncated_out;

   assign untruncated_out = a * b;
   assign out = untruncated_out[30:15] + untruncated_out[14];
   // see slade paper. this works as long as we're not
   // multiplying two maximum mag. negative numbers.

endmodule // mult


module complex_mult
  #(parameter width=16)
   (input logic [2*width-1:0]  a,
    input logic [2*width-1:0]  b,
    output logic [2*width-1:0] out);

   logic signed [width-1:0]    a_re, a_im, b_re, b_im, out_re, out_im;
   assign a_re = a[31:16]; assign a_im = a[15:0];
   assign b_re = b[31:16]; assign b_im = b[15:0];

   logic signed [width-1:0]    a_re_be_re, a_im_b_im, a_re_b_im, a_im_b_re;
   mult #(width) m1 (a_re, b_re, a_re_be_re);
   mult #(width) m2 (a_im, b_im, a_im_b_im);
   mult #(width) m3 (a_re, b_im, a_re_b_im);
   mult #(width) m4 (a_im, b_re, a_im_b_re);

   assign out_re = (a_re_be_re) - (a_im_b_im);
   assign out_im = (a_re_b_im) + (a_im_b_re);
   assign out = {out_re, out_im};
endmodule // complex_mult


module bit_reverse
  #(parameter N_2=5)
   (input logic [N_2-1:0] in,
    output logic [N_2-1:0] out);

   genvar                  i;
   generate
      for(i=0; i<N_2; i=i+1) begin : BIT_REVERSE
	 assign out[i] = in[N_2-i-1];
      end
   endgenerate

endmodule // bit_reverse
