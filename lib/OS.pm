use warnings;
use strict;

# =======================================================
package OS;
# =======================================================

my %fields = (
	'_osname' => undef,
	'os'		=> undef,
);

# =======================================================

sub new
{
	my $class = shift;
	my $self = {
		%fields,	
	};
	bless $self, $class;
	
	$self -> {'_osname'} = $^O;
	
	if( $self -> {'_osname'} =~ /mswin32/i ) {
		require W32;
		$self -> {'os'} = W32 -> new;
		return $self;
	}

	if( $self -> {'_osname'} =~ /linux/i ) {
		require Linux;
		$self -> {'os'} = Linux -> new;
		return $self;
	}

	if( $self -> {'_osname'} =~ /XYZ/i ) {
		require XYZ;
		$self -> {'os'} = XYZ -> new;
		return $self;
	}
}

sub _osname 
{
	my $self = shift;
	print $self -> {'_osname'};
}

sub get_os_name
{
	my $self = shift;	
	return $self -> {'os'} -> get_os_name();
}

sub get_os_version
{
	my $self = shift;	
	return $self -> {'os'} -> get_os_version();
}

sub get_hostname
{
	my $self = shift;	
	return $self -> {'os'} -> get_hostname();
}

sub get_domain
{
	my $self = shift;	
	return $self -> {'os'} -> get_domain();
}

sub get_logname
{
	my $self = shift;	
	return $self -> {'os'} -> get_logname();
}

sub has_acl($$)
{
	my $self = shift;
	return $self -> {'os'} -> has_acl();
}

sub get_path_acl($$)
{
	my $self = shift;
	my $path = shift;
	

	return $self -> {'os'} -> get_path_acl($path);
}

sub set_path_acl($$$)
{
	my $self = shift;
	my $path = shift;
	my $acl = shift;

	return $self -> {'os'} -> set_path_acl($path,$acl);
}

sub get_path_attrs
{
	my $self = shift;
	my $path = shift;
	
	return $self -> {'os'} -> get_path_attrs($path);
}

sub set_path_attrs
{
	my $self = shift;
	my $path = shift;
	my $attrs = shift;
	
	return $self -> {'os'} -> set_path_attrs($path,$attrs);
}

sub get_filesystems()
{
	my $self = shift;
	return $self -> {'os'} -> get_filesystems();
}

sub get_filesystem_attrs
{
	my $self = shift;
	my $vol = shift;

	return $self -> {'os'} -> get_filesystem_attrs($vol);
}

sub get_filesystem_type
{
	my $self = shift;
	my $vol = shift;

	return $self -> {'os'} -> get_filesystem_type($vol)
}

sub filesystem_has_acl
{
	my $self = shift;
	my $vol = shift;

	return $self -> {'os'} -> filesystem_has_acl($vol)
}

# ===================================================
1;
