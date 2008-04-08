package CPAN::Metabase::TestFact;
use base 'CPAN::Metabase::Fact';

use MIME::Base64 ();
use Data::Dumper ();
use Carp ();

sub odor {
    my $self = shift;
    if ( @_ > 1 ) { $self->content->{odor} = shift };
    return $self->content->{odor};
}

sub type { return 'smelly_fact' }

sub as_string {
  my ($self) = @_;

  return MIME::Base64::encode_base64(Data::Dumper::Dumper($self));
}

sub from_string { 
  my ($class, $string) = @_;

  $string = $$string if ref $string;

  my $perl = MIME::Base64::decode_base64($string);

  $class->new(eval $perl);
}

sub validate_content {
    my ($self) = @_;
    my @keys = keys %{$self->content};
    unless ( @keys == 1 && $keys[0] eq 'odor' ) {
        die "'odor' parameter required\n";
    }
    return 1;
}

1;
