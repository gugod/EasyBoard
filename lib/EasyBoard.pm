package EasyBoard;
use Dancer ':syntax';
use JSON ();
use DBI;
our $VERSION = '0.1';

my $DOTCLOUD_ENV = undef;
my $DOTCLOUD_ENV_FILE = "/home/dotcloud/environment.json";

if (-f $DOTCLOUD_ENV_FILE) {
    local $/ = undef;
    open(my $fh, "<", $DOTCLOUD_ENV_FILE) or die $!;
    my $json = <$fh>;
    $DOTCLOUD_ENV = JSON::decode_json($json);
    close($fh);
}

my $dbh;
sub database {
    return $dbh if $dbh;

    my $dsn = "DBI:mysql:database=easyboard";
    my ($user, $pass) = ("root", "");

    if ($DOTCLOUD_ENV) {
        $dsn .= ";host=" . $DOTCLOUD_ENV->{DOTCLOUD_DB_MYSQL_HOST};
        $dsn .= ";port=" . $DOTCLOUD_ENV->{DOTCLOUD_DB_MYSQL_PORT};
        $user = $DOTCLOUD_ENV->{DOTCLOUD_DB_MYSQL_LOGIN};
        $pass = $DOTCLOUD_ENV->{DOTCLOUD_DB_MYSQL_PASSWORD};
    }

    $dbh = DBI->connect($dsn, $user, $pass, { mysql_auto_reconnect => 1, mysql_enable_utf8 => 1 })
        or die "Fail to connect to db: $!";

    $dbh->do("SET NAMES UTF8");
    $dbh->do(<<SCHEMA);
      create table if not exists entries (
          id integer primary key auto_increment,
          name varchar(255) not null default 'Someone',
          body text not null
      ) DEFAULT CHARACTER SET = utf8 COLLATE = utf8_bin;
SCHEMA

    return $dbh;
}

database(); # connect to database on startup

my $flash;

sub flash {
    if (defined($_[0])) {
        session flash => $_[0];
        return $_[0];
    }

    my $x = session('flash');
    session flash => undef;
    return $x;
}

get '/' => sub {
    my $entries = database->selectall_arrayref(
        "SELECT * FROM entries ORDER BY id DESC LIMIT 0, 25",
        { Slice => {} }
    );

    template 'index', {
        flash => flash(),
        entries => $entries
    };
};

post '/' => sub {
    unless (params->{"body"}) {
        flash("Message body is required");
        redirect "/";
        return;
    }

    my $sth = database->prepare("INSERT INTO entries (name,body) VALUES (?,?)");
    $sth->execute(
        params->{name} || "Someone",
        params->{body}
    );

    flash("Posted.");
    redirect "/";
};

true;
