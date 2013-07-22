package WP::API::Types;

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Types::Common::String;
use MooseX::Types::Moose;
use MooseX::Types::Path::Class;
use MooseX::Types::URI;

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::Numeric
        MooseX::Types::Common::String
        MooseX::Types::Moose
        MooseX::Types::Path::Class
        MooseX::Types::URI
        )
);

1;

# ABSTRACT: Type library for the WP-API distro

__END__

=head1 DESCRIPTION

There are no user serviceable parts in here.

=cut
