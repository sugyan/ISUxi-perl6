use v6;

use Crust::Session::State;
use Crust::Request;

unit class Crust::Session::State::Cookie is Crust::Session::State;

has $.path;
has $.domain;
has $.expires;
has $.secure;
has $.httponly;

method get-session-id(%env) {
    Crust::Request.new(%env).cookies;
    %env<crust.cookie.parsed>{$.session-key};
}

method finalize($id, @res, %options) {
    my %opts := self!merge-options(%options);
    self!set-cookie($id, @res, %opts);
}

method !merge-options(%options) {
    %options<id>:delete;
    %options<path>     = $.path // '/' if !(%options<path>:exists);
    %options<domain>   = $.domain      if !(%options<domain>:exists) && $.domain.defined;
    %options<secure>   = $.secure      if !(%options<secure>:exists) && $.secure.defined;
    %options<httponly> = $.httponly    if !(%options<httponly>:exists) && $.httponly.defined;
    if (!(%options<expires>:exists) && $.expires.defined) {
        %options<expires> = now.Int + $.expires;
    }
    %options;
}

method !set-cookie($id, @res, %options) {
    # TODO add cookie to @res[1]
}
