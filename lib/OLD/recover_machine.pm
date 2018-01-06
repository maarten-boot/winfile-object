# =======================================================
# RECOVER MACHINE
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';


sub recover_this_machine($)
{
	my $relocate = shift;
	my $r = $relocate;
	$r =~ s/:.*/:\\/;
	my $fstype = w32_get_volume_type($r);

	log_msg "RELOCATE: $relocate , $fstype";
	my_mkdir($relocate,0755,undef,undef);

	foreach my $dirname (sort keys %{&db_directories_r()} ) {
		my $this_id = db_directories_get($dirname);
		$::DIRS++;
		recover_one_directory ($relocate,$dirname,$this_id);
	}
}

1;
