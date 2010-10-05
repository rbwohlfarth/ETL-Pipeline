# This file contains no code. It is a POD format user manual for the 
# ETL modules.

=pod

=head1 NAME

ETL::Manual - Translating Data

=head1 What is ETL?

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

By dividing a conversion into 3 steps, we isolate the input from the output.
The isolation lets us:

=over

=item * Standardize formatting and validation of the stored data.

=item * Add new input formats with ease.

=item * Swap files and databases without changing application code.

=back

=head1 An Example

You pull together the three parts in a data conversion object:

 package MyConversion;
 use Moose;
 with 'MooseX::Log::Log4perl';
 
 # Inherit from the ETL pattern modules.
 extends 'ETL::Extract::FromFile::Excel::2007';
 with 'ETL::Transform';
 extends 'ETL::Load::DBI';
 
 # Define the application specific tranformation.
 sub build_mapping { {Name => 'A', Age => 'B', Hair => 'C'} }
 
 ######################################################################
 package main;
 
 my $cnv = new MyConversion;

 # Link the conversion with the input file.
 $cnv->input( 'InputFile.xlsx' );

 # Link the conversion with the database.
 $cnv->output( 'PersonTable' );
 
 # Read every record from the input file...
 while (my $record = $cnv->extract()) {
	 # Format and validate the input data.
	 my $data = $cnv->transform( $record );
	 
	 # Save the results into the database.
	 $cnv->load( $data ) if defined $data;
 }

Now lets break down this example a little further.

=head2 
