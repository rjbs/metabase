package CPAN::Metabase::Fact::TestFact;
use base 'CPAN::Metabase::Fact';

use MIME::Base64 ();
use Data::Dumper ();
use Carp ();

sub validate_content {
  my ($self) = @_;
  Carp::croak "plain scalars only please" if ref $self->content;
  Carp::croak "non-empty scalars please"  if ! length $self->content;
}

sub content_as_string {
  my ($self) = @_;

  return MIME::Base64::encode_base64( scalar reverse $self->content );
}

sub content_from_string { 
  my ($class, $string) = @_;

  $string = $$string if ref $string;

  return scalar reverse MIME::Base64::decode_base64( $string );
}

1;
