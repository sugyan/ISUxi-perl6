use v6;

unit class Sabosan::Exception is Exception;

use HTTP::Status;

has int $.code;
has Str $.message;

method response() {
    $.code, [], [$.message // get_http_status_msg($.code)];
}
