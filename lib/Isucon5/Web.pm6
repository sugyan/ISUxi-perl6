use v6;

unit class Isucon5::Web;

use Sabosan;

method psgi(Str $root-dir) {
    my $app = app;
    $app.template.set-path($root-dir ~ '/views');
    $app.build-app;
}

get '/' => sub ($c) {
    $c.render('index.tt');
};
