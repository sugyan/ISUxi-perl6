use v6;

unit class Isucon5::Web;

use Sabosan;
use DBIish;

method psgi(Str $root-dir) {
    my $app = app;
    $app.template.add-path($root-dir ~ '/views');
    $app.build-app;
}

my $db;
sub db {
    $db //= do {
        my %conf := {
            host => %*ENV<ISUCON5_DB_HOST> // 'localhost',
            port => %*ENV<ISUCON5_DB_port> // '3306',
            user => %*ENV<ISUCON5_DB_USER> // 'root',
            password => %*ENV<ISUCON5_DB_PASSWORD> // '',
            database => %*ENV<ISUCON5_DB_NAME> // 'isucon5q',
        };
        DBIish.connect('mysql', |%conf);
    };
}
db();

my $C;

sub session {
    $C.stash<session> // {};
}

sub abort-authentication-error {
    session<user_id> = Nil;
    my $body = $C.tt.process('login', :message('ログインに失敗しました'));
    $C.halt(401, $body);
}

sub authenticate(Str $email, Str $password) {
    my $sth = db.prepare(q:to/SQL/);
SELECT u.id AS id, u.account_name AS account_name, u.nick_name AS nick_name, u.email AS email
FROM users u
JOIN salts s ON u.id = s.user_id
WHERE u.email = ? AND u.passhash = SHA2(CONCAT(?, s.salt), 512)
SQL
    $sth.execute($email, $password);
    my $result = $sth.fetchrow-hash;
    if !$result {
        abort-authentication-error;
    }
    # TODO: set to session
    say $result;
    return $result;
}

sub current-user {
    my $user_id = session<user_id>;
    return unless $user_id;

    # TODO: get from session
}

filter 'authenticated' => sub ($app) {
    sub ($c) {
        if ! current-user() {
            return $c.redirect('/login');
        }
        $app($c);
    }
}

filter 'set_global' => sub ($app) {
    sub ($c) {
        $C = $c;
        # TODO: session settings
        $app($c);
    };
}

get '/login' => sub ($c) {
    $c.render('login', :message('高負荷に耐えられるSNSコミュニティサイトへようこそ!'));
};

post '/login' => <set_global> => sub ($c) {
    my ($email, $password) = $c.req.parameters<email password>;
    authenticate($email, $password);
    $c.redirect('/');
};

get '/' => <set_global authenticated> => sub ($c) {
    $c.render('index');
};
