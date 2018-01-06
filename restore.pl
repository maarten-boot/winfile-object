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

my $winfile = $ENV{'WINFILE'};
my $relocate = "$winfile/RELOCATE";

sub file_check
{
	my $path = shift;

	my $vol = shift;
	my $dir_id = shift;
	my $name = shift;
	
	print "RECOVER: $path, $vol, $dir_id, $name\n";
	
	#print "1: volume " ,$a[1], "\n";
	#print "2: dir-id " ,$a[2], "\n";
	#print "3: item-name " ,$a[3], "\n";

	my $file_key = "\000" . join("\000",( $vol,$dir_id,$name));

	# to get to the guts of the file we have to investigate the datablocks
	# so we see if this file has any datablocks stored
	# empty files (length = 0 ) do not have data blocks
	# so we have all information in the path and attributes already
	
	my $p_key = $file_key;
	my $full_key = $p_key;
	my $value = undef;;

	my $n = 0;
	my $st = $::FILES -> select_first($full_key, $value);

	my $blocksize;
	use Fcntl;
	
	my $fh = undef;
	my $r = sysopen $fh,$path,O_CREAT|O_RDWR or 
		die "FATAL: cannot open '$path', $!";
	
	die "FATAL: no valid file discriptor '$path', $!" unless defined $fh;
	
	while( $st == 0) {
		# we look for the block numbers that make up the file here

		last if( index($full_key,$p_key) == -1 );
	
		my @a = split(/\000/, $full_key);
		my %b = split(/\000/,$value);
		
		$blocksize = $b{'Size'};
		my $block_nr = hex($a[4]);

		my $offset = $blocksize * $block_nr;
		print "\toffset: $offset ($a[4],$b{'Size'})\n";
		$r = seek $fh , $offset , 0 or
			die "FATAL: cannot seek '$path' offset $offset, $!";

		{
			my $block = aBlock -> FindMyBlock($value);

			# from syswrite explanation in perl book
			# handle partial writes
			my $len = $block -> length();
			my $data = $block -> data();
			
			my $off = 0;
			my $written = undef;
			while($len) {
				$written = syswrite($fh, $data, $len,$off);
				die "Fatal: '$path' syswrite error at offset $offset: $!\n" unless defined $written;
				$len -= $written;
				$off += $written;
			}
		}
		$st = $::FILES -> select_next($full_key, $value);
		$n ++;
	}
	
	$r = close $fh;
	
	return $n;
}

sub _file_open_r($)
{
	my $path = shift;
	
	my $fh;
	if(! sysopen($fh, $path, O_RDONLY ) ) {
		print "SKIP: cannot open '$path' in read only mode,$!\n";
		return undef;
	}
	if( ! defined $fh ) { return undef; }
	
	binmode($fh);	
	return $fh;
}

sub _file_md5
{
	my $file = shift;

	use Digest::MD5;    
	
	my $fh = _file_open_r($file);
	if( ! defined $fh ) {
		print STDERR "Can't open '$file': $!";
		return '';
	}
    return Digest::MD5->new->addfile($fh)->hexdigest;
}	
		
sub VERIFY_ME
{
	my $org = shift;
	my $new = shift;
	
	print "VERIFY $org $new\n";
	if( -f $org && -f $new ) {
		
		my $m1 = _file_md5($org);
		my $m2 = _file_md5($new);
		
		print "\tMD5_org: $m1\n";
		print "\tMD5_new: $m2\n";

		if ( $m1 ne $m2 ) {
			printf "MD5 NOT EQUAL: $org , $new\n";
			printf STDERR "MD5 NOT EQUAL: $org , $new\n";
		}
	}
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
		last if( index($full_key,$p_key) == -1 );

		# the attributes of the item we will need later TODO:
		my $attributes = $value;

		# copy the path into a new variable so we can do the relocation proper
		# we need the original path for verification
		
		my $p = $path;

		# note thet the key of the items (db_attributes) database is actually
		# made up of $dir_id\000$item_name\000$type 
		# where the dir_id is acttually \000$volume\000$number
		# but the file database has a key $dir_id\000$filename 
		# so we need to cut off the type for the next level
		
		my @a = split(/\000/,$full_key);
		
		#print "0: (empty) " ,$a[0], "\n";
		#print "1: volume " ,$a[1], "\n";
		#print "2: dir-id " ,$a[2], "\n";
		#print "3: item-name " ,$a[3], "\n";
		#print "4: type " ,$a[4], "\n";

		if( $a[4] eq "FILE:" ) {
			# for file types we have to dig deeper in the databases to retreive the information
			# of the file itself
		
			# the original path (the path we ran the backup with)
			my $p1 = "$p/$a[3]";

			# take out drive letters under Windows so we can relocate to a normal directory
			# this maps C:\/ABC/DEF to C/ABC/DEF
			
			$p =~ s/:\\?//;
			$p =~ s/\/\//\//;

			# now connect the relocate string to the cleaned original path
			# now C/ABC/DEF becomes: L:/NEWDIR/C/ABC/DEF
			
			my $p2 = "$relocate/$p/$a[3]";

			# REPORT PROGRESS AND INFORM WHAT WE ARE DOING
			print "FILE: ", $p1 , "\n";
			print "   -> ", $p2 , "\n";
	
			# try to recover the file data from the database
			# do not set the attributes and owner yet
			# just default mode and current user/group
			
			file_check($p2,$a[1],$a[2],$a[3]);
		
			# verify the file by calculating an md5 over the entire file 
			# both the original and the recovered one
			# complauin if they do not match
			
			VERIFY_ME($p1,$p2);
		}

		# for DIR type we have allready all information (path + attributes is already here)
		if( $a[4] eq "DIR:" ) {
			
			# take out drive letters under Windows so we can relocate to a normal directory
			# this maps C:\/ABC/DEF to C/ABC/DEF

			$p =~ s/:\\?//;
			$p =~ s/\/\//\//;

			my $p2 = "$relocate/$p/$a[3]";
			unless ( -d $p2 ) {
				mkdir $p2 || die "FATAL: cannot make dir: $p2,$!";
	
				# REPORT PROGRESS AND INFORM WHAT WE ARE DOING			
				print "\tMKDIR: $p2\n";
			}
		}
		# update attributes on the new item $p2 , $attributes
		# this creates a window between the original rights of the backup 
		# and the system rights that we are restoring with
		
		my $p2 = "$relocate/$p/$a[3]";
	
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

		# print "PATH: $full_key,$value\n";
		path_check($value,$full_key);
		$st = $::DIRS -> select_next($full_key, $value);
	}
}

# @@ MAIN
{
	$::THISAPP = ThisApp -> start("winfile");
	print STDERR "START " . scalar localtime(time) . "\n";

	if( ! defined $relocate || ! $relocate ) {
		print STDERR "Fatal: must have a location to restore to!";
		exit;
	}
	
	if( ! -d $relocate ) {
		mkdir $relocate 
	}

	print "RELOCATE to $relocate\n";
	
	# create a context that automatically closes the databases if they get out of scope
	{
		# $::GENSYM 		= aDB -> new("GENSYM.DB");
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
