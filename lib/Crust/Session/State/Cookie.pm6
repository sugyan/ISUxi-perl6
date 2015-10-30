use v6;

use Crust::Session::State;
use Crust::Request;

unit class Crust::Session::State::Cookie is Crust::Session::State;

method get-session-id(%env) {
    Crust::Request.new(%env).cookies;
    %env<crust.cookie.parsed>{$.session-key};
}
