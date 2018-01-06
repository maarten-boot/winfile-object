# =======================================================

use warnings;
use strict;

# =======================================================
# AITEM
=pod

	On the Item level all common attributes are stored that are 
	the same for each item. Item being one of ( File Dir Link Socket ... )
	
	On this level we maintain the Attributes database.
	to store posix attributes and later ACL realted data
	
	Based on mtime we can see if a file has changed at all
	We can double check with the file length.
	
	In case of attribute changes except mtime we can skip the contents 
	of the item and just update the attribute data store

	After data of an item is stored we check again the mtime and 
	signal suspect if during the backup the file data was modified


=cut

# =======================================================
package aItem;
# =======================================================

use lib './lib';
use aApp;
use aFile;

use DB_File;
use Fcntl;

my %fields = (
	'path' => undef,
	'type' => undef,
	'posix-attrs' => undef,

	'suspect' => 0,

	'key' => undef,
	'att-db' => undef,
);

sub new 
{
	my $class = shift;
	my $item = {
		%fields,
	};
	bless $item , $class;

	{
		my $n1 = 'ATTRIBUTES.DB';
		my $n2 = 'att-db';

		# open the db
		my $db = $::THISAPP -> lookup($n1);
		if( defined $db ) {
			$item -> {$n2} = $db;
		} else {
			$db = $item -> {$n2} = aDB -> new($n1);
			$::THISAPP -> register($n1,$db);
		}
	}

	return $item;
}

sub make_key
{
	my $self = shift;
	
	my $dir_id = shift;
	my $basename = shift;
	my $type = shift;
	
	my $key = "$dir_id\000$basename\000$type";	
	$self -> {'key'} = $key;
	
	return $key;
}

sub get_att_db 
{
	my $item = shift;
	return $item -> {'att-db'};
}

sub suspect
{
	my $item = shift;	

	$item -> {'suspect'} = 1;
	print "!!\tTHIS ITEM IS SUSPECT (some change occurred during the backup if this item)\n";
}

sub do_one_file
{
	my $item = shift;
	
	my $dir_id = shift;
	my $basename = shift;
	my $type = shift;
	
	print "\tDO_ONE_FILE: $dir_id,$basename,$type\n" if $::DBG;

	my $file = aFile -> open_read_only($dir_id,$basename);
	return unless defined $file;
	
	$file -> file_backup();
}

sub has_changed
{
	my $item = shift;

	my $key = shift;
	my $val = shift;

	my $old_val = $item -> {'att-db'} -> get($key);
	
	# if any attribute is different we flag the item as changed currently
	# later we can add more sophisticated ways based on separate parts of the attributes

	if(!defined $old_val ) {
		$item -> {'att-db'} -> put($key,$val);
		#print "NEW ITEM: $key\n";
		return 2;
	}

	if($old_val ne $val) {
		$item -> {'att-db'} -> put($key,$val);
		#print "ATTRS CHANGED: $key\n";
		return 1;
	}

	#print "NO ATTRS CHANGED: $key\n";
	return 0;
}

# ===============================================================
1;
