use v6;

unit class Isucon5::Web;

use Sabosan;

method psgi(Str $root_dir) {
    app;
}

get '/' => sub ($c) {
    say 'index';
};
