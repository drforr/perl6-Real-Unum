use v6.c;
use Test;
use Real::Unum;

my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

# Values from the original PDF...
#
subtest 'environment', {
  my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 1 ) );

  is $env.nbits,  6;
  is $env.es,     1;
  is $env.npat,   64;
  is $env.useed,  4;
  is $env.minpos, 1/256;
  is $env.maxpos, 256;
  is $env.qsize,  64;
  is $env.qextra, 32;
};

# Called positQ in the doc.
#
subtest 'is-valid-posit', {
  ok $env.is-valid-posit( 0 );
  ok $env.is-valid-posit( 1 );
  ok $env.is-valid-posit( 63 );
  ok $env.is-valid-posit( 64 );
  ok !$env.is-valid-posit( 65 );
}

# Sign is always the first bit.
#
subtest 'sign', {
	is $env.parts( 0b0_00001 )<sign>, 0;
	is $env.parts( 0b1_00000 )<sign>, 1;
	is $env.parts( 0b1_00001 )<sign>, 1;
};

# XXX There's a worrying break there...
# XXX
subtest 'regime', {
	is $env.parts( 0b000000  )<regime>, '00000';
	is $env.parts( 0b00000_1 )<regime>, '0000';
	is $env.parts( 0b0000_11 )<regime>, '000';
	is $env.parts( 0b000_101 )<regime>, '00';
	is $env.parts( 0b00_1001 )<regime>, '0';
	is $env.parts( 0b111111  )<regime>, '0000';
	is $env.parts( 0b11111_0 )<regime>, '000';
	is $env.parts( 0b1111_01 )<regime>, '000';
	is $env.parts( 0b111_001 )<regime>, '00';
	is $env.parts( 0b11_0001 )<regime>, '0';
};

subtest 'exponent', {
	is $env.parts( 0b001_10_1 )<exponent>, '10';
	is $env.parts( 0b0001_10 )<exponent>, '10';
	is $env.parts( 0b00001_1 )<exponent>, '1';
};

subtest 'fraction', {
	is $env.parts( 0b00110_1 )<fraction>, '1';
	is $env.parts( 0b00110_0 )<fraction>, '0';
};

subtest 'env(3,1)', {
	subtest 'p2x env(3,1)', {
		my $env = Real::Unum::Environment.new( :nbits( 3 ), :es( 1 ) );

		is $env.p2x( 0b000 ), 0,    '000';
		is $env.p2x( 0b001 ), 1/4,  '001';
		is $env.p2x( 0b010 ), 1,    '010';
		is $env.p2x( 0b011 ), 4,    '011';
		is $env.p2x( 0b100 ), Inf,  '100';
		is $env.p2x( 0b101 ), -4,   '101';
		is $env.p2x( 0b110 ), -1,   '110';
		is $env.p2x( 0b111 ), -1/4, '111';
	};

	subtest 'x2p env(3,1)', {
		my $env = Real::Unum::Environment.new( :nbits( 3 ), :es( 1 ) );

		is $env.x2p( 0    ), 0b000, '0';
		is $env.x2p( 1/4  ), 0b001, '1/4';
		is $env.x2p( 1    ), 0b010, '1';
		is $env.x2p( 4    ), 0b011, '4';
		is $env.x2p( Inf  ), 0b100, 'Inf';
		is $env.x2p( -4   ), 0b101, '-4';
		is $env.x2p( -1   ), 0b110, '-1';
		is $env.x2p( -1/4 ), 0b111, '-1/4';
	};
};

subtest 'env(4,1)', {
	# Note that env(3,1) is still there, just shifted up one.
	#
	subtest 'p2x', {
		my $env = Real::Unum::Environment.new( :nbits( 4 ), :es( 1 ) );

		is $env.p2x( 0b0000 ), 0;
		is $env.p2x( 0b0001 ), 1/16;
		is $env.p2x( 0b0010 ), 1/4;
		is $env.p2x( 0b0011 ), 1/2;
		is $env.p2x( 0b0100 ), 1;
		is $env.p2x( 0b0101 ), 2;
		is $env.p2x( 0b0110 ), 4;
		is $env.p2x( 0b0111 ), 16;
		is $env.p2x( 0b1000 ), Inf;
		is $env.p2x( 0b1001 ), -16;
		is $env.p2x( 0b1010 ), -4;
		is $env.p2x( 0b1011 ), -2;
		is $env.p2x( 0b1100 ), -1;
		is $env.p2x( 0b1101 ), -1/2;
		is $env.p2x( 0b1110 ), -1/4;
		is $env.p2x( 0b1111 ), -1/16;
	};

	subtest 'x2p', {
		my $env = Real::Unum::Environment.new( :nbits( 4 ), :es( 1 ) );

		is $env.x2p( 0    ), 0b0000;
		is $env.x2p( 1/16 ), 0b0001;
		is $env.x2p( 1/4  ), 0b0010;
		is $env.x2p( 1/2  ), 0b0011;
		is $env.x2p( 1    ), 0b0100;
		is $env.x2p( 2    ), 0b0101;
		is $env.x2p( 4    ), 0b0110;
		is $env.x2p( 16   ), 0b0111;
		is $env.x2p( Inf  ), 0b1000;
		is $env.x2p( -16  ), 0b1001;
		is $env.x2p( -4   ), 0b1010;
		is $env.x2p( -2   ), 0b1011;
		is $env.x2p( -1   ), 0b1100;
		is $env.x2p( -1/2 ), 0b1101;
		is $env.x2p( -1/4 ), 0b1110;
		is $env.x2p( -1/16), 0b1111;
	};
};

subtest 'env(5,1)', {
	subtest 'p2x env(5,1)', {
		my $env = Real::Unum::Environment.new( :nbits( 5 ), :es( 1 ) );

		is $env.p2x( 0b00000 ), 0;
		is $env.p2x( 0b00001 ), 1/64;
		is $env.p2x( 0b00010 ), 1/16;
		is $env.p2x( 0b00011 ), 1/8;
		is $env.p2x( 0b00100 ), 1/4;
		is $env.p2x( 0b00101 ), 3/8;
		is $env.p2x( 0b00110 ), 1/2;
		is $env.p2x( 0b00111 ), 3/4;
		is $env.p2x( 0b01000 ), 1;
		is $env.p2x( 0b01001 ), 3/2;
		is $env.p2x( 0b01010 ), 2;
		is $env.p2x( 0b01011 ), 3;
		is $env.p2x( 0b01100 ), 4;
		is $env.p2x( 0b01101 ), 8;
		is $env.p2x( 0b01110 ), 16;
		is $env.p2x( 0b01111 ), 64;
		is $env.p2x( 0b10000 ), Inf;
		is $env.p2x( 0b10001 ), -64;
		is $env.p2x( 0b10010 ), -16;
		is $env.p2x( 0b10011 ), -8;
		is $env.p2x( 0b10100 ), -4;
		is $env.p2x( 0b10101 ), -3;
		is $env.p2x( 0b10110 ), -2;
		is $env.p2x( 0b10111 ), -3/2;
		is $env.p2x( 0b11000 ), -1;
		is $env.p2x( 0b11001 ), -3/4;
		is $env.p2x( 0b11010 ), -1/2;
		is $env.p2x( 0b11011 ), -3/8;
		is $env.p2x( 0b11100 ), -1/4;
		is $env.p2x( 0b11101 ), -1/8;
		is $env.p2x( 0b11110 ), -1/16;
		is $env.p2x( 0b11111 ), -1/64;
	};

	subtest 'x2p env(5,1)', {
		my $env = Real::Unum::Environment.new( :nbits( 5 ), :es( 1 ) );

		is $env.x2p(  0     ), 0b00000;
		is $env.x2p(  1/64  ), 0b00001;
		is $env.x2p(  1/16  ), 0b00010;
		is $env.x2p(  1/8   ), 0b00011;
		is $env.x2p(  1/4   ), 0b00100;
		is $env.x2p(  3/8   ), 0b00101;
		is $env.x2p(  1/2   ), 0b00110;
		is $env.x2p(  3/4   ), 0b00111;
		is $env.x2p(  1     ), 0b01000;
		is $env.x2p(  3/2   ), 0b01001;
		is $env.x2p(  2     ), 0b01010;
		is $env.x2p(  3     ), 0b01011;
		is $env.x2p(  4     ), 0b01100;
		is $env.x2p(  8     ), 0b01101;
		is $env.x2p(  16    ), 0b01110;
		is $env.x2p(  64    ), 0b01111;
		is $env.x2p(  Inf   ), 0b10000;
		is $env.x2p(  -64   ), 0b10001;
		is $env.x2p(  -16   ), 0b10010;
		is $env.x2p(  -8    ), 0b10011;
		is $env.x2p(  -4    ), 0b10100;
		is $env.x2p(  -3    ), 0b10101;
		is $env.x2p(  -2    ), 0b10110;
		is $env.x2p(  -3/2  ), 0b10111;
		is $env.x2p(  -1    ), 0b11000;
		is $env.x2p(  -3/4  ), 0b11001;
		is $env.x2p(  -1/2  ), 0b11010;
		is $env.x2p(  -3/8  ), 0b11011;
		is $env.x2p(  -1/4  ), 0b11100;
		is $env.x2p(  -1/8  ), 0b11101;
		is $env.x2p(  -1/16 ), 0b11110;
		is $env.x2p(  -1/64 ), 0b11111;
	};
};

subtest 'p2x', {

	subtest 'p2x env(6,2)', {
		my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

		is     $env.p2x( 0b100_000 ), Inf;
		is     $env.p2x( 0b100_001 ), -65536;
		is     $env.p2x( 0b100_010 ), -4096;
		is     $env.p2x( 0b100_011 ), -1024;
		is     $env.p2x( 0b100_100 ), -256;
		is     $env.p2x( 0b100_101 ), -128;
		is     $env.p2x( 0b100_110 ), -64;
		is     $env.p2x( 0b100_111 ), -32;
		is     $env.p2x( 0b101_000 ), -16;
		is Int($env.p2x( 0b101_001 )), -12;
		is     $env.p2x( 0b101_010 ), -8;
		is Int($env.p2x( 0b101_011 )), -6;
		is     $env.p2x( 0b101_100 ), -4;
		is Int($env.p2x( 0b101_101 )), -3;
		is     $env.p2x( 0b101_110 ), -2;
		is     $env.p2x( 0b101_111 ), -3/2;
		is     $env.p2x( 0b110_000 ), -1;
		is     $env.p2x( 0b110_001 ), -3/4;
		is     $env.p2x( 0b110_010 ), -1/2;
		is     $env.p2x( 0b110_011 ), -3/8;
		is     $env.p2x( 0b110_100 ), -1/4;
		is     $env.p2x( 0b110_101 ), -3/16;
		is     $env.p2x( 0b110_110 ), -1/8;
		is     $env.p2x( 0b110_111 ), -3/32;
		is     $env.p2x( 0b111_000 ), -1/16;
		is     $env.p2x( 0b111_001 ), -1/32;
		is     $env.p2x( 0b111_010 ), -1/64;
		is     $env.p2x( 0b111_011 ), -1/128;
		is     $env.p2x( 0b111_100 ), -1/256;
		is     $env.p2x( 0b111_101 ), -1/1024;
		is     $env.p2x( 0b111_110 ), -1/4096;
		is     $env.p2x( 0b111_111 ), -1/65536;

		is     $env.p2x( 0b000_000 ), 0;
		is     $env.p2x( 0b000_001 ), 1/65536;
		is     $env.p2x( 0b000_010 ), 1/4096;
		is     $env.p2x( 0b000_011 ), 1/1024;
		is     $env.p2x( 0b000_100 ), 1/256;
		is     $env.p2x( 0b000_101 ), 1/128;
		is     $env.p2x( 0b000_110 ), 1/64;
		is     $env.p2x( 0b000_111 ), 1/32;
		is     $env.p2x( 0b001_000 ), 1/16;
		is     $env.p2x( 0b001_001 ), 3/32;
		is     $env.p2x( 0b001_010 ), 1/8;
		is     $env.p2x( 0b001_011 ), 3/16;
		is     $env.p2x( 0b001_100 ), 1/4;
		is     $env.p2x( 0b001_101 ), 3/8;
		is     $env.p2x( 0b001_110 ), 1/2;
		is     $env.p2x( 0b001_111 ), 3/4;
		is     $env.p2x( 0b010_000 ), 1;
		is     $env.p2x( 0b010_001 ), 3/2;
		is     $env.p2x( 0b010_010 ), 2;
		is Int($env.p2x( 0b010_011 )), 3;
		is     $env.p2x( 0b010_100 ), 4;
		is Int($env.p2x( 0b010_101 )), 6;
		is     $env.p2x( 0b010_110 ), 8;
		is Int($env.p2x( 0b010_111 )), 12;
		is     $env.p2x( 0b011_000 ), 16;
		is     $env.p2x( 0b011_001 ), 32;
		is     $env.p2x( 0b011_010 ), 64;
		is     $env.p2x( 0b011_011 ), 128;
		is     $env.p2x( 0b011_100 ), 256;
		is     $env.p2x( 0b011_101 ), 1024;
		is     $env.p2x( 0b011_110 ), 4096;
		is     $env.p2x( 0b011_111 ), 65536;
	};
};

subtest 'x2p(x) (6,2)', {
	my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

	is $env.x2p( Inf      ), 0b100_000;
	is $env.x2p( -65536   ), 0b100_001;
	is $env.x2p( -4096    ), 0b100_010;
	is $env.x2p( -1024    ), 0b100_011;
	is $env.x2p( -256     ), 0b100_100;
	is $env.x2p( -128     ), 0b100_101;
	is $env.x2p( -64      ), 0b100_110;
	is $env.x2p( -32      ), 0b100_111;
	is $env.x2p( -16      ), 0b101_000;
	is $env.x2p( -12      ), 0b101_001;
	is $env.x2p( -8       ), 0b101_010;
	is $env.x2p( -6       ), 0b101_011;
	is $env.x2p( -4       ), 0b101_100;
	is $env.x2p( -3       ), 0b101_101;
	is $env.x2p( -2       ), 0b101_110;
	is $env.x2p( -3/2     ), 0b101_111;
	is $env.x2p( -1       ), 0b110_000;
	is $env.x2p( -3/4     ), 0b110_001;
	is $env.x2p( -1/2     ), 0b110_010;
	is $env.x2p( -3/8     ), 0b110_011;
	is $env.x2p( -1/4     ), 0b110_100;
	is $env.x2p( -3/16    ), 0b110_101;
	is $env.x2p( -1/8     ), 0b110_110;
	is $env.x2p( -3/32    ), 0b110_111;
	is $env.x2p( -1/16    ), 0b111_000;
	is $env.x2p( -1/32    ), 0b111_001;
	is $env.x2p( -1/64    ), 0b111_010;
	is $env.x2p( -1/128   ), 0b111_011;
	is $env.x2p( -1/256   ), 0b111_100;
	is $env.x2p( -1/1024  ), 0b111_101;
	is $env.x2p( -1/4096  ), 0b111_110;
	is $env.x2p( -1/65536 ), 0b111_111;

	is $env.x2p( 0       ), 0b000_000;
	is $env.x2p( 1/65536 ), 0b000_001;
	is $env.x2p( 1/4096  ), 0b000_010;
	is $env.x2p( 1/1024  ), 0b000_011;
	is $env.x2p( 1/256   ), 0b000_100;
	is $env.x2p( 1/128   ), 0b000_101;
	is $env.x2p( 1/64    ), 0b000_110;
	is $env.x2p( 1/32    ), 0b000_111;
	is $env.x2p( 1/16    ), 0b001_000;
	is $env.x2p( 3/32    ), 0b001_001;
	is $env.x2p( 1/8     ), 0b001_010;
	is $env.x2p( 3/16    ), 0b001_011;
	is $env.x2p( 1/4     ), 0b001_100;
	is $env.x2p( 3/8     ), 0b001_101;
	is $env.x2p( 1/2     ), 0b001_110;
	is $env.x2p( 3/4     ), 0b001_111;
	is $env.x2p( 1       ), 0b010_000;
	is $env.x2p( 3/2     ), 0b010_001;
	is $env.x2p( 2       ), 0b010_010;
	is $env.x2p( 3       ), 0b010_011;
	is $env.x2p( 4       ), 0b010_100;
	is $env.x2p( 6       ), 0b010_101;
	is $env.x2p( 8       ), 0b010_110;
	is $env.x2p( 12      ), 0b010_111;
	is $env.x2p( 16      ), 0b011_000;
	is $env.x2p( 32      ), 0b011_001;
	is $env.x2p( 64      ), 0b011_010;
	is $env.x2p( 128     ), 0b011_011;
	is $env.x2p( 256     ), 0b011_100;
	is $env.x2p( 1024    ), 0b011_101;
	is $env.x2p( 4096    ), 0b011_110;
	is $env.x2p( 65536   ), 0b011_111;
};

subtest 'display value', {
	my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

	is $env.for-display( 0b100_000 ), '-00000';
	is $env.for-display( 0b100_001 ), '-11111';
	is $env.for-display( 0b100_010 ), '-11110';
	is $env.for-display( 0b100_011 ), '-11101';
	is $env.for-display( 0b100_100 ), '-11100';
	is $env.for-display( 0b100_101 ), '-11011';
	is $env.for-display( 0b100_110 ), '-11010';
	is $env.for-display( 0b100_111 ), '-11001';
	is $env.for-display( 0b101_000 ), '-11000';
	is $env.for-display( 0b101_001 ), '-10111';
	is $env.for-display( 0b101_010 ), '-10110';
	is $env.for-display( 0b101_011 ), '-10101';
	is $env.for-display( 0b101_100 ), '-10100';
	is $env.for-display( 0b101_101 ), '-10011';
	is $env.for-display( 0b101_110 ), '-10010';
	is $env.for-display( 0b101_111 ), '-10001';
	is $env.for-display( 0b110_000 ), '-10000';
	is $env.for-display( 0b110_001 ), '-01111';
	is $env.for-display( 0b110_010 ), '-01110';
	is $env.for-display( 0b110_011 ), '-01101';
	is $env.for-display( 0b110_100 ), '-01100';
	is $env.for-display( 0b110_101 ), '-01011';
	is $env.for-display( 0b110_110 ), '-01010';
	is $env.for-display( 0b110_111 ), '-01001';
	is $env.for-display( 0b111_000 ), '-01000';
	is $env.for-display( 0b111_001 ), '-00111';
	is $env.for-display( 0b111_010 ), '-00110';
	is $env.for-display( 0b111_011 ), '-00101';
	is $env.for-display( 0b111_100 ), '-00100';
	is $env.for-display( 0b111_101 ), '-00011';
	is $env.for-display( 0b111_110 ), '-00010';
	is $env.for-display( 0b111_111 ), '-00001';

	is $env.for-display( 0b000_000 ), '+00000';
	is $env.for-display( 0b000_001 ), '+00001';
	is $env.for-display( 0b000_010 ), '+00010';
	is $env.for-display( 0b000_011 ), '+00011';
	is $env.for-display( 0b000_100 ), '+00100';
	is $env.for-display( 0b000_101 ), '+00101';
	is $env.for-display( 0b000_110 ), '+00110';
	is $env.for-display( 0b000_111 ), '+00111';
	is $env.for-display( 0b001_000 ), '+01000';
	is $env.for-display( 0b001_001 ), '+01001';
	is $env.for-display( 0b001_010 ), '+01010';
	is $env.for-display( 0b001_011 ), '+01011';
	is $env.for-display( 0b001_100 ), '+01100';
	is $env.for-display( 0b001_101 ), '+01101';
	is $env.for-display( 0b001_110 ), '+01110';
	is $env.for-display( 0b001_111 ), '+01111';
	is $env.for-display( 0b010_000 ), '+10000';
	is $env.for-display( 0b010_001 ), '+10001';
	is $env.for-display( 0b010_010 ), '+10010';
	is $env.for-display( 0b010_011 ), '+10011';
	is $env.for-display( 0b010_100 ), '+10100';
	is $env.for-display( 0b010_101 ), '+10101';
	is $env.for-display( 0b010_110 ), '+10110';
	is $env.for-display( 0b010_111 ), '+10111';
	is $env.for-display( 0b011_000 ), '+11000';
	is $env.for-display( 0b011_001 ), '+11001';
	is $env.for-display( 0b011_010 ), '+11010';
	is $env.for-display( 0b011_011 ), '+11011';
	is $env.for-display( 0b011_100 ), '+11100';
	is $env.for-display( 0b011_101 ), '+11101';
	is $env.for-display( 0b011_110 ), '+11110';
	is $env.for-display( 0b011_111 ), '+11111';
};

done-testing;
