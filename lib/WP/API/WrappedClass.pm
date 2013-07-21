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

    my ($method) = $AUTOLOAD =~ /::(\w+)$/;

    return $self->class()->$method( api => $self->api(), @_ );
}

__PACKAGE__->meta()->make_immutable();

# This is hack so we can make an immutablized constructor - Moose will not
# rename the constructor as part of inlining.
*wrap = \&new;

Package::Stash->new(__PACKAGE__)->remove_symbol('&new');

# Now we want ->new to call the method on the wrapped class, not on
# WrappedClass itself.
Package::Stash->new(__PACKAGE__)->add_symbol(
    '&new' => sub {
        my $self = shift;

        $self->class()->new( api => $self->api(), @_ );
    }
);

1;
