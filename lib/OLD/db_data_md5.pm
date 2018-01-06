use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================
# ====================================================

my %DB_DATA_MD5;
my $DB_DATA_MD5;

# ======================================

sub db_data_md5_open($)
{
	my $root = shift;

	my $path = "$root/DATABASE/DATA_MD5.BDB";
	$DB_DATA_MD5 = tie %DB_DATA_MD5, "DB_File",
		$path, O_RDWR|O_CREAT, 0640, $DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_data_md5_sync ()
{
	$DB_DATA_MD5 -> sync;
}

sub db_data_md5_close_ ()
{
	undef $DB_DATA_MD5;
	untie %DB_DATA_MD5;
}

# ======================================

sub db_data_md5_r ()
{
	return \%DB_DATA_MD5;
}

sub db_data_md5 ()
{
	return $DB_DATA_MD5;
}

# ======================================

sub db_data_md5_del($)
{
	my $key = shift;

	delete $DB_DATA_MD5{$key};
}

sub db_data_md5_get($)
{
	my $key = shift;

	return $DB_DATA_MD5{$key};
}

sub db_data_md5_set($$)
{
	my $key = shift;
	my $val = shift;

	$DB_DATA_MD5{$key} = $val;
}

# ====================================================
# ====================================================

1;