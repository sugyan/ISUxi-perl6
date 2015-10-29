use v6;

class Sabosan {

    use Crust::Response;
    use Sabosan::Connection;
    use Sabosan::Exception;
    use Router::Boost::Method;
    use Web::Template::Template6;

    has $.router = Router::Boost::Method.new;
    has $.template = Web::Template::Template6.new;
    # has Str $.root_dir;

    method build-app() {
        sub (%env) {
            my $c = Sabosan::Connection.new(
                tt => $.template,
                req => %env,
            );
            my $path_info = %env<PATH_INFO>;
            my %match = $.router.match(%env<REQUEST_METHOD>, $path_info);
            if !%match {
                $c.halt(404);
            }
            my $app = sub ($c) {
                my $res = %match{'stuff'}($c);
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
            $sabosan.router.add(['GET'], $p.key, $p.value);
        },
        '&app' => sub {
            $sabosan;
        }
    }
}
