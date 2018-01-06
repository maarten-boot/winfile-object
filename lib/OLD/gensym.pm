# =======================================================
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

# =======================================================
# ==============# =======================================================
# module GENSYM

sub gensym_init()
{
	my $r = &db_machine_r;
	my $x = $r -> {'GENSYM'};

	if( ! defined $x ) {
		$r -> {'GENSYM'} = 0;
	}
}

sub gensym_new()
{
	my $r = &db_machine_r;
	$r -> {'GENSYM'}++;
	my $s = sprintf("%08x" , $r -> {'GENSYM'} );
	return $s;
}

sub gensym_last ()
{
	my $r = &db_machine_r;
	return $r -> { 'GENSYM' };
}

1;