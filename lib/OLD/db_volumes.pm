use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================
# ====================================================

my %DB_VOLUMES;
my $DB_VOLUMES;

sub db_volumes_open($)
{
	my $root = shift;
	my $path = "$root/DATABASE/VOLUMES.BDB";
	$DB_VOLUMES = tie %DB_VOLUMES, "DB_File", $path,
		O_RDWR|O_CREAT,	0640,$DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_volumes_sync ()
{
	$DB_VOLUMES -> sync;
}

sub db_volumes_close ()
{
	undef $DB_VOLUMES;
	untie %DB_VOLUMES;
}

sub db_volumes_r ()
{
	return \%DB_VOLUMES;
}

sub db_volumes_get($)
{
	my $key = shift;

	return $DB_VOLUMES{$key};
}

sub db_volumes_set($$)
{
	my $key = shift;
	my $val = shift;

	$DB_VOLUMES{$key} = $val;
}

# ====================================================

1;