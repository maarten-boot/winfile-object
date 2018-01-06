# =======================================================
# RECOVER DIRECTORY
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

sub set_attrs($$$)
{
	my $path = shift;
	my $attrs = shift;
	my $type = shift;

	return unless $attrs;

	my %h = (
		'archive' => $attrs & ARCHIVE,
		'system' => $attrs & SYSTEM,
		'hidden' => $attrs & HIDDEN,
		'read-only' => $attrs & READONLY,
		'directory' => $attrs & DIRECTORY,
		'compressed' => $attrs & COMPRESSED,
		'temporary' => $attrs & 0x0100,
		'offline' => $attrs & 0x1000,
		'normal' => $attrs & NORMAL,
	);

	my @z;
	foreach my $k (sort keys %h) {
		push(@z,$k) if $h{$k};
	}

	if( $attrs & DIRECTORY ) {
		$attrs = $attrs & (~DIRECTORY);
	}
	if( $attrs & COMPRESSED ) {
		$attrs = $attrs & (~COMPRESSED);
	}

	if ( $attrs) {
		log_msg "$type,$path,$attrs," . join(' ',@z);
		if(! Win32::File::SetAttributes( $path, $attrs ) ) {
			log_msg "cannot set attrs: $attrs on $path";
		}
	}
}

sub my_mkdir($$$$)
{
	my $path = shift;
	my $mode = shift;

	my $att = shift;
	my $acl = shift;

	if( ! -d $path) {
		my $m = sprintf "%o" , $mode if defined $mode;
		my $a = sprintf "%o" , $att if defined $att;
		log_msg "CREATE DIR: $path with mode $m/$a";
		mkdir($path,$m) || die "FATAL: cannot create '$path' mode '$mode',$!";
		$::DIRS++;
	}

	set_attrs($path,$att,"DIR:");
}

use Storable qw( freeze thaw );

sub recover_one_directory ($$$)
{
	my $relocate = shift;
	my $dirname = shift;
	my $this_id = shift;

	$dirname =~ s#:\\#/#;
	$dirname =~ s#//#/#g;

	my $d = $relocate . '/' . $dirname;
	print "$d\t$this_id";

	my $item_id = $this_id ;
	my $value = 0;

	my $ra = db_attributes();
    my $st = $ra -> seq($item_id, $value, R_CURSOR);
    while( $st == 0) {
		last unless ( $item_id =~ m#^$this_id# );

		my( $id,$name,$type) = split(/\000/,$item_id);
		my %attrs = %{ Storable::thaw $value };
		my( $size,$mtime,$ctime,$uid,$gid,$mode) = split(/,/,$attrs{'sig'});
		my $att = $attrs{'att'};
		my $acl = $attrs{'acl'};

		if( $type eq 'DIR:' ) {
		    # log_msg "R $item_id-> $value";
			my_mkdir("$d/$name",$mode,$att,$acl);
		}

		if( $type eq 'FILE:' ) {
		    # log_msg "R $item_id-> $value";
			recover_this_file($id,$name,"$d/$name",$mode,$att,$acl);
		}
		$st = $ra -> seq($item_id, $value, R_NEXT);
	}
}

1;
