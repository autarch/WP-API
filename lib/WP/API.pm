package WP::API;

use strict;
use warnings;
use namespace::autoclean;

use Carp qw( confess );
use XMLRPC::Lite;
use WP::API::Types qw( ClassName NonEmptyStr PositiveInt Uri );
use WP::API::WrappedClass;

use Moose;

has blog_id => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

has [qw( username password )] => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
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

for my $type (qw( media page post user )) {
    my $sub = sub {
        my $self = shift;
        return $self->_wrapped_class( 'WP::API::' . ucfirst $type );
    };

    __PACKAGE__->meta()->add_method( $type => $sub );
}

sub _wrapped_class {
    my $self = shift;

    return WP::API::WrappedClass->new(
        class => shift,
        api   => $self,
    );
}

sub call {
    my $self   = shift;
    my $method = shift;

    my $call = $self->_xmlrpc()->call(
        $method,
        $self->blog_id(),
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
    for my $info (qw( code string detail )) {
        my $meth  = 'fault' . $info;
        my $value = $fault->$meth();

        next unless defined $value && length $value;

        push @pieces, ( ucfirst $meth ) . ": $value";
    }

    my $error = "Error calling $method XML-RPC method: ";
    $error .= join ' - ', @pieces;

    local $Carp::CarpLevel = $Carp::CarpLevel + 2;

    confess $error;
}

__PACKAGE__->meta()->make_immutable();

1;
