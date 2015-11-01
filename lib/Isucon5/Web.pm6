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

sub abort-content-not-found {
    my $body = $C.tt.process('error', :message('要求されたコンテンツは存在しません'));
    $C.halt(404, $body);
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

sub user-from-account($account_name) {
    my $sth = db.prepare('SELECT * FROM users WHERE account_name = ?');
    $sth.execute($account_name);
    my %user = $sth.fetchrow-hash;
    $sth.finish;
    abort-content-not-found if !%user;
    return %user;
}

sub is-friend($another_id) {
    my $user_id = session<user-id>;
    my $query = 'SELECT COUNT(1) AS cnt FROM relations WHERE (one = ? AND another = ?) OR (one = ? AND another = ?)';
    my $cnt = do {
        my $sth = db.prepare($query);
        $sth.execute($user_id, $another_id, $another_id, $user_id);
        my %result = $sth.fetchrow-hash;
        $sth.finish;
        %result<cnt>;
    };
    return $cnt > 0 ?? 1 !! 0;
}

sub mark-footprint($user-id) {
    # TODO
}

sub permitted($another_id) {
    $another_id == current-user<id> || is-friend($another_id);
}

my $PREFS;
sub prefectures {
    $PREFS ||= do {
        [
        '未入力',
        '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県', '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県', '新潟県', '富山県',
        '石川県', '福井県', '山梨県', '長野県', '岐阜県', '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県', '鳥取県', '島根県',
        '岡山県', '広島県', '山口県', '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
        ]
    };
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

get '/profile/:account_name' => <set-global authenticated> => sub ($c) {
    my $account_name = $c.args<account_name>;
    my %owner = user-from-account($account_name);
    # TODO
    my %prof = ();
    my $entries = ();
    mark-footprint(%owner<id>);

    my %locals = (
        owner => %owner,
        profile => %prof,
        entries => $entries,
        private => permitted(%owner<id>),
        is_friend => is-friend(%owner<id>),
        current_user => current-user,
        prefectures => prefectures,
    );
    $c.render('profile', |%locals);
}
