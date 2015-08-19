#! /usr/bin/perl
use Eirotic;
use Test::More;
use open qw< :utf8 :std >;
use RTx::Provision::Read::Spreadsheet; 

say YAML::Dump
    ( RTx::Provision::Read::Spreadsheet
    -> new(qw( source examples/simple.ods ))
    -> dump )

# Documentation still relevant ? 
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
