use strict;
use warnings;
package CPAN::Metabase::Client;

use Carp ();
use LWP::UserAgent;

sub default_url {
}

# Whatever, I don't remember how to do this not awfully without Moose anymore.
# -- rjbs, 2008-04-06
sub url {
  my $self = shift;
  return $self->{url} unless @_;
  $self->{url} = shift;
}

sub auth_key {
  my $self = shift;
  return $self->{auth_key} unless @_;
  $self->{auth_key} = shift;
}

sub new {
  my ($class, $arg) = @_;

  my $self = bless { } => $class;

  $self->url($arg->{url} || $self->default_url);
  $self->auth_key($arg->{url});

  $self->$_ or Carp::croak "missing required param $_" for qw(url auth_key);

  return $self;
}

sub _validate_dist { 1 }

sub submit_fact {
  my ($self, $fact, $dist) = @_;

  $self->_validate_dist($dist);

  my $ua = LWP::UserAgent->new;
  $ua->post(
    $self->url,
    {
      auth_key    => $self->auth_key,
      dist_author => $dist->{author},
      dist_name   => $dist->{name},
      type        => ref $fact,
      content     => $fact->as_string,
    },
  );
}

1;
