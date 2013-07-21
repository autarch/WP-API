package WP::API::Media;

use strict;
use warnings;
use namespace::autoclean;

use DateTime::Format::ISO8601;
use Scalar::Util qw( blessed );
use WP::API::Types qw( ArrayRef Bool HashRef Maybe NonEmptyStr PositiveInt );

use Moose;

with 'WP::API::Role::WPObject';

my %fields = (
    date_created_gmt => 'DateTime',
    parent           => Maybe [PositiveInt],
    link             => NonEmptyStr,
    title            => NonEmptyStr,
    caption          => Maybe [NonEmptyStr],
    description      => Maybe [NonEmptyStr],
    metadata         => HashRef,
    image_meta       => HashRef,
);

with 'WP::API::Role::WPObject' => {
    id_method            => 'post_id',
    xmlrpc_get_method    => 'wp.getMediaItem',
    xmlrpc_create_method => 'wp.uploadFile',
    fields               => \%fields,
};

for my $field ( keys %fields ) {
    my $spec = $fields{$field};

    if ( blessed($spec) ) {
        has $field => (
            is       => 'ro',
            isa      => $spec,
            init_arg => undef,
            lazy     => 1,
            default  => sub { $_[0]->_attachment_data()->{$field} },
        );
    }
    else {
        has $field => (
            is       => 'ro',
            init_arg => undef,
            lazy     => 1,
            %{$spec},
        );
    }
}

sub _munge_create_parameters {
    my $class = shift;
    my $p     = shift;

    $class->_deflate_datetimes( $p, 'attachment_date_gmt' );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;
