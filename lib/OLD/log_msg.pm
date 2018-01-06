use warnings;
use strict;

# =======================================================
package aLog;
# =======================================================

my %fields = (
	'path' => undef,
	'fh' => undef,
);

# =======================================================

sub open
{
	my $class = shift;
	my $self = {
		%fields,
	};
	
	bless $self , $class;
	

	my $log = $self -> {'path'}  = shift;
	open(LOG,">$log") || die "FATAL: cannot open logfile '$log',$!";
	$self -> {'fh'} = *LOG;
	
	return $self;
}

sub close
{
	my $self = shift;

	my $log = $self -> {'path'};
	close $self -> {'fh'} || die "FATAL: cannot close logfile '$log',$!";

	$self -> {'fh'} = undef;
	
	return $self;
}

sub msg
{
	my $self = shift;
	
	my $msg = shift;
	if( ! defined $self -> {'fh'} ) {
		return undef;	
	}
	
	# @TODO: date and time ??
	printf $self -> {'fh'} "%s\n" , $msg;
	
	return $self;
}

1;
