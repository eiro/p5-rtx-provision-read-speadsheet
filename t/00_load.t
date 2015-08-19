#! /usr/bin/perl
use Eirotic;
use Test::More;
use ok $_=q(RTx::Provision::Read::Spreadsheet);

ok $_->new(qw( source examples/simple.ods ))->isa($_)
, "constructor work with a valid source";

eval { $_->new };
ok $@, "new dies without params";

eval { $_->new(qw( source \o/ )) };
ok $@, "new dies without valid source";

done_testing;

# Documentation : 
#    say YAML::Dump $provision->data('Users');
#    say YAML::Dump $provision->attrs('Users');
__END__
#say for keys %{ $provision->_cells };
values
Groups
CustomFields
Queues
membership
ACL
Users
