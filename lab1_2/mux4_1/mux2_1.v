module mux2_1
(
	input a,b,s,
	outout y

);

assign y = (~s & a) | (s & b) ; 

endmodule 