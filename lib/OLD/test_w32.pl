use warnings;
use strict;

$, = ',';
$\ = "\n";

use W32;
# ==============================================
# ==============================================
# ==============================================
# @@ MAIN
{
	my $os = W32 -> new();
	
	print 'LOGNAME   ',	$os -> get_logname();
	print 'HOSTNAME  ',	$os -> get_hostname();
	print 'DOMAIN    ',	$os -> get_domain();
	
	foreach my $d ($os -> get_filesystems()) {

		print 'FILESYSTEM', $d;
		print 'TYPE      ', $os -> get_filesystem_type($d);
		print 'FS_ATTRS  ', $os -> get_filesystem_attrs($d);
		print 'PATH_ATTRS', $os -> get_path_attrs($d);
		
		if( $os -> filesystem_has_acl($d) ) {
			print 'ACL       ', $os -> get_path_acl($d);
		}
	}
}
# ===================================================
