=pod

=head1 NAME

Data::ETL - Extract-Transform-Load pattern for converting data

=SYNOPSIS

  use Data::ETL;

  working_folder search_in => 'C:\Data', find_folder => qr/Pine/;
  extract_from 'Excel', find_file => qr/\.xlsx?$/;
  transform_as Name => 'A', Address => 'B', Birthday => 'C';
  set Client => 1, Type => 'Person';
  load_into 'Access', file => 'review.accdb';
  run;

=cut

package Data::ETL;

use 5.14.0;
use Exporter qw/import/;
use File::Find::Rule;
use String::Util qw/hascontent/;


our @EXPORT  = qw/extract_from transform_as set load_into run working_folder/;
our $VERSION = '1.00';


=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

By dividing a conversion into 3 steps, we isolate the input from the output.
The isolation lets us:

=over

=item * Centralize data formatting and validation.

=item * Add new input formats with ease.

=item * Swap files and databases without changing application code.

=back

=head2 How does the ETL module work?

B<Data::ETL> provides commands as a front end to various data related classes.
The classes do the actual work. The commands let you write a little script
without having to master all of the minute details yourself.

The L</SYNOPSIS> gives a pretty accurate example. You configure the input
file, translate file fields into database fields, then save the data to the
database. The L</load_into> performs all of the validation.

B<Data::ETL> does it work using helper classes. These classes all fall under
the naming convention I<Data::ETL::Extract::*> or I<Data::ETL::Load::*>.
Notice that L</extract_from> and L<load_into> take a format name as their
first parameter? In our example, L</extract_from> loads the helper class
I<Data::ETL::Extract::Excel>. And L</load_into> writes the records using the
helper class I<Data::ETL::Load::Access>. B<Data::ETL> automatically prepends
the I<Data::ETL::Extract> or I<Data::ETL::Load>.

B<Data::ETL> provides a few generic I<Data::ETL::Extract::*> classes. These
classes work for any file based input - regardless of content. If you receive
your data through files, then these classes will work for you.

Most times, your organization writes its own I<Data::ETL::Load::*> class. This
class performs any specialized tasks such as validation or conversion. The
I<Data::ETL::Load::*> classes are tied closely with your internal data format.

=head2 How do I use the ETL module?

First, you write an ETL script. Your script looks much like the L</SYNOPSIS>.
You execute the ETL script like any other Perl program. That's it. The ETL
script reads data in and sends it back out.

An ETL script must have at least one of each of the four commands:
L</extract_from>, L</transform>, L</load_into>, and L</run>. Technically, an
ETL script is just a Perl script. You may use any Perl commands or modules.

=head1 COMMANDS

=head3 extract_from

This command configures the input source. The ETL script reads data from this
source.

The first parameter is the name of the input format. The format is a Perl
module under the L<Data::ETL::Extract> namespace. C<extract_from> 
automatically adds the B<Data::ETL::Extract> to the start of the class name.

After the format class, you may pass in a hash of attributes for the format
class. C<extract_from> passes the rest of the parameters directly to the input 
source class.

=cut

my $extract;

sub extract_from {
	my $class      = shift @_;
	my %attributes = @_;

	$class = "Data::ETL::Extract::$class"
		unless $class =~ m/^Data::ETL::Extract/;
	$extract = eval "use $class; $class->new( \%attributes )";
}


=head3 transform_as

This command configures the transformation process. It copies data from input
fields to a corresponding output field. 

This method accepts a hash as its only parameter. The keys are output field
names. The values are input field names or code references. For field names, 
L</run> simply copies the data from the input field to the output field.

With a code reference, L</run> executes the code and stores the return value
as the output field. L</run> sets C<$_> to the current L<Data::ETL::Extract> 
object. You can access the raw data using L<Data::ETL::Extract/get>, like this:

  transform_as Name => sub { $_->get( 'A' ) // $_->get( 'B' ) };

=cut

my %mapping;

sub transform_as {
	my %add = @_;
	@mapping{keys %add} = values %add;
}


=head3 load_into

This command configures the data destination. Data destinations are Perl
modules under the L<Data::ETL::Load> namespace.

The first parameter names the data destination class. C<load_into> 
automatically adds the B<Data::ETL::Load> to the beginning of the class name.

After the format class, you may pass in a hash of attributes for the data
destination class. C<load_into> passes the rest of the parameters directly
to the input source class.

=cut

my $load;

sub load_into {
	my $class      = shift @_;
	my %attributes = @_;

	$class = "Data::ETL::Load::$class" unless $class =~ m/^Data::ETL::Load/;
	$load = eval "use $class; $class->new( \%attributes )";
}


=head3 set

This command sets hard coded output fields. It accepts a hash as its only
parameter. The keys are output field names. The values are, well, the
corresponding values that you want in that field.

If the same field shows up in both L</transform> and L</set>, the
L</transform> value is used. Data from the input source overrides constants.

You can also pass a code reference as the value. In this case, L</run> executes
the code and stores the return value as the output field. L</run> sets C<$_> to
the current L<Data::ETL::Load> object. You may find it useful for grabbing 
information out of your database.

=cut

my %constants;

sub set {
	my %add = @_;
	@constants{keys %add} = values %add;
}


=head3 run

This command kicks off the entire data conversion process. It takes no
parameters. All of the setup is done by the other commands. This should be
the last command in your ETL script. And 90% of the time, it will be.

There are rare cases when the input data spans multiple files. B<Data::ETL>
supports processing multiple files inside one ETL script. For example...

  use Data::ETL;
  
  # The first file has demographic details.
  extract_from 'Excel', path => 'C:\Pine\Details.xlsx';
  transform_as Name => 'A', Address => 'B', Birthday => 'C';
  set Client => 1, Type => 'Person';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;
  
  # The second file holds the Notes for the details that we loaded above.
  extract_from 'Excel', path => 'C:\Pine\Notes.xlsx';
  transform_as Name => 'A', Text => 'B';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

When B<run> finishes, it wipes out the settings. Simply tack the second ETL
script onto the end of the first.

=cut

sub run {
	# Make sure everything is configured correctly. Rather than crashing, I
	# want to give the developer a more informative error message.
	die 'Please add an "extract_using" command to your script'
		unless defined $extract;
	die 'Please add a "load_into" command to your script'
		unless defined $load;
	die 'Please add a "transform" command to your script'
		unless scalar %mapping;

	die ref( $extract ) . ' does not implement the Data::ETL::Extract role'
		unless $extract->does( 'Data::ETL::Extract' );
	die ref( $load ) . ' does not implement the Data::ETL::Load role'
		unless $load->does( 'Data::ETL::Load' );

	# The actual ETL process...
	$extract->setup;
	$load->setup( $extract );

	while ($extract->next_record) {
		while (my ($field, $value) = each %constants) {
			$value = _code( $value, $load ) if ref( $value ) eq 'CODE';
			$load->set( $field, $value );
		}

		while (my ($to, $from) = each %mapping) {
			if (ref( $from ) eq 'CODE') {
				$load->set( $to, _code( $from, $extract ) );
			} else {
				$load->set( $to, $extract->get( $from ) );
			}
		}

		$load->write_record( $extract->record_number );
	}

	$extract->finished;
	$load->finished;
	
	# Automatically clear out the settings. This leaves the ETL script in a
	# known state. Otherwise, you would have to know the inner workings of the
	# objects to determine the state. This way, you always know that you must
	# start over to re-run the script.
	%constants = ();
	$extract   = undef;
	$load      = undef;
	%mapping   = ();
}


=head3 working_folder

Sets a working folder where the ETL script stores all of its files. The
L<Data::ETL::Extract> classes find their input files under this folder. And
the L<Data::ETL::Load> classes put any files into this folder.

I originally had each input source and data destination search for its own
folder. It was possible that two parts of the same ETL script would use 
different folders. This command prevents that from ever happening.

B<working_folder> supports two ways of identifying the directory. In the first
way, you pass a single parameter - the path name of the working directory. 
Nothing special happens.

In the second way, you pass a hash of search criteria. B<working_folder> 
looks through the file system for the first folder that matches the criteria.
B<working_folder> accepts these criteria...

=over

=item search_in

When searching, only look inside this folder. The code does not search 
subdirectories. Data directories can be quite large. And a fully recursive 
search could take a very long time.

=item find_folder

The search looks for a folder underneath I<search_in> whose name matches this 
regular expression. 

=back

Developers: this command sets the L</WorkingFolder> variable.

=cut

sub working_folder {
	if (scalar( @_ ) < 2) {
		$Data::ETL::WorkingFolder = shift;
	} else {
		my %criteria = @_;
		
		# A blank causes errors in File::Find::Rule.
		$criteria{search_in} = '.' unless hascontent( $criteria{search_in} );
		
		if (defined $criteria{find_folder}) {
			$Data::ETL::WorkingFolder = shift [
				File::Find::Rule
				->directory
				->maxdepth( 1 )
				->name( $criteria{find_folder} )
				->in( $criteria{search_in} )
			];
		} else { $Data::ETL::WorkingFolder = $criteria{search_in}; }
	}

	die "Could not find a working folder" 
		unless defined $Data::ETL::WorkingFolder;
}


=head1 INTERNAL USE

These variables and subroutines may be used by L<Data::ETL::Extract> and
L<Data::ETL::Load> classes. An ETL script should never access these. I 
documented them for other developers creating L<Data::ETL::Extract> and 
L<Data::ETL::Load>.

=head3 WorkingFolder

This scalar variable contains the path set by the L</working_folder> command.
Your L<Data::ETL::Extract> and L<Data::ETL::Load> classes will find their data
files in this directory.

The default value is the current directory.

=cut

my $WorkingFolder = '.';


=head3 _code

This subroutine executes a code reference, passing an object as C<$_>. It is
called by the L</transform_as> code. 

=cut

sub _code {
	my ($code, $object) = @_;
	local $_;
	$_ = $object;
	$code->();
}


=head1 SEE ALSO

L<Data::ETL::Extract>, L<Data::ETL::Load>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# Required for Perl to load the module.
1;
