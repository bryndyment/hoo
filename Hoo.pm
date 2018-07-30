package Hoo;

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( $m );

use vars qw( $m );

use strict;
use Apache2::Const qw( OK );
use Apache2::Log;
use Params::Validate qw( :all );
use Sys::Hostname ();

use vars qw (
	@FIELD_TYPE
	%URL
	);

BEGIN {
	@FIELD_TYPE = (
		[ 1, 'Checkbox' ],
		[ 2, 'Hidden' ],
		[ 3, 'Password' ],
		[ 4, 'Radio' ],
		[ 5, 'Lookup' ],
		[ 6, 'Text' ],
		[ 7, 'Textarea' ],
		[ 8, 'Group' ],
		[ 9, 'Item' ],
		[ 10, 'Link' ]
		);

	%URL = (
		CART => 1,
		CHECKOUT => 1,
		CONTACT => 1,
		CONTACT_THANKS => 1,
		CSS => 1,
		JS => 1,
		SHIPPING => 1
		);
	}

use constant LIVE => ( Sys::Hostname::hostname =~ /^server-hoologic$/ );
use constant LOCAL => 0;

use constant ERROR_COMP => '/hoo/error.mas';
use constant VALIDATE_COMP => '/hoo/validate.mas';
use constant EMAIL_ERROR_COMP => '/hoo/email/error.mas';

use constant ERR_DUPLICATE_ENTRY => 1062;
use constant SENDMAIL => '/usr/sbin/sendmail -t';

use constant EMAIL_BCC => 'bryndyment@yahoo.com';

use constant LOWER => 100000000;
use constant UPPER => 999999999;
use constant MAX_TRIES => 100;

use constant LOOKUP_TYPE_INPUT => 1;

use constant LOOKUP_INPUT_CHECKBOX => 1;
use constant LOOKUP_INPUT_HIDDEN => 2;
use constant LOOKUP_INPUT_PASSWORD => 3;
use constant LOOKUP_INPUT_RADIO => 4;
use constant LOOKUP_INPUT_SELECT => 5;
use constant LOOKUP_INPUT_TEXT => 6;
use constant LOOKUP_INPUT_TEXTAREA => 7;
use constant LOOKUP_INPUT_GROUP => 8;
use constant LOOKUP_INPUT_ITEM => 9;
use constant LOOKUP_INPUT_LINK => 10;

use constant USER_HOO => 'hoo';

sub Error( $;$ ) {
	my ( $r );
	my ( $error, $full_error ) = @_;

	if ( $m ) {
#		$r = $m->apache_req;
#		$r->log->error( $full_error ? $full_error : $error );
#		Hoo::Email::Send( $m, { error => $error, full_error => $full_error } );
		$m->comp( ERROR_COMP, error => $error );
		$m->abort( OK );
		}
	else {
		die $error;
		}
	}


# Call HandleURL from the autohandler.
#
# added JSON stuff but haven't updated these comments!!!
#
# First, the URL (up to but excluding any '?') is captured and the presence of a final slash determined.
#
# Next, with a final slash added, ValidURL is called.
#
# If it's a valid URL and there's a final slash and it's not a legacy URL, handle it immediately.
#
# If it's a valid URL but is either missing the final slash or is a legacy URL, redirect.
#
# It it's not a valid URL, iteratively move 'up' the URL to find a valid URL.  If we match, redirect.
# If no match by the first sublevel under '/' (e.g., '/asdf/') then 404.

sub HandleURL( $;$ ) {
	my ( $arg, $final_slash, $r, $reqH );
	my ( $argH, $url ) = @_;

	$r = $m->apache_req;

	$url = $ENV{ REQUEST_URI } unless $url;

	if ( $url =~ /^([^\?]*)/ ) {
		$url = $1;

		$final_slash = ( $url =~ /\/$/ );
		if ( $url =~ /(%28)|(%29)/ ) {
			$url =~ s/%28/(/g;
			$url =~ s/%29/)/g;

			$m->redirect( $url, $Apache2::Const::MOVED );
			}
		elsif ( $reqH = Hoo::ValidURL( $url . ( $final_slash ? '' : '/' ), $argH->{ handler } ) ) {
			if ( $final_slash && ( ! $reqH->{ old_url } ) ) {
				$r->content_type( $reqH->{ content_type } );
				if ( ! $reqH->{ cache } ) {
					$r->no_cache( 1 );
					}
				$argH->{ groupH } = $reqH->{ groupH } if $reqH->{ groupH };
				$argH->{ itemH } = $reqH->{ itemH } if $reqH->{ itemH };
				$argH->{ json } = $reqH->{ json } if $reqH->{ json };
				$argH->{ url } = $reqH->{ url } if $reqH->{ url };
				$m->comp( $reqH->{ path }, %$argH );
				}
			else {
				$m->redirect( $reqH->{ old_url } ? $reqH->{ new_url } : ( $url . '/' ), $Apache2::Const::MOVED );
				}
			}
		else {
			$url = $ENV{ REQUEST_URI };
			while ( $url =~ /^(\/([^\/]+\/)*).{1}/ ) {
				$url = $1;
				if ( Hoo::ValidURL( $url ) ) {
					$m->redirect( $url, $Apache2::Const::MOVED );
					}
				}
			$m->clear_buffer;
			$m->abort( $Apache2::Const::NOT_FOUND );
			}
		}
	else {
		$m->clear_buffer;
		$m->abort( $Apache2::Const::NOT_FOUND );
		}
	}


sub Log( $$$$ ) {
	my ( $event_type_id, $item_type_id, $item_id, $note ) = @_;

	Hoo::DB::Insert( 't_log', { event_type_id => $event_type_id, item_type_id => $item_type_id, item_id => $item_id, c_timestamp => Hoo::Util::Now(), c_note => $note } );
	}


sub SetMasonRequestObject( $ ) {
	( $m ) = @_;
	}


sub UserAgent( $ ) {
	my ( $ie5, $ie50, $ie6, $mac, $uaH, $win );
	my ( $ua ) = @_;

	$ie5 = ( $ua =~ /MSIE 5/ );
	$ie50 = ( $ua =~ /MSIE 5\.0/ );
	$ie6 = ( $ua =~ /MSIE 6/ );

	$uaH->{ mac } = $mac = ( $ua =~ /Mac/ );
	$uaH->{ win } = $win = ( $ua =~ /Windows/ );

	$uaH->{ ie5 } = $ie5;
	$uaH->{ ie6 } = $ie6;

	$uaH->{ ie5m } = ( $ie5 && $mac );
	$uaH->{ ie5w } = ( $ie5 && $win );

	$uaH->{ ie50m } = ( $ie50 && $mac );
	$uaH->{ ie50w } = ( $ie50 && $win );
	$uaH->{ ie56w } = ( ( $ie5 || $ie6 ) && $win );

	$uaH->{ firefox } = ( $ua =~ /Firefox/ );
	$uaH->{ iew } = ( ( $ua =~ /MSIE/ ) && $win );
	$uaH->{ opera } = ( $ua =~ /Opera/ );
	$uaH->{ safari } = ( $ua =~ /Safari/ );

	$uaH->{ ns4 } = ( ( $ua =~ /Mozilla\/4/ ) && ( $ua !~ /MSIE/ ) );

	return $uaH;
	}


sub Validate( $$;@ ) {
	my ( $error, $full_error );
	my ( $paramA, $ruleH, @option ) = @_;

	validation_options( @option ) if ( scalar @option );

	eval {
		validate( @$paramA, $ruleH );
		};

	if ( $full_error = $@ ) {
		$error = $m->comp( VALIDATE_COMP );
		Error( $error, $full_error );
		}
	}


# ValidURL is called from HandleURL.  Input is a slash-terminated URL stripped of arguments.
#
# added JSON stuff but haven't updated these comments!!!
#
# First determine if various physical files are present (e.g., '/practice/json/index.json', '/options/index.html',
# '/css/index.css', '/js/index.js').
#
# If not, call GetViaURL to determine if the URL maps to a virtual element (e.g., group, item, weblog entry).
#
# If so, and it's a legacy URL, return the new URL and a redirect request. If it's not a legacy URL, determine
# the handler (e.g., group_list.mas, item_detail.mas, weblog_entry.mas) and element ID.
#
# If not, determine if the URL identifies an order.
#
# If not, determine if the URL has a default 'Hoo' handler (e.g., '/hoo/cart.mas' for the '/cart/' URL) and
# that the handler is physically present. A site can always override these default handlers. For example, a file
# physically at '/cart/index.html' preempts '/hoo/cart.mas', and '/css/index.css' preempts '/hoo/css.mas'.
#
# If not, the URL is not valid.

sub ValidURL( $;$ ) {
	my ( $groupH, $id, $itemH, $json, $path, $reqH, $tempH, $url_key );
	my ( $url, $handler ) = @_;

	undef $reqH;

	if ( $url =~ /^(.*\/)json\/$/ ) {
		$url = $1;
		$json = 1;
		}

	if ( $m->comp_exists( $url . 'index.html' ) ) {
		$reqH = { path => $url . 'index.html', content_type => 'text/html; charset=utf-8' };
		}
	elsif ( ( $url =~ /\/css\// ) && $m->comp_exists( $url . 'index.css' ) ) {
		$reqH = { path => ( $url . 'index.css' ), content_type => 'text/css; charset=utf-8', cache => 1 };
		}
	elsif ( ( $url =~ /\/js\// ) && $m->comp_exists( $url . 'index.js' ) ) {
		$reqH = { path => ( $url . 'index.js' ), content_type => 'application/javascript; charset=utf-8', cache => 1 };
		}
	elsif ( $handler ) {
		$reqH = { path => '/hoo/url_handler.mas', url => $url, content_type => 'text/html; charset=utf-8' };
		}
	elsif ( ( keys %{ Hoo::Item:: } ) && ( $itemH = Hoo::Item::GetViaURL( $url ) ) ) {
		$reqH = { path => '/hoo/item_detail.mas', itemH => $itemH, content_type => 'text/html; charset=utf-8' };
		}
	elsif ( ( keys %{ Hoo::Group:: } ) && ( $groupH = Hoo::Group::GetViaURL( $url ) ) ) {
		if ( $groupH->{ subgroup_id } && $groupH->{ item_id } ) {
			$path = '/hoo/item_group_list.mas';
			}
		elsif ( $groupH->{ subgroup_id } ) {
			$path = '/hoo/group_list.mas';
			}
		elsif ( $groupH->{ item_id } ) {
			$path = '/hoo/item_list.mas';
			}
		else {
			Hoo::Error( 'Group contains neither subgroups nor items.' );
			}
		$reqH = { path => $path, groupH => $groupH, content_type => 'text/html; charset=utf-8' };
		}
	elsif ( ( $url =~ /(.*\/)\d{1,2}\/$/ ) && ( keys %{ Hoo::Item:: } ) && ( $itemH = Hoo::Item::GetViaURL( $1 ) ) ) {
		$reqH = { path => '/hoo/item_detail.mas', itemH => $itemH, content_type => 'text/html; charset=utf-8' };
		}
	elsif ( ( $url =~ /\/(\d{9})\/$/ ) && ( keys %{ Hoo::Item:: } ) && ( $itemH = Hoo::Item::Get( $1 ) ) ) {
		$reqH = { path => '/hoo/item_detail.mas', itemH => $itemH, content_type => 'text/html; charset=utf-8' };
		}
	else {
		( $url_key = $url ) =~ s/\//_/g;
		$url_key = substr( $url_key, 1, -1 );
		if ( $Hoo::URL{ uc $url_key } ) {
			$reqH = { path => ( '/hoo/' . $url_key . '.mas' ), content_type => 'text/html; charset=utf-8' };
			}
		}

	if ( $json ) {
		$reqH->{ content_type } = 'text/plain; charset=utf-8';
		$reqH->{ json } = 1;
		}

	return $reqH;
	}

1;
