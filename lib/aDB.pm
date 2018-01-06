# =======================================================
# aDB
=pod
	The interface to the database part. Currently DB_FILE.
	Basically we treat each table as a different file.
	The environment variable WINFILE currenty indicates where to store
	the file data
	
	all tables are simple key -> value pairs at this level
	based on BTREE

	The interface to the database is SELECT,INSERT/UPDATE,DELETE

=cut
# =======================================================

use warnings;
use strict;

use lib './lib';
use aApp;

package aDB;

my %fields = (
	'path' => undef,
#	'type' => undef,
	'db_handle' => undef,
	'db_hash_r' => undef,
);

use DB_File;
use Fcntl;

sub new 
{
	my $class = shift;
	my $self = {
		%fields,
	};

	bless $self , $class;
	my $z = $ENV{'WINFILE'};
	die unless $z;

	my $d = "$z/DB";
	if( ! -d "$d" ) {
		mkdir("$d",0777) || die "FATAL: cannot make dir: '$d',$!";
	}
	
	my $path = $self -> {'path'} = shift;

	my %db;
	my $db = tie %db, "DB_File", 
		"$d/$path", 
		O_RDWR|O_CREAT,
		0640, 
		$DB_BTREE ||
	die "FATAL: cannot tie to '$path', $!\n";

	$self -> {'db_handle'} = $db;
	$self -> {'db_hash_r'} = \%db;

	return $self;
}

sub DESTROY 
{
	my $self = shift;		

	print 'closing', $self-> {'path'} if $::DBG > 5;

	$self -> sync($self -> {'db_handle'});
}

sub sync
{
	my $self = shift;	
	if( defined $self -> {'db_handle'} ) {
		$self -> {'db_handle'} -> sync;
		print "SYNC: ",$self -> {'path'},  "\n" if $::DBG > 5; 
	}
	return $self;
}

sub get
{
	my $self = shift;	
	my $key = shift;

	my $val = undef;
	$self -> {'db_handle'} -> get($key,$val);

	if( $::DBG > 5 ) {	
		my $path = $self -> {'path'};	
		print "GET: (path = $path) , (key = $key) \n"; 
	}

	return $val;
}

sub select_first
{
	my $self = shift;	
	
	my $st = $self -> {'db_handle'} -> seq($_[0],$_[1],R_CURSOR);

	return $st;
}

sub select_next
{
	my $self = shift;	

	my $st = $self -> {'db_handle'} -> seq($_[0],$_[1],R_NEXT);

	return $st;
}

sub put
{
	my $self = shift;	

	my $key = shift;
	my $val = shift;
	$self -> {'db_handle'} -> put($key, $val);

	if( $::DBG > 5 ) {	
		my $path = $self -> {'path'};
		if( ! defined $val ) {
			print "PUT: $path $key (val = undef)\n"; 
		}	
		print "PUT: $path $key $val\n"; 
	}	

	return $self;
}

sub del
{
	my $self = shift;	

	my $key = shift;
	$self -> {'db_handle'} -> del($key);
	
	if( $::DBG > 5 ) {	
		my $path = $self -> {'path'};
		print "DEL: $path $key\n";
	}
	
	return $self;
}

1;
