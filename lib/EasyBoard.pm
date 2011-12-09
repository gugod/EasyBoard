package EasyBoard;
use Dancer ':syntax';
use DBI;

our $VERSION = '0.1';

my $flash = "";

sub flash {
    if (defined($_[0])) {
        $flash = $_[0];
    }
    return $flash;
}

sub database {
    my $dbh = DBI->connect("dbi:mysql:dbname=easyboard", "root");

    $dbh->do(<<SCHEMA);
      create table if not exists entries (
          id integer primary key auto_increment,
          name varchar(255) not null default 'Someone',
          body text not null
      );
SCHEMA

    return $dbh;
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

    redirect "/";
};

true;
