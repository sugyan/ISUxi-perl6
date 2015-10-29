use v6;

unit class Isucon5::Web;

use Sabosan;

method psgi(Str $root-dir) {
    my $app = app;
    $app.template.add-path($root-dir ~ '/views');
    $app.build-app;
}

get '/login' => sub ($c) {
    $c.render('login', :message('高負荷に耐えられるSNSコミュニティサイトへようこそ!'));
};

get '/' => <set_global authenticated> => sub ($c) {
    $c.render('index');
};
