# =======================================================
# BACKUP A BLOCK
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

sub update_block ($$)
{
	# param 1 = digest
	# param 2 = data

	# if we already have the block in the block database,
	# (lookup its digest, local only at this moment)
	# then we can spare us the compress here and the store of the data
	# and just do an increment of the refcount

	if(! db_data_refcount_exists($_[0]) ) {
		# compress this block
		my $cdata = compress_block($_[1]);

		my $l = length $cdata;
		return if( $l == 0 );

		if( $::WITH_TCP) {
			my $client = get_client();
			my $cmd = cmd_add($_[0],$cdata);
			$client->send($cmd) || die "ERROR SENDING: $@\n";
			my $reply = $client->receive() || die "ERROR RECEIVING: $@\n";
		}
		my $stat = store_block($_[0],$cdata);
	}
	db_data_refcount_incr($_[0]);
}

# ===============================================================
1;
