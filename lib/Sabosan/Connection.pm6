use v6;

unit class Sabosan::Connection;

use Sabosan::Exception;

has $.tt;

method halt(int $code, Str $message?) {
    die Sabosan::Exception.new(
        code => $code,
        message => $message,
    );
}

method render(Str $template, *%named) {
    my $body = $.tt.render($template, |%named);
}
