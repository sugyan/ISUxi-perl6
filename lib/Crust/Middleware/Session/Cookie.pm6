use v6;

use Crust::Middleware::Session;
use Crust::Session::State::Cookie;
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
    # TODO Digest::HMAC_SHA1::hmac_sha1_hex($b64, $self->secret);
}
