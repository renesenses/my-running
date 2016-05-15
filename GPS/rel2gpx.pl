#!/usr/bin/perl -w
########################################################################################################
#
# rel2gpx.pl 
#
# Copyright (C) 2009, Rainer Unseld
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program;
# if not, see <http://www.gnu.org/licenses/>
#
########################################################################################################
# Change history:
#
#  Version 0.21:
#
#        - Verbesserte Überprüfung der Komandozeilen-Optionen
#        - Input von lokaler osm-Datei
#        - Ausgabe in osm-Datei
#        - Verbindung über kreisverkehr wird erkannt im Track als direkte Verbindung quer
#          über den Kreisverkehr berücksichtigt
#        - teilweise BeFlinkwrücksichtigung von oneway und role=forward/backward
#        - Einschränkungen:
#              . Bei Routen mit 2 Fahrtrichtungen (role=forward/backward) wird nur eine Richtung
#                als GPX-Track erzeugt
#              . Trackführung im Kreisverkehr nicht auf der Strasse
#              . u.v.a.m.
#
#  Version 0.22:
#        - Fehlerbehebungen
#        - erweiterte Optionen
#
#  Version 0.23:
#        - Behandlung von Fahrtrichtungen (oneway, forward/backward)
#
#  Version 0.24:
#        - Mehrsprachigkeit
#
#  Version 0.26:
#        - Fehler bei Behandlung von Kreisverkehren behoben
#
#  Version 0.27:
#        - Index für die Nummerierung der Tracks jetzt drei- statt zweistellig
#        - Zwei Patches von Andreas Tille eingebaut 
#           . berücksichtigen der Einheit (km) bei Länge der Route
#           . Inkorrekte Dereferenzierung korrigiert (verhindert Perl warnungen)
#
########################################################################################################
   use strict;
   our $debug = 0;
   use constant {DEBUG_LOW    => 1,
                 DEBUG_MEDIUM => 2,
                 DEBUG_HIGH   => 3,
                 DEBUG_MAX    => 4,
                };
   use constant {FORWARD => 0,
                 BACKWARD => 1,
                };
   
   #our (%lat, %lon);
   our (%relXml, %wayXml, %nodeXml);
   our $LH;
   my  $version = "0.27" ;
#======================================================================
package osmWay;
#======================================================================
   #use Data::Dumper;
   
   use LWP::Simple;
   #use IO::Scalar;
   use XML::Parser qw(parsefile);
   use OSM::osm 4.0 ;
   use Encode;
   use List::Util qw(max min);
   
   our $maxLat = -90;
   our $maxLon = -180;
   our $minLat = 90;
   our $minLon = 180;
   our %ways;
   our (%nodeLat, %nodeLon);
   our (%wayMinLat, %wayMinLon, %wayMaxLat, %wayMaxLon);
   our $onewayDisabled = 0;
   use constant {FORWARD => 0,
                 BACKWARD => 1,
                };
#------------------------------------------------------------------------
sub new {
  my $self=shift;
  my $way_ref = shift;
  my $ref={};

  bless($ref, $self); # nicht &bless schreiben!

   $ref->{ID} = $way_ref;
   @{$ref->{LAT}} = ();
   @{$ref->{LON}} = ();
   @{$ref->{NID}} = ();
   @{$ref->{wayIds}} = ();
   $ref->{processed} = 0;
   $ref->{ROUNDABOUT} = 0;
   $ref->{AREA} = 0;
   $ref->{ROLE} = "";
   $ref->{ONEWAY} = 0;
   $ref->{PREV} = ();
   $ref->{NEXT} = ();
   push @{$ref->{wayIds}}, $way_ref;
   $ways{$way_ref} = $ref;
   $ref;
}
sub clone{
   my $self = shift;
   my $id = "C".$self->id;
   my $newWay = osmWay->new($id);
   @{$newWay->{LAT}} =  (@{$self->{LAT}});
   @{$newWay->{LON}} =  (@{$self->{LON}});
   @{$newWay->{NID}} =  (@{$self->{NID}});
   @{$newWay->{wayIds}} =  (@{$self->{wayIds}});
   $newWay->{ONEWAY} = $self->{ONEWAY};
   $newWay->{ROUNDABOUT} = $self->{ROUNDABOUT};
   $newWay;
}
sub addNode{
   my $self = shift;
   my $nid = shift;
   my $lat = shift;
   my $lon = shift;
   push @{$self->{LAT}}, $lat;
   push @{$self->{LON}}, $lon;
   push @{$self->{NID}}, $nid;
}
sub removeNode{
   my $self = shift;
   my $i = shift;
   splice @{$self->{NID}}, $i, 1;
   splice @{$self->{LAT}}, $i, 1;
   splice @{$self->{LON}}, $i, 1;
}
sub delete{
   my $self = shift;
   delete $ways{$self->{ID}};
}
sub checkLink{
   my $self = shift;
   my $way2 = shift;
   my @links = ();

   if ($self == $way2){
      return @links;
   }

   if ($self->firstNid == $way2->firstNid){
      push @links, "AA";
   }
   if ($self->firstNid == $way2->lastNid){
         push @links, "AE";
   }
   if ($self->lastNid == $way2->firstNid){
      push @links, "EA";
   }
   if ($self->lastNid == $way2->lastNid){
      push @links, "EE";
   }
   return @links;
}
sub joinWays{
   my $self = shift;
   my $way1 = shift;
   my $way2 = shift;
   my $conn = shift;

   if ($conn eq "AA"){
      if ($way1->isOneway){
         $way2->reverse;
         $conn = "AE";
      }else{
         $way1->reverse;
         $conn = "EA";
      }
   }elsif ($conn eq "EE"){
      if ($way1->isOneway){
         $way2->reverse;
         $conn = "EA";
      }else{
         $way1->reverse;
         $conn = "AE";
      }
   }
   if ($conn eq "AE"){
      @{$way1->{LAT}} = (@{$way2->{LAT}}, @{$way1->{LAT}});
      @{$way1->{LON}} = (@{$way2->{LON}}, @{$way1->{LON}});
      @{$way1->{NID}} = (@{$way2->{NID}}, @{$way1->{NID}});
      @{$way1->{wayIds}} = (@{$way2->{wayIds}}, @{$way1->{wayIds}});
      $way1->{ID} = $way2->{ID};
   }else{
      @{$way1->{LAT}} = (@{$way1->{LAT}}, @{$way2->{LAT}});
      @{$way1->{LON}} = (@{$way1->{LON}}, @{$way2->{LON}});
      @{$way1->{NID}} = (@{$way1->{NID}}, @{$way2->{NID}});
      @{$way1->{wayIds}} = (@{$way1->{wayIds}}, @{$way2->{wayIds}});
   }
   if ($way2->isOneway){
      $way1->setOneway(1);
   }
}
sub joinWaysArray{
   my $self = shift;
   my $refArray = shift;

   # -------------------------------------------------------------
   # Fasse Wege zusammen:
   # -------------------------------------------------------------
   printf STDERR $LH->maketext("Verbinde zusammenhängende Wege...")." %4d", $#{$refArray};
   for (my $j = 0; $j < $#{$refArray}; $j++){
      my $way1 = $refArray->[$j];
      my $way2 = $refArray->[$j+1];
      my $type = "";
      if ($way1->lastNid == $way2->firstNid){
         $type = "EA";
         osmWay->joinWays($way1, $way2, $type);
         $refArray->[$j+1]->delete;
         splice(@{$refArray}, $j+1, 1);
         $j--;
         printf STDERR "\r", $LH->maketext("Verbinde zusammenhängende Wege...")." %4d", $#{$refArray};
      }
   }
   printf STDERR "\n";
}

sub linkWays{
   my $self = shift;
   my $way1 = shift;
   my $way2 = shift;

   if ($way1->lastNid == $way2->firstNid){
      push @{$way1->{NEXT}}, $way2;
      push @{$way2->{PREV}}, $way1;
   }elsif ($way1->firstNid == $way2->lastNid){
      push @{$way1->{PREV}}, $way2;
      push @{$way2->{NEXT}}, $way1;
   }elsif (not ($way1->isOneway and $way2->isOneway)){
      if ($way1->lastNid == $way2->lastNid){
         push @{$way1->{NEXT}}, $way2;
         push @{$way2->{NEXT}}, $way1;
      }elsif ($way1->firstNid == $way2->firstNid){
         push @{$way1->{PREV}}, $way2;
         push @{$way2->{PREV}}, $way1;
      }
   }
}
sub unlinkWay{
   my $self = shift;

   for (my $i=0; $i <= $#{$self->{PREV}}; $i++){
      my $way2 = $self->{PREV}[$i];
      for (my $j=0; $j <= $#{$way2->{NEXT}}; $j++){
         if ($way2->{NEXT}[$j] == $self){
            splice @{$way2->{NEXT}}, $j, 1;
            last;
         }
      }
      for (my $j=0; $j <= $#{$way2->{PREV}}; $j++){
         if ($way2->{PREV}[$j] == $self){
            splice @{$way2->{PREV}}, $j, 1;
            last;
         }
      }
   }
   for (my $i=0; $i <= $#{$self->{NEXT}}; $i++){
      my $way2 = $self->{NEXT}[$i];
      for (my $j=0; $j <= $#{$way2->{NEXT}}; $j++){
         if ($way2->{NEXT}[$j] == $self){
            splice @{$way2->{NEXT}}, $j, 1;
            last;
         }
      }
      for (my $j=0; $j <= $#{$way2->{PREV}}; $j++){
         if ($way2->{PREV}[$j] == $self){
            splice @{$way2->{PREV}}, $j, 1;
            last;
         }
      }
   }
}
sub dumpLinks{
   my $self = shift;
   my $refWayList = shift;
   foreach my $way1 (@{$refWayList}){
      print "\n\n",$way1->id;
      print "\n        PREV:";
      foreach my $way2 (@{$way1->{PREV}}){
         print "  ",$way2->id;
      }
      print "\n        NEXT:";
      foreach my $way2 (@{$way1->{NEXT}}){
         print "  ",$way2->id;
      }
   }
   print "\n\n";
}
use feature 'state';
sub traverse{
   my $self = shift;
   my $root =shift;
   my $cType = shift;
   my ($list, $tlist);
   state $depth = 0;
   state $calls = 0;
   my $loop = 0;
   if ($debug >= main::DEBUG_HIGH){
      print STDERR "traverse $depth ",$self->id," $cType $root\n";
   }
   $depth++;
   if ($calls > 2000){
      print $LH->maketext("Topologie der Relation zu komplex. Abbruch."),"\n";
      $depth--;
      $calls = -1;
      return (-2, 1, -2);
   }elsif ($calls < 0){
      $depth--;
      return (-2, 1, -2);
   }
   $calls++;
   if ($root){
      osmWay->clearFlagsVisited;
      $depth = 0;
      $calls = 0;
   }
   if ($self->{visited}){
      $depth--;
      return (-1, 1, -1);
   }
   if ($self->isOneway){
      $depth--;
      return (-1, 1, -1);
   }
   $self->{visited} = 1;
   if ($self->isRoundabout){
      $depth--;
      return (-1, 1, -1);
   }

   if ($cType eq "A"){
      $list = $self->{NEXT};
      $self->{direction} = FORWARD;
   }else{
      $list = $self->{PREV};
      $self->{direction} = BACKWARD;
   }
   my $dmax = 0;
   my $maxPrio = 0;
   my @a = ();
   my @t = ();
   for (my $i=0; $i<=$#{$list};$i++){
      my $cTypeN = "";
      my $way2 = $list->[$i];
      if ($cType eq "A"){
         if ($self->lastNid == $way2->firstNid){
            $cTypeN = "A";
         }else{
            $cTypeN = "E";
         }
      }else{
         if ($self->firstNid == $way2->firstNid){
            $cTypeN = "A";
         }else{
            $cTypeN = "E";
         }
      }
      my $cPrio;
      if ($self->isOneway){
         if ($way2->isOneway){
            $cPrio = 1;
         }else{
            $cPrio = 2;
         }
      }elsif ($way2->isOneway){
         $cPrio = 2;
      }else{
         $cPrio = 4;
      }
      if ($cPrio < 3 and $self->isRoundabout and not $way2->isRoundabout){
         $cPrio = 3;
      }
      if ($cType eq "A" and $cTypeN eq "A"){
         $cPrio = $cPrio*3+2;
      }elsif ($cType eq "A" and $cTypeN eq "E"){
         $cPrio = $cPrio*3 + 1;
      }else{
         $cPrio = $cPrio*3;
      }
      my ($d, $cLoop, @a) = $way2->traverse(0, $cTypeN);
      if ($d > 0){
         if ($loop){
            $cPrio--;   # ????
         }
         if ($cPrio > $maxPrio or ($cPrio == $maxPrio and $d > $dmax)){
            $dmax = $d;
            $maxPrio = $cPrio;
            @t = (@a);
            $loop = $cLoop;
         }
      }
   }
   if (not $self->{processed}){
      $dmax += $self->length;
      @t =  (($self), @t);
   }
   $self->{visited} = 0;
   $depth--;
   return ($dmax, $loop, (@t));
}
sub clearFlags{
  foreach my $id (keys(%ways)){
      my $way = $ways{$id};
      $way->{visited} = 0;
      $way->{processed} = 0;
   }
}
sub clearFlagsVisited{
   foreach my $id (keys(%ways)){
      $ways{$id}->{visited} = 0;
   }
}
#------------------------------------------------------------------------
sub download {
   my $self = shift;
   my $osmFile = shift;
   my $rc = 1;
   my $opposite = 0;
   my ($parsedXml, $member, $members, $way, $nodes);
   my $p1 = new XML::Parser(Style => 'Objects');

   if ($osmFile eq ""){
      my $url = "http://www.openstreetmap.org/api/0.6/way/".$self->{ID}."/full";
      $way=get($url);
      if (!defined($way)){
            print "\n  ",$LH->maketext("Fehler beim Lesen von [_1], Abbruch", $url),"\n";
            return -1;
      }
      #$XMLFILE=new IO::Scalar \$way;
      $parsedXml=$p1->parse($way, ProtocolEncoding => 'UTF-8');
      $wayXml{$self->{ID}} = $way;
      #close $XMLFILE;
      $members=@{$parsedXml}[0]->{'Kids'};
   }else{
      if (!exists($wayXml{$self->{ID}})){
          print STDERR "\n";
          print "  ",$LH->maketext("Warnung: Weg [_1] nicht in osm-Datei", $self->{ID}), "\n";
          statOutput->warningIncompleteData;
          return 0;
      }else{
         $way = $wayXml{$self->{ID}};
      }
      #$XMLFILE=new IO::Scalar \$way;
      $parsedXml=$p1->parse($way, ProtocolEncoding => 'UTF-8');
      #close $XMLFILE;
      $members=@{$parsedXml}[0]->{'Kids'};
      $nodes = "";
      foreach $member (@{$members}) {
         if ($member->isa('osmWay::nd')){
            if (!exists($nodeXml{$member->{'ref'}})){
               print STDERR "\n";
               print "  ", $LH->maketext("Warnung: Knoten [_1] (Weg [_2]) nicht in osm-Datei", $member->{'ref'}, $self->{ID}), "\n";
               statOutput->warningIncompleteData;
               $rc = 0
            }else{
               $nodes .= $nodeXml{$member->{'ref'}};
            }
         }
      }
      $way = "<osm>\n$nodes$way\n</osm>";
      #$XMLFILE=new IO::Scalar \$way;
      $parsedXml=$p1->parse($way, ProtocolEncoding => 'UTF-8');
      #close $XMLFILE;
      $members=@{$parsedXml}[0]->{'Kids'};
   }
   my $wayId = $self->id;
   my $myMaxLat = -90;
   my $myMaxLon = -180;
   my $myMinLat = 90;
   my $myMinLon = 180;
   foreach my $t (@{$members}) {
      if ($t->isa('osmWay::node') ne '') {
         my $id=$t->{'id'};
         $nodeLat{$id}=$t->{'lat'};
         $nodeLon{$id}=$t->{'lon'};
         $myMaxLat = max($t->{'lat'}, $myMaxLat);
         $myMaxLon = max($t->{'lon'}, $myMaxLon);
         $myMinLat = min($t->{'lat'}, $myMinLat);
         $myMinLon = min($t->{'lon'}, $myMinLon);
      } elsif ($t->isa('osmWay::way')) {
         if ($debug>=main::DEBUG_HIGH){
            print STDERR "\nway $wayId:\n";
         }
         my $nds = $t->{'Kids'};
         foreach my $nd (@{$nds}) {
            if ($nd->isa('osmWay::nd') ne ''){
               my $id=$nd->{'ref'};
               if (exists($nodeLat{$id})){
                  push @{$self->{LAT}}, $nodeLat{$id};
                  push @{$self->{LON}}, $nodeLon{$id};
                  push @{$self->{NID}}, $id;
               }
            }elsif ($nd->isa('osmWay::tag')){
               if ($debug>=main::DEBUG_HIGH){
                  print STDERR "$nd->{'k'} $nd->{'v'}\n";
               }
               if ($nd->{'k'} eq 'junction' && $nd->{'v'} eq 'roundabout'){
                  $self->setRoundabout(1);
               }elsif ($nd->{'k'} eq 'area' and ($nd->{'v'} eq 'yes' or $nd->{'v'} eq "1" or $nd->{'v'} eq "true")){
                  $self->{AREA} = 1;
               }elsif ($nd->{'k'} eq 'oneway'){
                  if (not $opposite){
                     my $value = $nd->{'v'};
                     if ($value eq "1" || $value eq "yes" || $value eq "true"){
                        $self->setOneway(1);
                     }elsif ($value eq "0" || $value eq "no" || $value eq "false"){
                        $self->setOneway(0);
                     }elsif ($value eq "-1" || $value eq "reverse"){
                        $self->setOneway(-1);
                     }
                  }
               }elsif (substr($nd->{'k'},0,8) eq 'cycleway'){
                  my $value = $nd->{'v'};
                  if (index($value, "opposite") >= 0){
                     $self->setOneway(0);
                     $opposite = 1;
                  }
               }
            }
         }
      }
   }
   $maxLat = max($myMaxLat, $maxLat);
   $maxLon = max($myMaxLon, $maxLon);
   $minLat = min($myMinLat, $minLat);
   $minLon = min($myMinLon, $minLon);
   $wayMaxLat{$wayId} = $myMaxLat;
   $wayMaxLon{$wayId} = $myMaxLon;
   $wayMinLat{$wayId} = $myMinLat;
   $wayMinLon{$wayId} = $myMinLon;
  return $rc;
}

#------------------------------------------------------------------------
sub id{
   my $self=shift;
   $self->{ID};
}
sub role{
   my $self=shift;
   $self->{ROLE};
}
#------------------------------------------------------------------------
sub nodes{
   my $self=shift;
   $#{$self->{LAT}} + 1;
}
#------------------------------------------------------------------------
sub first{
   my $self=shift;
   ($self->{LAT}[0], $self->{LON}[0]);
}
#------------------------------------------------------------------------
sub last{
   my $self=shift;
   my $i = $#{$self->{LAT}};
   ($self->{LAT}[$i], $self->{LON}[$i]);
}
sub firstNid{
   my $self=shift;
   $self->{NID}[0];
}
#------------------------------------------------------------------------
sub lastNid{
   my $self=shift;
   $self->{NID}[$#{$self->{NID}}];
}
#------------------------------------------------------------------------
sub lon{
   my $self=shift;
   my $i=shift;
   $self->{LON}[$i];
}
#------------------------------------------------------------------------
sub lat{
   my $self=shift;
   my $i=shift;
   $self->{LAT}[$i];
}
#------------------------------------------------------------------------
sub nid{
   my $self=shift;
   my $i=shift;
   $self->{NID}[$i];
}
sub nids{
   my $self=shift;
   @{$self->{NID}};
}
#------------------------------------------------------------------------
sub wayId{
   my $self=shift;
   my $i=shift;
   $self->{wayIds}[$i];
}
sub ways{
   my $self=shift;
   $#{$self->{wayIds}} + 1;
}
#------------------------------------------------------------------------
sub setRoundabout{
   my $self = shift;
   my $r = shift;
   $self->{ROUNDABOUT} = $r;
   if ($r != 0){
      $self->{ONEWAY} = 1;
   }
}
sub isRoundabout{
   my $self = shift;
   return $self->{ROUNDABOUT};
}
sub isArea{
   my $self = shift;
   return $self->{AREA};
}
#------------------------------------------------------------------------
sub maxlat{$maxLat}
sub maxlon{$maxLon}
sub minlat{$minLat}
sub minlon{$minLon}
sub setRole{
   my $self = shift;
   $self->{ROLE} = shift;
}
sub setOneway{
   my $self = shift;
   $self->{ONEWAY} = shift;
}
sub isOneway{
   my $self = shift;
   if ($onewayDisabled){
      return 0;
   }
   return $self->{ONEWAY};
}
sub disableOneway{
   $onewayDisabled = 1;
}
sub reverse{
   my $self = shift;
   @{$self->{LAT}} = reverse(@{$self->{LAT}});
   @{$self->{LON}} = reverse(@{$self->{LON}});
   @{$self->{NID}} = reverse(@{$self->{NID}});
   @{$self->{wayIds}} = reverse(@{$self->{wayIds}});
   if (defined $self->{PREV}){
      my @aTmp = (@{$self->{PREV}});
      if (defined $self->{NEXT}){
         @{$self->{PREV}} = (@{$self->{NEXT}});
      }else{
         @{$self->{PREV}} = ();
      }
   }else{
      if (defined $self->{NEXT}){
         @{$self->{PREV}} = (@{$self->{NEXT}});
      }else{
         @{$self->{PREV}} = ();
      }
      @{$self->{NEXT}} = ();
   }
}

sub length{
   my $self=shift;

   my $l = 0;
   for (my $j=0; $j < $self->nodes-1; $j++){
      $l += util::dist($self->lat($j),
                 $self->lon($j),
                 $self->lat($j+1),
                 $self->lon($j+1),
                );
   }
   return $l;
}
sub dump{
   my $self = shift;
   print STDERR Dumper($self)
}

sub distanceWays{
   my $self = shift;
   my $way1 = shift;
   my $way2 = shift;
   my $connectionType = shift;
   my $d =0;
   
   if ($connectionType eq "EA"){
      $d = util::dist($way1->last, $way2->first);
   }elsif ($connectionType eq "AE"){
      $d = util::dist($way1->first, $way2->last);
   }elsif ($connectionType eq "AA"){
      $d = util::dist($way1->first, $way2->first);
   }elsif ($connectionType eq "EE"){
      $d = util::dist($way1->last, $way2->last);
   }
   return $d;
}
#======================================================================
package segChain;
#======================================================================
   #use Data::Dumper;
sub new {
   my $self=shift;
   my $ways = shift;
   my $ref={};

   bless($ref, $self); # nicht &bless schreiben!

   $ref->{ONEWAY} = 0;
   @{$ref->{WAYS}} = @{$ways};
   for (my $i=0; $i<=$#{$ways}; $i++){
      if ($ways->[$i]->isOneway){
         $ref->{ONEWAY} = 1;
      }
      if ($ways->[$i]->isRoundabout){
         $ref->{ROUNDABOUT} = 1;
      }
   }
   $ref;
}

sub push{
   my $self = shift;
   my $way = shift;

   push @{$self->{WAYS}}, $way;
}
sub setOneway{
   my $self = shift;
   $self->{ONEWAY} = shift;
}
sub setRoundabout{
   my $self = shift;
   $self->{ROUNDABOUT} = shift;
}
sub isOneway{
   my $self = shift;
   if ($self->{ROUNDABOUT}){
      return 1;
   }
   if ($onewayDisabled){
      return 0;
   }
   return $self->{ONEWAY};
}
sub isRoundabout{
   my $self = shift;
   return $self->{ROUNDABOUT};
}
sub disableOneway{
   $onewayDisabled = 1;
}
sub linkChains{
   my $self = shift;
   my $chain2 = shift;
   my $t = shift;

   my $l1 = $#{$self->{WAYS}};
   my $l2 = $#{$chain2->{WAYS}};

   if ($t eq "EA"){
      @{$self->{WAYS}} = (@{$self->{WAYS}}, @{$chain2->{WAYS}});
   }elsif ($t eq "AE"){
      @{$self->{WAYS}} = (@{$chain2->{WAYS}},@{$self->{WAYS}});
   }elsif ($t eq "AA"){
      if ($self->isOneway){
         for (my $i=0; $i <= $l2; $i++){
            $chain2->{WAYS}[$i]->reverse;
         }
         @{$self->{WAYS}} = (reverse(@{$chain2->{WAYS}}), @{$self->{WAYS}});
      }else{
         for (my $i=0; $i <= $l1; $i++){
            $self->{WAYS}[$i]->reverse;
         }
         @{$self->{WAYS}} = (reverse(@{$self->{WAYS}}), @{$chain2->{WAYS}});
      }
   }elsif ($t eq "EE"){
      if ($self->isOneway){
         for (my $i=0; $i <= $l2; $i++){
            $chain2->{WAYS}[$i]->reverse;
         }
         @{$self->{WAYS}} = (@{$self->{WAYS}}, reverse(@{$chain2->{WAYS}}));
      }else{
         for (my $i=0; $i <= $l1; $i++){
            $self->{WAYS}[$i]->reverse;
         }
         @{$self->{WAYS}} = (@{$chain2->{WAYS}}, reverse(@{$self->{WAYS}}));
      }
   }
   if ($chain2->isOneway){
      $self->setOneway(1);
   }
   if ($chain2->isRoundabout){
      $self->setRoundabout(1);
   }
}
# Sortiere Segmente nach Entfernung:
sub sort{
   my $self = shift;
   my $refChains = shift;
   my $reverse = shift;
   my $dmax = 0;
   my $i2;

   if ($debug>=main::DEBUG_MEDIUM){
      print STDERR "Sortiere Chain\n";
      for (my $i=0;$i<=$#{$refChains};$i++){
         print STDERR "$i:\n";
         $refChains->[$i]->dump;
      }
   }
   my $found = 0;
   for (my $i=0; $i < $#{$refChains}; $i++) {
      do{
         my $chain1 = $refChains->[$i];
         my %distance = ();
         #my %angle = ();
         my %ct = ();
         for (my $j = 0; $j <= $#{$refChains}; $j++) {
            my $chain2 = $refChains->[$j];
            if ($i == $j){next};
            my @types = ("EA", "AE", "AA", "EE");
            #my @types = ("EA", "EE");
            if ($chain1->isOneway and $chain2->isOneway){
               @types = ("EA", "AE");
               #@types = ("EA");
            }
            if (not $reverse){
               @types = ("EA", "AE");
            }
            foreach my $connectionType (@types){
               my $d = segChain->distance($chain1, $chain2, $connectionType);
               my $j2 = $connectionType.$j;
               $distance{$j2} = $d;
               #$angle{$j2} = segChain->angle($chain1, $chain2, $connectionType);
               #$ct{$j2} = $connectionType;
            }
         }
         $found = 0;
         my @keys = sort { $distance{$a} <=> $distance{$b} } keys %distance;
         if ($#keys >= 0){
            if ($distance{$keys[0]} == 0){
               # Wege sind direkt verbunden
               my $maxPrio = 0;
               my $maxLen = 0;
               $i2 = -1;
               for (my $j=0; $j<$#keys and $distance{$keys[$j]} == 0; $j++){
                  my ($way1, $way2);
                  my $cPrio = 0;
                  my $cType = substr($keys[$j], 0, 2);
                  my $k = substr($keys[$j], 2);
                  if (substr($cType,0,1) eq "A"){
                     $way1 = $refChains->[$i]->{WAYS}[0];
                  }else{
                     $way1 = $refChains->[$i]->{WAYS}[$#{$refChains->[$i]->{WAYS}}];
                  }
                  if (substr($cType,1) eq "A"){
                     $way2 = $refChains->[$k]->{WAYS}[0];
                  }else{
                     $way2 = $refChains->[$k]->{WAYS}[$#{$refChains->[$k]->{WAYS}}];
                  }
                  if (not $reverse and not($way1->lastNid == $way2->firstNid
                                           or $way2->lastNid == $way1->firstNid)){
                     next;
                  }
                  if ($way1->isOneway or $way1->isRoundabout){
                     if ($way2->isOneway or $way2->isRoundabout){
                        $cPrio = 1;
                     }else{
                        $cPrio = 2;
                     }
                  }elsif ($way2->isOneway){
                     $cPrio = 2;
                  }else{
                     $cPrio = 4;
                  }
                  if ($cPrio < 3 and $way1->isRoundabout != $way2->isRoundabout){
                     $cPrio = 3;
                  }
                  if ($cType eq "EA"){
                     $cPrio = $cPrio*3+2;
                  }elsif ($cType eq "AE" ){
                     $cPrio = $cPrio*3 + 1;
                  }else{
                     $cPrio = $cPrio*3;
                  }
                  my $cLen = $way2->length;
                  if ($cPrio > $maxPrio or ($cPrio == $maxPrio and $cLen > $maxLen)){
                     $maxPrio = $cPrio;
                     $maxLen = $cLen;
                     $i2 = $j;
                  }
               }
            }else{
               $i2 = 0;
            }
            my $connectionType = substr($keys[$i2],0,2);
            $i2 = substr($keys[$i2],2);
            $refChains->[$i]->linkChains($refChains->[$i2], $connectionType);
            splice @{$refChains}, $i2, 1;
            $found = 1;
            if ($debug>=main::DEBUG_MEDIUM){
               print STDERR "Link chain $i -> $i2 $connectionType\n";
            }else{
               printf STDERR "\r", $LH->maketext("Sortiere Segmente...")."%4d", $#{$refChains};
            }
            # todo: destroy object
            if ($debug>=main::DEBUG_MEDIUM){
               for (my $i=0;$i<=$#{$refChains};$i++){
                  print STDERR "Chain $i:\n";
                  $refChains->[$i]->dump;
               }
            }
         }
      } while ($found and $#{$refChains} > 0);
   }
   print STDERR "\n";
} # sub sort



sub distance{
   my $self = shift;
   my $chain1 = shift;
   my $chain2 = shift;
   my $connectionType = shift;

   my $wayBeg = $chain1->{WAYS}[0];
   my $wayEnd = $chain1->{WAYS}[$#{$chain1->{WAYS}}];
   
   my @chain1_coord_a = ($wayBeg->lat(0),
                         $wayBeg->lon(0)
                        );
   my @chain1_coord_e = ($wayEnd->lat($wayEnd->nodes - 1),
                         $wayEnd->lon($wayEnd->nodes - 1)
                        );

   $wayBeg = $chain2->{WAYS}[0];
   $wayEnd = $chain2->{WAYS}[$#{$chain2->{WAYS}}];
   my @chain2_coord_a = ($wayBeg->lat(0),
                         $wayBeg->lon(0)
                        );
   my @chain2_coord_e = ($wayEnd->lat($wayEnd->nodes - 1),
                         $wayEnd->lon($wayEnd->nodes - 1)
                        );
   my $d = 0;
   if ($connectionType eq "EA"){
      if ($chain1->{WAYS}[$#{$chain1->{WAYS}}]->lastNid == $chain2->{WAYS}[0]->firstNid){
         $d = 0;
      }else{
         $d = util::dist(@chain1_coord_e, @chain2_coord_a);
      }
   }elsif ($connectionType eq "AE"){
      if ($chain1->{WAYS}[0]->firstNid == $chain2->{WAYS}[$#{$chain2->{WAYS}}]->lastNid){
         $d = 0;
      }else{
         $d = util::dist(@chain1_coord_a, @chain2_coord_e);
      }
   }elsif ($connectionType eq "AA"){
      if ($chain1->{WAYS}[0]->firstNid == $chain2->{WAYS}[0]->firstNid){
         $d = 0;
      }else{
         $d = util::dist(@chain1_coord_a, @chain2_coord_a);
      }
   }elsif ($connectionType eq "EE"){
      if ($chain1->{WAYS}[$#{$chain1->{WAYS}}]->lastNid == $chain2->{WAYS}[$#{$chain2->{WAYS}}]->lastNid){
         $d = 0;
      }else{
         $d = util::dist(@chain1_coord_e, @chain2_coord_e);
      }
   }
   return $d;
}
sub angle{
   my $self = shift;
   my $chain1 = shift;
   my $chain2 = shift;
   my $connectionType = shift;
   my ($direction1, $direction2);
   
   my $wayBeg = $chain1->{WAYS}[0];
   my $wayEnd = $chain1->{WAYS}[$#{$chain1->{WAYS}}];
   my @chain1_coord_a = ($wayBeg->lat(0),
                         $wayBeg->lon(0)
                        );
   my @chain1_coord_e = ($wayEnd->lat($wayEnd->nodes - 1),
                         $wayEnd->lon($wayEnd->nodes - 1)
                        );

   $wayBeg = $chain2->{WAYS}[0];
   $wayEnd = $chain2->{WAYS}[$#{$chain2->{WAYS}}];
   my @chain2_coord_a = ($wayBeg->lat(0),
                         $wayBeg->lon(0)
                        );
   my @chain2_coord_e = ($wayEnd->lat($wayEnd->nodes - 1),
                         $wayEnd->lon($wayEnd->nodes - 1)
                        );
   if ($connectionType eq "EA"){
   print $chain1->{WAYS}[$#{$chain1->{WAYS}}]->id, " ", $chain2->{WAYS}[0]->id, "\n";
      $direction1 = util::direction(@chain1_coord_a, @chain1_coord_e);
      $direction2 = util::direction(@chain2_coord_a, @chain2_coord_e);
   }elsif ($connectionType eq "AE"){
      $direction1 = util::direction(@chain1_coord_e, @chain1_coord_a);
      $direction2 = util::direction(@chain2_coord_e, @chain2_coord_a);
   }elsif ($connectionType eq "AA"){
      $direction1 = util::direction(@chain1_coord_e, @chain1_coord_a);
      $direction2 = util::direction(@chain2_coord_a, @chain2_coord_e);
   }elsif ($connectionType eq "EE"){
      $direction1 = util::direction(@chain1_coord_a, @chain1_coord_e);
      $direction2 = util::direction(@chain2_coord_e, @chain2_coord_a);
   }
   return abs ($direction1 - $direction2);
}
sub dump{
   my $self = shift;
   for (my $i=0; $i<=$#{$self->{WAYS}}; $i++){
      print STDERR "  ",$self->{WAYS}[$i]->id,"\n";
   }
   print STDERR "  oneway=",$self->{ONEWAY},"\n";
}
#======================================================================
package util;
#======================================================================
use Math::Trig qw(great_circle_distance great_circle_direction deg2rad);
#-------------------------------------------------------------
# Entfernung zwischen zwei Punkten (in m)
#-------------------------------------------------------------
sub dist{
   my ($lat1,$lon1,$lat2,$lon2) = @_;

   my $d = great_circle_distance(deg2rad($lon1), deg2rad(90-$lat1), deg2rad($lon2), deg2rad(90-$lat2), 6378);
   return $d;
}
#-------------------------------------------------------------
# Winkel zwischen zwei Punkten (Radian)
#-------------------------------------------------------------
sub direction{
   my ($lat1,$lon1,$lat2,$lon2) = @_;

   my $d = great_circle_direction(deg2rad($lon1), deg2rad(90-$lat1), deg2rad($lon2), deg2rad(90-$lat2));
   return $d;
}
#======================================================================
package statOutput;
#======================================================================
   #use strict;
   #use Data::Dumper;
   use List::Util qw(max min);
   use XML::Parser qw(parsefile);
   use LWP::Simple;

   our $incompleteData = 0;
   our @warnings;
   our $fh;

sub new {
   my $self=shift;

   my $ref={};

   bless($ref, $self); # nicht &bless schreiben!
   $ref;
}
sub printStatistics{
   my $self = shift;
   my $relId = shift;
   my $relName = shift;
   my $relDistance = shift;
   my $ways = shift;
   my $l_total = 0;
   my $s = "";
   print "\n";
   for (my $i=0; $i <= $#{$ways}; $i++) {
      my $n = 0;
      if ($i < $#{$ways}){
         $n = $i+1;
      }
      my $way1 = $ways->[$i];
      my $way2 = $ways->[$n];
      my $l = $way1->length;
      $l_total += $l;
      my $d = util::dist($way1->lat($way1->nodes-1),
                        $way1->lon($way1->nodes-1),
                        $way2->lat(0),
                        $way2->lon(0));
      $s =  sprintf "  ".$LH->maketext("Segment")." %2d", $i+1;
      $s .= sprintf ", ".$LH->maketext("Knoten:")." %4d", $way1->nodes;
      $s .= sprintf ", ".$LH->maketext("Länge:")." %7.3f km", $l;
      if ($i < $#{$ways}){
         $s .= sprintf ", ".$LH->maketext("Entf. zu Seg.")." %2d: %7.3f km", $n, $d;
      }
      print $s."\n";
   }
   $s = $LH->maketext("[quant,_1,Segment,Segmente]  Länge: [sprintf,%.1f,_2] km  Solllänge: [sprintf,%.1f,_3] km", $#{$ways}+1, $l_total, $relDistance);
   print "\n  ", $s, "\n\n";
}
sub setHtmlFileName{
   my $self = shift;
   my $fileName = shift;

   open ($fh, ">$fileName") or die $LH->maketext("Fehler beim Öffnen der HTML-Datei:")." $fileName $!\n";
   print $fh <<EOF;
<!DOCTYPE html>
<html>
<head>
   <meta charset="utf-8" />
   <title></title>
<style type="text/css">
table {
   border-width: 1px 1px 1px 1px;
   border-spacing: 1px;
   border-style: outset outset outset outset;
   border-color: gray gray gray gray;
   border-collapse: collapse;
   background-color: white;
}
th {
   border-width: 1px 1px 1px 1px;
   padding: 2px 2px 2px 2px;
   border-style: inset inset inset inset;
   border-color: gray gray gray gray;
   background-color: white;
   -moz-border-radius: 0px 0px 0px 0px;
}
td {
   border-width: 1px 1px 1px 1px;
   padding: 2px 2px 2px 2px;
   border-style: inset inset inset inset;
   border-color: gray gray gray gray;
   background-color: white;
   -moz-border-radius: 0px 0px 0px 0px;
}
p.error {
   color: red;
}
p.warning {
   color: fuchsia;
}
</style>
</head>
<body>
EOF
}
sub printStatisticsHtml{
   my $self = shift;
   my $relId = shift;
   my $relName = shift;
   my $relDistance = shift;
   my $wayList = $_[0];
   my ($i, $n, $d);
   my $p1 = new XML::Parser(Style => 'Objects');

   print ($fh "<h2>$relId - $relName</h2>\n");
   if ($incompleteData > 0){
      print $fh '<p class="warning">',$LH->maketext("Warnung: [quant,_1,Weg/Knoten,Wege/Knoten] der Relation wurden nicht in den Daten gefunden.",$incompleteData),'</p>';
      $incompleteData = 0;
   }
   print ($fh "<table>\n");
   print $fh "<tr><th>Segment</th><th>",$LH->maketext("Knoten"),"</th><th>",$LH->maketext("Länge (km)"),"</th><th>",
            $LH->maketext("Entfernung zum nächst.Segm.(km)"),"</th><th>",$LH->maketext("Josm Remote Control"),"</th></tr>";

   my $l_total = 0;
   for ($i=0; $i <= $#{$wayList}; $i++) {
      if ($i < $#{$wayList}){
         $n = $i+1;
      }else{
         $n = 0;
      }
      my $l = $$wayList[$i]->length;
      $l_total += $l;
      $d = osmWay->distanceWays($$wayList[$i],$$wayList[$n], "EA");
      my $way1 = $$wayList[$i];
      my $way2 = $$wayList[$n];
      my $idLast = $way1->wayId($way1->ways-1);
      my $idFirst = $way2->wayId(0);
      my $pos = (index($idLast, "_"));
      if ($pos >= 0){
         $idLast = substr($idLast,0,$pos);
      }
      $pos = (index($idFirst, "_"));
      if ($pos >= 0){
         $idFirst = substr($idFirst,0,$pos);
      }
      my $off = 0.005;
      if (not $wayMaxLat{$idLast} or not $wayMaxLat{$idFirst}){
         die $LH->maketext("Programmfehler"),"\n"
      }
      my $top = max($wayMaxLat{$idLast}, $wayMaxLat{$idFirst}) + $off;
      my $bottom = min($wayMinLat{$idLast}, $wayMinLat{$idFirst}) - $off;
      my $left = min($wayMinLon{$idLast}, $wayMinLon{$idFirst}) - $off;
      my $right  = max($wayMaxLon{$idLast}, $wayMaxLon{$idFirst}) + $off;
      #my $josmLinkBeg = sprintf '<a href="http://127.0.0.1:8111/load_and_zoom?left=%f&right=%f&top=%f&bottom=%f&select=node%d" target="relanamap">Anfang</a>',
      #                       $way1->lon(0)-0.001, $way1->lon(0)+0.001, $way1->lat(0)+0.001, $way1->lat(0)+0.001, $way1->nid(0);
      my $josmLinkBeg = sprintf '<a href="http://127.0.0.1:8111/load_and_zoom?left=%f&right=%f&top=%f&bottom=%f&select=way%s" target="relanamap">Anfang</a>',
                             $way1->lon(0)-$off, $way1->lon(0)+$off, $way1->lat(0)+$off, $way1->lat(0)-$off,
                             $way1->wayId(0);
      my $josmLinkEnd = sprintf '<a href="http://127.0.0.1:8111/load_and_zoom?left=%f&right=%f&top=%f&bottom=%f&select=way%s" target="relanamap">Ende</a>',
                             $way1->lon($way1->nodes-1)-$off, $way1->lon($way1->nodes-1)+$off, $way1->lat($way1->nodes-1)+$off, $way1->lat($way1->nodes-1)-$off,
                             $idLast;
      my $josmLinkGap = "";
#      if ($d < 1){
#         $josmLinkGap = sprintf '<a href="http://127.0.0.1:8111/load_and_zoom?left=%f&right=%f&top=%f&bottom=%f&select=way%d,way%d" target="relanamap">Lücke</a>',
#                                 $left, $right, $top, $bottom, $idLast, $idFirst;
#      }
      printf $fh "<tr><td align='center'>%d</td><td align='center'>%d</td><td align='right'>%8.3f</td>", $i+1, $way1->nodes, $l;
      if ($i < $#{$wayList}){
         printf ($fh "<td align='right'>%8.3f</td>", $d);
      }else{
         print ($fh "<td align='right'></td>");
      }
      if ($i == $#{$wayList}){
         #$josmLink = "";
      }
      printf ($fh "<td align='center'>%s %s %s</td></tr>\n", $josmLinkBeg, $josmLinkEnd, $josmLinkGap);
   }
   print ($fh "</table><br>\n");
   my $s = $LH->maketext("Segmente: [sprintf,%3d,_1] Länge: [sprintf,%6.1f,_2] km Solllänge: [sprintf,%6.1f,_3] km", $#{$wayList}+1, $l_total, $relDistance);
   print ($fh $s);

   print ($fh "<br><br>");

   my $wt = 0;
   if ($#warnings>=0){
      print ($fh "<table>\n");
      print ($fh "<h3>",$LH->maketext("Hinweise und Warnungen"),"</h3>\n");
      print ($fh "<tr><th>",$LH->maketext("Warnung"),"</th><th>",$LH->maketext("Objekte"),"</th><th>",$LH->maketext("Josm Remote Control"),"</th></tr>");
      $wt = 1;
   }
   for ($i=0; $i<=$#warnings; $i++){
      $s = $warnings[$i][0];
      for (my $j=$i; $j<=$#warnings; $j++){
         my $w = $warnings[$j];
         if ($s eq $w->[0]){
            print ($fh "<tr><td>",$s,"</td><td>");
            my $maxtop=-1;
            my $minbottom=999;
            my $minleft=999;
            my $maxright=-1;
            my $josmLink = '<a href="http://127.0.0.1:8111/load_and_zoom?';
            for (my $k=1; $k<=$#{$w}; $k+=2){
               my $type = $w->[$k];
               my $id = $w->[$k+1];
               if ($k == 1) {
                  $josmLink .= "select=";
               }else{
                  $josmLink .= ",";
               }
               $josmLink .= sprintf "%s%d", $type, $id;
               print ($fh "$type $id ");
               if ($type eq "node"){
                  if (exists $nodeLat{$id}){
                     $minbottom = min($minbottom, $nodeLat{$id});
                     $maxtop = max($maxtop, $nodeLat{$id});
                     $minleft = min($minleft, $nodeLon{$id});
                     $maxright = max($maxright, $nodeLon{$id});
                  }
               }elsif ($type eq "way"){
                  if (exists $wayMinLat{$id}){
                     $minbottom = min($minbottom, $wayMinLat{$id});
                     $maxtop = max($maxtop, $wayMaxLat{$id});
                     $minleft = min($minleft, $wayMinLon{$id});
                     $maxright = max($maxright, $wayMaxLon{$id});
                  }
               }
            }
            if ($maxtop >= 0){
               $josmLink .= sprintf '?left=%f&right=%f&top=%f&bottom=%f" target="relanamap">JOSM</a>',
                              $minleft-0.001, $maxright+0.001, $maxtop+0.001, $minbottom-0.001;
            }else{
               $josmLink = "";
            }
            print $fh "</td><td align='center'>",$josmLink,"</td></tr>";
            #print ($fh "<br>");
            splice @warnings, $j, 1;
            $j--;
         }
      }
      $i--;
   }
   if ($wt){
      print ($fh "</table><br>\n");
   }
   @warnings = ();
}
sub warningMsg{
      my $self = shift;
      my @msgData = @_;

      push @warnings, [@msgData];
}
sub errorMsg{
      my $self = shift;
      my $msg = shift;

}
sub warningIncompleteData{
      my $self = shift;

      $incompleteData++;
}
sub closeHtml{
   my $self = shift;

   print $fh  <<EOF;
</body>
</html>
EOF
   close $fh;
}
#======================================================================
package gpxOutput;
#======================================================================

sub write{
   my $self = shift;
   my $relId = shift;
   #my $idx = shift;
   my $fn = shift;
   my $chains = shift;
   
   print STDERR "Ausgabe in GPX-Datei: $fn\n";
   
   $fn =~ s#/#_#g;
   open (OUTFILE, ">$fn") or die "Can't open $fn for writing: $!\n";
   print OUTFILE <<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<gpx
version="1.0"
creator="rel2gpx"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.topografix.com/GPX/1/0"
xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
EOF
   print OUTFILE "<bounds minlat='",osmWay->minlat,"' minlon='",osmWay->minlon,
                      "' maxlat='",osmWay->maxlat,"' maxlon='", osmWay->maxlon, "'/>\n";

   for (my $i = 0; $i <= $#{$chains}; $i++){
      my $ways = $chains->[$i]->{WAYS};
      for (my $j = 0; $j <= $#{$ways}; $j++){
         my $way = $ways->[$j];
         my $trkName = "";
         if ($#{$chains} > 0){
            $trkName = sprintf("%s_%03d_%03d",$relId,$i,$j+1);
         }else{
            if ($#{$ways}>0){
               $trkName = sprintf("%s_%03d",$relId,$j+1);
            }else{
               $trkName = $relId;
            }
         }
         if ($debug >= main::DEBUG_LOW){
            $trkName .= "_".$way->id;
         }
         if ($way->isOneway){
            $trkName .= "_Oneway";
         }
         print OUTFILE "<trk>\n<name>".$trkName."</name>\n<trkseg>\n";
         for (my $k = 0; $k < $way->nodes; $k++){
            my $lat = $way->lat($k);
            my $lon = $way->lon($k);
            print OUTFILE "<trkpt lat='$lat' lon='$lon'/>\n";
         }
         print OUTFILE "</trkseg>\n</trk>\n";
      }
   }
   print OUTFILE "</gpx>\n";
   close OUTFILE;
}
#************************************************************************
package main;
#************************************************************************
   #use Data::Dumper;
   use English;
   use LWP::Simple;
   use Getopt::Std;
   use OSM::osm;
   #use Benchmark;
   use Encode;

sub VERSION_MESSAGE{
   print $version."\n";
   exit;
}

sub HELP_MESSAGE{
   print $LH->maketext('_USAGE_MESSAGE', $PROGRAM_NAME),"\n";
   exit -1;
}

#======================================================================
sub bsearch {
#======================================================================
    my ($array, $val) = @_;
    my $low = 0;
    my $high = @$array - 1;

    while ( $low <= $high ) {
        my $try = int( ($low+$high) / 2 );
        $low  = $try+1, next if $array->[$try] < $val;
        $high = $try-1, next if $array->[$try] > $val;
        return $try;
    }
    return -1;
}

#======================================================================
sub getMembers{
#======================================================================
   my $osmFile = shift;
   my $relId = shift;
   my ($i, $r, $url, $rel, $member, $seg, $dummy);
   my ($members);
   my $parsedXml;
   my $p1 = new XML::Parser(Style => 'Objects');

   my $relRef = "";
   my $relName = "$relId";
   my $relDistance = 0;

   my @wayList = ();
   my @wayList1 = ();

   if ($osmFile eq ""){
      # Daten über API holen
      $url="http://www.openstreetmap.org/api/0.6/relation/$relId";
      $rel=get($url);
      if (!defined($rel)){
         print "\n  ",$LH->maketext("Fehler beim Lesen von [_1], Abbruch", $url),"\n";
         @wayList = ();
         return (-1, "", "", @wayList);
      }
      #$XMLFILE=new IO::Scalar \$rel;
      $parsedXml=$p1->parse($rel);
      my $first=@{$parsedXml}[0]->{'Kids'};         # get first element of array
      $members=@{$first}[1]->{'Kids'};
      $relXml{$relId} = $rel;
      #close $XMLFILE;
   }else{
      # Intern gepufferte XML-Daten verwenden
      if (!exists($relXml{$relId})){
          return (-1, -1, -1, -1);
      }else{
         $rel = $relXml{$relId};
         #$XMLFILE=new IO::Scalar \$rel;
         $parsedXml=$p1->parse($rel, ProtocolEncoding => 'UTF-8');
         $members=@{$parsedXml}[0]->{'Kids'};         # get first element of array
         #close $XMLFILE;
      }
   }
   $relRef = $relId;
   # Parse members
   my $c = 0;
   foreach $member (@{$members}) {
      #if ($c > 10) { last};
      if ($member->isa('main::member')){
         if ($member->{'type'} eq "way"){;
            $seg = osmWay->new ($member->{'ref'});
            if (exists($member->{'role'})){
               $seg->setRole($member->{'role'});
            }
            push @wayList, $seg;
            $c++;
         }elsif ($member->{'type'} eq "relation"){;
            # geschachtelte Relation
            print STDERR "\t",$LH->maketext("Sub-Relation:")," $member->{'ref'}\n";
            ($i, $dummy, $dummy, $dummy, @wayList1) = getMembers($osmFile, $member->{'ref'});
            if ($i >= 0){
               @wayList = (@wayList, @wayList1);
            }
         }elsif ($member->{'type'} eq "node"){;
            print "  ",$LH->maketext("Warnung: Relation enthält Knoten Ref=[_1]",$member->{'ref'}),"\n";
            statOutput->warningMsg($LH->maketext("Relation enthält Knoten"), "node", $member->{'ref'});
         }else{
            print "  ",$LH->maketext("Fehler: Member ist kein Weg, Typ=[_1] Ref=[_2]",$member->{'type'}, $member->{'ref'}), "\n";
            statOutput->warningMsg($LH->maketext("Member ist kein Weg"), $member->{'type'}, $member->{'ref'});
         }
      }elsif ($member->isa('main::tag')){
         if ($member->{'k'} eq 'ref'){
            $relRef = $member->{'v'};
            $relRef = encode_utf8( $relRef );
         }elsif ($member->{'k'} eq 'name'){
            $relName = $member->{'v'};
            $relName = encode_utf8( $relName );
         }elsif ($member->{'k'} eq 'distance'){
            my $v = $member->{'v'};
            my @a = split / /, $v;
            $relDistance = $a[0];
         }
      }
   }
   return ($relId, $relName, $relRef, $relDistance, @wayList);
}
#======================================================================
sub loadOsm{
#======================================================================
   my ($i, $found, $id, $xml, $members, $member, $dummy);
   my (@wayList, @nodeList);
   my $cnt=0;
   my $refRelList = $_[1];
   my $routeType = $_[2];
   my @relList = @$refRelList;
   my $parsedXml;
   my $p1 = new XML::Parser(Style => 'Objects');
   #--------------------------------------------------
   # Relationen
   #--------------------------------------------------
   if ($routeType eq -1){
      # Liste abarbeiten
      my $n = 0;
      do{
         $n++;
         print STDERR "\n", $LH->maketext("Durchlauf [_1]...", $n), "\n";
         $found = 0;
         openOsmFile ($_[0]) ;
         print STDERR " ",$LH->maketext("Knoten überspringen..."), "\n";
         skipNodes();
         print STDERR " ",$LH->maketext("Wege überspringen..."), "\n";
         skipWays();
         $cnt=0;
         my @relListSorted = sort {$a <=> $b} @relList;
         do{
            if ($cnt%100 == 0){
               print STDERR "\r ",$LH->maketext("Relationen lesen..."),sprintf("%8d",$#relListSorted);
            }
            $cnt++;
            ($id, $xml) = getRelationXml ();
            if ($debug >= DEBUG_MEDIUM){print " rel: $id\n"};
            my $i = bsearch(\@relListSorted, $id);
            if ($i >= 0){
               $found = 1;
               splice(@relListSorted, $i, 1);
               $parsedXml=$p1->parse($xml);
               $relXml{$id} = $xml;
               $members=@{$parsedXml}[0]->{'Kids'};
               foreach $member (@{$members}) {
                  if ($member->isa('main::member')){
                     if ($member->{'type'} eq "way"){
                        push @wayList, $member->{'ref'};
                     }elsif ($member->{'type'} eq "node"){
                        push @nodeList, $member->{'ref'};
                     }elsif ($member->{'type'} eq "relation"){
                        # geschachtelte Relation
                        push @relListSorted, $member->{'ref'};
                     }
                  }
               }
               @relList = @relListSorted;
               @relListSorted = sort {$a <=> $b} @relList;
            }
         } while ($id != -1 && $#relListSorted >= 0);
         closeOsmFile();
      }while ($#relList > 0 && $found != 0);
   }else{
      # Selektion nach Route-Typ
      openOsmFile ($_[0]) ;
      print STDERR " ",$LH->maketext("Knoten überspringen..."), "\n";
      skipNodes();
      print STDERR " ",$LH->maketext("Wege überspringen..."), "\n";
      skipWays();
      print STDERR " ",$LH->maketext("Relationen mit type=\"route\" und route=\"[_1]\" lesen...", $routeType), "\n";
      do{
         if ($cnt%100 == 0){
         }
         $cnt++;
         ($id, $xml) = getRelationXml () ;
         my $isRoute = 0;
         my $typeOk = 0;
         my $name = "";
         if ($id >= 0){
            my @wayListRel = ();
            my @nodeListRel = ();
            $parsedXml=$p1->parse($xml);
            $members=@{$parsedXml}[0]->{'Kids'};
            foreach $member (@{$members}) {
               if ($member->isa('main::member')){
                  if ($member->{'type'} eq "way"){
                     push @wayListRel, $member->{'ref'};
                  }elsif ($member->{'type'} eq "node"){
                     push @nodeListRel, $member->{'ref'};
                  }
               }elsif ($member->isa('main::tag')){
                  if ($member->{'k'} eq 'type' and $member->{'v'} eq 'route'){
                     $isRoute = 1;
                  }elsif ($member->{'k'} eq 'name'){
                     $name = encode_utf8($member->{'v'});
                 }elsif ($member->{'k'} eq 'route' and $member->{'v'} eq $routeType){
                     $typeOk = 1;
                  }
               }
            }
            if ($typeOk){
               $relXml{$id} = $xml;
               push @$refRelList, $id;
               @wayList = (@wayList, @wayListRel);
               @nodeList = (@nodeList, @nodeListRel);
               print STDERR "  ",$LH->maketext("[_1]-Route gefunden: [_2] [_3]", $routeType, $id, $name), "\n";
            }
         }
      } while ($id >= 0);
    }
   #--------------------------------------------------
   # Ways
   #--------------------------------------------------
   openOsmFile ($_[0]) ;
   print STDERR "\n ", $LH->maketext("Knoten überspringen..."), "\n";
   skipNodes();
   $cnt = 0;
   my @wayListSorted = sort {$a <=> $b} @wayList;
   for ($i=1; $i<=$#wayListSorted; $i++){
      if ($wayListSorted[$i] == $wayListSorted[$i-1]){
         splice(@wayListSorted, $i, 1);
         $i--;
      }
   }
   #my $t0 = Benchmark->new;
   do{
      if ($cnt%997 == 0){
         print STDERR "\r ", $LH->maketext("Wege lesen..."), sprintf("%9d",$#wayListSorted+1);
      }
      $cnt++;
      ($id, $xml) = getWayXml () ;
      #print "$id\n";
      my $i = bsearch(\@wayListSorted, $id);
      if ($i >= 0){
         #print "  $id $xml\n";
         splice(@wayListSorted, $i, 1);
         $parsedXml=$p1->parse($xml);
         $wayXml{$id} = $xml;
         $members=@{$parsedXml}[0]->{'Kids'};
         foreach $member (@{$members}) {
            if ($member->isa('main::nd')){
               push @nodeList, $member->{'ref'};
               #print "    $member->{'ref'}\n";
            }
         }
      }
   } while ($id != -1 && $#wayListSorted >= 0);
   print STDERR "\r ", $LH->maketext("Wege lesen..."), sprintf("%9d",$#wayListSorted+1);
   #my $t1 = Benchmark->new; my $td = timediff($t1, $t0); print STDERR "\nthe code took:",timestr($td),"\n";

   closeOsmFile();
   print STDERR "\n";
   #-------------------------------------------------------
   # Nodes
   #-------------------------------------------------------
   $cnt = 0;
   my @nodeListSorted = sort {$a <=> $b} @nodeList;
   for ($i=1; $i<=$#nodeListSorted; $i++){
      if ($nodeListSorted[$i] == $nodeListSorted[$i-1]){
         splice(@nodeListSorted, $i, 1);
         $i--;
      }
   }
   openOsmFile ($_[0]) ;
   #$t0 = Benchmark->new;
   do{
      if ($cnt%997 == 0){
         print STDERR "\r ", $LH->maketext("Knoten lesen..."), sprintf("%9d",$#nodeListSorted+1);
      }
      $cnt++;
      ($id, $xml) = getNodeXml () ;
      #print $id."\n";
      my $i = bsearch(\@nodeListSorted, $id);
      if ($i >= 0){
         #print "  $id\n";
         splice(@nodeListSorted, $i, 1);
         $parsedXml=$p1->parse($xml);
         $nodeXml{$id} = $xml;
         $members=@{$parsedXml}[0]->{'Kids'};
      }
   } while ($id != -1 && $#nodeListSorted >= 0);
   print STDERR "\r ", $LH->maketext("Knoten lesen..."), sprintf("%9d",$#nodeListSorted+1);
   #$t1 = Benchmark->new; $td= timediff($t1, $t0); print STDERR "\nthe code took:",timestr($td),"\n";
   print STDERR "\n";
   closeOsmFile();
}

#*********************************************************************************
# main
#*********************************************************************************
   my ($fn, $relName, $relRef);
   my ($way, $way1, $way2);
   my ($i, $j, $c, $i1, $i2, $n, $d);
   my ($members, $connectionType, $id);
   my ($join);
   my ($relId, $relDistance);
   my %option;
#------------------------------------------------------------------------------
# language handle
#------------------------------------------------------------------------------
   $LH = I18N->get_handle() || die "Can't get a language handle!";
#------------------------------------------------------------------------------
# Get options
#-------------------------------------------------------------------------------
   if (!getopts("ohgpszd:wi:f:x:r:", \%option)){
      HELP_MESSAGE();
   }

   if($option{h}) {
      HELP_MESSAGE();
      exit;
   }

   if($option{d}){
      $debug=$option{d};
   }

   # Option "-i"
   my $osmSource = "";     # leer = API, sonst lokale Datei
   if(exists($option{i})){
      if (!$option{i}){
         HELP_MESSAGE();
      }
      $osmSource = $option{i};
   }   # Option "-i"

   my $routeType = "";
   if($option{r}){
      if (!$option{i}){
         print STDERR $LH->maketext("Option -r wird nur zusammen mit Option -i unterstützt", "\n");
         HELP_MESSAGE();
      }
      $routeType = $option{r};
      if ($option{f}){
         print STDERR $LH->maketext("Option -r und Option -f nicht zusammen möglich", "\n");
         HELP_MESSAGE();
      }
      if ($#ARGV >= 0){
         HELP_MESSAGE();
      }
   }

   # Option "-x"
   if (!$option{i}){
      if ($option{x}){
         print STDERR $LH->maketext("Option -x wird nur zusammen mit Option -i unterstützt"), "\n";
         HELP_MESSAGE();
      }
      if ($option{z}){
         print STDERR $LH->maketext("Option -z wird nur zusammen mit Option -i unterstützt"), "\n";
         HELP_MESSAGE();
      }
   }

   # Option "-f"
   my @relList = ();
   if(not $option{i} and $option{f}){
      print STDERR $LH->maketext("Option -f wird nur zusammen mit Option -i unterstützt"), "\n";
      HELP_MESSAGE();
   }
   if($option{f} or $option{r}){
      if ($#ARGV >= 0){
         print STDERR $LH->maketext("Angabe einer Relations-ID bei Option -f und -r nicht zulässig"), "\n";
         HELP_MESSAGE();
      }
      if ($option{f}){
         my $infile = $option{f};
         open (INFILE, "<$option{f}") or die $LH->maketext("Datei [_1] kann nicht geöffnet werden"), $option{f}, "\n";
         my $relId;
         while (my $line = <INFILE>){
            if (not ($line =~ /^[\s]*#/) and not ($line =~ /^\s*$/)){
               ($relId) = ($line =~ /[\s]*([\d]*)[\s#]*/);
               if ($relId ne ""){
                  push @relList, $relId;
               }else{
                  print $LH->maketext("Warnung: Relations-Id [_1] enthält nichtnumerische Zeichen", $relId), "\n";
               }
            }
         }
      }
   }else{
      if ($#ARGV != 0){
         print STDERR $LH->maketext("Option -f oder -r oder eine Relations-ID muss angegeben werden"), "\n";
         HELP_MESSAGE();
      }
      $relId=$ARGV[0];
      push @relList, $relId;
   }
   # Option "-o"
   if (not $option{o}){
      osmWay->disableOneway;
      segChain->disableOneway;
   }

   if (not ($option{x} or $option{z} or $option{g} or $option{p} or $option{s}))  {
      print STDERR $LH->maketext("Mindestens eine der Optionen -x, -z, -g, -p oder -s muss angegeben werden"), "\n";
      HELP_MESSAGE();
   }

   select STDERR; $| = 1; # make unbuffered 
   select STDOUT; $| = 1; # make unbuffered

   statOutput->new;
   if ($option{w} and ($option{f} or $option{r})){
      # Ausgabe in HTML-Datei
      my $fn1;
      if ($option{f}){
         $fn1 = $option{f};
      }elsif($option{f} or $option{i}){
         $fn1 = $option{i};
      }else{
          $fn1 = $option{r};
      }
      $i = rindex $fn1, ".";
      if ($i > 0){
         $fn1 = substr($fn1, 0, $i);
      }
      $i = rindex $fn1, "/";
      if ($i > 0){
         $fn1 = substr($fn1, $i+1);
      }
      $fn1 .= ".html";
      statOutput->setHtmlFileName($fn1);
   }

   if ($option{i}){
      if ($option{r}){
         loadOsm($osmSource, \@relList, $option{r});
      }else{
         loadOsm($osmSource, \@relList, -1);
      }
   }
   #-------------------------------------------------------------------------
   if($option{x}){
      my ($xmlOut, $xml);
      my $line;
      open ($xmlOut, ">$option{x}") or die $LH->maketext("Datei [_1] kann nicht zum Schreiben geöffnet werden", $option{x}), "\n";
      print $LH->maketext("Ausgabe in OSM-Datei [_1]", $option{x}),"\n";
      print $xmlOut '<?xml version="1.0" encoding="UTF-8"?>',"\n";
      print $xmlOut '<osm version="0.6" generator="rel2gpx">',"\n";
      my @keys = sort { $a <=> $b } keys %nodeXml;
      foreach my $key (@keys){
         print $xmlOut "$nodeXml{$key}";
      }
      @keys = sort { $a <=> $b } keys %wayXml;
      foreach my $key (@keys){
         print $xmlOut "$wayXml{$key}";
      }
      @keys = sort { $a <=> $b } keys %relXml;
      foreach my $key (@keys){
         print $xmlOut "$relXml{$key}";
      }
      print $xmlOut "</osm>\n";
      close $xmlOut;
   }
   my $relCnt = 0;
   my @wayList=();
   foreach $relId (@relList){
      print "\n",$LH->maketext("Relation:"), " $relId\n";
      #----------------------------------------------------------
      # Lese Wege der Relation ein:
      #----------------------------------------------------------
      ($i, $relName, $relRef, $relDistance, @wayList) = getMembers($osmSource, $relId);
      if ($i == -1){
         print "  ", $LH->maketext("Fehler: Relation [_1] existiert nicht", $relId), "\n";
         next;
      }
      # according to http://wiki.openstreetmap.org/wiki/Walking_Routes:
      # Given including a unit and with a dot for decimals. (e.g. "12.5km")
      if ($relDistance =~ /^([.\d]+)\s*km/) {
         $relDistance = $1;
      }
      print $LH->maketext("Name:"),"     $relName\n";
      print $LH->maketext("Ref: "),"     $relRef\n";
      print $LH->maketext("Dist:"),"     ${relDistance}km\n";
      print "\n";
      $fn = $relName;
      $fn =~ tr/ /_/;
      if ($option{w} and !$option{f} and !$option{r}){
         statOutput->setHtmlFileName($fn.".html");
      }
      if ($#wayList < 0){
         print "  ", $LH->maketext("Fehler: Relation enthält keine Wege"), "\n";
         statOutput->errorMsg($LH->maketext("Fehler: Relation enthält keine Wege"));
         next;
      }
      #----------------------------------------------------------
      # Entferne Duplikate (Ways):
      #----------------------------------------------------------
      for ($i=0; $i<=$#wayList; $i++){
         for ($j=$i+1; $j<=$#wayList; $j++){
            if ($wayList[$i]->id == $wayList[$j]->id){
               if (($wayList[$i]->role eq "backward" and $wayList[$j]->role eq "forward") ||
                   ($wayList[$i]->role eq "forward" and $wayList[$j]->role eq "backward")){
                   # nicht schön, aber ok
                   $wayList[$i]->setRole("");
               }else{
                  print "  ", $LH->maketext("Warnung: Weg [_1] mehrfach in Relation enthalten", $wayList[$i]->id), "\n";
                  statOutput->warningMsg($LH->maketext("Weg mehrfach in Relation enthalten"), "way", $wayList[$i]->id);
                  $wayList[$j]->delete;
                  splice(@wayList, $j, 1);
                  $j--;
               }
            }
         }
      }
      # -------------------------------------------------------------
      # Download Way-Daten:
      # -------------------------------------------------------------
      for ($i=0; $i<=$#wayList; $i++) {
         $c = $i+1;
         my $m = $#wayList+1;
         print STDERR "\r", $LH->maketext("Hole Daten für Weg [sprintf,%3d,_1] von [_2]", $c, $m);
         $c = $wayList[$i]->download($osmSource);
         if ($c <= 0){
            $wayList[$i]->delete;
            splice (@wayList, $i, 1);
            $i--;
         }
      }
      printf STDERR "\n";
      for (my $i=0; $i<=$#wayList; $i++){
         my $way1 = $wayList[$i];
         # Wege mit nur einem Knoten:
         if ($#{$way1->{NID}} == 0){
            # Weg mit nur einem Knoten
            print "  ", $LH->maketext("Warnung: Weg mit nur einem Knoten [_1]", $way1->{ID}), "\n";
            statOutput->warningMsg($LH->maketext("Weg mit nur einem Knoten"), "way", $way1->{ID});
            splice @wayList, $i, 1;
         }
         # Entferne Duplikate (Knoten)
         for (my $j=0; $j<=$#{$way1->{NID}}; $j++){
            for (my $k=$j+1; $k<=$#{$way1->{NID}}; $k++){
               if ($way1->{NID}[$j] == $way1->{NID}[$k]){
                  if (not (($way1->isRoundabout or $way1->isArea) && $j == 0 && $k == $#{$way1->{NID}})){
                     print "  ", $LH->maketext("Warnung: Knoten [_1] mehrfach in Weg [_2] enthalten", $way1->{NID}[$j], $way1->{ID})," \n";
                     statOutput->warningMsg($LH->maketext("Knoten mehrfach in Weg enthalten"), "way", $way1->{ID}, "node", $way1->{NID}[$j]);
                  }
               }
            }
         }
      }
      # -------------------------------------------------------------
      # XML-Datei (pro Relation) erstellen:
      # -------------------------------------------------------------
      if($option{z}){
         my ($xmlOut);
         my $fnXml = "$fn.osm";
         print $LH->maketext("Ausgabe in OSM-Datei [_1]", $fnXml), "\n";

         open ($xmlOut, ">$fnXml") or die $LH->maketext("Datei [_1] kann nicht zum Schreiben geöffnet werden", $fnXml), "\n";
         print $xmlOut '<?xml version="1.0" encoding="UTF-8"?>',"\n";
         print $xmlOut '<osm version="0.6" generator="rel2gpx">',"\n";
         my @nodeIds = ();
         my @wayIds = ();
         for (my $j = 0; $j <= $#wayList; $j++){
            my $way = $wayList[$j];
            push @wayIds, $way->id;
            push @nodeIds, @{$way->{NID}};
         }
         my @ids = sort { $a <=> $b } @nodeIds;
         my $prevId = -1;
         foreach my $id (@ids){
            if ($id != $prevId){
               print $xmlOut "$nodeXml{$id}";
            }
            $prevId = $id;
         }
         @ids = sort { $a <=> $b } @wayIds;
         $prevId = -1;
         foreach my $id (@ids){
            if ($id != $prevId){
               print $xmlOut "$wayXml{$id}";
            }
            $prevId = $id;
        }
         print $xmlOut "$relXml{$relId}";
         print $xmlOut "</osm>\n";
         close $xmlOut;
      }
      #----------------------------------------------------------
      # Forward/Backward => Oneway:
      #----------------------------------------------------------
      if($option{g} or $option{s} or $option{w}){
         foreach $way (@wayList){
            if ($way->role eq "forward"){
               $way->setOneway(1);
            }elsif ($way->role eq "backward"){
               $way->setOneway(-1);
            }
            if ($way->isOneway() == -1){
               $way->reverse();
               $way->setOneway(1);
            }
         }
      }
      # -------------------------------------------------------------
      # Diverse Plausibilitätsprüfungen:
      # -------------------------------------------------------------
      if($option{p}) {
         print STDERR $LH->maketext("Prüfe Verlauf der Relation auf mögliche Fehler..."), "\n";
         for ($i = 0; $i <= $#wayList; $i++) {
            print STDERR "\r", $LH->maketext("Prüfe Weg [sprintf,%3d,_1] von [_2]", $i+1, $#wayList+1);
            $way1 = $wayList[$i];
            my @nids1 = $way1->nids;
            for ($j = $i+1; $j <= $#wayList; $j++) {
               $way2 = $wayList[$j];
               my @nids2 = $way2->nids;
               for (my $i1=0; $i1<=$#nids1; $i1++){
                  my $nid1 = $nids1[$i1];
                  for (my $i2=0; $i2<=$#nids2; $i2++){
                     my $nid2 = $nids2[$i2];
                     if ($nid1 == $nid2){
                        if ($i1 == 0 and ($i2==0 or $i2==$#nids2)){
                           # Anfangspunkt Weg1 = Anfangs/Endpunkt Weg2
                        }elsif ($i1 == $#nids1 and ($i2==0 or $i2==$#nids2)){
                           # Endpunkt Weg1 = Anfangs/Endpunkt Weg2
                        }elsif ($i1 == 0 or $i1==$#nids1){
                           # T-Kreuzung, Weg1 stösst auf Weg2
                           if (not $way2->isRoundabout){
                              if ($i1 == 0){
                                 print "\n  ", $LH->maketext("Warnung: Gabelung am Anfang von Weg [_1]",$way1->id)," \n";
                                 statOutput->warningMsg($LH->maketext("Gabelung "), "node", $way1->nid(0), "way", $way1->id, "way", $way2->id);
                              }else{
                                 print "\n  ",$LH->maketext("Warnung: Gabelung am Ende von Weg [_1]",$way1->id)," \n";
                                 statOutput->warningMsg($LH->maketext("Gabelung "), "node", $way1->nid($way1->nodes-1), "way", $way1->id, "way", $way2->id);
                              }
                           }
                        }elsif ($i2 == 0 or $i2==$#nids2){
                           # T-Kreuzung, Weg2 stösst auf Weg1
                           if  (not $way1->isRoundabout){
                              if ($i2 == 0){
                                 print "\n  ",$LH->maketext("Warnung: Gabelung am Anfang von Weg [_1]",$way2->id)," \n";
                                 statOutput->warningMsg($LH->maketext("Gabelung "), "node", $way2->nid(0), "way", $way1->id, "way", $way2->id);
                              }else{
                                 print "\n  ",$LH->maketext("Warnung: Gabelung am Ende von Weg [_1]",$way2->id)," \n";
                                 statOutput->warningMsg($LH->maketext("Gabelung "), "node", $way2->nid($way2->nodes-1), "way", $way1->id, "way", $way2->id);
                              }
                           }
                        }else{
                              print "\n  ",$LH->maketext("Warnung: Weg [_1] und [_2] kreuzen sich",$way1->id, $way2->id),"\n";
                              statOutput->warningMsg($LH->maketext("Wege kreuzen sich "),
                                                      "way", $way1->id, "way", $way2->id, "node", $nid1);
                        }
                     }
                  }
               }
            }
         }
         print STDERR "\n";
      }
      my @chains = ();
      if($option{g} or $option{s} or $option{w}){
         # -------------------------------------------------------------
         # Wandle Kreisverkehre in Strecken:
         # -------------------------------------------------------------
         for (my $i = 0; $i <= $#wayList; $i++) {
            my $roundabout = $wayList[$i];
            if ($roundabout->isRoundabout){
               my @intersections = ();
               for (my $j = 0; $j <= $#wayList; $j++) {
                  my $way = $wayList[$j];
                  if (!$way->isRoundabout){
                     for (my $k=0; $k < $roundabout->nodes; $k++){
                        if ($roundabout->nid($k) == $way->firstNid or
                           $roundabout->nid($k) == $way->lastNid){
                           push @intersections, $k;
                           last;
                        }
                     }
                  }
               }
               push @intersections, $roundabout->nodes-1;
               if ($#intersections > 0){
                  @intersections = sort {$a <=> $b} @intersections;
                  for (my $j=0; $j < $#intersections; $j++){
                     my $k = $intersections[$j];
                     if ($k > 0 and $k != $roundabout->nodes-1){
                        my $id = sprintf("%d_%02d", $roundabout->id, $j);
                        my $way = osmWay->new($id);
                        push @wayList, $way;
                        for (my $l=0; $l <=$k; $l++){
                           $way->addNode($roundabout->nid($l),
                                       $roundabout->lat($l),
                                       $roundabout->lon($l));
                        }
                        $way->setOneway(1);
                        $way->setRoundabout(1);
                        for (my $l=0; $l < $k; $l++){
                           $roundabout->removeNode(0);
                        }
                        for (my $l=$j; $l<=$#intersections; $l++){
                           $intersections[$l] -= $k;
                        }
                     }
                  }
                  #$roundabout->delete;
                  #splice @wayList, $i, 1;
               }
            }
         }
         # -------------------------------------------------------------
         # Überbrücke Areas:
         # -------------------------------------------------------------
         printf STDERR "\n", $LH->maketext("Behandle Areas..."), "\n";
         for (my $i = 0; $i <= $#wayList; $i++) {
            #if ($wayList[$i]->isArea or (not $option{o} and $wayList[$i]->isRoundabout)){
            if ($wayList[$i]->isArea){
               my $area = $wayList[$i];
               print "  ", $LH->maketext("Relation enthält Fläche (area) [_1]",$area->id),"\n";
               statOutput->warningMsg("Area", "way", $area->id);
               my @intersections = ();
               for (my $j = 0; $j <= $#wayList; $j++) {
                  my $way = $wayList[$j];
                  if (not $way->isRoundabout and not $way->isArea){
                     for (my $k=0; $k < $area->nodes; $k++){
                        if ($area->nid($k) == $way->firstNid or
                            $area->nid($k) == $way->lastNid){
                           push @intersections, $k;
                           last;
                        }
                     }
                  }
               }
               if ($#intersections >= 0){
                  for (my $j=0; $j < $#intersections; $j++){
                     for (my $k=$j+1; $k<=$#intersections; $k++){
                        my $id = sprintf("%s_%02d_%02d",$area->id,$j,$k);
                        my $wayNew = osmWay->new($id);
                        my $l = $intersections[$j];
                        $wayNew->addNode($area->nid($l),
                                         $area->lat($l),
                                         $area->lon($l));
                        $l = $intersections[$k];
                        $wayNew->addNode($area->nid($l),
                                         $area->lat($l),
                                         $area->lon($l));
                        push @wayList, $wayNew;
                     }
                  }
                  #$wayList[$i]->delete;
                  #splice @wayList, $i, 1;
               }
            }
         }
         # -------------------------------------------------------------
         # Fasse Kanten zusammen:
         # -------------------------------------------------------------
         printf STDERR $LH->maketext("Verbinde zusammenhängende Wege...")." %4d", $#wayList;;
         for ($i = 0; $i <= $#wayList; $i++) {
            $way1 = $wayList[$i];
            do {
               my ($cnt2, $wayA, $wayE, $t, $tA, $tE, $iA, $iE);
               $join = 0;
               my $cntA = 0;
               my $cntE = 0;
               for ($j = 0; $j <= $#wayList; $j++) {
                  if ($j != $i){
                     $way2 = $wayList[$j];
                     my @lTypes = $way1->checkLink($way2);
                     foreach my $type (@lTypes){
                        if (substr($type, 0, 1) eq "A"){
                           $cntA++;
                           if ($cntA == 1){
                              $wayA = $way2;
                              $iA = $j;
                              $tA = $type;
                           }
                        }else{
                           $cntE++;
                           if ($cntE == 1){
                              $wayE = $way2;
                              $iE = $j;
                              $tE = $type;
                           }
                        }
                     }
                  }
               }
               my $i2 = -1;
               if ($cntE == 1){
                  $way2 = $wayE;
                  $i2 = $iE;
                  $cnt2 = $cntE;
                  $t = $tE;
               }elsif ($cntA == 1){
                  $way2 = $wayA;
                  $i2 = $iA;
                  $cnt2 = $cntA;
                  $t = $tA;
               }
               if ($i2 >= 0){
                  my $join1 = 0;
                  if ($way1->isOneway){
                     if ($way2->isOneway){
                        if ($t eq "EA" or $t eq "AE"){
                           $join1 = 1;
                        }
                     }elsif ($cntA+$cntE == 2 and $wayA->isOneway and $wayE->isOneway and substr($tA,0,1) ne substr($tE,1)){
                        $join1 = 1;
                     }elsif ($cnt2 == 0){
                        $join1 = 1;
                     }
                  }elsif (not $way1->isOneway and not $way2->isOneway){
                     $join1 = 1;
                  }
                  if ($join1){
                     if ($debug>=DEBUG_MAX){
                        printf $LH->maketext("Verbinde [_1] mit [_2] [_3]", $way1->id, $way2->id, $t);
                        print "\n";
                     }else{
                        printf STDERR "\r", $LH->maketext("Verbinde zusammenhängende Wege...")." %4d", $#wayList;
                     }
                     osmWay->joinWays($way1, $way2, $t);
                     $wayList[$i2]->delete;
                     splice(@wayList, $i2, 1);
                     $join = 1;
                     if ($i2 <= $i){
                        $i--;
                     }
                  }
               }
            } while ($join == 1);
         }
         print STDERR "\n";
         # Wege verlinken
         for (my $i=0; $i<=$#wayList; $i++){
            $way1 = $wayList[$i];
            for (my $j=$i+1; $j<=$#wayList; $j++){
               $way2 = $wayList[$j];
               osmWay->linkWays($way1, $way2);
            }
         }
         if ($debug >= DEBUG_HIGH){
            osmWay->dumpLinks(\@wayList);
         }
   L0:
         osmWay->clearFlags;
         my $done = 1;
         do{
            my ($maxRoot, @maxSeg, $loop);
            $done = 1;
            my $maxLen = 0;
            foreach $way (@wayList){
               my (@seg, $len);
               if (not $way->{processed} and $#{$way->{PREV}} < 0){
                  if ($debug>=DEBUG_MEDIUM){print "Root ",$way->id,"\n"};
                  ($len, $loop, @seg) = $way->traverse(1, "A");
                  if ($len == -2){
                     goto NEXT;
                  }
                  if ($#seg >= 0 and $len >= 0){
                     if ($debug>=DEBUG_MEDIUM){
                        print "  ",$LH->maketext("Länge="), "$len\n";
                        foreach $way2 (@seg){
                           print "    ",$way2->id,"\n";
                        }
                     }
                     if ($len > $maxLen){
                        $maxLen = $len;
                        $maxRoot = $way;
                        @maxSeg = @seg;
                     }
                  }
               }
            }
            if ($maxLen > 0){
               foreach $way (@maxSeg){
                  $way->unlinkWay;
                  $way->{processed} = 1;
               }
               # Richtung der Wege korrigieren
               for (my $i=1; $i<=$#maxSeg; $i++){
                  my $way1 = $maxSeg[$i-1];
                  my $way2 = $maxSeg[$i];
                  if ($way1->lastNid ==$way2->lastNid ){
                     $way2->reverse;
                  }
               }
               push @chains, segChain->new(\@maxSeg);
               $done = 0;
            }
         } while (not $done);
         # Plausi-Check ???????????????????
         foreach my $way (@wayList){
            if ($way->{processed} == 0){
               my @seg = ($way);
               push @chains, segChain->new(\@seg);
            }
         }
         if ($debug>=DEBUG_HIGH){
            for ($i=0;$i<=$#chains;$i++){
               print STDERR "Chain $i:\n";
               $chains[$i]->dump;
            }
            print STDERR "Segmente -> temp.gpx\n";
            gpxOutput->write($relId, "temp.gpx", \@chains);
         }
         # -------------------------------------------------------------
         # Sortiere Segmente nach Entfernung:
         # -------------------------------------------------------------
         if ($debug>=DEBUG_HIGH){
               print STDERR "\nSuche Anfang...\n";
         }
         my $dmax = 0;
         my $iStart = -1;
         for (my $i=0; $i < $#chains; $i++) {
            for ($j = $i+1; $j <= $#chains; $j++) {
               my @types = ("EA", "EE", "AE", "AA");
               if ($chains[$i]->isOneway and $chains[$j]->isOneway){
                  @types = ("EA", "AE");
               }
               foreach my $connectionType (@types){
                  my $d = segChain->distance($chains[$i], $chains[$j], $connectionType);
                  if ($d > $dmax){
                     $dmax = $d;
                     if ($connectionType eq "EA" or $connectionType eq "AA"){
                        $iStart = $j;
                     }else{
                        $iStart = $i;
                     }
                  }
               }
            }
         }
         my $chainTmp = $chains[$iStart];
         if ($iStart >= 0){
            splice(@chains, $iStart, 1);
            @chains = ($chainTmp, @chains);
         }
         segChain->sort(\@chains, 1);
         # erstelle eine Kopie
         my @chainsCopy = ();
         for (my $i=0; $i <= $#chains; $i++) {
            for (my $j=0; $j <= $#{$chains[$i]->{WAYS}}; $j++){
               my @ways = ();
               my $newWay = $chains[$i]->{WAYS}[$j]->clone;
               push @ways, $newWay;
               push @chainsCopy, segChain->new(\@ways);
            }
         }
         if ($debug>=DEBUG_HIGH){
            for ($i=0;$i<=$#chains;$i++){
               print STDERR "Chain $i:\n";
               $chains[$i]->dump;
            }
            print STDERR "Segmente -> temp2.gpx\n";
            gpxOutput->write($relId, "temp2.gpx", \@chains);
         }
         # Fasse Teilstrecken zusammen (Wege):
         osmWay->joinWaysArray(\@{$chains[0]->{WAYS}});
         if ($#chains > 0){
            die "Programmfehler, Anzahl Chains > 0\n";
         }
         # -------------------------------------------------------------
         # GPX-Datei erstellen:
         # -------------------------------------------------------------
         if($option{g}) {
            my $fnGpx = "$fn.gpx";
            gpxOutput->write($relId, $fnGpx, \@chains);
         }
         # -------------------------------------------------------------
         # Statistiken:
         # -------------------------------------------------------------
         if ($option{w}){
            statOutput->printStatisticsHtml($relId,$relName, $relDistance, \@{$chains[0]->{WAYS}});
         }
         if($option{s}) {
            statOutput->printStatistics($relId,$relName, $relDistance, \@{$chains[0]->{WAYS}})
         }
         # -------------------------------------------------------------
         # zweite Fahrtrichtung
         # -------------------------------------------------------------
         if ($option{o}){
            print STDERR "\n", $LH->maketext("Bearbeite Gegenrichtung..."), "\n";
            if ($debug>=DEBUG_HIGH){
               print STDERR "Segmente -> temp3.gpx\n";
               gpxOutput->write($relId, "temp3.gpx", \@chainsCopy);
            }
#            my $roundaboutAtStart = -1;
#            for (my $i=0; $i<=$#chainsCopy; $i++){
#               my $way = $chainsCopy[$i]->{WAYS}[0];
#               if ($way->isRoundabout){
#                  $roundaboutAtStart++;
#               }else{
#                  last;
#               }
#            }
#            my $roundaboutAtEnd = $#chainsCopy+1;
#            for (my $i=$#chainsCopy; $i>=0; $i--){
#               my $way = $chainsCopy[$i]->{WAYS}[0];
#               if ($way->isRoundabout){
#                  $roundaboutAtEnd--;
#               }else{
#                  last;
#               }
#            }
            my $oneway = 0;
#            for (my $i=$roundaboutAtStart+1; $i<$roundaboutAtEnd; $i++){
            for (my $i=0; $i<$#chainsCopy; $i++){
               my $way1 = $chainsCopy[$i]->{WAYS}[0];
               my $swap = 0;
               if ($way1->isOneway){
                  $oneway = 1;
                  if ($i > 0){
                     $way2 = $chainsCopy[$i-1]->{WAYS}[0];
                     if ($way1->firstNid != $way2->lastNid){
                        $swap = 1;
                     }
                  }
                  if ($i < $#chainsCopy){
                     $way2 = $chainsCopy[$i+1]->{WAYS}[0];
                     if ($way2->firstNid != $way1->lastNid){
                        $swap = 1;
                     }
                  }
                  if ($swap){
                     push @chainsCopy, $chainsCopy[$i];
                     splice @chainsCopy, $i, 1;
                  }
               }
            }
            #if ($oneway){
               for (my $i=0; $i<=$#chainsCopy; $i++){
                  my $swap = 0;
                  my $way1 = $chainsCopy[$i]->{WAYS}[0];
                  if ($way1->isOneway){
                     $oneway = 1;
                     if ($i > 0){
                        $way2 = $chainsCopy[$i-1]->{WAYS}[0];
                        if ($way1->firstNid != $way2->lastNid){
                           $swap = 1;
                        }
                     }
                     if ($i < $#chainsCopy){
                        $way2 = $chainsCopy[$i+1]->{WAYS}[0];
                        if ($way2->firstNid != $way1->lastNid){
                           $swap = 1;
                        }
                     }
                     if ($swap){
                        unshift @chainsCopy, $chainsCopy[$i];
                        splice @chainsCopy, $i+1, 1;
                     }
                  }
               }
               for (my $i=0; $i<=$#chainsCopy; $i++){
                  my $way1 = $chainsCopy[$i]->{WAYS}[0];
                  if (not $way1->isOneway){
                     $way1->reverse;
                  }
               }
               @chainsCopy = reverse @chainsCopy;
               if ($debug>=DEBUG_HIGH){
                  gpxOutput->write($relId, "temp3.gpx", \@chainsCopy);
               }
               segChain->sort(\@chainsCopy, 0);
               # Fasse Teilstrecken zusammen (Wege):
               osmWay->joinWaysArray(\@{$chainsCopy[0]->{WAYS}});
               if ($#chainsCopy > 0){
                  die "Programmfehler, Anzahl Chains > 0\n";
               }
               # GPX-Datei erstellen:
               if($option{g}) {
                  my $fnGpx = $fn."_r.gpx";
                  gpxOutput->write($relId."R", $fnGpx, \@chainsCopy);
               }
               # Statistiken:
               #if ($option{w}){
               #   statOutput->printStatisticsHtml($relId,$relName, \@{$chains[0]->{WAYS}});
               #}
               if($option{s}) {
                  statOutput->printStatistics($relId,$relName, $relDistance, \@{$chains[0]->{WAYS}})
               }
            #}
         }
      }

NEXT:
      $relCnt++;
   } # foreach $relId

   if ($option{w} && $relCnt > 0){
      statOutput->closeHtml;
   }
########################################################################################################
# This is the project base class using Locale::Maketext;
########################################################################################################
BEGIN {
package I18N;
sub Locale::Maketext::DEBUG () {0}

use Locale::Maketext 1.01;
use base ('Locale::Maketext');
use vars qw(%Lexicon);
# I decree that this project's first language is English.

%Lexicon  = (
  '_AUTO' => 1,
  # That means that lookup failures can't happen -- if we get as far
  #  as looking for something in this lexicon, and we don't find it,
  #  then automagically set $Lexicon{$key} = $key, before possibly
  #  compiling it.

  # The exception is keys that start with "_" -- they aren't auto-makeable.

  '_USAGE_MESSAGE' => q{Aufruf: [_1] ~[OPTION~]... <relation>
Optionen:
   -i  datei  lese OSM-Daten aus lokaler Datei
   -x  datei  schreibe XML in Datei, eine Datei für alle Relationen (nur zusammen mit -i)
   -z         schreibe XML in Datei, eine Datei pro Relation (nur zusammen mit -i)
   -r  typ    bearbeite alle Relationen mit type=route und route=typ (nur zusammen mit -i)
   -f  datei  lese Relation-Ids aus Datei
   -o         berücksichtige Fahrtrichtung (oneway, forward/backward)
   -d  Level  Debug-Ausgaben aktivieren
   -g         GPX-Ausgabe aktivieren
   -p         Plausibilitätsprüfungen aktivieren
   -s         Statistikausgabe auf STDOUT aktivieren
   -w         Ausgabe Statistik und Warnungen aus Plausi-Prüfung in HTML-Datei
}
,


  # Any further entries...

);
# End of lexicon.
########################################################################################################
########################################################################################################
package I18N::i_default;
use base qw(I18N);
1;
package I18N::en;
use base qw(I18N);
1;

package I18N::en_us;
use base qw(I18N::en);
1;
package I18N::de_de;
use base qw(I18N);
1;
########################################################################################################
# French language messages
########################################################################################################
package I18N::fr;
use base qw(I18N);
use strict;
use vars qw(%Lexicon);
%Lexicon = (

"[_1]-Route gefunden: [_2] [_3]" =>
"route de type [_1]: [_2] [_3]",

"Angabe einer Relations-ID bei Option -f und -r nicht zulässig" =>
"id de relation incompatible avec options -f et -r",

"Ausgabe in OSM-Datei [_1]" =>
"écriture dans fichier OSM [_1]",

"Bearbeite Gegenrichtung..." =>
"traitement du sens inverse...",

"Behandle Areas..." =>
"traitement des areas...",

"Datei [_1] kann nicht zum Schreiben geöffnet werden" =>
"impossible d'ouvrir le fichier [_1]",

"Datei [_1] kann nicht zum Schreiben geöffnet werden" =>
"impossible d'ouvrir le fichier [_1] en écriture",

"Durchlauf [_1]..." =>
"passe [_1]...",

"Entfernung zum nächst.Segm.(km)" =>
"Distance au segment suivant (km)",

"Entf. zu Seg." =>
"Dist. au seg.",

"Fehler beim Lesen von [_1], Abbruch" =>
"Erreur sur lecture de [_1], arrêt",

"Fehler beim Öffnen der HTML-Datei:" =>
"impossible d'ouvrir le fichier HTML:",

"Fehler: Member ist kein Weg, Typ=[_1] Ref=[_2]" =>
"Erreur: membre n'est pas un chemin, type=[_1] ref=[_2]",

"Fehler: Relation [_1] existiert nicht" =>
"Erreur: la relation [_1] n'existe pas",

"Fehler: Relation enthält keine Wege" =>
"Erreur: la relation ne contient aucun chemin",

"Hinweise und Warnungen" =>
"Indications et avertissements",

"Hole Daten für Weg [sprintf,%3d,_1] von [_2]" =>
"lecture des données du chemin [sprintf,%3d,_1] sur [_2]",

"Knoten:" =>
"noeud:",

"Knoten lesen..." =>
"lecture les noeuds...",

"Knoten mehrfach in Weg enthalten" =>
"plusieurs instances du noeud dans le chemin",

"Knoten überspringen..." =>
"passer les noeuds...",

"Länge=" =>
"longueur=",

"Länge:" =>
"longueur:",

"Member ist kein Weg" =>
"membre n'est pas un chemin",

"Mindestens eine der Optionen -x, -z, -g, -p oder -s muss angegeben werden" =>
"Au moins un des options -x, -z, -g, -p ou -s est obligatoire",

"Name:" =>
"nom: ",

"Option -f oder -r oder eine Relations-ID muss angegeben werden" =>
"Une des options -f et -r ou une id de relation est obligatoire",

"Option -f wird nur zusammen mit Option -i unterstützt" =>
"l'option -f implique l'option -i",

"Option -r und Option -f nicht zusammen möglich" =>
"les options -r et -f s'excluent",

"Option -r wird nur zusammen mit Option -i unterstützt" =>
"l'option -r implique l'option -i",

"Option -x wird nur zusammen mit Option -i unterstützt" =>
"l'option -x implique l'option -i",

"Option -z wird nur zusammen mit Option -i unterstützt" =>
"l'option -z implique l'option -i",

"Programmfehler" =>
"erreur de programme",

"Prüfe Verlauf der Relation auf mögliche Fehler..." =>
"recherche d'anomalies dans la topologie de la relation...",

"Prüfe Weg [sprintf,%3d,_1] von [_2]" =>
"vérifie chemin [sprintf,%3d,_1] sur [_2]",

"[quant,_1,Segment,Segmente]  Länge: [sprintf,%.1f,_2] km" =>
"[quant,_1,segment,segments]  longueur: [sprintf,%.1f,_2] km",

"Ref:" =>
"réf:",

"Relationen lesen..." =>
"lecture des relations...",

"Relationen mit type=\"route\" und route=\"[_1]\" lesen..." =>
"lecture des relations avec type=\"route\" et route=\"[_1]\" ...",

"Relation enthält Fläche (area) [_1]" =>
"la relation contient une surface (area) [_1]",

"Relation enthält Knoten" =>
"la relation contient des noeuds",

"Relation:" =>
"relation:",

"Segmente: [sprintf,%3d,_1] Länge: [sprintf,%6.1f,_2] km Solllänge: [sprintf,%6.1f,_3] km" =>
"segments: [sprintf,%3d,_1] Länge: [sprintf,%6.1f,_2] km real length: [sprintf,%6.1f,_3] km",

"Segment" =>
"segment",

"Sortiere Segmente..." =>
"triage des segments...",

"Sub-Relation:" =>
"sous-relation:",

"Topologie der Relation zu komplex. Abbruch." =>
"La topologie de la relation est trop complexe. Arrêt du programme.",

"Verbinde [_1] mit [_2] [_3]" =>
"connecter [_1] avec [_2] [_3]",

"Verbinde zusammenhängende Wege..." =>
"connecter les chemins adjacents...",

"Warnung: Knoten [_1] mehrfach in Weg [_2] enthalten" =>
"Avertissement: le chemin [_2] contient plusieures instances du noeud [_1]",

"Warnung: Knoten [_1] (Weg [_2]) nicht in osm-Datei" =>
"Avertissement: le fichier osm ne contien pas le noeud [_1] (chemin [_2])",

"Warnung: [quant, _1, Weg/Knoten, Wege/Knoten] der Relation wurden nicht in den Daten gefunden." =>
"Avertissement: [quant, _1, chemin/noeud, chemins/noeuds] de la relation n'ont pas été trouvés dans les données OSM.",

"Warnung: Relation enthält Knoten Ref=[_1]" =>
"Avertissement: la relation contient le noeud [_1]",

"Warnung: Relations-Id [_1] enthält nichtnumerische Zeichen" =>
"Avertissement: l'id de la relation [_1] contient des caractères non-numeriques",

"Warnung" =>
"Avertissement",

"Warnung: Weg [_1] mehrfach in Relation enthalten" =>
"Avertissement: la relation contient plusieures instances du noeud [_1]",

"Warnung: Weg [_1] nicht in osm-Datei" =>
"Avertissement: le noeud [_1] n\'a pas été trouvé dans les données OSM",

"Warnung: Weg mit nur einem Knoten [_1]" =>
"Avertissement: chemin [_1] ne contient qu\'un seul noeud",

"Wege lesen..." =>
"lecture des chemins...",

"Wege überspringen..." =>
"passer les chemins...",

"Weg mehrfach in Relation enthalten" =>
"La relation contient plusieures instances du chemin",

"Weg mit nur einem Knoten" =>
"Chemin avec un seul noeud",

"Warnung: Gabelung am Anfang von Weg [_1]" =>
"Avertissement: Bifurcation au début du chemin [_1]",

"Gabelung "  =>
"Bifurcation ",

"Warnung: Gabelung am Ende von Weg [_1]"  =>
"Avertissement: Bifurcation à la fin du chemin [_1]",

"Warnung: Weg [_1] und [_2] kreuzen sich"  =>
"Avertissement: les chemins [_1] et [_2] se croisent",

"Wege kreuzen sich "  =>
"les chemins se croisent ",

  '_USAGE_MESSAGE' => q{Commande: [_1] ~[OPTION~]... <relation_id>
Options:
   -i  fichier lire les données OSM dans un fichier local
   -x  fichier écrire le code XML des relations dans un seul fichier pour toutes les relations (avec option -i)
   -z          écrire le code XML dans un fichier par relation (avec option -i)
   -r  type    traiter toutes les relations dy type route et attribut route=<type> (avec option -i)
   -f  fichier lire les identificateurs des relations à traiter dans un fichier
   -o          tenir compte de la direction des voies (oneway, forward/backward)
   -d  level   activer les messages de debug
   -g          création d'un fichier GPX
   -p          activer la vérification de plausibilité
   -s          activer les informations statistiques
   -w          créer un fichier HTML avec les statistiques et les messages de plausibilité
}
);
# fin de lexique.

1;  # fin de module.
}


