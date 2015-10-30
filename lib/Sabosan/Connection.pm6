use v6;

unit class Sabosan::Connection;

use Sabosan::Exception;
use Sabosan::Response;

has $.tt;
has $.req;
has %.stash;

method halt(int $code, Str $message?) {
    die Sabosan::Exception.new(
        code => $code,
        message => $message,
    );
}

method render(Str $template, *%named) {
    my $body = $.tt.process($template, |%named);
    return Sabosan::Response.new(
        status => 200,
        headers => [ 'Content-Type' => 'text/html; charset=UTF-8', 'X-Frame-Options' => 'DENY' ],
        body => [$body],
    );
}

method redirect(Str $url) {
    return Sabosan::Response.new(
        status => 302,
        headers => [ 'Location' => $url ],
        body => [],
    );
}
