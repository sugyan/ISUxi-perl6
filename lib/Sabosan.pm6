use v6;

class Sabosan {

    use Crust::Response;
    use Sabosan::Connection;
    use Sabosan::Exception;
    use Router::Boost;

    has $.router = Router::Boost.new;
    # has Str $.root_dir;

    method new {
        self.bless;
    }

    method build-app() {
        sub (%env) {
            my $c = Sabosan::Connection.new(
                req => %env,
            );
            my $path_info = %env<PATH_INFO>;
            {
                my %match = $.router.match($path_info);
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
    my $sabosan = Sabosan.new;
    {
        '&get' => sub (Pair $p) {
            $sabosan.router.add($p.key, $p.value);
        },
        '&app' => sub {
            $sabosan.build-app;
        }
    }
}
