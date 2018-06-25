#!/usr/bin/perl
## BacMet-Scan
use FindBin qw($Bin);

$app_title     = "BacMet-Scan - A toolbox for searching the Biocide and Metal Resistance Database";
$app_author    = "Johan Bengtsson-Palme & Chandan Pal, University of Gothenburg";
$app_version   = "1.0";
$app_message   = "";

# modified by Zhihao Xie, to use diamond;
$diamond_db = "$Bin/BacMet2_PRE/BacMet_PRE_database.dmnd";
#$diamond_db = '/sdd/database/BacMet/BacMet2_PRE/BacMet_PRE_database.dmnd';

# ----------------------------------------------------------------- #

# License information
$license =
"   BacMet-Scan - A toolbox for searching the Biocide and Metal Resistance Database
    Copyright (C) 2013-2014 Johan Bengtsson-Palme & Chandan Pal

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
       * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in the
         documentation and/or other materials provided with the distribution.
       * Neither the name of University of Gothenburg, nor the
         names of its contributors may be used to endorse or promote products
         derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
";

## BUGS:
$bugs = "Added feature:\
- Initial relase\

Known bugs in this version ($app_version):\
- None\
";

## OPTIONS:

$usage = "\
-i <input file> : the path to the input file containing non-paired sequences to scan\
-1 <input file> : if using paired-end input, the path to the input file containing the first reads to scan\
-2 <input file> : if using paired-end input, the path to the input file containing the second reads to scan\
-o <output> : the base name of the BacMet-Scan output files (if not specified, BacMet-Scan will write to stdout)\
-d <database> : the database to use, either EXP, PRE, or a path to a specific database directory, default 'PRE'\

 Software options:\
 =================\
-blast : uses BLAST for searching BacMet (default)\
-blastall : uses the old BLAST engine for searching BacMet\
-blat : uses BLAT for searching BacMet\
-pblat : uses Parallel BLAT (pblat) for searching BacMet\
-vmatch : uses VMATCH for searching BacMet\
-fixst : uses FIXST for searching BacMet\
-diamond : uses diamond (v0.9.10) for searching BacMet\

-cpu <value> : number of CPUs to use (if possible), default = 1\
-r <file> : use this file (output from the tool above that generated the file)\
            for input instead of performing the actual search\
-protein : input sequence file is in protein format (nucleotides are assumed by default)\

 Filtering options:\
 =================\
-e <value> : E-value cutoff, default = 1\
-l <value> : Length cutoff, default = 30\
-p <value> : Percent identity cutoff, default = 90\
-s <value> : Score per length cutoff, not used by default (tool dependent!)\

 Output options:\
 =================\
-table : outputs a BacMet-Scan report in table format (default)\
-report : outputs the BLAST/BLAT/VMATCH/FIXST report\
-counts : outputs a list of counts for each gene\
-matrix : outputs a list of counts for each gene, without the gene names, suitable for matrix format\
-toplist : outputs a list of encountered genes, sorted by abundance\
-all : outputs all possible BacMet-Scan output\
-columns : selects what columns to output to the BacMet-Scan output table\
           comma-separated list with the following possible items:\
           query,subject,gene,description,organism,location,compound,identity,length,evalue,score\
           default is: query,subject,gene,identity,length\
           can also be specified as 'all' to get all columns\
-v : be verbose (print messages during the BacMet-Scan process)\

-h : displays short usage information\
-help : displays this help message\
-bugs : displays the bug fixes and known bugs in this version\
-license : displays licensing information\
";


$bindir = $0;
$bindir =~ s/BacMet-Scan$//;
$db = "PRE";
$input = "";
$input1 = "";
$input2 = "";
$output = "";
$cpu = 1;
$report = "";
$software = "blast";
$protein = 0;
$E = 1;
$L = 30;
$P = 90;
$S = -1000000;
$out_table = 1;
$out_report = 0;
$out_counts = 0;
$out_matrix = 0;
$out_top = 0;
$columns = "query,subject,gene,identity,length";
$verbose = 0;

for ($i = 0; $i <= scalar(@ARGV); $i++) {   # Goes through the list of arguments
  $arg = @ARGV[$i];   # Stores the current argument in $arg
  if (substr($arg, 0, 2) eq "--") {
    $arg = substr($arg,1);
  }

  if ($arg eq "-i") {   # Read input file from -i flag
    $i++;
    $input = @ARGV[$i];
  }
  if ($arg eq "-1") {   # Read input files from -1 flag
    $i++;
    $input1 = @ARGV[$i];
  }
  if ($arg eq "-2") {   # Read input files from -2 flag
    $i++;
    $input2 = @ARGV[$i];
  }
  if ($arg eq "-o") {   # Read output file
    $i++;
    $output = @ARGV[$i];
  }

  if ($arg eq "-r") {   # Read report file
    $i++;
    $report = @ARGV[$i];
  }


  if ($arg eq "-e") {   # Read E-value cutoff
    $i++;
    $E = @ARGV[$i];
  }
  if ($arg eq "-l") {   # Read minimal length
    $i++;
    $L = @ARGV[$i];
  }
  if ($arg eq "-p") {   # Read identity cutoff
    $i++;
    $P = @ARGV[$i];
  }
  if ($arg eq "-s") {   # Read score-per-length cutoff
    $i++;
    $S = @ARGV[$i];
  }
  if ($arg eq "-d") {   # Read database
    $i++;
    $db = @ARGV[$i];
    if ($db !~ /\/$/) {
        $db = $db . '/';
    }
  }

  if ($arg eq "-cpu") {   # Set number of CPUs
    $i++;
    $cpu = @ARGV[$i];
  }

  if ($arg eq "-blast") {   # Set software to use
    $software = "blast";
  }
  if ($arg eq "-diamond") {
    $software = 'diamond';
  }
  if ($arg eq "-blastall") {   # Set software to use
    $software = "blastall";
  }
  if ($arg eq "-blat") {   # Set software to use
    $software = "blat";
  }
  if ($arg eq "-pblat") {   # Set software to use
    $software = "pblat";
  }
  if ($arg eq "-vmatch") {   # Set software to use
    $software = "vmatch";
  }
  if ($arg eq "-fixst") {   # Set software to use
    $software = "fixst";
  }
  if ($arg eq "-protein") {   # Set input sequence type
    $protein = 1;
  }

  if ($arg eq "-all") {   # Set output type
    $out_report = 1;
    $out_table = 1;
    $out_matrix = 1;
    $out_counts = 1;
    $out_top = 1;
  }
  if ($arg eq "-report") {   # Set output type
    $out_report = 1;
  }
  if ($arg eq "-table") {   # Set output type
    $out_table = 1;
  }
  if ($arg eq "-counts") {   # Set output type
    $out_counts = 1;
  }
  if ($arg eq "-matrix") {   # Set output type
    $out_matrix = 1;
  }
  if ($arg eq "-toplist") {   # Set output type
    $out_top = 1;
  }
  if ($arg eq "-columns") {   # Set output columns
    $i++;
    $columns = @ARGV[$i];
    if (lc($columns) eq "all") {
      $columns = "query,subject,gene,description,organism,location,compound,identity,length,evalue,score";
    }
  }

  if ($arg eq "-v") {   # Be verbose?
    $verbose = 1;
  }



  ## If "-h" is among the options, output short usage data and options
  if ($arg eq "-h") {
    print "Usage: BacMet-Scan -i <input file> -o <output files base>\nOptions:$usage";
    print "-----------------------------------------------------------------\n";
    exit;   # Exit
  }

  ## If "-help" is among the options, output usage data and all options
  if ($arg eq "-help") {
    print "Usage: BacMet-Scan -i <input file> -o <output files base>\nOptions:$usage";
    print "-----------------------------------------------------------------\n";
    exit;   # Exit
  }

  ## If "-bugs" is among the options, output bugs and features information
  if ($arg eq "-bugs") {
    print "$bugs\n";
    exit;   # Exit
  }

  ## If "-license" is among the options, output license information
  if ($arg eq "-license") {
    print "$license\n";
    exit;   # Exit
  }
  
}

if ($verbose == 1) {
  ## Print title message
  print STDERR "$app_title\nby $app_author\nVersion: $app_version\n$app_message";
  print STDERR "-----------------------------------------------------------------\n";
}

@columns = split(',',$columns);

## Check for input
if (($input eq "") && ($input1 eq "") && ($report eq "")) {
  print STDERR "ERROR! No input file provided! Use '-h' for usage options!\n";
  print STDERR "-----------------------------------------------------------------\n";
  exit;
} 

## If database is EXP or PRE auto-detect where it is
if ($db eq "PRE") {
  $db_temp = `ls $bindir/BacMet/BacMet_PRE*fasta 2>/dev/null`;
  if ($db_temp ne "") {
    $db = "$bindir/BacMet/BacMet_PRE";
  }
  $db_temp = `ls $bindir/BacMet_PRE*fasta 2>/dev/null 2>/dev/null`;
  if ($db_temp ne "") {
    $db = "$bindir/BacMet_PRE";
  }
  $db_temp = `ls ./BacMet_PRE*fasta 2>/dev/null 2>/dev/null`;
  if ($db_temp ne "") {
    $db = "./BacMet_PRE";
  }
} else {
  if ($db eq "EXP") {
    $db_temp = `ls $bindir/BacMet/BacMet_EXP*fasta 2>/dev/null`;
    if ($db_temp ne "") {
      $db = "$bindir/BacMet/BacMet_EXP";
    }
    $db_temp = `ls $bindir/BacMet_EXP*fasta 2>/dev/null`;
    if ($db_temp ne "") {
      $db = "$bindir/BacMet_EXP";
    }
    $db_temp = `ls ./BacMet_EXP*fasta 2>/dev/null`;
    if ($db_temp ne "") {
      $db = "./BacMet_EXP";
    }
  }
}


## Check for database
chomp($errormsg = `ls $db* 2>&1 1>/dev/null`);   # Get the error msg when looking for the profile database
if (substr($errormsg,0,4) eq "ls: ") {   # If the error message begins with "ls: ", then show an error message and exit
  print STDERR "ERROR! The BacMet database could not be found.\
Expected to find it in $db\
Consult the manual for installation instructions.\n";
  print STDERR "-----------------------------------------------------------------\n";
  exit;
}

## Check for desired software
if ($software eq "diamond") {
    $diamond_binary = "$Bin/diamond";
    if (! -e $diamond_binary) {
        chomp($diamond_binary = `which diamond`);
        if ($diamond_binary eq "") {
            print STDERR "ERROR! Could not locate diamond binaries! Make sure that diamond is installed, and try again.\n";
            print STDERR "-----------------------------------------------------------------\n";
            exit;
        }
    }
    # for diamond db
    if ($db ne 'EXP' && $db ne 'PRE') {
        chomp($db_temp = `ls $db/BacMet*.dmnd`);
        if ($db_temp ne "") {
            $diamond_db = $db_temp;
        }
    }
    if (! -e $diamond_db) {
        print STDERR "ERROR! Could not find the diamond databases. Check it.\n";
        exit;
    }
}
if ($software eq "blast") {
  if ($protein == 0) {
    chomp($path = `which blastx`);   # Get the path for blastx
  } else {
    chomp($path = `which blastp`);   # Get the path for blastp
  }
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate BLAST binaries! Make sure that BLAST+ is installed, and try again.\
To use the old BLAST engine, use the -blastall option.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}
if ($software eq "blastall") {
  chomp($path = `which blastall`);   # Get the path for blastall
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate BLAST binaries! Make sure that BLAST is installed, and try again.\
To use the new BLAST+ engine, use the -blast option.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}
if ($software eq "blat") {
  chomp($path = `which blat`);   # Get the path for blat
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate BLAT binaries! Make sure that BLAT is installed, and try again.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}
if ($software eq "pblat") {
  chomp($path = `which pblat`);   # Get the path for pblat
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate pBLAT binaries! Make sure that pBLAT is installed, and try again.\
To use the non-parallelized version of BLAT, use the -blat option.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}
if ($software eq "vmatch") {
  chomp($path = `which vmatch`);   # Get the path for vmatch
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate VMATCH binaries! Make sure that VMATCH is installed, and try again.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}
if ($software eq "fixst") {
  chomp($path = `which fixst`);   # Get the path for fixst
  if ($path eq "") {   # If the path is empty, then show an error message and exit
    print STDERR "ERROR! Could not locate FIXST binaries! Make sure that FIXST is installed, and try again.\n";
    print STDERR "-----------------------------------------------------------------\n";
    exit;
  }
}

if ($verbose == 1) {
  $now = localtime;
  print STDERR "$now : BacMet-Scan started...\n";
}

if ($input ne "") {
  push(@inputFiles,$input);
}
if ($input1 ne "") {
  push(@inputFiles,$input1);
}
if ($input2 ne "") {
  push(@inputFiles,$input2);
}
  
if ($report eq "") {  # If no report has been input, do the searching against BacMet
  `rm $output.bacmet.report 2> /dev/null`;

  if ($verbose == 1) {
    $now = localtime;
    print STDERR "$now : Preparing BacMet database for $software...\n";
  }
  if ($software eq "blast") {
    `makeblastdb -in $db*fasta -title "BacMet-Scan database" -dbtype 'prot' -out $db `;
  }
  if ($software eq "blastall") {
    `formatdb -i $db*fasta -t "BacMet-Scan database" -o F -p T -n $db`;
  }
  if ($software eq "blat") {
    $db = "$db*fasta";
  }
  if ($software eq "pblat") {
    $db = "$db*fasta";
  }
  if ($software eq "vmatch") {
    `mkvtree -db $db*fasta -protein -indexname $db -pl -allout`;
  }
  if ($software eq "fixst") {
    `fixst --index -i $db*fasta -d $db -f prot`;
  }

  foreach $input (@inputFiles) {
    $runsoftware = 1;
    if ($verbose == 1) {
      $now = localtime;
      print STDERR "$now : Searching $input against BacMet using $software...\n";
    }
    if ($software eq 'diamond') {
        if ($protein == 0) {
            `$diamond_binary blastx --threads $cpu --query $input --db $diamond_db -a $output --max-target-seqs 10 --evalue $E`;
            `$diamond_binary view -a $output.daa -o $output.bacmet.report.temp`;
        } else {
            `$diamond_binary blastp --threads $cpu --query $input --db $diamond_db -a $output --max-target-seqs 10 --evalue $E`;
            `$diamond_binary view -a $output.daa -o $output.bacmet.report.temp`;
        }
    }
    if ($software eq "blast") {
      if ($protein == 0) {
	`blastx -db $db -query $input -out $output.bacmet.report.temp -evalue $E -seg no -outfmt 6 -num_threads $cpu`;
      } else {
	`blastp -db $db -query $input -out $output.bacmet.report.temp -evalue $E -seg no -outfmt 6 -num_threads $cpu`;
      }
    }
    if ($software eq "blastall") {
      if ($protein == 0) {
	`blastall -p blastx -d $db -i $input -o $output.bacmet.report.temp -e $E -F F -m 8 -a $cpu`;
      } else {
	`blastall -p blastp -d $db -i $input -o $output.bacmet.report.temp -e $E -F F -m 8 -a $cpu`;
      }
    }
    if ($software eq "blat") {
      if ($protein == 0) {
	`blat -t=dnax -q=prot -out=blast8 $input $db.fasta $output.bacmet.report.temp`;
      } else {
	`blat -t=prot -q=prot -out=blast8 $input $db.fasta $output.bacmet.report.temp`;
      }
    }
    if ($software eq "pblat") {
      if ($protein == 0) {
	`pblat -t=dnax -q=prot -out=blast8 -threads=$cpu $input $db.fasta $output.bacmet.report.temp`;
      } else {
	`pblat -t=prot -q=prot -out=blast8 -threads=$cpu $input $db.fasta $output.bacmet.report.temp`;
      }
    }
    if ($software eq "vmatch") {
      if ($protein == 0) {
	`vmatch -dnavsprot 1 -l $L -h 2 -evalue $E -showdesc 80 -q $input $db > $output.bacmet.report.temp`;
      } else {
	`vmatch -l $L -h 2 -evalue $E -showdesc 80 -q $input $db > $output.bacmet.report.temp`;
      }
    }
    if ($software eq "fixst") {
      if ($protein == 0) {
	`fixst -i $input -d $db -o $output.bacmet.report.temp -e $E -b -f nt`;
      } else {
	`fixst -i $input -d $db -o $output.bacmet.report.temp -e $E -b -f prot`;
      }
    }
    `cat $output.bacmet.report.temp >> $output.bacmet.report`;
  }
  $report = "$output.bacmet.report";
}

if ($verbose == 1) {
  $now = localtime;
  print STDERR "$now : Analyzing $software report...\n";
}

open (REPORT, $report);
while (chomp($line = <REPORT>)) {
  if ($software =~ m/diamond/) {
    ($query,$subject,$identity,$length,$mismatches,$gaps,$qs,$qe,$ss,$se,$matchEval,$matchScore) = split('\t',$line);
  }

  if ($software =~ m/blast/) {
    ($query,$subject,$identity,$length,$mismatches,$gaps,$qs,$qe,$ss,$se,$matchEval,$matchScore) = split('\t',$line);
  }

  if ($software =~ m/blat/) {
    ($subject,$query,$identity,$length,$mismatches,$gaps,$ss,$se,$qs,$qe,$matchEval,$matchScore) = split('\t',$line);
  }

  if ($software =~ m/vmatch/) {
    if (substr($line,0,1) ne "#") {
      $line =~ s/   */\t/g;
      ($null, $length, $subject, $matchSS, $DP, $matchQLength, $query, $qs, $mismatches, $matchEval, $matchScore, $identity) = split('\t', $line);
    } else {
      next;
    }
  }

  if ($software =~ m/fixst/) {
    if (substr($line,0,3) eq ">>>") {
      # StartMarker | QueryID | MatchID | MappedTo | ReadingFrame | MatchLength | QueryStart | QueryEnd |
      # | MatchStart | MatchEnd | P-value | E-value | Score | FullP-value | FullE-value | PrecentIdentity
      ($null, $query, $subject, $mapping, $rf, $length, $qs, $qe, $ss, $se, $nullPval, $nullEval, $matchScore, $matchPval, $matchEval, $identity) = split('\t', $line);
    } else {
      next;
    }
  }

#  @subItems = split('\|', $subject);
#  $subject = @subItems[3];

  if ($length > 0) {
    $score = $matchScore / $length;
  } else {
    $score = $matchScore;
  }
  if (($matchEval <= $E) && ($identity >= $P) && ($length >= $L) && ($score >= $S)) {
    if (exists($hits{$query})) {
      ($savedSubject,$savedIdentity,$savedLength,$savedEval,$savedScore) = split('\t',$hits{$query});
      if (($matchEval < $savedEval) && ($identity > $savedIdentity) && ($length >= $savedLength) && ($score >= $savedScore)) {
	$hits{$query} = "$subject\t$identity\t$length\t$matchEval\t$score";
      }
    } else {
      $hits{$query} = "$subject\t$identity\t$length\t$matchEval\t$score";
      push(@order,$query);
    }
  }
}
close REPORT;

if ($verbose == 1) {
  $now = localtime;
  print STDERR "$now : Generating output...\n";
}


## Remove or move software report
if ($out_report == 1) {
  if ($runsoftware == 1) {
    `mv $report $output.report`;
  }
} else {
  if ($runsoftware == 1) {
    `rm $report`;
  }
}

## Read ID-to-Type mapping
chomp($mappingFile = `ls $db*mapping.txt`);
open (MAPPING, $mappingFile);
while ($line = <MAPPING>) {
  chomp($line);
  ## BacMet-Scan Version 2
  ($acc_no,$bacid,$gene,$location,$orgn,$compound,$desc) = split('\t',$line);
  if ($bacid eq "") {
    $bacid = $acc_no;
  }
  if ($acc_no eq "") {
    $acc_no = $bacid;
  }

  $mapping{$bacid} = "$gene $location $orgn $compound $desc";
  $mapping{$acc_no} = "$gene $location $orgn $compound $desc";

  $descriptions{$acc_no} = $desc;
  $organisms{$acc_no} = $orgn;
  $genes{$acc_no} = $gene;
  $locations{$acc_no} = $location;
  $compounds{$acc_no} = $compound;

  $descriptions{$bacid} = $desc;
  $organisms{$bacid} = $orgn;
  $genes{$bacid} = $gene;
  $locations{$bacid} = $location;
  $compounds{$bacid} = $compound;

  $counts{$gene} = 0;
}
close MAPPING;

if ($out_table == 1) {
  open (TABLE, ">$output.table");
    if (scalar(grep(/query/, @columns)) > 0) {
      print TABLE "Query\t";
    }
    if (scalar(grep(/subject/, @columns)) > 0) {
      print TABLE "Subject\t";
    }
    if (scalar(grep(/gene/, @columns)) > 0) {
      print TABLE "Gene\t";
    }
    if (scalar(grep(/description/, @columns)) > 0) {
      print TABLE "Description\t";
    }
    if (scalar(grep(/organism/, @columns)) > 0) {
      print TABLE "Organism\t";
    }
    if (scalar(grep(/location/, @columns)) > 0) {
      print TABLE "Location\t";
    }
    if (scalar(grep(/compound/, @columns)) > 0) {
      print TABLE "Compounds\t";
    }
    if (scalar(grep(/mapping/, @columns)) > 0) {
      print TABLE "Complete mapping information\t";
    }
    if (scalar(grep(/identity/, @columns)) > 0) {
      print TABLE "Percent identity\t";
    }
    if (scalar(grep(/length/, @columns)) > 0) {
      print TABLE "Match length\t";
    }
    if (scalar(grep(/evalue/, @columns)) > 0) {
      print TABLE "E-value\t";
    }
    if (scalar(grep(/score/, @columns)) > 0) {
      print TABLE "Score per length\t";
    }
  print TABLE "\n";
}

foreach $query (@order) {
  ($savedSubject,$savedIdentity,$savedLength,$savedEval,$savedScore) = split('\t',$hits{$query});
  $savedMapping = $mapping{$savedSubject};
  $savedGene = $genes{$savedSubject};
  $savedDesc = $descriptions{$savedSubject};
  $savedOrgn = $organisms{$savedSubject};
  $savedLocation = $locations{$savedSubject};
  $savedCompound = $compounds{$savedSubject};
  if ($savedMapping eq "") {
    @accessions = split('\|',$savedSubject);
    foreach $seqID (@accessions) {
      $savedMapping = $mapping{$seqID};
      if ($savedMapping ne "") {
	$savedGene = $genes{$seqID};
	$savedDesc = $descriptions{$seqID};
	$savedOrgn = $organisms{$seqID};
	$savedLocation = $locations{$seqID};
	$savedCompound = $compounds{$seqID};
	last;
      }
    }
  }
  if ($savedMapping eq "") {
    $savedMapping = $savedSubject;
    $savedGene = $savedSubject;
    $savedDesc = "Not found in BacMet gene index";
    $savedOrgn = "N/A";
    $savedLocation = "N/A";
    $savedCompound = "N/A";
  }
  $counts{$savedGene}++;
  if ($out_table == 1) {
    #query,subject,gene,description,organism,mapping,identity,length,evalue,score
    if (scalar(grep(/query/, @columns)) > 0) {
      print TABLE $query . "\t";
    }
    if (scalar(grep(/subject/, @columns)) > 0) {
      print TABLE $savedSubject . "\t";
    }
    if (scalar(grep(/gene/, @columns)) > 0) {
      print TABLE $savedGene . "\t";
    }
    if (scalar(grep(/description/, @columns)) > 0) {
      print TABLE $savedDesc . "\t";
    }
    if (scalar(grep(/organism/, @columns)) > 0) {
      print TABLE $savedOrgn . "\t";
    }
    if (scalar(grep(/location/, @columns)) > 0) {
      print TABLE $savedLocation . "\t";
    }
    if (scalar(grep(/compound/, @columns)) > 0) {
      print TABLE $savedCompound . "\t";
    }
    if (scalar(grep(/mapping/, @columns)) > 0) {
      print TABLE $savedMapping . "\t";
    }
    if (scalar(grep(/identity/, @columns)) > 0) {
      print TABLE $savedIdentity . "\t";
    }
    if (scalar(grep(/length/, @columns)) > 0) {
      print TABLE $savedLength . "\t";
    }
    if (scalar(grep(/evalue/, @columns)) > 0) {
      print TABLE $savedEval . "\t";
    }
    if (scalar(grep(/score/, @columns)) > 0) {
      print TABLE $savedScore . "\t";
    }
    print TABLE "\n";
  }
}

if ($out_table == 1) {
  close TABLE;
}

if (($out_matrix == 1) || ($out_counts == 1)) {
  if ($out_matrix == 1) {
    open (MATRIX, ">$output.matrix");
  }
  if ($out_counts == 1) {
    open (COUNTS, ">$output.counts");
  }
  foreach $gene (sort(keys(%counts))) {
    if ($out_counts == 1) {
      print COUNTS $gene . "\t" . $counts{$gene} . "\n";
    }
    if ($out_matrix == 1) {
      print MATRIX $counts{$gene} . "\n";
    }
  }
  if ($out_matrix == 1) {
    close MATRIX;
  }
  if ($out_counts == 1) {
    close COUNTS;
  }
}

if ($out_top == 1) {
  open (TOPLIST, ">$output.toplist");
  foreach $gene (sort {$counts{$b} <=> $counts{$a}} keys(%counts)) {
    if ($counts{$gene} > 0) {
      print TOPLIST $gene . "\t" . $counts{$gene} . "\n";
    }
  }
  close TOPLIST;
}

if ($verbose == 1) {
  $now = localtime;
  print STDERR "$now : Finished!\n";
}
