
use strict;
use warnings;

use Test::MockObject;
use Test::More tests => 10;
use Test::Fatal;

sub RPX() {
  'Catalyst::Authentication::Credential::RPX';
}

sub APIRPX() {
  'Net::API::RPX';
}

# Order is important

use lib "t/mock";

BEGIN {
  use_ok( APIRPX() );
}

BEGIN {
  use_ok( RPX() );
}

my $config = {
  api_key     => 'SomeApiKey',
  base_url    => 'http://example.com',
  token_field => 'token',
};

my $realm = Test::MockObject->new();
$realm->mock( find_user => sub { $_[1] } );

my %data = map {
  my $i   = $_;
  my $req = Test::MockObject->new();
  $req->mock(
    params => sub {
      {
        field => 'value',
        token => $i,
      };
    }
  );
  my $c = Test::MockObject->new();
  $c->mock(
    req   => sub { $req },
    debug => sub { 1 },
    log   => sub { 1 },
  );

  $i => $c,

} qw( A B );

{    # Success

  my ( $m, $user );

  is( exception { $m = RPX->new( $config, $data{A}, $realm ) }, undef, "Create Credential ( XSUCCESS )" );
  can_ok( $m, qw( new authenticate ) );

  is( exception { $user = $m->authenticate( $data{A}, $realm ); }, undef, "Authenticate Credential ( XSUCCESS )" );
  is_deeply( $user, $Net::API::RPX::RESPONSES->{'A'}, "Credentials Match Expectations" );
}

{    # Fail
  my ( $m, $user );
  is( exception { $m = RPX->new( $config, $data{B}, $realm, ) }, undef, "Create Credential ( XFAIL )" );
  can_ok( $m, qw( new authenticate  ) );
  is( exception { $user = $m->authenticate( $data{B}, $realm, ); }, undef, "Authenticate Credential ( XFAIL )" );
  is_deeply( $user, undef, "Authentication fails properly" );
}
