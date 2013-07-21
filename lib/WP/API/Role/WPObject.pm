package WP::API::Role::WPObject;

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Params::Validate qw( validated_hash );
use Scalar::Util qw( blessed );
use WP::API::Types qw( HashRef NonEmptyStr PositiveInt );

use MooseX::Role::Parameterized;

parameter id_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter xmlrpc_get_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter xmlrpc_create_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter fields => (
    isa      => HashRef,
    required => 1,
);

has api => (
    is       => 'ro',
    isa      => 'WP::API',
    required => 1,
);

has _raw_data => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_raw_data',
);

my $_make_field_attrs = sub {
    my $fields = shift;

    for my $field ( keys %{$fields} ) {
        my $spec = $fields->{$field};

        my %attr_p = (
            is       => 'ro',
            isa      => $spec,
            init_arg => undef,
            lazy     => 1,
        );

        my $default;
        if ( $spec eq 'DateTime' ) {
            my $datetime_method
                = $field =~ /_gmt$/ ? '_gmt_datetime' : '_floating_datetime';
            $default = sub {
                $_[0]->$datetime_method( $_[0]->_raw_data()->{$field} );
            };
        }
        else {
            my $default = sub { $_[0]->_raw_data()->{$field} },;
        }

        has $field => (
            is       => 'ro',
            isa      => $spec,
            init_arg => undef,
            lazy     => 1,
            default  => $default,
        );
    }
};

sub _gmt_datetime {
    shift;
    my $value = shift;

    return DateTime::Format::ISO8601->parse_datetime($value)
        ->set_time_zone('UTC') );
}

sub _floating_datetime {
    shift;
    my $value = shift;

    return DateTime::Format::ISO8601->parse_datetime($value)
        ->set_time_zone( $self->api()->server_timezone() ) );
}

role {
    my $p = shift;

    $_make_field_attrs->( $p->{fields} );

    my $id_method = $p->id_method();

    has $id_method => (
        is       => 'ro',
        isa      => PositiveInt,
        required => 1,
    );

    my $xmlrpc_get_method = $p->xmlrpc_get_method();

    method _build_raw_data => sub {
        my $self = shift;

        return $api->call( $xmlrpc_get_method, $self->$id_method() );
    };

    my $xmlrpc_create_method = $p->xmlrpc_create_method();

    method create => sub {
        my $class = shift;
        my %p     = validated_hash(
            \@_,
            api                            => { isa => 'WP::API' },
            MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
        );

        my $api = delete $p{api};

        $class->_munge_create_parameters( \%p );

        my $id = $api->call(
            $create_method,
            \%p,
        );

        return $class->new( $id_method => $id, api => $api );
    };
};

sub _munge_create_parameters {
    return;
}

sub _deflate_datetimes {
    my $class  = shift;
    my $p      = shift;
    my @fields = @_;

    for my $field (@fields) {
        next unless $p->{$field} && blessed $p->{field};

        if ( $field =~ /_gmt$/ ) {
            $p->{$field}
                = $p->{$field}->clone()->set_time_zone('UTC')->datetime()
                . 'Z';
        }
        else {

            $p->{$field}
                = $p->{$field}->clone()
                ->set_time_zone( $self->api()->server_time_zone() )
                ->datetime();
        }
    }

    return;
}

1;
