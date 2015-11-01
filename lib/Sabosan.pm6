use v6;

class Sabosan {

    use Sabosan::Connection;
    use Sabosan::Exception;
    use Sabosan::Request;
    use Sabosan::Response;
    use Router::Boost::Method;
    use Template6;

    has $.router = Router::Boost::Method.new;
    has $.template = Template6.new;
    has %.filters;
    # has Str $.root_dir;

    method connect(Array $methods, Pair $p) {
        given $p.value {
            when Pair {
                my %h := {
                    __action__ => $p.value.value,
                    __filter__ => $p.value.key,
                };
                $.router.add($methods, $p.key, %h);
            }
            when Code {
                my %h := {
                    __action__ => $p.value,
                    __filter__ => (),
                };
                $.router.add($methods, $p.key, %h);
            }
            default {
                die 'invalid values';
            }
        }
    }

    method filter(Pair $p) {
        %.filters.push: $p;
    }

    method build-app() {
        sub (%env) {
            my $c = Sabosan::Connection.new(
                tt => $.template,
                req => Sabosan::Request.new(%env),
                stash => {},
            );
            my %match = $.router.match(%env<REQUEST_METHOD>, %env<PATH_INFO>);
            if !%match {
                $c.halt(404);
            }
            if %match<is-method-not-allowed> {
                $c.halt(405);
            }
            my $code = %match<stuff><__action__>;
            my @filters = %match<stuff><__filter__>.flat;
            $c.args = %match<captured>;
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
                $app = self!wrap-filter($filter, $app);
            }
            return $app($c).finalize;
            CATCH {
                when Sabosan::Exception {
                    return $_.response;
                }
            }
        };
    }

    method !wrap-filter(Str $name, $app) {
        my $sub = %.filters{$name};
        die "Filter $name does not exist" unless $sub.defined;
        return $sub($app);
    }
}

sub EXPORT {
    my $sabosan = Sabosan.new;
    {
        '&get' => sub (Pair $p) {
            $sabosan.connect(['GET', 'HEAD'], $p);
        },
        '&post' => sub (Pair $p) {
            $sabosan.connect(['POST'], $p);
        },
        '&filter' => sub (Pair $p) {
            $sabosan.filter($p);
        },
        '&app' => sub {
            $sabosan;
        },
    };
}
