=pod

=head1 NAME

Data::ETL - Extract-Transform-Load pattern for converting data

=SYNOPSIS

  use Data::ETL;

  extract_using 'Excel', in_folder => qr|/PineHill/|, like => qr/\.xlsx?$/;
  transform A => 'Name', B => 'Address', C => 'Birthday';
  load_into 'Access', path => 'C:\ETL\review.accdb';
  run;

=cut

package Data::ETL;


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
Notice that L</extract_using> and L<load_into> take a format name as their
first parameter? In our example, L</extract_using> loads the helper class
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
L</extract_using>, L</transform>, L</load_into>, and L</run>. Techinically, an
ETL script is just a Perl script. You may use any Perl commands or modules.

=head1 COMMANDS

=head3 extract_using

This command configures the input source. You may only have one input source
in an ETL script.

The first parameter is the name of the input format. C<extract_using>
automatically adds the B<Data::ETL::Extract> to the start of the class name.

After the format class, you may pass in a hash of attributes for the format
class. C<extract_using> passes the rest of the parameters directly to the
input source class.

=cut

my $extract;

sub extract_using {
	my $class      = shift @_;
	my %attributes = @_;

	$class = "Data::ETL::Extract::$class"
		unless $class =~ m/^Data::ETL::Extract/;
	$extract = eval "$class->new(\%attributes)";
}


=head3 transform

This command configures the mapping from input field names to output field
names. It accepts a hash as its only parameter. The keys are input field
names. The values are output field names. L</run> copies data from
L<Data::ETL::Extract/record> into L<Data::ETL::Load/record> using the mapping
from that hash.

=cut

my %mapping;

sub transform { $mapping{keys @_} = values @_; }


=head3 load_into

This command configures the data destination. The first parameter names the
L<Data::ETL::Load> class. C<load_into> automatically adds the
B<Data::ETL::Load> to the beginning of the class name.

After the format class, you may pass in a hash of attributes for the data
destination class. C<extract_using> passes the rest of the parameters directly
to the input source class.

=cut

my $load;

sub load_into {
	my $class      = shift @_;
	my %attributes = @_;

	$class = "Data::ETL::Load::$class" unless $class =~ m/^Data::ETL::Load/;
	$load = eval "$class->new(\%attributes)";
}


=head3 run

This command kicks off the entire data conversion process. It takes no
parameters. All of the setup is done by the other commands. This should be
the last command in your ETL script.

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
		unless $extract->does( 'Data::ETL::Load' );

	# The actual ETL process...
	$extract->setup;
	$load->setup;

	while ($extract->next_record) {
		my $in  = $extract->record;
		my $out = $load->record;

		$out = {};
		$out->{$mapping{$_}} = $in->{$_} foreach (keys %mapping);

		$load->write;
	}

	$extract->finished;
	$load->finished;
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
