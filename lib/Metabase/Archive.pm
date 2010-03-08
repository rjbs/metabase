# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package Metabase::Archive;
use Moose::Role;

our $VERSION = '0.003';
$VERSION = eval $VERSION;

requires 'store';    # store( $fact_struct ) -- die or return $guid
requires 'extract';  # extract( $guid ) -- die or return $fact_struct

1;

__END__

=pod

=head1 NAME

Metabase::Archive - Interface for Metabase storage

=head1 SYNOPSIS

  package Metabase::Archive::Foo;
  use Metabase::Fact;
  use Moose;
  with 'Metabase::Archive';
  
  # define Moose attributes
  
  sub store {
    my ( $self, $fact_struct ) = @_;
    # store a fact
  }

  sub extract {
    my ( $self, $guid ) = @_;
    # retrieve a fact
    return $fact;
  }

=head1 DESCRIPTION

This describes the interface for storing and retrieving facts.  Implementations
must provide the C<store> and C<extract> methods.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

=over 

=item *

David A. Golden (DAGOLDEN)

=item *

Ricardo J. B. Signes (RJBS)

=back

=head1 COPYRIGHT AND LICENSE

 Portions Copyright (c) 2008-2009 by David A. Golden
 Portions Copyright (c) 2008-2009 by Ricardo J. B. Signes

Licensed under terms of Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a 
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
