#! /usr/bin/perl -w
# ==============================================
use warnings;
use strict;
# ==============================================

$, = ',';
$\ = "\n";

# ==============================================
use lib './lib';
use OS;
# ==============================================

# @@ MAIN
{
	my $os = OS -> new();
	
	print 'LOGNAME   ',	$os -> get_logname();
	print 'HOSTNAME  ',	$os -> get_hostname();
	print 'DOMAIN    ',	$os -> get_domain();
	
	foreach my $d ($os -> get_filesystems()) {
		print '';
		print 'FILESYSTEM', $d;
		print 'TYPE      ', $os -> get_filesystem_type($d);
		print 'FS_ATTRS  ', $os -> get_filesystem_attrs($d);
		print 'PATH_ATTRS', $os -> get_path_attrs($d);
		
		if( $os -> filesystem_has_acl($d) ) {
			print 'ACL       ', $os -> get_path_acl($d);
		} else {
			print 'ACL       ', 'NO ACL FOR:' , $d;
		}
	}
}
# ===================================================
