package WP::API::Post;

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types
    qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveInt PositiveOrZeroInt Uri );

use Moose;
use MooseX::StrictConstructor;

my %fields = (
    post_type         => NonEmptyStr,
    post_status       => NonEmptyStr,
    post_title        => NonEmptyStr,
    post_author       => PositiveInt,
    post_excerpt      => Maybe [NonEmptyStr],
    post_content      => NonEmptyStr,
    post_date_gmt     => 'DateTime',
    post_date         => 'DateTime',
    post_modified_gmt => 'DateTime',
    post_modified     => 'DateTime',
    post_format       => NonEmptyStr,
    post_name         => NonEmptyStr,
    post_password     => Maybe [NonEmptyStr],
    comment_status    => NonEmptyStr,
    ping_status       => NonEmptyStr,
    sticky            => Bool,
    post_thumbnail    => HashRef,
    post_parent       => PositiveOrZeroInt,
    post_mime_type    => Maybe [NonEmptyStr],
    link              => Uri,
    guid              => Uri,
    menu_order        => PositiveOrZeroInt,
    custom_fields     => ArrayRef [HashRef],
    terms             => ArrayRef [HashRef],
    enclosure         => HashRef,
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

    $class->_deflate_datetimes(
        $p,
        'post_date_gmt',     'post_date',
        'post_modified_gmt', 'post_modified',
    );

    return;
}

sub _create_result_as_params {
    my $class = shift;
    my $p     = shift;

    return ( post_id => $p );
}

sub _munge_raw_data {
    my $self = shift;
    my $p    = shift;

    # WordPress 3.5 seems to return an array instead of a struct when the post
    # has no thumbnail.
    {
        local $@;
        if ( eval { my $foo = @{ $p->{post_thumbnail} }; 1 } ) {
            $p->{post_thumbnail} = {};
        }
    }

    return;
}

__PACKAGE__->meta()->make_immutable();

1;
