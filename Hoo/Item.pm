package Hoo::Item;

use strict;
use Hoo qw( $m );
use Hoo::DB qw( $dbH );

sub GetAll( ;$ ) {
	my ( $i, $sql );
	my ( $typeA ) = @_;

	$sql = 'SELECT * FROM t_item';

	if ( $typeA ) {
		$sql .= ' WHERE';

		foreach $i ( @$typeA ) {
			$sql .= ( ' item_type_id = ' . $i . ' OR' );
			}

		$sql = substr( $sql, 0, -3 );
		}

	return Hoo::DB::SelectHH( \$sql, 'id' );
	}

sub GetAllNames() {
	return Hoo::DB::SelectHH( \'SELECT id, c_name FROM t_item', [ 'id' ] );
	}

sub Accessed( $ ) {
	my ( $id ) = @_;

	Hoo::DB::Update( 't_item', "id = $id", { c_accessed => Hoo::Util::Now() } );
	}

sub AdminAdd( $ ) {
	my ( $tempH, $try );
	my ( $argH ) = @_;

	srand();

	while ( ! $argH->{ id } && ( $try++ < Hoo::MAX_TRIES ) ) {
		$argH->{ id } = sprintf( "%d", rand( Hoo::UPPER - Hoo::LOWER + 1 ) ) + Hoo::LOWER;
		{
			local $dbH->{ RaiseError };

			Hoo::DB::Insert( 't_item', $argH );

			if ( $dbH->err() == Hoo::ERR_DUPLICATE_ENTRY ) {
				$argH->{ id } = 0;
				}
			elsif ( $dbH->err() ) {
				Hoo::Error( $dbH->errstr() );
				}
			}
		}

	Hoo::Error( 'Could not create item; maximum attempts exceeded.' ) unless $argH->{ id };

	return $argH->{ id };
	}

sub AdminAddType( $ ) {
	my ( $sql );
	my ( $argH ) = @_;

	return Hoo::DB::Insert( 't_item_type', $argH );
	}

sub AdminAddTypeColumn( $ ) {
	my ( $sql );
	my ( $argH ) = @_;

	Hoo::DB::Insert( 't_item_type_column', $argH );
	}

sub AdminDelete( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_item WHERE id = ?', [ $id ] );
	}

sub DeleteMultiple( $;$ ) {
	my ( $sql );
	my ( $item_type_id, $argH ) = @_;

	$sql = '
		DELETE

		FROM
			t_item

		WHERE
			item_type_id = ?

			' . ( $argH->{ where } ? ( '

			AND ' . $argH->{ where }

			) : '' );

	return Hoo::DB::SQL( \$sql, [ $item_type_id ] );
	}

sub AdminDeleteType( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_item_type WHERE id = ?', [ $id ] );
	}

sub AdminDeleteTypeColumns( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_item_type_column WHERE item_type_id = ?', [ $id ] );
	}

sub AdminGet( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item

		WHERE
			id = ?
		';

	return Hoo::DB::SelectH( \$sql, [ $id ] );
	}

sub AdminGetAll() {
	my ( $sql );

	$sql = '
		SELECT
			*

		FROM
			t_item

		ORDER BY
			c_sequence,
			c_name
		';

	return Hoo::DB::SelectAH( \$sql );
	}

sub GetAllOfType( $;$ ) {
	my ( $sql );
	my ( $item_type_id, $argH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item

		WHERE
			item_type_id = ? ' .

		( $argH->{ where }
			? ( ' AND ' . $argH->{ where } )
			: '' ) .

		' ORDER BY ' .

			( $argH->{ order_by }
				? $argH->{ order_by }
				: 'c_sequence, c_name' ) .

		( $argH->{ limit }
			? ( ' LIMIT ' . $argH->{ limit } )
			: '' )

		;

	return Hoo::DB::SelectAH( \$sql, [ $item_type_id ] );
	}

sub AdminGetAllViaType( $;$ ) {
	my ( $itemAH, $sql );
	my ( $item_type_id, $argH ) = @_;

	if ( $argH->{ locale } ) {
		Hoo::DB::SQL( \'SET lc_time_names = ?', [ $argH->{ locale } ] );
		}

	$sql = '
		SELECT
			i.*

			' . ( $argH->{ select } ? ( ',' .

			$argH->{ select }

			) : '' ) . '

			' . ( $argH->{ log } ? ',

			l.event_type_id AS event_type_id, l.c_timestamp AS log_timestamp, DATE_FORMAT( l.c_timestamp, \'%b. %e, %Y\' ) AS log_timestamp_Mmm_dot_DD_comma_YYYY, l.c_note AS log_note

			' : '' ) . '

		FROM
			t_item i

			' . ( $argH->{ from } ?

			$argH->{ from }

			: '' ) . '

			' . ( $argH->{ log } ? '

			LEFT OUTER JOIN ( SELECT item_id, MAX( id ) AS id FROM t_log GROUP BY item_id ) la
			ON i.id = la.item_id

			LEFT OUTER JOIN t_log l ON la.item_id = l.item_id AND la.id = l.id

			' : '' ) . '

		WHERE
			i.item_type_id = ?

			' . ( $argH->{ where } ? ( '

			AND ' . $argH->{ where }

			) : '' ) . '

		ORDER BY
			' . ( $argH->{ order_by } ?

			$argH->{ order_by }

			: '

			i.c_sequence, i.c_name

			' );

	$itemAH = Hoo::DB::SelectAH( \$sql, [ $item_type_id ] );

	if ( $argH->{ locale } ) {
		Hoo::DB::SQL( \'SET lc_time_names = ?', [ 'en_US' ] );
		}

	return $itemAH;
	}

sub AdminGetAllHashViaType( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item

		WHERE
			item_type_id = ?

		ORDER BY
			c_sequence, c_name
		';

	return Hoo::DB::SelectHH( \$sql, [ 'id' ], [ $id ] );
	}

sub AdminGetType( $ ) {
	my ( $sql );
	my ( $item_type_id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item_type

		WHERE
			id = ?
		';

	return Hoo::DB::SelectH( \$sql, [ $item_type_id ] );
	}

sub AdminGetTypes() {
	my ( $sql );

	$sql = '
		SELECT
			*

		FROM
			t_item_type

		ORDER BY
			c_sequence
		';

	return Hoo::DB::SelectAH( \$sql );
	}

sub AdminGetTypeColumns( $;$ ) {
	my ( $sql );
	my ( $item_type_id, $optionH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item_type_column

		WHERE
			item_type_id = ?' . ( $optionH->{ summary } ? ' AND c_summary <> 0' : '' ) . '

		ORDER BY
			c_sequence,
			c_required DESC,
			c_label
		';

	return Hoo::DB::SelectAH( \$sql, [ $item_type_id ] );
	}

sub AdminUpdate( $$ ) {
	my ( $id, $argH ) = @_;

	return Hoo::DB::Update( 't_item', "id = $id", $argH );
	}

sub AdminUpdateType( $$ ) {
	my ( $id, $argH ) = @_;

	return Hoo::DB::Update( 't_item_type', "id = $id", $argH );
	}

sub Get( $;$ ) {
	my ( $itemH, $sql, $tempH );
	my ( $id, $argH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item

		WHERE
			id = ?
		';

	if ( ( $itemH = Hoo::DB::SelectH( \$sql, [ $id ] ) ) && ( $argH->{ nav } ) ) {
		$sql = '
			SELECT
				c_name,
				c_url

			FROM
				t_item

			WHERE
				c_navigable = 1
				c_visible = 1
				c_sequence < ?

			ORDER BY
				c_sequence DESC

			LIMIT 1
			';

		$tempH = Hoo::DB::SelectH( \$sql, [ $itemH->{ c_sequence } ] );
		$itemH->{ previous_url } = $tempH->{ c_url };
		$itemH->{ previous_name } = $tempH->{ c_name };

		$sql = '
			SELECT
				c_name,
				c_url

			FROM
				t_item

			WHERE
				c_navigable = 1
				AND c_visible = 1
				AND c_sequence > ?

			ORDER BY
				c_sequence

			LIMIT 1
			';

		$tempH = Hoo::DB::SelectH( \$sql, [ $itemH->{ c_sequence } ] );
		$itemH->{ next_url } = $tempH->{ c_url };
		$itemH->{ next_name } = $tempH->{ c_name };
		}

	return $itemH;
	}

sub GetLog( $$ ) {
	my ( $sql );
	my ( $item_type_id, $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_log

		WHERE
			item_type_id = ?
			AND item_id = ?

		ORDER BY
			c_timestamp
		';

	return Hoo::DB::SelectAH( \$sql, [ $item_type_id, $id ] );
	}

sub GetMultiple( $;$ ) {
	my ( $sql, $tempAH );
	my ( $id, $argH ) = @_;

	$sql = '
		SELECT
			*,
			DATE_FORMAT( c_date, \'%b. %e, %Y\' ) AS date_Mmm_dot_DD_comma_YYYY

		FROM
			t_item

		WHERE
			item_type_id = ?
			AND c_navigable = 1
			AND c_visible = 1

		ORDER BY
		';

	if ( $argH->{ order_by } ) {
		$sql .= "
			$argH->{ order_by }
			";
		}
	else {
		$sql .= '
			c_sequence
			';
		}

	if ( $argH->{ maximum } || $argH->{ offset } ) {
		$argH->{ maximum } = 0 unless $argH->{ maximum };
		$argH->{ offset } = 0 unless $argH->{ offset };

		# bump up to determine if "next" should be enabled
		$argH->{ maximum }++;

		$sql .= "
			LIMIT
				$argH->{ offset },$argH->{ maximum }
			";
		}

	$tempAH = Hoo::DB::SelectAH( \$sql, [ $id ] );

	if ( $argH->{ maximum } ) { # we're paging
		if ( ( scalar @$tempAH ) == $argH->{ maximum } ) {
			pop @$tempAH;
			$tempAH->[ -1 ]{ next } = 1;
			}

		$tempAH->[ 0 ]{ previous } = 1 if $argH->{ offset };
		}

	$tempAH->[ -1 ]{ last } = 1 if $tempAH;

	return $tempAH;
	}

sub GetViaColumns( $ ) {
	# temporarily hard-coding for provilla username/password... this function needs to be generalized
	# ... including a new function in Hoo::DB
	my ( $sql );
	my ( $columnH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item i

		WHERE
			c_name_short = ?' . ( $columnH->{ c_password } ? ' AND c_password = ?' : '' ) . '

			AND c_visible = 1

		LIMIT 1
		';

	if ( $columnH->{ c_password } ) {
		return Hoo::DB::SelectH( \$sql, [ $columnH->{ c_name_short }, $columnH->{ c_password } ] );
		}
	else {
		return Hoo::DB::SelectH( \$sql, [ $columnH->{ c_name_short } ] );
		}
	}

sub GetViaEmail( $ ) {
	# temporarily hard-coding for provilla; should go away after GetViaColumns, above, is generalized
	my ( $sql );
	my ( $columnH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_item i

		WHERE
			c_email = ?

		LIMIT 1
		';

	return Hoo::DB::SelectH( \$sql, [ $columnH->{ c_email } ] );
	}

sub GetViaURL( $ ) {
	my ( $sql );
	my ( $url ) = @_;

	if ( $m->apache_req->dir_config( 'HooDB' ) ) {
		$sql = '
			SELECT
				*,
				DATE_FORMAT( c_created, \'%M %e, %Y\' ) AS created,
				DATE_FORMAT( c_created, \'%b %e, %Y / %l:%i %p\' ) AS date_time

			FROM
				t_item

			WHERE
				c_url = ?
				AND c_visible = 1

			LIMIT 1
			';

		return Hoo::DB::SelectH( \$sql, [ $url ] );
		}
	else {
		return 0;
		}
	}

sub GetRandom( $ ) {
	my ( $sql );
	my ( $item_type_id ) = @_;

	$sql = 'SELECT * FROM t_item WHERE item_type_id = ? AND c_navigable = 1 AND c_visible = 1 ORDER BY RAND()';

	return Hoo::DB::SelectH( \$sql, [ $item_type_id ] );
	}

#sub GetRandom() {
#	my ( $itemH, $sql );
#
#	$sql = 'SELECT si.*, it.c_name AS item_type, se.c_url FROM t_site_item si INNER JOIN t_item_type it ON si.item_type_id = it.id INNER JOIN t_site_element se ON si.id = se.element_id WHERE si.site_id = ? AND se.element_type_id = ' . Hoo::ITEM . ' AND si.c_available = 1 AND si.c_home_page = 1 AND si.c_navigable = 1 AND se.c_visible = 1 ORDER BY RAND() LIMIT 1';
#
#	return Hoo::DB::SelectH( \$sql, [ $site_id ] );
#	}

#sub GetViaURL( $ ) {
#	my ( $sql );
#	my ( $url ) = @_;
#
#	$sql = 'SELECT si.*, it.c_name AS item_type, se.c_url FROM t_site_item si INNER JOIN t_item_type it ON si.item_type_id = it.id INNER JOIN t_site_element se ON si.id = se.element_id WHERE si.site_id = ? AND se.element_type_id = ' . Hoo::ITEM . ' AND se.c_url = ? AND se.c_visible = 1';
#
#	return Hoo::DB::SelectH( \$sql, [ $site_id, $url ] );
#	}

1;