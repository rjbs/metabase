package CPAN::Metabase::Report;
use Moose;

has guid => (
  is  => 'ro',
  isa => 'Data::GUID',
  handles => { guid_string => 'as_string' },
);

has fact => (is => 'ro', isa => 'CPAN::Metabase::Fact', required => 1);
has user => (is => 'ro', required => 1);

no Moose;
1;
