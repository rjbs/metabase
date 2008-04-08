use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use YAML::XS;

my $PA = 'CPAN::Metabase::Fact::PrereqAnalysis';

require_ok $PA;

my $sample_content = {
  'Meta::Meta'    => '0.001',
  'Mecha::Meta'   => '1.234',
  'Physics::Meta' => '9.1.12',
  'Physics::Pata' => '0.1_02',
};

my $sample_string = <<'END_YAML';
---
Meta::Meta: '0.001'
Mecha::Meta: '1.234'
Physics::Meta: '9.1.12'
Physics::Pata: '0.1_02'
END_YAML

sub new_pa {
  my ($content) = @_;

  return $PA->new({
    dist_file   => 'Test-Meta-1.00.tar.gz',
    dist_author => 'OPRIME',
    content     => $content,
  });
}

{
  throws_ok { new_pa([]) } qr/invalid/, "can't make prereq fact from arrayref";
}

{
  my $fact = new_pa($sample_content);

  # Some sanity checking.
  isa_ok($fact, $PA, 'constructed fact');
  is_deeply($fact->content, $sample_content, "content matches");
  is($fact->dist_author, 'OPRIME', "dist author matches");

  my $string = $fact->content_as_string;

  is_deeply(
    YAML::XS::Load($string),
    $sample_content,
    "stringified version reconstitutes to original structure",
  );
}
