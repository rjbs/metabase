requires "CHI" => "0";
requires "CPAN::DistnameInfo" => "0";
requires "Carp" => "0";
requires "Class::MOP" => "0";
requires "Data::GUID" => "0";
requires "Data::Stream::Bulk::Array" => "0";
requires "Data::Stream::Bulk::Callback" => "0";
requires "Data::Stream::Bulk::Filter" => "0";
requires "Data::Stream::Bulk::Nil" => "0";
requires "Fcntl" => "0";
requires "File::Slurp" => "0";
requires "IO::File" => "0";
requires "JSON" => "2";
requires "List::AllUtils" => "0";
requires "Metabase::Fact" => "0.018";
requires "Metabase::Fact::String" => "0";
requires "Metabase::User::Profile" => "0";
requires "Metabase::User::Secret" => "0";
requires "Moose" => "1.00";
requires "Moose::Role" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::Types::Moose" => "0";
requires "MooseX::Types::Path::Class" => "0";
requires "MooseX::Types::Structured" => "0";
requires "Regexp::SQL::LIKE" => "0.001";
requires "Test::Deep" => "0";
requires "Test::More" => "0.92";
requires "Test::Routine" => "0";
requires "Tie::File" => "0";
requires "namespace::autoclean" => "0";
requires "parent" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Path" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "List::Util" => "0";
  requires "Metabase::Report" => "0";
  requires "Path::Class" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Routine::Util" => "0";
  requires "base" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5.006";
  requires "Dist::Zilla::PluginBundle::DAGOLDEN" => "0.030";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
