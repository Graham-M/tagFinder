#!/usr/bin/perl -w



use strict;
use AWS::CLIWrapper;
use Data::Dumper;

if (!defined($ENV{'AWS_ACCESS_KEY_ID'})){
    die "AWS_ACCESS_KEY_ID is not set, please set it (hint - 'export AWS_ACCESS_KEY_ID=<key>')\n";
}

if (!defined($ENV{'AWS_SECRET_ACCESS_KEY'})){
    die "AWS_SECRET_ACCESS_KEY is not set, please set it (hint - 'export AWS_SECRET_ACCESS_KEY=<key>')\n";
}

if (!defined($ENV{'AWS_DEFAULT_REGION'})){
    die "AWS_DEFAULT_REGION is not set, please set it (hint - 'export AWS_DEFAULT_REGION=eu-west-1')\n";
}

if (scalar(@ARGV) != 3){
    die "Usage $0 <with|without> <resource> <keyname>\n<resource> can be '<ec2|ebs|eip|elb>'\n";
}

my $condition;
my $restype;
my $tagtype;


if ( (!defined($ARGV[0])) || ($ARGV[0] !~ /(with|without)/)){
    die "<condition> needs to be 'with' or 'without'\n";  
} else {
    $condition = $ARGV[0];
}

if ( (!defined($ARGV[1])) || ($ARGV[1] !~ /(ec2|ebs|eip|elb)/) ){
    die "<resource> needs to be 'ec2', 'ebs', 'eip' or 'elb'\nAlthough, only ec2 and ebs actually work\n";  
} else {
    $restype = $ARGV[1];
}

if (!defined($ARGV[2])){
    die "<tag> needs to be an alphanumeric string\n";  
} else {
    $tagtype = $ARGV[2];
}

my $aws = AWS::CLIWrapper->new();

my @inlist;
my @outlist;

if ($restype eq "ec2"){
    find_ec2();
} elsif ($restype eq "ebs"){
    find_ebs();
} elsif ($restype eq "eip"){
    die "Error - not quite able to $restype yet \n";
    #find_eip();
} elsif ($restype eq "elb"){
    die "Error - not quite able to $restype yet \n";
    #find_elb();
}
   
sub find_ec2 {

    my $res = $aws->ec2('describe-instances');

    if ($res) {
        for my $rs ( @{ $res->{Reservations} }) {
            for my $is (@{ $rs->{Instances} }) {
                my $instance_id = $is->{'InstanceId'};
                #print "$instance_id\n";
                my $intest = 0;
	        for my $tag (@{ $is->{'Tags'}}){
                    if ($tag->{'Key'} =~ /$tagtype/i){
                   #    print "In - $instance_id\n";
                        push(@inlist,$instance_id);
                        $intest = 1;
	            } 
                }
                if ($intest == 0){
                   #print "Out - $instance_id\n";
                   push(@outlist,$instance_id);
                }
            }
        }
    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }

    if ($condition eq 'with'){
        print Dumper(@inlist);
    } else {
        print Dumper(@outlist);
    }

}

sub find_ebs { 
    my @inlist;
    my @outlist;
    my $ebs = $aws->ec2('describe-volumes');
    for my $volume (@{ $ebs->{'Volumes'} }){
        my $volume_id = $volume->{'VolumeId'};
        my $intest = 0;
        for my $tag ( @{ $volume->{'Tags'} }){
            if ($tag->{'Key'} =~ /$tagtype/i){
                push(@inlist,$volume_id);
                $intest = 1;
            }
        }
        if ($intest == 0){
            push(@outlist,$volume_id);
        }
    }


    if ($condition eq 'with'){
        print Dumper(@inlist);
    } else {
        print Dumper(@outlist);
    }

}

sub find_elb {
    my $elb = $aws->ec2('describe-volumes');
}


 
    
#print Dumper(@instance_list);
