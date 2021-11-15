=pod

=head1 NAME

ETL::Pipeline - Extract-Transform-Load pattern for data file conversions

=head1 SYNOPSIS

  use ETL::Pipeline;

  # The object oriented interface...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', iname => qr/Ficticious/},
    input     => ['Excel', iname => qr/\.xlsx?$/              ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'      },
    constants => {Type => 1, Information => 'Demographic'     },
    output    => ['SQL', table => 'NewData'                   ],
  } )->process;

  # Or using method calls...
  my $etl = ETL::Pipeline->new;
  $etl->work_in  ( search => 'C:\Data', iname => qr/Ficticious/ );
  $etl->input    ( 'Excel', iname => qr/\.xlsx?$/i              );
  $etl->mapping  ( Name => 'A', Address => 'B', ID => 'C'       );
  $etl->constants( Type => 1, Information => 'Demographic'      );
  $etl->output   ( 'SQL', table => 'NewData'                    );
  $etl->process;

=cut

package ETL::Pipeline;

use 5.014000;
use warnings;

use Carp;
use Data::DPath qw/dpath/;
use Data::Traverse qw/traverse/;
use List::AllUtils qw/any/;
use Moose;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class::Rule;
use Scalar::Util qw/blessed/;
use String::Util qw/hascontent trim/;


our $VERSION = '3.00';


=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. ETL isn't just for Data
Warehousing. ETL works on almost any type of data conversion. You read the
source, translate the data for your target, and store the result.

By dividing a conversion into 3 steps, we isolate the input from the output...

=over

=item * Centralizes data formatting and validation.

=item * Makes new input formats a breeze.

=item * Makes new outputs just as easy.

=back

B<ETL::Pipeline> takes your data files from extract to load. It reads an input
source, translates the data, and writes it to an output destination. For
example, I use these pipelines for reading an Excel spread sheet (input) and
saving the information in an SQL database (output).

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', find => qr/\.xlsx?$/],
    mapping   => {Name => 'A', Complaint => 'B', ID => 'C'},
    constants => {Client => 1, Type => 'Complaint'}
    output    => ['SQL', table => 'NewData']
  } )->process;

Or like this, calling the methods instead of through the constructor...

  use ETL::Pipeline;
  my $etl = ETL::Pipeline->new;
  $etl->work_in  ( search => 'C:\Data', find => qr/Ficticious/ );
  $etl->input    ( 'Excel', find => qr/\.xlsx?$/               );
  $etl->mapping  ( Name => 'A', Complaint => 'B', ID => 'C'    );
  $etl->constants( Client => 1, Type => 'Complaint'            );
  $etl->output   ( 'SQL', table => 'NewData'                   );
  $etl->process;

These are equivalent. They do exactly the same thing. You can pick whichever
best suits your style.

=head2 What is a pipeline?

The term I<pipeline> describes a complete ETL process - extract, transform,
and load. Or more accurately - input, mapping, output. Raw data enters one end
of the pipe (input) and useful information comes out the other (output). An
B<ETL::Pipeline> object represents a complete pipeline.

=head1 METHODS & ATTRIBUTES

=head2 Managing the pipeline

=head3 new

Create a new ETL pipeline. The constructor accepts a hash reference whose keys
are B<ETL::Pipeline> attributes. See the corresponding attribute documentation
for details about acceptable values.

=over

=item constants

=item data_in

=item input

=item mapping

=item on_record

=item output

=item session

=item work_in

=back

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# "_chain" is a special argument to the constructor that implements the
	# "chain" method. It copies information from an existing object. This allows
	# pipelines to share settings.
	#
	# Always handle "_chain" first. That way "work_in" and "data_in" arguments
	# can override the defaults.
	if (defined $arguments->{_chain}) {
		my $object = $arguments->{_chain};
		croak '"chain" requires an ETL::Pipeline object' unless
			defined( blessed( $object ) )
			&& $object->isa( 'ETL::Pipeline' )
		;
		$self->_work_in( $object->_work_in ) if defined $object->_work_in;
		$self->_data_in( $object->_data_in ) if defined $object->_data_in;
		$self->_session( $object->_session );
	}

	# The order of these two is important. "work_in" resets "data_in" with a
	# trigger. "work_in" must be set first so that we don't lose the value
	# from "data_in".
	if (defined $arguments->{work_in}) {
		my $values = $arguments->{work_in};
		$self->work_in( ref( $values ) eq '' ? $values : @$values );
	}
	if (defined $arguments->{data_in}) {
		my $values = $arguments->{data_in};
		$self->data_in( ref( $values ) eq '' ? $values : @$values );
	}

	# The input and output configurations may be single string values or an
	# array of arguments. It depends on what each source or destination expects.
	if (defined $arguments->{input}) {
		my $values = $arguments->{input};
		$self->input( ref( $values ) eq '' ? $values : @$values );
	}
	if (defined $arguments->{output}) {
		my $values = $arguments->{output};
		$self->output( ref( $values ) eq '' ? $values : @$values );
	}
}


=head3 chain

This method creates a new pipeline using the same L</work_in>, L</data_in>, and
L</session> as the current pipeline. It returns a new instance of
B<ETL::Pipeline>.

B<chain> takes the same arguments as L</new>. It passes those arguments through
to the constructor of the new object.

See the section on L</Multiple input sources> for examples of chaining.

=cut

sub chain {
	my ($self, $arguments) = @_;

	# Create the new object. Use the internal "_chain" argument to do the
	# actual work of chaining.
	if (defined $arguments) { $arguments->{_chain} = $self  ; }
	else                    { $arguments = {_chain => $self}; }

	return ETL::Pipeline->new( $arguments );
}


=head3 constants

B<constants> sets output fields to literal values. L</mapping> accepts input
field names as strings. Instead of obtuse Perl tricks for marking literals,
B<constants> explicitly handles them.

Hash keys are output field names. The L</output> class defines acceptable
field names. The hash values are literals.

  # Get the current mapping...
  my $transformation = $etl->constants;

  # Set the output field "Name" to the string "John Doe"...
  $etl->constants( Name => 'John Doe' );

B<Note:> B<constants> does not accept code references, array references, or hash
references. It only works with literal values. Use L</mapping> instead for
calculated items.

With no parameters, B<constants> returns the current hash reference. If you pass
in a hash reference, B<constants> replaces the current hash with this new one.
If you pass in a list of key value pairs, B<constants> adds them to the current
hash.

=head3 has_constants

Returns a true value if this pipeline has one or more constants defined. A false
value means no constants.

=cut

has '_constants' => (
	handles  => {_add_constants => 'set', has_constants => 'count'},
	init_arg => 'constants',
	is       => 'rw',
	isa      => 'HashRef[Maybe[Str]]',
	traits   => [qw/Hash/],
);


sub constants {
	my $self = shift;
	my @pairs = @_;

	if (scalar( @pairs ) == 1 && ref( $pairs[0] ) eq 'HASH') {
		return $self->_constants( $pairs[0] );
	} elsif (scalar @pairs) {
		return $self->_add_constants( @pairs );
	} else {
		return $self->_constants;
	}
}


=head3 data_in

The working directory (L</work_in>) usually contains the raw data files. In
some cases, though, the actual data sits in a subdirectory underneath
L</work_in>. B<data_in> tells the pipeline where to find the input file.

B<data_in> accepts a search pattern - name, glob, or regular expression. It
searches L</work_in> for the first matching directory. The search is case
insensitive.

If you pass an empty string to B<data_in>, the pipeline resets B<data_in> to
the L</work_in> directory. This is useful when chaining pipelines. If one
changes the data directory, the next in line can change back.

=cut

has '_data_in' => (
	coerce   => 1,
	init_arg => undef,
	is       => 'rw',
	isa      => Dir,
);


sub data_in {
	my $self = shift;

	if (scalar @_) {
		croak 'The working folder was not set' unless defined $self->_work_in;

		my $name = shift;
		if (hascontent( $name )) {
			my $next = Path::Class::Rule
				->new
				->min_depth( 1 )
				->iname( $name )
				->directory
				->iter( $self->_work_in )
			;
			my $match = $next->();
			croak 'No matching directories' unless defined $match;
			return $self->_data_in( $match );
		} else { return $self->_data_in( $self->_work_in ); }
	} else { return $self->_data_in; }
}


=head3 input

B<input> sets and returns the L<ETL::Pipeline::Input> object. This object reads
the data. With no parameters, B<input> returns the current
L<ETL::Pipeline::Input> object.

  my $source = $etl->input();

Set the input source by calling B<input> with parameters...

  $etl->input( 'Excel', find => qr/\.xlsx/i );

The first parameter is a class name. B<input> looks for a Perl module matching
this name in the C<ETL::Pipeline::Input> namespace. In this example, the actual
class name becomes C<ETL::Pipeline::Input::Excel>.

The rest of the parameters are passed directly to the C<new> method of that
class.

B<Technical Note:> Want to use a custom class from B<Local> instead of
B<ETL::Pipeline::Input>? Put a B<+> (plus sign) in front of the class name.
For example, this command uses the input class B<Local::CustomExtract>.

  $etl->input( '+Local::CustomExtract' );

=cut

has '_input' => (
	does     => 'ETL::Pipeline::Input',
	init_arg => undef,
	is       => 'rw',
);


sub input {
	my $self = shift;

	return $self->_input( $self->_object_of_class( 'Input', @_ ) ) if (scalar @_);
	return $self->_input;
}


=head3 mapping

B<mapping> ties the input fields with the output fields. Hash keys are output
field names. The L</output> class defines acceptable field names. The hash
values can be anything accepted by the L</get> method. See L</get> for more
information.

If L</get> returns an ARRAY reference (aka multiple values), they will be
concatenated in the output with a semi-colon between values - B<; >. You can
override the seperator by setting the value to an ARRAY reference. The first
element is a regular field name for L</get>. The second element is a new
seperator string.

With no parameters, B<mapping> returns the current hash reference. If you pass
in a hash reference, B<mapping> replaces the current hash with this new one. If
you pass in a list of key value pairs, B<mapping> adds them to the current hash.

  # Get the current mapping...
  my $transformation = $etl->mapping;

  # Add the output field "Name" with data from input column "A"...
  $etl->mapping( Name => 'A' );

  # Change "Name" to get data from "Full Name" or "FullName"...
  $etl->mapping( Name => qr/Full\s*Name/i );

  # "Name" gets the lower case of input column "A"...
  $etl->mapping( Name => sub {
    my ($etl, $record) = @_;
    return lc $record{A};
  } );

  # Replace the entire mapping so only "Name" is output...
  $etl->mapping( {Name => 'C'} );

Want to save a literal value? Use L</constants> instead.

=head3 has_mapping

Returns a true value if this pipeline has one or more field mappings defined. A
false value means no mappings are present.

=cut

has '_mapping' => (
	handles  => {_add_mapping => 'set', has_mapping => 'count'},
	init_arg => 'mapping',
	is       => 'rw',
	isa      => 'HashRef',
	traits   => [qw/Hash/],
);


sub mapping {
	my $self = shift;
	my @pairs = @_;

	if (scalar( @pairs ) == 1 && ref( $pairs[0] ) eq 'HASH') {
		return $self->_mapping( $pairs[0] );
	} elsif (scalar @pairs) {
		return $self->_add_mapping( @pairs );
	} else {
		return $self->_mapping;
	}
}


=head3 on_record

Executes a customized subroutine on every record before any mapping. The code
can modify the record and your changes will feed into the mapping. You can use
B<on_record> for filtering, debugging, or just about anything.

B<on_record> accepts a code reference. L</record> executes this code for every
input record.

The code reference receives two parameters - the C<ETL::Pipeline> object and the
input record. The record is passed as a hash reference. If B<on_record> returns
a false value, L</record> will never send this record to the output destination.
It's as if this record never existed.

  ETL::Pipeline->new( {
    ...
    on_record => sub {
      my ($etl, $record) = @_;
      foreach my $field (keys %$record) {
        my $value = $record->{$field};
        $record->{$field} = ($value eq 'NA' ? '' : $value);
      }
    },
    ...
  } )->process;

  # -- OR --
  $etl->on_record( sub {
    my ($etl, $record) = @_;
    foreach my $field (keys %$record) {
      my $value = $record->{$field};
      $record->{$field} = ($value eq 'NA' ? '' : $value);
    }
  } );

B<Note:> L</record> automatically removes leading and trailing whitespace. You
do not need B<on_record> for that.

=cut

has 'on_record' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef]',
);


=head3 output

B<output> sets and returns the L<ETL::Pipeline::Output> object. This object
writes records to their final destination. With no parameters, B<output> returns
the current L<ETL::Pipeline::Output> object.

Set the output destination by calling B<output> with parameters...

  $etl->output( 'SQL', table => 'NewData' );

The first parameter is a class name. B<output> looks for a Perl module
matching this name in the C<ETL::Pipeline::Output> namespace. In this example,
the actual class name becomes C<ETL::Pipeline::Output::SQL>.

The rest of the parameters are passed directly to the C<new> method of that
class.

B<Technical Note:> Want to use a custom class from B<Local> instead of
B<ETL::Pipeline::Output>? Put a B<+> (plus sign) in front of the class name.
For example, this command uses the input class B<Local::CustomLoad>.

  $etl->output( '+Local::CustomLoad' );

=cut

has '_output' => (
	does     => 'ETL::Pipeline::Output',
	init_arg => undef,
	is       => 'rw',
);


sub output {
	my $self = shift;

	return $self->_output( $self->_object_of_class( 'Output', @_ ) ) if (scalar @_);
	return $self->_output;
}


=head3 process

B<process> kicks off the entire data conversion process. It takes no
parameters. All of the setup is done by the other methods.

B<process> returns the B<ETL::Pipeline> object so you can do things like
this...

  ETL::Pipeline->new( {...} )->process->chain( ... )->process;

=cut

sub process {
	my $self = shift;

	# Make sure we have all the required information.
	my ($success, $error) = $self->is_valid;
	croak $error unless $success;

	# Kick off the process. The input source loops over the records. It calls
	# the "record" method, described below.
	$self->_output->open( $self );
	$self->status( 'START' );
	$self->_input->run( $self );
	$self->status( 'END' );
	$self->_output->close( $self );

	# Return the pipeline object so that we can chain calls. Useful shorthand
	# when running multiple pipelines.
	return $self;
}


=head3 session

B<ETL::Pipeline> supports sessions. A session allows input and output objects
to share information along a chain. For example, imagine 3 Excel files being
loaded into an Access database. All 3 files go into the same Access database.
The first pipeline creates the database and saves its path in the session. That
pipeline chains with a second pipeline. The second pipeline retrieves the
Access filename from the session.

The B<session> method provides access to session level variables. As you write
your own L<ETL::Pipeline::Output> classes, they can use session variables for
sharing information.

The first parameter is the variable name. If you pass only the variable name,
B<session> returns the value.

  my $database = $etl->session( 'access_file' );
  my $identifier = $etl->session( 'session_identifier' );

A second parameter is the value.

  $etl->session( access_file => 'C:\ExcelData.accdb' );

You can set multiple variables in one call.

  $etl->session( access_file => 'C:\ExcelData.accdb', name => 'Abe' );

If you pass in a hash referece, it completely replaces the current session with
the new values.

When retrieving an array or hash reference, B<session> automatically
derefernces it if called in a list context. In a scalar context, B<session>
returns the reference.

  # Returns the list of names as a list.
  foreach my $name ($etl->session( 'name_list' )) { ... }

  # Returns a list reference instead of a list.
  my $reference = $etl->session( 'name_list' );

=head3 session_has

B<session_has> checks for a specific session variable. It returns I<true> if
the variable exists and I<false> if it doesn't.

B<session_has> only checks existence. It does not tell you if the value is
defined.

  if ($etl->session_has( 'access_file' )) { ... }

=cut

# Alternate design: Use attributes for session level information.
# Result: Discarded
#
# Instead of keeping session variables in a hash, the class would have an
# attribute corresponding to the session data it can keep. Since
# ETL::Pipeline::Input and ETL::Pipeline::Output objects have access to the
# the pipeline, they can share data through the attributes.
#
# For any session information, the developer must subclass ETL::Pipeline. The
# ETL::Pipeline::Input or ETL::Pipeline::Output classes would be tied to that
# specific subclass. And if you needed to combine two sets of session
# variables, well that just means another class type. That's very confusing.
#
# Attributes make development of new input and output classes very difficult.
# The hash is simple. It decouples the input/output classes from pipeline.
# That keeps customization simpler.


has '_session' => (
	default => sub { {} },
	handles => {
		_add_session => 'set',
		_get_session => 'get',
		session_has  => 'exists',
	},
	init_arg => undef,
	is       => 'rw',
	isa      => 'HashRef[Any]',
	traits   => [qw/Hash/],
);


sub session {
	my $self = shift;

	if (scalar( @_ ) > 1) {
		my %parameters = @_;
		while (my ($key, $value) = each %parameters) {
			$self->_add_session( $key, $value );
		}
		return $_[1];
	} elsif (scalar( @_ ) == 1) {
		my $key = shift;
		if (ref( $key ) eq 'HASH') {
			return $self->_session( $key );
		} elsif (wantarray) {
			my $result = $self->_get_session( $key );
			if    (ref( $result ) eq 'ARRAY') { return @$result; }
			elsif (ref( $result ) eq 'HASH' ) { return %$result; }
			else                              { return  $result; }
		} else { return $self->_get_session( $key ); }
	} else { return undef; }
}


=head3 work_in

The working directory sets the default place for finding files. All searches
start here and only descend subdirectories. Temporary or output files go into
this directory as well.

B<work_in> has two forms: C<work_in( 'C:\Data' );> or
C<< work_in( root => 'C:\Data', iname => 'Ficticious' ); >>.

The first form specifies the exact directory path. In our example, the working
directory is F<C:\Data>.

The second form searches the file system for a matching directory. Take this
example...

  $etl->work_in( root => 'C:\Data', iname => 'Ficticious' );

It scans the F<C:\Data> directory for a subdirectory named F<Fictious>, like
this: F<C:\Data\Ficticious>. The search is B<not> recursive. It locates files
in the B<root> folder.

B<work_in> accepts any of the tests provided by L<Path::Iterator::Rule>. The
values of these arguments are passed directly into the test. For boolean tests
(e.g. readable, exists, etc.), pass an C<undef> value.

B<work_in> automatically applies the C<directory> filter. Do not set it
yourself.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'Excel', iname => qr/\.xlsx$/ );

  # Search using a file glob...
  $etl->input( 'Excel', iname => '*.xlsx' );

The code throws an error if no directory matches the criteria. Only the first
match is used.

B<work_in> automatically resets L</data_in>.

=cut

has '_work_in' => (
	coerce   => 1,
	init_arg => undef,
	is       => 'rw',
	isa      => Dir,
	trigger  => \&_trigger_work_in,
);


sub work_in {
	my $self = shift;

	if (scalar( @_ ) == 1) {
		return $self->_work_in( shift );
	} elsif(scalar( @_ ) > 1) {
		my %options = @_;

		my $root = $options{root} // '.';
		delete $options{root};

		if (scalar %options) {
			my $rule = Path::Class::Rule->new->directory;
			while (my ($name, $value) = each %options) {
				eval "\$rule = \$rule->$name( \$value )";
				confess $@ unless $@ eq '';
			}
			my $next = $rule->iter( $root );
			my $match = $next->();
			croak 'No matching directories' unless defined $match;
			return $self->_work_in( $match );
		} else { return $self->_work_in( $root ); }
	} else { return $self->_work_in; }
}


sub _trigger_work_in {
	my $self = shift;
	my $new  = shift;

	# Force absolute paths. Changing the value will fire this trigger again.
	# I only want to change "_data_in" once.
	if (defined( $new ) && $new->is_relative) {
		$self->_work_in( $new->cleanup->absolute );
	} else {
		$self->_data_in( $new );
	}
}


=head2 Used in mapping

These methods may be used by code references in the L</mapping> attribute. They
will return information about/from the current record.

=head3 count

This attribute tells you how many records have been read from the input source.
This value is incremented before any filtering. So it even counts records that
are bypassed by L</on_record>.

The first record is always number B<1>.

=cut

has 'count' => (
	default => '0',
	handles => {_increment_count => 'inc'},
	is      => 'ro',
	isa     => 'Int',
	traits  => [qw/Counter/],
);


=head3 get

Retrieve the value from the record for the given field name. This method accepts
two parameters - a field name and the current record. It returns the exact value
found at the matching node.

=head4 Field names

The field name can be a string, regular expression reference, or code reference.

A string matches both field names and aliases. The string is used as a
L<Data::DPath>. L<Data::DPath> allows for some complex selections from data
structures of any depth - like those from XML or JSON. For simplicity, B<get>
automatically adds the leading B</> if needed. That way, you can use simple
field names for flat data structures.

A string can match more than just a hard coded field name. It can be any
expression accepted by L<Data::DPath> - even those with regular expressions
embedded in the path string. While B<get> makes the most common cases very easy,
you can always use the full range of L<Data::DPath> on complex structures.

When the field name is a regular expression, it matches fields and aliases at
the top level. You can do the same thing with the L<Data::DPath> syntax. B<get>
provides this shortcut because it's easier to read.

When the field name is a code reference, B<get> executes the subroutine. The
return value becomes the field value. A code reference is called in a scalar
context. If you need to return multiple values, then return an ARRAY or HASH
reference.

The code reference receives two parameters - the B<ETL::Pipeline> object and the
current record.

=head4 Current record

The current record is optional. B<get> will use L</this> if you do not pass in a
record. By accepting a record, you can use B<get> on sub-records. So by default,
B<get> returns a value from the top record. Use the second parameter to retrieve
values from a sub-record.

=head4 Return value

B<get> always returns a scalar value, but not always a string. The return value
might be a string, ARRAY reference, or HASH reference.

B<get> does not flatten out the nodes that it finds. It merely returns a
reference to whatever is in the data structure at the named point. The calling
code must account for the possibility of finding an array or hash or string.

=cut

sub get {
	my ($self, $field, $record) = @_;
	my @found = ();

	# Use the current record from the attribute unless the programmer explicilty
	# sent in a record. By sending in a record, "get" works on sub-records. But
	# the default behaviour is what you would expect.
	$record = $self->this unless defined $record;

	# Execute code reference.
	if (ref( $field ) eq 'CODE') {
		@found = $field->( $self, $record );
	}

	# Match field names to regular expression.
	elsif (ref( $field ) eq 'Regexp') {
		@found = dpath( "//*[key =~ /$field/]" )->match( $record );
	}

	# Strings are field names.
	else {
		my $path = $field =~ m|^/| ? $field : "/$field";
		@found = dpath( $path )->match( $record );
	}

	# Send back the final value.
	return (scalar( @found ) <= 1 ? $found[0] : \@found);
}


=head3 this

The current record. The L</record> method sets B<this> before it does anything
else. L</get> will use B<this> if you don't pass in a record. It makes a
convenient shortcut so you don't have to pass the record into every call.

B<this> is a hash reference.

=cut

has 'this' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'Maybe[HashRef[Any]]',
	writer  => '_set_this',
);


=head2 Used by input sources

=head3 add_alias

This method defines an alternate name for fields. The L</get> method can look up
fields by this alternate name instead. Most often used by input sources from
flat files such as Excel or CSV. Formats that may have column headers. An input
source would read the column headers then call this method to save the alias
for L</get>.

I store the aliases as a list. It is possible for files to use the same column
header more than once. By using a list, I ensure that data is not lost.

The field name can be any valid L</Data::Dpath>. L</get> will add the leading
slash - B</> - if needed.

=cut

has '_alias' => (
	default => sub { [] },
	handles => {
		_add_alias  => 'push',
		aliases     => 'elements',
		has_aliases => 'count',
	},
	init_arg => undef,
	is       => 'ro',
	isa      => 'ArrayRef[HashRef[Str]]',
	traits   => [qw/Array/],
);


sub add_alias {
	my ($self, $alias, $field) = @_;

	# Save the mapping.
	$self->_add_alias( {$alias => $field} );

	# Count instances so I can put values for repeated names in an ARRAY.
	my $count = $self->_alias_name;
	$count->{$alias}++;
}


has '_alias_name' => (
	default => sub { {} },
	handles => {_alias_name_count => 'get'},
	init_arg => undef,
	is       => 'ro',
	isa      => 'HashRef[Int]',
	traits   => [qw/Hash/],
);


=head3 record

The input source calls this method for each data record. This is where
L<ETL::Pipeline> applies the mapping, constants, and sends the results on to the
L<ETL::Pipeline> applies the mapping, constants, and sends the results on to the
output destination.

=cut

sub record {
	my ($self, $record) = @_;

	# Set aliases for fields. This way Data::Path can do all of the work
	# retrieving values. That lets us use complex queries, such as regular
	# expression matches that return more than one column.
	#
	# What if two fields have the same header (aka alias)? I count the unique
	# alias names as they're added. If more than one matches, I assign an ARRAY
	# reference to the alias and put the multiple values in the ARRAY.
	foreach my $item ($self->aliases) {
		while (my ($alias, $field) = each %$item) {
			if ($self->_alias_name_count( $alias ) > 1) {
				$record->{$alias} = [] unless exists $record->{$alias};
				my $list = $record->{$alias};
				push @$list, $record->{$field};
			} else {
				$record->{$alias} = $record->{$field};
			}
		}
	}

	# Save the current record so that other methods and helper functions can
	# access it without the programmer passing it around.
	$self->_set_this( $record );

	# Increase the record count. That way the count always shows the current
	# record number.
	$self->_increment_count;

	# Remove leading and trailing whitespace from all fields. We always want to
	# do this. Otherwise we end up with weird looking text. I do this first so
	# that all the customized code sees is the filtered data.
	traverse { trim( m/HASH/ ? $b : $a ) } $record;

	# Run the custom record filter, if there is one. If the filter returns
	# "false", then we bypass this entire record.
	my $code     = $self->on_record;
	my $continue = 1;

	$continue = $code->( $self, $record ) if defined $code;
	return unless $continue;

	# Insert constants into the output. Do this before the mapping. The mapping
	# will always override constants. I want data from the input.
	#
	# I had used a regular hash. Perl kept re-using the same memory location.
	# The records were overwriting each other. Switched to a hash reference so I
	# can force Perl to allocate new memory for every record.
	my $save = {};
	if ($self->has_constants) {
		my $constants = $self->_constants;
		%$save = %$constants;
	}

	# This is the transform step. It converts the input record into an output
	# record.
	my $mapping = $self->mapping;
	while (my ($to, $from) = each %$mapping) {
		my $seperator = '; ';
		if (ref( $from ) eq 'ARRAY') {
			$seperator = $from->[1];
			$from = $from->[0];	# Do this LAST!
		}

		my @values = $self->get( $from, $record );
		if (scalar( @values ) <= 1) {
			$save->{$to} = $values[0];
		} elsif (any { defined } @values) {
			$save->{$to} = join $seperator, grep { defined } @values;
		} else {
			$save->{$to} = undef;
		}
	}

	# We're done with this record. Finish up.
	$self->_output->write( $self, $save );
	$self->status( 'STATUS' );
}


=head3 status

This method displays a status message. B<ETL::Pipeline> calls this method to
report on the progress of pipeline. It takes one or two parameters - the message
type (required) and the message itself (optional).

The type can be anything. These are the ones that B<ETL::Pipeline> uses...

=over

=item END

The pipeline has finished. The input source is closed. The output destination
is still open. It will be closed immediately after. There is no message text.

=item ERROR

Report an error message to the user. These are not necessarily fatal errors.

=item INFO

An informational message to the user.

=item START

The pipeline is just starting. The output destination is open. But the input
source is not. There is no message text.

=item STATUS

Progress update. This is sent every after every input record.

=back

This method merely passes the parameters through to L</$ETL::Pipeline::log>. See
L</$ETL::Pipeline::log> for more information about displaying messages.

=cut

sub status {
	my ($self, $type, $message) = @_;
	return $ETL::Pipeline::log->( $self, $type, $message )
		if ref( $ETL::Pipeline::log ) eq 'CODE';
}


=head2 Other

=head3 is_valid

This method returns true or false. True means that the pipeline is ready to
go. False, of course, means that there's a problem. In a list context,
B<is_invalid> returns the false value and an error message. On success, the
error message is C<undef>.

=cut

sub is_valid {
	my $self = shift;
	my $error = '';

	if (!defined $self->_work_in) {
		$error = 'The working folder was not set';
	} elsif (!defined $self->_input) {
		$error = 'The "input" object was not set';
	} elsif (!defined $self->_output) {
		$error = 'The "output" object was not set';
	} elsif (!$self->has_mapping && !$self->has_constants) {
		$error = 'The mapping was not set';
	}

	if (wantarray) {
		return (($error eq '' ? 1 : 0), $error);
	} else {
		return ($error eq '' ? 1 : 0);
	}
}


=head3 $ETL::Pipeline::log

This package variable shows progress to the user. The variable holds a code
reference. The code reference is executed by the L</status> method.

The default value writes messages to the screen (standard output). If you want
to use log files, then write your own subroutine and assign this variable to it.
The same would also work for a GUI front end.

Why isn't it a method or attribute? Because overriding this behaviour should be
global to all pipelines. This is not the kind of functionality that changes
between pipelines.

The code reference receives two or three parameters - the B<ETL::Pipeline>
object, the message type, and the optional message text.

You should never execute this code directly. Call the L</status> method instead.
That method executes the code reference with all the right parameters.

=cut

my $log = sub {
	my ($etl, $type, $message) = @_;
	$type = uc( $type );

	if ($type eq 'START') {
		my $name;
		if ($etl->_input->does( 'ETL::Pipeline::Input::File' )) {
			$name = $etl->_input->file->relative( $etl->_work_in );
		} else {
			$name = ref( $etl->_input );
			$name =~ s/^ETL::Pipeline::Input:://;
		}
		say "Processing '$name'...";
	} elsif ($type eq 'END') {
		my $name;
		if ($etl->_input->does( 'ETL::Pipeline::Input::File' )) {
			$name = $etl->_input->file->relative( $etl->_work_in );
		} else {
			$name = ref( $etl->_input );
			$name =~ s/^ETL::Pipeline::Input:://;
		}
		say "Finished '$name'!";
	} elsif ($type eq 'STATUS') {
		my $count = $etl->count;
		say "Processed record #$count..." unless $count % 50;
	} else {
		say "$type: $message";
	}
};


#----------------------------------------------------------------------
# Internal methods and attributes.

# This private method creates the ETL::Pipeline::Input and ETL::Pipeline::Output
# objects. It allows me to centralize the error handling. The program dies if
# there's an error. It means that something is wrong with the corresponding
# class. And I don't want to hide those errors. You can only fix errors if you
# know about them.
#
# Override or modify this method if you want to perform extra checks.
#
# The first parameter is a string with either "Input" or "Output".
# The method appends this value onto "ETL::Pipeline". For example, "Input"
# becomes "ETL::Pipeline::Input".
#
# The rest of the parameters are passed directly into the constructor for the
# class this method instantiates.
sub _object_of_class {
	my $self = shift;
	my $action = shift;

	my @arguments = @_;
	@arguments = @{$arguments[0]} if
		scalar( @arguments ) == 1
		&& ref( $arguments[0] ) eq 'ARRAY'
	;

	my $class = shift @arguments;
	if ($class =~ m/^\+/) {
		$class =~ s/^\+//;
	} elsif ($class !~ m/^ETL::Pipeline::$action/) {
		$class = "ETL::Pipeline::${action}::$class";
	}

	my %attributes = @arguments;
	$attributes{pipeline} = $self;

	my $object = eval "use $class; $class->new( \%attributes )";
	croak "Error creating $class...\n$@\n" unless defined $object;
	return $object;
}


=head1 ADVANCED TOPICS

=head2 Multiple input sources

It is not uncommon to receive your data spread across more than one file. How
do you guarantee that each pipeline pulls files from the same working directory
(L</work_in>)? You L</chain> the pipelines together.

The L</chain> method works like this...

  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', iname => 'main.xlsx'              ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process->chain( {
    input     => ['Excel', iname => 'notes.xlsx'        ],
    mapping   => {User => 'A', Text => 'B', Date => 'C' },
    constants => {Type => 2, Information => 'Note'      },
    output    => ['SQL', table => 'OtherData'           ],
  } )->process;

When the first pipeline finishes, it creates a new object with the same
L</work_in>. The code then calls L</process> on the new object. The second
pipeline copies L</work_in> from the first pipeline.

=head2 Writing an input source

B<ETL::Pipeline> provides some basic, generic input sources. Inevitably, you
will come across data that doesn't fit one of these. No problem.
B<ETL::Pipeline> lets you create your own input sources.

An input source is a L<Moose> class that implements the L<ETL::Pipeline::Input>
role. The role requires that you define the L<ETL::Pipeline::Input/run> method.
B<ETL::Pipeline> calls that method. Name your class B<ETL::Pipeline::Input::*>
and the L</input> method can find it automatically.

See L<ETL::Pipeline::Input> for more details.

=head2 Writing an output destination

B<ETL::Pipeline> does not have any default output destinations. Output
destinations are customized. You have something you want done with the data.
And that something intimately ties into your specific business. You will have
to write at least one output destination to do anything useful.

An output destination is a L<Moose> class that implements the
L<ETL::Pipeline::Output> role. The role defines required methods.
B<ETL::Pipeline> calls those methods. Name your class
B<ETL::Pipeline::Output::*> and the L</output> method can find it automatically.

See L<ETL::Pipeline::Output> for more details.

=head2 Why are the inputs and outputs separate?

Wouldn't it make sense to have an input source for Excel and an output
destination for Excel?

Input sources are generic. It takes the same code to read from one Excel file
as another. Output destinations, on the other hand, are customized for your
business - with data validation and business logic.

B<ETL::Pipeline> assumes that you have multiple input sources. Different
feeds use different formats. But output destinations will be much fewer.
You're writing data into a centralized place.

For these reasons, it makes sense to keep the input sources and output
destinations separate. You can easily add more inputs without affecting the
outputs.

=head1 SEE ALSO

L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output>

=head2 Input Source Formats

L<ETL::Pipeline::Input::Excel>, L<ETL::Pipeline::Input::DelimitedText>,
L<ETL::Pipeline::Input::JsonFiles>, L<ETL::Pipeline::Input::Xml>,
L<ETL::Pipeline::Input::XmlFiles>

=head1 REPOSITORY

L<https://github.com/rbwohlfarth/ETL-Pipeline>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021  Robert Wohlfarth

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
