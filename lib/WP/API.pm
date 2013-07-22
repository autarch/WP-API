package WP::API;

use strict;
use warnings;
use namespace::autoclean;

use Carp qw( confess );
use XMLRPC::Lite;
use WP::API::Media;
use WP::API::Post;
use WP::API::Types qw( ClassName NonEmptyStr PositiveInt Uri );
use WP::API::WrappedClass;

use Moose;

has [qw( username password )] => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has blog_id => (
    is      => 'ro',
    isa     => PositiveInt,
    lazy    => 1,
    builder => '_build_blog_id',
);

has proxy => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has server_timezone => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

# This exists to make it possible to mock out the XMLRPC::Lite->call method in
# tests.
has _xmlrpc_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'XMLRPC::Lite',
);

has _xmlrpc => (
    is       => 'ro',
    isa      => 'XMLRPC::Lite',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_xmlrpc',
);

sub _build_xmlrpc {
    my $self = shift;

    return $self->_xmlrpc_class()->proxy( $self->proxy() );
}

sub _build_blog_id {
    my $self = shift;

    my $blogs = $self->call('wp.getUsersBlogs');

    if ( @{$blogs} > 1 ) {
        confess
            'This user belongs to more than one blog. Please supply a blog_id to the WP::API constructor';
    }

    return $blogs->[0]{blogid};
}

for my $type (qw( media page post user )) {
    my $sub = sub {
        my $self = shift;
        return $self->_wrapped_class( 'WP::API::' . ucfirst $type );
    };

    __PACKAGE__->meta()->add_method( $type => $sub );
}

sub _wrapped_class {
    my $self = shift;

    return WP::API::WrappedClass->wrap(
        class => shift,
        api   => $self,
    );
}

sub call {
    my $self   = shift;
    my $method = shift;

    my $call = $self->_xmlrpc()->call(
        $method,
        ( $method eq 'wp.getUsersBlogs' ? () : $self->blog_id() ),
        $self->username(),
        $self->password(),
        @_,
    );

    $self->_check_for_error( $call, $method );

    return $call->result()
        or confess
        "No result from call to $method XML-RPC method and no error!";
}

sub _check_for_error {
    my $self   = shift;
    my $call   = shift;
    my $method = shift;

    my $fault = $call->fault()
        or return;

    my @pieces;
    for my $key (qw( Code String Detail )) {
        my $value = $fault->{'fault'.$key};

        next unless defined $value && length $value;

        push @pieces, "$key = $value";
    }

    my $error = "Error calling $method XML-RPC method: ";
    $error .= join ' - ', @pieces;

    local $Carp::CarpLevel = $Carp::CarpLevel + 2;

    confess $error;
}

__PACKAGE__->meta()->make_immutable();

1;
