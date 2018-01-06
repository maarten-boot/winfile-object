use warnings;
use strict;

# =======================================================
package aLog;
# =======================================================

my %fields = (
	'path' => undef,
	'fh' => undef,
	'debug' => undef,
);

# =======================================================

sub new
{
	my $class = shift;
	my $self = {
		%fields,
	};
	bless $self , $class;
	
	my $log = $self -> {'path'}  = shift;
	
	if( @_ ) {
		$self -> {'debug'}  = shift;
	}
	
	open(LOG,">$log") || die "FATAL: cannot open logfile '$log',$!";
	$self -> {'fh'} = *LOG;
	
	return $self;
}

sub msg
{
	my $self = shift;	
	my $msg = shift;

	my $fh = $self -> {'fh'};
	return undef unless( defined $fh );
	printf $fh "%s\n" , $msg;
	return $self;
}

1;
