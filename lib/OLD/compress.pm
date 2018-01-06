# =======================================================
# MODULE COMPRESS
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

# =======================================================
# =======================================================

use Compress::Zlib;

sub compress_block($)
{
	my $m = length($_[0]);
    if ( $m == 0 ) {
		return undef;
	}

	my ($d,$status) = deflateInit(-Bufsize => $::BLOCKSIZE);
	$status == Z_OK || die "FATAL: deflation failed, $status";

	my $out1;
	($out1,$status) = $d -> deflate($_[0]);
	$status == Z_OK || die "FATAL: deflation failed, $status";

	my $out2;
	($out2,$status) = $d -> flush();
	$status == Z_OK || die "FATAL: deflation failed, $status";

	return $out1 . $out2;
}

sub uncompress_block ($)
{
	my $block_r = shift;

	return undef unless (defined $block_r && length($$block_r) > 0);

    my ($x,$status) = inflateInit();
	die "FATAL: inflateInit failed" unless $status == Z_OK;

	my $output = undef;
	($output, $status) = $x->inflate($$block_r);
	if( $status == Z_OK || $status == Z_STREAM_END) {
		log_msg "uncompress OK, " . length($output) . " $status";
	}
	warn "inflation failed" unless $status == Z_STREAM_END;

	return \$output;
}

# ===============================================================
1;
