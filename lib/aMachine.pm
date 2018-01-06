# =======================================================
# aMachine
# =======================================================

use warnings;
use strict;

use lib './lib';
use aApp;

# =======================================================
package aMachine;
# =======================================================

use OS;
use aDB;

my %fields = (
	'os' => undef,			# an object 
	'hostname' => undef,
	'domain' => undef,
	'volumes' => undef,
	'login' => undef,
	'db' => undef
);

# =======================================================

sub new ($$)
{
	my $class = shift;

	my $self = {
		%fields,
	};
	bless($self,$class);

	
	my $os = $self -> {'os'} = OS -> new();
	$self -> {'volumes'} = [ $os -> get_filesystems()];
	$self -> {'db'} = aDB -> new('MACHINE.DB');

	return $self;
}

sub get_os ()
{
	my $self = shift;
	return $self -> {'os'};	
}

sub get_db ()
{
	my $self = shift;
	return $self -> {'db'};	
}

sub get_volumes ()
{
	my $self = shift;	
	return @{$self -> {'volumes'}};
}

sub backup($)
{
	my $self = shift;

	use aVolume;
	
	foreach my $name ($self -> get_volumes()) {
		my $volume = aVolume -> new ($name);
		$volume -> backup();
	}
}

# ====================================================

1;
