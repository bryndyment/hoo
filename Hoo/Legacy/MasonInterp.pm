package Hoo::Legacy::MasonInterp;

use strict;
use HTML::Mason;

##
# Constructor
#
sub new
{
	my ($class, %args) = @_;
	unless (defined($args{COMP_ROOT}))
	{
		die('Hoo::Legacy::MasonInterp->new() - missing COMP_ROOT');
	}
	unless (defined($args{DATA_DIR}))
	{
		die('Hoo::Legacy::MasonInterp->new() - missing DATA_DIR');
	}

	my $output_var;
	my $interp = HTML::Mason::Interp->new(
		data_dir => $args{DATA_DIR},
		comp_root => $args{COMP_ROOT},
		out_method => \$output_var
	);

	my $self = {
		INTERP => $interp,
		OUTPUT_VAR_REF => \$output_var,
		COMP_ROOT => $args{COMP_ROOT}
	};
	bless($self, $class);
	return $self;
}

sub getCompRoot($)
{
	return $_[0]->{COMP_ROOT};
}

sub generate($;@)
{
	my ($self, %args) = @_;
	unless (defined($args{COMP_PATH}))
	{
		die('Hoo::Legacy::MasonInterp->generate() - missing COMP_PATH');
	}
	my $comp_path = $args{COMP_PATH};
	my $comp = $self->{INTERP}->load($comp_path);
	die "Hoo::Legacy::MasonInterp->generate() - Unable to load component $comp_path" unless ($comp);

	delete $args{COMP_PATH};

	${$self->{OUTPUT_VAR_REF}} = '';
	$self->{INTERP}->exec($comp, %args);

	return ${$self->{OUTPUT_VAR_REF}};
}

1;
