use warnings;
use strict;

$\ = "\n";
$, = ' ';

# =============================================

use db_attributes;
use db_data_md5;
use db_directories;
use db_history;
use db_machine;
use db_volumes;

use db_data_refcount;
use db_data_blocks;

# =============================================

sub db_open($)
{
	log_msg "DB_OPEN";

	my $root = shift;

	db_machine_open ($root);
	db_volumes_open ($root);
	db_directories_open ($root);
	db_attributes_open ($root);
	db_history_open ($root);
	db_data_md5_open ($root);

	db_data_refcount_open ($root);
	db_data_blocks_open ($root);
}

sub db_sync ()
{
	log_msg "DB_SYNC";

	db_machine_sync ();
	db_volumes_sync ();
	db_directories_sync ();
	db_attributes_sync ();
	db_history_sync ();
	db_data_md5_sync ();
	db_data_blocks_sync ();

	db_data_refcount_sync ();
	db_data_blocks_sync ();
}

sub db_close ()
{
	log_msg "DB_CLOSE";

	db_sync();

	db_machine_close ();
	db_volumes_close ();
	db_directories_close ();
	db_attributes_close ();
	db_history_close ();
	db_data_md5_close_ ();

	db_data_blocks_close ();
	db_data_refcount_close ();
}

1;