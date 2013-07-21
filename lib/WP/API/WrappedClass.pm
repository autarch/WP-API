package WP::API::WrappedClass;

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types qw( ClassName );

use Moose;

has api => (
    is       => 'ro',
    isa      => 'WP::API',
    required => 1,
);

has class => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD =~ /::(\w+)$/;

    return $self->class()->$method( api => $self->api(), @_ );
}

__PACKAGE__->meta()->make_immutable();

1;
