use 5.006;
use strict;
use warnings;

package Metabase;
# ABSTRACT: A database framework and API for resource metadata
# VERSION


1;

__END__

=head1 DESCRIPTION

Metabase is a database framework and API for resource metadata.  The framework
describes how arbitrary data ("facts") are associated with particular resources
or related to each other.  The API describes how to store, retrieve, and search
this information.

=head2 History and Motivation

Metabase was originally designed as a means of storing reports from the CPAN
Testers project.  When Metabase was initially developed, CPAN Testers reports
were sent by individual testers to a single email server, which then forwarded
them to a USENET group, which was considered the authoritative store.  This
presented problems: some testers couldn't send email, the system wasn't very
searchable or mirrorable, and the data inside the system was entirely
unstructured.

Metabase aimed to avoid all of those problems by being transport-neutral,
searchable and mirrorable by design, and geared toward storing structured data.
Simplicity is another design goal: while it has several moving parts, they're
all simple and designed to be replaceable and extensible, rather than to be a
perfect design up front.

=head1 OVERVIEW

A Metabase has several parts:

=over

=item * 

L<Metabase::Gateway>, which manages submission of facts to the Librarian

=item *

L<Metabase::Librarian>, which manages access to the Archive and Index

=item *

L<Metabase::Archive>, which stores and retrieves facts

=item *

L<Metabase::Index>, which indexes and searches facts

=back

Archive and Index are abstract base classes.  Implementations could use flat
files, relational databases, object databases, cloud services, or anything else
that can satisfy the API.

Metabase comes with some standard backends:

=over

=item *

L<Metabase::Archive::Filesystem>

=item *

L<Metabase::Archive::SQLite>

=item *

L<Metabase::Index::FlatFile>

=item *

L<Metabase::Index::Solr>

=back

Facts stored with in a Metabase are defined as subclasses of L<Metabase::Fact>.
L<Metabase::Report> is a subclass that relates multiple facts.

L<Metabase::Web> provides the web API for storing, searching and retrieving
facts.  L<Metabase::Client::Simple> is the client library to submit facts to a
Metabase::Web server.  A future Metabase::Client class will provide submit and
search capabilities.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=cut
