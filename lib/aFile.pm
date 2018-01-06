use warnings;
use strict;

use lib './lib';
use aApp;

# =============================
package aFile;
# =============================

my %fields = (
	'fh' => undef,
	'dir' => undef,
	'id' => undef,
	'name' => undef,
	'block#' => undef,
	'files-db' => undef,
);

# =============================
use aBlock;

use Fcntl;

sub new
{
	my $class = shift;
	my $file = {
		%fields,
	};	
	bless $file , $class;

	# ======================================
	# this database stores 
	#
	#	$dir2id,$filename,$blocknr -> digest
	#	other databases will store the actual data 
	#
	{
		my $n1 = 'FILES.DB';
		my $n2 = 'files-db';

		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$file -> {$n2} = $db;
		} else {
			$db = $file -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	return $file;
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

sub open_read_only
{
	my $class = shift;
	my $file = new($class);
	
	# directory(id)
	my $dir_id = shift;
	$file -> {'dir_id'} = $dir_id;

	# name of the file
	my $name = shift;	
	$file -> {'name'} = $name;
	
	my $fh = _file_open_r($name);	
	return undef unless $fh;

	$file -> {'fh'} = $fh;	

	return $file;
}

sub _get_db
{
	my $file = shift;
	return $file -> {'files-db'};
}

sub _get_old_digest
{
	my $file = shift;

	my $key = shift;
	my $db = $file -> _get_db();
	my $val = $db -> get($key);

	return $val;
}

sub _set_new_digest
{
	my $file = shift;
	
	my $key = shift;
	my $val = shift;
	my $db = $file -> _get_db();

	$db -> put($key,$val);
}

sub make_key
{
	my $dir_id = shift;
	my $name = shift;
	my $block_nr = shift;
		
	my $nr = sprintf "%08x" , $block_nr;

	# TODO: use pack and use 64 bit sequence numbers as
	# currently with blocks of 64k and 0x8 we are on 48 bits of file-size 
	# with 2k blocks that is 31 + 11 bits = 43 bits file size
	

	# my $x = pack "axaN" , 
	
	return join("\000", ( $dir_id,$name,$nr));
}

sub file_backup
{
	my $file = shift;

	my $dir_id = $file -> {'dir_id'};
	my $name = $file -> {'name'};

	print "\t$dir_id,$name\n";
	# the block counter , which is part of the key for looking up the data of this file
	# the file offset to read this block would be: block_nr * block_size 
	# block_ starts at  offset 0 (zero)
	
	my $block_nr = 0;

	while(1) {
		# read one block from the filehandle
		my $block = aBlock -> read1block($file -> {'fh'});

		# if the block has zero length there is 
		# nothing to do further down so we quit here
		# we also make sure that block-nr is now set to 
		# the last successfull block that got anything back
		# ( BLOCKLEN or less but not zero )
		my $len = $block -> get_len();		
		if( $len == 0 ) {
			$block_nr --;
			last;
		}

		# we have some data so calculate a digest over the data of the block
		my $digest = $block -> make_digest();
		print "digest: $digest\n" if $::DBG;
		
		# compose the key for this block for later use
		my $key = make_key($dir_id,$name,$block_nr);
		print "key: $key\n" if $::DBG;
		
		# check if there is a old_digest for this block 
		my $db = $file -> _get_db();
		my $old_digest = $file -> _get_old_digest($key);
		print "old_digest: $old_digest\n" if defined $old_digest && $::DBG;
		
		# is it new or it changed then we have do something
		my $changed = 0;
		if( ! defined $old_digest ) {
			$changed = 1;	# a new block
		} elsif ( $old_digest ne $digest ) {
			$changed = 2;	# a changed block
		}
		
		if( $changed ) {
			print "\t\t$changed block: $block_nr len: $len\n" if $::VERBOSE;

			# it changed so we have to update our database 
			$file -> _set_new_digest($key,$digest);
		
			# and the data itself has to be stored also 
			$block -> update();
			
			# if we have an changed block (s0 we had another block before ) 
			# we have to delete that old block here as this file does not need it any more
			if( $changed == 2 ) {
				$block -> discard_block($old_digest);
			}
		}

		# increase the block number and try again
		$block_nr ++;
	}

	$file -> shorten($dir_id,$name,$block_nr);

	return $block_nr;
}

sub shorten
{
	my $file = shift;	

	my $dir_id = shift;
	my $name = shift;
	my $block_nr = shift;

	# at the end of the file we must now check 
	# if the FILES database has extra blocks still in the database for this file
	# this could be the case if the files has shrunk since the last backup run.
	# 

	# the full key is the next possible block that could be in the database
	my $full_key = make_key($dir_id,$name,$block_nr + 1);

	# the partial key identifies this file, 
	# so the dir-id and the name but not the number part
	my $p_key = join("\000", ( $dir_id,$name));
	

	# we are not interseted yet in the value 

	# later we will decrement the refcount of any digest found  

	my $value = undef;
		
	my $db = $file -> _get_db();

	# see if there is any block in the database belonging to this file 
	# but past the current length of the file as it is at this moment
	# this could be the case if the file got shorter or got rewritten to a shorter length
	# than since the last backup run
	my $st = $db -> select_first($full_key, $value);
	while( $st == 0) {
		# if the posiotioning of the cursor succeeded we have to look now
		# if we are still in this file, so we compare the partial key ( directory-id + name )
		# to the data found 
		last if( index($full_key,$p_key) == -1 );
		
		# we are now sure that we are still in the file searched for 
		# and that we have a block that must be removed 

		print "EXESS BLOCK FOUND\t\t$full_key $value\n" if $::VERBOSE;

		# TODO: dependancy between refcount an blocks 		
		# lets only decrement the refcount, a later vacuum process will actually remove the data
		# this makes sure that if during backup we do see the data already we have the block still in the database

		my $block = aBlock -> lazy_delete($value);
		$st = $db -> select_next($full_key, $value);
	}
}

# =======================================================================

sub _open_file_write($$)
{
	my $path = shift;
	my $mode = shift;

	my $fh = undef;

	use Fcntl;

	if ( -f $path ) {
		print "WARN: Overwriting $path\n";
		if(!sysopen($fh, $path, O_RDWR ) ) {
			print "FATAL: cannot open $path mode $mode in O_RDWR mode,$!\n";
			return undef;
		}
	} else {
		if(!sysopen($fh, $path, O_CREAT | O_RDWR ) ) {
			print "FATAL: cannot open $path mode $mode in O_CREAT mode,$!\n";
			return undef;
		}
	}
	if(!defined $fh ) {
		print STDERR "ERROR: cannot open file '$path', $!\n";
		return undef;
	}

	binmode($fh);

	return $fh;
}


sub recover
{
	my $file = shift;

	my $fh = shift;	
	return unless $fh;

	my $dir_id = shift;
	my $name = shift;
	
	$file -> recover_data($fh,$dir_id,$name);
	$file -> recover_attributes($dir_id,$name);
	$file -> recover_acl($dir_id,$name);
}

sub recover1block
{

}

sub _recover_data
{
	my $file = shift;
	

	my $fh = shift;
	my $dir_id = shift;	
	my $name = shift;

	my $p_key = "$dir_id\000$name";

    my $full_key = $p_key;
    my $value = undef;
	my $db = $file -> _get_db();
    my $st = $db -> select_first($full_key, $value);
    while( $st == 0) {
		last unless ( $full_key =~ m#^$p_key# );
		recover1block($value,$fh);
		$st = $db -> select_next($full_key, $value);
	}
	close $fh;
}

sub recover_attributes
{
	# =================================
	# recover attributes
	# my $att = shift;
	# set_attrs($path,$att,"FILE:");
}

sub recover_acl
{
	# recover acl

	# my $acl = shift;
	
}

=pod

sub recover1block
{
	my $file = shift;
	my $fh = shift;
	
	
	my $data_ref = get($digest);

	if( defined $data_ref && length($data_ref) > 0 ) {
		my $r = uncompress(\$data_ref);
		if( defined $r ) {
			my $n = syswrite($fh,$$r);
			die "$!" unless $n;
		}
	}
}
=cut

1;
