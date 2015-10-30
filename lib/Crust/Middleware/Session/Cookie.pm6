use v6;

use Crust::Middleware::Session;
use Crust::Session::State::Cookie;

unit class Crust::Middleware::Session::Cookie is Crust::Middleware::Session;

has $.session-key;
has $.secret;

submethod BUILD(:$!session-key, :$!secret) {
    say 'BUILD Crust::Middleware::Session::Cookie';
    self.state.session-key = $!session-key;
}

method get-session(%env) {
    dd $.state.get-session-id(%env);
}
