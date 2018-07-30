package Hoo::DB;

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( $dbH );

use vars qw( $dbH );

use strict;
use DBI;
use Hoo qw( $m );

sub Connect( ;$ ) {
	my ( $db, $dbHost, $mysql_enable_utf8, $password, $username );
	my ( $argH ) = @_;

	$db = ( $argH->{ db } || $m->apache_req->dir_config( 'HooDB' ) );
	$dbHost = ( $argH->{ dbHost } || $m->apache_req->dir_config( 'HooDBHost' ) || 'localhost' );
	$mysql_enable_utf8 = ( $argH->{ mysql_enable_utf8 } || 0 );
	$password = ( $argH->{ password } || 'content' );
	$username = ( $argH->{ username } || 'content' );

	die $DBI::errstr unless ( $dbH = DBI->connect( 'DBI:mysql:database=' . $db . ';host=' . $dbHost, ( $username ), ( $password ), { RaiseError => 1, AutoCommit => 1, mysql_enable_utf8 => $mysql_enable_utf8 } ) );
	}


sub Disconnect( % ) {
	$dbH->disconnect if $dbH;
	}


# sample call:
#
# GetAH( [ 'c_nam', 'l_nam' ], [ 't_cat', 't_lay' ], { g_id => 0, 't_cat.l_id' => 't_lay.l_id' }, [ 'c_seq' ] );
#
# order is fixed; all fields except $dbH and $table are optional;
sub GetAH( $;$$$ ) {
	my ( $arg, $cols, $error, $order, $sql, $table, @value, $where );

	if ( ref( $arg = shift ) eq 'ARRAY' ) {
		$cols = join ', ', @$arg;
		$arg = shift;
		}
	else {
		$cols = '*';
		}

	$table = join ', ', $arg;

	if ( $arg = shift ) {
		if ( ref( $arg ) eq 'HASH' ) {
			( $where, @value ) = PrepSelectArgs( $arg );
			$arg = shift;
			}
		$order = ( ' ORDER BY ' . ( join ', ', @$arg ) ) if $arg;
		}

	$sql = 'SELECT ' . $cols . ' FROM ' . $table . $where . $order;

	return SelectAH( \$sql, \@value );
	}


# good for form-based inserts... builds minimalist INSERT by skipping undefined hash values
sub Insert( $$;$ ) {
	my ( @arg, $sql, $val );
	my ( $table, $argH, $flagH ) = @_;

	foreach ( keys %$argH ) {
		if ( defined $argH->{ $_ } ) {
			$sql .= ( $_ . ',' );
			$val .= '?,';
			push @arg, $argH->{ $_ };
			}
		}

	$sql = 'INSERT ' . ( $flagH->{ ignore } ? 'IGNORE ' : '' ) . $table . ' (' . substr( $sql, 0, -1 ) . ') VALUES(' . substr( $val, 0, -1 ) . ')';

	SQL( \$sql, \@arg );

	return $dbH->{ 'mysql_insertid' };
	}


sub PrepSelectArgs( $ ) {
	my ( @arg, $argH, $temp, @value );

	( $argH ) = @_;

	foreach ( keys %$argH ) {
		if ( defined ( $temp = $argH->{ $_ } ) ) {
			push @arg, "$_=?";
			push @value, $temp;
			}
		}

	return ( '', undef ) unless ( scalar @arg );
	return ( ' WHERE ' . join( ' AND ', @arg ), @value );
	}


# efficient but inconvenient; returns array of arrays
sub SelectAA( $;@ ) {
	my ( $sqlS, $argA ) = @_;

	return $dbH->selectall_arrayref( $$sqlS, undef, @$argA );
	}


# inefficient but convenient; returns array of hashes
sub SelectAH( $;@ ) {
	my ( $argA, $sqlS, $stH, $temp, $tempAH );

	( $sqlS, $argA ) = @_;

	$tempAH = [ ];

	$stH = $dbH->prepare( $$sqlS );
	$stH->execute( @$argA );

	while ( $temp = $stH->fetchrow_hashref ) {
		push @$tempAH, $temp;
		}

	$stH->finish;

	return ( ( scalar @$tempAH ) ? $tempAH : undef );
	}


# inefficient but convenient; fetches a single row; returns hash
sub SelectH( $;@ ) {
	my ( $sqlS, $argA ) = @_;

	return $dbH->selectrow_hashref( $$sqlS, undef, @$argA );
	}


# inefficient but convenient; returns hash of hashes
sub SelectHH( $$;@ ) {
	my ( $sqlS, $key, $argA ) = @_;

	return $dbH->selectall_hashref( $$sqlS, $key, undef, @$argA );
	}


# fetch a single value; returns scalar
sub SelectS( $;@ ) {
	my ( $sqlS, $argA ) = @_;

	return ( $dbH->selectrow_array( $$sqlS, undef, @$argA ) )[ 0 ];
	}


sub SQL( $;@ ) {
	my ( $sqlS, $argA ) = @_;

	return $dbH->do( $$sqlS, undef, @$argA );
	}


sub Update( $$$ ) {
	my ( @arg, $sql, $val );
	my ( $table, $where, $argH ) = @_;

	foreach ( keys %$argH ) {
		if ( defined $argH->{ $_ } ) {
			$sql .= ( $_ . '=?,' );
			push @arg, $argH->{ $_ };
			}
		}

	$sql = 'UPDATE ' . $table . ' SET ' . substr( $sql, 0, -1 ) . ' WHERE ' . $where;

	return SQL( \$sql, \@arg );
	}

1;
