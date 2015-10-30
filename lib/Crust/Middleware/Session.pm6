use v6;

use Crust::Middleware;

unit class Crust::Middleware::Session is Crust::Middleware;

has $.state is rw;
has $.store;

submethod BUILD(:$!state, :$!store) {
    $!state //= 'Cookie';
    $!state = self!inflate-backend('Crust::Session::State', $!state);
    $!store = self!inflate-backend('Crust::Session::Store', $!store);
}

method CALL-ME(%env) {
    self.get-session(%env);
    $.app()(%env);
}

method get-session(%env) {
    ...
}

method !inflate-backend(Str $prefix, $backend) {
    my $class = $prefix;
    if $backend.defined {
        $class ~= "::$backend";
    }
    require ::($class);
    ::($class).new
}
