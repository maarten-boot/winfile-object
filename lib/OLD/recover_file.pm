# =======================================================
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

# ===============================================================
# RECOVER DATASETS

sub open_file_write($$)
{
	my $path = shift;
	my $mode = shift;
	my $fh = undef;

	use Fcntl;

	if ( -f $path ) {
		log_msg "WARN: Overwriting $path";
		if(!sysopen($fh, $path, O_RDWR ) ) {
			log_msg "FATAL: cannot open $path mode $mode in O_RDWR mode,$!";
			return undef;
		}
	} else {
		if(!sysopen($fh, $path, O_CREAT | O_RDWR ) ) {
			log_msg "FATAL: cannot open $path mode $mode in O_CREAT mode,$!";
			return undef;
		}
	}
	if(!defined $fh ) {
		print STDERR "ERROR: cannot open file '$path', $!";
		return undef;
	}

	binmode($fh);
	return $fh;
}

sub recover_this_file($$$$$$)
{
	my $item_id = shift;
	my $name = shift;
	my $path = shift;

	my $mode = shift;
	my $att = shift;
	my $acl = shift;

	my $m = sprintf "%o" , $mode;
	my $a = sprintf "%o" , $att;
	my $fh = open_file_write($path,$mode);

	return unless $fh;

	$::FILES++;

	# find the first block of data
	my $rmd5 = db_data_md5();

	my $p_key = "$item_id\000$name";
	log_msg "F $p_key";

    my $full_key = $p_key;
    my $value = undef;

    my $st = $rmd5 -> seq($full_key, $value, R_CURSOR);
    while( $st == 0) {
		last unless ( $full_key =~ m#^$p_key# );
		my $d = db_data_blocks_get($value);
		if( defined $d && length($d) > 0 ) {
			my $r = uncompress_block(\$d);
			if( defined $r ) {
				my $n = syswrite($fh,$$r);
				die "$!" unless $n;
			}
		}
		log_msg "$full_key $value";
		$st = $rmd5 -> seq($full_key, $value, R_NEXT);
	}
	close $fh;

	set_attrs($path,$att,"FILE:");
}

1;