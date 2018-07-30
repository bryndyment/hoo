package Hoo::Session;

use strict;
use Apache::Session::MySQL;
use CGI::Simple::Cookie;
use Hoo qw( $m );
use Hoo::DB qw( $dbH );

# call Hoo::SetMasonRequestObject (for $m) and Hoo::DB::Connect (for $dbH) first
sub Read() {
	my ( $cookie, %cookie, $id, $r, %s );

	$r = $m->apache_req;

	unless ( $m ) {
		$r->log->error( 'Hoo::Session::Read: No Mason request object.' );
		die 'No Mason request object.';
		}

	unless ( $dbH ) {
		$r->log->error( 'Hoo::Session::Read: No database connection.' );
		die 'No database connection.';
		}

	%cookie = CGI::Simple::Cookie->fetch( $r );

	$cookie = $cookie{ 'hoo_session' } ? $cookie{ 'hoo_session' }->value() : undef;

	undef $id;

	if ( $cookie ) {
		if ( $cookie =~ /^(\w{32})$/ ) {
			$id = $1;
#			$r->log->error( 'Hoo::Session::Read: Cookie: ' . $cookie . '.' );
#			$r->log->error( 'Hoo::Session::Read: ID: ' . $id . '.' );
			}
		else {
#			$r->log->error( 'Hoo::Session::Read: Bad cookie: ' . $cookie . '.' );
			}
		}
	else {
#		$r->log->error( 'Hoo::Session::Read: No cookie.' );
		}

	eval {
		eval {
			tie %s, 'Apache::Session::MySQL', $id, { Handle => $dbH, LockHandle => $dbH };
			};
		};

	if ( $@ =~ /Object does not exist in the data store/ ) {
#		$r->log->error( 'Hoo::Session::Read: Object does not exist in the data store.' );
		tie %s, 'Apache::Session::MySQL', undef, { Handle => $dbH, LockHandle => $dbH };
		}

	use Data::Dumper;
#	$r->log->error( 'Hoo::Session::Read: %s: ' . ( Dumper %s ) . '.' );

	return \%s;
	}

# call Hoo::SetMasonRequestObject (for $m) and Hoo::DB::Connect (for $dbH) first
sub Write( $;$$ ) {
	my ( $cookie, $cookie2, $r );
	my ( $sH, $persistent ) = @_;

	$r = $m->apache_req;

	if ( $sH ) {
		unless ( $m ) {
			$r->log->error( 'Hoo::Session::Write: No Mason request object.' );
			die 'No Mason request object.';
			}

		unless ( $dbH ) {
			$r->log->error( 'Hoo::Session::Write: No database connection.' );
			die 'No database connection.';
			}

#		$r->log->error( 'Hoo::Session::Write: Session ID: ' . $sH->{ _session_id } . '.' );

		$cookie = CGI::Simple::Cookie->new(
			-name    => 'hoo_session',
			-value   => $sH->{ _session_id },
			-path    => '/'
			);

		unless ( $cookie ) {
#			$r->log->error( 'Hoo::Session::Write: No cookie.' );
			}

		if ( $persistent ) {
			$cookie->expires( '+12M' );
			}

#		$r->log->error( 'Hoo::Session::Write: Cookie: ' . $cookie . '.' );

		$r->err_headers_out->add( 'Set-Cookie' => $cookie );

		$sH->{ count }++;

		use Data::Dumper;
#		$r->log->error( 'Hoo::Session::Write: $sH: ' . ( Dumper $sH ) . '.' );

		untie %$sH;
		}
	else {
#		$r->log->error( 'Hoo::Session::Write: No session.' );
		}
	}

1;
