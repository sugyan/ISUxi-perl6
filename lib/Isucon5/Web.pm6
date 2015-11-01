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
    my %result = $sth.fetchrow-hash;
    $sth.finish;
    if !%result {
        abort-authentication-error;
    }
    session<user-id> = %result<id>;
    return %result;
}

sub current-user {
    my $user-id = session<user-id>;
    return unless $user-id;

    my $sth = db.prepare('SELECT id, account_name, nick_name, email FROM users WHERE id = ?');
    $sth.execute($user-id);
    my %user = $sth.fetchrow-hash;
    $sth.finish;
    if !%user {
        session<user-id> = Nil;
        abort-authentication-error;
    }
    return %user;
}

filter 'authenticated' => sub ($app) {
    sub ($c) {
        if !current-user() {
            return $c.redirect('/login');
        }
        $app($c);
    }
}

filter 'set-global' => sub ($app) {
    sub ($c) {
        $C = $c;
        $C.stash<session> = $c.req.env<p6sgix.session>;
        $app($c);
    };
}

get '/login' => sub ($c) {
    $c.render('login', :message('高負荷に耐えられるSNSコミュニティサイトへようこそ!'));
};

post '/login' => <set-global> => sub ($c) {
    my ($email, $password) = $c.req.parameters<email password>;
    authenticate($email, $password);
    $c.redirect('/');
};

get '/logout' => <set-global> => sub ($c) {
    session<user-id>:delete;
    $c.redirect('/login');
};

get '/' => <set-global authenticated> => sub ($c) {
    my %profile = do {
        my $sth = db.prepare('SELECT * FROM profiles WHERE user_id = ?');
        $sth.execute(current-user<id>);
        my %profile = $sth.fetchrow-hash;
        $sth.finish;
        %profile;
    };
    # TODO
    my $entries = ();
    my $comments_for_me = ();
    my $entries_of_friends = ();
    my $comments_of_friends = ();
    my $friends = ();
    my $footprints = ();

    my %locals = (
        user => current-user,
        profile => %profile,
        entries => $entries,
        comments_for_me => $comments_for_me,
        entries_of_friends => $entries_of_friends,
        comments_of_friends => $comments_of_friends,
        friends => $friends,
        footprints => $footprints,
    );
    $c.render('index', |%locals);
};
