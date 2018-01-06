# =======================================================
# BACKUP A VOLUME
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

sub pre (@)
{
	# do stuff like filter and
	# on line fileter like .nsr
	# 
	# print join(',',@_);

	my @out;
	
	loop1: 
	for my $item (sort @_) {
		my @rules = skip_rules();
		for my $rule (@rules) {
			if( $item =~ m#$rule#i ) {
				print "SKIP: '$item' with rule '$rule'";	
				next loop1;
			}
		}
		push(@out,$item);
	}

	return @out;
}

sub post 
{
	
}

sub do_one_volume($$)
{
	my $vol = shift;
	my $fs_type = shift;
	
	$::FS_TYPE = $fs_type;
	{
		# remember the volume attributes for later (for  a restore )
		my $s = w32_get_volume_attrs($vol);
		db_volumes_set($vol,$s);
		log_msg $s;
	
		find(
			{ 
				preprocess => \&pre,
				wanted => \&process_item,
				postprocess => \&post,
				follow => 0 ,
			},
			$vol
		);
	}
	$::FS_TYPE = undef;
	
	db_machine_set('CUR_VOLUME',$vol);
	db_sync();	
}

# ===============================================================
1;
