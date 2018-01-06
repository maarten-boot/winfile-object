# =======================================================
# A MACHINE
# =======================================================

use warnings;
use strict;

# =======================================================
package machine;

my %fields = (
	'hostname' => undef,
	'domain' => undef,
	'volumes' => undef,
	'os' => undef,			# an object 
	'os_version' => undef,	
);

# =======================================================

use Os;

# =======================================================

sub new ($$)
{
	my $class = shift;

	my $self = {
		%fields,
	};
	bless($self,$class);
	$self -> initialize();
	
	return $self;
}

sub initialize ()
{
	my $self = shift;

	# initialize the OS object and the os version
	$self -> os = OS -> new;
	$self -> os_version = $os -> get_version();

	# get the volumes (fixed)
	
	return $self;
}

sub os ()
{
	my $self = shift;

	return $self -> os;	
}

sub get_os_version ()
{
	my $self = shift;
	return $self -> os_version;	
}

sub volumes ()
{
	my $self = shift;
	my $self -> volumes = sort($os -> get_mounts());
	return $self -> volumes;
}

# =======================================================
1;

