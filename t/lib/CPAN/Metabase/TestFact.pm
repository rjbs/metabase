package CPAN::Metabase::TestFact;
use Moose;

use MIME::Base64 ();
use Data::Dumper;

has odor => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_string {
  my ($self) = @_;

  return MIME::Base64::encode_base64($self->dump);
}

sub from_string { 
  my ($class, $string) = @_;

  $string = $$string if ref $string;

  my $perl = MIME::Base64::decode_base64($string);

  $class->new(eval $perl);
}

1;
