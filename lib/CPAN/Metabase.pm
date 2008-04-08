# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

=head1 NAME

CPAN::Metabase - a database for metadata about CPAN distributions

=head1 DESCRIPTION

The CPAN metabase is a framework for storing metadata about CPAN distributions.
It can be used to store, retrieve, and search this information, which can be of
arbitrary and mixed types.

The metabase was built as a means of storing reports from the CPAN Testers.
When CPAN::Metabase was initially developed, CPAN Testers reports were sent by
individual testers to a single email server, which then forwarded them to a
USENET group, which was considered the authoritative store.  This presented
problems: some testers couldn't send email, the system wasn't very searchable
or mirrorable, and the data inside the system was entirely unstructured.

CPAN::Metabase aims to avoid all of those problems by being transport-neutral,
searchable and mirrorable by design, and geared toward storing structured data.
Simplicity is another design goal: while it has several moving parts, they're
all simple and designed to be replaceable and extensible, rather than to be a
perfect design up front.

=head1 OVERVIEW

The metabase server has a few parts:

=over

=item * the Gateway, which authorizes the addition of facts to the Archiver

=item * the Archive, which stores and retrieves facts

=item * the Index, which builds searchable indexes of facts

=item * the Librarian, which coordinates access to the Archive and Index

=back

=head1 COPYRIGHT

Copyright (c) 2008 by Ricardo Signes.

Licensed under the same terms as Perl itself (the "License").  You may not use
this file except in compliance with the License.  A copy of the License was
distributed with this file or you may obtain a copy of the License from
http://dev.perl.org/licenses/

=cut

1;
