use v6;

unit class Crust::Session::Store;

has $.stash = {};

method store(Str $session-id, %session) {
    $.stash{$session-id} = %session;
}
