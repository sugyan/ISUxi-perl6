use v6;

unit class Isucon5::Web;

use Sabosan;

method psgi(Str $root_dir) {
    Sabosan.new($root_dir).build_app
}

get '/' => sub ($c) {
    say 'index';
};
