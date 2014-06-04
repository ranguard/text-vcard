# NAME

Text::vCard - a package to edit and create a single vCard (RFC 2426)

# WARNING

[vCard](https://metacpan.org/pod/vCard) and [vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook) are built on top of this module and provide
a more intuitive user interface.  Please try those modules first.

# SYNOPSIS

    use Text::vCard;
    my $cards
        = Text::vCard->new( { 'asData_node' => $objects_node_from_asData, } );

# DESCRIPTION

A vCard is an electronic business card. 

This package is for a single vCard (person / record / set of address
information). It provides an API to editing and creating vCards, or supplied
a specific piece of the Text::vFile::asData results it generates a vCard 
with that content.

You should really use [Text::vCard::Addressbook](https://metacpan.org/pod/Text::vCard::Addressbook) as this handles creating
vCards from an existing file for you.

# METHODS

## new()

    use Text::vCard;

    my $new_vcard = Text::vCard->new();

    my $existing_vcard
        = Text::vCard->new( { 'asData_node' => $objects_node_from_asData, } );

## add\_node()

    my $address = $vcard->add_node( { 'node_type' => 'ADR', } );

This creates a new address (a [Text::vCard::Node](https://metacpan.org/pod/Text::vCard::Node) object) in the vCard
which you can then call the address methods on. See below for what options are available.

The node\_type parameter must conform to the vCard spec format (e.g. ADR not address)

## get()

The following method allows you to extract the contents from the vCard.

    # get all elements
    $nodes = $vcard->get('tel');

    # Just get the home address
    my $nodes = $vcard->get(
        {   'node_type' => 'addresses',
            'types'     => 'home',
        }
    );

    # get all phone number that matches serveral types
    my @types = qw(work home);
    my $nodes = $vcard->get(
        {   'node_type' => 'tel',
            'types'     => \@types,
        }
    );



Either an array or array ref is returned, containing
[Text::vCard::Node](https://metacpan.org/pod/Text::vCard::Node) objects.  If there are no results of 'node\_type'
undef is returned.

Supplied with a scalar or an array ref the methods
return a list of nodes of a type, where relevant. If any
of the elements is the prefered element it will be
returned as the first element of the list.

## get\_simple\_type()

The following method is a convenience wrapper for accessing simple elements.

    $value = $vcard->get_simple_type( 'email', [ 'internet', 'work' ] );

If multiple elements match, then only the first is returned.  If the object
isn't found, or doesn't have a simple value, then undef is returned.
 

The argument type may be ommitted, it can be a scalar, or it can be an
array reference if multiple types are selected.

## nodes

    my $addresses = $vcard->get( { 'node_type' => 'address' } );

    my $first_address = $addresses->[0];

    # get the value
    print $first_address->street();

    # set the value
    $first_address->street('Barney Rubble');

    # See if it is part of a group
    if ( $first_address->group() ) {
        print 'Group: ' . $first_address->group();
    }

According to the RFC the following 'simple' nodes should only have one
element, this is not enforced by this module, so for example you can
have multiple URL's if you wish.

## simple nodes

For simple nodes, you can also access the first node in the following way:

    my $fn = $vcard->fullname();
    # or setting
    $vcard->fullname('new name');

The node will be automatically created if it does not exist and you
supplied a value.  undef is returned if the node does not
exist. Simple nodes can be called as all upper or all lowercase method
names.

    vCard Spec: 'simple'    Alias
    --------------------    --------
    FN                      fullname
    BDAY                    birthday
    MAILER
    TZ                      timezone
    TITLE 
    ROLE 
    NOTE 
    PRODID 
    REV 
    SORT-STRING 
    UID
    URL 
    CLASS
    EMAIL
    NICKNAME
    PHOTO
    version (lowercase only)
    

## more complex vCard nodes

    vCard Spec    Alias           Methods on object
    ----------    ----------      -----------------
    N             name (depreciated as conflicts with rfc, use moniker)
    N             moniker            'family','given','middle','prefixes','suffixes'
    ADR           addresses       'po_box','extended','street','city','region','post_code','country'
    GEO                           'lat','long'
    TEL           phones
    LABELS
    ORG                           'name','unit' (unit is a special case and will return an array reference)

    my $addresses = $vcard->get( { 'node_type' => 'addresses' } );
    foreach my $address ( @{$addresses} ) {
        print $address->street();
    }

    # Setting values on an address element
    $addresses->[0]->street('The burrows');
    $addresses->[0]->region('Wimbeldon common');

    # Checking an address is a specific type
    $addresses->[0]->is_type('fax');
    $addresses->[0]->add_types('home');
    $addresses->[0]->remove_types('work');

## get\_group()

    my $group_name = 'item1';
    my $node_type  = 'X-ABLABEL';
    my $of_group   = $vcard->get_group( $group_name, $node_type );
    foreach my $label ( @{$of_group} ) {
        print $label->value();
    }

This method takes one or two arguments. The group name
(accessable on any node object by using $node->group() - not
all nodes will have a group, indeed most vcards do not seem
to use it) and optionally the types of node you with to 
have returned.

Either an array or array reference is returned depending
on the calling context, if there are no matches it will
be empty.

# BINARY METHODS

These methods allow access to what are potentially binary values such
as a photo or sound file. Binary values will be correctly encoded and
decoded to/from base 64.

API still to be finalised.

## photo()

## sound()

## key()

## logo()

## get\_lookup

This method is used internally to lookup those nodes which have
multiple elements, e.g. GEO has lat and long, N (name) has family,
given, middle etc.

If you wish to extend this package (for custom attributes), overload
this method in your code:

    sub my_lookup {
        return \%my_lookup;
    }
    *Text::vCard::get_lookup = \&my_lookup;

This has not been tested yet.

## get\_of\_type()

    my $list = $vcard->get_of_type( $node_type, \@types );

It is probably easier just to use the get() method, which inturn calls
this method.

## as\_string

Returns the vCard as a string.

# AUTHOR

Leo Lapworth, LLAP@cuckoo.org
Eric Johnson (kablamo), github ~!at!~ iijo dot org

# Repository (git)

http://github.com/ranguard/text-vcard, git://github.com/ranguard/text-vcard.git

# COPYRIGHT

Copyright (c) 2005-2010 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

# SEE ALSO

[Text::vCard::Addressbook](https://metacpan.org/pod/Text::vCard::Addressbook), [Text::vCard::Node](https://metacpan.org/pod/Text::vCard::Node),
[vCard](https://metacpan.org/pod/vCard) [vCard](https://metacpan.org/pod/vCard), [vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook) [vCard::AddressBook](https://metacpan.org/pod/vCard::AddressBook),
