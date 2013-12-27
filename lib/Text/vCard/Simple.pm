package Text::vCard::Simple;

use Moo;
use Text::vCard;
use Path::Class;

=head1 SYNOPSIS

    use vCard;

    # create the object
    my $vcard = vCard->new;

    # if you want to parse vcard data from a file see L<vCard::AddressBook>

    # there are 3 ways to load vcard data in one fell swoop 
    # (see method documentation for details)
    $vcard->load_file($filename); 
    $vcard->load_string($string); 
    $vcard->load_hashref($hashref); 

    # there are 3 ways to output data in vcard format
    my $file   = $vcard->as_file($filename); # writes to $filename
    my $string = $vcard->as_string;          # returns a string
    print "$vcard";                          # overloaded as a string

    # simple getters/setters
    $vcard->fullname('Bruce Banner, PhD');
    $vcard->first_name('Bruce');
    $vcard->family_name('Banner');
    $vcard->title('Research Scientist');
    $vcard->photo('http://example.com/bbanner.gif');

    # phones setter example
    $vcard->phones({
        work => { number => '651-290-1234', preferred => 1 },
        cell => { number => '651-290-1111' }
    });

    # phones getter example
    if (my $work_phone = $vcard->phones->work) {
        $work_phone->number();
    }
    $vcard->phones->work->number();
    $vcard->phones->work->preferred();

    # addresses setter example
    $vcard->addresses({
        work => { street => 'Main St' },
        home => { street => 'Army St' },
    });

    # addresses getter example
    $vcard->addresses->work->po_box();
    $vcard->addresses->work->extended();
    $vcard->addresses->work->street();
    $vcard->addresses->work->city();
    $vcard->addresses->work->region();
    $vcard->addresses->work->post_code();
    $vcard->addresses->work->country();
    $vcard->addresses->work->preferred();

    # email setter example
    $vcard->email({
        work => { address => 'bbanner@ssh.secret.army.mil' },
        home => { address => 'bbanner@timewarner.com'      },
    });

    # email getter examples
    $vcard->email->work->address();
    $vcard->email->home->address();
    $vcard->email->home->preferred();


=head1 DESCRIPTION

A vCard is a digital business card.  vCard and vCard::AddressBook provide an
API for parsing, editing, and creating vCards.

This module is built on top of Text::vCard.  It provides a more intuitive user
interface.  

To handle an address book with several vCard entries in it, start with
L<vCard::AddressBook> and then come back to this module.

=head1 METHODS

=cut

has _data => ( is => 'rw' );

=head2 load_hashref($hashref)

$hashref looks like this:

    fullname   => 'Bruce Banner, PhD',
    first_name  => 'Bruce',
    family_name => 'Banner', # required
    title       => 'Research Scientist',
    photo       => 'http://example.com/bbanner.gif',
    phones      => {
        {   type      => 'work',
            number    => '651-290-1234',
            preferred => 1,
        },
        {   type   => 'cell',
            number => '651-290-1111'
        },
    },
    addresses => {
        work => {  },
        home => {  },
    },
    email_addresses => {
        work => { address => 'bbanner@shh.secret.army.mil', preferred => 1 },
        home => { address => 'bbanner@timewarner.com' },
    },

Returns $self in case you feel like chaining.

=cut

sub load_hashref {
    my ( $self, $hashref ) = @_;
    $self->_data($hashref);
    return $self;
}

=head2 as_string()

Returns the vCard as a string.

=cut

sub as_string {
    my ($self) = @_;
    my $vcard = Text::vCard->new;

    my $phones          = $self->_data->{phones};
    my $addresses       = $self->_data->{addresses};
    my $email_addresses = $self->_data->{email_addresses};

    $self->_build_simple_nodes( $vcard, $self->_data );
    $self->_build_phone_nodes( $vcard, $phones ) if $phones;
    $self->_build_address_nodes( $vcard, $addresses ) if $addresses;
    $self->_build_email_address_nodes( $vcard, $email_addresses )
        if $email_addresses;

    return $vcard->as_string;
}

sub _build_simple_nodes {
    my ( $self, $vcard, $data ) = @_;

    my @simple_node_types = qw/fullname title photo birthday timezone/;

    foreach my $node_type (@simple_node_types) {
        next unless $data->{$node_type};
        $vcard->$node_type( $data->{$node_type} );
    }
}

sub _build_phone_nodes {
    my ( $self, $vcard, $phones ) = @_;

    foreach my $phone (@$phones) {

        # TODO: better error handling
        die "'number' attr missing from 'phones'" unless $phone->{number};

        my $type      = $phone->{type};
        my $preferred = $phone->{preferred};
        my $number    = $phone->{number};

        my $params = [];
        push @$params, { type => $type }      if $type;
        push @$params, { pref => $preferred } if $preferred;

        $vcard->add_node(
            {   node_type => 'TEL',
                data      => [ { params => $params, value => $number } ],
            }
        );
    }
}

sub _build_address_nodes {
    my ( $self, $vcard, $addresses ) = @_;

    foreach my $address (@$addresses) {

        my $type      = $address->{type};
        my $preferred = $address->{preferred};

        my $params = [];
        push @$params, { type => $type }      if $type;
        push @$params, { pref => $preferred } if $preferred;

        my $value = join ';',
            $address->{pobox}     || '',
            $address->{extended}  || '',
            $address->{street}    || '',
            $address->{city}      || '',
            $address->{region}    || '',
            $address->{post_code} || '',
            $address->{country}   || '';

        $vcard->add_node(
            {   node_type => 'ADR',
                data      => [ { params => $params, value => $value } ],
            }
        );
    }
}

sub _build_email_address_nodes {
    my ( $self, $vcard, $email_addresses ) = @_;

    foreach my $email_address (@$email_addresses) {

        # TODO: better error handling
        die "'address' attr missing from 'email_addresses'"
            unless $email_address->{address};

        my $type      = $email_address->{type};
        my $preferred = $email_address->{preferred};

        my $params = [];
        push @$params, { type => $type }      if $type;
        push @$params, { pref => $preferred } if $preferred;

        # TODO: better error handling
        my $value = $email_address->{address};

        $vcard->add_node(
            {   node_type => 'EMAIL',
                data      => [ { params => $params, value => $value } ],
            }
        );
    }
}

=head2 as_file($filename)

Write data in vCard format to $filename.

Returns a Path::Class::File if successful.  Dies if not successful.

=cut

sub as_file {
    my ( $self, $filename ) = @_;

    my $file = ref $filename eq 'Path::Class::File'    #
        ? $filename
        : file($filename);

    $file->spew( $self->as_string );

    return $file;
}

1;
