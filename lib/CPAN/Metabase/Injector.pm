package CPAN::Metabase::Injector;
use Moose;

use DateTime;
use Path::Class;
use YAML::Syck ();

sub _root_dir {
  return $ENV{CPAN_METABASE_ROOT} || die "no metabase root dir";
}

sub _typename_for_path {
  my ($self, $typename) = @_;
  $typename =~ s/::/-/g;
  return $typename;
}

sub inject_report {
  my ($self, $report) = @_;

  my $dest_path = dir(
    $self->_root_dir,
    'meta',
    $self->_typename_for_path($report->type),
    $report->dist_author,
    $report->dist_file
  );

  $dest_path->mkpath;

  my $report_file = file($dest_path, $report->guid);

  my $injection_time = DateTime->now(time_zone => 'UTC');

  $self->_write_file($report, $report_file);
  $self->_record_injection($report, $report_file);
}

sub _write_file {
  my ($self, $report, $report_file) = @_;

  my $fh = $report_file->openw;
  print $fh $report->fact->as_string
    or die "couldn't write to $report_file: $!";
  close $fh or die "couldn't close $report_file: $!";

  $self->_write_meta($report, $report_file);
}

sub _write_meta {
  my ($self, $report, $report_file) = @_;

  my ($dir, $file) = map { $report_file->$_ } qw(dir basename);

  my $meta_file = file($dir, "$file.meta");
  my $metadata = $report->metadata;

  # XXX: Totally insufficient. -- rjbs, 2008-04-06
  die "invalid metadata" unless ref $metadata eq 'HASH';

  my $fh = $meta_file->openw;
  print $fh YAML::Syck::Dump($metadata)
    or die "couldn't write to $meta_file: $!";
  close $fh or die "couldn't close $meta_file: $!";
}

sub _record_injection {
  my ($self, $report, $report_file) = @_;

  my $injection_time = DateTime->now(time_zone => 'UTC');

  my $activity_log = $self->_activity_log($injection_time);
  my $fh = $activity_log->open('>>') or die "Can't append to $activity_log: $!";

  printf $fh "%s %s %s %s/%s\n",
    $report->guid,
    $injection_time,
    $report->type,
    $report->dist_author, $report->dist_file;
}

sub _activity_log {
  my ($self, $dt) = @_;

  my $dir = dir($self->_root_dir, 'metalog', (split m{-}, $dt->ymd));
  $dir->mkpath;
  
  $dir->file('inject.log');
}

1;
