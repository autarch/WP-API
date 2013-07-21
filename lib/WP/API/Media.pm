package WP::API::Media;

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types
    qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveOrZeroInt Uri );

use Moose;

my %fields = (
    date_created_gmt => 'DateTime',
    parent           => PositiveOrZeroInt,
    link             => Uri,
    title            => NonEmptyStr,
    caption          => Maybe [NonEmptyStr],
    description      => Maybe [NonEmptyStr],
    metadata         => HashRef,
    thumbnail        => Uri,
);

with 'WP::API::Role::WPObject' => {
    id_method            => 'attachment_id',
    xmlrpc_get_method    => 'wp.getMediaItem',
    xmlrpc_create_method => 'wp.uploadFile',
    fields               => \%fields,
};

sub _munge_create_parameters {
    my $class = shift;
    my $p     = shift;

    my %copy = %{$p};

    delete @{$p}{ keys %{$p} };

    $p->{data} = \%copy;

    return;
}

sub _create_result_as_params {
    my $class = shift;
    my $p     = shift;

    return ( attachment_id => $p->{id} );
}

__PACKAGE__->meta()->make_immutable();

1;
