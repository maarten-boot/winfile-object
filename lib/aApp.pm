use warnings;
use strict;

# ===============================================================
package aApp;
# ===============================================================
=pod
	The idea is to collect all common elements of an application
	here.
	
	Is it an interactive application?
	Do we have a log file?
	What OS do we run on ?
	when did we start ?
=cut

my %fields = (
	# what is the operating system we are running on
	'os' => undef,

	# the hostname we are running on 
	'host' => undef,
	'fqn' => undef,

	# process id, the tuple (fqn,pid) must be unique
	'pid' => undef,
	
	# the user who started the application
	'user' => undef,

	# the application name (usually the basename of the invoked binary)
	'appname' => undef,	

	# start and end time 	
	'start_time' => undef,
	'end_time' => undef,

	# do we have a logging facility	
	'logfile' => undef,

	# are we by any chance running interactive
	'interactive' => undef,

	# this is a kind of runtime registry to collect and recall 
	# runtime information, if we ever have the ability to freeze and thaw an app
	# this data is volatile and not stored
	'RUNTIME' => undef,
);

# ===============================================================

use lib './lib';
use OS;
use aLog;

# ===============================================================

sub start ($)
{
	my $class = shift;
	my $self = {
		%fields,	
	};
	bless $self, $class;
	
	$self -> {'appname'} = shift;	
	$self -> {'start_time'} = time;

	my $os = $self -> {'os'} = OS -> new();
	$self -> {'host'} = $os -> get_hostname();
	$self -> {'user'} = $os -> get_logname();
	
	return $self;
}

sub finish()
{
	my $self = shift;

	$self -> {'end_time'} = time;

	exit(0);
}

sub logging
{
	my $self = shift;
	my $path = shift;
	
	my $debug = 0;
	if( @_ ) {
		$debug = shift;
	}
	
	$self -> {'logfile'} = aLog -> new($path,$debug);

	return $self;
}

sub log
{
	my $self = shift;
	my $msg = shift;
	
	$self -> {'logfile'} -> msg($msg);

	return $self;
}

sub arguments()
{
	my $self = shift;
	my $args = shift;

	# process any command line arguments that this application may have stated with
	# e.g 
	# -log = 'filename' , -interactive , -debug , -trace , 

	return $self;
}

sub get_os()
{
	my $self = shift;

	return $self -> {'os'};
}

# ============================================
# ============================================
# ============================================

sub register
{
	my $self = shift;
	
	my $key = shift;
	my $val = shift;

	if( defined $key ) {
		print "register key: $key val: $val\n" if $::DBG;
		$self -> {'RUNTIME'} -> {$key} = $val;
		return;
	}
	
	print STDERR "cannot remember with key that is undef, sorry";
}

sub lookup
{
	my $self = shift;
	my $key = shift;

	if( defined $key ) {
		my $val = $self -> {'RUNTIME'} -> {$key};

			if( ! defined $val ) {
			print "lookup key: ($key) val: (undef)\n" if $::DBG;		
		} else {		
			print "lookup key: ($key) val: ($val)\n" if $::DBG;
		}

		return $val;
	}	

	print STDERR "cannot recall with key that is undef, sorry";
}

# ====================================================
1;
