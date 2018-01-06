# =======================================================
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

# =======================================================
# =======================================================
# CHECK THE BACKUP INTERNALLY

sub check_this_machine()
{
	# CHECK 1
	# DB_DIRECTORIES -> DB_ATTRIBUTES
	# LIST ALL DIRECTORIES ALPHABETICALLY

	my $r = db_directories_r();
	my $r_att = db_attributes();

	foreach my $key ( sort keys %{$r} ) {
		$::DIRS++;
		my $val = $r -> { $key };
		log_msg "$key\t$val";

		# FIND ALL ITEMS IN THIS DIRECTORY AND LIST THEM
		# val is the id of the directory (all directories are stored under ID nr to avoid redundant data)

		my $k = $val ;
		my $value = 0;
		my $st = $r_att -> seq($k,$value,R_CURSOR);
	    while( $st == 0) {
			last unless ( $k =~ m#^$val# );
			my($item,$name,$type) = split(/\000/,$k);
			if( $type eq 'FILE:' ) {
				$::FILESS++;
				# check the data blocks of this file
			}
			log_msg "\t-> $k-> $value";
		    $st = $r_att -> seq($k, $value, R_NEXT);
		}
	}

	# CHECK 2
	# DB_ATTRIBUTES -> DB_DIRECTORIES
	# CHECK ALL ITEMS AND FIND THEIR DIRECTORY


	# CHECK 3
	# DB_DATA_MD5 -> DB_DATA_BLOCKS
	# CHECK ALL MD5 RECORDS AND MATCH THEIR BLOCKS

	# CHECK 4
	# DB_DATA_BLOCKS -> DB_DATA_MD5
	# CHECK ALL DATA_BLOCKS AND MATCH THEIR MD5

	# ? MACHINE , VOLUMES , HISTORY
}

# ===============================================================
# ===============================================================
# ===============================================================
1;
