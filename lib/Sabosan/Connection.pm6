use v6;

unit class Sabosan::Connection;

use Sabosan::Exception;

method halt(int $code, Str $message?) {
    die Sabosan::Exception.new(
        code => $code,
        message => $message,
    );
}
