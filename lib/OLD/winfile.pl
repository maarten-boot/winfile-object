#! /usr/bin/perl -w

use warnings;
use strict;

$::DBG = 0;

use lib './lib';
use aApp;

# ==============================================================
package ThisApp;

@ThisApp::ISA = ( 'aApp' );

use aMachine;

sub start 
{
	my $class = shift;
	my $name = shift;

	my $self = aApp -> start("$name");

	my $machine = $self -> {'machine'}  = aMachine -> new();
	$self -> {'os'} = $machine -> get_os();

	return $self;
}

# ==============================================================
package main;

# @@ MAIN
{
	$::THISAPP = ThisApp -> start("winfile");

	my $os = $::THISAPP -> get_os();
	
	foreach my $name ($os -> get_filesystems()) {
		use aVolume;
		my $volume = aVolume -> new ($name,$os);
		$volume -> backup();
		last;
	}
 	$::THISAPP -> finish();
}
