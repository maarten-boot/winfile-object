use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================
# ====================================================

my %DB_ATTRIBUTES;
my $DB_ATTRIBUTES;

sub db_attributes_open($)
{
	my $root = shift;

	my $path = "$root/DATABASE/ATTRIBUTES.BDB";
	$DB_ATTRIBUTES =tie %DB_ATTRIBUTES, "DB_File", $path,
		O_RDWR|O_CREAT, 0640, $DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_attributes_sync ()
{
	$DB_ATTRIBUTES -> sync;
}

sub db_attributes_close ()
{
	undef $DB_ATTRIBUTES;
	untie %DB_ATTRIBUTES;
}

sub db_attributes_r()
{
	return \%DB_ATTRIBUTES;
}

sub db_attributes()
{
	return $DB_ATTRIBUTES;
}

sub db_attributes_get($)
{
	my $key = shift;

	return $DB_ATTRIBUTES{$key};
}

sub db_attributes_set($$)
{
	my $key = shift;
	my $val = shift;

	$DB_ATTRIBUTES{$key} = $val;
}

sub db_attributes_del($)
{
	my $key = shift;
	delete $DB_ATTRIBUTES{$key};
}

1;