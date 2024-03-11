#!/usr/bin/perl -w
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#

use strict;

# values for hex conversion
my %h2v= ( '0'=>0, '1'=>1, '2'=>2, '3'=>3, 
           '4'=>4, '5'=>5, '6'=>6, '7'=>7, 
           '8'=>8, '9'=>9, 'A'=>10,'B'=>11, 
           'C'=>12,'D'=>13,'E'=>14,'F'=>15);
my %v2h= reverse %h2v;

my %m;   # hash for memory 

while (<>){                                       # read from stdin or first arg
  next if (/^\s*$/);                              # skip empty lines
  next unless (/^S3/);                            # only process 32 bit data lines
  s/^....//;                                      # delete the first four chars
  chomp;                                          # get rid of the newline
  s/\S\S\s*$//;                                   # and the last two chars

  my $addr=substr($_,0,8);                        # the first 8 are address
  my $aint=hex2int($addr);                        # the address as an integer
  my $data=substr($_,8,2);                        # the rest is data 
  $m{$aint}=$data;                                # write to mem hash
}

# go from 8 bit entries to 32 bit entries
my %m32; # hash for memory, 32 bit entries
my $prev_addr = 0;
foreach my $aint (sort keys %m) {
  my $data=$m{$aint};

  my $addr = ($aint/4) << 2;


  if (($addr - $prev_addr > 4) && ($addr % 8 != 0)) { # there was a hole and we are not aligned to 8bit anymore: need to insert padding
    $m32{$addr - 4} = "00000000";
  }

  my $prev="00000000";
  if (exists $m32{$addr}) {
      $prev=$m32{$addr};
  }

  my $byte0=substr($prev,0,2);
  my $byte1=substr($prev,2,2);
  my $byte2=substr($prev,4,2);
  my $byte3=substr($prev,6,2);

  use Switch;

  switch($aint % 4) {
      case 0 { $prev="${data}${byte1}${byte2}${byte3}" }
      case 1 { $prev="${byte0}${data}${byte2}${byte3}" }
      case 2 { $prev="${byte0}${byte1}${data}${byte3}" }
      case 3 { $prev="${byte0}${byte1}${byte2}${data}" }
  }

  $m32{$addr}=$prev;
  $prev_addr = $addr;
}

my @all=sort keys %m32;    # all addresses sorted

my $i =0;                  # our index counter
while ($i <= $#all){
 my $a=$all[$i];           # go through the addresses we have one by one 
 if ($a % 8 eq 4){         # the address is not aligned to 64
   $a=$a-4;                # go back one address 
   $i=$i+1;                # only increment the addresses by one
 }
 else{                     # address was properly aligned
  $i=$i+2;                 # the next one will be 64 bits (2 index values)
 }
  my $h=int2hex($a);       # determine the hex value for the address
  my $lo="00000000";       # default 0
  my $hi="00000000";       # default 0
  my $miss=0;              # miss count, we will skip output if two mem locations are not in S19
  
  if (exists($m32{$a}))  { $lo=swap_endian($m32{$a})}   else {$miss++};  # get the low value
  if (exists($m32{$a+4})){ $hi=swap_endian($m32{$a+4})} else {$miss++};  # get the high value
   
  print "${h}_${hi}${lo}\n" unless ($miss>1);           # print unless both are misses
}

#------------------------------------------------------------------------------
# Due to the great endian swap, something has to be done here as well 
#
# Read in the value, split into two character array, reverse the array and join it.
# 
sub swap_endian {
  my $d=shift;                                    # get parameter - assumed to be strings, even length..
  my @q=reverse(split('(\S\S)',$d));              # split and reverse into two character groups        
  my $retval = join('', @q);                      # now join again without any spaces in between       
  return $retval;                                 # return back a value                                
}

#------------------------------------------------------------------------------
# subroutine to convert from hex to integer, always big endian
#
# there should be an easier way.. 
#
sub hex2int {                                     

  my $h=shift;                                    # get the hex value
  my @d=split ('',$h);                            # split into chars
  my $i=0;                                        # initial value
  my $j=0;                                        # digit value
  foreach my $n (reverse @d){                     # traverse from reverse (LSB)
    $i = $i + ($h2v{$n}*(16 ** $j));              # add up the values
    $j++;                                         # increment digit count
  }
  return $i;                                      # return value
}

#------------------------------------------------------------------------------
# subroutine to convert from long integer to hex, always big endian
#
# there should be an easier way.. 
# only for 8 digits.. 
# 
sub int2hex {
  my $i=shift;                                    # read in the integer
  my $h;                                          # define hex value
  for my $n (0..7){                               # 8 digits
    my $e=16 ** (7-$n);                           # calculate exponent
    if ($e > $i){                                 # if 2^e is larger
       $h=$h."0";                                 # write 0 for the digit
    }
    else{                                         # now we have a non-zero 
       my $d= int ($i/$e);                        # divide
       $h=$h.$v2h{$d};                            # determine the hex value
       $i=$i - ($d* (16 ** (7-$n)));              # subtract from int
    }
  }
  return $h;                                      # return hex value
}

#------------------------------------------------------------------------------
# subroutine to pad a 64bit data chunk and swap the 32bits 
#
sub pad_data64 {
 my $data=shift;                                  # get data
 my $l=length($data);                             # determine length

 my $hi="";                                       # initial values
 my $lo="";                               
 if ($l <8){                                      # not even a full 32 bit
   $lo="0"x(8-$l).$data;                          # LS is padded with zeroes to the left
   $hi="00000000";                                # MS is all zeroes
 }
 elsif ($l <16){                                  # One 32 bit word complete, the other half full
   $lo=substr($data,0,8);                         # get the wirst 8 hex characters
   $hi="0"x(16-$l).substr($data,8);               # left append missing zeroes for the second one
 }
 else{                                            # exactly 64 bits, no padding, just swap
   $lo=substr($data,0,8);                         # LS 32 bit 
   $hi=substr($data,8,8);                         # MS 32 bit
 }
 my $ret=$hi.$lo;                                 # merge to one string
 return $ret;
}
