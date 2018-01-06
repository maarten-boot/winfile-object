# ========================================================
# Linux
# =======================================================

use warnings;
use strict;

package Linux;

# =======================================================

my %fields = (
	'os'		=> undef,
	'osname'	=> undef,
	'user'		=> undef,
	'domain'	=> undef,
	'hostname'	=> undef,
	'has_acl'	=> undef,
);

# =======================================================

# =======================================================

sub new 
{
	my $class = shift;
	my $self = {
		%fields
	};
	bless($self,$class);
	
	$self -> {'os_version'} = "";
	$self -> {'os_name'} = $^O;
	$self -> {'logname'} = $ENV{'LOGNAME'};
	$self -> {'domain'} = `/bin/domainname`;
	chomp $self -> {'domain'};
	$self -> {'hostname'} = `/bin/hostname`;
	chomp $self -> {'hostname'};
	
	return $self
}

# ==========================================
# ==========================================
# ==========================================

sub get_os_name
{
	my $self = shift;	
	return $self -> {'os_name'};
}

sub get_os_version
{
	my $self = shift;	
	return $self -> {'os_version'};
}

sub get_hostname
{
	my $self = shift;	
	return $self -> {'hostname'};
}

sub get_domain
{
	my $self = shift;	
	return $self -> {'domain'};
}

sub get_logname
{
	my $self = shift;	
	return $self -> {'logname'};
}

# ==========================================
# ==========================================
# ==========================================

sub has_acl($$)
{
	my $self = shift;
	
	return 0;
}

sub get_path_acl($$)
{
	my $self = shift;
	my $path = shift;
	
	my $acl = undef;
	return $acl; 
}

sub set_path_acl($$$)
{
	my $self = shift;
	my $path = shift;
	my $acl = shift;

	return undef;	
}

# ==========================================
# ==========================================
# ==========================================
# Get / Set filesystem attributes
# stat/chmod under posix

sub get_path_attrs
{
	my $self = shift;
	my $item = shift;
	
	my $attrs = undef;
	my @a = stat($item);
	$attrs = join(";", @a);
	return $attrs; 
}

sub set_path_attrs
{
	my $self = shift;
	my $item = shift;
	my $attrs = shift;
	
	return set_item($item,$attrs);
}

# ==========================================
# ==========================================
# ==========================================

sub _get_fixed_drives()
{
	my $cmd = "/bin/mount";

	my @A = ();
	open(IN,"$cmd |") || die "FATAL: cannor open '$cmd',$!";
	while(<IN>) {
		chomp;
		my @a = split;
		if( $a[4] eq 'ext2' ) { push(@A,$a[2]); next; }
		if( $a[4] eq 'reiserfs' ) { push(@A,$a[2]); next; }
	}
	close IN;
	
	return @A;
}

sub get_filesystems()
{
	my $self = shift;
	return _get_fixed_drives();
}

sub get_filesystem_attrs
{
	my $self = shift;

	my $s = "";
	return $s;
}

sub get_filesystem_type
{
	my $self = shift;
	my $vol = shift;

	my $fs_type = undef;	
	my $cmd = "/bin/mount";

	my @A = ();
	open(IN,"$cmd |") || die "FATAL: cannor open '$cmd',$!";
	while(<IN>) {
		chomp;
		my @a = split;
		if( $a[2] eq $vol ) { 
			$fs_type = $a[4];	
		}
	}
	close IN;
	return $fs_type;
}

sub filesystem_has_acl
{
	my $self = shift;
	my $vol = shift;

	return 0;
}

# ===================================================
1;
