use v6;

class Sabosan {

    use Crust::Response;
    use Sabosan::Connection;
    use Sabosan::Exception;
    use Router::Boost::Method;
    use Template6;

    has $.router = Router::Boost::Method.new;
    has $.template = Template6.new;
    # has Str $.root_dir;

    method get(Pair $p) {
        given $p.value {
            when Pair {
                my %h := {
                    __action__ => $p.value.value,
                    __filter__ => $p.value.key,
                };
                $.router.add(['GET'], $p.key, %h);
            }
            when Code {
                my %h := {
                    __action__ => $p.value,
                    __filter__ => (),
                };
                $.router.add(['GET'], $p.key, %h);
            }
            default {
                die 'invalid values';
            }
        }
    }

    method build-app() {
        sub (%env) {
            my $c = Sabosan::Connection.new(
                tt => $.template,
                req => %env,
            );
            my %match = $.router.match(%env<REQUEST_METHOD>, %env<PATH_INFO>);
            if !%match {
                $c.halt(404);
            }
            my $code = %match{'stuff'}{'__action__'};
            my @filters = %match{'stuff'}{'__filter__'}.flat;
            my $app = sub ($c) {
                my $res = $code($c);
                given $res {
                    when Sabosan::Response {
                        return $res;
                    }
                    default {
                        die 'invalid response';
                    }
                }
            };
            for @filters.reverse -> $filter {
                say "filter: $filter";
            }
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
            $sabosan.get($p);
        },
        '&app' => sub {
            $sabosan;
        },
    };
}
