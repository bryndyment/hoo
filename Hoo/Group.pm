package Hoo::Group;

use strict;
use Hoo qw( $m );
use Hoo::DB qw( $dbH );

sub AdminAdd( $ ) {
	my ( $tempH, $try );
	my ( $argH ) = @_;

	srand();

	while ( ! $argH->{ id } && ( $try++ < Hoo::MAX_TRIES ) ) {
		$argH->{ id } = sprintf( "%d", rand( Hoo::UPPER - Hoo::LOWER + 1 ) ) + Hoo::LOWER;
		{
			local $dbH->{ RaiseError };

			Hoo::DB::Insert( 't_group', $argH );

			if ( $dbH->err() == Hoo::ERR_DUPLICATE_ENTRY ) {
				$argH->{ id } = 0;
				}
			elsif ( $dbH->err() ) {
				Hoo::Error( $dbH->errstr() );
				}
			}
		}

	Hoo::Error( 'Could not create group; maximum attempts exceeded.' ) unless $argH->{ id };
	}

sub AdminAddType( $ ) {
	my ( $argH ) = @_;

	return Hoo::DB::Insert( 't_group_type', $argH );
	}

sub AdminAddTypeColumn( $ ) {
	my ( $argH ) = @_;

	Hoo::DB::Insert( 't_group_type_column', $argH );
	}

sub AdminDelete( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_group WHERE id = ?', [ $id ] );
	}

sub AdminDeleteType( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_group_type WHERE id = ?', [ $id ] );
	}

sub AdminDeleteTypeColumns( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_group_type_column WHERE group_type_id = ?', [ $id ] );
	}

sub AdminGet( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_group

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
			t_group

		ORDER BY
			c_sequence,
			c_name
		';

	return Hoo::DB::SelectAH( \$sql );
	}

sub AdminGetAllViaType( $ ) {
	my ( $sql );
	my ( $group_type_id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_group

		WHERE
			group_type_id = ?

		ORDER BY
			c_sequence,
			c_name
		';

	return Hoo::DB::SelectAH( \$sql, [ $group_type_id ] );
	}

sub AdminGetItemsRecursive( $;$ ) {
	my ( $iH, $sql, $tempAH );
	my ( $id, $itemAH ) = @_;

	$itemAH = [ ] unless $itemAH;

	$sql = '
		SELECT
			*

		FROM
			t_item

		WHERE
			group_id = ?

		ORDER BY
			c_sequence,
			c_name
		';

	if ( $tempAH = Hoo::DB::SelectAH( \$sql, [ $id ] ) ) {
		push( @$itemAH, @$tempAH );
		}

	$sql = '
		SELECT
			*

		FROM
			t_group

		WHERE
			parent_group_id = ?

		ORDER BY
			c_sequence,
			c_name
		';

	if ( $tempAH = Hoo::DB::SelectAH( \$sql, [ $id ] ) ) {
		foreach $iH ( @$tempAH ) {
			AdminGetItemsRecursive( $iH->{ id }, $itemAH );
			}
		}

	return ( ( scalar @$itemAH ) ? $itemAH : undef );
	}

sub AdminGetType( $ ) {
	my ( $sql );
	my ( $group_type_id ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_group_type

		WHERE
			id = ?
		';

	return Hoo::DB::SelectH( \$sql, [ $group_type_id ] );
	}

sub AdminGetTypes() {
	my ( $groupTypeAH, $sql );

	$sql = '
		SELECT
			*

		FROM
			t_group_type
		';

	local $dbH->{ RaiseError };

	$groupTypeAH = Hoo::DB::SelectAH( \$sql );

	return ( $dbH->err() ? [ ] : $groupTypeAH );
	}

sub AdminGetTypeColumns( $;$ ) {
	my ( $sql );
	my ( $group_type_id, $optionH ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_group_type_column

		WHERE
			group_type_id = ?' . ( $optionH->{ summary } ? ' AND c_summary <> 0' : '' ) . '

		ORDER BY
			c_sequence,
			c_required DESC,
			c_label
		';

	return Hoo::DB::SelectAH( \$sql, [ $group_type_id ] );
	}

sub AdminUpdate( $$ ) {
	my ( $id, $argH ) = @_;

	return Hoo::DB::Update( 't_group', "id = $id", $argH );
	}

sub AdminUpdateType( $$ ) {
	my ( $id, $argH ) = @_;

	return Hoo::DB::Update( 't_group_type', "id = $id", $argH );
	}

sub Get( $;$ ) {
	my ( $groupH, $sql, $tempH );
	my ( $id, $argH ) = @_;

	$sql = '
		SELECT
			g.*,
			gt.item_type_id

		FROM
			t_group g

			INNER JOIN t_group_type gt
			ON g.group_type_id = gt.id

		WHERE
			g.id = ?
		';

	if ( ( $groupH = Hoo::DB::SelectH( \$sql, [ $id ] ) ) && ( $argH->{ nav } ) ) {
		$sql = '
			SELECT
				c_name,
				c_url

			FROM
				t_group

			WHERE
				c_navigable = 1
				AND c_visible = 1
				AND c_sequence < ?

			ORDER BY
				c_sequence DESC

			LIMIT 1
			';

		$tempH = Hoo::DB::SelectH( \$sql, [ $groupH->{ c_sequence } ] );
		$groupH->{ previous_url } = $tempH->{ c_url };
		$groupH->{ previous_name } = $tempH->{ c_name };

		$sql = '
			SELECT
				c_name,
				c_url

			FROM
				t_group

			WHERE
				c_navigable = 1
				AND c_visible = 1
				AND c_sequence > ?

			ORDER BY
				c_sequence

			LIMIT 1
			';

		$tempH = Hoo::DB::SelectH( \$sql, [ $groupH->{ c_sequence } ] );
		$groupH->{ next_url } = $tempH->{ c_url };
		$groupH->{ next_name } = $tempH->{ c_name };
		}

	return $groupH;
	}

sub GetItems( $ ) {
	my ( $sql );
	my ( $id ) = @_;

	$sql = '
		SELECT
			gi.group_id, gi.c_sequence AS group_item_sequence,
			i.*

		FROM
			t_group_item gi

			INNER JOIN t_item i
			ON gi.item_id = i.id

		WHERE
			gi.group_id = ?

		ORDER BY
			gi.c_sequence,
			i.c_name
		';

	return Hoo::DB::SelectAH( \$sql, [ $id ] );
	}

sub AddItem( $ ) {
	my ( $argH ) = @_;

	Hoo::DB::Insert( 't_group_item', $argH );
	}

sub DeleteItem( $$ ) {
	my ( $group_id, $item_id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_group_item WHERE group_id = ? AND item_id = ?', [ $group_id, $item_id ] );
	}

sub DeleteItems( $ ) {
	my ( $id ) = @_;

	Hoo::DB::SQL( \'DELETE FROM t_group_item WHERE group_id = ?', [ $id ] );
	}

sub OldGetItems( $;$ ) {
	my ( $sql, $tempAH );
	my ( $id, $argH ) = @_;

	$sql = '
		SELECT
			*,
			DATE_FORMAT( c_date, \'%b. %e, %Y\' ) AS date_Mmm_dot_DD_comma_YYYY

		FROM
			t_item

		WHERE
			group_id = ?
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

sub GetViaURL( $ ) {
	my ( $groupH, $sql );
	my ( $url ) = @_;

	$sql = '
		SELECT
			*

		FROM
			t_group

		WHERE
			c_url = ?
			AND c_visible = 1

		LIMIT 1
		';

	local $dbH->{ RaiseError };

	$groupH = Hoo::DB::SelectH( \$sql, [ $url ] );

	return ( $dbH->err() ? undef : $groupH );
	}

#sub GetAllTopLevel() {
#	my ( $sql );
#
#	$sql = 'SELECT sg.c_name, gt.id AS group_type_id, gt.c_name AS group_type_name, se.c_url FROM t_site_group sg INNER JOIN t_group_type gt ON sg.group_type_id = gt.id INNER JOIN t_site_element se ON sg.id = se.element_id INNER JOIN t_site_group sg ON sg.parent_group_id = sg.id WHERE sg.site_id = ? AND se.element_type_id = ' . Hoo::GROUP . ' AND sg.c_navigable = 1 AND se.c_visible = 1 AND sg.parent_group_id = 0 ORDER BY sg.c_sequence';
#	return Hoo::DB::SelectAH( \$sql, [ $site_id ] );
#	}

#sub GetRoot() {
#	my ( $sql, $tempH );
#
#	$sql = 'SELECT sg.*, gt.id AS group_type_id, gt.c_name AS group_type_name, se.c_url, se.c_visible FROM t_site_group sg INNER JOIN t_group_type gt ON sg.group_type_id = gt.id INNER JOIN t_site_element se ON sg.id = se.element_id WHERE sg.site_id = ? AND sg.parent_group_id = 0 AND se.element_type_id = ' . Hoo::GROUP;
#	if ( $tempH = Hoo::DB::SelectH( \$sql, [ $site_id ] ) ) {
#		$tempH->{ itemH } = Hoo::Item::Get( $tempH->{ item_id } );
#		}
#
#	return $tempH;
#	}

#sub GetSubcategories( $ ) {
#	my ( $sql );
#	my ( $id ) = @_;
#
#	$sql = 'SELECT sg.*, gt.id AS group_type_id, gt.c_name AS group_type_name, se.c_url, si.c_image AS item_image, si.c_image_border AS item_image_border, si.c_name AS item_name, si.c_note AS item_note FROM t_site_group sg INNER JOIN t_group_type gt ON sg.group_type_id = gt.id INNER JOIN t_site_element se ON sg.id = se.element_id LEFT OUTER JOIN t_site_item si ON sg.item_id = si.id WHERE sg.site_id = ? AND sg.parent_group_id = ? AND se.element_type_id = ' . Hoo::GROUP . ' AND sg.c_navigable = 1 AND se.c_visible = 1 ORDER BY sg.c_sequence';
#	return Hoo::DB::SelectAH( \$sql, [ $site_id, $id ] );
#	}

1;
