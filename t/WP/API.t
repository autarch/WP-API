use strict;
use warnings;

use lib 't/lib';
use Test::XMLRPC::Lite;

use Test::Fatal;
use Test::More 0.88;

use SOAP::Lite;
use WP::API;

{
    my $api = WP::API->new(
        blog_id         => 42,
        username        => 'testuser',
        password        => 'testpass',
        proxy           => 'http://example.com/xmlrpc.php',
        server_timezone => 'UTC',
        _xmlrpc_class   => 'Test::XMLRPC::Lite'
    );

    my @params = ( 'foo', 99, { x => 'y' } );

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'test.Method', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,            'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser',    'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass',    'fourth argument to XMLRPC::Lite->call' );
        is_deeply(
            \@_, \@params,
            'additional parameters to XMLRPC::Lite->call'
        );
    };

    local $Test::XMLRPC::Lite::Call
        = XMLRPC::Deserializer->deserialize(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member><name>post_id</name><value><string>1252</string></value></member>
          <member><name>post_title</name><value><string>Test</string></value></member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my $result = $api->call( 'test.Method', @params );

    is_deeply(
        $result,
        {
            post_id    => 1252,
            post_title => 'Test',
        },
        'result  from XMLRPC::Lite->call'
    );
}

done_testing();
