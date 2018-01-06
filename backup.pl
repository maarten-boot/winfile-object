#! /usr/bin/perl -w

use warnings;
use strict;

# ==============================================================

$::DBG 		= 0;
$::VERBOSE	= 1;
$::TEST		= 1;

# ==============================================================

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

sub backup_all
{
	my $os = $::THISAPP -> get_os();
	foreach my $name ($os -> get_filesystems()) {
		use aVolume;
		my $volume = aVolume -> new ($name,$os);
		$volume -> backup($name);		
		last if $::TEST;
	}
}

sub backup_path
{
	my $name = shift;
	
	# if we specify a path the volume should allways be the underlying real volume
	# otherwise we introduce false volumes here
	# TODO: separate volume and path
	
	use aVolume;
	my $os = $::THISAPP -> get_os();
	my $volume = aVolume -> new ($name,$os);
	$volume -> backup($name);		
}

# @@ MAIN
{
	$::THISAPP = ThisApp -> start("winfile");
	print STDERR "START " . scalar localtime(time) . "\n";
	
	backup_all();
	
	print STDERR "END " . scalar localtime(time) . "\n";
 	$::THISAPP -> finish();	# this never returns 
}
