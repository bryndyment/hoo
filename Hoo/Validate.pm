package Hoo::Validate;

use strict;
use Hoo;
use Params::Validate qw(:all);

sub Dynamic( $$;@ ) {
	my ( $i, $j, $k, $l, $match, @param, %param );
	my ( $paramA, $regexA, @ignore ) = @_;

	foreach $j ( 0 .. ( @$paramA / 2 ) - 1 ) {
		$j = $j * 2;
		$match = 0;

		foreach ( @ignore ) {
			if ( $paramA->[ $j ] eq $_ ) {
				$match = 1;
				last;
				}
			}
		next if $match;

		foreach $l ( 0 .. ( @$regexA / 2 ) - 1 ) {
			$l = $l * 2;
			if ( $paramA->[ $j ] =~ $regexA->[ $l ] ) {
				$match = 1;
				$param{ $paramA->[ $j ] } = { regex => $regexA->[ $l + 1 ] };
				last;
				}
			}
		Hoo::Error( 'Invalid parameter.' ) unless $match;

		push @param, $paramA->[ $j ], $paramA->[ $j + 1 ];
		}

	Hoo::Validate( \@param, \%param, allow_extra => 0 );
	}

1;
