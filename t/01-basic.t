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
}

subtest 'x value', {
	my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

	is-deeply $env.p2x( 0b100_000 ), Inf;
	is-deeply $env.p2x( 0b100_001 ), -65536;
	is-deeply $env.p2x( 0b100_010 ), -4096;
#`{
	is-deeply $env.p2x( 0b100_011 ), -1024;
	is-deeply $env.p2x( 0b100_100 ), -256;
	is-deeply $env.p2x( 0b100_101 ), -128;
	is-deeply $env.p2x( 0b100_110 ), -64;
	is-deeply $env.p2x( 0b100_111 ), -32;
	is-deeply $env.p2x( 0b101_000 ), -16;
	is-deeply $env.p2x( 0b101_001 ), -12;
	is-deeply $env.p2x( 0b101_010 ), -8;
	is-deeply $env.p2x( 0b101_011 ), -6;
	is-deeply $env.p2x( 0b101_100 ), -4;
	is-deeply $env.p2x( 0b101_101 ), -3;
	is-deeply $env.p2x( 0b101_110 ), -2;
	is-deeply $env.p2x( 0b101_111 ), -3/2;
	is-deeply $env.p2x( 0b110_000 ), -1;
	is-deeply $env.p2x( 0b110_001 ), -3/4;
	is-deeply $env.p2x( 0b110_010 ), -1/2;
	is-deeply $env.p2x( 0b110_011 ), -3/8;
	is-deeply $env.p2x( 0b110_100 ), -1/4;
	is-deeply $env.p2x( 0b110_101 ), -3/16;
	is-deeply $env.p2x( 0b110_110 ), -1/8;
	is-deeply $env.p2x( 0b110_111 ), -3/32;
	is-deeply $env.p2x( 0b111_000 ), -1/16;
	is-deeply $env.p2x( 0b111_001 ), -1/32;
	is-deeply $env.p2x( 0b111_010 ), -1/64;
	is-deeply $env.p2x( 0b111_011 ), -1/128;
	is-deeply $env.p2x( 0b111_100 ), -1/256;
	is-deeply $env.p2x( 0b111_101 ), -1/1024;
}
	is-deeply $env.p2x( 0b111_110 ), -1/4096;
	is-deeply $env.p2x( 0b111_111 ), -1/65536;

	is-deeply $env.p2x( 0b000_000 ), 0;
	is-deeply $env.p2x( 0b000_001 ), 1/65536;
	is-deeply $env.p2x( 0b000_010 ), 1/4096;
#`{
	is-deeply $env.p2x( 0b000_011 ), 1/1024;
	is-deeply $env.p2x( 0b000_100 ), 1/256;
	is-deeply $env.p2x( 0b000_101 ), 1/128;
	is-deeply $env.p2x( 0b000_110 ), 1/64;
	is-deeply $env.p2x( 0b000_111 ), 1/32;
	is-deeply $env.p2x( 0b001_000 ), 1/16;
	is-deeply $env.p2x( 0b001_001 ), 3/32;
	is-deeply $env.p2x( 0b001_010 ), 1/8;
	is-deeply $env.p2x( 0b001_011 ), 3/16;
	is-deeply $env.p2x( 0b001_100 ), 1/4;
	is-deeply $env.p2x( 0b001_101 ), 3/8;
	is-deeply $env.p2x( 0b001_110 ), 1/2;
	is-deeply $env.p2x( 0b001_111 ), 3/4;
	is-deeply $env.p2x( 0b010_000 ), 1;
	is-deeply $env.p2x( 0b010_001 ), 3/2;
	is-deeply $env.p2x( 0b010_010 ), 2;
	is-deeply $env.p2x( 0b010_011 ), 3;
	is-deeply $env.p2x( 0b010_100 ), 4;
	is-deeply $env.p2x( 0b010_101 ), 6;
	is-deeply $env.p2x( 0b010_110 ), 8;
	is-deeply $env.p2x( 0b010_111 ), 12;
	is-deeply $env.p2x( 0b011_000 ), 16;
	is-deeply $env.p2x( 0b011_001 ), 32;
	is-deeply $env.p2x( 0b011_010 ), 64;
	is-deeply $env.p2x( 0b011_011 ), 128;
	is-deeply $env.p2x( 0b011_100 ), 256;
	is-deeply $env.p2x( 0b011_101 ), 1024;
}
	is-deeply $env.p2x( 0b011_110 ), 4096;
	is-deeply $env.p2x( 0b011_111 ), 65536;
};
die "#### replace me\n";

subtest 'display value', {
	my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

	is-deeply $env.for-display( 0b100_000 ), '-00000';
	is-deeply $env.for-display( 0b100_001 ), '-11111';
	is-deeply $env.for-display( 0b100_010 ), '-11110';
	is-deeply $env.for-display( 0b100_011 ), '-11101';
	is-deeply $env.for-display( 0b100_100 ), '-11100';
	is-deeply $env.for-display( 0b100_101 ), '-11011';
	is-deeply $env.for-display( 0b100_110 ), '-11010';
	is-deeply $env.for-display( 0b100_111 ), '-11001';
	is-deeply $env.for-display( 0b101_000 ), '-11000';
	is-deeply $env.for-display( 0b101_001 ), '-10111';
	is-deeply $env.for-display( 0b101_010 ), '-10110';
	is-deeply $env.for-display( 0b101_011 ), '-10101';
	is-deeply $env.for-display( 0b101_100 ), '-10100';
	is-deeply $env.for-display( 0b101_101 ), '-10011';
	is-deeply $env.for-display( 0b101_110 ), '-10010';
	is-deeply $env.for-display( 0b101_111 ), '-10001';
	is-deeply $env.for-display( 0b110_000 ), '-10000';
	is-deeply $env.for-display( 0b110_001 ), '-01111';
	is-deeply $env.for-display( 0b110_010 ), '-01110';
	is-deeply $env.for-display( 0b110_011 ), '-01101';
	is-deeply $env.for-display( 0b110_100 ), '-01100';
	is-deeply $env.for-display( 0b110_101 ), '-01011';
	is-deeply $env.for-display( 0b110_110 ), '-01010';
	is-deeply $env.for-display( 0b110_111 ), '-01001';
	is-deeply $env.for-display( 0b111_000 ), '-01000';
	is-deeply $env.for-display( 0b111_001 ), '-00111';
	is-deeply $env.for-display( 0b111_010 ), '-00110';
	is-deeply $env.for-display( 0b111_011 ), '-00101';
	is-deeply $env.for-display( 0b111_100 ), '-00100';
	is-deeply $env.for-display( 0b111_101 ), '-00011';
	is-deeply $env.for-display( 0b111_110 ), '-00010';
	is-deeply $env.for-display( 0b111_111 ), '-00001';

	is-deeply $env.for-display( 0b000_000 ), '+00000';
	is-deeply $env.for-display( 0b000_001 ), '+00001';
	is-deeply $env.for-display( 0b000_010 ), '+00010';
	is-deeply $env.for-display( 0b000_011 ), '+00011';
	is-deeply $env.for-display( 0b000_100 ), '+00100';
	is-deeply $env.for-display( 0b000_101 ), '+00101';
	is-deeply $env.for-display( 0b000_110 ), '+00110';
	is-deeply $env.for-display( 0b000_111 ), '+00111';
	is-deeply $env.for-display( 0b001_000 ), '+01000';
	is-deeply $env.for-display( 0b001_001 ), '+01001';
	is-deeply $env.for-display( 0b001_010 ), '+01010';
	is-deeply $env.for-display( 0b001_011 ), '+01011';
	is-deeply $env.for-display( 0b001_100 ), '+01100';
	is-deeply $env.for-display( 0b001_101 ), '+01101';
	is-deeply $env.for-display( 0b001_110 ), '+01110';
	is-deeply $env.for-display( 0b001_111 ), '+01111';
	is-deeply $env.for-display( 0b010_000 ), '+10000';
	is-deeply $env.for-display( 0b010_001 ), '+10001';
	is-deeply $env.for-display( 0b010_010 ), '+10010';
	is-deeply $env.for-display( 0b010_011 ), '+10011';
	is-deeply $env.for-display( 0b010_100 ), '+10100';
	is-deeply $env.for-display( 0b010_101 ), '+10101';
	is-deeply $env.for-display( 0b010_110 ), '+10110';
	is-deeply $env.for-display( 0b010_111 ), '+10111';
	is-deeply $env.for-display( 0b011_000 ), '+11000';
	is-deeply $env.for-display( 0b011_001 ), '+11001';
	is-deeply $env.for-display( 0b011_010 ), '+11010';
	is-deeply $env.for-display( 0b011_011 ), '+11011';
	is-deeply $env.for-display( 0b011_100 ), '+11100';
	is-deeply $env.for-display( 0b011_101 ), '+11101';
	is-deeply $env.for-display( 0b011_110 ), '+11110';
	is-deeply $env.for-display( 0b011_111 ), '+11111';
};

done-testing;
