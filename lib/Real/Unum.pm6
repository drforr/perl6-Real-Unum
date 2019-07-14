use v6;

# nbits and es are set at object creation time.
#
# This is effectively a factory for creating Posit-based integers.
#
# It also only creates Posits of one width.
# Other posit sizes will be available later on.
#
# Yes, the spec does state how to create any size of posit, but the author
# works with a single size of posit at any given time.
#
# Plus it makes it easier to deal with the odd sizes of posit created in
# the "test" sections of the document.
#
class Real::Unum::Environment {
	my subset Bit of Int where -1 < * < 2;
	#
	# nbits is the total size of the Posit.
	# es is the number of exponent bits.
	#
	has $.nbits is required where * >= 2;
	has $.es    is required where * >= 0;

	has $.npat   = 2**$!nbits;
	has $.useed  = 2**(2**$!es);
	has $.minpos = $!useed**(-$!nbits + 2);
	has $.maxpos = $!useed**($!nbits - 2);
	has $.qsize  = 2**ceiling( log( ($!nbits-2)*(2**($!es+2))+5 , 2 ) );
	has $.qextra = $!qsize - ($!nbits-2)*2**($!es+2);

#`{

	In principle, the Mathematica description of the way Posit internals
	work is wonderful. In practice, it's simpler to do good old-fashioned
	string manipulation.

	Internally a posit is broken up like this (for a 6-bit integer):

	[0] [11111] # Sign bit and 5 regime bits
	[0] [11110] # Sign bit and 4 regime bits
	[0] [111] [0] [0] # Sign bit, 3 regime bits, pad, and 1 exponent bit


	The MSB of a Posit is its sign bit.
	The regime bits of a Posit are all of the bits that are the same value
	after the sign bit.

	* The document originally seems to state that it's the number of bits
	  after the sign that have the opposite value to the sign bit, but
	  when you get to page 15 this is clearly untrue, as '000000' has a
	  zero sign bit, and the regime bits are all 0s.
}

	method twoscomp( Int $sign, Int $p ) {
		( $sign > 0 ?? $p !! $.npat - $p ) mod $.npat;
	}

	# Return $p as a (maybe left-padded) array of bits
	method padded-array( Int $p ) {
		my Str $base-two = $p.base(2);
		my Str $padding = '0' x ( $.nbits - $base-two.chars );
		$base-two = $padding ~ $base-two;

		map { +$_ }, $base-two.split( '', :skip-empty );
	}

	# Break the posit into its component parts. There will always be
	# a sign and regime bit, the other parts may not exist.
	#
	method parts( Int $p ) {
		my %parts;
		my @binary = self.padded-array( $p );
		%parts<sign> = @binary.shift;

		%parts<regime> = ~@binary.shift;
		my $regime-bit = %parts<regime>;
		%parts<regime> ~= ~@binary.shift while
			@binary and @binary[0] == $regime-bit;

		# Get rid of pad bit between regime and exponent if it exists
		#
		@binary.shift if @binary;
		if @binary {
			for ^$.es {
				last unless @binary;
				%parts<exponent> ~= ~@binary.shift;
			}
			if @binary {
				%parts<fraction> = ~@binary.shift while @binary;
			}
		}

		%parts;
	}

	method p2x( Int $p ) {
	}

	method for-display( Int $p ) returns Str {
		my %parts = self.parts( $p );
		my $binary = %parts<sign> == 0 ?? '+' !! '-';
		$binary ~= %parts<regime> if %parts<regime>;
		if $binary.chars < $.nbits and %parts<regime> {
			%parts<regime> ~~ m{ ^ (.) };
			my $regime-number = +$0;
			$binary ~= ~( 1-$regime-number );
		}
		$binary ~= %parts<exponent> if %parts<exponent>;
		$binary ~= %parts<fraction> if %parts<fraction>;
		$binary;
	}


#`{

	method positQ( Int $p ) returns Bool {
		0 <= $p <= $.npat;
	}

	method _IntegerDigits( Int $p, Int $base where * >= 2 = 10, Int $maxlen? where * > 0 ) {
		my $p-base = $p.base($base);
		die "Out of range" if $maxlen and $p-base.chars > $maxlen;

		if $p-base.chars < $maxlen {
			$p-base = ('0' x ( $maxlen - $p-base.chars )) ~ $p-base;
		}
		return map { +$_ }, $p-base.split('', :skip-empty);
	}

	method twoscomp( Int $sign, Int $p ) {
		( $sign > 0 ?? $p !! $.npat - $p ) mod $.npat;
	}

	my subset Bit of Int where -1 < * < 2;

	method signbit( Int $p ) returns Bit {
		die "should be an exception" unless self.positQ( $p );
		my @digits = self._IntegerDigits( $p, 2, $.nbits );
		@digits[0];
	}

	# Don't bother with the Mathematica interpretation.
	#
	# Save the MSB

	method regimebits( $p ) {
		die "should be an exception" unless self.positQ( $p );
		my $q = self.twoscomp( 1 - self.signbit( $p ), $p );
		my @bits = self._IntegerDigits( $q, 2, $.nbits );
		@bits.shift;
		my $msb = @bits[0];
		@bits.append( 1-$msb );
		my @regimebits;

		@regimebits.append( $msb ) while @bits.shift == $msb;
		@regimebits;
	}

	method regimevalue( @bits ) {
		@bits[0] == 1 ?? @bits.elems - 1 !! -@bits.elems;
	}

	method exponentbits( Int $p ) {
		die "should be an exception" unless self.positQ( $p );
		my $q = self.twoscomp( 1 - self.signbit( $p ), $p );
		my $startbit = self.regimebits( $q ).elems + 3;
		my @bits = self._IntegerDigits( $q, 2, $.nbits );
		if $startbit > $.nbits {
			return ( );
		}
		else {
			return @bits.splice( $startbit,
			              min( $startbit + $.es - 1, $.nbits ) );
		}
	}

	method fractionbits( Int $p ) {
		die "should be an exception" unless self.positQ( $p );
		my $q = self.twoscomp( 1 - self.signbit( $p ), $p );
		my $startbit = self.regimebits( $q ).elems + 3 + $.es;
		my @bits = self._IntegerDigits( $q, 2, $.nbits );
		if $startbit > $.nbits {
			return ( );
		}
		else {
			return @bits.splice( $startbit, $.nbits );
		}
	}

	method p2x( Int $p ) {
		my $s = (-1)**self.signbit( $p );
		my $k = self.regimevalue( self.regimebits( $p ) );
		my @e = self.exponentbits( $p );
		my @f = self.fractionbits( $p );
		$e = $e ~ ( 0 xx ( $.es - $e.chars ) );
		$e = :2( $e );
		$f = @f.elems == 0 ? 1 : 1 + :2( $f ) * 2**( -( @f.elems ) ); 
		given $p {
			when 0 {
				0
			}
			when $.npat / 2 {
				Inf
			}
			default {
				$s * $.useed**$k * 2**$e * $f
			}
		}
	}

	method display( Int $p ) {
		die "should be an exception" unless self.positQ( $p );
		my $sign = self.signbit( $p );
		my @regimebits = self.regimebits( $p );
		my @exponentbits = self.exponentbits( $p );
		my @fractionbits = self.fractionbits( $p );

		return "$sign|{@regimebits}|{@exponentbits}|{@fractionbits}";
	}
}
}

=begin pod

=head1 NAME

Real::Unum - Posit implementation in Perl 6 from https://posithub.org/docs/Posits4.pdf

=head1 SYNOPSIS

=begin code :lang<perl6>

use Real::Unum;

=end code

=head1 DESCRIPTION

Real::Unum is ...

=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Jeffrey Goff

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
