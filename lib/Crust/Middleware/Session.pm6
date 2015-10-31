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
    my ($id, %session) = self.get-session(%env);
    if $id.defined && %session.defined {
        %env<p6sgix.session> = %session;
    } else {
        $id = self.generate-id(%env);
        %env<p6sgix.session> = {};
    }
    %env<p6sgix.session.options> = { id => $id };

    my @res = $.app()(%env);
    self.finalize(%env, @res);
    return @res;
}

method get-session(%env) {
    ...
}

method generate-id(%env) {
    ...
}

method commit(%env) {
    my %session = %env<p6sgix.session>;
    my %options = %env<p6sgix.session.options>;
    if %options<expire> {
        # TODO
    } elsif %options<change_id> {
        # TODO
    } else {
        $.store.store(%options<id>, %session);
    }
}

method save-state($id, @res, %env) {
    ...
}

method finalize(%env, @res) {
    my %session = %env<p6sgix.session>;
    my %options = %env<p6sgix.session.options>;
    self.commit(%env) unless %options<no_store>;
    if %options<expire> {
        # TODO
    } else {
        self.save-state(%options<id>, @res, %env);
    }
}

method !inflate-backend(Str $prefix, $backend) {
    my $class = $prefix;
    if $backend.defined {
        $class ~= "::$backend";
    }
    require ::($class);
    ::($class).new
}
