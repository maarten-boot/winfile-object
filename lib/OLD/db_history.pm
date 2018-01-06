use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================
# ====================================================
my %DB_HISTORY;
my $DB_HISTORY;

sub db_history_open($)
{
	my $root = shift;

	my $path = "$root/DATABASE/HISTORY.BDB";
	$DB_HISTORY = tie %DB_HISTORY, "DB_File", $path, O_RDWR|O_CREAT,
		0640, $DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_history_sync ()
{
	$DB_HISTORY -> sync;
}

sub db_history_close ()
{
	undef $DB_HISTORY;
	untie %DB_HISTORY;
}

sub db_history_r ()
{
	return \%DB_HISTORY;
}

sub db_history_get($)
{
	my $key = shift;

	return $DB_HISTORY{$key};
}

sub db_history_set($$)
{
	my $key = shift;
	my $val = shift;

	$DB_HISTORY{$key} = $val;
}

sub db_history_del($)
{
	my $key = shift;
	delete $DB_HISTORY{$key};
}

# ====================================================

1;