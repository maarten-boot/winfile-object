# =======================================================
# BACKUP A ITEM
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

sub item_has_changed($$)
{
	my $key = shift;
	my $attrs = shift;

	my $item = db_attributes_get($key);

	# as we are checking a item it can be removed from the history
	db_history_del($key);

	if(!defined $item ) {
		db_attributes_set($key,$attrs);
		log_msg "NEW ITEM: $key";
		return 2;
	}

	if($item ne $attrs) {
		db_attributes_set($key,$attrs);
		log_msg "ATTRS CHANGED: $key";
		return 1;
	}

	# they are equal , no change
	return 0;
}

use File::Find;
use Storable;

sub pre_file ()
{

}

sub post_file ()
{

}

sub process_item
{
	# REMEMBER: we have done a chdir to $dirname already
	# so stat($basename) is possible without a full path

	my $basename = $_;

	# POSIX ATTRIBUTES
	my ($dev,
		$ino,$mode,$nlink,
		$uid,$gid,
		$rdev,$size,
		$atime,$mtime,$ctime,
		$blksize,$blocks) = stat($basename);

	my $dirname = $File::Find::dir;
	my $fullpath = $File::Find::name;

	my $type = undef;
	{
		# DIRECTORIES
		if ( -d ) {	$type = "DIR:";	$::DIRS++;	}
	
		# NORMAL FILES
		if( -f ) { $type = "FILE:"; $::FILES++;	}
	
			# for now we only process FILES and DIRECTORIES
		return unless ( -d || -f );
	}
	
	my $dir_id = db_directories_name2id($dirname);
	
	#======================================================
	# ATTRIBUTES

	my $att = w32_fileatt_get($basename);
	my $acl = "";
	if( $::WITH_ACL && $::FS_TYPE eq "NTFS") {
		$acl = w32_dacl_get($basename);
	}

	my $sig = "$size,$mtime,$ctime,$uid,$gid,$mode";
	my %attrs = (
		'acl'=> $acl,
		'att'=> $att,
		'sig'=> $sig,
	);

	# ====================================================
	# KEY TO LOOKUP ATTRIBUTE CHANGES

	my $new_item = 0;
	my $key = "$dir_id\000$basename\000$type";
	my $ret = item_has_changed($key,Storable::nfreeze \%attrs);
	if( $ret == 0) {
		return undef;
	}

	if( $ret == 2 ) {
		$new_item = 1;
	}

	# =============================================================
	# IF IT IS A DIR WE ARE READY (having stored all attributes already)

	return undef if ( -d );

	# =============================================================
	# START PROCESSING THE DATA
	my $last_block = do_one_file($dir_id,$basename,$type,$new_item);

	# =============================================================
	# SEE IF THE FILE CHANGED DURING BACKUP
	my ($p_dev,$p_ino,
		$p_mode,$p_nlink,
		$p_uid,$p_gid,
		$p_rdev,$p_size,
		$p_atime,$p_mtime,$p_ctime,
		$p_blksize,$p_blocks) = stat($basename);

	if( $size != $p_size ) {
		log_msg "WARN: '$fullpath' size changed from $size to $p_size during backup";
	}

	if( $mtime != $p_mtime ) {
		log_msg "WARN: '$fullpath' mtime changed from $mtime to $p_mtime during backup";
	}
	# set this item to suspect

	log_msg "";

	return undef;
}

# ===============================================================
1;
