use v6;

unit class Crust::Session::State;

has $.session-key is rw;

method finalize($id, $res, $options) {
    ...
}
