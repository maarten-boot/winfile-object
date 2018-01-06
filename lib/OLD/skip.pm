# =======================================================
# =======================================================

use warnings;
use strict;

$\ = "\n";
$, = ' ';

# ======================================================

my @SKIP_RULES = ();

# skip all
# skip file
# skip dir

sub add_skip_rules()
{

	# possibly add matched rules to the top of the list
	# to improve speed
	
	# SKIP RULES CAN COME FROM COMMAND LINE OR FILE
	# add skip extension
	# add skip directory
	# add skip pattern
	# add skip volume
	# reverse skip

	#add_skip_rule('\.log$');
	add_skip_rule('\.tmp$');
	#add_skip_rule('\.wav$');
	#add_skip_rule('\.mp3$');

	add_skip_rule('drwatson');
	add_skip_rule('recycler');
	add_skip_rule('Temporary Internet Files');
	add_skip_rule('system volume information');
	add_skip_rule("pagefile\\.sys");
}

sub add_skip_rule($)
{
	my $rule = shift;

	log_msg "ADD SKIP RULE: $rule";
	push(@SKIP_RULES,$rule);
}

sub list_skip_rules()
{
	my $rules = undef;

	$rules = join("\n",@SKIP_RULES);
	return $rules;
}

sub apply_skip_rules($$)
{
	my $path = shift;
	my $dir = shift;

	my $skip = 0;
	foreach my $rule (@SKIP_RULES) {
		next if ( $rule =~ /\$$/ && $dir eq 'd' );

		if( $path =~ m#$rule#i ) {
			$skip = 1;
		}
		last if $skip == 1;
	}
	return $skip;
}

sub skip_rules ()
{
	return @SKIP_RULES;
}

# ======================================================
1;