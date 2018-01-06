# =======================================================
# A MACHINE
# =======================================================

package machine;

use warnings;
use strict;

# =======================================================
my %fields = (
	'hostname' => undef,
	'domain' => undef,
	'volumes' => undef,
	'os' => undef,			# an object 
	'os_version' => undef,	
);

# =======================================================

sub new ($$)
{
	my $class = shift;

	my $self = {
		%fields,
	};
	bless($self,$class);
	$self -> initialize();
	
	return $self;
}

sub initialize ()
{
	my $self = shift;

	# initialize the OS object and the os version
	# get the volumes (fixed)
	
	return $self;
}


sub get_os ()
{
	my $class = shift;

	return $self -> os;	
}

sub get_os_version ()
{
	my $class = shift;

	return $self -> os_version;	
}

sub volumes ()
{
	my $self = shift;
	
	my $self -> volumes = sort($os -> get_mounts());

}

# =======================================================
1;
# =======================================================
__DATA__

sub volumes ()
{
	foreach my $vol( sort keys %{$mounts}) {
		my $fstype = $mounts -> {$vol};
		do_one_volume($vol,$fstype);

		last if $::DEMO;
	}
}

sub post ()
{
	# delete all items not in current backup set
	log_msg "REMOVE DELETED ITEMS";
	my $h = db_history_r();
	while( my ($key1,$val1) = each(%{$h}) ) {
		my($item,$name,$type) = split(/\000/,$key1);
		log_msg "DELETE: $type $name at $item";

		my $key = "$item\000$name\000$type";

		db_history_del($key);
		db_attributes_del($key);

		# delete md5
		# key = $item $name $block-nr

		# delete blocks;
	}
	db_sync();

	# build new history
	log_msg "RECREATE HISTORY DB";
	my $h2 = db_attributes_r();
	while(my ($key2,$val2) = each(%{$h2}) ) {
		db_history_set($key2,"");
	}
	db_sync();

}

sub backup($)
{
	my $client = shift;

	db_machine_set('CLIENT',$client);

	machine_pre();
	machine_volumes();
	machine_post();

}

# ===============================================================
1;
