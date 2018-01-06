use warnings;
use strict;

# =======================================================
# aVolume, we process data by volumes at a time
# =======================================================
=pod

The volume will walk the tree of directories and 
for each item in a directory will try to backup that item.

=cut
# =======================================================

use lib './lib';
use aApp;

package aVolume;

use aDB;
use aGensym;
use aItem;

my %fields = (
	# what is the name of the volume
	'name' => undef,

	# what is the volume id ( we need this to detect if we are still in this voulme
	# after each chdir when we walk the tree
	'volume_id' => undef,

	# what is its type (FAT, NTFS, ext3, reiser, ...)
	'type' => undef,

	# what attributes does this volume has, does it do acl?
	'vol-attrs' => undef,
	'has-acl?' => undef,

	# we store some properties of this volume so we can use them for verification and restore
	'vol-db' => undef,

	# remember the current path and id while we walk the volume
	'cur-path' => undef,
	
	# what OS are we running on
	'os' => undef,

	# how can we find the dir2id database
	'dir2id-db' => undef,

	# the interface to the gensym handler which needs the volume name to generate the gensym key from
	'gensym' => undef,
);

# =======================================================

sub new 
{
	my $class = shift;
	my $volume = {
		%fields,
	};
	bless $volume , $class;

	my $path = $volume -> {'name'} = shift;
	my $os = $volume -> {'os'} = shift;

	my $type = $volume -> {'type'} = $os -> get_filesystem_type($path);
	my $vol_attrs = $volume -> {'vol-attrs'} = $os -> get_filesystem_attrs($path);

	my @a = lstat($path);
	$volume -> {'volume_id'} = $a[0];

	{
		my $n1 = 'VOLUMES.DB';
		my $n2 = 'vol-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$volume -> {$n2} = $db;
		} else {
			$db = $volume -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	$volume -> _store();

	{
		my $n1 = 'DIRS.DB';
		my $n2 = 'dir2id-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$volume -> {$n2} = $db;
		} else {
			$db = $volume -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	$volume -> {'gensym'} = aGensym -> new($path);

	print "
=========================
VOLUME PATH: $path
VOLUME TYPE: $type
VOLUME ATTRS: $vol_attrs
=========================
" if $::DBG;

	return $volume;
}

# ===============================================================

sub _store
{
	my $volume = shift;

	my %vol;
	my $name = $volume -> {'name'};

	$vol{$name} -> {'attrs'} = $volume -> {'vol-attrs'};
	$vol{$name} -> {'type'} = $volume -> {'type'};

	use Storable;
	my $serialize = &Storable::nfreeze(\%vol) ;

	my $db = $volume -> get_vol_db();
	
	$db -> put($name,$serialize);
}

sub recall
{
	my $volume = shift;
	my $name = shift;
	
	my $db = $volume -> get_vol_db();
	my $serialized = $db -> get($name);

	use Storable;
	my %vol = &Storable::thaw($serialized);

	return %vol;	
}

# ===============================================================

sub get_vol_id
{
	my $volume = shift;
	return $volume -> {'volume_id'};
}

sub get_dir2id_db
{
	my $volume = shift;
	return $volume -> {'dir2id-db'};
}

sub get_vol_db
{
	my $volume = shift;
	return $volume -> {'vol-db'};
}

sub dir2id ($)
{
	my $volume = shift;
	
	# Map a directory name into an id for faster lookup and more efficient storage
	# gensym(key) will create the next key to use for this path 
	
	my $fullpath = shift;

	my $db = $volume -> get_dir2id_db();
	my $dir_id = $db -> get($fullpath);

	if(defined $dir_id) {
		print "$fullpath maps to $dir_id (seen before)\n" if $::DBG;
		return $dir_id;
	}

	# we have an item that is not yet stored in the database 
	# so we have to store it now
	
	# get the nest id from the gensym generator
	$dir_id = $volume -> {'gensym'} -> next();
	
	# put path -> id mapping in the database
	$db -> put($fullpath,$dir_id);
	
	# ALSO PUT REVERSE map in the database
	# so we can lookup id -> path
	
	$db -> put($dir_id,$fullpath);

	print "$fullpath maps to $dir_id (new)\n" if $::DBG;
	
	return $dir_id;
}

# =======================================================

sub backup
{
	my $volume = shift;
	my $path = shift;

	$volume -> dir2id($path);
	$volume -> _process($path)
}

use File::Find;

# Filtering is done at the volume level.
# Before we make the list of items to process at this directory level we apply a filter
# any item that should not be in this backup session 
# must be filterd out from the list of items at this level.
# so before we process each item separately

sub _dir_pre
{
	my $volume = shift;

	if( $::DBG ) {
		my $dir = $File::Find::dir;
		print "_dir_pre: $dir\n";
	}
	
	my @out;

	my $dirname = $File::Find::dir;
	$volume -> {'cur-path'} = $dirname;

	print "ENTER: $dirname\n" if $::VERBOSE;
	
	# here on this level is an explicit mapping done 
 	my $dir_id = $volume -> dir2id($dirname);	

	# any pre-processing before we acually enter the item is done here
	# the list in @_ is filterd for patterns and
	# a new list is build

	# we can implement filters that skip based on regex match 
	# or anchored at the end for extensions that we want to skip
	# todo: filter plugin and external file load like e.g. .nsr in legato networker	
	
	loop1: 
	for my $item (sort @_) {
		$_ = $item;
		
		# FILTER HERE
		if( 
			# item ISDIR AND ...
			( -d $_ && 
				(
					/^Temporary Internet Files$/i ||
					/^System Volume Information$/i ||
					/^recycler$/i ||
					/^temp$/i ||
					/^tmp$/i 
				)
			) ||
			# item ISFILE and ...
			( -f $_ &&
				( 
					/^hiberfil\.sys$/i ||
					/^pagefile\.sys$/i ||
					/\.tmp$/i ||
					/\.log$/i 
				)
			)
		) {
			print "FILTER SKIP: $item\n" if $::VERBOSE;
			next;
		}
	
		push(@out,$item);
	}
	
	return @out;
}

sub _item_each 
{
	my $volume = shift;

	# what do we get from FILE::Find
	my $basename = $_;
	my $fullpath = $File::Find::name;
	my $dirname = $File::Find::dir;

	if( $::DBG ) {
		print "_item_each: $fullpath\n";
	}

	# =============================================================	
	# here we are procesing items.
	# items can be regular files or dirs or symlinks (under posix) 
	# other types of items are also possible but not yet supported
	
	# lstat($basename) is possible without a full path
	# as we have done a chdir by using the defaults of File::Find
		
	# first we will get the posix attributes	
	# ( always stat the item itself not the data it might point to if a symlink)

	my ($dev,
		$ino,$mode,$nlink,
		$uid,$gid,
		$rdev,$size,
		$atime,$mtime,$ctime,
		$blksize,$blocks) = lstat($basename);

	# using the volume part of the posix attributes we can determine 
	# if we are by any chance in a different volume as where we started from
	# (that can happen because of nfs-mounts or device-mounts inside the tree we are walking)
	# symlinks should not cause this as we will read the data of the symlink and 
	# not the item it is pointing to (CURRENTLY NO SUPPORT FOR SYMLINKS)
	# TODO: SYMLINK
	
	# note also that nlink is not checked currently, so hardlinks are not supported 
	# on restore. the backup will discover that it already has all the data of the file but 
	# not that it is a hard linked file or even a hard liked directory
	# TODO: hardlinks
	
	# ARE WE STILL IN THE ORIGINAL VOLUME ?
	my $v = $volume -> get_vol_id();
	if( $dev != $v ) {
		# if we are outside the starting volume we prune the tree at this point using the
		# prune flag inside the File::Find module
		# as we return the master function (process) will see that it has to skip this item.

		$File::Find::prune = 1;
		print "PRUNING: (no longer in current volume): $fullpath:$dev:$v\n" if $::DBG;
		return;
	}
	
	# lets find out what type of item we have here
	my $type = undef;
	
	if ( -d ) {	
		$type = "DIR:";	
	} elsif( -f ) { 
		$type = "FILE:"; 
	}
	# elsif( -l ) { $type = "LINK:"; }

	# Currently we skip anything that is not a FILE or a DIR
	if( ! defined $type ) {
		print "SKIP: $fullpath, it is not a file or a dir\n";
		return undef;
	}
	
	print "\t$type $fullpath \n" if $::DBG;

	# now that we have someting to do create a new item object to record and store 
	# attributes that all items have in common
	
	my $item = aItem -> new();
	
	my $dir_id = $volume -> dir2id($dirname);	

	# create a condensed signature of this item.
	# this will make it easy to see any change in the attributes 
	# by doing a simple string-compare

	# TODO: separate meta attributes only change from mtime change
	# that way we can do a fast check if we only need to update the meta data
	# size is a double check on mtime as theoretical size cannot change without mtime also
	# however you can cheat somewhere allways
	
	# the sig must have mtime as that signifies a very likely change 
	# but is also shows any user or group change 
	my $sig1 = "$size,$mtime";
	my $sig2 = "$ctime,$uid,$gid,$mode";
	my $sig = "$sig1,$sig2";

	# find out if we already have a dir mapping (the top path gets the dir mapping elswhere)
	# TODO: explain that
	# and create one if it does not exist yet
	
	# ask the os for any other attributes that this item might have.
	# Win32 attributes would show up here but not yet any acls they are mapped separatly
	# for posix that would amount for the ones we alredy have
	
	my $att = $volume -> {'os'}  -> get_path_attrs($basename);
		
	# acl is by default empty ,
	my $acl = "";	
=pod
	# but if this volume supports acl, we can ask the os to get the acls for this item 
	# so we can then store it for recovery or detection of meta data changes
	if( $volume -> has_acl() ) {
		$acl = get_path_acl($basename);	
	}
=cut
	# we need to serialize all the collected meta data in a way that it 
	# can be stored and compared deterministically yet still be read back into a hash 
	# hence a array here and later when we read it back we can read it into a proper hash
	# an @array with an even amount of elements can still be assigned into an %hash

	# collect al the attrs now, properly labeled
	my @attrs = ('sig',$sig,'att',$att,'acl',$acl);

	# and prepare them for efficient storage 
	use Storable;
	my $serialize = Storable::nfreeze \@attrs;
	
	# the attribute database will store the attributes only of this item
	# for that we need a proper key that is unique all the possible filesystems of this machine
	# we will always store this table on a machine basis so the hostname is not needed here
		
	my $key = $item -> make_key($dir_id,$basename,$type);	
		
	# as we have now all the meta data complete we can store it in the attributes database
	# we will now test against a (possible) previous value 
	# if there were any changes in the meta data

	my $ret = $item -> has_changed($key,$serialize);
	
	# if the meta data did not change at-all we conclude that 
	# we can skip any further processing of this item 
	# N.B. if it is a new item we will not get 0 here

	if( $ret == 0) { 
		return;
	}
	
	# this completes the meta data part and  
	# for direcrtory items that means we are ready so we say goodbye  
	if ( -d ) {
		return;
	}

	# for FILE items (that have changed or are new) 
	# we will have to investigate the actual data in more detail

	$item -> do_one_file($dir_id,$basename,$type);

	# after the backup we will do a stat again to double check that 
	# the item (file) did not change during backup
	# if either the size or the mtime changed between the start of the backup and now 
	# we will flag this item as supect so we get that in a report or 
	# we can get a warning during restore if we want to
	
	# ( always stat the item itself not the data it might point to if a symlink)
	my ($p_dev,$p_ino,
		$p_mode,$p_nlink,
		$p_uid,$p_gid,
		$p_rdev,$p_size,
		$p_atime,$p_mtime,$p_ctime,
		$p_blksize,$p_blocks) = lstat($basename);

	my $suspect = 0;
	if( $size != $p_size ) {
		$suspect = 1;
		print "WARN: '$fullpath' size changed from $size to $p_size during backup";
	}

	if( $mtime != $p_mtime ) {
		$suspect = 1;
		print "WARN: '$fullpath' mtime changed from $mtime to $p_mtime during backup";
	}

	if( $suspect ) {
		$item ->suspect();
	}
	
	return;
}

sub _dir_post 
{
	my $volume = shift;

	if( $::DBG ) {
		my $dir = $File::Find::dir;
		print "_dir_post: $dir\n";
	}

	my $dir = $File::Find::dir;
	
	opendir(DIR,$dir) || die "FATAL: cannot open dir: $dir,$!\n";
	my @list = readdir DIR;
	closedir DIR;
	
	# print join(',',@list) , "\n";
	
	#  at the end of each directory processing we have still to detect what items have been removed
	# between the last backup run of this directory and now
	# any item that is currently missing at this level can be scheduled for removal 
	# how to figure out what has been removed

	print 'Leaving dir: ', $dir,"\n" if $::VERBOSE;
}

sub _process
{

# this is the main interface to FILE::Find 
# we use the explicit interface with pre and post processing
# we do not follw symlinks
# and inside the item_each we will test if we are still inside the current volume
# we will not cross filesystem boundaries currently
# under unix this means that when processing / 
# we do not walk into /usr or /var if that is a separate volume/filesystem
# TODO: test on W2k and above with mounted volumes on a path instead of a drive letter

	my $volume = shift;
	my $path = shift;
	
	# WALK THE VOLUME AND PROCESS IT
	find( 
		{ 
			preprocess 	=> sub { 
				$volume -> _dir_pre(@_) 
			},
			wanted 		=> sub { 
				$volume -> _item_each(@_) 
			},
			postprocess => sub { 
				$volume -> _dir_post(@_) 
			},
			follow 		=> 0 , 
		}, 
		$path,
	);
}

1;
