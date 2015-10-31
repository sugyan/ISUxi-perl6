use v6;

use Crust::Middleware::Session;
use Crust::Session::State::Cookie;
use Digest::HMAC;
use Digest::SHA;
use MIME::Base64;

unit class Crust::Middleware::Session::Cookie is Crust::Middleware::Session;

has $.session-key;
has $.secret;

submethod BUILD(:$!session-key, :$!secret) {
    self.state.session-key = $!session-key;
}

method get-session(%env) {
    my $cookie = $.state.get-session-id(%env) or return;

    # TODO
}

method save-state($id, @res, %env) {
    my $cookie = self!serialize($id, %env<p6sgix.session>);
    self.state.finalize($cookie, @res, %env<p6sgix.session.options>);
}

method generate-id(%env) {
    now.Num.Str;
}

method !serialize($id, %session) {
    my $b64 = MIME::Base64.encode(%session.perl.encode('utf8'));
    join ':', $id, $b64, self!sig($b64);
}

method !sig($b64) {
    return '.' unless $.secret;
    hmac-hex($b64, $.secret, &sha1);
}
