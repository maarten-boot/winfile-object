package SESSION;

use Carp;

use warnings;
use strict;

my %fields = (
	machine_name => undef,
	machine_os => undef,
	machine_type => undef,
	machine_user => undef,
	machine_passwd => undef,
	generate_passwd => undef,
	validate_passwd => undef,
	session_id => undef,
	session_start => undef,
	session_end => undef,
	filesystems => undef,
);

# = CLASS VARIABLES

# handles for the tied hash for persistent storing of the session

my $SESSION;
my %SESSION;

# = CLASS MESSAGES

sub new 
{
	my $that = shift;
	my $class = ref($that) || $that;

	my 	$self = { %fields };

	# INITIALIZE what machine
	
	# initialize the start time
	
	# initialize the session id
	
	bless $self, $class;
	return $self;
}

# = INSTANCE MESSAGES
sub detect_filesystems 
{

}

sub AUTOLOAD {
	no strict 'vars';
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	my $name = $AUTOLOAD;

	$name =~ s/.*://; # strip fully qualified portion
	unless (exists $self -> {$name} ) {
		croak "Can't acess '$name' field in object of class $type";
	}

	if(@_) {
		return $self -> {$name} = shift;
	} else {
		return $self -> {$name};
	}
}

# DESTROY closes the hash/ tie dbm
1;

