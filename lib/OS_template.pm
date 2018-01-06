# ========================================================
# MODULE OS
# =======================================================

use warnings;
use strict;

# =======================================================
package OS;
# =======================================================


# =======================================================
# =======================================================
# =======================================================

# ==========================================
# ==========================================
# ==========================================

sub get_hostname
{
	my $self = shift;	
	return $self -> hostname;
}

sub get_domain
{
	my $self = shift;	
	return $self -> domain;
}

sub get_logname
{
	my $self = shift;
	return $self -> logname;
}

# ==========================================
# ==========================================
# ==========================================
# Get / Set acls of filesystem objects

sub has_acl($$)
{
	my $self = shift;
	
	# does this os support acl at all
	return undef;
}

sub get_acl($$)
{
	my $self = shift;
	my $item = shift;
	
	my $acl = undef;
	
	# retrieve acl of item
	
	return $acl; 
}

sub set_acl($$$)
{
	my $self = shift;
	my $item = shift;
	my $acl = shift;
	
	return set_item($item,$acl);
}

# ==========================================
# ==========================================
# ==========================================
# Get / Set filesystem attributes
# stat/chmod under posix

sub get_fileatt
{
	my $self = shift;
	my $item = shift;
	
	my $attrs = undef;
	
	# retrieve attrs of item
	
	return $attrs; 
}

sub set_fileatt
{
	my $self = shift;
	my $item = shift;
	my $attrs = shift;
	
	return set_item($item,$attrs);
}

# ==========================================
# ==========================================
# ==========================================

sub get_filesystems()
{
	# enumerate all currenlty mounted fileystems
}

sub get_filesystem_attrs
{
	# for the filesystem specified, retreive its attributes
	# e.g. does it have acl, does is support holes, ...
}

1;
