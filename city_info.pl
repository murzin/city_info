#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

# Notes about Data File Format:
# Script recognises format defined with the task for cities:
# ID. City, Country - Population
#
# and extended with format for countries:
# ID. Country : Capital, Population
#
# lines could be mixed
#
# if Country data is provided - capitals are recognised and city info output is extended with country info
# see __DATA__ section
#
# capital: ./city_info.pl -c Tokyo
# usual  : ./city_info.pl -c Seoul
# file   : ./city_info.pl -f city_names.txt -c Kyiv


# Classes: City, Capital, Country
# Capital extends City. Don't think it is a good idea, capital should be property of the Country,
# but realised just for inheritance example.

package City;
use Moo;

# storage for all cities by name
my %cities;

has id => (is => 'ro', required => 1);
has name => (is => 'ro', required => 1);
has country => (is => 'ro', required => 1);
has population => (is => 'ro', required => 1);

sub info {
    my $self = shift;
    printf "%-15s located in: %-15s city population: %-15s\n", $self->name, $self->country, $self->population;
}

sub store {
    my $self = shift;
    $cities{$self->name} = $self;
}

sub getCityNames {
    my $self = shift;
    return keys %cities;
}

sub getCityByName {
    my $self = shift;
    my $city = ref $self ? shift : $self;
    return $cities{$city};
}

sub getCities {
    my $self = shift;
    return values %cities;
}

sub isCapital {
    my $self = shift;
    my $country = Country::getCountryByName($self->country);
    if ($country) {
        if ($country->capital eq $self->name) {
            return $country;
        }
    }
    return;
}

package Capital;
use Moo;

extends 'City';

has isCapital => (is => 'ro', default => sub { 1 });
has Country => (is => 'ro', required => 1);

around info => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig;
    $self->Country->info;
};

package Country;
use Moo;

# storage forr coutries by name
my %countries;

has name => (is => 'ro', required => 1);
has capital => (is => 'ro', required => 1);
has population => (is => 'ro', required => 1);

sub info {
    my $self = shift;
    printf "%s: population: %s, capital: %s\n", $self->name, $self->population, $self->capital;
}

sub store {
    my $self = shift;
    $countries{$self->name} = $self;
}

sub getCountryByName {
    my $self = shift;
    my $country = ref $self ? shift : $self;
    return $countries{$country};
}

# script code
#
# it is possible to pack it into some Application class and
# my $ap = Application->new;
# $ap->init;
# $ap->run;
#
# but desided to keep it simple for this case
# if things will grow this script will stay as is with classes moved to modules
# and Application class could be used for something bigger


package main;
use Getopt::Long;

sub usage {
    die "Usage: $0 --city=city_name [--filename=data_file]\n";
}

sub init {
    my $filename = shift;
    my $fh;
    if ($filename) {
        unless (-r $filename) {
            warn "Unable to read file $filename\n";
            usage(); 
        }
        open $fh, '<', $filename or die $!;
    } else {
        $fh = *DATA;
    }
    while (my $line = <$fh>) {
        chomp $line;
# cities: ID. City, Country - Population
        if ($line =~ /(\d+)\.\s+([^,]+),\s+([^,-]+)\s+-\s+([\d,]+)/) {
            my $city = City->new(
                    id => $1,
                    name => $2,
                    country => $3,
                    population => $4,
                    );
            $city->store;
# countries: ID. Country : Capital, Population
        } elsif ($line =~ /(\d+)\.\s+([^:]+):\s+([^,]+)\s*,\s+([\d,]+)/) {
            my $country = Country->new(
                    id => $1,
                    name => $2,
                    capital => $3,
                    population => $4,
            );
            $country->store;
        } else {
            #print "BAD LINE: $line\n";
        }
    }
# it is possible to detect Capitals only after everything is parsed
    for my $city (City::getCities) {
        if (my $country = $city->isCapital) {
            my $capital = Capital->new(
                    id => $city->id,
                    name => $city->name,
                    country => $city->country,
                    population => $city->population,
                    Country => $country,
            );
            $capital->store;
        }
    }
}

sub main {
    my %opt;
    my @cities;

    GetOptions(
        \%opt,
        'city=s',
        'filename=s'
    ) || usage();

    init($opt{filename});

    if ($opt{city}) {
        my $city = City::getCityByName($opt{city});
        unless ($city) {
            warn "No information for city $opt{city}\n";
            usage();
        }
        @cities = ($city);
    } else {
        @cities = City::getCities;
    }

    for my $city (@cities) {
        $city->info;
    }
}

main();
exit 0;

__DATA__
Cities:
ID. City, Country - Population
1. Tokyo, Japan - 32,450,000
2. Seoul, South Korea - 20,550,000
3. Mexico City, Mexico - 20,450,000

Countries:
ID. Country: Capital, Population
1. Japan: Tokyo, 127,2323,243,232
2. Mexico: Mexico City, 27,2323,243,232
