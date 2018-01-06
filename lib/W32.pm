# ========================================================
# MODULE W32
# =======================================================

use warnings;
use strict;

package W32;

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

use Win32; # OS VERSION USER DOMAIN
use Win32::File; # DOS FILE MODES
use Win32API::File 0.08 qw( :ALL ); # DRIVETYPE
use Win32::FileSecurity qw(Get EnumerateRights); # ACL

# =======================================================

sub new 
{
	my $class = shift;
	my $self = {
		%fields
	};
	bless($self,$class);
	
	$self -> {'os_version'} = Win32::GetOSVersion;
	$self -> {'os_name'} = Win32::GetOSName;
	$self -> {'logname'} = Win32::LoginName;
	$self -> {'domain'} = Win32::DomainName;
	$self -> {'hostname'} = Win32::NodeName;
	
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
# Get / Set acls of filesystem objects

use Storable qw( freeze thaw );
 
## TODO
## ACL object ??

sub has_acl($$)
{
	my $self = shift;
	
	# does this os support acl at all
}

sub get_path_acl($$)
{
	my $self = shift;
	my $path = shift;
	
	my $acl = undef;
	my %hash;

	eval {
		if (! Win32::FileSecurity::Get( $path, \%hash ) ) {
			my $s = "\tError(get_dacl) #" . int( $! ) . ": $!\n";
			print $s;
		}
	};

	$acl = Storable::nfreeze \%hash;
	# SORT AND SERIALIZE CONSISTENT	
	
	return $acl; 
}

sub set_path_acl($$$)
{
	my $self = shift;
	my $path = shift;
	my $acl = shift;

	my $bool = 1; # false
	my %hash = %{ thaw($acl) };
	eval {
		if (! Win32::FileSecurity::Set( $path, \%hash ) ) {
			my $s = "\tError(set_dacl) #". int( $! ). ": $!\n";
			print $s;
		} else {
			$bool = 0; # true
		}
	};
	
	return $bool;	# reporting success or failure
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
	eval {
		if( ! Win32::File::GetAttributes($item, $attrs) ) {
			print "\tError(get_w32_fileatt):$item #", int( $! ), ": $!\n";
			return undef;
		}
	};
	# ERROR HANDLING
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
	my @roots= getLogicalDrives();

	my $fixed = 0;
	my @fixed = ();

	foreach my $dir (@roots) {
		my $uDriveType= GetDriveType( $dir );
		my $s;

		if( $uDriveType== DRIVE_FIXED ) {
			$s = "DRIVE_FIXED";
			push(@fixed,$dir);
			$fixed ++;
		}
		next;

		if( $uDriveType == DRIVE_FIXED ) {
			$s = "DRIVE_FIXED";
		} elsif( $uDriveType == DRIVE_NO_ROOT_DIR ) {
			$s = "DRIVE_NO_ROOT_DIR";
		} elsif( $uDriveType == DRIVE_REMOVABLE ) {
			$s = "DRIVE_REMOVABLE";
		} elsif( $uDriveType == DRIVE_UNKNOWN) {
			$s = "DRIVE_UNKNOWN";
		} elsif( $uDriveType == DRIVE_REMOTE ) {
			$s= "DRIVE_REMOTE";
		} elsif( $uDriveType == DRIVE_CDROM ) {
			$s = "DRIVE_CDROM";
		} elsif( $uDriveType == DRIVE_RAMDISK ) {
			$s = "DRIVE_RAMDISK";
		}
	}
	return @fixed;
}

sub get_filesystems()
{
	my $self = shift;
	return _get_fixed_drives();
}

sub get_filesystem_attrs
{
	my $self = shift;

	# for the filesystem specified, retreive its attributes
	# e.g. does it have acl, does is support holes, ...

	my $vol = shift;

	my $s = undef;
	my ($osVolName,$lVolName,$ouSerialNum,$ouMaxNameLen,$ouFsFlags,$osFsType,$lFsType);

	eval {
		if(! GetVolumeInformation(
			$vol,$osVolName,$lVolName,$ouSerialNum,$ouMaxNameLen,$ouFsFlags,$osFsType,$lFsType)
		) {
			# log_msg "Error #" . int( $! ) . ": $!, $^E";
		}

		$lVolName = "" if( ! defined $lVolName );
		$lFsType = "" if( ! defined $lFsType );

		$s = join("\000", ($vol,$osVolName,$lVolName,$ouSerialNum,$ouMaxNameLen,$ouFsFlags,$osFsType,$lFsType));
	};

	return $s;
}

sub get_filesystem_type
{
	my $self = shift;
	my $vol = shift;

	my $fs_type = undef;	
	my ($osVolName,$lVolName,$ouSerialNum,$ouMaxNameLen,$ouFsFlags,$osFsType,$lFsType);

	eval {
		if(! GetVolumeInformation(
			$vol,
			$osVolName,
			$lVolName,
			$ouSerialNum,
			$ouMaxNameLen,
			$ouFsFlags,
			$osFsType,
			$lFsType)
		) {
			# log_msg "Error #" . int( $! ) . ": $!, $^E";
		}
		$fs_type = $osFsType;
	};

	return $fs_type;
}

sub filesystem_has_acl
{
	my $self = shift;
	my $vol = shift;

	my $fs_type = lc($self -> get_filesystem_type($vol));

	return 1 if($fs_type eq 'ntfs' );
	
	return 0;
}

# ===================================================
1;
