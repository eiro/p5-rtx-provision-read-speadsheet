package RTx::Provision::Read::Spreadsheet;
use Moo;
use Eirotic;
use Spreadsheet::Read;
use Array::Transpose;
use namespace::clean;
use Type::Tiny;

sub carry_data :prototype(_)
    { grep defined && /\S/, @{shift,} } 

sub map_hash_with ($attrs,@data)
    { map { my %e; @e{ @$attrs } = @$_; \%e } @data }

sub _as_table :prototype(_) {
    # removing useless cells
    # * remove empty lines
    # * transpose
    # * remove empty lines again

    # now first column is the list of attributes, the rest data
    my ($attrs, @data ) = 
        grep carry_data, 
        transpose[
            grep {defined and carry_data}
            @{+shift} ];

    [ $attrs, \@data ];

}

# my $ExistingFile = sub ($path) {
#     -f $path or die "$path must be an existing file"
# };
# 
# my $hashRef = sub ($v) {
#     defined $v or die 
#     $r// = 'Undefined';
#     defined $r and $r='Undefined';
#     defined $r &&
#     grep /HASH/, ref $r or die "$r must be"
# 
# }

my @definedHashRef = ( default => sub{+{}} );

my $ExistingFile = 
Type::Tiny->new
( name        => 'ExistingFile'
, constraint  => sub {-f}
, message     => sub {"$_ must be an existing file"} );

my $HashRef = Type::Tiny->new
( name        => 'HashRef'
, constraint  => sub { grep /HASH/, ref }
, message     => sub {"$_ must be a ref to an hash"} );

has qw( source is rw required 1 ), isa => $ExistingFile;

has qw( read      is lazy )
, default => sub ($self) { ReadData $self->source };

has qw( _cells is lazy )
, default => sub ($self) {
    +{ map {
        my @v =
            grep defined,
            @{$_ }{qw( label cell )};
        if (@v == 2) { @v }
        else {} 
    } @{ $self->read } }
};

has qw( _table   is ro ) , @definedHashRef;
has qw( _entries is ro ) , @definedHashRef;

sub table ($self,$key=return $self->_table) {
    $self->_table->{$key}
        ||= _as_table($self->_cells->{$key})
        ||  die "the $key sheet is missing  in $self->source"
}

sub attrs    ($self,$table) { $self->table($table)->[0] }
sub data     ($self,$table) { $self->table($table)->[1] }
sub _lines   ($self,$table) {
    map { $self->attrs($_), @{ $self->data($_) } }
        $table
}
sub entries  ($self,$table) { map_hash_with $self->_lines($table) }  


sub dump ($self) {
    my %config =
        ( map +( $_ => [ $self->entries($_) ] )
        , qw( Queues ));

    $config{Groups} = do {

        my $G = +{ map { $$_{Name} => $_ } $self->entries('Groups') };

        map { push
            @{ $G
                -> { $$_{Group} } 
                -> {Members}
                -> {$$_{Type}} ||= [] }
            , $$_{Member}
        } $self->entries('membership');

        [ values %$G ]

    };

    $config{CustomFields} = do {
        my $V= {};
        map { push @{ $$V{ delete $$_{CustomField} } ||= [] }, $_ }
            $self->entries('values');

        [ map {
            if (my $v = delete $$V{$$_{Name}} ) { $$_{Values} = $v }
            $_
        } $self->entries('CustomFields') ]

    };

    \%config;
}



# sub sheets        ($self) { grep $$_{label}, @{$self->read} }
# 
# sub list  ($self,$table) {
#     state $cache = {};
#     $$cache{$table} ||= [ _entries $self->_cells->{$table} ];
# }

1;
