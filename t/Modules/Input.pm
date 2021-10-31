# This module does nothing. I use it for testing roles.
package Input;
use Moose;


sub run { }
with 'ETL::Pipeline::Input';


no Moose;
__PACKAGE__->meta->make_immutable;
