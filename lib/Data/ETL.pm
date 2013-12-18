=pod

=head1 NAME

Data::ETL - Extract-Transform-Load pattern for converting data

=head1 SYNOPSIS

  use Data::ETL;

  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'Excel', find_file => qr/\.xlsx?$/;
  transform_as Name => 'A', Complaint => 'B', ID => 'C';
  set Client => 1, Type => 'Complaint';
  load_into 'Access', file => 'review.accdb';
  run;

=cut

package Data::ETL;

use 5.14.0;
use Data::ETL::CodeRef;
use Exporter qw/import/;
use File::Find::Rule;
use String::Util qw/hascontent/;


our @EXPORT  = qw/extract_from transform_as set load_into run working_folder/;
our $VERSION = '1.00';


=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works on almost any type
of data conversion. You read the source (I<Extract>), translate the data for
your target (I<Transform>), and store the result (I<Load>).

By dividing a conversion into 3 steps, we isolate the input from the output.
The isolation lets us:

=over

=item * Centralize data formatting and validation.

=item * Add new input formats with ease.

=item * Swap files and databases without changing application code.

=back

I use the I<Extract-Transform-Load> pattern to upload third party data into our
SQL database. For example, imagine a hospital named Ficticious Medical Center.
Ficticious signs up for our services and sends me a copy of their patient
complaints in an MS Excel spreadsheet. I write a B<Data::ETL> script like this:

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'Excel', find_file => qr/\.xlsx?$/;
  transform_as Name => 'A', Complaint => 'B', ID => 'C';
  set Client => 1, Type => 'Complaint';
  load_into 'Access', file => 'review.accdb';
  run;

Run the script, pop open the MS Access database, and give it all a once over.
The MS Access database has a query that uploads the data into our full blown
SQL database.

Next month, Ficticious sends me all of their new complaints. I run the same
script, do the same verification, and upload the data in just a few minutes.
All thanks to B<Data::ETL>.

=head2 How does B<Data::ETL> work?

B<Data::ETL> provides commands for what I call a B<Data::ETL script>. The
script configures and executes a data conversion. A typical B<Data::ETL> script
looks like this:

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'Excel', find_file => qr/\.xlsx?$/;
  transform_as Name => 'A', Complaint => 'B', ID => 'C';
  set Client => 1, Type => 'Complaint';
  load_into 'Access', file => 'review.accdb';
  run;

Let's break it down one line at a time. Line 1, C<use Data::ETL;> loads this
module. It makes available all of the other commands. Easy enough.

=head3 Tell it where the files are

B<Data::ETL> assumes that you don't always use exactly the same file or
directory names. For example, I append the date onto directory names to avoid
collisions. Ficticious also changes the name of their spreadsheet depending on
the mood of the person who creates it. Rather than make the user pick a file,
B<Data::ETL> searches the file system for the right one. The
C<working_folder search_in...> command on line 2 tells B<Data::ETL> where it
can search for those files.

You control the search using the I<search_in> and I<find_folder> options.

I<search_in> establishes the root directory. I keep my data in a common root
directory. I<search_in> anchors the search here.

I<find_folder> finds the first directory directly underneath I<search_in> that
matches the regular expression.

=head3 Tell it the file format

B<Data::ETL> supports any file format that Perl can read. The
C<extract_from 'Excel'> commands tells B<Data::ETL> that Ficticious sends an
MS Excel spreadsheet. I<extract_from> searches the working folder for the first
file that matches the regular expression.

Sounds too good to be true? It is. There's a technicality: B<Data::ETL>
supports any file format I<for which someone already wrote a bridge>. The
bridge takes an existing Perl module and gives it an API that B<Data::ETL>
understands. The bridge is actually L<a Moose role|http://search.cpan.org/~ether/Moose-2.0901-TRIAL/lib/Moose/Manual/Roles.pod>
: L<Data::ETL::Extract>.

B<Data::ETL> comes with bridges for L<MS Excel|Data::ETL::Extract::Excel>,
L<CSV/tab delimited/pipe delimited|Data::ETL::Extract::DelimitedText>, and a
L<directory listing|Data::ETL::Extract::FileListing>. You identify the bridge
in the I<extract_from> command using the last part of the class name. In our
example, I used C<extract_from 'Excel'>. I<extract_from> assumed that I meant
L<Data::ETL::Extract::Excel>. It added the B<Data::ETL::Extract> automatically.

Each bridge supports its own set of options. You pass these into
C<extract_from> after the bridge name.

=head3 Tell it where to send the data

I'm going to skip ahead to the line that starts C<load_into 'Access'...>. The
I<load_into> command also uses a bridge. In our case, the bridge is really
I<Data::ETL::Load::Access>. I<load_into> automatically adds the
B<Data::ETL::Load>.

Similar to I<extract_from>, a I<load_into> bridge implements the
L<the Moose role|http://search.cpan.org/~ether/Moose-2.0901-TRIAL/lib/Moose/Manual/Roles.pod>
named L<Data::ETL::Load>. Each bridge supports its own set of options.

=head3 Map the input to the output

C<< transform_as Name => 'A' >> takes the data from column A and puts it into
the database column called I<Name>. You can pass as many mappings to the
I<transform_as> command that you want.

=head3 What about constants?

C<< set Client => 1 >> hard codes the database column I<Client> to the constant
value B<1>. I<transform_as> maps data that changes for every record. I<set>
maps data that stays the same for every record.

=head3 So where is the actual data conversion?

The C<run;> command starts everything in motion. Up until I<run>, nothing
actually happens. You configure the process using I<extract_from>,
I<transform_as>, and I<load_into>. I<run> fires it off.

I<run> starts a giant loop that does the actual I<Extract-Transform-Load>.
I<run> is usually the last command in your script.

=head2 Bridge Classes

As you can see, B<Data::ETL> acts as a front end to various data related
classes called I<bridges>. The bridges do the actual work. B<Data::ETL> lets
you write a little script, harnessing the work of existing Perl modules.

The bridge classes all belong under the I<Data::ETL::Extract::*> or
I<Data::ETL::Load::*> namespaces. And they implement the L<Data::ETL::Extract>
or L<Data::ETL::Load> roles respectively. I<extract_from> and I<load_into>
automatically add the namespace, making it easy to scan a script and determine
the file formats.

=head3 Input formats

B<Data::ETL> provides a few generic I<Data::ETL::Extract::*> classes. These
classes work for file based input - regardless of content. If you receive
your data through files, then these classes will work for you.

To add a new input format, see the documentation for L<Data::ETL::Extract>.

=head3 Output formats

Your organization writes its own I<Data::ETL::Load::*> classes. This bridge
performs any specialized tasks such as validation or conversion. The
I<Data::ETL::Load::*> classes are tied closely with your internal data format.

To add a new output format, see the documentation for L<Data::ETL::Load>.

=head2 How do I write a B<Data::ETL> script?

=over

=item 1. Put C<use Data::ETL;> at the top.

=item 2. Add the C<working_folder> command.

=item 3. Set the I<search_in> option to your root directory.

=item 4. Set I<find_folder> to a regular expression for matching the directory name.

=item 5. Add the C<extract_from> command and the input file format.

=item 6. Set I<find_file> to a egular expression for matching the data file.

=item 7. Add the C<transform_as> command.

=item 8. Set each destination field to the corresponding input field.

=item 9. Add the C<load_into> command with the output format.

=item 10. Add the C<run> command.

=item 11. Run your new script!

=back

Your script looks much like the example in the L</SYNOPSIS>. You execute the
B<Data::ETL> script like any other Perl program. That's it. The B<Data::ETL>
script reads data in and sends it back out.

A B<Data::ETL> script must have at least one of each of the four commands:
L</extract_from>, L</transform>, L</load_into>, and L</run>.

=head3 Plain old Perl

A B<Data::ETL> script is a plain old Perl script. You can use any modules or
Perl commands that you want. This makes B<Data::ETL> extremely flexible.

=head1 COMMANDS

=head3 extract_from

The B<extract_from> command configures the input source.

The first parameter is the file format. This is the name of a
L<bridge class|/Bridge Classes>. B<extract_from> automatically loads the
bridge. See L</Bridge Classes> above for more information.

The remaining parameters set options for the input source. B<Data::ETL> makes
the following options available for all input sources...

=over

=item bypass_if

Skip over invalid or unwanted records.

=item stop_if

Stop processing when this becomes true. It lets you avoid footer or trailers.

=item filter

Extra processing of the raw data, such as trimming whitespace.

=item debug

Executed once for each record. Used to debug errors with the data.

=back

See L<Data::ETL::Extract> for a complete explanation of these options.

Note that you do not have to put the I<Data::ETL::Extract::> in front of the
bridge class name. B<extract_from> automatically adds that bit for you. This
makes your B<Data::ETL> script easier to read.

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

B<transform_as> configures the data mapping. It mapss data from an input field
to the corresponding output field.

B<transform_as> takes a hash as its only parameter. The hash keys are I<output>
field names. The hash values are the I<input> field names. The
L<bridge classes|/Bridge Classes> define the field names. See their
documentation for details.

And like all good rules, there is one exception. B<transform_as> does allow a
code reference as a hash value. B<transform_as> executes this code instead of
retrieving data from the input source. The code returns a value that goes
directly into the output field. This how you combine multiple fields into one,
change the data, or perform complex calculations.

B<transform_as> passes the L<Data::ETL::Extract> object into the code
reference. B<transform_as> sets C<$_> to the L<Data::ETL::Extract> object. It
also passes the L<Data::ETL::Extract> object as the only parameter to the code
reference.

  transform_as Name => sub { $_->get( 'A' ) // $_->get( 'B' ) };
  transform_as Percent => sub { shift->get( 'C' ) * 100 };

=cut

my %mapping;

sub transform_as {
	my %add = @_;
	@mapping{keys %add} = values %add;
}


=head3 load_into

B<load_into> configures the output destination.

The first parameter is the output format. This is the name of a
L<bridge class|/Bridge Classes>. B<load_into> automatically loads the bridge.
See L</Bridge Classes> above for more information.

The remaining parameters set options for the destination. These options are
unique to the selected bridge class.

Note that you do not have to put the I<Data::ETL::Load::> in front of the
bridge class name. B<load_into> automatically adds that bit for you. This makes
the B<Data::ETL> easier to read.

=cut

my $load;

sub load_into {
	my $class      = shift @_;
	my %attributes = @_;

	$class = "Data::ETL::Load::$class" unless $class =~ m/^Data::ETL::Load/;
	$load = eval "use $class; $class->new( \%attributes )";
}


=head3 set

B<set> hard codes specific output fields. It accepts a hash as its only
parameter. The keys are output field names. The values are, well, the
corresponding values that you want in that field.

B<set> handles values that do not change from one record to the next.

If the same field shows up in both L</transform_as> and B<set>, the
L</transform_as> value is used. Data from the input source overrides constants.

You can also pass a code reference as the value. In this case, B<set> executes
the code and stores the return value as the output field. B<set> passes the
current L<Data::ETL::Load> object as C<$_> and as a parameter. You may find it
useful for grabbing information out of your database.

Note that B<set> executes the code reference I<for each record>.

=cut

my %constants;

sub set {
	my %add = @_;
	@constants{keys %add} = values %add;
}


=head3 run

B<run> kicks off the entire data conversion process. It takes no parameters.
All of the setup is done by the other commands. This should be the last command
in your B<Data::ETL> script. And 90% of the time, it will be.

=cut

sub run {
	# Make sure everything is configured correctly. Rather than crashing, I
	# want to give the developer a more informative error message.
	die 'Could not find the data folder in "working_folder"'
		unless defined $Data::ETL::WorkingFolder;

	die 'Please add an "extract_from" command to your script'
		unless defined $extract;
	die 'Please add a "load_into" command to your script'
		unless defined $load;
	die 'Please add a "transform_as" command to your script'
		unless scalar %mapping;

	die ref( $extract ) . ' does not implement the Data::ETL::Extract role'
		unless $extract->does( 'Data::ETL::Extract' );
	die ref( $load ) . ' does not implement the Data::ETL::Load role'
		unless $load->does( 'Data::ETL::Load' );

	# The actual ETL process...
	$extract->setup;
	$load->setup( $extract );

	say $Data::ETL::WorkingFolder;
	while ($extract->next_record) {
		next if Data::ETL::CodeRef::run( $extract->bypass_if, $extract );

		# "set" values...
		while (my ($field, $value) = each %constants) {
			$value = Data::ETL::CodeRef::run( $value, $load )
				if ref( $value ) eq 'CODE';
			$load->set( $field, $value );
		}

		# "transform_as" values...
		while (my ($to, $from) = each %mapping) {
			if (ref( $from ) eq 'CODE') {
				$load->set( $to, Data::ETL::CodeRef::run( $from, $extract ) );
			} else {
				$load->set( $to, $extract->get( $from ) );
			}
		}

		$load->write_record( $extract->record_number );
	} continue {
		say( 'Finsihed record #', $extract->record_number )
			unless $extract->record_number % 20;
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

The B<working_folder> command sets the root directory for finding data files.
The L<Data::ETL::Extract> L<bridge class|/Bridge Classes> only loads files
from this directory. And the L<Data::ETL::Extract>
L<bridge class|/Bridge Classes> writes its files into this directory. This
keeps all of your files organized.

B<working_folder> has two forms: C<working_folder 'C:\Data';> or
C<working_folder search_in => 'C:\Data', find_folder => 'Ficticious';>.

The first form hard codes the directory path. You tell B<Data::ETL> that its
files reside in this directory, period. In our example, B<Data::ETL> finds its
files in F<C:\Data>.

The second form searches the file system for a matching directory. For example,
I receive monthly updates from multiple clients. Each update gets its own
directory with the date appended to the client name:
F<C:\Data\Ficticious_2013-01-01>, F<C:\Data\Anonymous_2013-01-03>, and
F<C:\Data\Unknown_2013-01-03>. The files share a common root, with a variable
directory name underneath that root.

B<working_folder> supports variable directory names using the search options:

=over

=item search_in

When searching, only look inside this folder. The code does not search
subdirectories. Data directories can be quite large. And a fully recursive
search could take a very long time.

=item find_folder

The search looks for a folder underneath I<search_in> whose name matches this
regular expression.

=back

=cut

sub working_folder {
	if (scalar( @_ ) < 2) {
		$Data::ETL::WorkingFolder = shift;
	} else {
		my %criteria = @_;

		# A blank causes errors in File::Find::Rule.
		$criteria{search_in} = '.' unless hascontent( $criteria{search_in} );

		if (defined $criteria{find_folder}) {
			$Data::ETL::WorkingFolder = shift [ sort File::Find::Rule
				->directory
				->maxdepth( 1 )
				->name( $criteria{find_folder} )
				->in( $criteria{search_in} )
			];
		} else { $Data::ETL::WorkingFolder = $criteria{search_in}; }
	}
}


=head1 INTERNAL USE

These variables and subroutines may be used by the L<Data::ETL::Extract> or
L<Data::ETL::Load> bridge classes. A Data::ETL script never accesses these. I
documented them for other developers creating L<Data::ETL::Extract> and
L<Data::ETL::Load> bridges.

=head3 WorkingFolder

This scalar variable contains the path set by the L</working_folder> command.
Your L<Data::ETL::Extract> or L<Data::ETL::Load> classes will find their data
files in this directory.

The default value is the current directory.

=cut

my $WorkingFolder = '.';


=head1 ADVANCED USES

=head3 Adding your output file format

See L<Data::ETL::Load/Writing Your Own Output Class> for details.

=head3 Adding a new input file format

See L<Data::ETL::Extract> for details.

=head3 Multiple input files

What happens if the input data spans multiple files? B<Data::ETL> supports
processing multiple files inside one script. For example...

  use Data::ETL;

  # The first file has demographic details.
  extract_from 'Excel', path => 'C:\Ficticious\Details.xlsx';
  transform_as Name => 'A', Address => 'B', Birthday => 'C';
  set Client => 1, Type => 'Person';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

  # The second file holds the Notes for the details that we loaded above.
  extract_from 'Excel', path => 'C:\Ficticious\Notes.xlsx';
  transform_as Name => 'A', Text => 'B';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

See the two B<run> commands? When the first B<run> finishes, it wipes out the
settings. Simply tack the second B<Data::ETL> script onto the end of the first.

You can repeat this for three files...

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;

  # The first file has demographic details.
  extract_from 'Excel', find_file => qr/Demographics.*\.xlsx$/i;
  transform_as Name => 'A', Address => 'B', Birthday => 'C';
  set Client => 1, Type => 'Person';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

  # The second file holds the Notes for the details that we loaded above.
  extract_from 'Excel', find_file => qr/Notes.*\.xlsx/i;
  transform_as Name => 'A', Text => 'B';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

  # The third file holds a date field.
  extract_from 'Excel', find_file => qr/Dates.*\.xlsx/i;
  transform_as Name => 'A', Date => 'B';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

Notice the single L</working_folder> command at the top? All three files
reside in the same working folder. B<Data::ETL> assumes that you group related
files inside the same folder.

=head1 SEE ALSO

L<Data::ETL::Extract>, L<Data::ETL::Load>

=head2 Input File Formats

L<Data::ETL::Extract::Excel>, L<Data::ETL::Extract::DelimitedText>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# Required for Perl to load the module.
1;
