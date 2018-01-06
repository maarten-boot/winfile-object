# test aDB

use aDB;

{
	my $db = aDB -> new('XX.DB');

	$db -> put('aaa','bbb');
	print '!', $db -> get('aaa'),'!', "\n";
	$db -> sync;
}
