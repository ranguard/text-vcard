package vCard;

use Moo;

use Path::Tiny;
use Text::vCard;
use vCard::AddressBook;
use URI;

=head1 NAME

vCard - read, write, and edit a single vCard

=head1 SYNOPSIS

    use vCard;

    # create the object
    my $vcard = vCard->new;

    # these methods load vCard data
    # (see method documentation for details)
    $vcard->load_file($filename); 
    $vcard->load_string($string); 
    $vcard->load_hashref($hashref); 

    # simple getters/setters
    $vcard->full_name('Bruce Banner, PhD');
    $vcard->title('Research Scientist');
    $vcard->photo('http://example.com/bbanner.gif');

    # complex getters/setters
    $vcard->phones({
        { type => ['work', 'text'], number => '651-290-1234', preferred => 1 },
        { type => ['home'],         number => '651-290-1111' }
    });
    $vcard->email_addresses({
        { type => ['work'], address => 'bbanner@ssh.secret.army.mil' },
        { type => ['home'], address => 'bbanner@timewarner.com'      },
    });

    # these methods output data in vCard format
    my $file   = $vcard->as_file($filename); # writes to $filename
    my $string = $vcard->as_string;          # returns a string


=head1 DESCRIPTION

A vCard is a digital business card.  vCard and L<vCard::AddressBook> provide an
API for parsing, editing, and creating vCards.

This module is built on top of L<Text::vCard>.  It provides a more intuitive user
interface.  

To handle an address book with several vCard entries in it, start with
L<vCard::AddressBook> and then come back to this module.

Note that the vCard RFC requires version() and full_name().  This module does
not check or warn if these conditions have not been met.


=head1 ENCODING AND UTF-8

See the 'ENCODING AND UTF-8' section of L<vCard::AddressBook>.


=head1 METHODS

=cut

has encoding_in  => ( is => 'rw', default => sub {'UTF-8'} );
has encoding_out => ( is => 'rw', default => sub {'UTF-8'} );
has _data        => ( is => 'rw', default => sub { { version => '4.0' } } );

with 'vCard::Role::FileIO';

=head2 load_hashref($hashref)

$hashref should look like this:

    full_name    => 'Bruce Banner, PhD',
    given_names  => ['Bruce'],
    family_names => ['Banner'],
    title        => 'Research Scientist',
    photo        => 'http://example.com/bbanner.gif',
    phones       => [
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

    $self->_data->{version} = '4.0'
        unless $self->_data->{version};

    $self->_data->{photo} = URI->new( $self->_data->{photo} )
        unless ref $self->_data->{photo} =~ /^URI/;

    return $self;
}

=head2 load_file($filename)

Returns $self in case you feel like chaining.

=cut

sub load_file {
    my ( $self, $filename ) = @_;

    my $addressBook = vCard::AddressBook->new({
        encoding_in  => $self->encoding_in,
        encoding_out => $self->encoding_out,
    });
    my $vcard = $addressBook->load_file($filename)->vcards->[0];

    $self->_data($vcard->_data);

    return $self;
}

=head2 load_string($string)

Returns $self in case you feel like chaining.  This method assumes $string is
decoded (but not MIME decoded).

=cut

sub load_string {
    my ( $self, $string ) = @_;

    my $addressBook = vCard::AddressBook->new({
        encoding_in  => $self->encoding_in,
        encoding_out => $self->encoding_out,
    });
    my $vcard = $addressBook->load_string($string)->vcards->[0];

    $self->_data($vcard->_data);

    return $self;
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
    $self->_build_name_node( $vcard, $self->_data );
    $self->_build_phone_nodes( $vcard, $phones ) if $phones;
    $self->_build_address_nodes( $vcard, $addresses ) if $addresses;
    $self->_build_email_address_nodes( $vcard, $email_addresses )
        if $email_addresses;

    return $vcard->as_string;
}

sub _simple_node_types {
    qw/full_name title photo birthday timezone version/;
}

sub _build_simple_nodes {
    my ( $self, $vcard, $data ) = @_;

    foreach my $node_type ( $self->_simple_node_types ) {
        if ( $node_type eq 'full_name' ) {
            next unless $data->{full_name};
            $vcard->fullname( $data->{full_name} );
        } else {
            next unless $data->{$node_type};
            $vcard->$node_type( $data->{$node_type} );
        }
    }
}

sub _build_name_node {
    my ( $self, $vcard, $data ) = @_;

    my $value = join ',', @{ $data->{family_names} || [] };
    $value .= ';' . join ',', @{ $data->{given_names}        || [] };
    $value .= ';' . join ',', @{ $data->{other_names}        || [] };
    $value .= ';' . join ',', @{ $data->{honorific_prefixes} || [] };
    $value .= ';' . join ',', @{ $data->{honorific_suffixes} || [] };

    $vcard->add_node( { node_type => 'N', data => [ { value => $value } ] } )
        if $value ne ';;;;';
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

Dies if not successful.

=cut

sub as_file {
    my ( $self, $filename ) = @_;
    my $file = $self->_path($filename);
    $file->spew( $self->_iomode_out, $self->as_string );
    return $file;
}

=head1 SIMPLE GETTERS/SETTERS

These methods accept and return strings.  

=head2 version()

Version number of the vcard.  Defaults to '4.0'

=head2 full_name()

A person's entire name as they would like to see it displayed.  

=head2 title()

A person's position or job.

=head2 photo()

This should be a link. Accepts a string or a URI object.  This method
always returns a L<URI> object. 

TODO: handle binary images using the data uri schema

=head2 birthday()

=head2 timezone()


=head1 COMPLEX GETTERS/SETTERS

These methods accept and return array references rather than simple strings.

=head2 family_names()

Accepts/returns an arrayref of family names (aka surnames).

=head2 given_names()

Accepts/returns an arrayref.

=head2 other_names()

Accepts/returns an arrayref of names which don't qualify as family_names or
given_names.

=head2 honorific_prefixes()

Accepts/returns an arrayref.  eg C<[ 'Dr.' ]>

=head2 honorific_suffixes()

Accepts/returns an arrayref.  eg C<[ 'Jr.', 'MD' ]>

=head2 phones()

Accepts/returns an arrayref that looks like:

  [
    { type => ['work'], number => '651-290-1234', preferred => 1 },
    { type => ['cell'], number => '651-290-1111' },
  ]

=head2 addresses()

Accepts/returns an arrayref that looks like:

  [
    { type => ['work'], street => 'Main St', preferred => 0 },
    { type      => ['home'], 
      pobox     => 1234,
      extended  => 'asdf',
      street    => 'Army St',
      city      => 'Desert Base',
      region    => '',
      post_code => '',
      country   => 'USA',
      preferred => 1,
    },
  ]

=head2 email_addresses()

Accepts/returns an arrayref that looks like:

  [
    { type => ['work'], address => 'bbanner@ssh.secret.army.mil' },
    { type => ['home'], address => 'bbanner@timewarner.com', preferred => 1 },
  ]

=cut

sub version            { shift->_setget( 'version',            @_ ) }
sub full_name          { shift->_setget( 'full_name',          @_ ) }
sub family_names       { shift->_setget( 'family_names',       @_ ) }
sub given_names        { shift->_setget( 'given_names',        @_ ) }
sub other_names        { shift->_setget( 'other_names',        @_ ) }
sub honorific_prefixes { shift->_setget( 'honorific_prefixes', @_ ) }
sub honorific_suffixes { shift->_setget( 'honorific_suffixes', @_ ) }
sub title              { shift->_setget( 'title',              @_ ) }
sub photo              { shift->_setget( 'photo',              @_ ) }
sub birthday           { shift->_setget( 'birthday',           @_ ) }
sub timezone           { shift->_setget( 'timezone',           @_ ) }
sub phones             { shift->_setget( 'phones',             @_ ) }
sub addresses          { shift->_setget( 'addresses',          @_ ) }
sub email_addresses    { shift->_setget( 'email_addresses',    @_ ) }

sub _setget {
    my ( $self, $attr, $value ) = @_;

    $value = URI->new($value)
        if $value && $attr eq 'photo' && ref $value =~ /^URI/;

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
