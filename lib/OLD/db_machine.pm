use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================

my %DB_MACHINE;
my $DB_MACHINE;

sub db_machine_open($)
{
	my $root = shift;

	my $path = "$root/DATABASE/MACHINE.BDB";
	$DB_MACHINE = tie %DB_MACHINE, "DB_File", $path,
		O_RDWR|O_CREAT,	0640,$DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_machine_sync ()
{
	$DB_MACHINE -> sync;
}

sub db_machine_close ()
{
	undef $DB_MACHINE;
	untie %DB_MACHINE;
}

sub db_machine_r ()
{
	my $r = \%DB_MACHINE;
	return $r;
}

sub db_machine_get($)
{
	my $key = shift;

	return $DB_MACHINE{$key};
}

sub db_machine_set($$)
{
	my $key = shift;
	my $val = shift;

	$DB_MACHINE{$key} = $val;
}

# ====================================================

1;