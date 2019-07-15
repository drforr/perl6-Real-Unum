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

	# Same as positQ in the PDF.
	#
	method is-valid-posit( Int $p ) returns Bool {
		0 <= $p <= $.npat;
	}

#`{

	In principle, the Mathematica description of the way Posit internals
	work is wonderful. In practice, it's simpler to do good old-fashioned
	string manipulation.

	Internally a posit is broken up like this 
	(6-bit, 2-exponent environment):

	001000 => sign[0] regime[0][1] exponent[00] fraction[0]

	The sign is the MSB.
	The regime is the longest run of bits that match the sign bit.
	(The regime may conceivably be the entire bit-string, see 0_00000
	 and 1_11111 - in that case, there's nothing left to interpret.)
	The exponent is the next <es> bits, if they exist. No padding.
	The fraction is the remainder, if it exists.

	There are probably many, many simpler ways to do what I'm doing here.
	I'll probably do more compact bit-shifting, maybe even adding a small
	C library later on.
}

	# Return $p as a (maybe left-padded) array of bits
	method padded-array( Int $p ) {
		die "Got invalid posit $p" unless self.is-valid-posit( $p );
		my Str $base-two = $p.base(2);
		my Str $padding = '0' x ( $.nbits - $base-two.chars );
		$base-two = $padding ~ $base-two;

		map { +$_ }, $base-two.split( '', :skip-empty );
	}

	method twos-complement( @bits ) {
		my @comp = map { 1 - $_ }, @bits;
		@comp[*-1]++;
		for 1 .. @comp.elems -> $index {
			next unless @comp[*-$index] > 1;

			@comp[*-$index-1]++ if $index+1 <= @comp.elems;
			@comp[*-$index] = 0;
		}
		@comp;
	}

	# Break the posit into its component parts. There will always be
	# a sign and regime bit, the other parts may not exist.
	#
	# Note that for negative numbers we take the 2s complement after
	# stripping the sign bit.
	#
	method parts( Int $p ) {
		die "Got invalid posit $p" unless self.is-valid-posit( $p );
		my %parts;
		my @binary = self.padded-array( $p );
		%parts<sign> = @binary.shift;
		@binary = self.twos-complement( @binary ) if
			%parts<sign> > 0;

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
		die "Got invalid posit $p" unless self.is-valid-posit( $p );
		given $p {
			when 0 { return 0 }
			when -Int($.npat/2) { return Inf }
			default {
				my ( $s, $k, $e, $f );
				my %parts = self.parts( $p );
				$s = %parts<sign>;
				$k = self.regimevalue( %parts<regime> );
				$e = %parts<exponent> ?? %parts<exponent>.parse-base(10) !! 1;
				$f = %parts<fraction> ?? +(%parts<fraction>).parse-base(10) !! 1;

				return (-1)**$s * $.useed**$k * 2**$e * $f;
			}
		}
	}

#`{

x2p[x_/; positableQ[x]] :=
   Module[{i, p, e = 2**(es-1), y = Abs[x]},
          Which[ # First, take care of the two exception values:
                 y == 0,   0 # all 0 bits
               , y == Inf, BitShiftLeft[1, nbits-1] # 1 followed by all 0s
               , True, If[ y >= 1 # Northeast quadrant
                         , p = 1;
                           i = 2; # Shift in 1s from the right and scale down
                           While[ y >= useed && i < nbits
                                , {p, y, i} = {2*p+1, y/useed, i+1}
                                ];
                           p = 2*p; i++
                         , # Else, southeast quadrant
                           p = 0;
                           i = 1; # Shift in 0s from the right and scale up
                           While[ y < 1 && i <= nbits
                                , {y, i} = {y*useed, i+1}
                                ];
                           If[ i >= nbits
                             , p = 2;
                               i = nbits + 1
                             , p = 1;
                               i++
                             ]
                         ];
                       # Extract exponent bits
                       While[ e > 1/2 && i <= nbits
                            , p=2*p;
                              If[ y >= 2**e
                                , y /= 2**e;
                                  p++
                                ];
                              e /= 2;
                              i++
                            ];
                       y--; # Fraction bits; subtract the hidden bit
                       While[ y > 0 && i <= nbits
                            , y = 2*y;
                              p = 2*p+floor(y);
                              y -= floor(y);
                              i++
                            ];
                       p *= 2**(nbits+1-i);
                       i++;
                       # round to nearest; tie goes to even
                       i = BitAnd[p, 1]; p=floor(p/2);
                       p = Which[
                          i = 0,       p,             # closer to lower value
                          y=1 || y==0, p+BitAnd[p,1], # tie goes to nearest even
                          True,        p+1
                         ]; # closer to upper value
                       Mod[ If[ x<0
                              , npat-p
                              , p 
                              ], npat ] # Simulate 2s complement
               ]
         ]
}

	method x2p( $x ) { # positable check is moot...
		my $i;
		my $p;
		my $e = 2**($.es - 1);
		my $y = abs( $x );

		given $y {
			when 0 { return 0 }
			when Inf {
				return 1 +< $.nbits - 1; # left is <<
			}
			default {
				if $y >= 1 { # Northeast quadrant
					$p = 1;
					$i = 2; # Shift in 1s from the right and scale down
					while $y >= $.useed and $i < $.nbits {
						$p = 2 * $p + 1;
						$y = $y / $.useed;
						$i++;
					}
					$p *= 2;
					$i++;
				}
				else { # Else, Southeast quadrant
					$p = 0;
					$i = 1; # Shift in 0s from the right and scale up
					while $y < 1 and $i <= $.nbits {
						$y *= $.useed;
						$i++;
					}
					if $i >= $.nbits {
						$p = 2;
						$i = $.nbits + 1;
					}
					else {
						$p = 1;
						$i++;
					}
				}
				# Extract exponent bits
				while $e > 1/2 and $i <= $.nbits {
					$p *= 2;
					if $y >= 2**$e {
						$y /= 2**$e;
						$p++;
					}
					$e /= 2;
					$i++;
				}
				$y--; # Fraction bits; subtract the hidden bit
				while $y > 0 and $i <= $.nbits {
					$y *= 2;
					$p = 2 * $p + floor( $y );
					$y -= floor( $y );
					$i++;
				}
				$p *= 2**($.nbits+1-$i);
				$i++;
				# round to nearest; tie goes to even
				$i = $p & 1; # bitand
				$p = floor( $p / 2 );
				if $i == 0 {
					#$p = $p; # closer to lower value
				}
				elsif $y == 1 || 0 {
					$p += ( $p & 1 ); # tie goes to nearest even
				}
				else {
					$p = $p + 1;
				}
				return ( $x < 0 ?? $.npat - $p !! $p )
					mod $.npat;
			}
		}
	}

	method regimevalue( $regimebits ) {
		$regimebits ~~ m{ ^ 0 } ?? -$regimebits.chars
					!! $regimebits.chars - 1;
	}

	method for-display( Int $p ) returns Str {
		die "Got invalid posit $p" unless self.is-valid-posit( $p );
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

	method _IntegerDigits( Int $p, Int $base where * >= 2 = 10, Int $maxlen? where * > 0 ) {
		my $p-base = $p.base($base);
		die "Out of range" if $maxlen and $p-base.chars > $maxlen;

		if $p-base.chars < $maxlen {
			$p-base = ('0' x ( $maxlen - $p-base.chars )) ~ $p-base;
		}
		return map { +$_ }, $p-base.split('', :skip-empty);
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

my $env = Real::Unum::Environment.new( :nbits( 6 ), :es( 2 ) );

my $pa = $env.new-from-float( 1/8 );
my $pb = $env.new-from-float( 1/16 );
is $pa+$pb, 3/16;

=end code

=head1 DESCRIPTION

Real::Unum is an implementation of an alternate floating-point numeric system described at L<https://posithub.org/docs/Posits4.pdf|PositHub.org>. The creator claims all the advantages of floats with fewer downsides.

It's a variable-width system that can accommodate any number of bits, and any number of exponent bits, within reason. Eventually there will be subclasses around uint{8,16,32,64} and so on to do regular math with those. Floating-point math within this system is supposedly less prone to rounding errors, and can all be done in less space than a typical IEEE float.

Please don't confuse this implementation with anything resembling a tuned numeric system. It mostly exists due to the fact that a posting caught my eye.

=head1 AUTHOR

Jeffrey Goff <drforr@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Jeffrey Goff

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
