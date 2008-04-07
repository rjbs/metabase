# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase::Fact;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

# should accept/provide scalars or refs to scalars

BEGIN {
    no strict 'refs';
    for my $m (qw/guid type/) {
        *{$m} = sub { if (@_ > 1) { $_[0]->{$m} = $_[1] }; return $_[0]->{$m} };
    }
}

sub new { 
    my $class = shift;
    die "new() not implemented by $class";
}

sub as_string { 
    my $self = shift;
    die "as_string() not implemented by " . ref $self;
}

sub from_string { 
    my $self = shift;
    die "from_string() not implemented by " . ref $self;
}

1;

__END__

=pod

=head1 NAME

CPAN::Metabase::Fact - Abstract base class for CPAN::Metabase facts

=head1 SYNOPSIS

 package CPAN::Metabase::Fact::Custom;
 use base 'CPAN::Metabase::Fact';

 sub as_string { 
     # implementation goes here
 }

 sub from-string {
     # implementation goes here
 }
 
 1;

=head1 DESCRIPTION

Description...

=head1 USAGE

Usage...

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Metabase>

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

 Portions copyright (c) 2008 by David A. Golden
 Portions copyright (c) 2008 by Ricardo J. B. Signes

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

