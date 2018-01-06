# =======================================================
# BACKUP A FILE
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

use Fcntl;

sub open_file_read_only($)
{
	my $fullpath = shift;

	my $fh = undef;

	if(! sysopen($fh, $fullpath, O_RDONLY ) ) {
		warn "SKIP: cannot open $fullpath in read only mode,$!";
		return undef;
	}

	if( ! defined $fh ) {
		return undef;
	}

	binmode($fh);

	return $fh;
}

sub del_old_blocks($$$)
{
	my $dir_id = shift;
	my $name = shift;
	my $block_nr = shift;

	# blocks from this file ($dir_id,$name)
	# starting at $block_nr
	# till the last block_nr can be deleted

	my $b_hex = sprintf "%08x" , $block_nr;
	my $this_file = "$dir_id\000$name";
	my $curr_key = "$this_file\000$b_hex";

	my $r = db_data_blocks();
	my $val;
	my $st = $r -> seq($curr_key,$val,R_CURSOR);

	while( $st == 0 ) {
		my($id,$n,$b) = split(/\000/,$curr_key);
		last unless ($this_file eq "$id\000$n");

		log_msg "DELETE BLOCK: $curr_key";
		db_data_blocks_del($curr_key);

		$st = $r -> seq($curr_key,$val,R_NEXT);
	}
}

sub make_digest($)
{
	# arg 1 = data
	my $d = $_[0];

	use Digest::MD5;
	my $md5_context = new Digest::MD5;
	$md5_context -> add($d);
	my $md5 = $md5_context -> hexdigest;

	use Digest::SHA1;
	my $sha1_context = new Digest::SHA1;
	$sha1_context -> add($d);
	my $sha1 = $sha1_context -> hexdigest;

	return "$md5\000$sha1";
}

sub do_one_file ($$$$)
{
	my $dir_id = shift;
	my $name = shift;
	my $type = shift;
	my $new_item = shift;

	my $fh = open_file_read_only($name);
	return 0 unless defined $fh;

	my $block_nr = 0;

	my $data;
	while( my $len = sysread($fh,$data,$::BLOCKSIZE)) {
		if(!defined $len ) {
			# do partial read
			next if $! =~ /^Interrupted/;
			die "FATAL: sysread error: $!";
		}

		# I HAVE A BLOCK, compose a key
		my $b_hex = sprintf "%08x" , $block_nr;
		my $block_id = "$dir_id\000$name\000$b_hex";

		# Calculate a MD5 Digest and SHA1 on this block;
		my $digest = make_digest($data);
		my $old_digest = db_data_md5_get($block_id);
		my $this_block_changed = 0;

		# and see if the block changed (or maybe the block is new)
		if(( !defined $old_digest) || ( $old_digest ne $digest )) {
			$this_block_changed = 1;
		}

		if( $this_block_changed ) {
			# update the block if changed
			update_block($digest,$data);
			# and then set the new digest of this block
			db_data_md5_set($block_id,$digest);
		}

		# then go to the next block
		$block_nr ++;
	}

	# POST BLOCK =======================================================
	
	# when the file is has been scanned totally, close the read filehandle
	close $fh || die "cannot close read only filehandle (fh = $fh),$!";

	# the last block of this file is:
	my $b_hex = sprintf "%08x" , $block_nr;

	# REMOVE REMAINING BLOCKS from a previous version of this file
	# with curent block nr delete this and more blocks
	# del_old_blocks(	$dir_id,$name,$block_nr) unless $new_item;
	# and so also decr_refcount

	# This returns the amount of blocks stored so
	# always one higher than the block_nr in the key

	return $block_nr;
}

# ===============================================================
1;
