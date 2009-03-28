#!/home/acme/bin/perl
use strict;
use warnings;
use WebService::Solr;
use Perl6::Say;

my $query = shift || die "Usage: solr_search.pl roman_s:MCIX";

my $solr     = WebService::Solr->new();
my $response = $solr->search($query);
for my $doc ( $response->docs ) {
    say $doc->value_for('guid');
}
