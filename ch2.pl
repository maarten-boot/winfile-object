#! /usr/bin/perl -w

use warnings;
use strict;

$::DBG = 0;
$::VERBOSE = 1;

my $relocate = "G:/RELOCATE";

=pod


	FOR ALL FILES in $RELOCATE
	DO 
		CHECK_FILE
	DONE

	CHECK_FILE:
	
		a = md5 over path
		strip $RELOCATE
		b = md5 over original
		if( a is not b ) {
			complain
		}

=cut
