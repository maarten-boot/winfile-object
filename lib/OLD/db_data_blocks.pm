use warnings;
use strict;

use DB_File;
use Fcntl;

$\ = "\n";
$, = ' ';

# ====================================================
# ====================================================

my %DB_DATA_BLOCKS;
my $DB_DATA_BLOCKS;

# ===========================

sub db_data_blocks_open($)
{
	my $root = shift;

	my $p = "$root/DATABASE2";
	my $path = "$p/DATA_BLOCKS.BDB";
	mkdir("$p",0777) unless -d $p;
	
	$DB_DATA_BLOCKS = tie %DB_DATA_BLOCKS, "DB_File", $path, O_RDWR|O_CREAT, 0640,
		$DB_BTREE ||
		die "FATAL: cannot tie to '$path', $!\n";
}

sub db_data_blocks_sync ()
{
	$DB_DATA_BLOCKS -> sync;
}

sub db_data_blocks_close ()
{
	undef $DB_DATA_BLOCKS;
	untie %DB_DATA_BLOCKS;
}

# ===========================

sub db_data_blocks_r ()
{
	return \%DB_DATA_BLOCKS;
}

sub db_data_blocks ()
{
	return $DB_DATA_BLOCKS;
}

# ===========================

sub db_data_blocks_del($)
{
	delete $DB_DATA_BLOCKS{$_[0]};
}

sub db_data_blocks_get($)
{
	return $DB_DATA_BLOCKS{$_[0]};
}

sub db_data_blocks_set($$)
{
	$DB_DATA_BLOCKS{$_[0]} = $_[1];
}

sub store_block($$)
{
	# no collission detect as for now

	if(length($_[1]) == 0) {
		log_msg "!Nothing to store for digest $_[0]";
		return 0;
	}

	if(defined $DB_DATA_BLOCKS{$_[0]} )  {
		print "Duplicate digest $_[0]";
		return 1;
	}

	db_data_blocks_set($_[0],$_[1]);

	return 1;
}

# ====================================================

1;