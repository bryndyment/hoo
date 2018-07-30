package Hoo::Util;

use strict;


sub DayMonthYear() {
	my ( $day, $month, $year );

	( undef, undef, undef, $day, $month, $year ) = localtime( time );
	$month++;
	$year += 1900;

	return ( $day, $month, $year );
	}


sub EscapeCurrency {
	return unless defined ${ $_[0] };

	${ $_[0] } = sprintf( "%.2f", ${ $_[ 0 ] } );
	}


sub EscapeJavaScript {
	return unless defined ${ $_[0] };

	${ $_[0] } =~ s/\\/\\\\/gsm;
	${ $_[0] } =~ s/\n/\\n/gsm;
	${ $_[0] } =~ s/\r/\\r/gsm;
	${ $_[0] } =~ s/\t/\\t/gsm;
	${ $_[0] } =~ s/'/\\'/gsm;
	}


sub Now() {
	my ( @time );

	@time = localtime();

	return sprintf( "%d-%d-%d %d:%d:%d", $time[ 5 ] + 1900, $time[ 4 ] + 1, $time[ 3 ], $time[ 2 ], $time[ 1 ], $time[ 0 ] );
	}


sub Today() {
	my ( @time );

	@time = localtime();

	return sprintf( "%04d-%02d-%02d", $time[ 5 ] + 1900, $time[ 4 ] + 1, $time[ 3 ] );
	}


sub UserAgent( $ ) {
	my ( $uaH );
	my ( $ua ) = @_;

	$uaH->{ ie5 } = ( $ua =~ /msie 5/i );
	$uaH->{ ie5m } = ( $uaH->{ ie5 } && ( $ua =~ /mac/i ) );
	$uaH->{ ie5w } = ( $uaH->{ ie5 } && ( $ua !~ /mac/i ) );
	$uaH->{ ie6 } = ( $ua =~ /msie 6/i );
	$uaH->{ ie56w } = $uaH->{ ie5w } || $uaH->{ ie6 };
	$uaH->{ opera } = ( $ua =~ /opera/i );
	$uaH->{ ns4 } = ( ( $ua =~ /mozilla\/4/i ) && ( $ua !~ /msie/i ) );
	$uaH->{ ns6 } = ( $ua =~ /netscape6/i );
	$uaH->{ m5 } = ( $ua =~ /mozilla\/5/i );

	return $uaH;
	}

1;
