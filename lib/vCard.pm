package vCard;
use Moo;

use Path::Class;
use Text::vCard;
use vCard::AddressBook;

=head1 NAME

vCard - read, write, and edit a single vCard

=head1 SYNOPSIS

    use vCard;

    # create the object
    my $vcard = vCard->new;

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

    # complex getters/setters
    $vcard->phones({
        { type => ['work', 'text'], number => '651-290-1234', preferred => 1 },
        { type => ['home'],         number => '651-290-1111' }
    });
    $vcard->addresses({
        { type => ['work'], street => 'Main St' },
        { type => ['home'], street => 'Army St' },
    });
    $vcard->email_addresses({
        { type => ['work'], address => 'bbanner@ssh.secret.army.mil' },
        { type => ['home'], address => 'bbanner@timewarner.com'      },
    });


=head1 DESCRIPTION

A vCard is a digital business card.  vCard and L<vCard::AddressBook> provide an
API for parsing, editing, and creating vCards.

This module is built on top of L<Text::vCard>.  It provides a more intuitive user
interface.  

To handle an address book with several vCard entries in it, start with
L<vCard::AddressBook> and then come back to this module.


=head1 ENCODING AND UTF-8

See the 'ENCODING AND UTF-8' section of L<vCard::AddressBook>.


=head1 METHODS

=cut

has encoding_in  => ( is => 'rw', default => sub {'UTF-8'} );
has encoding_out => ( is => 'rw', default => sub {'UTF-8'} );
has _data        => ( is => 'rw', default => sub { {} } );

=head2 load_hashref($hashref)

$hashref looks like this:

    fullname    => 'Bruce Banner, PhD',
    '<:encoding(' . first_name  => 'Bruce',
    family_name => 'Banner',
    title       => 'Research Scientist',
    photo       => 'http://example.com/bbanner.gif',
    phones      => [
        { type => ['work'], number => '651-290-1234', preferred => 1 },
        { type => ['cell'], number => '651-290-1111' },
    },
    addresses => [
        { type => ['work'], ... },
        { type => ['home'], ... },
    ],
    email_addresses => [
        { type => ['work'], address => 'bbanner@shh.secret.army.mil' },
        { type => ['home'], address => 'bbanner@timewarner.com' },
    ],

Returns $self in case you feel like chaining.

=cut

sub load_hashref {
    my ( $self, $hashref ) = @_;
    $self->_data($hashref);
    return $self;
}

=head2 load_file($filename)

Returns $self in case you feel like chaining.

=cut

sub load_file {
    my ( $self, $filename ) = @_;
    return vCard::AddressBook    #
        ->new(
        {   encoding_in  => $self->encoding_in,
            encoding_out => $self->encoding_out,
        }
        )                         #
        ->load_file($filename)    #
        ->vcards->[0];
}

=head2 load_string($string)

Returns $self in case you feel like chaining.  This method assumes $string is
decoded (but not MIME decoded).

=cut

sub load_string {
    my ( $self, $string ) = @_;
    return vCard::AddressBook    #
        ->new(
        {   encoding_in  => $self->encoding_in,
            encoding_out => $self->encoding_out,
        }
        )->load_string($string)    #
        ->vcards->[0];
}

=head2 as_string()

Returns the vCard as a string.

=cut

sub as_string {
    my ($self) = @_;
    my $vcard = Text::vCard->new( { encoding_out => $self->encoding_out } );

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

sub _simple_node_types {
    qw/fullname title photo birthday timezone/;
}

sub _build_simple_nodes {
    my ( $self, $vcard, $data ) = @_;

    foreach my $node_type ( $self->_simple_node_types ) {
        next unless $data->{$node_type};
        $vcard->$node_type( $data->{$node_type} );
    }
}

sub _build_phone_nodes {
    my ( $self, $vcard, $phones ) = @_;

    foreach my $phone (@$phones) {

        # TODO: better error handling
        die "'number' attr missing from 'phones'" unless $phone->{number};
        die "'type' attr in 'phones' should be an arrayref"
            if ( $phone->{type} && ref( $phone->{type} ) ne 'ARRAY' );

        my $type      = $phone->{type} || [];
        my $preferred = $phone->{preferred};
        my $number    = $phone->{number};

        my $params = [];
        push @$params, { type => $_ } foreach @$type;
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

        die "'type' attr in 'addresses' should be an arrayref"
            if ( $address->{type} && ref( $address->{type} ) ne 'ARRAY' );

        my $type = $address->{type} || [];
        my $preferred = $address->{preferred};

        my $params = [];
        push @$params, { type => $_ } foreach @$type;
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
        die "'type' attr in 'email_addresses' should be an arrayref"
            if ( $email_address->{type}
            && ref( $email_address->{type} ) ne 'ARRAY' );

        my $type = $email_address->{type} || [];
        my $preferred = $email_address->{preferred};

        my $params = [];
        push @$params, { type => $_ } foreach @$type;
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

Returns a L<Path::Class::File> object if successful.  Dies if not successful.

=cut

sub as_file {
    my ( $self, $filename ) = @_;

    my $file = ref $filename eq 'Path::Class::File'    #
        ? $filename
        : file($filename);

    my @iomode = $self->encoding_in eq 'none'          #
        ? ()
        : ( iomode => '<:encoding(' . $self->encoding_out . ')' );

    $file->spew( @iomode, $self->as_string, );

    return $file;
}

=head1 SIMPLE GETTERS/SETTERS

These methods accept and return strings.  

The vCard RFC requires version, fullname.  This module does not check or warn
if this condition has not been met.

Note that fullname() is an entire name as the person would like to see it
displayed.  

=head2 version()

=head2 fullname()

=head2 title()

=head2 photo()

=head2 birthday()

=head2 timezone()


=head1 COMPLEX GETTERS/SETTERS

These methods accept and return hashrefs.  Each method accepts 'type' (an
arrayref) and 'preferred' (a boolean).  See the example below.

=head2 phones()

Accepts a hashref that looks like:

  {
    { type => ['work'], number => '651-290-1234', preferred => 1 },
    { type => ['cell'], number => '651-290-1111' },
  }

=head2 addresses()

Accepts a hashref that looks like:

  {
    { type => ['work'], street => 'Main St' },
    { type => ['home'], street => 'Army St' },
  }

=head2 email_addresses()

Accepts a hashref that looks like:

  {
    { type => ['work'], address => 'bbanner@ssh.secret.army.mil' },
    { type => ['home'], address => 'bbanner@timewarner.com'      },
  }

=cut

sub fullname        { shift->setget( 'fullname',        @_ ) }
sub title           { shift->setget( 'title',           @_ ) }
sub photo           { shift->setget( 'photo',           @_ ) }
sub birthday        { shift->setget( 'birthday',        @_ ) }
sub timezone        { shift->setget( 'timezone',        @_ ) }
sub phones          { shift->setget( 'phones',          @_ ) }
sub addresses       { shift->setget( 'addresses',       @_ ) }
sub email_addresses { shift->setget( 'email_addresses', @_ ) }

sub setget {
    my ( $self, $attr, $value ) = @_;
    $self->_data->{$attr} = $value if $value;
    return $self->_data->{$attr};
}

=head1 AUTHOR

Eric Johnson (kablamo), github ~!at!~ iijo dot org

=head1 ACKNOWLEDGEMENTS

Thanks to L<Foxtons|http://foxtons.co.uk> for making this module possible by
donating a significant amount of developer time.

=cut

1;
