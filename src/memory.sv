// adapted from HDL example 5.7 in 
// Harris, Digital Design and Computer Architecture
module twoport_RAM
  #(parameter width=16, N_2=5)
   (input logic                clk,
    input logic                we,
    input logic [N_2-1:0]      adra,
    input logic [N_2-1:0]      adrb,
    input logic [2*width-1:0]  wda,
    input logic [2*width-1:0]  wdb,
    output logic [2*width-1:0] rda,
    output logic [2*width-1:0] rdb);

   reg [2*width-1:0]           mem [2**N_2-1:0];

   always @(posedge clk)
     if (we)
       begin
          mem[adra] <= wda;
          mem[adrb] <= wdb;
       end

   assign rda = mem[adra];
   assign rdb = mem[adrb];

endmodule // twoport_RAM
