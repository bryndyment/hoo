package Hoo::Lookup;

use strict;
use Hoo qw( $m );
use Hoo::DB qw( $dbH );

sub Get( $$ ) {
	my ( $sql );
	my ( $lookup_type_id, $value ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_lookup

		WHERE
			lookup_type_id = ?
			AND c_value = ?
		';

	return Hoo::DB::SelectH( \$sql, [ $lookup_type_id, $value ] );
	}

sub GetAll() {
	my ( $lookupHH );

	local $dbH->{ RaiseError };

	$lookupHH = Hoo::DB::SelectHH( \'SELECT * FROM t_lookup', [ 'lookup_type_id', 'c_value' ] );

	return ( $dbH->err() ? { } : $lookupHH );
	}

sub GetHashViaType( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_lookup

		WHERE
			lookup_type_id = ?

		ORDER BY
			c_sequence
		';

	return Hoo::DB::SelectHH( \$sql, [ $id ] );
	}

sub GetListViaType( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_lookup

		WHERE
			lookup_type_id = ?

		ORDER BY
			c_sequence
		';

	return Hoo::DB::SelectAH( \$sql, [ $id ] );
	}

sub GetTypes() {
	my ( $lookupTypeAH, $sql );

	$sql = '
		SELECT
			*

		FROM
			t_lookup_type

		ORDER BY
			id
		';

	local $dbH->{ RaiseError };

	$lookupTypeAH = Hoo::DB::SelectAH( \$sql );

	return ( $dbH->err() ? [ ] : $lookupTypeAH );
	}

1;