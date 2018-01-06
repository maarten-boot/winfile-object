use aGensym;

{
	my $gs = aGensym -> new('zz');

	print $gs -> next();
	print $gs -> next();
}

{
	my $gs = aGensym -> new('zz');

	print $gs -> next();
	print $gs -> next();
}
