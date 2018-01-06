# =======================================================
# aBlock
# =======================================================

use warnings;
use strict;

use lib './lib';
use aApp;

# =======================================================
package aBlock;
# =======================================================

my $BlockSize = 64 * 1024;

my %fields = (
	# the raw data block
	'data' => undef,
	'length' => undef,

	# the compressed data block
	'cdata' => undef,
	'clength' => undef,

	# how is it compressed
	'compress-method' => undef,

	# the digest
	'sha1' => , undef,
	'md5' => , undef,
	'digest' => , undef,
	'old-digest' => , undef,

	'refcount' => undef,
	
	# interface to the block database and the refcount database
	# data-db stores the data itself (incompressd form) 
	# key is digest -> value is the compressed data

	'data-db' => undef,

	# ================================================
	# refcount-db stores the data itself (incompressd form)
	# key is digest -> value is the refcount for this digest

	'refcount-db' => undef,
);

# ===================================================================
# PUBLIC

sub read1block($$)
{
	my $class = shift;
	my $fh = shift;

	# ======================================
	# init self
	
	my $self = {
		%fields,
	};
	bless $self , $class;
	
	{
		my $n1 = 'BLOCKS.DB';
		my $n2 = 'data-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	{
		my $n1 = 'REFCOUNT.DB';
		my $n2 = 'refcount-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	# init finished
	# ===================================

	while (1) {
		my $len = sysread($fh,$self -> {'data'},$BlockSize);
		if(!defined $len ) {
			# do partial read
			next if $! =~ /^Interrupted/;
			die "FATAL: sysread error: $!";
		}

		$self -> {'length'} = length( $self -> {'data'} );

		return $self;
	}
}

sub lazy_delete
{
	my $class = shift;
	my $digest = shift;

	# ======================================
	# init self
	
	my $self = {
		%fields,
	};
	bless $self , $class;
	
	{
		my $n1 = 'BLOCKS.DB';
		my $n2 = 'data-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	{
		my $n1 = 'REFCOUNT.DB';
		my $n2 = 'refcount-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	# init finished
	# ===================================

	$self -> {'digest'} = $digest;
	$self -> _refcount_decr();

	return $self;
}

sub FindMyBlock
{
	my $class = shift;
	my $digest = shift;

	# ======================================
	# init self
	
	my $self = {
		%fields,
	};
	bless $self , $class;
	
	{
		my $n1 = 'BLOCKS.DB';
		my $n2 = 'data-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	{
		my $n1 = 'REFCOUNT.DB';
		my $n2 = 'refcount-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$self -> {$n2} = $db;
		} else {
			$db = $self -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	# init finished
	# ===================================

	$self -> {'digest'} = $digest;
	$self -> {'refcount'} = $self -> _get_refcount_db() -> get($digest);

	if( ! defined $self -> {'refcount'}  ) {
		die "FATAL: '$digest' must exist in REFCOUNT";	
	}

	if( $self -> {'refcount'} == 0  ) {
		die "FATAL: refcount == 0 for '$digest'";	
	}

	$self -> {'cdata'} = $self -> _get_data_db() -> get($digest);

	if( ! defined $self -> {'cdata'}  ) {
		die "FATAL: '$digest' must exist in BLOCKS";	
	}
	
	$self -> {'clength'} = length($self -> {'cdata'});
	$self -> UncompressZlib();

	return $self;
}

sub discard_block
{
	my $self = shift;
	my $digest = shift;

	# we will only decrecment the refcount for now, cleaning the actual data will be done
	# at the end of the session as we could find that we will need this block later 
	# a separate vacuum process will actually clean the datablocks later by checking if refcount == 0

	my $db = $self -> _get_refcount_db();
	my $count = $db -> get($digest);
	if( ! defined $count ) {
		die "FATAL: MUST HAVE defined refcount";
	}

	if( $count == 0 ) {
		die "FATAL: MUST HAVE refcount > 0 ";
	}

	$count --;
	$db -> put($digest,$count);
}

sub length
{
	my $self = shift;

	return	$self -> {'length'};
}

sub data
{
	my $self = shift;

	return	$self -> {'data'};
}

sub digest
{
	my $self = shift;

	return	$self -> {'digest'};
}

sub make_digest
{
	my $self = shift;

	my $md5 = $self -> _make_md5();
	my $sha1 = $self -> _make_sha1();
	my $digest = $self -> {'digest'} = "Size\000$BlockSize\000md5\000$md5\000sha1\000$sha1";

	return $digest;
}

sub get_len
{
	my $self = shift;

	return $self -> {'length'};
}

sub CompressZlib($)
{
	my $self = shift;
	my $len = $self -> {'length'};
	return 0 unless $len;
	
	use Compress::Zlib;
	$self -> {'compress-method'} = 'Zlib';
	
	my ($d,$status) = deflateInit(-Bufsize => $BlockSize);
	$status == Z_OK || die "FATAL: deflation failed, $status";

	my $out1;
	($out1,$status) = $d -> deflate($self -> {'data'});
	$status == Z_OK || die "FATAL: deflation failed, $status";

	my $out2;
	($out2,$status) = $d -> flush();
	$status == Z_OK || die "FATAL: deflation failed, $status";
	# print length($out1) , length($out2);

	$self -> {'cdata'} = $out1 . $out2; 
	my $clen = $self -> {'clength'} = CORE::length( $self -> {'cdata'} );

	print "Compress: $len, $clen\n" if $::DBG;
	
	return $clen;
}

sub UncompressZlib($)
{
	my $self = shift;	

	$self -> {'data'} = undef;
	$self -> {'length'} = undef;

	if(	defined $self -> {'cdata'} && 
		defined $self -> {'clength'} && 
		$self -> {'clength'} > 0 
	) {
		use Compress::Zlib;

	    my ($x,$status) = inflateInit();
		die "FATAL: inflateInit failed" unless $status == Z_OK;

		($self -> {'data'} , $status) = $x->inflate($self -> {'cdata'});
		if( $status == Z_OK || $status == Z_STREAM_END) {
			print "\tuncompress OK, " . CORE::length($self -> {'data'}) . " $status\n";
		}
		warn "inflation failed" unless $status == Z_STREAM_END;
	}

	$self -> {'length'} = CORE::length( $self -> {'data'} );	
	$self;
}

sub store_data
{
	my $self = shift;

	print "\t\tstore\n";
	my $db = $self -> _get_data_db();
	my $key = $self -> _get_digest();
	my $val = $self -> _get_cdata();

	$db -> put($key,$val);
	$self -> _refcount_incr(); # sets refcount to 1
}

sub update
{
	my $self = shift;
	my $what = shift;

	# This block has to be remembered. 
	# If the block has never been seen before 
	# we have to insert it in the data-db and set the refcount to 1.
	# If the block already exists we only have to increment the refcount.
	# so the easiest is first to see if the refcount extsts in the refcount-db

	if( defined $self -> _refcount_exists()) {
		# if we already have the block in the block database,
		# then we can spare us the compress here and the store of the data
		# and just do an increment of the refcount
		$self -> _refcount_incr();
	} else {

		# this block is not yet in database,
		# so we have to compress it first and then 
		# store it in the data-db
	
		my $l = $self -> CompressZlib();
		$self -> store_data(); 
	}
}

# ===================================================================
# PRIVATE

sub _get_data_db()
{
	my $self = shift;	

	return $self -> {'data-db'};
}

sub _get_refcount_db()
{
	my $self = shift;	

	return $self -> {'refcount-db'};
}


sub _make_md5
{
	my $self = shift;

	use Digest::MD5;
	my $md5_context = new Digest::MD5;
	$md5_context -> add($self -> {'data'});

	return $self -> {'md5'} = $md5_context -> hexdigest;
}

sub _make_sha1
{
	my $self = shift;

	use Digest::SHA1;
	my $sha1_context = new Digest::SHA1;
	$sha1_context -> add($self -> {'data'});	

	return $self -> {'sha1'} = $sha1_context -> hexdigest;
}

sub _get_digest
{
	my $self = shift;

	return $self -> {'digest'};
}

sub _get_old_digest
{
	my $self = shift;

	return $self -> {'digest'};
}

sub _get_cdata
{
	my $self = shift;

	return $self -> {'cdata'};
}

sub _refcount_exists
{
	my $self = shift;

	my $db = $self -> _get_refcount_db();
	my $digest = $self -> _get_digest();
	
	return $db -> get($digest);
}

sub _refcount_incr
{
	my $self = shift;

	my $db = $self -> _get_refcount_db();
	my $digest = $self -> _get_digest();
	
	my $count = $db -> get($digest);

	if( defined $count ) {
		$count ++;
	} else {
		$count = 1;
	}

	print "\t\trefcount: $count\n";
	$db -> put($digest,$count);

	return $count;
}

sub _refcount_decr
{
	my $self = shift;

	my $db = $self -> _get_refcount_db();
	my $digest = $self -> _get_digest();
	
	my $count = $db -> get($digest);

	if( ! defined $count ) {
		die "FATAL: MUST HAVE defined refcount";
	}

	if( $count == 0 ) {
		die "FATAL: MUST HAVE refcount > 0 ";
	}

	$count --;
	$db -> put($digest,$count);
}
# ===============================================================
1;
