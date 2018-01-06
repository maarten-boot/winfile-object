#! /usr/bin/perl -w

use warnings;
use strict;

$::DBG = 0;
$::VERBOSE = 1;

use lib './lib';
use aApp;

# ==============
package ThisApp;

@ThisApp::ISA = ( 'aApp' );

use aMachine;

sub start 
{
	my $class = shift;
	my $name = shift;

	my $self = aApp -> start("$name");

	my $machine = $self -> {'machine'}  = aMachine -> new();
	$self -> {'os'} = $machine -> get_os();

	return $self;
}

# ============
package main;

use aDB;

sub must_exist
{
	my $key = shift;

	# there must be if the refount exists so we die if we dont find a block of data

	my $value;
	my $st = $::BLOCKS -> select_first($key, $value);
	if( $st != 0 ) {
		die "FATAL: $key must exist in BLOCKS";	
	}

	# we return a reference to the data block as to avoid copying
	return \$value;
}

sub block_check
{
	my $digest = shift;

	# data blocks have a direst as key and the compressed block as data
	# the allways also have a refcount part that maches the digest

	# so we check for refcount >= 1 first
	# and then see if there is a corresponding data block
	# there must be if the refount exists so we die if we dont find a block of data
	
	my $p_key = $digest;
	my $full_key = $p_key;
	my $value = undef;;
	
	my $n = 0;
	my $st = $::REFCOUNT -> select_first($full_key, $value);
	while( $st == 0) {
		last if( index($full_key,$p_key) == -1 );
		print "\t\t\t$full_key $value\n";
		my $data_ref = must_exist($full_key);
		
		# here we can decompress the block and possibly write it back to the filesystem 
		# with a relocation of the data as not to overwrite any existing file.
		
		# uncompress 
		# write

		$st = $::REFCOUNT -> select_next($full_key, $value);
		$n ++;
	}
	return $n;
}

sub file_check
{
	my $file = shift;


	# to get to the guts of the file we have to investigate the datablocks
	# so we see if this file has any datablocks stored
	# empty files (length = 0 ) do not have data blocks
	# so we have all information in the path and attributes already
	
	my $p_key = $file;
	my $full_key = $p_key;
	my $value = undef;;

	my $n = 0;
	my $st = $::FILES -> select_first($full_key, $value);
	while( $st == 0) {
		last if( index($full_key,$p_key) == -1 );
		print "\t\t$full_key\n";
		block_check($value);
		$st = $::FILES -> select_next($full_key, $value);
		$n ++;
	}
	return $n;
}
		
sub path_check
{
	my $path_id = shift;
	my $path = shift;

	# extract the attributes of all items in the given path 
	my $p_key = $path_id;
	my $full_key = $p_key;
	my $value = undef;;
	
	my $st = $::ATTRIBUTES -> select_first($full_key, $value);
	while( $st == 0) {
		
		# print "$full_key,$p_key\n";
		last if( index($full_key,$p_key) == -1 );

		# note thet the key of the items (attributes) database is actually
		# made up of $dir_id\000$item_name\000$type 
		# where the dir_id is acttually \000$volume\000$number
		# but the file database has a key $dir_id\000$filename 
		# so we need to cut off the type for the next level
		
		my @a = split(/\000/,$full_key);
		my $attrs = $value;
		
		#print "0: (empty) " ,$a[0], "\n";
		#print "1: volume " ,$a[1], "\n";
		#print "2: dir-id " ,$a[2], "\n";
		#print "3: item-name " ,$a[3], "\n";
		#print "4: type " ,$a[4], "\n";

		if( $a[4] eq "FILE:" ) {
			# for file types we have to dig deeper in the databases to retreive the information
			# of the file itself
		
			# relocate and open file
			print "\tFILE: $path/$a[3]\n";
			my $file_start = "$a[0]\000$a[1]\000$a[2]\000$a[3]";
			file_check($file_start);
		}

		# for DIR type we are ready al all information (path + attributes is already here)
		if( $a[4] eq "DIR:" ) {
			print "\tDIR: $path/$a[3]\n";
		}

		$st = $::ATTRIBUTES -> select_next($full_key, $value);
	}
}

sub volume_check
{
	my $volume = shift;

	# get all the paths ( = directories ) from the given volume	

	my $p_key = $volume;
	my $full_key = $p_key;
	my $value = undef;;
	my $st = $::DIRS -> select_first($full_key, $value);
	while( $st == 0) {
		last if( index($full_key,$p_key) == -1 );

		print "PATH: $full_key,$value\n";
		path_check($value,$full_key);
		$st = $::DIRS -> select_next($full_key, $value);
	}
}

# @@ MAIN
{
	$::THISAPP = ThisApp -> start("winfile");
	print STDERR "START " . scalar localtime(time) . "\n";

	# create a context that automatically closes the databases if they get out of scope
	{
		$::GENSYM 		= aDB -> new("GENSYM.DB");
		$::VOLUMES 		= aDB -> new("VOLUMES.DB");
		$::DIRS 		= aDB -> new("DIRS.DB");
		$::ATTRIBUTES 	= aDB -> new("ATTRIBUTES.DB");
		$::FILES		= aDB -> new("FILES.DB");
		$::BLOCKS		= aDB -> new("BLOCKS.DB");
		$::REFCOUNT		= aDB -> new("REFCOUNT.DB");

		my $p_key = "";

  		my $full_key = $p_key;
  		my $value = undef;;	

		# get all the volumes from the backup database
		my $st = $::VOLUMES -> select_first($full_key, $value);
		while( $st == 0) {

			print "I see a volume: $full_key lets check this volume\n\n";			
			volume_check($full_key);
			$st = $::VOLUMES -> select_next($full_key, $value);
		}
	}	

	print STDERR "END " . scalar localtime(time) . "\n";
 	$::THISAPP -> finish();
}


__DATA__

the restore must be able to do:

restore (list of files) into path (overwrite)
restore (list of dirs) into path (recursive) (overwrite)
restore (list of voulmes) into path (recursive) (overwrite)

this can be started from a separate GUI window
