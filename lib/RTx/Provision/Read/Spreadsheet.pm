package RTx::Provision::Read::Spreadsheet;
use Spreadsheet::Read;
use Array::Transpose;
use Eirotic;
use Exporter 'import';
our @EXPORT_OK = qw(
    sheets
    rt_provision
    sheets_as_rt_provision
    values_for keys_for
);

sub trimi            { s/ ^\s+ | \s+$ //xg  }
sub trim             { s/ ^\s+ | \s+$ //xgr }
sub values_for  ($key,$sheets=$_) { $$sheets{$key}[1] }
sub keys_for    ($key,$sheets=$_) { $$sheets{$key}[0] }
sub entries_for {
    my @v = (@_,$_)[0,1];
    my @f = @{keys_for @v};
    map { my %e; @e{@f} = @$_ ; \%e } @{values_for @v};
}

sub cell_with_data :prototype() {
    defined or return;
    ref and die;
    trimi;
    length
}

sub line_with_data :prototype(_) { grep cell_with_data, @{shift,} }

sub columns :prototype(_) {
    # columns are [$header,[@entries]]
    my ($attrs, @data ) =
        grep line_with_data  # remove empty lines again (actually empty cols)
        , transpose[       # rotate
            grep line_with_data, # remove empty lines
            @{shift,} ];
    [ $attrs, \@data ];
}

sub sheets ($file) {
    my ($summary, @data) = @{ ReadData $file };
    # sheet maps
    # columns are [$attrs,[@entries]]

    my %sheets = map { $$_{label}, columns $$_{cell} } @data;

    # remove empty sheets
    map {
        delete $sheets{$_} unless
            grep {defined and @$_} @{ $sheets{$_} }
    } keys %sheets;

    \%sheets;
};



sub sheets_as_rt_provision ($sheets) {

    my %config = map
        { $_ => [entries_for $_, $sheets] }
        qw( Queues );


    # add members to the groups reading the 'membership' sheet
    $config{Groups} = do {

        my $G = +{ map { $$_{Name} => $_ } entries_for Groups => $sheets };

        map { push
            @{ $G
                -> { $$_{Group} } 
                -> {Members}
                -> {$$_{Type}} ||= [] }
            , $$_{Member}
        } entries_for membership => $sheets;

        [ values %$G ]

    };

    #add possible values to CustomFields reading the 'CustomFields' sheet
    $config{CustomFields} = do {
        my $V= {};
        map { push @{ $$V{ delete $$_{CustomField} } ||= [] }
            , $_ }
            entries_for values => $sheets;
        [ map {
            if (my $v = delete $$V{$$_{Name}} ) { $$_{Values} = $v }
            $_
        } entries_for CustomFields => $sheets ]
    };

    \%config;
};

sub rt_provision { sheets_as_rt_provision sheets @_ }


1;
