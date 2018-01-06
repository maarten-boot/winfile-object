use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================

my %DB_DATA_REFCOUNT;
my $DB_DATA_REFCOUNT;

# ===========================

sub db_data_refcount_open($)
{
	my $root = shift;

	my $path = "$root/DATABASE2/DATA_REFCOUNT.BDB";
	$DB_DATA_REFCOUNT = tie %DB_DATA_REFCOUNT, "DB_File", $path, O_RDWR|O_CREAT, 0640,
		$DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_data_refcount_sync ()
{
	$DB_DATA_REFCOUNT -> sync;
}

sub db_data_refcount_close ()
{
	undef $DB_DATA_REFCOUNT;
	untie %DB_DATA_REFCOUNT;
}

# ===========================

sub db_data_refcount_r ()
{
	return \%DB_DATA_REFCOUNT;
}

sub db_data_refcount ()
{
	# return the db_scalar handle not the tied hash
	return $DB_DATA_REFCOUNT;
}

# ===========================

sub db_data_refcount_del($)
{
	delete $DB_DATA_REFCOUNT{$_[0]};
}

sub db_data_refcount_get($)
{
	return $DB_DATA_REFCOUNT{$_[0]};
}

sub db_data_refcount_exists($)
{
	return defined $DB_DATA_REFCOUNT{$_[0]};
}

sub db_data_refcount_set($$)
{
	$DB_DATA_REFCOUNT{$_[0]} = $_[1];
}

sub db_data_refcount_decr($)
{
	$DB_DATA_REFCOUNT{$_[0]} --;
}


sub db_data_refcount_incr($)
{
	$DB_DATA_REFCOUNT{$_[0]}++;
}

# ====================================================

1;