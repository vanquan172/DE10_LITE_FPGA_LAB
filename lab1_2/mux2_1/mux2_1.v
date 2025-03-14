module mux2_1 

( 
	input [3:0] a,b,
	input sel,
	output [3:0] out
);

assign out = (~sel & a) | (sel & b);

endmodule 