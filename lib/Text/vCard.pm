package Text::vCard;

use 5.006;
use Carp;
use strict;
use warnings;
use File::Slurp;
use Text::vFile::asData;
use Text::vCard::Node;

# See this module for your basic parser functions
use base qw(Text::vFile::asData);
use vars qw ($VERSION %lookup %node_aliases @simple);
$VERSION = '2.11';

# If the node's data does not break down use this
my @default_field = qw(value);

# If it does use these
%lookup = (
    'ADR' => [
        'po_box', 'extended',  'street', 'city',
        'region', 'post_code', 'country'
    ],
    'N'   => [ 'family', 'given', 'middle', 'prefixes', 'suffixes' ],
    'GEO' => [ 'lat',    'long' ],
    'ORG' => [ 'name',   'unit' ],
);

%node_aliases = (
    'FULLNAME'  => 'FN',
    'BIRTHDAY'  => 'BDAY',
    'TIMEZONE'  => 'TZ',
    'PHONES'    => 'TEL',
    'ADDRESSES' => 'ADR',
    'NAME'      => 'N',      # To be deprecated as clashes with RFC
    'MONIKER'   => 'N',
);

# Generate all our simple methods
@simple
    = qw(FN BDAY MAILER TZ TITLE ROLE NOTE PRODID REV SORT-STRING UID URL CLASS FULLNAME BIRTHDAY TZ NAME EMAIL NICKNAME PHOTO);

# Now we want lowercase as well
map { push( @simple, lc($_) ) } @simple;

# Generate the methods
{
    no strict 'refs';
    no warnings 'redefine';

    # 'version' handled separately
    # to prevent conflict with ExtUtils::MakeMaker
    # and $VERSION
    for my $node ( @simple, "version" ) {
        *$node = sub {
            my ( $self, $value ) = @_;

            # See if we have it already
            my $nodes = $self->get($node);
            if ( !defined $nodes && $value ) {

                # Add it as a node if not exists and there is a value
                $self->add_node( { 'node_type' => $node, } );

                # Get it out again
                $nodes = $self->get($node);
            }

            if ( scalar($nodes) && $value ) {

                # Set it
                $nodes->[0]->value($value);
            }

            return $nodes->[0]->value() if scalar($nodes);
            return undef;
            }
    }
}

=head1 NAME

Text::vCard - a package to edit and create a single vCard (RFC 2426) 

=head1 WARNING

To handle a whole addressbook with several vCard entries in it, you probably
want to start with L<Text::vCard::Addressbook>, then this module.

This is not backwards compatable with 1.0 or earlier versions! 

Version 1.1 was a complete rewrite/restructure, this should not happen again.

=head1 SYNOPSIS

  use Text::vCard;
  my $cards = Text::vCard->new({
	'asData_node' => $objects_node_from_asData,
  });

=head1 DESCRIPTION

A vCard is an electronic business card. 

This package is for a single vCard (person / record / set of address information).
It provides an API to editing and creating vCards, or supplied a specific piece
of the Text::vFile::asData results it generates a vCard with that content.

You should really use L<Text::vCard::Addressbook> as this handles creating
vCards from an existing file for you.

=head1 METHODS

=head2 new()

  use Text::vCard;

  my $new_vcard = Text::vCard->new();
  
  my $existing_vcard = Text::vCard->new({
	'asData_node' => $objects_node_from_asData,
  });
  
=cut

sub new {
    my ( $proto, $conf ) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless( $self, $class );

    my %nodes;
    $self->{nodes} = \%nodes;

    if ( defined $conf->{'asData_node'} ) {

        # Have a vcard data node being passed in
        while ( my ( $node_type, $data ) = each %{ $conf->{'asData_node'} } )
        {
            my $group;
            if ( $node_type =~ /\./ ) {

                # Version 3.0 supports group types, we do not
                # so remove everything before '.'
                ( $group, $node_type ) = $node_type =~ /(.+)\.(.*)/;
            }

            # Deal with each type (ADR, FN, TEL etc)
            $self->_add_node(
                {   'node_type' => $node_type,
                    'data'      => $data,
                    'group'     => $group,
                }
            );
        }
    }    # else we're creating a new vCard

    return $self;
}

=head2 add_node()

my $address = $vcard->add_node({
	'node_type' => 'ADR',
});

This creates a new address (a L<Text::vCard::Node> object) in the vCard
which you can then call the address methods on. See below for what options are available.

The node_type parameter must conform to the vCard spec format (e.g. ADR not address)

=cut

sub add_node {
    my ( $self, $conf ) = @_;
    croak 'Must supply a node_type'
        unless defined $conf && defined $conf->{'node_type'};
    unless ( defined $conf->{data} ) {
        my %empty;
        my @data = ( \%empty );
        $conf->{'data'} = \@data;
    }

    $self->_add_node($conf);
}

=head2 get()

The following method allows you to extract the contents from the vCard.

  # get all elements
  $nodes = $vcard->get('tel');

  # Just get the home address
  my $nodes = $vcard->get({
	'node_type' => 'addresses',
	'types' => 'home',
  });
  
  # get all phone number that matches serveral types
  my @types = qw(work home);
  my $nodes = $vcard->get({
	'node_type' => 'tel',
	'types' => \@types,
  });
 
Either an array or array ref is returned, containing L<Text::vCard::Node> objects.
If there are no results of 'node_type' undef is returned.

Supplied with a scalar or an array ref the methods
return a list of nodes of a type, where relevant. If any
of the elements is the prefered element it will be
returned as the first element of the list.

=cut

sub get {
    my ( $self, $conf ) = @_;
    carp "You did not supply an element type" unless defined $conf;
    if ( ref($conf) eq 'HASH' ) {
        return $self->get_of_type( $conf->{'node_type'}, $conf->{'types'} )
            if defined $conf->{'types'};
        return $self->get_of_type( $conf->{'node_type'} );
    } else {
        return $self->get_of_type($conf);
    }
}

=head2 get_simple_type()

The following method is a convenience wrapper for accessing simple elements.

  $value = $vcard->get_simple_type('email', ['internet', 'work']);

If multiple elements match, then only the first is returned.  If the object
isn't found, or doesn't have a simple value, then undef is returned.
 
The argument type may be ommitted, it can be a scalar, or it can be an
array reference if multiple types are selected.

=cut

sub get_simple_type {
    my ( $self, $node_type, $types ) = @_;
    carp "You did not supply an element type" unless defined $node_type;

    my %hash = ('node_type', $node_type);
    $hash{'types'} = $types if defined $types;
    my $node = $self->get(\%hash);
    return undef unless $node && @{$node} > 0 && exists $node->[0]->{'value'};

    $node->[0]->{'value'};
}

=head2 nodes

  my $addresses = $vcard->get({ 'node_type' => 'address' });

  my $first_address = $addresses->[0];
  
  # get the value
  print $first_address->street();

  # set the value
  $first_address->street('Barney Rubble');

  # See if it is part of a group
  if($first_address->group()) {
	print 'Group: ' . $first_address->group();
  }
  
According to the RFC the following 'simple' nodes should only have one element, this is
not enforced by this module, so for example you can have multiple URL's if you wish.

=head2 simple nodes

For simple nodes, you can also access the first node in the following way:

  my $fn = $vcard->fullname();
  # or setting
  $vcard->fullname('new name');

The node will be automatically created if it does not exist and you supplied a value.
undef is returned if the node does not exist. Simple nodes can be called as all upper
or all lowercase method names.

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
  
=head2 more complex vCard nodes

  vCard Spec    Alias           Methods on object
  ----------    ----------      -----------------
  N             name (depreciated as conflicts with rfc, use moniker)
  N             moniker            'family','given','middle','prefixes','suffixes'
  ADR           addresses       'po_box','extended','street','city','region','post_code','country'
  GEO                           'lat','long'
  TEL           phones
  LABELS
  ORG                           'name','unit' (unit is a special case and will return an array reference)

  my $addresses = $vcard->get({ 'node_type' => 'addresses' });
  foreach my $address (@{$addresses}) {
	print $address->street();
  }

  # Setting values on an address element
  $addresses->[0]->street('The burrows');
  $addresses->[0]->region('Wimbeldon common');

  # Checking an address is a specific type
  $addresses->[0]->is_type('fax');
  $addresses->[0]->add_types('home');
  $addresses->[0]->remove_types('work');

=head2 get_group()

  my $group_name = 'item1';
  my $node_type = 'X-ABLABEL';
  my $of_group = $vcard->get_group($group_name,$node_type);
  foreach my $label (@{$of_group}) {
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

=cut

sub get_group {
    my ( $self, $group_name, $node_type ) = @_;
    my @to_return;

    carp "No group name supplied"
        unless defined $group_name
            and $group_name ne '';

    $group_name = lc($group_name);

    if ( defined $node_type && $node_type ne '' ) {

        # After a specific node type
        my $nodes = $self->get($node_type);
        foreach my $node ( @{$nodes} ) {
            push( @to_return, $node ) if $node->group() eq $group_name;
        }
    } else {

        # We want everything from that group
        foreach my $node_loop ( keys %{ $self->{nodes} } ) {

            # Loop through each type
            my $nodes = $self->get($node_loop);
            foreach my $node ( @{$nodes} ) {
                if ( $node->group() ) {
                    push( @to_return, $node )
                        if $node->group() eq $group_name;
                }
            }
        }
    }
    return wantarray ? @to_return : \@to_return;
}

=head1 BINARY METHODS

These methods allow access to what are potentially
binary values such as a photo or sound file.

API still to be finalised.

=head2 photo()

=head2 sound()

=head2 key()

=head2 logo()

=cut

sub DESTROY {
}

=head2 get_lookup

This method is used internally to lookup those nodes which have multiple elements,
e.g. GEO has lat and long, N (name) has family, given, middle etc.

If you wish to extend this package (for custom attributes), overload this method
in your code

  sub my_lookup {
		return \%my_lookup;
  }
  *Text::vCard::get_lookup = \&my_lookup;

This has not been tested yet.

=cut 

sub get_lookup {
    my $self = shift;
    return \%lookup;
}

=head2 get_of_type()

  my $list = $vcard->get_of_type($node_type,\@types);

It is probably easier just to use the get() method, which inturn calls
this method.

=cut

# Used to get the right elements
sub get_of_type {
    my ( $self, $node_type, $types ) = @_;

    # Upper case the name
    $node_type = uc($node_type);

    # See if there is an alias for it
    $node_type = uc( $node_aliases{$node_type} )
        if defined $node_aliases{$node_type};

    return undef unless defined $self->{nodes}->{$node_type};

    if ($types) {

        # After specific types
        my @of_type;
        if ( ref($types) eq 'ARRAY' ) {
            @of_type = @{$types};

            #	print "T A: " . join('-',@{$types}) . "\n";
        } else {
            push( @of_type, $types );

            #	print "T: $types\n";
        }
        my @to_return;
        foreach my $element ( @{ $self->{nodes}->{$node_type} } ) {
            my $check = 1;    # assum ok for now
            foreach my $type (@of_type) {

                # set it as bad if we don't match
                $check = 0 unless $element->is_type($type);
            }
            if ( $check == 1 ) {

                #	print "Adding: $element->street() \n";
                push( @to_return, $element );
            }
        }

        return undef unless scalar(@to_return);

        # Make prefered value first
        @to_return = sort { _sort_prefs($b) <=> _sort_prefs($a) } @to_return;

        return wantarray ? @to_return : \@to_return;

    } else {

        # Return them all
        return wantarray
            ? @{ $self->{nodes}->{$node_type} }
            : $self->{nodes}->{$node_type};
    }
}

=head2 as_string

=cut

sub as_string {
    my ($self, $fields, $charset) = @_;
    # derp
    my %e = map { lc $_ => 1 } @{$fields || []};

    my @k = qw(VERSION N FN);
    if ($fields) {
        push @k, map { uc $_ } @$fields;
    }
    else {
        push @k, grep { defined $_ and $_ ne '' and $_ !~ /^(VERSION|N|FN)$/ }
            map { uc $_ } keys %{$self->{nodes}};
    }

    my @lines = qw(BEGIN:VCARD);
    for my $k (@k) {
        next unless $k;
        next unless my $nodes = $self->get($k);
        push @lines, map { $_->as_string($charset) } @{$nodes};
    }
    return join "\x0d\x0a", @lines, 'END:VCARD', '';
}

sub _sort_prefs {
    my $check = shift;
    if ( $check->is_type('pref') ) {
        return 1;
    } else {
        return 0;
    }
}

# Private method for adding nodes
sub _add_node {
    my ( $self, $conf ) = @_;

    my $value_fields = $self->get_lookup();

    my $node_type = uc( $conf->{node_type} );
    $node_type = $node_aliases{$node_type}
        if defined $node_aliases{$node_type};

    my $field_list;

    if ( defined $value_fields->{$node_type} ) {

        # We know what the field list is
        $field_list = $value_fields->{$node_type};
    } else {

        # No defined fields - use just the 'value' one
        $field_list = \@default_field;
    }
    unless ( defined $self->{nodes}->{$node_type} ) {

        # create space to hold list of node objects
        my @node_list_space;
        $self->{nodes}->{$node_type} = \@node_list_space;
    }
    my $last_node;
    foreach my $node_data ( @{ $conf->{data} } ) {
        my $node_obj = Text::vCard::Node->new(
            {   node_type => $node_type,
                fields    => $field_list,
                data      => $node_data,
                group     => $conf->{group} || '',
            }
        );

        push( @{ $self->{nodes}->{$node_type} }, $node_obj );

        # store the last node so we can return it.
        $last_node = $node_obj;
    }
    return $last_node;
}

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head1 BUGS

None that I'm aware of - export may not encode correctly.

=head1 Repository (git)

http://github.com/ranguard/text-vcard, git://github.com/ranguard/text-vcard.git

=head1 COPYRIGHT

Copyright (c) 2005-2010 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::vCard::Addressbook>, L<Text::vCard::Node>

=cut

1;
