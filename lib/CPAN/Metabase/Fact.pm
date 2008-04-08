# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase::Fact;
use strict;
use warnings;
use Params::Validate ();
use Carp ();

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

my @valid_args;
BEGIN { @valid_args = qw/dist_author dist_file content/ }

use Object::Tiny @valid_args;

# new takes a reference
# may have a type, but we'll set it anyway 
sub new {
    my ($class, @args) = @_;
    my %args = Params::Validate::validate( @args, 
        { type => 0, guid => 0, map { $_ => 1 } @valid_args } 
    );
    my $self = bless { %args, type => $class->type }, $class;
    eval { $self->validate_content( $self->content ) };
    if ($@) {
        Carp::confess( "$class object content invalid: $@" );
    }
    return $self;
}

# guid() has to be read/write as facts start without a GUID and have one
# assigned depending on where/how they are stored
sub guid {
    my $self = shift;
    if (@_) { $self->{guid} = shift }; 
    return $self->{guid};
}

# default schema
sub schema_version { 1 }

sub type {
    my $self = shift;
    my $class = ref $self ? ref($self) : $self;
    $class =~ s{::}{-}g;
    return $class;
}

#--------------------------------------------------------------------------#
# fatal stubs
#--------------------------------------------------------------------------#

sub content_as_string { 
    my $self = shift;
    Carp::confess "content_as_string() not implemented by " . ref $self;
}

sub content_from_string { 
    my $self = shift;
    Carp::confess "content_from_string() not implemented by " . ref $self;
}

sub validate_content {
    my ($self, $content) = @_;
    Carp::confess "validate_content() not implemented by " . ref $self;
}

1;

__END__

=pod

=head1 NAME

CPAN::Metabase::Fact - Abstract base class for CPAN::Metabase facts

=head1 SYNOPSIS

 package CPAN::Metabase::Fact::Custom;
 use base 'CPAN::Metabase::Fact';

 sub type { return 'web-query-type-string' }

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

