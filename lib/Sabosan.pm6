use v6;

use Router::Boost;
my $router = Router::Boost.new;

class Sabosan {

    use Crust::Response;
    use Sabosan::Connection;
    use Sabosan::Exception;

    has Str $.root_dir;

    method new(Str $root_dir) {
        self.bless(root_dir => $root_dir);
    }

    method build_app() {
        sub (%env) {
            my $c = Sabosan::Connection.new(
                req => %env,
            );
            my $path_info = %env<PATH_INFO>;
            {
                my %match = $router.match($path_info);
                if !%match {
                    $c.halt(404);
                }
                CATCH {
                    when Sabosan::Exception {
                        die $_;
                    }
                }
            }
            my $app = sub ($c) {
                Crust::Response.new(
                    status  => 200,
                    headers => ['Content-Type' => 'text/plain'],
                    body    => ["hello!!!\n".encode('utf-8')],
                );
            };
            return $app($c).finalize;
            CATCH {
                when Sabosan::Exception {
                    return $_.response;
                }
            }
        };
    }
}

sub EXPORT {
    {
        '&get' => sub (Pair $p) {
            $router.add($p.key, $p.value);
        },
    }
}
