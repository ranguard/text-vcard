# NAME

vCard - Read, write, and edit vCards

# SYNOPSIS

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

# DESCRIPTION

A vCard is a digital business card.  vCard and [vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook) provide an
API for parsing, editing, and creating vCards.

This module is built on top of [Text::vCard](https://metacpan.org/pod/Text::vCard).  It provides a more intuitive user
interface.  

To handle an address book with several vCard entries in it, start with
[vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook) and then come back to this module.

Note that the vCard RFC requires version() and full\_name().  This module does
not check or warn if these conditions have not been met.

# ENCODING AND UTF-8

See the 'ENCODING AND UTF-8' section of [vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook).

# METHODS

## load\_hashref($hashref)

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

## load\_file($filename)

Returns $self in case you feel like chaining.

## load\_string($string)

Returns $self in case you feel like chaining.  This method assumes $string is
decoded (but not MIME decoded).

## as\_string()

Returns the vCard as a string.

## as\_file($filename)

Write data in vCard format to $filename.

Dies if not successful.

# SIMPLE GETTERS/SETTERS

These methods accept and return strings.  

## version()

Version number of the vcard.  Defaults to '4.0'

## full\_name()

A person's entire name as they would like to see it displayed.  

## title()

A person's position or job.

## photo()

This should be a link. Accepts a string or a URI object.  This method
always returns a [URI](https://metacpan.org/pod/URI) object. 

TODO: handle binary images using the data uri schema

## birthday()

## timezone()

# COMPLEX GETTERS/SETTERS

These methods accept and return array references rather than simple strings.

## family\_names()

Accepts/returns an arrayref of family names (aka surnames).

## given\_names()

Accepts/returns an arrayref.

## other\_names()

Accepts/returns an arrayref of names which don't qualify as family\_names or
given\_names.

## honorific\_prefixes()

Accepts/returns an arrayref.  eg `[ 'Dr.' ]`

## honorific\_suffixes()

Accepts/returns an arrayref.  eg `[ 'Jr.', 'MD' ]`

## phones()

Accepts/returns an arrayref that looks like:

    [
      { type => ['work'], number => '651-290-1234', preferred => 1 },
      { type => ['cell'], number => '651-290-1111' },
    ]

## addresses()

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

## email\_addresses()

Accepts/returns an arrayref that looks like:

    [
      { type => ['work'], address => 'bbanner@ssh.secret.army.mil' },
      { type => ['home'], address => 'bbanner@timewarner.com', preferred => 1 },
    ]

# AUTHOR

Eric Johnson (kablamo), github ~!at!~ iijo dot org

# ACKNOWLEDGEMENTS

Thanks to [Foxtons](http://foxtons.co.uk) for making this module possible by
donating a significant amount of developer time.
