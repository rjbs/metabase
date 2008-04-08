# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase::Fact;
use strict;
use warnings;
use Params::Validate ();
use Data::GUID ();
use CPAN::DistnameInfo ();
use Carp ();

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

my (@new_requires, @submit_requires, @generated_vars, @class_methods);
BEGIN { 
    @new_requires       = qw/dist_author dist_file content/;
    @submit_requires    = qw/user_id/;
    @generated_vars     = qw/guid dist_name dist_version/;
    @class_methods      = qw/type schema_version/;
}

use Object::Tiny @new_requires, @submit_requires, @generated_vars;

sub new {
    my ($class, @args) = @_;

    my %args = Params::Validate::validate( @args, { 
        ( map { $_ => 1 } @new_requires ), 
        ( map { $_ => 0 } @submit_requires, @generated_vars ),
    });
    
    # create and check
    my $self = bless \%args, $class;

    eval { $self->validate_content( $self->content ) };
    if ($@) {
        Carp::confess( "$class object content invalid: $@" );
    }

    # add metadata
    my $dist_info = CPAN::DistnameInfo->new(
        uc($self->dist_author) . "/" . $self->dist_file
    );
    $self->{dist_name} = $dist_info->dist;
    $self->{dist_version} = $dist_info->version;

    return $self;
}

# check if it has both a user_id and a guid
sub is_submitted {
    my ($self) = @_;
    return defined $self->guid && defined $self->user_id;
}

# record submission, but only once
sub mark_submitted {
    my ($self, @args) = @_;
    
    # need certain vars to be set
    my %args = Params::Validate::validate( @args, { 
        map { $_ => 1 } @submit_requires, 
    });

    # only mark once
    if ( $self->is_submitted ) {
        Carp::confess( "submission data can't be changed once set" );
    }

    # set submission vars
    for my $k ( @submit_requires ) {
        $self->{$k} = $args{$k};
    }

    # set GUID -- this is the only time this should happen
    $self->{guid} = Data::GUID->new;
}


sub type {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    return $self->class_to_type( $class );
}

#--------------------------------------------------------------------------#
# class methods
#--------------------------------------------------------------------------#

sub schema_version { 1 }

sub class_to_type {
    my ($self, $class) = @_;
    $class =~ s{::}{-}g;
    return $class;
}

sub type_to_class {
    my ($self, $type) = @_;
    $type =~ s{-}{::}g;
    return $type;
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

