package WP::API::Post;

use strict;
use warnings;
use namespace::autoclean;

use DateTime::Format::ISO8601;
use Scalar::Util qw( blessed );
use WP::API::Types qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveInt );

use Moose;
use MooseX::Params::Validate qw( validated_hash );

my %fields = (
    post_type      => NonEmptyStr,
    post_status    => NonEmptyStr,
    post_title     => NonEmptyStr,
    post_author    => PositiveInt,
    post_excerpt   => Maybe [NonEmptyStr],
    post_content   => NonEmptyStr,
    post_date_gmt  => 'DateTime',
    post_date      => 'DateTime',
    post_format    => NonEmptyStr,
    post_name      => Maybe [NonEmptyStr],
    post_password  => Maybe [NonEmptyStr],
    comment_status => Maybe [NonEmptyStr],
    ping_status    => Maybe [NonEmptyStr],
    sticky         => Bool,
    post_thumbnail => HashRef,
    post_parent    => Maybe [PositiveInt],
    custom_fields  => ArrayRef [HashRef],
    terms          => ArrayRef [HashRef],
    enclosure      => HashRef,
);

with 'WP::API::Role::WPObject' => {
    id_method            => 'post_id',
    xmlrpc_get_method    => 'wp.getPost',
    xmlrpc_create_method => 'wp.newPost',
    fields               => \%fields,
};

sub _munge_create_parameters {
    my $class = shift;
    my $p     = shift;

    $p->{post_status} //= 'publish';

    $class->_deflate_datetimes( $p, 'post_date_gmt', 'post_date' );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;
