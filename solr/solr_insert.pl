#!/home/acme/bin/perl
use strict;
use warnings;
use Text::Roman;
use WebService::Solr;
use Term::ProgressBar::Simple;

my $count = 10_000;

my $progress = Term::ProgressBar::Simple->new($count);

my $solr = WebService::Solr->new( undef, { autocommit => 0 } );

my @docs;
foreach my $i ( 1 .. $count ) {
    my $doc = WebService::Solr::Document->new;
    $doc->add_fields(
        guid    => $i,
        type    => 'roman',
        roman_s => roman($i),
    );
    push @docs, $doc;
    $progress++;

    # add in bunches of a thousand
    if ( @docs == 1_000 ) {
        $solr->add( \@docs );
        @docs = ();
    }
}
$solr->commit;
$solr->optimize;
