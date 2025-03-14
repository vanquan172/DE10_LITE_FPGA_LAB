module mux2_1
(
	input a,b,s,
	output y

);

assign y = (~s & a) | (s & b) ; 

endmodule 

module mux4_1 

(
	input [3:0] a,b,
	input s, 
	output [3:0] y
);

mux2_1 ins1 (a[0],b[0],s,y[0]);
mux2_1 ins2(a[1],b[1],s,y[1]);
mux2_1 ins3 (a[2],b[2],s,y[2]);
mux2_1 ins4 (a[3],b[3],s,y[3]);

endmodule 