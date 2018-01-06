# =======================================================
# aGensym
=pod
	
	Gensym generates unique keys based on a key that we supply.
	gensym stored the current key in a database so keys are not reused
	the nest run but continue from the last key used
	
	Upon creating a new instance of GENSYM you register the key for this instance
	
=cut
# =======================================================

use warnings;
use strict;

use lib './lib';
use aApp;

package aGensym;

use aDB;

my %fields = (
	'key' => undef,
	'db' => undef,	
);

# =======================================================

sub new()
{
	# create a new instance of this Class 
	my $class = shift;
	my $self = {
		%fields,
	};
	bless $self , $class;

	# open the connection to the database that we talk to
	$self -> {'db'} = aDB -> new('GENSYM.DB');

	# what is the key that we use for this instance of gensym
	
	my $root = shift;
	# Make the key based on the root but not exact as the root, otherwise we have problems
	# later in the DIRS database as both the realpath and the dir2id match the volume partially
	
	$root = "\000$root\000";
	my $key = $self -> {'key'} = $root;	

	# lets see if we have ever seen this key before,
	if( ! defined $self -> {'db'} -> get($key) ) {
		# if no we create the first key and store it
		$self -> {'db'} -> put($key,1);
	}
	
	# we do not return the last key used here
	# we return the object 

	return $self;
}

# recall the last key used 
sub last ()
{
	my $self = shift;

	# we retreive the last key used based on the stored key	
	my $key = $self -> {'key'};
	my $val = $self -> {'db'} -> get($key);

	# and return it as format: '\000key\000xxxxxxxx'	
	return sprintf("%s%08x" , $key, $val );
}

sub next()
{
	my $self = shift;
	
	# we retreive the last key used based on the stored key	
	my $key = $self -> {'key'};
	my $val;
	# increment it and store it back in the database
	# if we ever want to do multi threading 
	# this section is critical TODO
	
	# ATOMIC 
	{
		$val = $self -> {'db'} -> get($key);
		$val++;
		$self -> {'db'} -> put($key,$val);
	}
	
	# and return it as format: '\000key\000xxxxxxxx'
	return sprintf("%s%08x" , $key, $val );
}

# ====================================================

1;
