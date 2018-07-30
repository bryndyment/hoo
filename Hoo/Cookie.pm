package Hoo::Cookie;

use strict;
use Hoo qw( $m );

# call Hoo::SetMasonRequestObject (for $m) first

sub Get() {
	my ( %cookie, $cookieH, $key, $r );

	die 'No Mason request object.' unless $m;

	$r = $m->apache_req;

	$cookieH = {  };

	%cookie = CGI::Simple::Cookie->fetch( $r );

	foreach $key ( keys %cookie ) {
		$cookieH->{ $key } = $cookie{ $key }->value();
		}

	return $cookieH;
	}

# simple cookie(s); { a => 1, b => 2 } (separate cookies) or { c => 'a1b2' } (single cookie); defaults to session unless pass in "expires"
sub Set( $;$ ) {
	my ( $cookie, $key, $r );
	my ( $cookieH, $expires ) = @_;

	die 'No Mason request object.' unless $m;

	$r = $m->apache_req;

	foreach $key ( keys %$cookieH ) {
		if ( $expires ) {
			$cookie = CGI::Simple::Cookie->new( -name => $key, -value => $cookieH->{ $key }, -expires => $expires, -path => '/' );
			}
		else {
			$cookie = CGI::Simple::Cookie->new( -name => $key, -value => $cookieH->{ $key }, -path => '/' );
			}
		$r->err_headers_out->add( 'Set-Cookie' => $cookie );
		}
	}

sub Read() {
	my ( %cookie, $r );

	die 'No Mason request object.' unless $m;

	$r = $m->apache_req;

	%cookie = CGI::Simple::Cookie->fetch( $r );

#	$r = $m->apache_req;
#	$cookie = $r->headers_in->{ 'Cookie' };
#	$cookie =~ s/hoologic=(\w*)/$1/;

	return $cookie{ 'hoologic' } ? $cookie{ 'hoologic' }->value() : undef;
	}


sub Write( $;$$ ) {
	my ( $cookie, $r );
	my ( $value, $persistent, $expires ) = @_;

	die 'No Mason request object.' unless $m;

	$r = $m->apache_req;

	$expires = '+12M' unless $expires;

	$cookie = CGI::Simple::Cookie->new(
		-name    => 'hoologic',
		-value   => $value,
		-expires => $expires,
		-path    => '/'
		);

	$r->err_headers_out->add( 'Set-Cookie' => $cookie );
#	$r->err_headers_out->{ 'Set-Cookie' } = $cookie;

#	$r = $m->apache_req;
#	$cookie = Apache2::Cookie->new( $r,
#		-name    => 'hoologic',
#		-value   => $value,
#		-expires => '+12M',
#		-path    => '/'
#		);
#
#	$cookie->bake( $r );

#	$r = $m->apache_req;
#	$r->headers_out->{ 'Set-Cookie' } = ( ( "hoologic=$cookie; path=/" ) . ( $persistent ? '; expires=Fri, 31 Dec 2049 23:59:59 UTC' : '' ) );
#	$r->header_out( 'Set-Cookie' => ( "cookie=$cookie; path=/" ) . ( $persistent ? '; expires=Fri, 31 Dec 2049 23:59:59 UTC' : '' ) );
	}

1;