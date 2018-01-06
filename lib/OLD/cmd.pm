# COMMAND.PM
# a common point for sending and receiving commands 
# using anon arrays to serialize a command

use warnings;
use strict;

use English;
$ORS = "\n";
$OFS = ',';

# ==========================================
# REMEMBER $_[n] in subs is a alias to the n th argument
# this avoids costry copying of large data buffers
# to copy use the my $name = $_[n] assignment
# ==========================================

sub cmd_incr ($)
{
	my $digest = $_[0]; 

	return [ 'BLOCK_INCR', 1, $digest ];
}

sub cmd_decr ($)
{
	my $digest = $_[0];

	return [ 'BLOCK_DECR', 1, $digest ];
}

sub cmd_add ($$)
{
	my $digest = $_[0];
	my $data = $_[1]; 

	return [ 'ADD_BLOCK', 2,  $digest , $data ];
}

sub dispatch_incr ($)
{
	my $cmd = $_[0];
	print $cmd -> [0];
}

sub dispatch_decr ($)
{
	my $cmd = $_[0];
	print $cmd -> [0];
}

sub dispatch_add  ($)
{
	my $cmd = $_[0];
	print $cmd -> [0];
}

my %known_commands = (
	'BLOCK_INCR' => \&dispatch_incr,
	'BLOCK_DECR' => \&dispatch_decr,
	'ADD_BLOCK' => \&dispatch_add,
);

sub do_cmd ($) 
{
	my $cmd = $_[0];

	my $z = $known_commands{ $cmd -> [0] };
	if( ! defined $z ) {
		warn "CRYOUT: unknown command: $cmd -> [0], command ignored";
		return undef;
	}

	return $z -> ( $cmd );
}

1;

__DATA__

{
	my $digest = "agagagagagagaga";
	my $data = "hshshhshshshsshhshshshshshshshshshshshshshshshshshshshshhshhshhsshhshshshshshshshhhshshshsh";


	my $incr = cmd_incr($digest);
	my $decr = cmd_decr($digest);

	my $add = cmd_add($digest,$data);

	do_cmd($incr);
	do_cmd($decr);
	do_cmd($add);
}
