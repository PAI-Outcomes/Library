#______________________________________________________________________________
#
# Common_routines.pl
# Jay & Josh Herder
# Date: 03/26/2014
# Mods: Daily. :-)
# Mods:  BB. 05/03/17.  Updated current/expired logic (eliminated 'warning') for employee credentialing display to pharmacies.  (printCredEmployees) 
# Mods: SMD  03/01/18.  Removed most of MHT logic.  
#______________________________________________________________________________
#
sub get_reconrx_aging_sql {

  my $db = 'reconrxdb';
  my $PHID = shift;
  #print "PHID: $PHID\n";
  
  $db = 'webinar' if ($PHID == 11 || $PHID == 23 || $PHID eq "11,23");
  my $display_esi = shift;
  my $and = ''; 
##     $and = "|| third_party_payer_id  = 700006" if($display_esi);
  my $sql;

  $db = 'webinar' if($WHICHDB =~ /^Webinar$/i);
  #print "db: $db\n";
  $sql = "
    SELECT Third_Party_Payer_Name,  LPAD(dbBinNumber, 6, 0) as dbBinNumber, dbRxNumber, dbFillNumber, dbDateOfService, dbDateTransmitted, dbTotalAmountPaid_Remaining,dbCode,
           IF (DATE(LEFT(dbDateTransmitted,8)) >= (CURDATE() - INTERVAL 44 DAY), dbTotalAmountPaid_Remaining, 0) as '1-44 Days',
           IF (DATE(LEFT(dbDateTransmitted,8)) >= (CURDATE() - INTERVAL 59 DAY) && DATE(LEFT(dbDateTransmitted,8)) <= (CURDATE() - INTERVAL 45 DAY), dbTotalAmountPaid_Remaining, 0) as '45-59 Days',
           IF (DATE(LEFT(dbDateTransmitted,8)) >= (CURDATE() - INTERVAL 89 DAY) && DATE(LEFT(dbDateTransmitted,8)) <= (CURDATE() - INTERVAL 60 DAY), dbTotalAmountPaid_Remaining, 0) as '60-89 Days', 
           IF (DATE(LEFT(dbDateTransmitted,8)) <= (CURDATE() - INTERVAL 90 DAY), dbTotalAmountPaid_Remaining, 0) as '90+ Days',
           dbBinParentdbkey as TPP_ID
      FROM $db.incomingtb 
      LEFT JOIN officedb.third_party_payers 
        ON dbBinParentdbkey = Third_Party_Payer_ID
     WHERE pharmacy_id IN ($PHID) 
        && dbTotalAmountPaid_Remaining > 0
        && dbTCode IN ('PP','')
        && (officedb.third_party_payers.Reconcile = 'YES' $and)
     ORDER BY Third_Party_Payer_Name, dbDateTransmitted, dbRxNumber

    ";
  #print "sql: $sql\n";
  return $sql;
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#______________________________________________________________________________

sub printsql {

 #my $debug++;

  my ($where, $what, $sql) = @_;

  $PScnt++;
  $sql =~ s/^\n//;
  $sql =~ s/\n$//;

  my $divider = "";
  if ( $where =~ /Web|screen/i ) {
     $PRINTSQLTERM = "<br>\n";
     $divider = "<hr size=4 color=red>\n";
  } else {
     $PRINTSQLTERM = "\n";
     $divider = "-"x72, "\n";
  }

  if ( $debug ) {
     print $divider;
     print "sub printsql. Entry. where: $where $PRINTSQLTERM";
  }

  $sqlptr++;	# DO NOT MY THiS VARIABLE!!!!!!
  if ( $debug ) {
     (my $sqlout = $sql) =~ s/\n/<br>\n/g;
     printf("SQL: %03d) %s ${PRINTSQLTERM} sql: ${PRINTSQLTERM}${sqlout}$PRINTSQLTERM", $PScnt, $what, $sql) if ($debug);
  } else {
     printf("$what $PRINTSQLTERM");
  }

  if ( $debug ) {
     print "sub printsql. Exit. $PRINTSQLTERM";
     print $divider;
  }

}

#______________________________________________________________________________

sub FixDBDate {

  my ($date) = @_;
  my ($dateout) = "";
  my ($p1, $p2) = split(" ", $date);
  my ($year, $month, $day) = split("-", $p1);
  my ($hour, $minute, $second) = split(":", $p2);
  my $ampm = "";
  if ( $hour >= 12 ) {
     $ampm = "PM";
  } else {
     $ampm = "AM";
  }
  if ( $hour >= 13 ) {
     $hour = $hour - 12;
  }
  $dateout = sprintf("%02d/%02d/%04d %02d:%02d %s", $month,$day,$year,$hour,$minute,$ampm);
  return($dateout);
}

#______________________________________________________________________________

sub logActivity {
  my ($user, $action, $ncpdp) = @_;

  $ncpdp =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
  $user =~ s/\'/\\'/;
  $action =~ s/\'/\\'/;
  if ( $ncpdp !~ /^\d+$/ ) {
     $ncpdp = NULL;
  }
  my $device = $ENV{"HTTP_USER_AGENT"};
  my $remhost= $ENV{"REMOTE_HOST"};
  my $remaddr= $ENV{"REMOTE_ADDR"};
  my $url    = $ENV{"HTTP_HOST"} . $ENV{"SCRIPT_NAME"};
  my $exec   = $ENV{"SCRIPT_NAME"};

  my $program = "Other";

  if      ($url =~ /it.pharmassess.com/i) {
  	$program = "IT";
  } elsif ($url =~ /rbsdesktop/i) {
  	$program = "RBSDesktop";
  } elsif ($url =~ /paidesktop/i) {
  	$program = "PAIDesktop";
  } elsif ($url =~ /pharmassess.com/i) {
  	$program = "RBS";
  } elsif ($url =~ /recon-rx.com/i) {
  	$program = "ReconRx";
  } elsif ($url =~ /cipnetwork.com/i) {
  	$program = "CIPN";
  } elsif ($url =~ /QCPdesktop.com/i) {
  	$program = "QCPDesktop";
  } elsif ($url =~ /QCPNetwoRx/i) {
  	$program = "QCPN";
  } else {
  	$program = "UNKNOWN";
  }

  my $DBNAME = "officedb";
  my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error );
  my $dbCon = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error;

  DBI->trace(1) if ($dbitrace);

  my $sql = qq#INSERT INTO $DBNAME.logs
                SET date    = NOW(),
                    user    = "$user",
                    ncpdp   =  $ncpdp,
                    program = "$program",
                    exec    = "$exec",
                    action  = "$action",
                    device  = "$device",
                    url     = "$url",
                    IP      = "$remhost"#;

  $logThis = $dbCon->prepare($sql);
  $logThis->execute();

  $logThis->finish;
  # Close the Database
  $dbCon->disconnect;
}

#______________________________________________________________________________

sub send_email {
  my ($from, $to, $subject, $msg, $html, @attch) = @_;
  my $USER;
  my $FROM;
  my $PASS;

  use Email::Sender::Transport::SMTP;
  use Email::Stuffer;

  $html = 1 if (!defined $html);
  $msg =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

  my $EMAILHOST = 'outlook.office365.com';
  my $PORT = 587;
#  my $USER = 'PharmAssess@computer-rx.net';
  my $service_acct = 'Service';
  my $SSL  = 'starttls';   # 'ssl' / 'starttls' / undef
  my @sendtos = split(/,| /, $to);
  my $REPLY_TO = $EMAILACCT{"$from"};

  if ( $from =~ /NoReply/i ) {
    $USER = $EMAILUSER{"$from"};
    $FROM = $EMAILACCT{"$from"};
    $PASS = $EMAILACCTPWD{"$from"};
  }
  else {
    push(@sendtos, $REPLY_TO);

    $USER = $EMAILUSER{"$service_acct"};
    $FROM = $EMAILACCT{"$service_acct"};
    $PASS = $EMAILACCTPWD{"$service_acct"};
  }

#print "from: $from, FROM: $FROM, REPLY TO: $REPLY_TO TO: @sendtos\n";
  
  $FROM = $from if ($FROM =~ /^\s*$/);
 
  my $transport = Email::Sender::Transport::SMTP->new({
    host => $EMAILHOST,
    port => $PORT,
    ssl  => $SSL,
    sasl_username => $USER,
    sasl_password => $PASS,
    debug => 0,
  });

  $email = Email::Stuffer
             ->from($FROM)
             ->reply_to($REPLY_TO)
             ->subject($subject)
             ->transport($transport);

  if ($html) {
    $email->html_body($msg);
  } else {
    $email->text_body($msg);
  }

  foreach my $file (@attch) {
    $email->attach_file($file);
  }

#  print "EMAIL: " . $email->as_string() . "<br>\n";
  my $success = 0;

  foreach my $to (@sendtos) {
    next if ( $to =~ /^\s*$/ );
    if (! $email->to($to)
                ->send ) {
    } else {
      $success++;
    }
    sleep(3);
  }

  print "sub send_email: Exit\n" if ( $debug || $incdebug );
  return $success;
}

#______________________________________________________________________________

sub read_canned_file {

# Read in a canned file and fill in the variable names and return the file in an array

  my ($filename) = @_;
# print "sub read_canned_file: Entry\n\tfilename: $filename\n" if ($debug);

  my ($textmessage, @textarray);
  if ( $filename =~ /.html$/i ) {
    $file = "$CANNEDFILESDIR/${filename}";
  } else {
    $file = "$CANNEDFILESDIR/${filename}.txt";
  }

  open(SUBFILE,"< $file") || die "Couldn't open file: '$file'\n\t$!\n\n";
  my @array = <SUBFILE>;		# Slurp in the entire file into the string $text
  close(SUBFILE);

  my $line;
  $textmessage = "";
  foreach $line (@array) {
     chomp($line);
     $line =~ s/<%(.+?)%>/$$1/gi;	# sub all "<%variablename%>" with "actual variable value"
     if ( $line =~ /CCUstomerMiddleInit/i ) {
        $line =~ s/  / /g;
     }
     $textmessage .= "$line\n";
     push(@textarray, $line);
  }

  return($textmessage, @textarray);
}

#______________________________________________________________________________

# Calling Example:  (@PHFIELDS2) = &create_dol_fields($PHFIELDS);

sub create_dol_fields {

# my $debug++;

  my ($FIELDS) = @_;
  my (@FIELDS2);
# print "FIELDS: $FIELDS, ATFIELDS2: ", join(" # ", @FIELDS2), "\n";

  @fields = split(",", $FIELDS);
  foreach $fld (@fields) {
     print "fld: fld: $fld<br>\n" if ($incdebug);
     next if ($fld =~ /^\s*$/);

     $fld =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

     print "push '$fld' into FIELDS2 array<br>\n" if ($debug);
     my $value = "$fld";
#    print "value: $value<br>\n" if ($debug);
     push(@FIELDS2, "$value");
  }

  return(@FIELDS2);
}
#______________________________________________________________________________

# Call with ($cmd, $out) = &docmd($cmd);

sub docmd {

  ($cmd) = @_;
  my $out = "";

  print qq#Execute cmd: $cmd\n# if ($debug);
  chomp($out = `$cmd`);
  $cmd = "";
  print qq#$out\n# if ($debug);

  return($cmd, $out);
}
#______________________________________________________________________________

sub dostart {

  my ( $print_start_time ) = @_;

  $tm_beg = time();
  ($prog, $dir, $ext) = fileparse($0, '\..*');

  ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
  $year  += 1900;	# reported as "years since 1900".
  $month += 1;	# reported ast 0-11, 0==January
  $sdate = sprintf("%02d/%02d/%04d", $month, $day, $year);
  $ddate = sprintf("%04d%02d%02d", $year, $month, $day);
  $stime = sprintf("%02d.%02d", $hour, $min);

  $dt    = sprintf("%04d%02d%02d_%02d%02d", $year, $month, $day, $hour, $min);

  $tdate = sprintf("%02d/%02d/%04d", $month, $day, $year);
  $ttime = sprintf("%02d:%02d", $hour, $min);

  $dbdate= sprintf("%04d-%02d-%02d", $year, $month, $day);

  print "The prog is '$prog' and the directory is '$dir'.\n" if ( $incdebug || $print_start_time );
}

#______________________________________________________________________________

sub doend {

  my ( $print_run_time ) = @_;

  if ( $print_run_time ) {
    my $tm_end = time();
    print "\n", "-"x72, "\n\n";
    print "tm_end: $tm_end\n" if ($incdebug);

    my $elapsed = $tm_end - $tm_beg;

    my $hours   = int($elapsed / 3600);
    my $left    = $elapsed - ($hours * 3600);
    my $minutes = int($left / 60);
    my $seconds = $left - ($minutes * 60);

    print "Elapsed time: $elapsed seconds ";
    if ( $elapsed > 0 ) {
       print "( ";
       print "$hours hours "     if ( $hours > 0 );
       print "$minutes minutes " if ( $minutes > 0 );
       print "$seconds seconds "  if ($seconds > 0);
       print ")\n";
    }

    my ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
    $year  += 1900;	# reported as "years since 1900".
    $month += 1;	# reported ast 0-11, 0==January
    $syear  = sprintf("%4d", $year);
    $smonth = sprintf("%02d", $month);
    $sday   = sprintf("%02d", $day);
    $sdate = sprintf("%02d/%02d/%04d", $month, $day, $year);
    $stime = sprintf("%02d:%02d", $hour, $min);
    print qq#$sdate - $stime\n#;
  }
}

#______________________________________________________________________________

sub StripJunk {

   my ($value) = @_;

   $value    =~ s/\&160//g;
   $value    =~ s/\&#160//g;
#  $value    =~ s/[^a-zA-Z0-9\.\-\_\@\&\,\ \:\/\(\)]//g;	 # Only allow a-z, A-Z, 0-9, ., -, _, @, &, comma, space, :, /, (, )
   $value    =~ s/[^a-zA-Z0-9\'\.\-\_\@\&\,\ \:\/\(\)]//g;	 # Only allow ', a-z, A-Z, 0-9, ., -, _, @, &, comma, space, :, /, (, )
   $value    =~ s/^\s*(.*?)\s*$/$1/;
   return($value);
}

#______________________________________________________________________________

sub FixPhone {

   my ($value) = @_;
   my ($value2);

   $value2 = $value;

   if ( $value =~ /N\/A/i ) {
     # Just drop through
   } elsif ( $value !~ /^\s*$/ ) {
     $value    =~ s/\&160//g;
     $value    =~ s/\&#160//g;
     $value    =~ s/[^0-9]//g;	 # Only allow 0-9
     $value    =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
     $value2 = "(";
     my @pcs = split("", $value);
     my $ptr = 0;
     foreach $pc (@pcs) {
        $ptr++;
        $value2 .= $pc;
        $value2 .= ") " if ( $ptr == 3);
        $value2 .= "-"  if ( $ptr == 6);
     }
   }
   return($value2);
}

#______________________________________________________________________________

sub read_this_Owners_Pharmacies {
  my ($USER, $TYPE)  = @_;

  $rtopFound++;

  $USER  =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
  $TYPE =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
  if ( $TYPE =~ /SuperUser|User/i ) {
     my $DBNAME  = 'Officedb';
     my $TABLE   = 'Weblogin_dtl';

     $sql  = "SELECT Pharmacy_ID
                FROM $DBNAME.$TABLE
	       WHERE login_id = '$USER'
                 AND program REGEXP '($PROGRAM)'";
     my $sthx = $dbx->prepare("$sql");
     $sthx->execute;

     while ( my ($Pharmacy_ID) = $sthx->fetchrow_array() ) {
        $Pharmacies{$Pharmacy_ID}++;
        $rtopFound++;
     }
     $sthx->finish;
  } elsif ( $TYPE =~ /Affiliate/i ) {
     my $DBNAME       = 'Officedb';
     my $tbl_pharmacy = 'Pharmacy';
     my $tbl_weblogin = 'Weblogin';

     $sql  = "SELECT b.Pharmacy_ID
                FROM $DBNAME.$tbl_weblogin a 
                JOIN $DBNAME.$tbl_pharmacy b ON a.access = b.affiliate_name
	       WHERE a.id = $USER
                  && Status_ReconRx IN ('Active','Transition')
             ";
      my $sthx = $dbx->prepare("$sql");
      $sthx->execute;

      while ( my ($Pharmacy_ID) = $sthx->fetchrow_array() ) {
         $Pharmacies{$Pharmacy_ID}++;
      }
     $sthx->finish;
  } elsif ( $TYPE =~ /Admin/i ) {
      $EightWeeksSecs = 8 * 7 * 24 * 60 * 60;

      $Status = "";
      foreach $Pharmacy_ID  ( sort { $Pharmacy_Names{$a} cmp $Pharmacy_Names{$b} } keys %Pharmacy_NCPDPs) {
#         print "<hr>PROGRAM: $PROGRAM, Pharmacy_ID: $Pharmacy_ID, Pharmacy_Type: $Pharmacy_Types{$Pharmacy_ID}, CIPN Status: $Pharmacy_Status_CIPNs{$Pharmacy_ID}<br>\n"; # if ($debug);
         $Status = "";
         if ( $PROGRAM =~ /RBS|VacOnly/i && $Pharmacy_Types{$Pharmacy_ID} =~ /VacOnly/i ) {
            $Status   = $Pharmacy_Status_VacOnlys{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_VacOnlys{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /ReconRx_SPs/i ) {
            $Status   = $Pharmacy_Status_ReconRx_SPs{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_ReconRx_SPs{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /DefaultCash/i ) {
            $Status   = $Pharmacy_Status_DefaultCashs{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_DefaultCashs{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /RBS/i ) {
            if ( $Pharmacy_Status_RBS_Directs{$Pharmacy_ID} =~ /^Active$/i ||
                 $Pharmacy_Status_RBSs{$Pharmacy_ID} =~ /^Active$/i ) {
                 $Status   = "Active";
            }
         } elsif ( $Pharmacy_Types{$Pharmacy_ID} =~ /ReconRx_Clinic/i ) {
            $Status   = $Pharmacy_Status_ReconRx_Clinics{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_ReconRx_Clinics{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /ReconRx/i ) {
            $Status   = $Pharmacy_Status_ReconRxs{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_ReconRxs{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /Cred/i ) {
            $Status   = $Pharmacy_Status_Creds{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_Creds{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /RedeemRx/i ) {
            $Status   = $Pharmacy_Status_RedeemRxs{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_RedeemRxs{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /TDSB/i ) {
            $Status   = $Pharmacy_Status_TDSs{$Pharmacy_ID};
            $TermDate = $Pharmacy_Term_Date_TDSs{$Pharmacy_ID};
         } elsif ( $PROGRAM =~ /CIPN/i ) {
            if ( $Pharmacy_Status_CIPN_Directs{$Pharmacy_ID} =~ /^Active$/i ||
                 $Pharmacy_Status_CIPNs{$Pharmacy_ID} =~ /^Active$/i ) {
                 $Status   = "Active";
            }
            $TermDate = $Pharmacy_Term_Date_CIPN_Directs{$Pharmacy_ID};
         }

#         print "Status: $Status, Term: $TermDate<br>";

         next if ( $Status !~ /^Active$|^Pending$|^Transition$/i );
         next if ( $Pharmacy_ID < 5 );
         next if ( $TYPE =~ /Arete_Admin/i && $Pharmacy_Arete{$Pharmacy_ID} !~ /B|E/);

         my $OPharmacy_Name = $Pharmacy_Names{$Pharmacy_ID};

#        However, pharmacy without a type of ReconRx still has 8 weeks to access the site, so...

         my $TermBut8wks = 0;
         if ( $PROGRAM =~ /ReconRx/i ) {
            if ( $Pharmacy_Types{$Pharmacy_ID} !~ /$PROGRAM/i && $TermDate =~ /-/ ) {
               ($TermDateEpochReconRx) = &makeEpoch($Pharmacy_Term_Date_ReconRxs{$Pharmacy_ID});
               ($TermDateEpochReconRxClinic) = &makeEpoch($Pharmacy_Term_Date_ReconRx_Clinics{$Pharmacy_ID});
               if ( $TermDateEpochReconRx >= $TermDateEpochReconRxClinic ) {
                  $testEpoch = $TermDateEpochReconRx;
                  print "Term Date ReconRx: $Pharmacy_Term_Date_ReconRxs{$Pharmacy_ID}<br>\n" if ($debug);
               } else {
                  $testEpoch = $TermDateEpochReconRxClinic;
                  print "Term Date ReconRxClinic: $Pharmacy_Term_Date_ReconRx_Clinics{$Pharmacy_ID}<br>\n" if ($debug);
               }
               my $now = time();
               my $diff = $now - $testEpoch;
               if ( $debug ) {
                  my $days = $diff / 60 / 60 / 24;
                  print "Pharmacy_ID            : $Pharmacy_ID ($Pharmacy_Names{$Pharmacy_ID})<br>\n";
                  print "time()                 : $now<br>\n";
                  print "TermDateEpochReconRx   : $TermDateEpochReconRx<br>\n";
                  print "TermDateEpochReconRxClinic: $TermDateEpochReconRxClinic<br>\n";
                  print "Days since Terminated  : $days<br>\n";
               }
               if ( $diff > $EightWeeksSecs ) {
                  print "SKIPPING - Past eight weeks!<hr>\n" if ( $debug );
                  next;
               } else {
                 $TermBut8wks++;
               }
               print "<hr>\n" if ( $debug );
   
            }
         }
         next if ( !$TermBut8wks && $Pharmacy_Types{$Pharmacy_ID} !~ /$PROGRAM|VacOnly/i );

         next if ( $Status =~ /^Inactive$/i && $OPharmacy_Name !~ /-COO$/i );

         my $ONCPDP         = $Pharmacy_NCPDPs{$Pharmacy_ID};
         my $ONPI           = $Pharmacy_NPIs{$Pharmacy_ID};

         $ONCPDPs{$Pharmacy_ID} = $ONCPDP;
         $ONPIs{$ONCPDP} = $ONPI;
         $OIDs{$ONCPDP} = $Pharmacy_ID;
         $ONPIs{$Pharmacy_ID} = $ONPI;
         $OPharmacy_Names{$ONCPDP} = $OPharmacy_Name;
         $OPharmacy_Names{$Pharmacy_ID} = $OPharmacy_Name;
         push(@NCPDParray, $ONCPDP);
         $Pharmacies{$Pharmacy_ID}++;
         $rtopFound++;
      }
  }
}

#______________________________________________________________________________

sub set_OPTS_arrays {

# Do not print out unless testing from the command line

# my $debug++;

  my $dbin    = "OPDBNAME";
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};

  print "dbin: $dbin, DBNAME: $DBNAME, TABLE: $TABLE<br>\n" if ($debug);

  my $dbm98 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = qq#SELECT Description, Array, Vals FROM $DBNAME.$TABLE ORDER BY Vals#;
  print "sql: $sql<P>\n" if ($debug);

  $sth98 = $dbm98->prepare($sql);
  $sth98->execute();

  my $NumOfRows = $sth98->rows;
# print "Number of rows found: $NumOfRows<br>\n";

  while ( my @row = $sth98->fetchrow_array() ) {
    my ($Description, $Array, $Vals) = @row;
#   print "row: Description: $Description, Array: $Array, Vals: $Vals<br>\n" if ($incdebug);
    my @arr = parse_csv($Vals);
    foreach $val (@arr) {
      $val =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
      $val = "BLANK" if ( $val =~ /^\s*$/ );
      push(@$Array, "$val");
    }
  }

  $sth98->finish;

  # Close the Database
  $dbm98->disconnect;
}

#______________________________________________________________________________

sub parse_csv {

  my $text = shift;     # record containing comma-separated values
  my @new = ();
  push(@new, $+) while $text =~ m{
        # the first part groups the phrase inside the quotes.
        "([^\"\\]*(?:\\.[^\"\\]*)*) ",?
        |   ([^,]+),?
        |  ,
  }gx;
  push(@new, undef) if substr($text, -1,1) eq ',';
  return @new;          #list of values that were comma-separated

}

#______________________________________________________________________________

sub commify {

    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text

}

#______________________________________________________________________________

sub readPharmacies {

  my ($NoTest, $PROGRAM, $INNCPDP) = @_;

  ##my $debug++;
  ##my $incdebug++;

  print "<hr>sub readPharmacies: Entry. NoTest: $NoTest, PROGRAM: $PROGRAM, INNCPDP: $INNCPDP<br>\n" if ( $incdebug );
  
  $RBSPharmaciesCount   = 0;
  $ReconPharmaciesCount = 0;

  my $dbin    = "PHDBNAME";
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $TABLE_COO = 'pharmacy_coo';

  #______________________________________________________________________________
  
  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
     { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  
  DBI->trace(1) if ($dbitrace);
  my $sql = qq# SELECT * FROM (
               SELECT Pharmacy_ID, Pharmacy_Name, Legal_Name, NPI, LPAD(NCPDP,7,"0") as NCPDP, Business_Phone, Address, City, State, Zip, County, Monthly_Charge, Status, Affiliate_Name, Affiliate_Customer_ID, Software_Vendor,
	              Current_PSAO, Chain, Email_Address, Fax_Number, State_Permit_Number, State_Permit_Expiration_Date, PIC_License_Number, PIC_License_Expiration_Date, Medicare_Part_B_ID_PTAN, ReconRx_Account_Manager,
	              Medicaid_Primary_Num, Medicaid_Primary_State, Pharmacy_with_24Hour_Service, Mail_Service_Pharmacy, Compounding_Pharmacy, ePrescribing_Capabilities, Comm_Pref, Contracted_to_Distribute_Under_340B, Website_Mgmt,
           	      RBS_Fee, CIPN_Fee, ReconRx_Clinic_Fee, ReconRx_Fee, Cred_Fee, Type, FEIN, DEA, DEA_Expiration, Liability_Ins_Policy_Number, Liability_Ins_Expiration_Date, State_Controlled_Substance_License,
	              State_Controlled_Substance_License_Exp_Date, Last_Onsite_Visit_Date, Status_RBS, Active_Date_RBS, Term_Date_RBS, Status_RBS_Direct, Active_Date_RBS_Direct, Term_Date_RBS_Direct, Status_ReconRx_Clinic, Status_Cred, Status_RedeemRx, 
		      Active_Date_ReconRx_Clinic, Term_Date_ReconRx_Clinic, Status_ReconRx, Active_Date_ReconRx, Term_Date_ReconRx, Active_Date_Cred, Term_Date_Cred, Active_Date_RedeemRx, Term_Date_RedeemRx, Status_CIPN,
		      Active_Date_CIPN, Term_Date_CIPN, Status_CIPN_Direct, Active_Date_CIPN_Direct, Term_Date_CIPN_Direct, Active_Date, Term_Date, Status_TDS, Active_Date_TDS, Term_Date_TDS, RBSReporting, FluVaccineMarketProgram, FVMPInvoiceMonth, EOY_Report_Date, Single_Pay,
                      PQS, PQS_Fee, Rural, Store_User, Store_Pass, CIPN_Plus, Active_Date_CIPN_Plus, CentralPay835, CentralPayOrg, Hours_Sunday, Hours_Monday, 
		      Hours_Tuesday, Hours_Wednesday, Hours_Thursday, Hours_Friday, Hours_Saturday, Inactivate_Date, LTC, Wants835Files,
		      Status_VacOnly, Active_Date_VacOnly, Term_Date_VacOnly, Status_DefaultCash, Active_Date_DefaultCash, Term_Date_DefaultCash, Status_Special_Programs, Active_Date_Special_Programs, Term_Date_Special_Programs,
		      Status_ReconRx_SP, Active_Date_ReconRx_SP, Term_Date_ReconRx_SP, cipn_insurance_carrier, cipn_insurance_aggregate, cipn_insurance_amount_per, CMEA_Certification_Number, CMEA_Certification_Expiration_Date, AdvCred, 
		      Arete_Type, Display_ESI, Pharmacy_Data_Feed, Auto_PostPayment, 'PROD' as 'tbl' 
                FROM $DBNAME.$TABLE
		UNION ALL
               SELECT Pharmacy_ID, Pharmacy_Name, Legal_Name, NPI, LPAD(NCPDP,7,"0") as NCPDP, Business_Phone, Address, City, State, Zip, County, Monthly_Charge, Status, Affiliate_Name, Affiliate_Customer_ID, Software_Vendor,
	              Current_PSAO, Chain, Email_Address, Fax_Number, State_Permit_Number, State_Permit_Expiration_Date, PIC_License_Number, PIC_License_Expiration_Date, Medicare_Part_B_ID_PTAN, ReconRx_Account_Manager,
	              Medicaid_Primary_Num, Medicaid_Primary_State, Pharmacy_with_24Hour_Service, Mail_Service_Pharmacy, Compounding_Pharmacy, ePrescribing_Capabilities, Comm_Pref, Contracted_to_Distribute_Under_340B, Website_Mgmt,
           	      RBS_Fee, CIPN_Fee, ReconRx_Clinic_Fee, ReconRx_Fee, Cred_Fee, Type, FEIN, DEA, DEA_Expiration, Liability_Ins_Policy_Number, Liability_Ins_Expiration_Date, State_Controlled_Substance_License,
	              State_Controlled_Substance_License_Exp_Date, Last_Onsite_Visit_Date, Status_RBS, Active_Date_RBS, Term_Date_RBS, Status_RBS_Direct, Active_Date_RBS_Direct, Term_Date_RBS_Direct, Status_ReconRx_Clinic, Status_Cred, Status_RedeemRx, 
		      Active_Date_ReconRx_Clinic, Term_Date_ReconRx_Clinic, Status_ReconRx, Active_Date_ReconRx, Term_Date_ReconRx, Active_Date_Cred, Term_Date_Cred, Active_Date_RedeemRx, Term_Date_RedeemRx, Status_CIPN,
		      Active_Date_CIPN, Term_Date_CIPN, Status_CIPN_Direct, Active_Date_CIPN_Direct, Term_Date_CIPN_Direct, Active_Date, Term_Date, Status_TDS, Active_Date_TDS, Term_Date_TDS, RBSReporting, FluVaccineMarketProgram, FVMPInvoiceMonth, EOY_Report_Date, Single_Pay,
                      PQS, PQS_Fee, Rural, Store_User, Store_Pass, CIPN_Plus, Active_Date_CIPN_Plus, CentralPay835, CentralPayOrg, Hours_Sunday, Hours_Monday, 
		      Hours_Tuesday, Hours_Wednesday, Hours_Thursday, Hours_Friday, Hours_Saturday, Inactivate_Date, LTC, Wants835Files,
		      Status_VacOnly, Active_Date_VacOnly, Term_Date_VacOnly, Status_DefaultCash, Active_Date_DefaultCash, Term_Date_DefaultCash, Status_Special_Programs, Active_Date_Special_Programs, Term_Date_Special_Programs,
		      Status_ReconRx_SP, Active_Date_ReconRx_SP, Term_Date_ReconRx_SP, cipn_insurance_carrier, cipn_insurance_aggregate, cipn_insurance_amount_per, CMEA_Certification_Number, CMEA_Certification_Expiration_Date, AdvCred,
	              Null as Arete_Type, Null as Display_ESI, Pharmacy_Data_Feed, Auto_PostPayment, 'COO' as 'tbl'  

                FROM $DBNAME.$TABLE_COO
   	        WHERE CASE 
                        WHEN coo_date is null THEN 1=1   
                        ELSE coo_date  < now()
                      END 
	   ) a
		WHERE 1=1
  #;
  
  if ( $INNCPDP ) {
     $sql .= " && NCPDP=$INNCPDP";
  }

  if ( $NoTest ) {
    $sql .= " && NCPDP!=1111111 && NCPDP!=2222222 && NCPDP!=3333333 && NCPDP!=9879879";
  }

  $sql .= " ORDER BY NCPDP, tbl desc ";
  
  print "sql:<br><pre>$sql</pre><br>\n" if ($incdebug);
  
  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;
  
  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);
  
  push(@OPTSPharmacies, "All");
  
  while ( my @row = $sthx->fetchrow_array() ) {
  
    my ($Pharmacy_ID, $Pharmacy_Name, $Legal_Name, $jNPI, $jNCPDP, $Business_Phone, $Address, $City, $State, $Zip, $County, $Monthly_Charge, $Status, $Affiliate_Name, $Affiliate_Customer_ID, $Software_Vendor, 
	$Current_PSAO, $Chain, $Email_Address, $Fax_Number, $State_Permit_Number, $State_Permit_Expiration_Date, $PIC_License_Number, $PIC_License_Expiration_Date, $Medicare_Part_B_ID_PTAN, $ReconRx_Account_Manager, $Medicaid_Primary_Num, 
        $Medicaid_Primary_State, $Pharmacy_with_24Hour_Service, $Mail_Service_Pharmacy, $Compounding_Pharmacy, $ePrescribing_Capabilities, $Comm_Pref, $Contracted_to_Distribute_Under_340B, $Website_Mgmt, $RBS_Fee, $CIPN_Fee, $ReconRx_Clinic_Fee, 
        $ReconRx_Fee, $Cred_Fee, $Type, $FEIN, $DEA, $DEA_Expiration, $Liability_Ins_Policy_Number, $Liability_Ins_Expiration_Date, $State_Controlled_Substance_License, 
        $State_Controlled_Substance_License_Exp_Date, $Last_Onsite_Visit_Date, $Status_RBS, $Active_Date_RBS, $Term_Date_RBS, $Status_RBS_Direct, $Active_Date_RBS_Direct, $Term_Date_RBS_Direct, $Status_ReconRx_Clinic, $Status_Cred, $Status_RedeemRx, 
        $Active_Date_ReconRx_Clinic, $Term_Date_ReconRx_Clinic, $Status_ReconRx, $Active_Date_ReconRx, $Term_Date_ReconRx, $Active_Date_Cred, $Term_Date_Cred, $Active_Date_RedeemRx, $Term_Date_RedeemRx,
        $Status_CIPN, $Active_Date_CIPN, $Term_Date_CIPN, $Status_CIPN_Direct, $Active_Date_CIPN_Direct, $Term_Date_CIPN_Direct, $Active_Date, $Term_Date, $Status_TDS, $Active_Date_TDS, $Term_Date_TDS, $RBSReporting, $FluVaccineMarketProgram, $FVMPInvoiceMonth,
        $EOY_Report_Date, $Single_Pay, $PQS, $PQS_Fee, $Rural, $Store_User, $Store_Pass, $CIPN_Plus, $Active_Date_CIPN_Plus, $CentralPay835, $CentralPayOrg,
        $Hours_Sunday,$Hours_Monday,$Hours_Tuesday,$Hours_Wednesday,$Hours_Thursday,$Hours_Friday,$Hours_Saturday, $Inactivate_Date, $LTC, $Wants835Files,
        $Status_VacOnly, $Active_Date_VacOnly, $Term_Date_VacOnly, $Status_DefaultCash, $Active_Date_DefaultCash, $Term_Date_DefaultCash, $Status_Special_Programs, $Active_Date_Special_Programs, $Term_Date_Special_Programs,
	$Status_ReconRx_SP, $Active_Date_ReconRx_SP, $Term_Date_ReconRx_SP, $cipn_insurance_carrier, $cipn_insurance_aggregate, $cipn_insurance_amount_per, $CMEA_Certification_Number, $CMEA_Certification_Expiration_Date, $AdvCred,
	$Arete_Type, $Display_ESI, $Data_Feed, $Auto_PostPayment, $Pharmacy_tbl
     ) = @row;
  
    $Pharmacy_IDs{$Pharmacy_ID}++;
    $Pharmacy_PROGRAM{$Pharmacy_ID}         = $PROGRAM;
    $Pharmacy_Names{$Pharmacy_ID}           = $Pharmacy_Name;
    $Pharmacy_Legal_Names{$Pharmacy_ID}     = $Legal_Name;
    $Pharmacy_NPIs{$Pharmacy_ID}            = $jNPI;
    $Pharmacy_NCPDPs{$Pharmacy_ID}          = $jNCPDP;
    $Pharmacy_Store_User{$Pharmacy_ID}      = $Store_User;
  
    $Pharmacy_Store_Pass{$Pharmacy_ID}      = $Store_Pass;
  
    $Pharmacy_Comm_Prefs{$Pharmacy_ID}      = $Comm_Pref;
    $Pharmacy_Software_Vendors{$Pharmacy_ID}= $Software_Vendor;
    $Pharmacy_Current_PSAOs{$Pharmacy_ID}   = $Current_PSAO;
    $Pharmacy_Business_Phones{$Pharmacy_ID} = $Business_Phone;
    $Pharmacy_Addresses{$Pharmacy_ID}       = $Address;
    $Pharmacy_Citys{$Pharmacy_ID}           = $City;
    $Pharmacy_States{$Pharmacy_ID}          = $State;
    $Pharmacy_Zips{$Pharmacy_ID}            = $Zip;
    $Pharmacy_Countys{$Pharmacy_ID}         = $County;
    $Pharmacy_Monthly_Charges{$Pharmacy_ID} = $Monthly_Charge;
    $Pharmacy_Statuses{$Pharmacy_ID}        = $Status;
    $Pharmacy_Affiliate_Names{$Pharmacy_ID} = $Affiliate_Name;
    $Pharmacy_Affiliate_Customer_IDs{$Pharmacy_ID} = $Affiliate_Customer_ID;
    $Pharmacy_Chains{$Pharmacy_ID}          = $Chain;
    $Pharmacy_RBS_Fees{$Pharmacy_ID}        = $RBS_Fee;
    $Pharmacy_CIPN_Fees{$Pharmacy_ID}       = $CIPN_Fee;
    $Pharmacy_Cred_Fees{$Pharmacy_ID}       = $Cred_Fee;
    $Pharmacy_ReconRx_Clinic_Fees{$Pharmacy_ID}= $ReconRx_Clinic_Fee;
    $Pharmacy_ReconRx_Fees{$Pharmacy_ID}    = $ReconRx_Fee;
    $Pharmacy_AdvCred{$Pharmacy_ID}         = $AdvCred;
    $Pharmacy_Auto_PostPayments{$Pharmacy_ID}  = $Auto_PostPayment;
  
    $Pharmacy_Types{$Pharmacy_ID}           .= $Type if ( $Pharmacy_Types{$Pharmacy_ID} !~ /$Type/i );
    
    $Pharmacy_ReconRx_Account_Managers{$Pharmacy_ID}            = $ReconRx_Account_Manager;
 
    $Pharmacy_Email_Address{$Pharmacy_ID}                       = $Email_Address;
    $Pharmacy_Fax_Number{$Pharmacy_ID}                          = $Fax_Number;
    $Pharmacy_Medicare_Part_B_ID_PTAN{$Pharmacy_ID}             = $Medicare_Part_B_ID_PTAN;
    $Pharmacy_Medicaid_Primary_Num{$Pharmacy_ID}                = $Medicaid_Primary_Num;
    $Pharmacy_Medicaid_Primary_State{$Pharmacy_ID}              = $Medicaid_Primary_State;
    $Pharmacy_Pharmacy_with_24Hour_Service{$Pharmacy_ID}        = $Pharmacy_with_24Hour_Service;
    $Pharmacy_Mail_Service_Pharmacy{$Pharmacy_ID}               = $Mail_Service_Pharmacy;
    $Pharmacy_Compounding_Pharmacy{$Pharmacy_ID}                = $Compounding_Pharmacy;
    $Pharmacy_ePrescribing_Capabilities{$Pharmacy_ID}           = $ePrescribing_Capabilities;
    $Pharmacy_Contracted_to_Distribute_Under_340B{$Pharmacy_ID} = $Contracted_to_Distribute_Under_340B;
    $Pharmacy_FEINs{$Pharmacy_ID}                               = $FEIN;
    $Pharmacy_Website_Mgmt{$Pharmacy_ID}                        = $Website_Mgmt;
    $Pharmacy_Last_Onsite_Visit_Dates{$Pharmacy_ID}             = $Last_Onsite_Visit_Date;
    $Pharmacy_RBSReporting{$Pharmacy_ID}                        = $RBSReporting;
    $Pharmacy_FluVaccineMarketProgram{$Pharmacy_ID}             = $FluVaccineMarketProgram;
    $Pharmacy_FVMPInvoiceMonth{$Pharmacy_ID}                    = $FVMPInvoiceMonth;
    $Pharmacy_EOY_Report_Dates{$Pharmacy_ID}                    = $EOY_Report_Date;
    $Pharmacy_Single_Pays{$Pharmacy_ID}                         = $Single_Pay;

    $Pharmacy_DEA{$Pharmacy_ID}                                 = $DEA;
    $Pharmacy_DEA_Expiration{$Pharmacy_ID}                      = $DEA_Expiration;
    $Pharmacy_Liability_Ins_Policy_Number{$Pharmacy_ID}         = $Liability_Ins_Policy_Number;
    $Pharmacy_Liability_Ins_Expiration_Date{$Pharmacy_ID}       = $Liability_Ins_Expiration_Date;
    $Pharmacy_PIC_License_Number{$Pharmacy_ID}                  = $PIC_License_Number;
    $Pharmacy_PIC_License_Expiration_Date{$Pharmacy_ID}         = $PIC_License_Expiration_Date;
    $Pharmacy_State_Permit_Number{$Pharmacy_ID}                 = $State_Permit_Number;
    $Pharmacy_State_Permit_Expiration_Date{$Pharmacy_ID}        = $State_Permit_Expiration_Date;
    $Pharmacy_State_Controlled_Substance_License{$Pharmacy_ID}  = $State_Controlled_Substance_License;
    $Pharmacy_State_Controlled_Substance_License_Exp_Date{$Pharmacy_ID}= $State_Controlled_Substance_License_Exp_Date;
  
    $Pharmacy_Status_RBSs{$Pharmacy_ID}                    = $Status_RBS;
    $Pharmacy_Status_RBS_Directs{$Pharmacy_ID}             = $Status_RBS_Direct;
    $Pharmacy_Status_ReconRx_Clinics{$Pharmacy_ID}         = $Status_ReconRx_Clinic;
    $Pharmacy_Status_ReconRxs{$Pharmacy_ID}                = $Status_ReconRx;
    $Pharmacy_Status_Creds{$Pharmacy_ID}                   = $Status_Cred;
    $Pharmacy_Status_RedeemRxs{$Pharmacy_ID}               = $Status_RedeemRx;
    $Pharmacy_Status_CIPNs{$Pharmacy_ID}                   = $Status_CIPN;
    $Pharmacy_Status_CIPN_Directs{$Pharmacy_ID}            = $Status_CIPN_Direct;
    $Pharmacy_Status_VacOnlys{$Pharmacy_ID}                = $Status_VacOnly;
    $Pharmacy_Status_DefaultCashs{$Pharmacy_ID}            = $Status_DefaultCash;
    $Pharmacy_Status_Special_Programss{$Pharmacy_ID}       = $Status_Special_Programs;
    $Pharmacy_Status_ReconRx_SPs{$Pharmacy_ID}             = $Status_ReconRx_SP;
    $Pharmacy_Status_TDSs{$Pharmacy_ID}                    = $Status_TDS;
 
    $Pharmacy_Active_Dates{$Pharmacy_ID}                   = $Active_Date;
    $Pharmacy_Active_Date_RBSs{$Pharmacy_ID}               = $Active_Date_RBS;
    $Pharmacy_Active_Date_RBS_Directs{$Pharmacy_ID}        = $Active_Date_RBS_Direct;
    $Pharmacy_Active_Date_ReconRx_Clinics{$Pharmacy_ID}    = $Active_Date_ReconRx_Clinic;
    $Pharmacy_Active_Date_ReconRxs{$Pharmacy_ID}           = $Active_Date_ReconRx;
    $Pharmacy_Active_Date_Creds{$Pharmacy_ID}              = $Active_Date_Cred;
    $Pharmacy_Active_Date_RedeemRxs{$Pharmacy_ID}          = $Active_Date_RedeemRx;
    $Pharmacy_Active_Date_CIPNs{$Pharmacy_ID}              = $Active_Date_CIPN;
    $Pharmacy_Active_Date_CIPN_Directs{$Pharmacy_ID}       = $Active_Date_CIPN_Direct;
    $Pharmacy_Active_Date_VacOnlys{$Pharmacy_ID}           = $Active_Date_VacOnly;
    $Pharmacy_Active_Date_DefaultCashs{$Pharmacy_ID}       = $Active_Date_DefaultCash;
    $Pharmacy_Active_Date_Special_Programss{$Pharmacy_ID}  = $Active_Date_Special_Programs;
    $Pharmacy_Active_Date_ReconRx_SPs{$Pharmacy_ID}        = $Active_Date_ReconRx_SP;
    $Pharmacy_Active_Date_TDSs{$Pharmacy_ID}               = $Active_Date_TDS;

    $Pharmacy_Term_Dates{$Pharmacy_ID}                     = $Term_Date;
    $Pharmacy_Term_Date_RBSs{$Pharmacy_ID}                 = $Term_Date_RBS;
    $Pharmacy_Term_Date_RBS_Directs{$Pharmacy_ID}          = $Term_Date_RBS_Direct;
    $Pharmacy_Term_Date_ReconRx_Clinics{$Pharmacy_ID}      = $Term_Date_ReconRx_Clinic;
    $Pharmacy_Term_Date_ReconRxs{$Pharmacy_ID}             = $Term_Date_ReconRx;
    $Pharmacy_Term_Date_Creds{$Pharmacy_ID}                = $Term_Date_Cred;
    $Pharmacy_Term_Date_RedeemRxs{$Pharmacy_ID}            = $Term_Date_RedeemRx;
    $Pharmacy_Term_Date_CIPNs{$Pharmacy_ID}                = $Term_Date_CIPN;
    $Pharmacy_Term_Date_CIPN_Directs{$Pharmacy_ID}         = $Term_Date_CIPN_Direct;
    $Pharmacy_Term_Date_VacOnlys{$Pharmacy_ID}             = $Term_Date_VacOnly;
    $Pharmacy_Term_Date_DefaultCashs{$Pharmacy_ID}         = $Term_Date_DefaultCash;
    $Pharmacy_Term_Date_Special_Programss{$Pharmacy_ID}    = $Term_Date_Special_Programs;
    $Pharmacy_Term_Date_ReconRx_SPs{$Pharmacy_ID}          = $Term_Date_ReconRx_SP;
    $Pharmacy_Term_Date_TDSs{$Pharmacy_ID}                 = $Term_Date_TDS;

    $Pharmacy_PQSs{$Pharmacy_ID}                           = $PQS;
    $Pharmacy_PQS_Fees{$Pharmacy_ID}                       = $PQS_Fee;

    $Pharmacy_Rurals{$Pharmacy_ID}                         = $Rural;
  
    $Pharmacy_CIPN_Plus{$Pharmacy_ID}                      = $CIPN_Plus;
    $Pharmacy_Active_Date_CIPN_Plus{$Pharmacy_ID}          = $Active_Date_CIPN_Plus;
    $Pharmacy_Term_Date_CIPN_Plus{$Pharmacy_ID}            = $Term_Date_CIPN_Plus;

    $Pharmacy_CentralPay835s{$Pharmacy_ID}                 = $CentralPay835;
    $Pharmacy_CentralPayOrgs{$Pharmacy_ID}                 = $CentralPayOrg;

    $Pharmacy_Hours_Sunday{$Pharmacy_ID}                   = $Hours_Sunday;
    $Pharmacy_Hours_Monday{$Pharmacy_ID}                   = $Hours_Monday;
    $Pharmacy_Hours_Tuesday{$Pharmacy_ID}                  = $Hours_Tuesday;
    $Pharmacy_Hours_Wednesday{$Pharmacy_ID}                = $Hours_Wednesday;
    $Pharmacy_Hours_Thursday{$Pharmacy_ID}                 = $Hours_Thursday;
    $Pharmacy_Hours_Friday{$Pharmacy_ID}                   = $Hours_Friday;
    $Pharmacy_Hours_Saturday{$Pharmacy_ID}                 = $Hours_Saturday;
    $Pharmacy_Inactivate_Date                              = $Inactivate_Date ;

    $Pharmacy_LTCs{$Pharmacy_ID}                           = $LTC;
    $Pharmacy_Wants835Files{$Pharmacy_ID}                  = $Wants835Files;

    $Pharmacy_cipn_insurance_carrier{$Pharmacy_ID}         = $cipn_insurance_carrier;
    $Pharmacy_cipn_insurance_aggregate{$Pharmacy_ID}       = $cipn_insurance_aggregate;
    $Pharmacy_cipn_insurance_amount_per{$Pharmacy_ID}      = $cipn_insurance_amount_per;
    $Pharmacy_CMEA_Certification_Number{$Pharmacy_ID}      = $CMEA_Certification_Number;
    $Pharmacy_CMEA_Expiration_Date{$Pharmacy_ID}           = $CMEA_Certification_Expiration_Date;
    $Pharmacy_Data_Feed{$Pharmacy_ID}                      = $Data_Feed;
  
    $Reverse_Pharmacy_NPIs{$jNPI}      = $Pharmacy_ID if ($Pharmacy_tbl ne 'COO');	# Reverse lookup for Interventions Search!
    $Reverse_Pharmacy_NCPDPs{$jNCPDP}  = $Pharmacy_ID if ($Pharmacy_tbl ne 'COO');	# Reverse lookup for Interventions Search!
#    $Reverse_Pharmacy_NCPDPs{$jNCPDP}  = $Pharmacy_ID;	# Reverse lookup for Interventions Search!

    $RBSPharmaciesCount++   if ( $Type =~ /RBS/i   && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $ReconPharmaciesCount++ if ( $Type =~ /Recon/i && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $QCPPharmaciesCount++   if ( $Type =~ /QCP/i   && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $Pharmacy_Arete{$Pharmacy_ID}      = $Arete_Type if ($Arete_Type =~ /E|B/);
    $Pharmacy_DisplayESI{$Pharmacy_ID} = $Display_ESI;
  
  }
  $sthx->finish;
  $dbm->disconnect;
  
  foreach $id ( sort keys %Pharmacy_Names) {
    $name = $Pharmacy_Names{$id};
    $key  = "${id} - $name";
    push(@OPTSPharmacies, "$key");
    $HASHPharmacies{$key} = $name;
  }

  print "sub readPharmacies: Exit. RBSPharmaciesCount: $RBSPharmaciesCount, ReconPharmaciesCount: $ReconPharmaciesCount<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ( $incdebug );

}

sub readContacts {
  my ($Program, $Pharmacy_ID) = @_;

  my $DBNAME  = 'officedb';
  my $db_pc_table = "officedb.pharmacy_contacts";
  my $db_cc_table = "officedb.contact_ctl";
  my $db_ct_table = "officedb.contact_types";

  #______________________________________________________________________________
  
  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
     { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  
  my $sql = "SELECT a.pharmacy_id,
                    b.contact_owner,
                    c.`name` AS contact_type,
		    a.`name` AS contact_name,
                    a.title  AS contact_title,		    
		    a.email AS contact_email,
		    a.phone AS contact_phone,
		    a.cellphone AS contact_cell,
		    a.fax AS contact_fax
               FROM $db_pc_table a
	       JOIN $db_cc_table b ON (a.contact_ctl_id = b.id)
	       JOIN $db_ct_table c ON (b.contact_type = c.id)
              WHERE a.active = 1";
  
  if ( $Program ) {
     $sql .= " && b.contact_owner = '$program'";
  }

  if ( $Pharmacy_ID ) {
    $sql .= " && Pharmacy_ID = $Pharmacy_ID";
  }

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;
  
  my $NumOfRows = $sthx->rows;
  
  push(@OPTSPharmacies, "All");
  
  while ( my ($Pharmacy_ID, $Program, $Type, $Name, $Title, $Email, $Phone, $Cell, $Fax) = $sthx->fetchrow_array() ) {
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Name'}  = $Name;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Name'}  = $Name;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Title'} = $Title;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Email'} = $Email;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Phone'} = $Phone;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Cell'}  = $Cell;
    $Contacts{$Pharmacy_ID}{$Program}{$Type}{'Fax'}   = $Fax;
  }
  $sthx->finish;
  $dbm->disconnect;
}

#______________________________________________________________________________

sub readThirdPartyPayers {

# my $debug++;
# my $incdebug++;

  my ($ENV) = &What_Env_am_I_in;

  $SERVER_NAME = $ENV{"SERVER_NAME"};
  print "<hr>sub readThirdPartyPayers: Entry. ENV: $ENV, SERVER_NAME: $SERVER_NAME<br>\n" if ( $incdebug );

  my $dbin    = "TPDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT Third_Party_Payer_ID, Third_Party_Payer_Name, Status, Business_Phone, Address, City, State, Zip, Website, Direct_Payer, Inactivate_Date, BIN, Primary_Contact_Name, Primary_Contact_Phone, Primary_Contact_Phone_Ext, Primary_Contact_Email, Pharmacy_Manual, ISA_ID_01, ISA_ID_02, ISA_ID_03, ISA_ID_04, ISA_ID_05, ISA_ID_06, ISA_ID_07, ISA_ID_08, ISA_ID_09, ISA_ID_10, Fee_Overpayment, Fee_Overpayment_Description, Primary_Secondary, MAC_Appeal_Turn_Around, Reconcile, Parent_Name_Key, Tax_Location, HelpDesk, TransFee, MACAppealResubmissionWindow, EmergencyPAPhoneNumber, MAC_Appeal_Comm_Type, MAC_Appeal_Form_Type, MAC_Appeal_Invoice_Required, MACAppeal_Contact_Email, MACAppeal_Contact_Fax, MACAppeal_Contact_Phone, PreferredNetwork_Contact_Name, PreferredNetwork_Contact_Address, PreferredNetwork_Contact_City, PreferredNetwork_Contact_State, PreferredNetwork_Contact_Zip, PreferredNetwork_Contact_Email, RemittancePrimary_Contact_Name, RemittancePrimary_Contact_Email, RemittanceMaintenance_Contact_Email, RxPaymentInquiries_Contact_Email, Payment_Cycle, Trans_Fee_Loc, Trans_Fee_Loc_PSAO, DIR_Loc,DIR_Loc_PSAO, Tax_Location, LA_Provider_Fee_Loc, Use_TransFee, Central_Pay_Entity, DIR_Loc_Display FROM $DBNAME.$TABLE ";

# print "<hr>ENV: $ENV<hr>\n" if ($incdebug);
# if BLANK, then we are in BATCH, so check for that too
  if ( $ENV =~ /^\s*$|DEV/i ) {
    # Get them all, including JAY/JOSH test TPP entries
  } else {
    $sql .= " WHERE BIN <= 999999 && Status  = 'Active'";
  }
    $sql .= "ORDER BY STATUS DESC";
  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {

     my ($Third_Party_Payer_ID, $Third_Party_Payer_Name, $Status, $Business_Phone, $Address, $City, $State, $Zip, $Website, $Direct_Payer, $Inactivate_Date, $BIN, $Primary_Contact_Name, $Primary_Contact_Phone, $Primary_Contact_Phone_Ext, $Primary_Contact_Email, $Pharmacy_Manual, $ISA_ID_01, $ISA_ID_02, $ISA_ID_03, $ISA_ID_04, $ISA_ID_05, $ISA_ID_06, $ISA_ID_07, $ISA_ID_08, $ISA_ID_09, $ISA_ID_10, $Fee_Overpayment, $Fee_Overpayment_Description, $Primary_Secondary, $MAC_Appeal_Turn_Around, $Reconcile, $Parent_Name_Key, $Tax_Location, $HelpDesk, $TransFee, $MACAppealResubmissionWindow, $EmergencyPAPhoneNumber, $MAC_Appeal_Comm_Type, $MAC_Appeal_Form_Type, $MAC_Appeal_Invoice_Required, $MACAppeal_Contact_Email, $MACAppeal_Contact_Fax, $MACAppeal_Contact_Phone, $PreferredNetwork_Contact_Name, $PreferredNetwork_Contact_Address, $PreferredNetwork_Contact_City, $PreferredNetwork_Contact_State, $PreferredNetwork_Contact_Zip, $PreferredNetwork_Contact_Email, $RemittancePrimary_Contact_Name, $RemittancePrimary_Contact_Email, $RemittanceMaintenance_Contact_Email, $RxPaymentInquiries_Contact_Email, $Payment_Cycle, $Trans_Fee_Loc, $Trans_Fee_Loc_PSAO, $DIR_Loc,$DIR_Loc_PSAO, $Tax_Location, $LA_Provider_Fee_Loc, $Use_TransFee, $Central_Pay_Entity, $DIR_Loc_Disp) = @row;

     $ThirdPartyPayer_IDs{$Third_Party_Payer_ID}++;
     $ThirdPartyPayer_Names{$Third_Party_Payer_ID} = $Third_Party_Payer_Name;
#     $Third_Party_Payer_Name = 'Other' if ($Third_Party_Payer_ID == '700006');
     $TPP_IDs{$Third_Party_Payer_ID}++;
     $TPP_Names{$Third_Party_Payer_ID}           = $Third_Party_Payer_Name;
     $TPP_Statuses{$Third_Party_Payer_ID}        = $Status;
     $TPP_Business_Phones{$Third_Party_Payer_ID} = $Business_Phone;
     $TPP_Addresses{$Third_Party_Payer_ID}       = $Address;
     $TPP_Citys{$Third_Party_Payer_ID}           = $City;
     $TPP_States{$Third_Party_Payer_ID}          = $State;
     $TPP_Zips{$Third_Party_Payer_ID}            = $Zip;
     $TPP_Websites{$Third_Party_Payer_ID}        = $Website;
     $TPP_Direct_Payers{$Third_Party_Payer_ID}   = $Direct_Payer;
     $TPP_Inactive_Dates{$Third_Party_Payer_ID}  = $Inactive_Date;
     $TPP_BINs{$Third_Party_Payer_ID}            = $BIN;
     $TPP_Pri_Contact_Names{$Third_Party_Payer_ID}      = $Primary_Contact_Name;
     $TPP_Pri_Contact_Phones{$Third_Party_Payer_ID}     = $Primary_Contact_Phone;
     $TPP_Pri_Contact_Phone_Exts{$Third_Party_Payer_ID} = $Primary_Contact_Phone_Ext;
     $TPP_Pri_Contact_Emails{$Third_Party_Payer_ID}     = $Primary_Contact_Email;
     $TPP_Manuals{$Third_Party_Payer_ID}                = $Pharmacy_Manual;
     $TPP_MAC_Appeal_Turn_Arounds{$Third_Party_Payer_ID}= $MAC_Appeal_Turn_Around;
     $TPP_MACAppealResubmissionWindows{$Third_Party_Payer_ID} = $MACAppealResubmissionWindow;
     $TPP_EmergencyPAPhoneNumbers{$Third_Party_Payer_ID}= $EmergencyPAPhoneNumber;
     $TPP_MAC_Appeal_Comm_Types{$Third_Party_Payer_ID}  = $MAC_Appeal_Comm_Type;
     $TPP_MAC_Appeal_Form_Types{$Third_Party_Payer_ID}  = $MAC_Appeal_Form_Type;
     $TPP_MAC_Appeal_Invoices_Required{$Third_Party_Payer_ID} = $MAC_Appeal_Invoice_Required;
     $TPP_MACAppeal_Contact_Emails{$Third_Party_Payer_ID}  = $MACAppeal_Contact_Email;
     $TPP_MACAppeal_Contact_Faxs{$Third_Party_Payer_ID}    = $MACAppeal_Contact_Fax;
     $TPP_MACAppeal_Contact_Phones{$Third_Party_Payer_ID}  = $MACAppeal_Contact_Phone;

     $TPP_PreferredNetwork_Contact_Names{$Third_Party_Payer_ID}     = $PreferredNetwork_Contact_Name;
     $TPP_PreferredNetwork_Contact_Addresses{$Third_Party_Payer_ID} = $PreferredNetwork_Contact_Address;
     $TPP_PreferredNetwork_Contact_Citys{$Third_Party_Payer_ID}     = $PreferredNetwork_Contact_City;
     $TPP_PreferredNetwork_Contact_States{$Third_Party_Payer_ID}    = $PreferredNetwork_Contact_State;
     $TPP_PreferredNetwork_Contact_Zips{$Third_Party_Payer_ID}      = $PreferredNetwork_Contact_Zip;
     $TPP_PreferredNetwork_Contact_Emails{$Third_Party_Payer_ID}    = $PreferredNetwork_Contact_Email;

     $TPP_RemittancePrimary_Contact_Names{$Third_Party_Payer_ID}     = $RemittancePrimary_Contact_Name;
     $TPP_RemittancePrimary_Contact_Emails{$Third_Party_Payer_ID}    = $RemittancePrimary_Contact_Email;
     $TPP_RemittanceMaintenance_Contact_Emails{$Third_Party_Payer_ID}= $RemittanceMaintenance_Contact_Email;
     $TPP_RxPaymentInquiries_Contact_Emails{$Third_Party_Payer_ID}   = $RxPaymentInquiries_Contact_Email;

     $TPP_PriSecs{$Third_Party_Payer_ID}                = $Primary_Secondary;
     $TPP_ISA_IDs{$Third_Party_Payer_ID}                = "${ISA_ID_01}##${ISA_ID_02}##${ISA_ID_03}##${ISA_ID_04}##${ISA_ID_05}##${ISA_ID_06}##${ISA_ID_07}##${ISA_ID_08}##${ISA_ID_09}##${ISA_ID_10}";
     $TPP_Fee_Overpayments{$Third_Party_Payer_ID}       = $Fee_Overpayment;
     $TPP_Fee_Overpayment_Descriptions{$Third_Party_Payer_ID} = $Fee_Overpayment_Description;
     $TPP_Reconciles{$Third_Party_Payer_ID}             = $Reconcile;
     $TPP_Parent_Name_Keys{$Third_Party_Payer_ID}       = $Parent_Name_Key;
#    print "TPP_Parent_Name_Keys($Third_Party_Payer_ID): $TPP_Parent_Name_Keys{$Third_Party_Payer_ID}<br>\n";
     $TPP_Tax_Locations{$Third_Party_Payer_ID}          = $Tax_Location;
     $TPP_HelpDesks{$Third_Party_Payer_ID}              = $HelpDesk;
     $TPP_TransFees{$Third_Party_Payer_ID}              = $TransFee;
     $TPP_Payment_Cycles{$Third_Party_Payer_ID}         = $Payment_Cycle;

     $TPP_Use_Trans_Fee{$Third_Party_Payer_ID}          = $Use_TransFee;
     $TPP_Trans_Fee_Locs{$Third_Party_Payer_ID}         = $Trans_Fee_Loc;
     $TPP_Trans_Fee_Locs_PSAO{$Third_Party_Payer_ID}    = $Trans_Fee_Loc_PSAO;
     $TPP_DIR_Locs{$Third_Party_Payer_ID}               = $DIR_Loc;
     $TPP_DIR_Locs_PSAO{$Third_Party_Payer_ID}          = $DIR_Loc_PSAO;
     $TPP_DIR_Locs_Display{$Third_Party_Payer_ID}       = $DIR_Loc_Disp if($DIR_Loc_Disp);
     $TPP_Tax_Locations{$Third_Party_Payer_ID}          = $Tax_Location;
     $TPP_LA_Provider_Fee_Locs{$Third_Party_Payer_ID}   = $LA_Provider_Fee_Loc;
     $Reverse_TPP_BINs_PRISEC{$BIN} = $Third_Party_Payer_ID;
     $Central_Pay_Entity{$Third_Party_Payer_ID}         = $Central_Pay_Entity;

     $Reverse_TPP_BINs_ALL{$BIN} = $Third_Party_Payer_ID;
     $Reverse_TPP_Names_ALL{$Third_Party_Payer_Name} = $Third_Party_Payer_ID;

     if ( $Primary_Secondary =~ /^Pri$/i || $TPP_Reconciles{$Third_Party_Payer_ID} =~ /^Y/i ) {
         # Reverse lookup for lookups
         $Reverse_TPP_BINs{$BIN}   = $Third_Party_Payer_ID;
     }
     ($BIN2 = $BIN) += 0;
     if ( $Primary_Secondary =~ /^Pri$/i || $TPP_Reconciles{$Third_Party_Payer_ID} =~ /^Y/i ) {
        # Reverse lookup for lookups
        $Reverse_TPP_BINs2{$BIN2} = $Third_Party_Payer_ID;
     }

#    Save way to find TPP key when all I have is an ISA_ID value
     $Reverse_ISA_IDs{$ISA_ID_01} = $Parent_Name_Key if ( $ISA_ID_01 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_02} = $Parent_Name_Key if ( $ISA_ID_02 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_03} = $Parent_Name_Key if ( $ISA_ID_03 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_04} = $Parent_Name_Key if ( $ISA_ID_04 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_05} = $Parent_Name_Key if ( $ISA_ID_05 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_06} = $Parent_Name_Key if ( $ISA_ID_06 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_07} = $Parent_Name_Key if ( $ISA_ID_07 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_08} = $Parent_Name_Key if ( $ISA_ID_08 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_09} = $Parent_Name_Key if ( $ISA_ID_09 !~ /^\s*$/ );
     $Reverse_ISA_IDs{$ISA_ID_10} = $Parent_Name_Key if ( $ISA_ID_10 !~ /^\s*$/ );

     if ( $incdebug ) {
        print "TPPID: $Third_Party_Payer_ID<br>\n";
        print "Reverse_ISA_IDs (if any):\n";
        print "Reverse_ISA_IDs($ISA_ID_01): $Reverse_ISA_IDs{$ISA_ID_01}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_01} );
        print "Reverse_ISA_IDs($ISA_ID_02): $Reverse_ISA_IDs{$ISA_ID_02}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_02} );
        print "Reverse_ISA_IDs($ISA_ID_03): $Reverse_ISA_IDs{$ISA_ID_03}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_03} );
        print "Reverse_ISA_IDs($ISA_ID_04): $Reverse_ISA_IDs{$ISA_ID_04}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_04} );
        print "Reverse_ISA_IDs($ISA_ID_05): $Reverse_ISA_IDs{$ISA_ID_05}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_05} );
        print "Reverse_ISA_IDs($ISA_ID_06): $Reverse_ISA_IDs{$ISA_ID_06}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_06} );
        print "Reverse_ISA_IDs($ISA_ID_07): $Reverse_ISA_IDs{$ISA_ID_07}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_07} );
        print "Reverse_ISA_IDs($ISA_ID_08): $Reverse_ISA_IDs{$ISA_ID_08}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_08} );
        print "Reverse_ISA_IDs($ISA_ID_09): $Reverse_ISA_IDs{$ISA_ID_09}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_09} );
        print "Reverse_ISA_IDs($ISA_ID_10): $Reverse_ISA_IDs{$ISA_ID_10}<br>\n" if ( $Reverse_ISA_IDs{$ISA_ID_10} );
        print "<hr>\n";
     }

#    print "sub readThirdParty_Payer: Third_Party_Payer_ID: $Third_Party_Payer_ID, Third_Party_Payer_Name: $Third_Party_Payer_Name<br>\n" if ($incdebug);
  }
  # only want Primary TPP's in OPTSTPPPris array
  my %TMP = ();
  foreach $id ( sort {$ThirdPartyPayer_Names{$a} cmp $ThirdPartyPayer_Names{$b} } keys %ThirdPartyPayer_Names) {
     next if ( $TPP_PriSecs{$id} !~ /^Pri$/i );
     next if ( $TPP_Reconciles{$id} !~ /^Y/i );
     my $name = $ThirdPartyPayer_Names{$id};
     $TMP{$id} = $name;
  }
# $jcount = 0;
  foreach my $id ( sort { $TMP{$a} cmp $TMP{$b} } keys %TMP ) {
     my $key  = "${id} - $TMP{$id}";
     push(@OPTSTPPPris, "$key");
#    $jcount++;
  }
# print "jcount: $jcount<br>\n";

  # All TPP's in OPTSTPPs array
  %TMP = ();
  foreach $id ( sort {$ThirdPartyPayer_Names{$a} cmp $ThirdPartyPayer_Names{$b} } keys %ThirdPartyPayer_Names) {
     my $name = $ThirdPartyPayer_Names{$id};
     $TMP{$id} = $name;
  }
  foreach my $id ( sort { $TMP{$a} cmp $TMP{$b} } keys %TMP ) {
     my $key  = "${id} - $TMP{$id}";
     push(@OPTSTPPs, "$key");
     my $key2 = "$TPP_BINs{$id} - $TMP{$id}";
     push(@OPTSTPPBINs, "$key2");
  }

  # All TPP's in OPTSTPPDirectPris array
  %TMP = ();
  foreach $id ( sort {$ThirdPartyPayer_Names{$a} cmp $ThirdPartyPayer_Names{$b} } keys %ThirdPartyPayer_Names) {
     next if ( $TPP_PriSecs{$id} !~ /^Pri$/i );
     next if ( $TPP_Direct_Payers{$id} !~ /^Direct/i );
     next if ( $ThirdPartyPayer_Names{$id} =~ /^CVS\s*Caremark/i );
     my $name = $ThirdPartyPayer_Names{$id};
     $TMP{$id} = $name;
  }
  foreach my $id ( sort { $TMP{$a} cmp $TMP{$b} } keys %TMP ) {
     my $key  = "${id} - $TMP{$id}";
     push(@OPTSTPPDirectPris, "$key");
  }

  # All TPP's in OPTSTPPPriLessDirects above array
  my %TMP2 = ();
  foreach $id ( sort {$ThirdPartyPayer_Names{$a} cmp $ThirdPartyPayer_Names{$b} } keys %ThirdPartyPayer_Names) {
     next if ( $TPP_PriSecs{$id} !~ /^Pri$/i );
     next if ( $TMP{$id} );
     my $name = $ThirdPartyPayer_Names{$id};
     $TMP2{$id} = $name;
  }
  foreach my $id ( sort { $TMP2{$a} cmp $TMP2{$b} } keys %TMP2 ) {
     my $key  = "${id} - $TMP2{$id}";
     push(@OPTSTPPPriLessDirects, "$key");
  }

  @OPTSTPPPrisPlusDirects = (@OPTSTPPPris,@OPTSTPPDirectPris);

  $sthx->finish;

# print "DBNAME: $DBNAME, TABLE: $TABLE\n";
  # Now determine "Check Name Changes" for Tori. 2013-04-30. jlh
  my $sql = "";
  $sql .= qq#SELECT a.Third_Party_Payer_ID, a.BIN, a.Third_Party_Payer_Name, a.Parent_Name_Key, b.Third_Party_Payer_Name\n#;
  $sql .= qq#FROM \n#;
  $sql .= qq#(SELECT Status, Third_Party_Payer_ID, BIN, Third_Party_Payer_Name, Parent_Name_Key\n#;
  $sql .= qq#FROM $DBNAME.$TABLE \n#;
  $sql .= qq#) a INNER JOIN\n#;
  $sql .= qq#(SELECT Third_Party_Payer_ID, BIN, Third_Party_Payer_Name, Parent_Name_Key\n#;
  $sql .= qq#FROM $DBNAME.$TABLE) b\n#;
  $sql .= qq#on (a.Parent_Name_Key=b.Third_Party_Payer_ID)\n#;
  $sql .= qq#WHERE Status='Active' && a.Third_Party_Payer_ID!=a.Parent_Name_Key\n#;

  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Third_Party_Payer_ID, $BIN, $Third_Party_Payer_Name, $Parent_Name_Key, $Parent_Name) = @row;

     $TPP_Display_Me_Instead_TPPID{$Third_Party_Payer_ID} = $Parent_Name_Key;
     $TPP_Display_Me_Instead_Names{$Third_Party_Payer_ID} = $Parent_Name;
  }

  $sthx->finish;
  $dbm->disconnect;

  print "<hr size=4 color=red noshade>\n" if ($incdebug);

}

#______________________________________________________________________________

sub readCompanies {

  my ($NoTest, $PROGRAM, $inCompanyID) = @_;

# my $debug++;
# my $incdebug++;

  print "<hr>sub readCompanies: Entry. NoTest: $NoTest, PROGRAM: $PROGRAM, inCompanyID: $inCompanyID<br>\n" if ( $incdebug );

  $RBSPharmaciesCount   = 0;
  $ReconPharmaciesCount = 0;
  my $dbin    = "CODBNAME";
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);


  my $sql = "
SELECT Company_ID, Company_Name, Store_User, Store_Pass, Status_Cred, Type, Legal_Name, Business_Phone, Address, City, State, Zip, County, Email_Address, Fax_Number, Mailing_Address, Mailing_City, Mailing_State, Mailing_Zip, Website, Comm_Pref, Send_Reports_To, State_Sales_Tx_ID, Cred_Fee, Last_Onsite_Visit_Date, Active_Date_Cred, Term_Date_Cred, Inactivate_Date, FEIN, Fed_Tax_Classification, Affiliate_Name, Affiliate_Customer_ID, Billing, Owner_Contact_Name, Owner_Contact_CellPhone, Owner_Contact_Phone, Owner_Contact_Phone_Ext, Owner_Contact_Email, Owner_Contact_Fax, Owner_Contact_Address, Owner_Contact_City, Owner_Contact_State, Owner_Contact_Zip, Primary_Contact_Name, Primary_Contact_CellPhone, Primary_Contact_Phone, Primary_Contact_Phone_Ext, Primary_Contact_Email, Primary_Contact_Fax, Primary_Contact_Address, Primary_Contact_City, Primary_Contact_State, Primary_Contact_Zip, Secondary_Contact_Name, Secondary_Contact_CellPhone, Secondary_Contact_Phone, Secondary_Contact_Phone_Ext, Secondary_Contact_Email, Secondary_Contact_Fax, Secondary_Contact_Address, Secondary_Contact_City, Secondary_Contact_State, Secondary_Contact_Zip, Compliance_Contact_Name, Compliance_Contact_CellPhone, Compliance_Contact_Phone, Compliance_Contact_Phone_Ext, Compliance_Contact_Email, Compliance_Contact_Fax, Compliance_Contact_Address, Compliance_Contact_City, Compliance_Contact_State, Compliance_Contact_Zip, Credentialing_Contact_Name, Credentialing_Contact_CellPhone, Credentialing_Contact_Phone, Credentialing_Contact_Phone_Ext, Credentialing_Contact_Email, Credentialing_Contact_Fax, Credentialing_Contact_Address, Credentialing_Contact_City, Credentialing_Contact_State, Credentialing_Contact_Zip, Communication1_Contact_Name, Communication1_Contact_CellPhone, Communication1_Contact_Phone, Communication1_Contact_Phone_Ext, Communication1_Contact_Email, Communication1_Contact_Fax, Communication1_Contact_Address, Communication1_Contact_City, Communication1_Contact_State, Communication1_Contact_Zip, Communication2_Contact_Name, Communication2_Contact_CellPhone, Communication2_Contact_Phone, Communication2_Contact_Phone_Ext, Communication2_Contact_Email, Communication2_Contact_Fax, Communication2_Contact_Address, Communication2_Contact_City, Communication2_Contact_State, Communication2_Contact_Zip, Communication3_Contact_Name, Communication3_Contact_CellPhone, Communication3_Contact_Phone, Communication3_Contact_Phone_Ext, Communication3_Contact_Email, Communication3_Contact_Fax, Communication3_Contact_Address, Communication3_Contact_City, Communication3_Contact_State, Communication3_Contact_Zip, Invoicing_Contact_Name, Invoicing_Contact_CellPhone, Invoicing_Contact_Phone, Invoicing_Contact_Phone_Ext, Invoicing_Contact_Email, Invoicing_Contact_Fax, Invoicing_Contact_Address, Invoicing_Contact_City, Invoicing_Contact_State, Invoicing_Contact_Zip, Hours_of_Operation_MF, Hours_of_Operation_Sat, Hours_of_Operation_Sun, Notes
  
FROM $DBNAME.$TABLE ";
#;

  $sql .= " WHERE (1=1) ";
  if ( $inCompanyID ) {
     $sql .= " && Company_ID=$inCompanyID";
  }
  if ( $NoTest ) {
     $sql .= " && Company_ID < 10000";
  }

  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  push(@OPTSPharmacies, "All");

  while ( my @row = $sthx->fetchrow_array() ) {

      my ($Company_ID, $Company_Name, $Store_User, $Store_Pass, $Status_Cred, $Type, $Legal_Name, $Business_Phone, $Address, $City, $State, $Zip, $County, $Email_Address, $Fax_Number, $Mailing_Address, $Mailing_City, $Mailing_State, $Mailing_Zip, $Website, $Comm_Pref, $Send_Reports_To, $State_Sales_Tx_ID, $Cred_Fee, $Last_Onsite_Visit_Date, $Active_Date_Cred, $Term_Date_Cred, $Inactivate_Date, $FEIN, $Fed_Tax_Classification, $Affiliate_Name, $Affiliate_Customer_ID, $Billing, $Owner_Contact_Name, $Owner_Contact_CellPhone, $Owner_Contact_Phone, $Owner_Contact_Phone_Ext, $Owner_Contact_Email, $Owner_Contact_Fax, $Owner_Contact_Address, $Owner_Contact_City, $Owner_Contact_State, $Owner_Contact_Zip, $Primary_Contact_Name, $Primary_Contact_CellPhone, $Primary_Contact_Phone, $Primary_Contact_Phone_Ext, $Primary_Contact_Email, $Primary_Contact_Fax, $Primary_Contact_Address, $Primary_Contact_City, $Primary_Contact_State, $Primary_Contact_Zip, $Secondary_Contact_Name, $Secondary_Contact_CellPhone, $Secondary_Contact_Phone, $Secondary_Contact_Phone_Ext, $Secondary_Contact_Email, $Secondary_Contact_Fax, $Secondary_Contact_Address, $Secondary_Contact_City, $Secondary_Contact_State, $Secondary_Contact_Zip, $Compliance_Contact_Name, $Compliance_Contact_CellPhone, $Compliance_Contact_Phone, $Compliance_Contact_Phone_Ext, $Compliance_Contact_Email, $Compliance_Contact_Fax, $Compliance_Contact_Address, $Compliance_Contact_City, $Compliance_Contact_State, $Compliance_Contact_Zip, $Credentialing_Contact_Name, $Credentialing_Contact_CellPhone, $Credentialing_Contact_Phone, $Credentialing_Contact_Phone_Ext, $Credentialing_Contact_Email, $Credentialing_Contact_Fax, $Credentialing_Contact_Address, $Credentialing_Contact_City, $Credentialing_Contact_State, $Credentialing_Contact_Zip, $Communication1_Contact_Name, $Communication1_Contact_CellPhone, $Communication1_Contact_Phone, $Communication1_Contact_Phone_Ext, $Communication1_Contact_Email, $Communication1_Contact_Fax, $Communication1_Contact_Address, $Communication1_Contact_City, $Communication1_Contact_State, $Communication1_Contact_Zip, $Communication2_Contact_Name, $Communication2_Contact_CellPhone, $Communication2_Contact_Phone, $Communication2_Contact_Phone_Ext, $Communication2_Contact_Email, $Communication2_Contact_Fax, $Communication2_Contact_Address, $Communication2_Contact_City, $Communication2_Contact_State, $Communication2_Contact_Zip, $Communication3_Contact_Name, $Communication3_Contact_CellPhone, $Communication3_Contact_Phone, $Communication3_Contact_Phone_Ext, $Communication3_Contact_Email, $Communication3_Contact_Fax, $Communication3_Contact_Address, $Communication3_Contact_City, $Communication3_Contact_State, $Communication3_Contact_Zip, $Invoicing_Contact_Name, $Invoicing_Contact_CellPhone, $Invoicing_Contact_Phone, $Invoicing_Contact_Phone_Ext, $Invoicing_Contact_Email, $Invoicing_Contact_Fax, $Invoicing_Contact_Address, $Invoicing_Contact_City, $Invoicing_Contact_State, $Invoicing_Contact_Zip, $Hours_of_Operation_MF, $Hours_of_Operation_Sat, $Hours_of_Operation_Sun, $Notes) = @row;

     $Company_IDs{$Company_ID}++;
     $Company_ID{$Company_ID}                               = $Company_ID;
     $Company_Name{$Company_ID}                             = $Company_Name;
     $Company_Store_User{$Company_ID}                       = $Store_User;
     $Company_Store_Pass{$Company_ID}                       = $Store_Pass;
     $Company_Status_Cred{$Company_ID}                      = $Status_Cred;
     $Company_Type{$Company_ID}                             = $Type;
     $Company_Legal_Name{$Company_ID}                       = $Legal_Name;
     $Company_Business_Phone{$Company_ID}                   = $Business_Phone;
     $Company_Address{$Company_ID}                          = $Address;
     $Company_City{$Company_ID}                             = $City;
     $Company_State{$Company_ID}                            = $State;
     $Company_Zip{$Company_ID}                              = $Zip;
     $Company_County{$Company_ID}                           = $County;
     $Company_Email_Address{$Company_ID}                    = $Email_Address;
     $Company_Fax_Number{$Company_ID}                       = $Fax_Number;
     $Company_Mailing_Address{$Company_ID}                  = $Mailing_Address;
     $Company_Mailing_City{$Company_ID}                     = $Mailing_City;
     $Company_Mailing_State{$Company_ID}                    = $Mailing_State;
     $Company_Mailing_Zip{$Company_ID}                      = $Mailing_Zip;
     $Company_Website{$Company_ID}                          = $Website;
     $Company_Comm_Pref{$Company_ID}                        = $Comm_Pref;
     $Company_Send_Reports_To{$Company_ID}                  = $Send_Reports_To;
     $Company_State_Sales_Tx_ID{$Company_ID}                = $State_Sales_Tx_ID;
     $Company_Cred_Fee{$Company_ID}                         = $Cred_Fee;
     $Company_Last_Onsite_Visit_Date{$Company_ID}           = $Last_Onsite_Visit_Date;
     $Company_Active_Date_Cred{$Company_ID}                 = $Active_Date_Cred;
     $Company_Term_Date_Cred{$Company_ID}                   = $Term_Date_Cred;
     $Company_Inactivate_Date{$Company_ID}                  = $Inactivate_Date;
     $Company_FEIN{$Company_ID}                             = $FEIN;
     $Company_Fed_Tax_Classification{$Company_ID}           = $Fed_Tax_Classification;
     $Company_Affiliate_Name{$Company_ID}                   = $Affiliate_Name;
     $Company_Affiliate_Customer_ID{$Company_ID}            = $Affiliate_Customer_ID;
     $Company_Billing{$Company_ID}                          = $Billing;
     $Company_Owner_Contact_Name{$Company_ID}               = $Owner_Contact_Name;
     $Company_Owner_Contact_CellPhone{$Company_ID}          = $Owner_Contact_CellPhone;
     $Company_Owner_Contact_Phone{$Company_ID}              = $Owner_Contact_Phone;
     $Company_Owner_Contact_Phone_Ext{$Company_ID}          = $Owner_Contact_Phone_Ext;
     $Company_Owner_Contact_Email{$Company_ID}              = $Owner_Contact_Email;
     $Company_Owner_Contact_Fax{$Company_ID}                = $Owner_Contact_Fax;
     $Company_Owner_Contact_Address{$Company_ID}            = $Owner_Contact_Address;
     $Company_Owner_Contact_City{$Company_ID}               = $Owner_Contact_City;
     $Company_Owner_Contact_State{$Company_ID}              = $Owner_Contact_State;
     $Company_Owner_Contact_Zip{$Company_ID}                = $Owner_Contact_Zip;
     $Company_Primary_Contact_Name{$Company_ID}             = $Primary_Contact_Name;
     $Company_Primary_Contact_CellPhone{$Company_ID}        = $Primary_Contact_CellPhone;
     $Company_Primary_Contact_Phone{$Company_ID}            = $Primary_Contact_Phone;
     $Company_Primary_Contact_Phone_Ext{$Company_ID}        = $Primary_Contact_Phone_Ext;
     $Company_Primary_Contact_Email{$Company_ID}            = $Primary_Contact_Email;
     $Company_Primary_Contact_Fax{$Company_ID}              = $Primary_Contact_Fax;
     $Company_Primary_Contact_Address{$Company_ID}          = $Primary_Contact_Address;
     $Company_Primary_Contact_City{$Company_ID}             = $Primary_Contact_City;
     $Company_Primary_Contact_State{$Company_ID}            = $Primary_Contact_State;
     $Company_Primary_Contact_Zip{$Company_ID}              = $Primary_Contact_Zip;
     $Company_Secondary_Contact_Name{$Company_ID}           = $Secondary_Contact_Name;
     $Company_Secondary_Contact_CellPhone{$Company_ID}      = $Secondary_Contact_CellPhone;
     $Company_Secondary_Contact_Phone{$Company_ID}          = $Secondary_Contact_Phone;
     $Company_Secondary_Contact_Phone_Ext{$Company_ID}      = $Secondary_Contact_Phone_Ext;
     $Company_Secondary_Contact_Email{$Company_ID}          = $Secondary_Contact_Email;
     $Company_Secondary_Contact_Fax{$Company_ID}            = $Secondary_Contact_Fax;
     $Company_Secondary_Contact_Address{$Company_ID}        = $Secondary_Contact_Address;
     $Company_Secondary_Contact_City{$Company_ID}           = $Secondary_Contact_City;
     $Company_Secondary_Contact_State{$Company_ID}          = $Secondary_Contact_State;
     $Company_Secondary_Contact_Zip{$Company_ID}            = $Secondary_Contact_Zip;
     $Company_Compliance_Contact_Name{$Company_ID}          = $Compliance_Contact_Name;
     $Company_Compliance_Contact_CellPhone{$Company_ID}     = $Compliance_Contact_CellPhone;
     $Company_Compliance_Contact_Phone{$Company_ID}         = $Compliance_Contact_Phone;
     $Company_Compliance_Contact_Phone_Ext{$Company_ID}     = $Compliance_Contact_Phone_Ext;
     $Company_Compliance_Contact_Email{$Company_ID}         = $Compliance_Contact_Email;
     $Company_Compliance_Contact_Fax{$Company_ID}           = $Compliance_Contact_Fax;
     $Company_Compliance_Contact_Address{$Company_ID}       = $Compliance_Contact_Address;
     $Company_Compliance_Contact_City{$Company_ID}          = $Compliance_Contact_City;
     $Company_Compliance_Contact_State{$Company_ID}         = $Compliance_Contact_State;
     $Company_Compliance_Contact_Zip{$Company_ID}           = $Compliance_Contact_Zip;
     $Company_Credentialing_Contact_Name{$Company_ID}       = $Credentialing_Contact_Name;
     $Company_Credentialing_Contact_CellPhone{$Company_ID}  = $Credentialing_Contact_CellPhone;
     $Company_Credentialing_Contact_Phone{$Company_ID}      = $Credentialing_Contact_Phone;
     $Company_Credentialing_Contact_Phone_Ext{$Company_ID}  = $Credentialing_Contact_Phone_Ext;
     $Company_Credentialing_Contact_Email{$Company_ID}      = $Credentialing_Contact_Email;
     $Company_Credentialing_Contact_Fax{$Company_ID}        = $Credentialing_Contact_Fax;
     $Company_Credentialing_Contact_Address{$Company_ID}    = $Credentialing_Contact_Address;
     $Company_Credentialing_Contact_City{$Company_ID}       = $Credentialing_Contact_City;
     $Company_Credentialing_Contact_State{$Company_ID}      = $Credentialing_Contact_State;
     $Company_Credentialing_Contact_Zip{$Company_ID}        = $Credentialing_Contact_Zip;
     $Company_Communication1_Contact_Name{$Company_ID}      = $Communication1_Contact_Name;
     $Company_Communication1_Contact_CellPhone{$Company_ID} = $Communication1_Contact_CellPhone;
     $Company_Communication1_Contact_Phone{$Company_ID}     = $Communication1_Contact_Phone;
     $Company_Communication1_Contact_Phone_Ext{$Company_ID} = $Communication1_Contact_Phone_Ext;
     $Company_Communication1_Contact_Email{$Company_ID}     = $Communication1_Contact_Email;
     $Company_Communication1_Contact_Fax{$Company_ID}       = $Communication1_Contact_Fax;
     $Company_Communication1_Contact_Address{$Company_ID}   = $Communication1_Contact_Address;
     $Company_Communication1_Contact_City{$Company_ID}      = $Communication1_Contact_City;
     $Company_Communication1_Contact_State{$Company_ID}     = $Communication1_Contact_State;
     $Company_Communication1_Contact_Zip{$Company_ID}       = $Communication1_Contact_Zip;
     $Company_Communication2_Contact_Name{$Company_ID}      = $Communication2_Contact_Name;
     $Company_Communication2_Contact_CellPhone{$Company_ID} = $Communication2_Contact_CellPhone;
     $Company_Communication2_Contact_Phone{$Company_ID}     = $Communication2_Contact_Phone;
     $Company_Communication2_Contact_Phone_Ext{$Company_ID} = $Communication2_Contact_Phone_Ext;
     $Company_Communication2_Contact_Email{$Company_ID}     = $Communication2_Contact_Email;
     $Company_Communication2_Contact_Fax{$Company_ID}       = $Communication2_Contact_Fax;
     $Company_Communication2_Contact_Address{$Company_ID}   = $Communication2_Contact_Address;
     $Company_Communication2_Contact_City{$Company_ID}      = $Communication2_Contact_City;
     $Company_Communication2_Contact_State{$Company_ID}     = $Communication2_Contact_State;
     $Company_Communication2_Contact_Zip{$Company_ID}       = $Communication2_Contact_Zip;
     $Company_Communication3_Contact_Name{$Company_ID}      = $Communication3_Contact_Name;
     $Company_Communication3_Contact_CellPhone{$Company_ID} = $Communication3_Contact_CellPhone;
     $Company_Communication3_Contact_Phone{$Company_ID}     = $Communication3_Contact_Phone;
     $Company_Communication3_Contact_Phone_Ext{$Company_ID} = $Communication3_Contact_Phone_Ext;
     $Company_Communication3_Contact_Email{$Company_ID}     = $Communication3_Contact_Email;
     $Company_Communication3_Contact_Fax{$Company_ID}       = $Communication3_Contact_Fax;
     $Company_Communication3_Contact_Address{$Company_ID}   = $Communication3_Contact_Address;
     $Company_Communication3_Contact_City{$Company_ID}      = $Communication3_Contact_City;
     $Company_Communication3_Contact_State{$Company_ID}     = $Communication3_Contact_State;
     $Company_Communication3_Contact_Zip{$Company_ID}       = $Communication3_Contact_Zip;
     $Company_Invoicing_Contact_Name{$Company_ID}           = $Invoicing_Contact_Name;
     $Company_Invoicing_Contact_CellPhone{$Company_ID}      = $Invoicing_Contact_CellPhone;
     $Company_Invoicing_Contact_Phone{$Company_ID}          = $Invoicing_Contact_Phone;
     $Company_Invoicing_Contact_Phone_Ext{$Company_ID}      = $Invoicing_Contact_Phone_Ext;
     $Company_Invoicing_Contact_Email{$Company_ID}          = $Invoicing_Contact_Email;
     $Company_Invoicing_Contact_Fax{$Company_ID}            = $Invoicing_Contact_Fax;
     $Company_Invoicing_Contact_Address{$Company_ID}        = $Invoicing_Contact_Address;
     $Company_Invoicing_Contact_City{$Company_ID}           = $Invoicing_Contact_City;
     $Company_Invoicing_Contact_State{$Company_ID}          = $Invoicing_Contact_State;
     $Company_Invoicing_Contact_Zip{$Company_ID}            = $Invoicing_Contact_Zip;
     $Company_Hours_of_Operation_MF{$Company_ID}            = $Hours_of_Operation_MF;
     $Company_Hours_of_Operation_Sat{$Company_ID}           = $Hours_of_Operation_Sat;
     $Company_Hours_of_Operation_Sun{$Company_ID}           = $Hours_of_Operation_Sun;
     $Company_Notes{$Company_ID}                            = $Notes;

  }
  $sthx->finish;
  $dbm->disconnect;

  foreach $id ( sort keys %Company_Names) {
     $name = $Company_Names{$id};
     $key  = "${id} - $name";
     push(@OPTSCompanies, "$key");
     $HASHCompanies{$key} = $name;
  }
  $inCompanyID = $Company_ID;
  
  print "sub readCompanies: Exit. RBSPharmaciesCount: $RBSPharmaciesCount, ReconPharmaciesCount: $ReconPharmaciesCount<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ( $incdebug );

}

#______________________________________________________________________________

sub readTPPPriSec {

# my $debug++;
# my $incdebug++;

  print "<hr>sub readTPPPriSec: Entry.<br>\n" if ( $incdebug );

  my $dbin    = "PSDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT TPP_Pri_Sec_ID, TPP_Pri_ID, TPP_Sec_ID, Start_Date, Term_Date, Notes FROM $DBNAME.$TABLE";
  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($TPP_Pri_Sec_ID, $TPP_Pri_ID, $TPP_Sec_ID, $Start_Date, $Term_Date, $Notes) = @row;
#    print "$TPP_Pri_Sec_ID, $TPP_Pri_ID, $TPP_Sec_ID, $Start_Date, $Term_Date, $Notes<br>\n";

     $key = $TPP_Pri_Sec_ID;

     $Start_Date =~ s/\s*00:00:00//g;
     $Term_Date  =~ s/\s*00:00:00//g;

     $TPPPS_Pri_Sec_IDs{$key}++;
     $TPPPS_Pri_IDs{$key}       = $TPP_Pri_ID;
     $TPPPS_Sec_IDs{$key}       = $TPP_Sec_ID;
     # print "TPPPS_Pri_IDs($key): $TPPPS_Pri_IDs{$key}, TPPPS_Sec_IDs($key): $TPPPS_Sec_IDs{$key}<br>\n";
     $TPPPS_Start_Dates{$key}   = $Start_Date;
     $TPPPS_Term_Dates{$key}    = $Term_Date;
     $TPPPS_Notes{$key}         = $Notes;

     $Reverse_TPPPS_Pri_IDs{$TPP_Pri_ID} = $key;	# Reverse lookup for lookups
     $Reverse_TPPPS_Sec_IDs{$TPP_Sec_ID} = $key;	# Reverse lookup for lookups

  }
  $sthx->finish;
  $dbm->disconnect;

  $readTPPPriSec_DONE++;

  print "<hr>sub readTPPPriSec: Exit.<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ($incdebug);

}

#______________________________________________________________________________

sub readVendors {

# my $debug++;
# my $incdebug++;

  print "<hr>sub readVendors: Entry.<br>\n" if ( $incdebug );

  my $dbin    = "VNDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT Vendor_ID, Vendor_Name, Status, Business_Phone, Commission, Commission_Type, Preferred, Address, City, State, Zip, Primary_Contact_Name, Primary_Contact_Phone, Primary_Contact_Phone_Ext, Primary_Contact_Email, Secondary_Contact_Email, Website, Logo, Documents_Path, Documents FROM $DBNAME.$TABLE";
  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Vendor_ID, $Vendor_Name, $Status, $BusinessPhone, $Commission, $Commission_Type, $Preferred, $Address, $City, $State, $Zip, $Primary_Contact_Name, $Primary_Contact_Phone, $Primary_Contact_Phone_Ext, $Primary_Contact_Email, $Secondary_Contact_Email, $Website, $Logo, $Documents_Path, $Documents) = @row;
     $Vendor_IDs{$Vendor_ID}++;
     $Vendor_Names{$Vendor_ID}           = $Vendor_Name;
     $Vendor_Statuses{$Vendor_ID}        = $Status;
     $Vendor_Business_Phones{$Vendor_ID} = $BusinessPhone;
     $Vendor_Commissions{$Vendor_ID}     = $Commission;
     $Vendor_CommissionTypes{$Vendor_ID} = $CommissionType;
     $Vendor_Preferreds{$Vendor_ID}      = $Preferred;
     $Vendor_Addresses{$Vendor_ID}       = $Address;
     $Vendor_Citys{$Vendor_ID}           = $City;
     $Vendor_States{$Vendor_ID}          = $State;
     $Vendor_Zips{$Vendor_ID}            = $Zip;
     $Vendor_Pri_Contact_Names{$Vendor_ID}      = $Primary_Contact_Name;
     $Vendor_Pri_Contact_Phones{$Vendor_ID}     = $Primary_Contact_Phone;
     $Vendor_Pri_Contact_Phone_Exts{$Vendor_ID} = $Primary_Contact_Phone_Ext;
     $Vendor_Pri_Contact_Emails{$Vendor_ID}     = $Primary_Contact_Email;
     $Vendor_Sec_Contact_Emails{$Vendor_ID}     = $Secondary_Contact_Email;
     $Vendor_Websites{$Vendor_ID}               = $Website;
     $Vendor_Logos{$Vendor_ID}                  = $Logo;
	 $Vendor_Doc_Path{$Vendor_ID}               = $Documents_Path;
	 $Vendor_Documents{$Vendor_ID}              = $Documents;
#    print "sub readVendors: Vendor_ID: $Vendor_ID, Vendor_Name: $Vendor_Name<br>\n" if ($incdebug);
  }
  $sthx->finish;
  $dbm->disconnect;

  my %TMP = ();
  foreach $id ( sort {$Vendor_Names{$a} cmp $Vendor_Names{$b} } keys %Vendor_Names) {
     my $name = $Vendor_Names{$id};
     $TMP{$id} = $name;
  }
  foreach my $id ( sort { $TMP{$a} cmp $TMP{$b} } keys %TMP ) {
     my $key  = "${id} - $TMP{$id}";
     push(@OPTSVendors, "$key");
  }

  print "sub readVendors: Exit.<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ($incdebug);

}

#______________________________________________________________________________

sub readPharmacysVendors {

# my $debug++;
# my $incdebug++;

  print "<hr>sub readPharmacysVendors: Entry.<br>\n" if ( $incdebug );

  my $DBNAME  = 'officedb';
  my $TABLE   = 'pharmacys_vendors';
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "
SELECT Pharmacys_Vendor_ID, Pharmacy_ID, Internal_Vendor_ID, Start_Date, Term_Date, User_ID, Password, Notes
FROM $DBNAME.$TABLE
GROUP BY Pharmacy_ID, Internal_Vendor_ID
";

  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Pharmacys_Vendor_ID, $Pharmacy_ID, $Internal_Vendor_ID, $Start_Date, $Term_Date, $User_ID, $Password, $Notes) = @row;

#    print "Pharmacys_Vendor_ID: $Pharmacys_Vendor_ID, Pharmacy_ID: $Pharmacy_ID, Start_Date: $Start_Date, Term_Date: $Term_Date<br>\n" if ($incdebug);

     $Start_Date =~ s/\s*00:00:00//g;
     $Term_Date  =~ s/\s*00:00:00//g;

     $PVPharmacys_Vendor_IDs{$Pharmacys_Vendor_ID}++;
     $PVPharmacy_IDs{$Pharmacys_Vendor_ID}        = $Pharmacy_ID;
     $PVInternal_Vendor_IDs{$Pharmacys_Vendor_ID} = $Internal_Vendor_ID;
     $PVStart_Dates{$Pharmacys_Vendor_ID}         = $Start_Date;
     $PVTerm_Dates{$Pharmacys_Vendor_ID}          = $Term_Date;
     $PVUser_IDs{$Pharmacys_Vendor_ID}            = $User_ID;
     $PVPasswords{$Pharmacys_Vendor_ID}           = $Password;
     $PVNotes{$Pharmacys_Vendor_ID}               = $Notes;

#    print "sub readPharmacysVendors: Pharmacys_Vendor_ID: $Pharmacys_Vendor_ID<br>\n" if ($incdebug);
  }
  $sthx->finish;
  $dbm->disconnect;

  if ( $incdebug ) {
     print "sub readPharmacysVendors: Exit.<br>\n";
     print "<hr size=4 color=red noshade>\n";
  }
}

#______________________________________________________________________________

sub readPharmacysTPPs {

# my $debug++;

  print "<hr>sub readPharmacysTPPs: Entry.<br>\n" if ( $debug );

  my $dbin    = "PTDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT Pharmacys_TPP_ID, Pharmacy_ID, Internal_TPP_ID, Start_Date, Term_Date, User_ID, Password, Notes FROM $DBNAME.$TABLE";
  print "sql:<br>$sql<br>\n" if ($debug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Pharmacys_TPP_ID, $Pharmacy_ID, $Internal_TPP_ID, $Start_Date, $Term_Date, $User_ID, $Password, $Notes) = @row;

#    print "Pharmacys_TPP_ID: $Pharmacys_TPP_ID, Pharmacy_ID: $Pharmacy_ID, Start_Date: $Start_Date, Term_Date: $Term_Date<br>\n" if ($incdebug);

     $Start_Date =~ s/\s*00:00:00//g;
     $Term_Date  =~ s/\s*00:00:00//g;

     $PTPharmacys_TPP_IDs{$Pharmacys_TPP_ID}++;
     $PTPharmacy_IDs{$Pharmacys_TPP_ID}        = $Pharmacy_ID;
     $PTInternal_TPP_IDs{$Pharmacys_TPP_ID}    = $Internal_TPP_ID;
     $PTStart_Dates{$Pharmacys_TPP_ID}         = $Start_Date;
     $PTTerm_Dates{$Pharmacys_TPP_ID}          = $Term_Date;
     $PTUser_IDs{$Pharmacys_TPP_ID}            = $User_ID;
     $PTPasswords{$Pharmacys_TPP_ID}           = $Password;
     $PTNotes{$Pharmacys_TPP_ID}               = $Notes;

#    print "sub readPharmacysTPPs: Pharmacys_TPP_ID: $Pharmacys_TPP_ID<br>\n" if ($debug);
  }
  $sthx->finish;
  $dbm->disconnect;

  if ( $debug ) {
     print "sub readPharmacysTPPs: Exit.<br>\n";
     print "<hr size=4 color=red noshade>\n";
  }
}


#______________________________________________________________________________

sub readCredFees {

  my ($CFNCPDP) = @_;

# my $debug++;
# my $incdebug++;

  use Scalar::Util qw(looks_like_number);

  print "<hr>sub readCredFees: Entry.<br>\n" if ( $incdebug );

  my $DBNAME  = "Pharmassess";
  my $TABLE   = "Credentialing.Employees";

  # Blank out hashes!

  my $LIMITSINGLE         = "";
  my $Cred_Fee_Local      =  0;

  $Cred_Fee = $Pharmacy_Cred_Fees{$CFNCPDP};
  print "CFNCPDP: $CFNCPDP, Cred_Fee: $Cred_Fee<br>\n" if ($incdebug);

  if ( looks_like_number($Cred_Fee) || $CFNCPDP > 0 ) {
     $Cred_Fee_Local = $Cred_Fee || 0;
     $LIMITSINGLE = "&& OfficeDb.Pharmacy.Pharmacy_ID=$CFNCPDP " if ($CFNCPDP > 0);
  } else {
     $Cred_Fee_Local = 95;
  }
  print "LIMITSINGLE: $LIMITSINGLE<br>\n" if ($incdebug);
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT officedb.pharmacy.Pharmacy_ID, officedb.pharmacy.NCPDP, Pharmacy_Name as 'Pharmacy Name', count(*) as Employees, 
                    IF (count(*) > 20, ((count(*)-20)*1.25), 0)     as 'Overage Fee',
                    IF (count(*) > 20, ((count(*)-20)*1.25)+$Cred_Fee_Local, $Cred_Fee_Local) as 'Monthly Charge'
               FROM pharmassess.credentialing_employees 
         RIGHT JOIN officedb.pharmacy
                 ON officedb.pharmacy.Pharmacy_ID = credentialing_employees.Pharmacy_ID
              WHERE 1=1
                 && credentialing_employees.status = 'Active'
                 && officedb.pharmacy.Type LIKE '%Cred%'
                 $LIMITSINGLE 
           GROUP BY Pharmacy_ID
           ORDER BY Pharmacy_Name DESC";

  print "sql:<br><pre>$sql</pre><br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Pharmacy_ID, $NCPDP, $Pharmacy_Name, $Employees, $Overage_Fee, $Monthly_Charge) = @row;

     $CredFeesPharmacyNames{$Pharmacy_ID}  = $Pharmacy_Name;
     $CredFeesEmployees{$Pharmacy_ID}      = $Employees;
     $CredFeesOverageFees{$Pharmacy_ID}    = $Overage_Fee;
     $CredFeesMonthlyCharges{$Pharmacy_ID} = $Monthly_Charge;

  }
  $sthx->finish;
  $dbm->disconnect;

  print "<hr>sub readCredFees: Exit.<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ($incdebug);

}

#______________________________________________________________________________

sub readReconExceptionRouting2 {

# my $debug++;
# my $incdebug++;

  my $DBNAME;
  my $TABLE  = "PlanExceptions";

  print "<hr>sub readReconExceptionRouting2: Entry.<br>\n" if ( $debug );

  if ( $testing ) {
     if ( $WHICHDB ) {
        $DBNAME = $WHICHDB;
     }
  }
  $DBNAME = "ReconRxDB" if ( $DBNAME =~ /^\s*$/ );

  %EBINS  = ();
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { PrintError => 1, RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT BinFrom, PCN, GroupID, BinTo, dbkeyRouteToBin, Comments FROM $DBNAME.$TABLE ";
  $sql .= " ORDER BY BinFrom, PCN, GroupID ";
  print "sql:<br>$sql<br>\n" if ($debug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($BinFrom, $PCN, $GroupID, $BinTo, $dbkeyRouteToBin, $Comments) = @row;

     $BinFrom =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
     $PCN     =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
     $GroupID =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
     $BinTo   =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
     $Comments=~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces

     $PCN     = "ANY" if ( $PCN     =~ /^\s*$|ANY/i );
     $GroupID = "ANY" if ( $GroupID =~ /^\s*$|ANY/i );

     $BinFrom1 = $BinFrom + 0;
     $BinTo1   = $BinTo + 0;
     $BinFrom = substr("000000" . $BinFrom, -6);
     $BinTo   = substr("000000" . $BinTo,   -6);

     $EBINS{$BinFrom1}++;
     $EBINS{$BinFrom}++;

     $key = "$BinFrom1##$PCN##$GroupID";
     print "readReconExceptionRouting2- EBINS($BinFrom1): $EBINS{$BinFrom1}, key: $key<br>\n" if ($debug);
     $ExceptionBins{$key}     = $BinTo1;
     $ExceptiondbKeys{$key}   = $dbkeyRouteToBin;
     $ExceptionComments{$key} = $Comments;

     $key = "$BinFrom##$PCN##$GroupID";
     print "readReconExceptionRouting2- EBINS($BinFrom): $EBINS{$BinFrom}, key: $key<br>\n" if ($debug);
     $ExceptionBins{$key}     = $BinTo;
     $ExceptiondbKeys{$key}   = $dbkeyRouteToBin;
     $ExceptionComments{$key} = $Comments;


# Won't work anymore!
#####################     $Reverse_ExceptionBins{$RouteToBin} = $BIN;	# Reverse lookup for lookups


  }

  $sthx->finish;
  $dbm->disconnect;

  $readReconExceptionRouting2++;

  if ( $debug ) {
     print "\n2. Keys to ExceptionBins<br>\n";
     foreach $key (sort keys %ExceptionBins) {
        print "key: $key<br>\n";
     }
  }

  print "<hr size=4 color=red noshade>\n" if ($debug);

}

#______________________________________________________________________________

sub readReconExceptionRouting {

# my $debug++;

  my $dbin    = "REDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};

  if ( $testing ) {
     $DBNAME = $WHICHDB;
  }
  $DBNAME = "ReconRxDB" if ( $DBNAME =~ /^\s*$/ );

  print "<hr>sub readReconExceptionRouting: Entry. dbin: $dbin, DBNAME: $DBNAME, TABLE: $TABLE<br>\n" if ( $debug );

#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { PrintError => 1, RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "
SELECT id, BIN, RouteToBin, dbkeyRouteToBin, Comments
FROM $DBNAME.$TABLE";
  print "sql:<br>$sql<br>\n" if ($debug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  print "<hr size=4 color=red noshade>\n" if ($debug);
  while ( my @row = $sthx->fetchrow_array() ) {
     my ($id, $BIN, $RouteToBin, $dbkeyRouteToBin, $Comments) = @row;
     print qq#($id, $BIN, $RouteToBin, $dbkeyRouteToBin, $Comments)<br>\n# if ($debug);

     $BIN  = sprintf("%06d", $BIN);
     $BIN1 = $BIN + 0;
     $ExceptionBins{$BIN}     = $RouteToBin;
     $ExceptiondbKeys{$BIN}   = $dbkeyRouteToBin;
     $ExceptionComments{$BIN} = $Comments;

     $ExceptionBins{$BIN1}     = $RouteToBin;
     $ExceptiondbKeys{$BIN1}   = $dbkeyRouteToBin;
     $ExceptionComments{$BIN1} = $Comments;
     if ( $debug ) {
        print "DO BIN1: $BIN1\n";
        print "ExceptionBins($BIN1)     : $ExceptionBins{$BIN1}<br>\n";
        print "ExceptiondbKeys($BIN1)   : $ExceptiondbKeys{$BIN1}<br>\n";
        print "ExceptionComments($BIN1) : $ExceptionComments{$BIN1}<br>\n";
        print "DO BIN: $BIN\n";
        print "ExceptionBins($BIN)      : $ExceptionBins{$BIN}<br>\n";
        print "ExceptiondbKeys($BIN)    : $ExceptiondbKeys{$BIN}<br>\n";
        print "ExceptionComments($BIN)  : $ExceptionComments{$BIN}<br>\n";
        print "<hr size=4 color=red noshade>\n";
     }

     $Reverse_ExceptionBins{$RouteToBin} = $BIN;	# Reverse lookup for lookups

  }
  $sthx->finish;
  $dbm->disconnect;

  $readReconExceptionRouting++;

  if ( $debug ) {
     print "\n1. Keys to ExceptionBins\n";
     foreach $key (sort keys %ExceptionBins) {
        print "key: $key\n";
     }
  }

  print "<hr size=4 color=red noshade>\n" if ($debug);

}

#______________________________________________________________________________

sub readAffiliates {

# my $debug++;
# my $incdebug++;

  print "<hr>sub readAffiliates: Entry.<br>\n" if ( $incdebug );

  my $dbin    = "AFDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT Affiliate_ID, Affiliate_Name, Affiliate_NickName, Status, Business_Phone, Fax_Number, Address, City, State, Zip, Website, Email_Address, Notes, Inactivate_Date, Primary_Contact_Name, Primary_Contact_CellPhone, Primary_Contact_Phone, Primary_Contact_Phone_Ext, Primary_Contact_Email, Primary_Contact_Fax, Primary_Contact_Address, Primary_Contact_City, Primary_Contact_State, Primary_Contact_Zip, Secondary_Contact_Name, Secondary_Contact_CellPhone, Secondary_Contact_Phone, Secondary_Contact_Phone_Ext, Secondary_Contact_Email, Secondary_Contact_Fax, Secondary_Contact_Address, Secondary_Contact_City, Secondary_Contact_State, Secondary_Contact_Zip FROM $DBNAME.$TABLE";

  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Affiliate_ID, $Affiliate_Name, $Affiliate_NickName, $Status, $Business_Phone, $Fax_Number, $Address, $City, $State, $Zip, $Website, $Email_Address, $Notes, $Inactivate_Date, $Primary_Contact_Name, $Primary_Contact_CellPhone, $Primary_Contact_Phone, $Primary_Contact_Phone_Ext, $Primary_Contact_Email, $Primary_Contact_Fax, $Primary_Contact_Address, $Primary_Contact_City, $Primary_Contact_State, $Primary_Contact_Zip, $Secondary_Contact_Name, $Secondary_Contact_CellPhone, $Secondary_Contact_Phone, $Secondary_Contact_Phone_Ext, $Secondary_Contact_Email, $Secondary_Contact_Fax, $Secondary_Contact_Address, $Secondary_Contact_City, $Secondary_Contact_State, $Secondary_Contact_Zip) = @row;

#    $Affiliate_IDs{$Affiliate_ID}++;
#    $Affiliate_Names{$Affiliate_ID} = $Affiliate_Name;

     $key = $Affiliate_ID;
     $Affiliate_IDs{$key}++;
     $Affiliate_Names{$key}                        = $Affiliate_Name;
     $Affiliate_NickNames{$key}                    = $Affiliate_NickName;
#    print "key: $key, Affiliate_Names(): $Affiliate_Names{$key}<br>\n";
     $Affiliate_Statuses{$key}                     = $Status;
     $Affiliate_Business_Phones{$key}              = $Business_Phone;
     $Affiliate_Fax_Numbers{$key}                  = $Fax_Number;
     $Affiliate_Addresses{$key}                    = $Address;
     $Affiliate_Citys{$key}                        = $City;
     $Affiliate_States{$key}                       = $State;
     $Affiliate_Zips{$key}                         = $Zip;
     $Affiliate_Websites{$key}                     = $Website;
     $Affiliate_Email_Addresses{$key}              = $Email_Address;
     $Affiliate_Notes{$key}                        = $Notes;
     $Affiliate_Inactivate_Dates{$key}             = $Inactivate_Date;
     $Affiliate_Primary_Contact_Names{$key}        = $Primary_Contact_Name;
     $Affiliate_Primary_Contact_CellPhones{$key}   = $Primary_Contact_CellPhone;
     $Affiliate_Primary_Contact_Phones{$key}       = $Primary_Contact_Phone;
     $Affiliate_Primary_Contact_Phone_Exts{$key}   = $Primary_Contact_Phone_Ext;
     $Affiliate_Primary_Contact_Emails{$key}       = $Primary_Contact_Email;
     $Affiliate_Primary_Contact_Faxs{$key}         = $Primary_Contact_Fax;
     $Affiliate_Primary_Contact_Addresses{$key}    = $Primary_Contact_Address;
     $Affiliate_Primary_Contact_Citys{$key}        = $Primary_Contact_City;
     $Affiliate_Primary_Contact_States{$key}       = $Primary_Contact_State;
     $Affiliate_Primary_Contact_Zips{$key}         = $Primary_Contact_Zip;
     $Affiliate_Secondary_Contact_Names{$key}      = $Secondary_Contact_Name;
     $Affiliate_Secondary_Contact_CellPhones{$key} = $Secondary_Contact_CellPhone;
     $Affiliate_Secondary_Contact_Phones{$key}     = $Secondary_Contact_Phone;
     $Affiliate_Secondary_Contact_Phone_Exts{$key} = $Secondary_Contact_Phone_Ext;
     $Affiliate_Secondary_Contact_Emails{$key}     = $Secondary_Contact_Email;
     $Affiliate_Secondary_Contact_Faxs{$key}       = $Secondary_Contact_Fax;
     $Affiliate_Secondary_Contact_Addresses{$key}  = $Secondary_Contact_Address;
     $Affiliate_Secondary_Contact_Citys{$key}      = $Secondary_Contact_City;
     $Affiliate_Secondary_Contact_States{$key}     = $Secondary_Contact_State;
     $Affiliate_Secondary_Contact_Zips{$key}       = $Secondary_Contact_Zip;

#    print "sub readAffiliates: Affiliate_ID: $Affiliate_ID, Affiliate_Name: $Affiliate_Name<br>\n" if ($incdebug);
  }
  $sthx->finish;
  $dbm->disconnect;

#	  foreach $id ( sort keys %Affiliate_Names) {
#	     $name = $Affiliate_Names{$id};
#	     $key  = "${id} - $name";
#	     push(@OPTSAffiliates, "$key");
#	  }

  my %TMP = ();
  foreach $id ( sort {$Affiliate_Names{$a} cmp $Affiliate_Names{$b} } keys %Affiliate_Names ) {
     my $name = $Affiliate_Names{$id};
     $TMP{$id} = $name;
  }
  foreach my $id ( sort { $TMP{$a} cmp $TMP{$b} } keys %TMP ) {
     my $key  = "${id} - $TMP{$id}";
     push(@OPTSAffiliates, "$key");
  }

  print "sub readAffiliates: Exit.<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ( $incdebug );
}

#______________________________________________________________________________

sub readSwitchData {

  my ($ThisNCPDP) = @_;

# my $debug++;
# my $incdebug++;

  print "<hr>sub readSwitchData: Entry. ThisNCPDP: $ThisNCPDP<br>\n" if ( $incdebug );

  my $dbin    = "RIDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $FIELDS  = $DBFLDS{"$dbin"};
  my $FIELDS2 = $DBFLDS{"$dbin"} . "2";
  my $prefix  = "RI";	# unique to this table
#______________________________________________________________________________
  @mySwitchhashes = ();
  my @fieldnames = ();
  my @pcs = split(", ", $$FIELDS);
  foreach $pc (@pcs) {
    $key = "${prefix}##$pc";
    $pchead = $HEADINGS{"$key"};
#   print "pc: '$pc', pchead: $pchead\n" if ($incdebug);
    push(@fieldnames, "$pchead");
  }
  foreach $fieldname (@fieldnames) {
     if ( $fieldname =~ /s$/ ) {
        $HASH = "${fieldname}es";	# end in an 'es'
     } else {
        $HASH = "${fieldname}s";	# end in an 's'
     }
     push(@mySwitchhashes, $HASH);
     undef %$HASH;
#    print "TTT: undef $HASH\n" if ($incdebug);
  }
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "";
# $sql  = "SELECT $$FIELDS FROM $DBNAME.$TABLE ";
  $sql  = "SELECT $$FIELDS FROM ${DBNAME}.${TABLE} ";
  if ( $ThisNCPDP ) {
     $sql .= " WHERE dbNCPDPNumber='$ThisNCPDP' ";
  }

  print "sql:<br>$sql<br>\n" if ($incdebug);

  $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  if ( $NumOfRows > -1 ) {
     while ( my @row = $sthx->fetchrow_array() ) {

       my $ptr = 0;
       my $pc  = "";
       foreach $pc (@row) {
          my $jfieldname = $fieldnames[$ptr];
          $$jfieldname   = $pc;		# So now "$dbSwVendor" is real variable with real value to match for this row
          $ptr++;
       }

       $key = "$dbSwVendor##$dbDateTransmitted##$dbNCPDPNumber##$dbDateOfService##$dbRxNumberExtended##$dbRxNumber##$dbTransactionCode##$dbDateOfBirth##$dbTotalAmountPaid##$dbBinNumber";

#      print "key: $key<br>\n" if ($incdebug);

       $ptr = 0;
       $pc  = "";
       foreach $pc (@row) {
          my $jfieldname = $fieldnames[$ptr];
          $$jfieldname   = $pc;		# So now "$dbSwVendor" is real variable with real value to match for this row
          if ( $jfieldname =~ /s$/ ) {
             $HASH = "${jfieldname}es";	# end in an 'es'
          } else {
             $HASH = "${jfieldname}s";	# end in an 's'
          }

#         print "HASH: $HASH\n";
          my $val = $$jfieldname;
#         print "HASH: $HASH, val: $val\n";
          $$HASH{$key} = $val;
          $ptr++;
       }

     }
  } else {
     print qq#No Data found!<br><br>\n#;
#    print qq#sql:<br><br>$sql<br><br>\n# if ( $incdebug );
     print qq#<td>UNKNOWN</td>\n#;
  }
  $sthx->finish;
  $dbm->disconnect;

  print "sub readSwitchData: Exit.<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ( $incdebug );
}

#______________________________________________________________________________

sub readLogins {
  my $DBNAME  = 'Officedb';
  my $TABLE   = 'weblogin';

  my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = "SELECT id, login, type, fname, lname, access, date_added
            FROM $DBNAME.$TABLE
           WHERE permission_level = 'Admin'";

  $sth99 = $dbm99->prepare($sql);
  $sth99->execute();

  my $NumOfRows = $sth99->rows;

  @OPTSCSRLOGINIDS = ();
  while ( my @row = $sth99->fetchrow_array() ) {
     my ($id, $login, $type, $fname, $lname, $access, $date_added) = @row;

     $key = $id;
     $LCustomerIDs{$key} = $WLSuperUser;
     $LLoginIDs{$key}    = $login;
     $LTypes{$key}       = $type;
     $LDateAddeds{$key}  = $date_added;
     $LFirstNames{$key}  = $fname;
     $LLastNames{$key}   = $lname;
     $LNames{$key}       = "$lname, $fname";
     push(@OPTSCSRLOGINIDS, "$key");
  }

  $sth99->finish;

  $dbm99->disconnect;
}

#______________________________________________________________________________
#

sub readCSRCTL_notusingyet {
  my $db_office  = 'officedb';
  my $tbl_ctl = 'ctr_ctl';
  my $sql;

  my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = "SELECT weblogin_id, user, email, title 
            FROM $db_office.$tbl_ctl 
           WHERE active'
           ORDER BY weblogin_id
         ";

  $sthx = $dbm99->prepare($sql) || die "Error preparing query" . $dbm99->errstr;
  $sthx->execute() or die $DBI::errstr;

  my $NumOfRows = $sthx->rows;

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($ctl_id, $ctl_user, $ctl_email, $ctl_title) = @row;

     $CSR_User{"$ctl_id"}   = $ctl_user;
     $CSR_Email{"$ctl_id"}  = $ctl_email;
     $CSR_Title{"$ctl_id"}  = $ctl_title;

  }
  $sthx->finish;
  $dbm99->disconnect;
}


sub readCSRs {
  if ( scalar keys %CSR_Reverse_ID_Lookup == 0 ) {
    my $db_office  = 'officedb';
    my $TABLE      = 'weblogin';
    my $tbl_access = 'webloginaccess';
    my $sql;
#______________________________________________________________________________

    my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
  	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

    DBI->trace(1) if ($dbitrace);

    $sql = "SELECT id, id, type, fname, lname, permission_level, login, display_in_menus, ReconRx_Ram 
              FROM $db_office.$TABLE a
	      JOIN $db_office.$tbl_access b ON a.id = b.WLSuperUser
             WHERE programs LIKE '%RBSD%'
          ORDER BY lname, fname";

    $sthx = $dbm99->prepare($sql) || die "Error preparing query" . $dbm99->errstr;
    $sthx->execute() or die $DBI::errstr;

    my $NumOfRows = $sthx->rows;

    while ( my @row = $sthx->fetchrow_array() ) {
       my ($WLSuperUser, $WLCustomerID, $WLType, $WLFirstName, $WLLastName, $WLPermissionLevel, $WLLoginID, $WLDisplayInMenus, $ReconRAM) = @row;

       if ( $WLCustomerID > 0 && $WLPermissionLevel =~ /^NONE|^View/i ) {
         print "Skipping $WLFirstName $WLLastName - $WLPermissionLevel<br>\n" if ($verbose);
       } else {

         $name = "$WLLastName, $WLFirstName";
         $key = "$name";
         if ( exists($CSR_IDs{"$key"}) ) {
		 ##print "<font color=red size=+1>FIX 2nd occurrance of '$name'</font><br>\n";
         }

         $CSR_IDs{"$key"}            = $WLSuperUser;
         $CSR_SuperUsers{"$key"}     = $WLSuperUser;
         $CSR_Types{"$key"}          = $WLType;
         $CSR_Names{"$key"}          = $name;
         $CSR_Emails{"$key"}         = $WLLoginID;
         $CSR_DisplayInMenus{"$key"} = $WLDisplayInMenus;
         $CSR_Recon_Ram{"$key"}      = $ReconRAM;

         $CSR_Reverse_Lookup{"$WLLoginID"} = $key;
         $CSR_Reverse_ID_Lookup{"$WLSuperUser"} = $key;

         push(@OPTSCSR, "$key");
       }
    }
    $sthx->finish;

    # Close the Database
    $dbm99->disconnect;

    $CSR_ID       = "";
    $CSR_Name     = "";
    $Row_CSR_ID   = "";
    $Row_CSR_Name = "";

    foreach $key (sort keys %CSR_Emails) {
      next if ( $CSR_Emails{"$key"} !~ /$USER/i );
  
      $CSR_ID       = $CSR_SuperUsers{"$key"};
      $CSR_Name     = $CSR_Names{"$key"};
      $Row_CSR_ID   = $CSR_ID;
      $Row_CSR_Name = $CSR_Name;
    }

    $UpDB_Row_CSR_Name = $Row_CSR_Name;
    $UpDB_Row_Comments = $in{"UpDB_Row_Comments"};
    $CUSTOMERID        = $CSR_ID;
  }
}

sub read_emails {
  my $DBNAME  = 'officedb';
  my $TABLE   = 'email_users';
  my $sql;
#______________________________________________________________________________

  my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  $sql = "SELECT user, account, email, CAST(AES_DECRYPT(password,'PAI20181217!') AS CHAR), title, ext, rc_phone, user_id
            FROM $DBNAME.$TABLE
        ORDER BY user";

  $sthx = $dbm99->prepare($sql) || die "Error preparing query" . $dbm99->errstr;
  $sthx->execute() or die $DBI::errstr;

  my $NumOfRows = $sthx->rows;

  while ( my @row = $sthx->fetchrow_array() ) {
     my ($user, $account, $email, $pwd, $title, $ext, $rc_phone, $uid) = @row;

     $EMAILUSER{$user}       = $account;
     $EMAILACCT{$user}       = $email;
     $EMAILACCTPWD{$user}    = $pwd;
     $EMAIL_SIG_TITLE{$user} = $title;
     $EMAIL_SIG_EXT{$user}   = $ext;
     $EMAIL_SIG_RC_PHONE{$user} = $rc_phone;
  }
  $sthx->finish;

  # Close the Database
  $dbm99->disconnect;
}

#______________________________________________________________________________

sub makeEpoch {

  my ($datein) = @_;
  my ($epoch)  = 0;

  print "sub makeEpoch: Entry. datein: $datein<br>\n" if ($incdebug);

  if ( $datein && $datein !~ /^\s*00:00$|^\s*23:59$/ ) {
    my ( $jdate, $jtime) = split(" ", $datein, 2);
    my ($jyear, $jmon, $jmday) = split("-", $jdate, 3);
    my ($jhour, $jmin) = split(":", $jtime, 2);
    my $jsec .= 0;

    if ( $incdebug ) {
      print "datein: $datein<br>\n";
      print "jdate: $jdate, jtime: $jtime<br>\n";
      print "jyear: $jyear, jmon: $jmon, jmday: $jmday<br>\n";
      print "jhour: $jhour, jmin: $jmin<br>\n";
    }

    $jmon  = $jmon  - 1;
    $jyear = $jyear - 1900;
    $epoch = timelocal($jsec,$jmin,$jhour,$jmday,$jmon,$jyear);

  } else {
    $epoch = 0;
  }

  print "sub makeEpoch: Exit. epoch: $epoch<br>\n" if ($incdebug);
  return($epoch);

}

#______________________________________________________________________________

# call with    ($TS) = &build_date_TS($DATE);

sub build_date_TS {

  my ($DATE) = @_;
  my ($TS) = "";

  print "sub build_date_TS: Entry. DATE: $DATE<br>\n" if ($incdebug);

  my ($p1, $p2) = split(" ", $DATE, 2);
  print "p1: $p1, p2: $p2<br>\n" if ($incdebug);
  my ($year, $month, $day) = split("-", $p1, 3);
  my ($hour, $min, $sec) = split(":", $p2, 3);
  print "year: $year, month: $month, day: $day, hour: $hour, min: $min, sec: $sec<br>\n" if ($incdebug);
  $month--;
  $TS = timelocal($sec,$min,$hour,$day,$month,$year);

  print "sub build_date_TS: Exit. TS: $TS<br>\n" if ($incdebug);

  return ($TS);

}

#______________________________________________________________________________

sub build_date {

  my ($DATE) = "";

  print "sub build_date: Entry.<br>\n" if ($debug);

  my ($sec, $min, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
  $year  += 1900;	# reported as "years since 1900".
  $month += 1;	# reported ast 0-11, 0==January
  $DATE   = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);

  if ( $debug ) {
     printf("Date Fields: %04d-%02d-%02d %02d:%02d:%02d<br>\n", $year, $month, $day, $hour, $min, $sec);
     print "DATE: $DATE<br>\n";
  }
  print "sub build_date: Exit. DATE: $DATE<br>\n" if ($debug);

  return ($DATE);

}

sub readsetCookies {

# jlh. 02/23/2012
  my ($flag) = @_;

#	  my @rsCmonthnames = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
#	  my @rsCweekdays = qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
#	  my $rsCnextday = time+ (8 * 60 * 60);
#	  my ($rsCsec,$rsCmin,$rsChour,$rsCmday,$rsCmon,$rsCyear,$rsCdayname,$rsCdayofyear) = gmtime($rsCnextday);
#	  $rsCyear += 1900;
#	  $rsCexpires = sprintf ("%s, %02d-%s-%d %02d:%02d:%02d GMT",
#	  	$rsCweekdays[$rsCdayname],$rsCmday, $monthnames[$rsCmon],$rsCyear,$rsChour,$rsCmin,$rsCsec);

  $rcvd_cookies = $ENV{'HTTP_COOKIE'};
  @cookies = split /;/, $rcvd_cookies;
  foreach $cookie ( @cookies ){
     ($key, $val) = split(/=/, $cookie); # splits on the first =.
     $key =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white space
     $val =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white space
     print "cookie key: $key, cookie val: $val<br>\n" if ($debug);
     if ( $key eq "USER" ) {
        $Cookie_USER = $val;
     } elsif($key eq "LOGIN") {
        $Cookie_LOGIN = $val;
     } elsif ( $key eq "PERMISSIONLEVEL" ) {
        $Cookie_PERMISSIONLEVEL = $val;
     } elsif($key eq "WHICHDB") {
        $Cookie_WHICHDB = $val;
     } elsif($key eq "PH_ID") {
        $Cookie_PH_ID = $val;
     } elsif($key eq "PH_COUNT") {
        $Cookie_PH_COUNT = $val;
     } elsif($key eq "TYPE") {
        $Cookie_TYPE = $val;
     } elsif($key eq "PROGRAM") {
        $Cookie_PROGRAM = $val;
     } elsif($key eq "RBSHeader") {
        $Cookie_RBSHeader = $val;
     } elsif($key eq "AreteUser") {
        $Cookie_AreteUser = $val;
     }elsif($key eq "Aggregated") {
        $Cookie_Aggregated = $val;
     }elsif($key eq "Agg_String") {
        $Cookie_AggString = $val;
     } elsif($key eq "AreteMember") {
        $Cookie_AreteMember = $val;
     }
  }

# jlh. 01/28/2015. Commented out StripJunk on Passwords as we are using passwords with exclamations in them now...

  ($Cookie_USER)             = &StripJunk($Cookie_USER);
  ($Cookie_LOGIN)            = &StripJunk($Cookie_LOGIN);
  ($Cookie_PERMISSIONLEVEL)  = &StripJunk($Cookie_PERMISSIONLEVEL);
  ($Cookie_WHICHDB)          = &StripJunk($Cookie_WHICHDB);
  ($Cookie_PH_ID)            = &StripJunk($Cookie_PH_ID);
  ($Cookie_PH_COUNT)         = &StripJunk($Cookie_PH_COUNT);
  ($Cookie_TYPE)             = &StripJunk($Cookie_TYPE);

  $USER       = $Cookie_USER       if ( $Cookie_USER       and !$USER );
  $LOGIN      = $Cookie_LOGIN      if ( $Cookie_LOGIN      and !$LOGIN );
  $PERMISSIONLEVEL = $Cookie_PERMISSIONLEVEL if ($Cookie_PERMISSIONLEVEL and !$PERMISSIONLEVEL );
  $WHICHDB     = $Cookie_WHICHDB   if ( $Cookie_WHICHDB    and !$WHICHDB );
  $PH_ID       = $Cookie_PH_ID     if ( $Cookie_PH_ID      and !$PH_ID );
  $PH_COUNT    = $Cookie_PH_COUNT  if ( $Cookie_PH_COUNT   and !$PH_COUNT );
  $TYPE        = $Cookie_TYPE      if ( $Cookie_TYPE       and !$TYPE );
  $PROGRAM     = $Cookie_PROGRAM   if ( $Cookie_PROGRAM    and !$PROGRAM );
  $RBSHeader   = $Cookie_RBSHeader if ( $Cookie_RBSHeader  and !$RBSHeader );
  $AreteUser   = $Cookie_AreteUser if ( $Cookie_AreteUser  and !$AreteUser );
  $Aggregated  = $Cookie_Aggregated  if ( $Cookie_Aggregated   and !$Aggregated );
  $Agg_String   = $Cookie_AggString   if ( $Cookie_AggString    and !$Agg_String );
  $AreteMember = $Cookie_AreteMember if ( $Cookie_AreteMember  and !$AreteMember );
  
  #______________________________________________________________________________

# jlh. 01/28/2015. Commented out StripJunk on Passwords as we are using passwords with exclamations in them now...

  ($USER)       = &StripJunk($USER);
  ($LOGIN)       = &StripJunk($LOGIN);
  ($PERMISSIONLEVEL) = &StripJunk($PERMISSIONLEVEL);
  ($WHICHDB)     = &StripJunk($WHICHDB);
  ($PH_ID)       = &StripJunk($PH_ID);
  ($PH_COUNT)    = &StripJunk($PH_COUNT);
  ($TYPE)        = &StripJunk($TYPE);

  print qq#Set-Cookie:USER=$USER;               path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:LOGIN=$LOGIN;             path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:LPERMISSIONLEVEL=$PERMISSIONLEVEL; path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:LTYPE=$LTYPE;             path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:WHICHDB=$WHICHDB;         path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:PH_ID=$PH_ID;             path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:PH_COUNT=$PH_COUNT;       path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:TYPE=$TYPE;               path=/; domain=$cookie_server;\n#;
  print qq#Set-Cookie:PROGRAM=$PROGRAM;         path=/; domain=$cookie_server;\n#;
}

#______________________________________________________________________________

sub display_Nag_Page {

  my ($Header, $H1, @message) = @_;

  my $whocalledme = $ENV{'SERVER_NAME'};
  print "<hr>whocalledme: $whocalledme<hr>\n" if ($debug);

  if ( $whocalledme =~ /Pharmassess/i ) {
     $Program      = $ContactProgram{"RBS"};
     $emailaddress = $ContactEmail{"RBS"};
	 $phone        = $ContactPhone{"RBS"};
     $TollFree     = $ContactTollFree{"RBS"};
	 $fax          = $ContactFaxCred{"RBS"};
  } elsif ( $whocalledme =~ /Recon-Rx/i ) {
     $Program      = $ContactProgram{"ReconRx"};
     $emailaddress = $ContactEmail{"ReconRx"};
	 $phone        = $ContactPhone{"ReconRx"};
     $TollFree     = $ContactTollFree{"ReconRx"};
     $fax          = $ContactFaxReg{"ReconRx"};
  } elsif ( $whocalledme =~ /CIPNetwork/i ) {
     $Program      = $ContactProgram{"CIPN"};
     $emailaddress = $ContactEmail{"CIPN"};
	 $phone        = $ContactPhone{"CIPN"};
     $TollFree     = $ContactTollFree{"CIPN"};
	 $fax          = $ContactFaxCred{"CIPN"};
  } elsif ( $whocalledme =~ /QCPN/i ) {
     $Program      = $ContactProgram{"QCPN"};
     $emailaddress = $ContactEmail{"QCPN"};
	 $phone        = $ContactPhone{"QCPN"};
     $TollFree     = $ContactTollFree{"QCPN"};
	 $fax          = $ContactFaxCred{"QCPN"};
  } else {
     $Program      = $ContactProgram{"PAI"};
     $emailaddress = $ContactEmail{"PAI"};
	 $phone        = $ContactPhone{"PAI"};
     $TollFree     = $ContactTollFree{"PAI"};
     $fax          = $ContactFaxCred{"PAI"};
	 }
#####
  print qq#<link rel="stylesheet" href="/css/reveal.css">\n#;
  print qq#<script type="text/javascript" src="https://code.jquery.com/jquery-1.6.min.js"></script>\n#;
  print qq#<script type="text/javascript" src="/includes/jquery.reveal.js"></script>\n#;
  print qq#<script type="text/javascript">\n#;
  print qq#\$(document).ready(function() {\n#;
  print qq#	\$('\#myModal').reveal()\;\n#;
  print qq#})\;\n#;
  print qq#</script>\n\n#;

  print qq#<div id="myModal" class="reveal-modal">\n#;

#####

  print "<h1>$Pharmacy_Name<br>$Header</h1>\n";
  my @pcs = split("##", $Licenses_Broken);
  foreach $pc (sort @pcs) {
     $pc =~ s/_/ /g;
     print "<h2><font color=red>$pc</font></h2>\n";
  }
  print "<hr>\n";

  print "<table width=100%>\n";
  print "<tr><th colspan=2>$nbsp</th></tr>\n";

# print "<tr><th colspan=2 align=left>$Program: $H1</th></tr>\n";
  print "<tr><th colspan=2 align=left>$$H1</th></tr>\n";
  foreach $pc (@message) {
    print "<tr><th colspan=2 align=left>$pc</th></tr>\n";
  }

  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>\n";
     print "<table>";
     print "<tr><td align=left>Email:</td>    <td>$emailaddress</td></tr>\n";
     print "<tr><td align=left>Phone:</td>    <td>$phone</td></tr>\n" if ($whocalledme !~ /CIPN/i );
     print "<tr><td align=left>Fax:</td>      <td>$fax</td></tr>\n";
     print "<tr><td align=left>Toll Free:</td><td>$TollFree</td></tr>\n";
     print "</table>\n";
  print "</td></tr>\n";

  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>Regular Business Hours</td></tr>\n";
  print "<tr><td colspan=2>Mon-Fri	8:30am - 5:30pm CT</td></tr>\n";
  print "<tr><td colspan=2>Sat-Sun	Closed</td></tr>\n";
  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>Closed on the following holidays:</td></tr>\n";

  my $DAYS = "";
  foreach $DAY (@PAINOTINOFFICE) {
    $DAYS .= "$DAY, ";
  }
  $DAYS =~ s/,\s*$//g;
  print "<tr><td colspan=2>$DAYS</td></tr>\n";
  print "</table>\n";

  print "<br><hr>\n";

# jlh. 11/06/2013. Flip/Flop again and again for CIPN...
# if ( $whocalledme !~ /CIPNetwork/i ) {
     print qq#	<a class="close-reveal-modal">&\#215\;</a>\n#;
     print qq#</div>\n#;
# }

}

#______________________________________________________________________________

sub display_Expired_Page {

unless ( $Pharmacy_Types{$inNCPDP} =~ /Special Programs/i )
  {

  my ($Licenses_Broken) = @_;

  my $whocalledme = $ENV{'SERVER_NAME'};
  print "<hr>whocalledme: $whocalledme<hr>\n" if ($debug);

  if ( $whocalledme =~ /Pharmassess/i ) {
     $Program      = $ContactProgram{"RBS"};
     $emailaddress = $ContactEmail{"RBS"};
	 $phone        = $ContactPhone{"RBS"};
     $TollFree     = $ContactTollFree{"RBS"};
	 $fax          = $ContactFaxCred{"RBS"};
  } elsif ( $whocalledme =~ /Recon-Rx/i ) {
     $Program      = $ContactProgram{"ReconRx"};
     $emailaddress = $ContactEmail{"ReconRx"};
	 $phone        = $ContactPhone{"ReconRx"};
     $TollFree     = $ContactTollFree{"ReconRx"};
     $fax          = $ContactFaxReg{"ReconRx"};
  } elsif ( $whocalledme =~ /CIPNetwork/i ) {
     $Program      = $ContactProgram{"CIPN"};
     $emailaddress = $ContactEmail{"CIPN"};
	 $phone        = $ContactPhone{"CIPN"};
     $TollFree     = $ContactTollFree{"CIPN"};
	 $fax          = $ContactFaxCred{"CIPN"};
  } elsif ( $whocalledme =~ /QCPN/i ) {
     $Program      = $ContactProgram{"QCPN"};
     $emailaddress = $ContactEmail{"QCPN"};
	 $phone        = $ContactPhone{"QCPN"};
     $TollFree     = $ContactTollFree{"QCPN"};
	 $fax          = $ContactFaxCred{"QCPN"};
  } else {
     $Program      = $ContactProgram{"PAI"};
     $emailaddress = $ContactEmail{"PAI"};
	 $phone        = $ContactPhone{"PAI"};
     $TollFree     = $ContactTollFree{"PAI"};
     $fax          = $ContactFaxCred{"PAI"};
	 }

#####
  print qq#<link rel="stylesheet" href="/css/reveal.css">\n#;
  print qq#<script type="text/javascript" src="https://code.jquery.com/jquery-1.6.min.js"></script>\n#;
  print qq#<script type="text/javascript" src="/includes/jquery.reveal.js"></script>\n#;
  print qq#<script type="text/javascript">\n#;
  print qq#\$(document).ready(function() {\n#;
  print qq#	\$('\#myModal').reveal()\;\n#;
  print qq#})\;\n#;
  print qq#</script>\n\n#;

# jlh. 11/06/2013. Flip/Flop again and again for CIPN...
#  if ( $whocalledme !~ /CIPNetwork/i ) {
     print qq#<div id="myModal" class="reveal-modal">\n#;
# }

#####

  print "<h1>$Pharmacy_Name<br>Information records found out of date</h1>\n";
  my @pcs = split("##", $Licenses_Broken);
  foreach $pc (sort @pcs) {
     $pc =~ s/_/ /g;
     print "<h2><font color=red>$pc</font></h2>\n";
  }
  print "<hr>\n";

  print "<table width=100%>\n";
  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><th colspan=2 align=left>Please contact $Program with your updated information as soon as possible.</th></tr>\n";
  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>\n";
     print "<table>";
     print "<tr><td align=left>Email:</td>    <td>$emailaddress</td></tr>\n";
     print "<tr><td align=left>Phone:</td>    <td>$phone</td></tr>\n" if ($whocalledme !~ /CIPN/i );
     print "<tr><td align=left>Fax:</td>      <td>$fax</td></tr>\n";
     print "<tr><td align=left>Toll Free:</td><td>$TollFree</td></tr>\n";
     print "</table>\n";
  print "</td></tr>\n";

  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>Regular Business Hours</td></tr>\n";
  print "<tr><td colspan=2>Mon-Fri	8:30am - 5:30pm CT</td></tr>\n";
  print "<tr><td colspan=2>Sat-Sun	Closed</td></tr>\n";
  print "<tr><th colspan=2>$nbsp</th></tr>\n";
  print "<tr><td colspan=2>Closed on the following holidays:</td></tr>\n";

  my $DAYS = "";
  foreach $DAY (@PAINOTINOFFICE) {
    $DAYS .= "$DAY, ";
  }
  $DAYS =~ s/,\s*$//g;
  print "<tr><td colspan=2>$DAYS</td></tr>\n";
  print "</table>\n";

  print "<br><hr>\n";

# jlh. 11/06/2013. Flip/Flop again and again for CIPN...
# if ( $whocalledme !~ /CIPNetwork/i ) {
     print qq#	<a class="close-reveal-modal">&\#215\;</a>\n#;
     print qq#</div>\n#;
# }

  } #end unless

}

#______________________________________________________________________________

sub readdirs {

  my ($dskpath) = @_;
  my @dirs = ();

  print "sub readdirs: Entry.<br>dskpath: $dskpath<br>\n" if ($debug);

  # Default to current directory. Look for dirs
  opendir DIR, "$dskpath" || die "Couldn't open directory '$dskpath'\n$!\n\n";
  my @dirs = grep {
     !/^\./            # Begins with a period
     && -d "$dskpath/$_"   # and is a directory
  } readdir(DIR);
  closedir DIR;

# @dirs = sort { $a <=> $b } (@dirs);

  $dircnt = $#dirs + 1;
  print "sub readdirs: Exit. dircnt: $dircnt<br>\n" if ($debug);
  return (@dirs);
}

#______________________________________________________________________________

sub readfiles {

  my ($dskpath) = @_;
  my @files = ();
# my $debug++;
# my $incdebug++;

  print "<br>sub readfiles: Entry. dskpath:<br>$dskpath<br>\n" if ($incdebug);

  # Default to current directory. Look for files
  opendir DIR, "$dskpath" || die "Couldn't open directory '$dskpath'\n$!\n\n";
  my @files = grep {
     !/^\./					# Doesn't begin with a period
     && -f "$dskpath/$_"	# and is a file
     && !/Thumbs.db/i		# and isn't "Thumbs.db"
  } readdir(DIR);
  closedir DIR;

  @files = sort { -M "$dskpath/$a" <=> -M "$dskpath/$b"} (@files);

  $filescnt = $#files + 1;
  print "sub readfiles: Exit. filecnt: $filescnt<br><br>\n" if ($incdebug);

  return (@files);
}

sub find_pdf_file {

  my ($dskpath) = @_;
  my @files = ();

  # Default to current directory. Look for files
  opendir DIR, "$dskpath" || die "Couldn't open directory '$dskpath'\n$!\n\n";
  my @files = grep {
     !/^\./					# Doesn't begin with a period
     && -f "$dskpath/$_"	# and is a file
     && !/Thumbs.db/i		# and isn't "Thumbs.db"
     && /pdf$/i			# and ends in "pdf"
  } readdir(DIR);
  closedir DIR;

  @files = sort { -M "$dskpath/$a" <=> -M "$dskpath/$b"} (@files);

#  print "Path: $dskpath Files: @files<br>";

  $filescnt = $#files + 1;
  return (@files);
}

#______________________________________________________________________________

# Call with: my ($keyPri, $MyPrimary) = &setMyPrimary2($TPP_ID, $BIN, $PCN, $GroupID);

sub setMyPrimary2 {

   my ($TPPID, $BIN, $PCN, $GroupID) = @_;
   my ($MyPrimary) = "";
   my $key;

#  my $debug++;
#  my $incdebug++;

   if ( !$readTPPPriSec_DONE ) {
     print "Call readTPPPriSec!!!!!<br>\n" if ($debug);
     &readTPPPriSec;
   }

   $BIN     =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
   $PCN     =~ s/^\s*(.*?)\s*$/$1/;
   $GroupID =~ s/^\s*(.*?)\s*$/$1/;

   $BIN     = substr("000000" . $BIN, -6);
   my $lzBIN = $BIN;

   if ($incdebug) {
      print "<hr>sub setMyPrimary2: Entry. TPPID: $TPPID, BIN: $BIN, PCN: $PCN, GroupID: $GroupID<br>\n";
   }

   $PCN     = "ANY" if ( $PCN     =~ /^\s*$|ANY/i );
   $GroupID = "ANY" if ( $GroupID =~ /^\s*$|ANY/i );

   &readReconExceptionRouting2 if ( !$readReconExceptionRouting2 );

   $key = "$BIN##$PCN##$GroupID";

   my $MATCH  = 0;
   my $exckey = "";

   if ( $debug || $incdebug ) {
      print "-"x72, "<br><br>\n\n";
      print "BIN: $BIN, EBINS(): $EBINS{$BIN}<br>\n";
   }

   if ( $EBINS{$BIN} ) {
      # Okay, the BIN read in is in the Exceptions table. So compare against lines in table.
      foreach $EKEY ( sort keys %ExceptionBins ) {

         my ($checkbin, $checkPCN, $checkGroupID) = split("##", $EKEY, 3);

         if ( $debug || $incdebug ) {
            print "-"x72, "<br>\n";
            print "BZ - Check EKEY: $EKEY, checkbin: $checkbin, checkPCN: $checkPCN, checkGroupID: $checkGroupID<br>\n";
         }
         if ( $BIN == $checkbin ) {
            if ( $debug || $incdebug ) {
               print "BZ - BIN: $BIN, checkbin: $checkbin<br>\n";
               print "\tBZ1. TRUE. PCN: $PCN, checkPCN: $checkPCN<br>\n" if ($PCN =~ /$checkPCN/i);
               print "\tBZ2. TRUE. PCN: $PCN, checkPCN: $checkPCN<br>\n" if ($PCN eq $checkPCN);
               print "\tBZ3. TRUE. PCN: $PCN, checkPCN: $checkPCN<br>\n" if ($checkPCN =~ /^ANY$/i );
            }
            if ( $PCN =~ /$checkPCN/i || $PCN eq $checkPCN || $checkPCN =~ /^ANY$/i ) {
               print "BZ - PCN: $PCN, checkPCN: $checkPCN<br>\n" if ($debug || $incdebug);
               if ( 
                   ( $GroupID =~ /$checkGroupID/i || $GroupID eq $checkGroupID || $checkGroupID =~ /^ANY$/i) 
                  ) {
                  if ($debug || $incdebug) {
                     print "BZ - GroupID: $GroupID, checkGroupID: $checkGroupID<br>\n";
                     print "MATCH FOUND! $BIN/$checkbin | $PCN/$checkPCN | $GroupID/$checkGroupID<br>\n";
                  }
                  $MATCH++;
                  $exckey = "$BIN##$checkPCN##$checkGroupID";
                  $key = $exckey;
               }
            }
         }
         last if ( $MATCH );
      }
   }
   if ( $BIN == 600471 && $PCN =~ /^7777$|^VOUCHER$/i && $GroupID =~ /^X/i ) {
      $savekeyPri = 700498;
      $MyPrimary  = "017290 - $TPP_Names{700498}";
      print "1. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

   } elsif ( $MATCH && $ExceptionBins{$key} ) {

      $savekeyPri = $TPPID;
      $MyPrimary  = qq#$ExceptionBins{$key} - #;
      $MyPrimary .= $TPP_Names{ $ExceptiondbKeys{$key} };
#     $MyPrimary .= qq# ($ExceptionComments{$key})#;
      $savekeyPri = $ExceptiondbKeys{$key};

#     print "YOHO! MyPrimary: $MyPrimary, savekeyPri: $savekeyPri<br>\n\n" if ($incdebug);
      print "2. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

   } elsif ( $TPPID <= 0 || !$TPPID ) {
##      $saveTPPIDPri{$TPPID}  = -1;
##      $saveMyPrimary{$TPPID} = -1;
      $MyPrimary = "";
      print "3. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

   } elsif ( $TPP_PriSecs{$TPPID} =~ /^Pri/i ) {

#     print "1. here. TPPID: $TPPID, TPP_BINs(): $TPP_BINs{$TPPID}<br>\n" if ($debug);

      $savekeyPri = $TPPID;
      $MyPrimary = "$TPP_BINs{$TPPID} - $TPP_Names{$TPPID}";
      print "4. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

   } else {

      print "5a. TPPID: $TPPID, saveTPPIDPri(): $saveTPPIDPri{$TPPID}<br>\n" if ($incdebug);
      if ( $saveTPPIDPri{$TPPID} ) {
         $savekeyPri = $saveTPPIDPri{$TPPID};
         $MyPrimary  = $saveMyPrimary{$TPPID};
         print "5b. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

      } else {

         foreach $key (sort keys %TPPPS_Pri_Sec_IDs) {
           $keyPri = $TPPPS_Pri_IDs{$key};
           $keySec = $TPPPS_Sec_IDs{$key};
           next if ( $keyPri < 0 );
           $TPPPS_Sec_ID = $TPP_BINs{$keySec};
           $TPPPS_Pri_ID = $TPP_BINs{$keyPri};

           next if ( $keyPri < 0 || $keySec < 0 );
           next if ( $keySec !~ /^$TPPID$/ && $keyPri !~ /^$TPPID$/ );
           if ( $incdebug ) {
              print "key: $key, TPPID: $TPPID, keyPri: $keyPri, keySec: $keySec<br>\n";
              print "TPPPS_Pri_ID: $TPPPS_Pri_ID<br>\n";
              print "TPPPS_Sec_ID: $TPPPS_Sec_ID<br>\n";
           }
           next if ( !$TPPPS_Sec_ID );

           if ( $TPPPS_Pri_ID =~ /^$BIN$|^$lzBIN$/i ) {
              $MyPrimary = "$TPPPS_Pri_ID - $TPP_Names{$keyPri}";
           } elsif ( $TPPPS_Sec_ID =~ /^$BIN$|^$lzBIN$/i ) {
              $MyPrimary = "$TPPPS_Pri_ID - $TPP_Names{$keyPri}";
           }
           $savekeyPri = $keyPri;
         }
      }
   }
   $MyPrimary = "Unknown" if ( $MyPrimary =~ /^\s*$/ );
   print "6. here. MyPrimary: $MyPrimary<br>\n" if ($incdebug);

   ## $saveTPPIDPri{$TPPID}  = $savekeyPri;
   ##$saveMyPrimary{$TPPID} = $MyPrimary;

   print "sub setMyPrimary2: Exit. keyPri: $keyPri, savekeyPri: $savekeyPri, MyPrimary: $MyPrimary<br><hr>\n" if ($incdebug);

   return ($savekeyPri, $MyPrimary);

}

#______________________________________________________________________________

# Call with: my ($keyPri, $MyPrimary) = &setMyPrimary($TPP_ID, $BinNumber);

sub setMyPrimary {

   my ($TPPID, $BIN) = @_;
   my $savekeyPri = "";
   my $MyPrimary  = "";
   my $key;

#  my $debug++;
#  my $incdebug++;

   &readReconExceptionRouting if ( !$readReconExceptionRouting );

   if ( !$readTPPPriSec_DONE ) {
     print "Call readTPPPriSec!!!!!<br>\n" if ($debug);
     &readTPPPriSec;
   }

   my $lzBIN = substr("000000" . $BIN, -6);
   if ( $debug ) {
      print "="x96, "\n";
      print "sub setMyPrimary: Entry. TPPID: $TPPID, BIN: $BIN, lzBIN: $lzBIN<br>\n";
      print "BIN: $BIN, ExceptionBins(): $ExceptionBins{$BIN}<br>\n";
      print "BIN: $BIN, TPPID: $TPPID, TPP_PriSecs(): $TPP_PriSecs{$TPPID}<br>\n";
   }


   if ( $ExceptionBins{$BIN} ) {
#     print "1. here<br>\n";
#     print "BIN: $BIN, ExceptionBins($BIN): $ExceptionBins{$BIN}<br>\n" if ($BIN=600471 );

      $savekeyPri = $TPPID;
      $MyPrimary  = qq#$ExceptionBins{$BIN} - #;
      $MyPrimary .= $TPP_Names{ $ExceptiondbKeys{$BIN} };
#     $MyPrimary .= qq# ($ExceptionComments{$BIN})#;
      $savekeyPri = $ExceptiondbKeys{$BIN};

   } elsif ( $TPPID <= 0 || !$TPPID ) {
#     print "2. here<br>\n";
##      $saveTPPIDPri{$TPPID}  = -1;
##      $saveMyPrimary{$TPPID} = -1;
      $MyPrimary = "";

   } elsif ( $TPP_PriSecs{$TPPID} =~ /^Pri/i ) {
#     print "3. here<br>\n";
#     print "1. here. TPPID: $TPPID, TPP_BINs(): $TPP_BINs{$TPPID}<br>\n" if ($debug);

      $savekeyPri = $TPPID;
      $MyPrimary = "$TPP_BINs{$TPPID} - $TPP_Names{$TPPID}";

   } else {
#     print "4. here<br>\n";

      if ( $saveTPPIDPri{$TPPID} ) {
#        print "5. here<br>\n";
         $savekeyPri = $saveTPPIDPri{$TPPID};
         $MyPrimary  = $saveMyPrimary{$TPPID};

      } else {
#        print "6. here<br>\n";

         foreach $key (sort keys %TPPPS_Pri_Sec_IDs) {
           $keyPri = $TPPPS_Pri_IDs{$key};
           $keySec = $TPPPS_Sec_IDs{$key};
           print "JJJ- key: $key, keyPri: $keyPri, keySec: $keySec\n" if ($debug);
           next if ( $keyPri < 0 );
           $TPPPS_Sec_ID = $TPP_BINs{$keySec};
           $TPPPS_Pri_ID = $TPP_BINs{$keyPri};

           next if ( $keyPri < 0 || $keySec < 0 );
           next if ( $keySec !~ /^$TPPID$/ && $keyPri !~ /^$TPPID$/ );
           if ( $debug ) {
              print "key: $key, TPPID: $TPPID, keyPri: $keyPri, keySec: $keySec<br>\n";
              print "TPPPS_Pri_ID: $TPPPS_Pri_ID<br>\n";
              print "TPPPS_Sec_ID: $TPPPS_Sec_ID<br>\n";
           }
           next if ( !$TPPPS_Sec_ID );

           if ( $TPPPS_Pri_ID =~ /^$BIN$|^$lzBIN$/i ) {
              print "setMyPrimary: keyPri: $keyPri<br>\n" if ( $debug );
              $MyPrimary = "$TPPPS_Pri_ID - $TPP_Names{$keyPri}";
           } elsif ( $TPPPS_Sec_ID =~ /^$BIN$|^$lzBIN$/i ) {
              print "setMyPrimary: keyPri: $keyPri<br>\n" if ( $debug );
              $MyPrimary = "$TPPPS_Pri_ID - $TPP_Names{$keyPri}";
           }
           $savekeyPri = $keyPri;
         }
      }
   }
   $MyPrimary = "Unknown" if ( $MyPrimary =~ /^\s*$/ );

   ##$saveTPPIDPri{$TPPID}  = $savekeyPri;
   ##$saveMyPrimary{$TPPID} = $MyPrimary;

   if ( $debug ) {
      print "sub setMyPrimary: Exit. savekeyPri: $savekeyPri, MyPrimary: $MyPrimary<br><br>\n";
      print "="x96, "\n";
   }

   return ($savekeyPri, $MyPrimary);

}

#______________________________________________________________________________

sub calcRanges {

  my ($START, $END) = @_;
  my ($qstart, $qend) = 0;

  print qq#sub calcRanges. Entry. START: $START, END: $END<br>\n# if ($debug);

  my $nowTS = time();
  my $diffstart = $START * 24 * 60 * 60;	# number of days in seconds
  my $diffend   = $END   * 24 * 60 * 60;	# number of days in seconds

  my $jstart = $nowTS - $diffstart;
  my $jend   = $nowTS - $diffend;

  my ($ssec, $smin, $shour, $sday, $smonth, $syear) = (localtime($jstart))[0,1,2,3,4,5];
  $syear  += 1900;
  $smonth +=    1;
  my ($esec, $emin, $ehour, $eday, $emonth, $eyear) = (localtime($jend  ))[0,1,2,3,4,5];
  $eyear  += 1900;
  $emonth +=    1;

  my $FMT = "%04d%02d%02d";
  $qstart = sprintf("$FMT", $syear, $smonth, $sday);
  $qend   = sprintf("$FMT", $eyear, $emonth, $eday);

# print "days: ", ($jstart - $jend) / 60 / 60 / 24, "<br>\n" if ($debug);

  print qq#sub calcRanges. Exit. qstart: $qstart, qend: $qend<br>\n# if ($debug);

  return($qstart, $qend);

}

#______________________________________________________________________________

# jlh. 08/27/2012. Added Webinar and Testing databases, set by WHICHDB cookie

sub set_Webinar_or_Testing_DBNames {

# my $incdebug++;

  print qq#sub set_Webinar_or_Testing_DBNames. WHICHDB: $WHICHDB<br>\n# if ($incdebug);

  my $setcnt = 0;

  if ( $WHICHDB && $WHICHDB !~ /^LIVE$/i ) {

     foreach $dbin ( sort keys %DBNAMES ) {
       print qq#dbin: $dbin, DBNAMES(): $DBNAMES{"$dbin"}<br>\n# if ($incdebug);

       if ( $DBNAMES{"$dbin"} =~ /^Office|^ReconRxDB$|^Transfers|^Claims|^RBSReporting|SouthernScripts|CIPN/i ) {

          $TABLE = $DBTABN{$dbin};
          if ( $TABLE =~ /Pharmacy|Third_Party_Payers|TPP_Pri_Sec|Affiliate|Vendor|Interventions|Int_Rows|WebLogintb/i ) {
             print qq#\tSKIP $DBNAMES{"$dbin"}.$TABLE<br>\n# if ($incdebug);
          } else {

             if ( $incdebug ) {
                if ( $WHICHDB =~ /$DBNAMES{"$dbin"}/i ) {
                   print qq#\tDBNAMES(): $DBNAMES{"$dbin"}<br>\n#;
                   print qq#\tDBDESCS(): $DBDESCS{"$dbin"}<br>\n#;
                   print qq#\tSet $DBNAMES($dbin) from $DBNAMES{"$dbin"} to  '$WHICHDB'<br>\n#;
                   print "-"x72, "<br>\n";
                }
             }
             $DBNAMES{$dbin} = $WHICHDB;
             $$dbin = $DBNAMES{$dbin};
             $setcnt++;
          }
       }
       print "dbin: $dbin, val: ", $$dbin, "<br>\n" if ($incdebug && $WHICHDB =~ /$DBNAMES{"$dbin"}/i );
#      print "-"x96, "\n";
     }
  }

  print qq#sub set_Webinar_or_Testing_DBNames. exit. Set count: $setcnt<br>\n# if ($incdebug);
}

#______________________________________________________________________________

sub get_CSR_Name {

# my $incdebug++;
  my ($CUSTOMERID) = @_;
  my ($CSR_Name) = "";

  my $db_office  = 'officedb';
  my $TABLE   = 'weblogin';
  print "dbin: $db_office, DBNAME: $DBNAME, TABLE: $TABLE<br>\n" if ($debug);

  $dbm98 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	  { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = qq#SELECT fname, lname FROM $db_office.$TABLE WHERE id='$CUSTOMERID'#;

  print "sql: $sql<P>\n" if ($incdebug);

  $sth98 = $dbm98->prepare($sql);
  my $NumOfRows = $sth98->execute();

  print "Number of rows found: $NumOfRows<br>\n" if ($debug);

  @row = $sth98->fetchrow_array();
  ($LFirstName, $LLastName) = @row;
  $LFirstName =~ s/^\s*(.*?)\s*$/$1/;   # trim leading and trailing white spaces
  $LLastName  =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

  $CSR_Name = "$LLastName, $LFirstName";
  print "FOUND: LFirstName: $LFirstName, LLastName: $LLastName<br>CSR_Name: $CSR_Name<br>\n" if ($debug);

  $sth98->finish;
  # Close the Database
  $dbm98->disconnect;

  return ($CSR_Name);
}

#______________________________________________________________________________

sub handle_error {

  print qq#<hr size=6 color=red>\n#;
  print qq#sub handle_error. Entry.<br>\n# if ($debug);
  print qq#<strong><font size=+1>ERROR FOUND!</font></strong><br><br>\n#;

  my $sqlout;
  ($sqlout = $sql) =~ s/\n/<br>\n/g;
  print qq#sql:<br>$sqlout<br><hr>\n#;

  my $number = $DBI::err;		# Gets the error number
  my $str    = $DBI::errstr;	# In english

  warn $DBI::errstr, "<br>\n";
  print qq#<br>\n#;
  print qq#MySQL Error number: $number<br>\n#;
  print qq#MySQL Error string: $str   <br>\n#;
  print qq#sub handle_error. Exit.<br>\n# if ($debug);

  print qq#<br>sql<br>$sql<br><br>\n#;
  print qq#<br><br><a href="javascript:history.go(-1)"> Go Back </a><br><br>\n#;

  use Carp qw(cluck longmess shortmess);
# carp "Error in module!";
  my $long_message = longmess("Error: " );
  $long_message =~ s/\n/<br><br>\n/g;
  print "$long_message<br><br>\n";

  print qq#<hr size=6 color=red>\n#;

  exit;

}

#______________________________________________________________________________

sub handle_error_batch {

  print "-"x110, "\n";
  print "-"x110, "\n";

  print qq#sub handle_error_batch. Entry.\n# if ($debug);
  print qq# ***** ERROR FOUND! ***** \n#;

  $number = $DBI::err;		# Gets the error number
  $str    = $DBI::errstr;	# In english

  warn $DBI::errstr, "\n";
  print qq#\n#;
  print qq#MySQL Error number: $number\n#;
  print qq#MySQL Error string: $str   \n#;

  print "Execute a ROLLBACK!\n\n";
  my $sql  = qq#ROLLBACK #;
  ($rowsfound) = &jdo_sql($sql);
  print "Return from ROLLBACK. rowsfound: $rowsfound\n\n";

  use Carp;
  carp "Error in module!";

  print qq#\nsql\n$sql\n\n\n#;
  print qq#sub handle_error_batch. Exit.\n# if ($debug);

  print "-"x110, "\n";
  print "-"x110, "\n";

  exit;

}


#______________________________________________________________________________

sub jdo_sql {

  my ($sql) = @_;
  my ($rowsfound) = 0;
  if ( $incdebug ) {
     print "sub jdo_sql. Entry.\n";
     print "sql:\n$sql\n";
  }

  my $sth24  = $dbx->prepare($sql);
  $rowsfound = $sth24->execute;
  print "jdo_sql: rowsfound: $rowsfound\n" if ($incdebug);
  if ( $rowsfound =~ /^0|0E0/i ) {
#    print "Setting rowsfound to ZERO: 0\n" if ($incdebug);
     $rowsfound = 0;
  }

  if ( $rowsfound > 0 && $sql !~ /^\s*INSERT|^\s*UPDATE|^\s*REPLACE|^\s*DELETE/i ) {
     while ( my @row = $sth24->fetchrow_array() ) {
        print qq#row: #, join(",", @row), qq#\n# if ($incdebug);
     }
  }
  $sth24->finish;

  $sql = "";

  if ( $incdebug ) {
     print "sub jdo_sql. Exit. rowsfound: $rowsfound\n";
     print "-"x96, "\n";
  }

  return($rowsfound);
}

# ______________________________________________________________________________
# call with:
# &tohere("subname", $START);

sub tohere {

   my ($subroutine, $START) = @_;

   $elapsed = sprintf("%d", time() - $START);

   my $hours   = int($elapsed / 3600);
   my $left    = $elapsed - ($hours * 3600);
   my $minutes = int($left / 60);
   my $seconds = $left - ($minutes * 60);

   print "To Here: $subroutine. Elapsed: $elapsed seconds ";
   if ( $elapsed > 0 ) {
      print " ( ";
      print "$hours hours "     if ( $hours   > 0 );
      print "$minutes minutes " if ( $minutes > 0 );
      print "$seconds seconds " if ($seconds  > 0);
      print ")";
   }
   print "\n";
}

# ______________________________________________________________________________
# call with:
# &tohereweb("subname", $START);

sub tohereweb {
   my ($subroutine, $START) = @_;
   $elapsed = sprintf("%d", time() - $START);
   $minutes = sprintf("%3d", int($elapsed / 60));
   $seconds = sprintf("%3d", $elapsed - ($minutes * 60));
   print "To Here: $subroutine. Elapsed: $elapsed seconds ($minutes minutes, $seconds seconds)<br>\n";

}

#______________________________________________________________________________

sub LastDayOfMonth {

   my ($year, $month) = @_;

   print "sub LastDayOfMonth. Entry. year: $year, month: $month<br>\n" if ($incdebug);

   use Date::Calc qw(Today Add_Delta_YMD Days_in_Month);
   if ( $incdebug ) {
      printf "start: %04d-%02d-%02d\n", $year, $month, 1;
      printf "  end: %04d-%02d-%02d\n", $year, $month, Days_in_Month($year, $month);
   }
   $date = Days_in_Month($year, $month);

   print "sub LastDayOfMonth. Exit. date: $date<br>\n" if ($incdebug);

   return $date;
}

#______________________________________________________________________________
# ($ENV) = &What_Env_am_I_in;

sub What_Env_am_I_in {

  $SERVER_NAME = $ENV{"SERVER_NAME"};
  my $dot = "\\.";
  my @pcs = split("$dot", $SERVER_NAME);
  $ENV = $pcs[0];
  return($ENV);

}

#______________________________________________________________________________

sub jCompare {

  my ($name, $save) = @_;
  my $changes = 0;

# my $debug++;

  print "sub jCompare: Entry. name: $name, save: $save<br>\n" if ($debug);

  if ( $name =~ /^-?\d+/ ) {
     # Do numeric comparison
     if ( "$name" != "$save" ) {
        $changes++;
     }
  } else {
#    if ( "$name" !~ /^\s*$save\s*$/i ) {
     if ( "$name" ne "$save" ) {
        $changes++;
     }
  }

  print "sub jCompare: Exit. changes: $changes<br>\n" if ($debug);

  return($changes);
}

#______________________________________________________________________________

sub Get_DrugNames {

  my $dbin    = "LTDBNAME";
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $HASH    = $HASHNAMES{$dbin};

  my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error_batch );

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error_batch;

  my $sql = "";
  $sql .= qq# SELECT NDC, tcgpi_name, dosage_form, strength, strength_unit_of_measure, generic_product_identifier,substring(generic_product_identifier,1,6) as minorsubclass, drug_name  
                FROM $DBNAME.$TABLE\n#;
 
  print "sql:\n$sql\n" if ($debug);

  $sthLM = $dbm->prepare($sql);
  $sthLM->execute();
    
  my $NumOfRows = $sthLM->rows;

  if ( $NumOfRows > -1 ) {
     while ( my @row = $sthLM->fetchrow_array() ) {
        ($NDC,$drug_name, $dosage_form, $strength, $strength_UOM, $GPI, $MSC, $dname ) = @row;
	$DrugNames{$NDC}    = "$drug_name";
	$DrugNames2{$NDC}   = "$dname";
	$GPI{$NDC}          = "$GPI";
	$Minor_SC{$NDC}     = "$MSC";
     }
  }
  $sthLM->finish;
  $dbm->disconnect;
  
  print "sub Get_DrugNames: exit. $DBNAME.$TABLE - Drug Name: $Drug_Name\n" if ($debug);
  return(\%Minor_SC,\%GPI,\%DrugNames,\%DrugNames2);
}

#______________________________________________________________________________

sub Lookup_MSBorG {

  my ($NDC_Number) = @_;
  my ($Brand_Generic_Indicator) = "";
  my $NDC            = 0;
  my $OTC;

# my $debug++;

  print "sub Lookup_MSBorG: Entry. NDC_Number: $NDC_Number\n" if ($debug);

  if ( $Lookup_MSBorG_Hash{-20000} eq "J" ) {
#   print "Hash already exists. Skip rebuilding it!\n" if ($debug);
  } else {
    
    print "Hash does not exist. Building it!\n" if ($debug);

    my $dbin    = "LTDBNAME";
    my $DBNAME  = $DBNAMES{"$dbin"};
    my $TABLE   = $DBTABN{"$dbin"};
    my $HASH    = $HASHNAMES{$dbin};
  
    my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error_batch );
  
    my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error_batch;
  
    my $sql = "";
    $sql .= qq# SELECT NDC, MSBorG, otc, multi_source_code, generic_product_identifier  FROM $DBNAME.$TABLE\n#;
   
    print "sql:\n$sql\n" if ($debug);
  
    $sthLM = $dbm->prepare($sql);
    $sthLM->execute();
      
    my $NumOfRows = $sthLM->rows;
#   print "sub Lookup_MSBorG: $DBNAME.$TABLE - Number of rows found: $NumOfRows\n" if ($debug);
  
    if ( $NumOfRows > -1 ) {
       while ( my @row = $sthLM->fetchrow_array() ) {
          ($NDC, $Brand_Generic_Indicator, $OTC, $MONY, $GPI) = @row;
          $Lookup_MSBorG_Hash{$NDC} = $Brand_Generic_Indicator;
          $Lookup_MSBorG_OTC{$NDC} = $OTC;
          $Lookup_MSBorG_MONY{$NDC} = $MONY;
          $Lookup_MSBorG_GPI{$NDC} = $GPI;
       }
       $Lookup_MSBorG_Hash{-20000} = "J";
    }

    $sthLM->finish;
    $dbm->disconnect;

    print "Hash 'Lookup_MSBorG' now has hash members!\n" if ($debug);

  }

  $Brand_Generic_Indicator = $Lookup_MSBorG_Hash{$NDC_Number};

  if ( $Brand_Generic_Indicator =~ /^\s*$/ ) {
     $NDC_Number = substr("00000000000" . $NDC_Number, -11);
     $Brand_Generic_Indicator = $Lookup_MSBorG_Hash{$NDC_Number};
  }

  print "sub Lookup_MSBorG: exit. $DBNAME.$TABLE - Brand_Generic_Indicator: $Brand_Generic_Indicator\n" if ($debug);
  print "\n", "-"x120, "\n\n" if ($debug);

  return($Brand_Generic_Indicator);

}

#______________________________________________________________________________

###############################################################################
#
# Functions used for Autofit.
#
###############################################################################

###############################################################################
#
# Adjust the column widths to fit the longest string in the column.
#
sub autofit_columns {

    my $worksheet = shift;
    my $col       = 0;

    for my $width (@{$worksheet->{__col_widths}}) {

        $worksheet->set_column($col, $col, $width) if $width;
        $col++;
    }
}


###############################################################################
#
# The following function is a callback that was added via add_write_handler()
# above. It modifies the write() function so that it stores the maximum
# unwrapped width of a string in a column.
#
sub store_string_widths {

    my $worksheet = shift;
    my $col       = $_[1];
    my $token     = $_[2];

    # Ignore some tokens that we aren't interested in.
    return if not defined $token;       # Ignore undefs.
    return if $token eq '';             # Ignore blank cells.
    return if ref $token eq 'ARRAY';    # Ignore array refs.
    return if $token =~ /^=/;           # Ignore formula

    # Ignore numbers
    return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

    # Ignore various internal and external hyperlinks. In a real scenario
    # you may wish to track the length of the optional strings used with
    # urls.
    return if $token =~ m{^[fh]tt?ps?://};
    return if $token =~ m{^mailto:};
    return if $token =~ m{^(?:in|ex)ternal:};


    # We store the string width as data in the Worksheet object. We use
    # a double underscore key name to avoid conflicts with future names.
    #
    my $old_width    = $worksheet->{__col_widths}->[$col];
    my $string_width = string_width($token);

    if (not defined $old_width or $string_width > $old_width) {
        # You may wish to set a minimum column width as follows.
        #return undef if $string_width < 10;

        $worksheet->{__col_widths}->[$col] = $string_width;
    }

    # Return control to write();
    return undef;
}


###############################################################################
#
# Very simple conversion between string length and string width for Arial 10.
# See below for a more sophisticated method.
#
#	sub string_width {
#
#	# jlh. 2012/02/03
#	    return 1.2 * length $_[0];
#	#   return 0.9 * length $_[0];
#
#	}

###############################################################################
#
# This function uses an external module to get a more accurate width for a
# string. Note that in a real program you could "use" the module instead of
# "require"-ing it and you could make the Font object global to avoid repeated
# initialisation.
#
# Note also that the $pixel_width to $cell_width is specific to Arial. For
# other fonts you should calculate appropriate relationships. A future version
# of S::WE will provide a way of specifying column widths in pixels instead of
# cell units in order to simplify this conversion.
#

sub string_width {

    require Font::TTFMetrics;

    my $arial        = Font::TTFMetrics->new('c:\windows\fonts\arial.ttf');

    my $font_size    = 10;
    my $dpi          = 96;
    my $units_per_em = $arial->get_units_per_em();
    my $font_width   = $arial->string_width($_[0]);

    # Convert to pixels as per TTFMetrics docs.
    my $pixel_width  = 6 + $font_width *$font_size *$dpi /(72 *$units_per_em);

    # Add extra pixels for border around text.
    $pixel_width  += 6;

    # Convert to cell width (for Arial) and for cell widths > 1.
    my $cell_width   = ($pixel_width -5) /7;

    # jlh. 03/01/2012
    $cell_width = 6 if ( $cell_width < 6 );

    return $cell_width;

}

#______________________________________________________________________________

sub get_column_names {

  my ($DBNAME, $TABLE) = @_;
#  my $incdebug++;

  print "sub get_column_names. Entry. DBNAME: $DBNAME, TABLE: $TABLE<br>\n" if ($incdebug);

  my @COLUMNS = ();

  my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error_batch );

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error_batch;

  DBI->trace(1) if ($dbitrace);

# $sql = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='ReconRxDB' && TABLE_NAME='incomingtb' order by COLUMN_NAME";

  $sql = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='$DBNAME' && TABLE_NAME='$TABLE' order by COLUMN_NAME && COLUMN_NAME <> '835remitstbID'";

  print "sql: $sql\n<br><br>\n" if ($incdebug);

  $sthGCN = $dbm->prepare($sql);
  $sthGCN->execute();

  my $NumOfRows = $sthGCN->rows;
  print "Number of rows found: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthGCN->fetchrow_array() ) {
    my ($COLUMN) = @row;
    push(@COLUMNS, $COLUMN);
  }

  $sthGCN->finish;
  $dbm->disconnect;

# print "Columns found: \n", join(" ## ", @COLUMNS), "<br>\n" if ($incdebug);

  print "sub get_column_names. Exit.<br>\n" if ($incdebug);
  return(@COLUMNS);

}

#_______________________________________________________________________________

sub print_time_to_here {

  my ($msg) = @_;
  my ($package, $filename, $line) = caller;

  my $debug = 0;

  if ( $print_time ) {

  # my $fmt = "%0.02f";
    my $fmt = "%4d";
  
    my $now = time();
    print "package: $package, filename: $filename, line: $line, now: $now<br>\n" if ($debug);
  
    my $slc = time() - $global_ptth;
    my $slcmins = int($slc / 60);
    my $slcsecs = sprintf("$fmt", (($slc / 60) - $slcmins) * 60);
    my $slctime = "$slcmins mins, $slcsecs secs";
  
    my $diff = time() - $starttime;
    my $runmins = int($diff / 60);
    my $runsecs = sprintf("$fmt", (($diff / 60) - $runmins) * 60);
    my $runtime = "$runmins min, $runsecs secs";
  
#   print "PTTH: $now: $package:$line - Since: $slctime. ToHere: $diff ($runtime) - $msg<hr>\n";
    print "PTTH: $now: $package:$line - Since: $slctime. ToHere: $diff - $msg<hr>\n";
  
#   $global_ptth = time(); 
  }
}

#_______________________________________________________________________________

sub get_GPI {

  my ($NDC_Number) = @_;
  my $DRUGNAME = "";
  my $GPI      = "";
  my $NDC      = 0;

  print "sub get_GPI: Entry. NDC_Number: $NDC_Number\n" if ($incdebug);

  if ($GPIs{$NDC} ) {

     $GPI = $GPIs{$NDC};
     $DRUGNAME = $DRUGNAMEs{$NDC};
     $CONTROLLED_SUBSTANCE_CODE = $CONTROLLED_SUBSTANCE_CODEs{$NDC};

  } else {

    my $DBNAME  = "Medispan";
    my $TABLE   = "mf2ndc";
  
    my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error_batch );
  
    my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error_batch;
  
  #ndc_upc_hri, CONCAT(drug_name," ",strength," ",strength_unit_of_measure," - ",dosage_form), generic_product_identifier
    my $sql = "";
    $sql = qq#
  SELECT 
  ndc_upc_hri, tcgpi_name, generic_product_identifier, controlled_substance_code
  FROM $DBNAME.$TABLE
    LEFT JOIN mf2name 
      ON mf2ndc.drug_descriptor_id = mf2name.drug_descriptor_id
    LEFT JOIN mf2tcgpi 
      ON mf2name.generic_product_identifier = mf2tcgpi.tcgpi_id
  WHERE 
  ndc_upc_hri = $NDC_Number
  #;
   
    print "sql:\n$sql\n" if ($incdebug);
  
    $sthLM = $dbm->prepare($sql);
    $sthLM->execute();
      
    my $NumOfRows = $sthLM->rows;
    print "sub get_GPI: $DBNAME.$TABLE - Number of rows found: $NumOfRows\n" if ($incdebug);
  
    if ( $NumOfRows > 0 ) {
       while ( my @row = $sthLM->fetchrow_array() ) {
          ($NDC, $DRUGNAME, $GPI, $CONTROLLED_SUBSTANCE_CODE) = @row;
          print "Yo: NDC: $NDC, DRUGNAME: $DRUGNAME, GPI: $GPI, CONTROLLED_SUBSTANCE_CODE: $CONTROLLED_SUBSTANCE_CODE\n" if ($incdebug);
       }
    }
    $sthLM->finish;
    $dbm->disconnect;

    $GPIs{$NDC}                       = $GPI;
    $DRUGNAMEs{$NDC}                  = $DRUGNAME;
    $CONTROLLED_SUBSTANCE_CODEs{$NDC} = $CONTROLLED_SUBSTANCE_CODE;
  }
  
# print "\n", "-"x120, "\n\n" if ($incdebug);

  if ( $incdebug ) {
     print "sub get_GPI: exit. $DBNAME.$TABLE - GPI: $GPI, DRUGNAME: $DRUGNAME, CONTROLLED_SUBSTANCE_CODE: $CONTROLLED_SUBSTANCE_CODE\n";
     print "-"x80, "\n";
  }

  return($GPI, $DRUGNAME, $CONTROLLED_SUBSTANCE_CODE);

}

#_______________________________________________________________________________

sub readGroups {

  my ($getType) = @_;

  print "sub readGroups. Entry. getType: $getType\n" if ($incdebug);
  my $grpcount = 0;

  $sql  = "
SELECT PGGroup, PGType, PGEmail, PGNCPDPs , PGPharmacy_IDs
FROM Officedb.pharmacy_groups
WHERE PGType='$getType'
";
print "sql:\n$sql\n";

  $strRG = $dbx->prepare("$sql");
  $NumOfRows = $strRG->execute;

  print "sub strRG: Number of rows found: $NumOfRows\n";

  if ( $NumOfRows > 0 ) {
     while ( my @row = $strRG->fetchrow_array() ) {

       my ( $PGGroup, $PGType, $PGEmail, $PGNCPDPs, $PGPharmacy_IDs ) = @row;
       $PGGroup        =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
       $PGType         =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
       $PGEmail        =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
       $PGNCPDPs       =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
       $PGPharmacy_IDs =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

       $PGEmails{$PGGroup}       = $PGEmail;
       $PGNCPDPs{$PGGroup}       = $PGNCPDPs;
       $PGPharmacy_IDs{$PGGroup} = $PGPharmacy_IDs;

       $grpcount++;
     }
  }
  $strRG->finish();

  print "sub readGroups. Exit. Groups found: $grpcount\n" if ($incdebug);
  
}

#_______________________________________________________________________________

sub DataFound {

  my ($NCPDP, $TYPE) = @_;
  my $DataFound = 0;

# my $incdebug++;

  print "sub DataFound. Entry. NCPDP: $NCPDP, TYPE: $TYPE<br>\n" if ($incdebug);

  my $DBNAME = "";
  my $TABLE  = "";

  if      ( $TYPE =~ /RBS/i ) {
     $DBNAME = "RBSReporting";
     $TABLE  = "incomingtb_RBSData";
  } elsif ( $TYPE =~ /ReconRx/i ) {
     $DBNAME = "ReconRxDB";
     $TABLE  = "incomingtb";
  } 

  $sql  = "SELECT dbNCPDPNumber FROM $DBNAME.$TABLE ";
  $sql .= "WHERE dbNCPDPNumber=$NCPDP ";
  $sql .= "LIMIT 1";
  print "sql:<br>\n$sql<br>\n" if ($incdebug);

  $strh = $dbx->prepare("$sql");
  $NumOfRows = $strh->execute;

  print "sub strh: Number of rows found: $NumOfRows<br>\n" if ($incdebug);

  if ( $NumOfRows > 0 ) {
     $DataFound++;
  }
  $strh->finish();

  print "sub DataFound. Exit. DataFound: $DataFound<br>\n" if ($incdebug);

  return ($DataFound);
  
}

#______________________________________________________________________________

sub isReconRxMember {
  my ($USER, $PASS) = @_;
  $PROGRAM = "ReconRx";
  my ($isMember, $VALID) = &isAuthorizedMember($USER, $PASS, $PROGRAM);
  return($isMember, $VALID);
}

#______________________________________________________________________________

sub isAuthorizedMember {
  my ($USER, $PASS, $PROGRAM) = @_;
  my $arete = 0;
  
  ($USER) = &StripJunk($USER);
  $PASS   =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

  my $isMember = 0;

  my @progs = split(/\|/, $PROGRAM);
  my $and_where = 'AND (';
  
  my $DBNAME       = 'Officedb';
  my $TABLE        = 'Weblogin';
  my $DTL_TABLE    = 'Weblogin_dtl';
  my $tbl_pharmacy = 'Pharmacy';

  $dbx_login = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
               { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  foreach $p (@progs) {
    $and_where .= " b.program LIKE '%$p%' OR";
  }

  $and_where =~ s/OR$/\)/i;

  $sql = "SELECT a.id, a.type, b.pharmacy_id, permission_level, aggregated, arete_type, whichdb
            FROM $DBNAME.$TABLE a
            JOIN $DBNAME.$DTL_TABLE b ON a.id = b.login_id
   	    LEFT JOIN $DBNAME.$tbl_pharmacy c on c.pharmacy_id = b.pharmacy_id
           WHERE a.login='$USER' 
             AND a.password=AES_ENCRYPT('$PASS','PAI20181217!') 
	     $and_where";

  $sth_login = $dbx_login->prepare($sql);
  my $NumOfRows = $sth_login->execute();

  if ( $NumOfRows > 0 ) {
    ($ID, $TYPE, $PH_ID, $LEVEL, $ag, $aretetype, $whichdb) = $sth_login->fetchrow_array();
    $arete = $NumOfRows if($aretetype);
    $isMember++;
  }

  $sth_login->finish;
  
  $dbx_login->disconnect;

  return($isMember, $ID, $TYPE, $PH_ID, $LEVEL, $NumOfRows, $ag, $arete, $whichdb);
}

#______________________________________________________________________________

sub isAuthorizedArete {
  my ($AUTHKEY, $PROGRAM) = @_;
  
  my $isMember = 0;

  my @progs = split(/\|/, $PROGRAM);
  
  my $DBNAME   = 'Officedb';
  my $TABLE_A  = 'weblogin_auth';
  my $TABLE_P  = 'pharmacy';
  my $TABLE_L  = 'weblogin';

  $dbx_login = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
               { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  $sql = "SELECT l.id, l.type, p.Pharmacy_ID, p.Store_User, l.permission_level
            FROM $DBNAME.$TABLE_A a
	    JOIN $DBNAME.$TABLE_P p ON (a.pharmacy_id = p.pharmacy_id AND p.Status_ReconRx = 'Active')
	    JOIN $DBNAME.$TABLE_L l ON (p.Store_User = l.login)
           WHERE auth_key = '$AUTHKEY'";

  $sth_login = $dbx_login->prepare($sql);
  my $NumOfRows = $sth_login->execute();

  if ( $NumOfRows > 0 ) {
    ($user, $type, $ph_id, $login, $level) = $sth_login->fetchrow_array();
    $isMember++;

    #$dbx_login->do("DELETE FROM $DBNAME.$TABLE_A WHERE auth_key = '$AUTHKEY'");
  }

  $sth_login->finish;

  $dbx_login->disconnect;

  return($isMember, $user, $type, $ph_id, $login, $level, $NumOfRows);
}

#______________________________________________________________________________

sub checkStoreUser {

# my $debug++;
  my ($PROGRAM, $Store_User) = @_;
  my ($STORE_USER_ALREADY_EXISTS) = 0;
  print "sub checkStoreUser: Entry. PROGRAM: $PROGRAM, Store_User: $Store_User<br>\n" if ($debug);
  
  my $MYHASH = "Pharmacy_Store_User";
  if ($Store_User =~ /^\s*$/ ) {
     print "sub checkStoreUser: Skipping check!<br>\n" if ($debug);
  } else {
    if ( $PROGRAM =~ /QCP/i ) {
       $MYHASH = "Clinic_Store_User";
       $Pharmacy_ID = $Clinic_ID;
       ##print "here:$Pharmacy_ID";
    } elsif ($PROGRAM =~ /COMPANY/i ) {
       $MYHASH = "Company_Store_User";
    }
    print "MYHASH: $MYHASH<hr>\n" if ($debug);

    foreach $PSUkey (sort { $$MYHASH{$a} cmp $$MYHASH{$b} } keys %$MYHASH) {
       print "PSUkey: $PSUkey, inCompanyID: $inCompanyID<br>\n" if ($debug);
       next if ( $PSUkey == $Pharmacy_ID);
       $chkPSU = $$MYHASH{$PSUkey};
       print "Store_User: $Store_User, chkPSU: $chkPSU<br>\n" if ($debug);

       if ( $Store_User =~ /^$chkPSU$/i ) {
          print "$nbsp $nbsp chkPSU: $chkPSU, Store_User: $Store_User<br>\n" if ($debug);
          $STORE_USER_ALREADY_EXISTS = $PSUkey;
          last;
       }
#      print "<hr>\n";
    }
    print "<hr size=8 noshade color=green>\n" if ($debug);

    if ($STORE_USER_ALREADY_EXISTS == 0) {
      print "Check to see if this newUsername exists as 'SuperUser'<br>\n" if ($debug);
      # Note: mySQL ignores case
      my $sql = "
      SELECT login 
      FROM officedb.weblogin
      WHERE 
      login = '$Store_User';
      ";
      print "checkStoreUser: sql<br>$sql<hr>\n" if ($debug);
      my $sths = $dbx->prepare("$sql");
      $rowsfound = $sths->execute;
      if ( $rowsfound =~ /^0|0E0/i ) { $rowsfound = 0; }
      if ($rowsfound > 0) {
        $STORE_USER_ALREADY_EXISTS++;
      }
    } else {
       print "<font size=+2>This store user value '$Store_User' must be unique and is already being used<br>by pharmacy '$Pharmacy_Names{$STORE_USER_ALREADY_EXISTS}' ($STORE_USER_ALREADY_EXISTS)</font><hr>\n";

    }

  }

  print "sub checkStoreUser: Exit. STORE_USER_ALREADY_EXISTS: $STORE_USER_ALREADY_EXISTS<br>\n" if ($debug);
  return ($STORE_USER_ALREADY_EXISTS);
}

#_______________________________________________________________________________

sub displayProfileInfo {
  my ($Pharmacy_ID, $HELPURL) = @_;

  # -----------------------------------------

  my $dbin = "";

    if      ( $ENV{APP_POOL_ID} =~ /PharmAssess/i ) {
     $dbin     = "PHDBNAME";
     $PN       = "Pharmacy_Name";
     $PRI_CT_CTL = '21';
     $PIC_CT_CTL = '23';
     $CRED_CT_CTL = '25';
     $id_fld   = "Pharmacy_ID";
  } else {
     $dbin     = "PHDBNAME";
     $PN       = "Pharmacy_Name";
     $PRI_CT_CTL = '21';
     $PIC_CT_CTL = '23';
     $CRED_CT_CTL = '25';
     $id_fld   = "Pharmacy_ID";
  }

  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  my $FIELDS   = $DBFLDS{"$dbin"};
  my $FIELDS2  = $DBFLDS{"$dbin"} . "2";
  my $fieldcnt = $#${FIELDS2} + 2;

# connect to the pharmacy MySQL database

  $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT $$FIELDS FROM $DBNAME.$TABLE WHERE $id_fld = $Pharmacy_ID";

  $sthp = $dbp->prepare($sql);
  $sthp->execute();
  my $numofrows = $sthp->rows;

  @$FIELDS3 = @$FIELDS2;
  while (my @row = $sthp->fetchrow_array()) {
    (@$FIELDS3) =  @row;
    $ptr = -1;
    foreach $pc (@$FIELDS3) {
       $ptr++;
       my $name = @$FIELDS2[$ptr];
       ${$name} = $pc || $nbsp;
    }
  }

  $sthp->finish();

  if ( $ENV{APP_POOL_ID} !~ /QCP/i ) {
    $sql = "SELECT name, email
              FROM $DBNAME.${TABLE}_contacts
	     WHERE Pharmacy_ID = $Pharmacy_ID
	        && contact_ctl_id = $PRI_CT_CTL";
    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $numofrows = $sthp->rows;

    if ($numofrows > 0) {
      ( $Primary_Contact_Name, $Primary_Contact_Email) = $sthp->fetchrow_array();
    }
    $sthp->finish();

    $sql = "SELECT name, email
              FROM $DBNAME.${TABLE}_contacts
	     WHERE Pharmacy_ID = $Pharmacy_ID
	        && contact_ctl_id = $PIC_CT_CTL";
    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $numofrows = $sthp->rows;

    if ($numofrows > 0) {
      ( $PIC_Contact_Name, $PIC_Contact_Email) = $sthp->fetchrow_array();
    }
    $sthp->finish();

    $sql = "SELECT name, email
              FROM $DBNAME.${TABLE}_contacts
	     WHERE Pharmacy_ID = $Pharmacy_ID
	        && contact_ctl_id = $CRED_CT_CTL";
    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $numofrows = $sthp->rows;

    if ($numofrows > 0) {
      ( $Cred_Contact_Name, $Cred_Contact_Email) = $sthp->fetchrow_array();
    }
    $sthp->finish();
  }

  # Close the Databases
  $dbp->disconnect;

  # -----------------------------------------

  $Pharmacy_Name = $$PN;

  if ( $Comm_Pref =~ /Both/i ) {
     $Comm_Pref_Out = "Email & Fax";
  } else {
     $Comm_Pref_Out = $Comm_Pref;
  }

  $active_date = '';

  if ( $ENV{APP_POOL_ID} =~ /PharmAssess/i ) {
     if ($Active_Date_RBS =~ /-/) {
        $active_date = $Active_Date_RBS;
     }
     elsif ($Active_Date_Cred =~ /-/) {
        $active_date = $Active_Date_Cred;
     }
     elsif ($Active_Date_RBS_Direct =~ /-/) {
        $active_date = $Active_Date_RBS_Direct;
     }
     else {
        $active_date = 'Not Set';
     } 
  } elsif ( $ENV{APP_POOL_ID} =~ /ReconRx/i ) {
     if ($Active_Date_ReconRx =~ /-/) {
        $active_date = $Active_Date_ReconRx;
     }
     elsif ($Active_Date_ReconRx_Clinic =~ /-/) {
        $active_date = $Active_Date_ReconRx_Clinic;
     }
     elsif ($Active_Date_ReconRx_SP =~ /-/) {
        $active_date = $Active_Date_ReconRx_SP;
     }
     else {
        $active_date = 'Not Set';
     } 
  }

  $DEA                   = "Unknown" if ( !$DEA );
  $DEA_Expiration        = "Unknown" if ( !$DEA_Expiration );
  $Primary_Contact_Name  = "Unknown" if ( !$Primary_Contact_Name );
  $Primary_Contact_Email = "Unknown" if ( !$Primary_Contact_Email );
  $PIC_Contact_Name      = "Unknown" if ( !$PIC_Contact_Name );
  $PIC_Contact_Email     = "Unknown" if ( !$PIC_Contact_Email );
  $Cred_Contact_Name     = "Unknown" if ( !$Cred_Contact_Name );
  $Cred_Contact_Email    = "Unknown" if ( !$Cred_Contact_Email );
  $State_Permit_Number   = "Unknown" if ( !$State_Permit_Number );
  $State_Permit_Expiration_Date = "Unknown" if ( !$State_Permit_Expiration_Date || $State_Permit_Expiration_Date =~ /^\s*$|nbsp/i );
  $Software_Vendor       = "Unknown" if ( !$Software_Vendor );
  $Primary_Switch        = "Unknown" if ( !$Primary_Switch );

  print qq#<p class="profilename">$Pharmacy_Name</p>\n#;
  print qq#<p class="profileaddress">#;
  if ( $Address && $Address !~ /\&nbsp\;/i ) {
     print qq#$Address<br>#;
  } else {
     print qq#Unknown Address<br>#;
  }
  if ( $City && $City !~ /\&nbsp\;/i ) {
     print qq#$City, #;
  } else {
     print qq#Unknown City, #;
  }
  if ( $State && $State !~ /\&nbsp\;/i && $State !~ /\-\-/ ) {
     print qq#$State, #;
  } else {
     print qq#Unknown State, #;
  }
  if ( $Zip && $Zip !~ /\&nbsp\;/i &&  $Zip !~ /\-\-/ ) {
     print qq#$Zip#;
  } else {
     print qq#Unknown Zip#;
  }
  print qq#</p>\n#;

  #&display_Upcoming_Events;

  print qq#<table border=1 class="profile">\n#;
  print qq#<tr valign="top"><td>\n#;

  print qq#<table border=1 class="profile">\n#;
    print qq#<tr><th nowrap>Active Date</th> <td>$active_date</td></tr>\n#;
    print qq#<tr><th nowrap>Phone</th> <td>$Business_Phone</td></tr>\n#;
    print qq#<tr><th nowrap>Fax</th> <td> $Fax_Number</td></tr>\n#;
 
    print qq#<tr><th nowrap>Primary Contact</th>  <td> $Primary_Contact_Name</td></tr>\n#;
    print qq#<tr><th nowrap>Email</th>            <td> $Primary_Contact_Email</td></tr>\n#;

    if ( $Pharmacy_Types{$Pharmacy_ID} !~ /^VacOnly$/i ) {
       print qq#<tr><th nowrap>PIC</th>              <td> $PIC_Contact_Name</td></tr>\n#;
       print qq#<tr><th nowrap>PIC Email</th>        <td> $PIC_Contact_Email</td></tr>\n#;
       print qq#<tr><th nowrap>PIC Lic Number</th>   <td> $PIC_License_Number</td></tr>\n#;
       print qq#<tr><th nowrap>- Expiration Date</th><td> $PIC_License_Expiration_Date</td></tr>\n#;
       print qq#<tr><th nowrap>Sotware Vendor</th>   <td> $Software_Vendor</td></tr>\n#;
    }
  print qq#</table>\n#;
 
  print qq#</td><td>\n#;
#      print qq#<tr><th colspan=2>$nbsp</th></tr>\n#;
 
  print qq#<table border=1 class="profile">\n#;
    print qq#<tr><th nowrap>&nbsp</th> <td> &nbsp</td></tr>\n#;
    print qq#<tr><th nowrap>NCPDP</th> <td> $NCPDP</td></tr>\n#;
    print qq#<tr><th nowrap>NPI  </th> <td> $NPI  </td></tr>\n#;

    if ( $Pharmacy_Types{$Pharmacy_ID} !~ /^VacOnly$/i ) {
       print qq#<tr><th nowrap>State Permit</th> <td> $State_Permit_Number</td></tr>\n#;
       print qq#<tr><th nowrap>- Expiration Date</th> <td> $State_Permit_Expiration_Date</td></tr>\n#;
       print qq#<tr><th nowrap>Cred Email</th>       <td> $Cred_Contact_Email</td></tr>\n#;
       print qq#<tr><th nowrap>DEA Permit</th> <td> $DEA</td></tr>\n#;
       print qq#<tr><th nowrap>- Expiration Date</th> <td> $DEA_Expiration</td></tr>\n#;
 
#      print qq#<tr><th colspan=2>$nbsp</th></tr>\n#;
 
       if ( $Website =~ /^N\/A$|\&nbsp\;/i || !$Website ) {
          $Website = "N/A";
          print qq#<tr><th nowrap>Website</th> <td>$Website</td></tr>\n#;
 
       } else {
          if ( $Website =~ /^http:/i ) {
             ($Website = $Website) =~ s/^http:\/\///;
          } else {
             $Website = $Website;
             $Website = "http://$Website";
          }
          print qq#<tr><th nowrap>Website</th> <td><a href="$Website" target="_blank">$Website</a></td></tr>\n#;
       }
    }

    print qq#<tr><th nowrap>Communication Pref</th> #;
    print qq#    <td>$Comm_Pref_Out</td></tr>\n#;
    print qq#<tr><th nowrap>Switch Company</th> #;
    print qq#    <td>$Primary_Switch</td></tr>\n#;

    print qq#</table>\n#;

  print qq#</td></tr>\n#;
  
  if ($HELPURL !~ /^\s*$/) {
    print qq#<tr><th colspan=2>$nbsp</th></tr>\n#;
    print qq#<tr><th colspan=2>Please <a href="$HELPURL">Click here</a> to request updates/changes</th></tr>\n#;
  }

  print qq#</table>\n#;
}

#_______________________________________________________________________________

sub displayProfileInfoCompany {
  my ($inCompanyID, $HELPURL) = @_;

  # -----------------------------------------

  my $dbin = "";

  $dbin     = "CODBNAME";
  $PN       = "Company_Name";

  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  my $FIELDS   = $DBFLDS{"$dbin"};
  my $FIELDS2  = $DBFLDS{"$dbin"} . "2";
  my $fieldcnt = $#${FIELDS2} + 2;

  $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
	        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT $$FIELDS FROM $DBNAME.$TABLE WHERE Company_ID = $inCompanyID";

  $sthp = $dbp->prepare($sql);
  $sthp->execute();
  my $numofrows = $sthp->rows;

  @$FIELDS3 = @$FIELDS2;
  while (my @row = $sthp->fetchrow_array()) {
    (@$FIELDS3) =  @row;
    $ptr = -1;
    foreach $pc (@$FIELDS3) {
       $ptr++;
	    my $name = @$FIELDS2[$ptr];
       ${$name} = $pc || $nbsp;
    }
  }

  $sthp->finish();

  # Close the Databases
  $dbp->disconnect;

  # -----------------------------------------

  # Now display the page of Pharmacy information

  $Pharmacy_Name = $$PN;

  if ( $Comm_Pref =~ /Both/i ) {
     $Comm_Pref_Out = "Email & Fax";
  } else {
     $Comm_Pref_Out = $Comm_Pref;
  }

  $Primary_Contact_Name  = "Unknown" if ( !$Primary_Contact_Name );
  $Primary_Contact_Email = "Unknown" if ( !$Primary_Contact_Email );

  print qq#<p class="profilename">$Pharmacy_Name</p>\n#;
  print qq#<p class="profileaddress">#;
  if ( $Address && $Address !~ /\&nbsp\;/i ) {
     print qq#$Address<br>#;
  } else {
     print qq#Unknown Address<br>#;
  }
  if ( $City && $City !~ /\&nbsp\;/i ) {
     print qq#$City, #;
  } else {
     print qq#Unknown City, #;
  }
  if ( $State && $State !~ /\&nbsp\;/i && $State !~ /\-\-/ ) {
     print qq#$State, #;
  } else {
     print qq#Unknown State, #;
  }
  if ( $Zip && $Zip !~ /\&nbsp\;/i &&  $Zip !~ /\-\-/ ) {
     print qq#$Zip#;
  } else {
     print qq#Unknown Zip#;
  }
  print qq#</p>\n#;

  #&display_Upcoming_Events;

  print qq#<table border=1 class="profile">\n#;
  print qq#<tr valign="top"><td valign="top">\n#;

  print qq#<table border=1 class="profile">\n#;
    print qq#<tr><th nowrap>Primary Contact</th>  <td> $Primary_Contact_Name</td></tr>\n#;
    print qq#<tr><th nowrap>Phone</th> <td>$Business_Phone</td></tr>\n#;
 
    print qq#<tr><th nowrap>Fax</th> <td> $Fax_Number</td></tr>\n#;
  print qq#</table>\n#;
 
  print qq#</td><td valign="top">\n#;
 
  print qq#<table border=1 class="profile">\n#;
 
    print qq#<tr><th nowrap>Communication Pref</th> #;
    print qq#    <td>$Comm_Pref_Out</td></tr>\n#;
   print qq#<tr><th nowrap>Email</th>            <td> $Primary_Contact_Email</td></tr>\n#;
 
	print qq#<tr><th nowrap><br /></th><td><br /></td></tr>\n#;

    print qq#</table>\n#;

  print qq#</td></tr>\n#;
  
  if ($HELPURL !~ /^\s*$/) {
    print qq#<tr><th colspan=2>$nbsp</th></tr>\n#;
    print qq#<tr><th colspan=2>Please <a href="$HELPURL">Click here</a> to request updates/changes</th></tr>\n#;
  }
  
  print qq#</table>\n#;
}

#_______________________________________________________________________________

sub displayPSP_Table {

# my $debug++;

  print qq#<div>\n\n#;
  print qq#<p><a href="/members/psp.cgi">Back to Prescription Savings Program (main)</a></p>\n#;
  print qq#<hr /><br />\n#;


  print qq#<link type="text/css" media="screen" rel="stylesheet" href="/includes/datatables/css/jquery.dataTables.css" /> \n#;
  print qq#<script type="text/javascript" charset="utf-8" src="/includes/datatables/js/jquery.dataTables.min.js"></script> \n#;
  print qq#<script type="text/javascript" charset="utf-8"> \n#;
  print qq#\$(document).ready(function() { \n#;
  print qq#  \$('\#tablef').dataTable( { \n#;
  #print qq#    "sScrollX": "100%", \n#;
  print qq#    "bScrollCollapse": true,  \n#;
  print qq#    "sScrollY": "350px", \n#;
  print qq#    "bPaginate": false \n#;
  print qq#  } ); \n#;
  print qq#} ); \n#;
  print qq#</script> \n#;

  $sql = "
SELECT NDC, Drug, Strength, Formulation, Package_Size, 
       Type_of_coupon_Savings, Details, Limitations, 
       Comments, Helpful_Links
FROM Pharmassess.psp_comprehensivetrial_copaycard_tablewndc
GROUP BY Drug, Type_of_coupon_Savings, Details, Limitations
ORDER BY Drug
";

  (my $sqlout = $sql) =~ s/\n/<br>\n/g;
  print "sql:<br>$sqlout<hr>\n" if ($debug);

  my $closeDB = 0;
  if ( !$dbx ) {
    $closeDB++;
    %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error );
    $dbx = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd, \%attr) || &handle_error;
   
    DBI->trace(1) if ($dbitrace);
  }

  $sthi = $dbx->prepare($sql);
  $sthi->execute();
  my $intsFound = $sthi->rows;

  if ($intsFound > 0) {

#       <th>NDC</th>
    print "<table id=\"tablef\">\n\n";
    print "<thead><tr>
        <th>Drug</th>
        <th>Type of coupon or Savings</th>
        <th>Details</th>
        <th>Limitations & Comments</th>
        </tr></thead>\n";
        print "<tbody>\n";

    while (my @row = $sthi->fetchrow_array()) {
      my ($NDC, $Drug, $Strength, $Formulation, $Package_Size, $Type_of_coupon_Savings, $Details, $Limitations, $Comments, $Helpful_Links) = @row;

      $drug_disp = $Drug;

      if ( $Helpful_Links !~ /^\s*$/ ) {
         if ( $Helpful_Links !~ /^http/i ) {
            $Helpful_Links = "http://".$Helpful_Links;
         }
         $drug_disp = qq#<a href="$Helpful_Links" target="_blank">$drug_disp</a>#;
      }
#     <td>$NDC</td>
      print "
      <tdead><tr>
      <td>$drug_disp</td>
      <td>$Type_of_coupon_Savings</td>
      <td>$Details</td>
      <td>$Limitations<br>$Comments</td>
      </tr></tdead>
      ";
      
    }
    $sthi->finish;
    print "</tbody>\n";
    print "</table>\n\n";
  
    print qq#<br style="clear: both;" /><br />\n#;
    print "<p>*<i>Other requirements may apply.</i></p>\n";

  }
  if ($closeDB > 0) {
    $dbx->disconnect;
  }

  print qq#</div>\n#;

}

#_______________________________________________________________________________

sub printCredInfo {
  my ($Pharmacy_ID, $PROGRAM, $disp_cred, $disp_manage, $alert) = @_;	
  my @path_dirs;
  my @cmea_files;
  my $cmea_path = "\\\\fileprod1\\datashare\\Pharm AssessRBS\\Credentialing";

  #Master source for document links ($dochost)
  #The master will be on pharmassess.com
  $HTTP_HOST = $ENV{'HTTP_HOST'};
  if ($HTTP_HOST =~ /^dev/i) {
    $dochost = "http://dev.pharmassess.com";
  } else {
    $dochost = "https://members.pharmassess.com";
  }
  #------------------------------------------#
  
  print qq#
  <script>
  \$(function() {
    \$( ".expander" ).click(function() {
    
  	  var wasOpen = 0;
  	
  	  if ( \$(this).next('.content').is(":visible") ) {
        wasOpen = 1;
      }
  	
      \$('.content').slideUp();
      \$('.sign').html('+');
  	
      if ( wasOpen > 0 ) {
        //Do Nothing
      } else { 
        \$(this).next('.content').slideDown();
        \$(this).find('.sign').html('>');
      }
  	
    });
    
    \$( ".expander_sub" ).click(function() {
    
      var wasOpen = 0;
  	
      if ( \$(this).next('.content').is(":visible") ) {
        wasOpen = 1;
      }
  	
      \$(this).next('.content').slideUp();
      \$(this).find('.sign').html('+');
  	
      if ( wasOpen > 0 ) {
        //Do Nothing
      } else { 
        \$(this).next('.content').slideDown();
        \$(this).find('.sign').html('>');
      }
  	
    });
    
  });

  function submitform() {
    document.uploaddoc.action= "file_upload.cgi?cred=Y&type=test";
    return true;
  }  
  </script>
  #;

  print qq#<script type="text/javascript" language="javascript" src="/members/js/uploadcontract.js"></script>#;

  print qq#<div id="expander_area">\n\n#;
  print qq#<p>Expand categories below for more information.</p>\n#;
  print qq#<hr />\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Credentialing Profile</h2>\n#;
  print qq#<div class="content expander_category" style="display:$disp_cred">\n#;

  $attestation_complete = 0;
  $notcomplete = 0;

  &printCredEmployees($Pharmacy_ID, $PROGRAM, $dochost, "Color", $disp_manage, $alert);
  $date_yyyymmdd     = &build_date; 
  ($date_yyyymmdd)   = split(/\s+/ , $date_yyyymmdd);
  ($CURYEAR,$mm,$dd) = split(/-/ , $Pharmacy_CMEA_Expiration_Date{$Pharmacy_ID});
#  $CURYEAR -=1;
  $exp = $Pharmacy_CMEA_Expiration_Date{$Pharmacy_ID};

  my $ncpdp = $Pharmacy_NCPDPs{$Pharmacy_ID};
  my $p_name = $Pharmacy_Names{$Pharmacy_ID};
  my $oig_gsa_path = "\\\\pasrvc\\DataShare\\Pharm AssessRBS\\Credentialing\\${pname}_${ncpdp}\\FWA\\OIG_GSA_REPORTS";

  $pharm_dir = "$Pharmacy_Names{$Pharmacy_ID}_$ncpdp";

  @cmea_files = &readfiles("$cmea_path\\$pharm_dir\\CMEA\\$CURYEAR");
  $pharm_cmea = shift(@cmea_files);
#  print "$cmea_path\\$pharm_dir\\CMEA\\$CURYEAR<br>";

  $path = "RBSCredentialing/$pharm_dir/CMEA/$CURYEAR/$pharm_cmea";

  $pp_webpath = qq#/members/WebShare/Policy_and_Procedure/PP_${Pharmacy_ID}_${Pharmacy_NCPDPs{$Pharmacy_ID}}.pdf#;
  $pp_dskpath = "D:/WWW/members.pharmassess.com/members/WebShare/Policy_and_Procedure/PP_${Pharmacy_ID}_${Pharmacy_NCPDPs{$Pharmacy_ID}}.pdf";
  $path_OIGGSA_Reports = "D:/WWW/members.pharmassess.com/members/WebShare/Credentialing/OIG_GSA_REPORTS/$Pharmacy_ID";
  print qq#<table class="tableNoBorder">\n#;
  print qq#<tr><td class="tdNoBorder"><strong>*</strong> - Within 90 Days Of Hire</td></tr># if ($doh_cnt);
  print qq#</table><br />#;

  if ($attestation_complete < 1) {
    print qq#<ul><li>Once all employees are completed and a signed form has been returned you will find a link here to print and sign an attestation form.</li>\n#;
  } else {
    print qq#<ul><li><a href="attestation.cgi" target="_blank">Click here to print attestation form.</a></li>\n#;
  }

   $date_yyyymmdd =~ s/-//g;
   $exp =~ s/-//g;

  if ($exp > $date_yyyymmdd) {
    print qq#<li><a href="$path" target="_blank">Click here to print CMEA Certification form.</a></li># ;
  }
  else {
    print qq#</ul><br />\n# ;
  }

  print qq#<table class='CMEAtable'>\n#;
  print qq#<tr><td class="CMEAtd"><strong>HIPAA</strong> - Health Insurance Portability and Accountability Act</td><td class="CMEAtd"><strong>CMEA</strong> - Combat Methamphetamine Epidemic Act</td></tr>#;
  print qq#<tr><td class="CMEAtd"><strong>FWA</strong> - Fraud, Waste, and Abuse</td></tr>#;
  print qq#<tr><td class="CMEAtd"><strong>COI/COC</strong> - Conflict of Interest / Code of Conduct</td></tr>#;
  print qq#<tr><td class="CMEAtd"><strong>Handbook</strong> - Signed Employee Handbook</td></tr>#;
  print qq#<tr><td class="CMEAtd"> <strong>OIG/GSA</strong> - Office of Inspector General / General Service Administration</td></tr>#;
  print qq#</table>\n#;
  
  print "
  <p style=\"margin-left: 8px; font-size: 10px;\">
  <img src=\"${dochost}/images/fwa/fwa_check32.png\" style=\"width: 16px; vertical-align: middle;\"> - Compliant in this area. | 
  <img src=\"${dochost}/images/fwa/fwa_warn32.png\" style=\"width: 16px; vertical-align: middle;\"> - Compliant, but expiring soon. | 
  <img src=\"${dochost}/images/fwa/fwa_x32.png\" style=\"width: 16px; vertical-align: middle;\"> - Noncompliant. 
  </p>
  ";

  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Upload License/Document</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p>This option can be used in place of e-mailing or faxing renewed licenses, permits or certificates. These documents may still be faxed to (888) 825-4157 or e-mailed to <a href='mailto:rbs\@outcomes.com'>rbs\@outcomes.com</a>.</p>\n#;
		
  print qq#
    <br>
    <form method="post" name="uploaddoc" onSubmit="return submitform();" enctype="multipart/form-data" target="hidden_frame">
      <p>Enter a file to upload:</p>
      <p><input type="file" id="file" name="upfile"> <span style='font-size: 12px'><i>* PDF files only please</i></span></p><br>
      <input type="submit" name="Submit" value="Upload File"><br>
      <span id="msg"></span><br>
      <span style='font-size: 12px'>Please allow up to two business days for the changes to be reflected on the pharmacy profile.</span>
    </form>
    <iframe name='hidden_frame' id="hidden_frame" style='display:none'></iframe>
#;

  print qq#</div>\n#;
  print qq#<div style="clear: both;"></div>#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> HIPAA</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><a href="https://credentialing-tds.bridgeapp.com" target="_blank">Training Program (link)</a></p>\n#;
  print qq#<ul><li>Click above link to login.</li></ul><br />\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/FWA_HIPAA_Compliance_Incident_Report.pdf" target="_blank">FWA/HIPAA Compliance Incident Report (pdf)</a></p>\n#;
  print qq#<ul><li>To report an incident.</li></ul><br />\n#;

  print qq#<h3 class="expander_sub" style="cursor:pointer;"><span class="sign">+</span> HIPAA Required Documents</h3>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;
		
  print qq#<p><a href="${dochost}/downloads/credentialing/HIPAA_Notice_Of_Privacy_Practices.doc" target="_blank">Notice Of Privacy Practices (docx)</a></p>\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/HIPAA_Business_Associate_Contracts.docx" target="_blank">Business Associate Contracts (docx)</a></p>\n#;

  print qq#</div>\n#;
  print qq#<div style="clear: both;"></div>#;

  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Fraud, Waste and Abuse</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><a href="https://credentialing-tds.bridgeapp.com" target="_blank">Training Program (link)</a></p>\n#;
  
  print qq#<h3 class="expander_sub" style="cursor:pointer;"><span class="sign">+</span> FWA Required Documents</h3>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;
  
  print qq#<p><a href="${dochost}/downloads/credentialing/FWA_Code_of_Conduct_and_Conflict_of_Interest.pdf" target="_blank">Code of Conduct and Conflict of Interest (pdf)</a></p>\n#;
  print qq#<ul><li>Must be completed by each employee annually.</li></ul><br />\n#;
		
  print qq#<p><a href="${dochost}/downloads/credentialing/Employee_Acknowledgement_Form.pdf" target="_blank">Employee Acknowledgement Form (pdf)</a></p>\n#;
  print qq#<ul><li>Must be completed by each employee annually.</li></ul><br />\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/FWA_HIPAA_Compliance_Incident_Report.pdf" target="_blank">FWA/HIPAA Compliance Incident Report (pdf)</a></p>\n#;
  print qq#<ul><li>To report an incident.</li></ul><br />\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/FWA_Report_Fraud_Contact_Employee.pdf" target="_blank">Report Fraud Contact (Employee) (pdf)</a></p>\n#;
  print qq#<ul><li>Must be displayed with Employee Notices for all employees to reference.</li></ul><br />\n#;
  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<a href="http://www.hhs.gov/ocr/privacy/hipaa/administrative/breachnotificationrule/brinstruction.html" target="_blank">FWA Breach (link)</a>\n#;
  print qq#<ul><li>Report breach to Secretary.</li></ul>\n#;

  #print qq#<a href="https://www.federalregister.gov/health-and-public-welfare" target="_blank">Federal Register (link)</a>\n#;
  #print qq#<ul><li>Link to Federal Register.</li></ul><br />\n#;

  print qq#<hr />#;
  print qq#</div>\n#;

  opendir(DIR, $path_OIGGSA_Reports);
  @files = readdir(DIR);
  @files = reverse sort @files;
  foreach $file (@files) {
    $fcnt++;
    last if($fcnt) > 24;
    # Use a regular expression to ignore files beginning with a period
    next if ($file !~ /.xlsx$/);
    $printfile = $file;
    ($pt1,$pt2,$pt3,$pt4,$pt5,$pt6) = split(_,$printfile);
    if ($pt6 =~ /\./) {
      ($tmp,$tmp2) = split (/\./,$pt6);
      $pt6 = $tmp;
    }
    $date = $pt6;
    @a = $date =~ /(.{4})(.*)/s;
    @a2 = $a[1] =~ /(.{2})(.*)/s;
    $y = $a[0];
    $m = $a2[0];
    $d = $a2[1];

    $printfile = "$m-$d-$y OIG&GSA Verification";
    if ($fcnt < 4) {
       $top .= "<a href=\"${dochost}/members/WebShare/Credentialing/OIG_GSA_REPORTS/$Pharmacy_ID/$file\" target=\"_blank\">$printfile</a><br>\n";
    }
    else {
       $bottom .= "<a href=\"${dochost}/members/WebShare/Credentialing/OIG_GSA_REPORTS/$Pharmacy_ID/$file\" target=\"_blank\">$printfile</a><br>\n";
    }
  }
  closedir(DIR);
  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Monthly OIG & GSA Reports</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;
    print qq#$top\n#;
    print qq#<h3 class="expander_sub" style="cursor:pointer;"><span class="sign">+</span> Past OIG & GSA Reports</h3>\n#;
    print qq#<div class="content expander_category" style="display:none">\n#;
      print qq#$bottom\n#;
    print qq#</div>\n#;
  print qq#</div>\n#;

  if (-e $pp_dskpath) {
    print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Pharmacy & Employee Policy & Procedure Manual</h2>\n#;
    print qq#<div class="content expander_category" style="display:none">\n#;

    print qq#<p><a href="$pp_webpath" target="_blank">Policy & Procedure Manual (pdf)</a></p>\n#;
    print qq#<ul><li>To keep up to date on pharmacy policies and procedures.</li></ul><br />\n#;

    print qq#<hr />#;
    print qq#</div>\n#;
  }

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> USP 800</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><strong>USP 800 Template Policy & Procedure</strong></p>
           <p>Compliance with USP 800 will require ongoing attention by the pharmacy staying up to date with recent criteria released by OSHA. You will also want to work closely with your State Board of Pharmacy to ensure you are meeting any requirements they may have. Below you will find a link to a template policy and procedure document to assist in documenting how you are handling your compliance with this regulation.</p>\n#;
  print qq#<p><a href="/downloads/USP_800_Template_P&P.pdf" target="_blank"> Template USP 800 Policy & Procedure (pdf)</a></p>\n#;

  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Continuous Quality Improvement</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/CQI_Medication_Incident_Doc.pdf" target="_blank">Medication Incident Report (pdf)</a></p>\n#;
  print qq#<ul><li>To report an incident.</li></ul><br />\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/CQI_Self_Monitoring_of_Process_Errors.pdf" target="_blank">Self-Monitoring of Process Errors (pdf)</a></p>\n#;
  print qq#<ul><li>To monitor employee errors.</li></ul><br />\n#;
	
  print qq#<p><a href="${dochost}/downloads/credentialing/CQI_Meeting_Agenda.docx" target="_blank">Meeting Agenda (docx)</a></p>\n#;

  print qq#<p><a href="${dochost}/downloads/credentialing/CQI_Sample_Agenda.pdf" target="_blank">Sample Meeting Agenda (pdf)</a></p>\n#;

  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> CMEA </h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><a href="https://www.deadiversion.usdoj.gov/meth/trg_retail_081106.pdf" target="_blank">
  Training Material (link)
  </a></p>\n#;
  print qq#<ul><li>Click above link to access required training material.</li></ul><br />\n#;

  print qq#<p><a href="https://apps.deadiversion.usdoj.gov/webforms/jsp/cmea/forms/menu.jsp" target="_blank">
  Certification (link)
  </a></p>\n#;
  print qq#<ul><li>Click above link to certify your pharmacy.</li></ul><br />\n#;

  print qq#<hr />#;
  print qq#</div>\n#;

  print qq#<h2 class="expander" style="cursor:pointer;"><span class="sign">+</span> Helpful Links</h2>\n#;
  print qq#<div class="content expander_category" style="display:none">\n#;

  print qq#<p><a href="http://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Chapter9.pdf" target="_blank">
  CMS.gov Prescription Drug Benefit Manual (pdf)
  </a></p>\n#;
  print qq#<ul><li>Chapter 9 Compliance Program Guidelines.</li></ul><br />\n#;
	
  print qq#<p><a href="https://www.federalregister.gov" target="_blank">
  Federal Register Health and Human Services (link)
  </a></p>\n#;
  print qq#<ul><li>Enter Search term to find most recent rules affecting Medicare Training Programs.</li></ul><br />\n#;
	
  print qq#<p><a href="http://oig.hhs.gov/exclusions/" target="_blank">
  Office of Inspector General (OIG) Exclusion List (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.sam.gov" target="_blank">
  General Services Administration (GSA) Exclusion List (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.hhs.gov/ocr/privacy/index.html" target="_blank">
  Health Information Privacy (link)
  </a></p>\n#;

  print qq#<p><a href="https://oig.hhs.gov/fraud/report-fraud/index.asp" target="_blank">
  Reporting Fraud Resources (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.ahrq.gov/professionals/quality-patient-safety/index.html" target="_blank">
  Agency of Healthcare Research and Quality (Quality and Patient Safety) (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.fda.gov" target="_blank">
  FDA Medwatch (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.ismp.org" target="_blank">
  Institute for Safe Medication Practices (link)
  </a></p>\n#;

  print qq#<p><a href="http://www.fda.gov" target="_blank">
  Voluntarily Reporting of Adverse Medication Events; Potential or Actual Product Errors (link)
  </a></p>\n#;
	
  print qq#<hr />#;

  print qq#</div>\n#;
  
  print qq#</div> <!-- end expander_area -->\n#;
}

#_______________________________________________________________________________

sub printCredEmployees {
  my ($Pharmacy_ID, $PROGRAM, $DOCHOST, $COLORMODE, $disp_cred, $alert) = @_;
  
  my $DBNAME = '';
  my $TABLE  = '';
  my $NCPDP;

  if ($PROGRAM =~ /QCP/i) {
    $DBNAME = "qcp";
    $NCPDP = $Clinic_NCPDPs{$Pharmacy_ID};
  } else { 
    $DBNAME = "pharmassess";
    $NCPDP = $Pharmacy_NCPDPs{$Pharmacy_ID};
  }

  if ($PROGRAM =~ /company/i) {
    $TABLE = 'credentialing_employees_company';
	$Entity_ID_field = 'Company_ID';
  } else {
    $TABLE = 'credentialing_employees';
	$Entity_ID_field = 'NCPDP';
  }
  
  $color = '';
  if ($COLORMODE =~ /BW/i) {
    $color = "_bw";
  }

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT id, fname, lname, title, fwa_c, fwa_m, hipaa_exp, coi_coc, handbook, oig_gsa, license,
                    (DATEDIFF(CURDATE(), exp_date) ) AS 'LicAge', (DATEDIFF(CURDATE(), date_hired) ) AS 'DOH', oig_gsa_match, exp_date, date_hired
               FROM $DBNAME.$TABLE
              WHERE $Entity_ID_field = $NCPDP && status = 'Active'
	   ORDER BY lname ASC";

  my $employees  = $dbm->prepare("$sql");
  $employees->execute;

  my $NumOfRows = $employees->rows;

  if ($NumOfRows > 0) {

  $today = $syear.$smonth.$sday;

  print "
  <style> 
  .center { text-align: center; } 
  .credEmployees table, .credEmployees td, .credEmployees th { vertical-align: middle; border: 0px; }
  .credEmployees th { border-bottom: 1px solid #000; margin: 0px; }
  </style>";

  print '<link rel="stylesheet" href="https://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />';
  print '<script src="https://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>';
  print '<script src="/includes/jquery.maskedinput.min.js" type="text/javascript"></script>';

#  print "<button style='float:right;' id='edit' type='button' class='button-form-small' onClick='edit_employees()'>Edit</button>";

  print qq#<span style="color: green; font-size: 12px;">$alert</span>\n#;
  print qq#<table class="credEmployees">\n#;
  print "<tr>
  <th><button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='add_employee()'>Add</button></th>
  <th style=\"min-width: 130px; text-align: left;\">Name</th>
  <th style=\"min-width: 130px; text-align: left;\">Title</th>
  <th width=\"160px\" class=\"center\">FWA</th>
  <th width=\"85px\" class=\"center\">HIPAA</th>
  <th width=\"85px\" class=\"center\">COI/COC</th>
  <th width=\"85px\" class=\"center\">Handbook</th>
  <th width=\"85px\" class=\"center\">OIG/GSA</th>
  </tr>\n";

  while ( my @row = $employees->fetchrow_array() ) {
     my ($emp_id, $fname, $lname, $title, $fwa_c, $fwa_m, $hipaa, $coi_coc, $handbook, $oig_gsa, $license, $LicAge, $doh, $oig_gsa_match, $exp_date, $date_hired) = @row;
         $doh = '100' if (!$doh);
	 
 	 my @datepcs = split('-', $fwa_c);
	 $fwa_c = $datepcs[0];
	 
	 my @datepcs = split('-', $fwa_m);
	 $fwa_m = $datepcs[0];
	 
	 my @datepcs = split('-', $hipaa);
	 $hipaa_exp = $datepcs[0];

	 my @datepcs = split('-', $coi_coc);
         $coi_coc = $datepcs[0];
	 
	 my @datepcs = split('-', $handbook);
         $handbook = $datepcs[0];

	 my @datepcs = split('-', $oig_gsa);
	 my $dt1 = DateTime->new (
			   year => $datepcs[0],
			   month => $datepcs[1],
			   day => $datepcs[2]
			   );
	$dt1->add(days => 40);
	$oig_gsa = $dt1->ymd('') if (!$oig_gsa_match);	

        if ($hipaa < $syear) { 
	  $img_hipaa = "${dochost}/images/fwa/fwa_x32${color}.png";
	  $notcomplete++;
        } else { 
	  $img_hipaa = "${dochost}/images/fwa/fwa_check32${color}.png";
        }
	 
        if ($fwa_c < $syear) { 
          $img_fwa_c = "${dochost}/images/fwa/fwa_x32${color}.png";
          $notcomplete++;
        } else { 
          $img_fwa_c = "${dochost}/images/fwa/fwa_check32${color}.png";
        }
	 
        if ($fwa_m < $syear) { 
          $img_fwa_m = "${dochost}/images/fwa/fwa_x32${color}.png";
          $notcomplete++;
        } else { 
          $img_fwa_m = "${dochost}/images/fwa/fwa_check32${color}.png";
        }

	 if ($coi_coc < $syear) { 
	   $img_coi_coc = "${dochost}/images/fwa/fwa_x32${color}.png";
	   $notcomplete++;
	 } else { 
	   $img_coi_coc = "${dochost}/images/fwa/fwa_check32${color}.png";
	 }

	 if ($handbook < $syear) { 
	   $img_handbook = "${dochost}/images/fwa/fwa_x32${color}.png";
	   $notcomplete++;
	 } else { 
	   $img_handbook = "${dochost}/images/fwa/fwa_check32${color}.png";
	 }
	 
	 
	 if ($oig_gsa > $today) { 
	   $img_oig_gsa = "${dochost}/images/fwa/fwa_check32${color}.png";
	 } else { 
	   $img_oig_gsa = "${dochost}/images/fwa/fwa_x32${color}.png";
	   $notcomplete++;
	 }

     my $bgcolorbeg = "";
     if ( $LicAge < -60 || $LicAge =~ /^\s*$/ ) {
     } elsif ( $LicAge < 0 ) { 
        $bgcolorbeg = qq#class="yellow"#;
     } else { 
        $bgcolorbeg = qq#class="red"#;
     } 

     $doh90 = '';

     if ( $doh <= 90  ) {
       $doh90 = '*';
       $doh_cnt++;
     }
     $match = ''; 
     $match = '<td class="match">MATCH</td>' if ($oig_gsa_match);
		
     print "<tr>
         <td><button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='manage_employee(\"$fname\", \"$lname\", \"$title\", \"$license\", \"$exp_date\", \"$date_hired\", \"$emp_id\")'>Manage</button></td>
	 <td $bgcolorbeg> $lname, $fname $doh90</td>
	 <td>$title</td>
	 <td class=\"center\">C: <img src=\"$img_fwa_c\" style=\"vertical-align: middle;\" /> M: <img src=\"$img_fwa_m\" style=\"vertical-align: middle;\" /></td>
	 <td class=\"center\"><img src=\"$img_hipaa\" /></td>	 
	 <td class=\"center\"><img src=\"$img_coi_coc\" /></td>
	 <td class=\"center\"><img src=\"$img_handbook\" /></td>
	 <td class=\"center\"><img src=\"$img_oig_gsa\" /></td>
	 $match
	 </tr>";
  }
     print "<tr>";

     if ( $COLORMODE =~ /BW/i) {
       print "<td></td>";
     }
     else {
       print "<td><button type='button' class='button-form-small' onClick='edit_employees()'>Edit</button> <button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='add_employee()'>Add</button></td>";
     }

       print "<td></td>
    	      <td></td>
	      <td></td>
	      <td></td>
	      <td></td>
	      <td colspan='2'>
                <form id='form' action='credentialing.cgi' method='post'>
                  <input type='hidden' name='action' value='Save'>
	          <button style='display: $disp_cred' id='save_changes' type='button' class='button-form-small manage' onClick='this.form.submit();'>Save Changes</button> <button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='cancel_button()'>Cancel</button>
	        </form>
  	      </td>  
            </tr>";
  print "</table><br />";

  print <<BM;
    <script>
	\$(function() {
	  \$( ".datepicker" ).datepicker({ dateFormat: "yy-mm-dd" });
	  \$( "#anim" ).change(function() {
	  \$( ".datepicker" ).datepicker( "option", "dateFormat", "yy-mm-dd" );
	});

	  \$("#fadeout").animate({top:'30px'});
	  jQuery("#fadeout").delay(3500).fadeOut("slow");

	  jQuery(function(\$){
	    \$(".datepicker").mask("9999-99-99");
	  });
	});

      function isValidDate(ExpiryDate) { 
        var objDate,  // date object initialized from the ExpiryDate string 
        mSeconds,  
        day,       
        month,     
        year;      

	if (ExpiryDate.length !== 10) { 
          return false; 
        } 
        if (ExpiryDate.substring(4, 5) !== '-' || ExpiryDate.substring(7, 8) !== '-') { 
          return false; 
        } 

        month = ExpiryDate.substring(5, 7) - 1;  
        day   = ExpiryDate.substring(8, 10) - 0; 
        year  = ExpiryDate.substring(0, 4) - 0; 
    
        if (year < 1900 || year > 2050) { 
          return false; 
        } 

        mSeconds = (new Date(year, month, day)).getTime(); 

        objDate = new Date(); 
        objDate.setTime(mSeconds); 

        if (objDate.getFullYear() !== year || 
          objDate.getMonth() !== month || 
          objDate.getDate() !== day) { 
          return false; 
        } 
        return true; 
      }

        function checkinfo(){
          var thisform = 'form1';
	  var message = '';
	  var doc = document.forms[thisform];

	  if(doc["fname"].value == '') {
            message = "First Name is required<br>";
	  }
	  if(doc["lname"].value == '') {
            message = message + "Last Name is required<br>";  
	  }
	  if(doc["title"].value == '') {
            message = message + "Title is required<br>";
	  }
          if(!(isValidDate(doc["date_hired"].value))) {
            message = message + "Invalid Date Of Hire<br>";  
	  }
          if((!isValidDate(doc["license_exp"].value)) && doc["license_exp"].value != '') {
            message = message + "Invalid License Date<br>";  
	  }

	  if(message == ''){
	    return true;
	  }	   
	  else {
	    alert(message);
	    return false; 
	  }
        }

        function authinfo(){
          var thisform = 'mev_form';
	  var message = '';
	  var doc = document.forms[thisform];

	  if(doc["auth_name"].value == '') {
            message = "Authorizing Name is required<br>";
	  }

	  if(message == ''){
	    return true;
	  }	   
	  else {
	    alert(message);
	    return false; 
	  }
	}

        function edit_employees() {
	 var buttons=document.getElementsByClassName('manage');

         for (var i=0; i<buttons.length;i++){
           buttons[i].style.display='inline-block';
          }
	}

	function cancel_button() {
	 var buttons=document.getElementsByClassName('manage');

         for (var i=0; i<buttons.length;i++){
           buttons[i].style.display='none';
          }
	}

      function manage_employee(fname, lname, title, license, exp_date, date_hired, emp_id) {
        \$("#fname").val(fname);
        \$("#lname").val(lname);
        \$("#title").val(title);
        \$("#license").val(license);
        \$("#license_exp").val(exp_date);
        \$("#date_hired").val(date_hired);
        \$("#action").val('Update');
        \$("#emp_id").val(emp_id);
        \$("#disp_name").val(fname + ' ' + lname);
        \$("#disp_title").val(title);
        \$("#dialog-form1").dialog("open");	
      }

      function add_employee() {
        \$("#fname").val('');
        \$("#lname").val('');
        \$("#title").val('');
        \$("#license").val('');
        \$("#license_exp").val('');
        \$("#date_hired").val('');
        \$("#action").val('Add');
        \$("#dialog-form1").dialog("open");	
      }

      function term_employee() {
        if (window.confirm("Term " + \$("#fname").val() + ' ' + \$("#lname").val() + '?')) {
          \$("#action").val('Term');
	  \$('#form1').submit();
	}
      }

      function mev_auth() {
        var x = document.getElementById("save_changes");
        if (window.getComputedStyle(x).display === "none") {
          \$("#dialog-form2").dialog("open");	
	}
        else {
          alert('Please click <Save Changes> before proceeding.');
        } 
      }

      \$(function() {
        \$( "#dialog-form1" ).dialog({
		autoOpen: false,
		height: 290,
		width: 600,
		modal: true,
		buttons: {
			"Complete": function() {
                                      var tf  = checkinfo();
					if(tf) {
					  \$('#form1').submit();
					}
				},
			Cancel: function() {
					\$( this ).dialog( "close" );
				}
			},
			close: function() {
				
			}
		});
      });

      \$(function() {
        \$( "#dialog-form2" ).dialog({
		autoOpen: false,
		height: 200,
		width: 400,
		modal: true,
		buttons: {
			"Confirm": function() {
                                      var tf  = authinfo();
                                        if(tf) {
					  \$('#mev_form').submit();
					}
				},
			Cancel: function() {
					\$( this ).dialog( "close" );
				}
			},
			close: function() {
				
			}
		});
      });
  </script>

    <div id="dialog-form1" title="Manage Employee" style="display: none;">
      <form id="form1" action="credentialing.cgi" method="post">
        <input type="hidden" id="action" name="action" value="">
        <input type="hidden" id="emp_id" name="emp_id" value="">
        <input type="hidden" id="disp_name" name="disp_name" value="">
        <input type="hidden" id="disp_title" name="disp_title" value="">
        <table class="tableNoBorder">
	  <tr>
	    <td class="tdNoBorder">
	      <label for="fname">First Name</label>
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="fname" id="fname" value="" class="text ui-corner-all"><br />
	    </td>
	  </tr>
	  <tr>
	    <td class="tdNoBorder">
	      <label for="lname">Last Name</label>
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="lname" id="lname" value="" class="text ui-corner-all"><br />
	    </td>
          </tr>
	  <tr>
	    <td class="tdNoBorder">
	      <label for="title">Title</label>
            </td>
	    <td class="tdNoBorder">
	      <select name="title" id="title" class="cipn-dropdown-form required">
BM

   $sql_titles = "SELECT Vals 
                    FROM officedb.opts 
                   WHERE OPTS_ID = 3000 #Job Titles
                ORDER BY Vals ASC";

   my $titles  = $dbm->prepare("$sql_titles");
   $titles->execute;

   while ( my ($rec) = $titles->fetchrow_array() ) {
     @vals = split(/,\s+/, $rec);

     foreach (@vals) {
       print "<option value=\"$_\">$_</option>\n";
     }
   }
   
   $titles->finish();

  print <<BM;   
              </select>
	    </td>
	  </tr>
          <tr>
	    <td class="tdNoBorder">
	      <label for="license">License</label><br />
	    </td>
	    <td class="tdNoBorder">
              <input type="text" name="license" id="license" value="" class="text ui-corner-all" style="width: 150px;">
	    </td>	
	    <td class="tdNoBorder">
	      <label for="license_exp">Expiration</label><br />
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="license_exp" id="license_exp" value="" placeholder="yyyy-mm-dd" class="datepicker datebox required text ui-corner-all" style="width: 150px;">
	    </td>	
	  </tr>
          <tr>
	    <td class="tdNoBorder">
	      <label for="date_hired">Date Of Hire</label><br />
	    </td>
	    <td class="tdNoBorder">
	      <INPUT class="datepicker datebox required ui-corner-all" ID="date_hired" TYPE="text" NAME="date_hired" VALUE="" placeholder="yyyy-mm-dd">
	    </td>	
	  </tr>
	</table>
	<div style="float: right">
	  <button id='term' type='button' class='button-form-small' style="color: red" onClick='term_employee()'>Term Employee</button>
	</div>
      </form>
    </div>

    <div id="dialog-form2" title="Monthly Employee Verification" style="display: none;">
      <form id="mev_form" action="credentialing.cgi" method="post">
        <input type="hidden" name="mev_conf" value="Y">
	<p>I hereby confirm and attest that the employees and their names listed in the Credentialing Profile are accurate as of today.</p>
        <label for="auth_name">Authorized Name:</label>
        <input type="text" name="auth_name" id="auth_name" value="" class="text ui-widget-content ui-corner-all"><br />
      </form>
    </div>
BM

  } else {
     $notcomplete++;
     print "<span>No employees have been entered yet.</span><br /><br />";
  }
  $employees->finish;
  $dbm->disconnect;

     if ( $COLORMODE !~ /BW/i) {
       print "<div style='text-align:center;'><button style='border-radius: 8px; font-size:16px;' type='button' class='button-form-small' onClick='mev_auth()'>Monthly Employee Verification</button></div>";
     }
  
  #Attestation
  if ($notcomplete == 0) {
    $attestation_complete = 1;
  } else {
    $attestation_complete = 0;
  }
}

#_______________________________________________________________________________	 

sub printCredAttestationHeader {

  #Master source for document/image links ($dochost)
  #The master will be on pharmassess.com
  $HTTP_HOST = $ENV{'HTTP_HOST'};
  if ($HTTP_HOST =~ /^dev/i) {
    $dochost = "http://dev.pharmassess.com";
  } else {
    $dochost = "http://members.pharmassess.com";
  }

print <<BM;

<!doctype html>
<html>
<head>

<link rel="stylesheet" type="text/css" media="screen" href="${dochost}/css/reports_weekly.css" />
<link rel="stylesheet" type="text/css" media="print"  href="${dochost}/css/reports_weekly_print.css" />

<title>Pharm AssessRBS Attestation Form</title>

</head>

<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

BM

}

#_______________________________________________________________________________

sub printCredAttestation {

  my ($Pharmacy_ID, $PROGRAM) = @_;
  
  if (!$dochost) {
    #LIKELY ALREADY SET BY &printCredAttestationHeader
    #Master source for document/image links ($dochost)
    #The master will be on pharmassess.com
    $HTTP_HOST = $ENV{'HTTP_HOST'};
    if ($HTTP_HOST =~ /^dev/i) {
      $dochost = "http://dev.pharmassess.com";
    } else {
      $dochost = "http://members.pharmassess.com";
    }
  }
  
  my $Store_Name = '';
  if ($PROGRAM =~ /QCP/i) {
    $Store_Name = $Clinic_Names{$Pharmacy_ID}  
  } else { 
    $Store_Name = $Pharmacy_Names{$Pharmacy_ID};
  }
  
  print qq#<br>\n#;
  print qq#<div style="margin: 0 auto 0; width: 800px;">\n#;
  print qq#<table class="header"><tr>\n#;
  print qq#<td width="350px"><img src="${dochost}/images/pa_rbs_logo_bw.jpg"></td>\n#;
  print qq#<td><h2>Attestation Form</h2>\n#;
  
  if ($Store_Name !~ /^\s*$/) {
    print qq#for $Store_Name</td>\n#;
  }
  
  print qq#</tr></table>\n#;
  print qq#<br>\n#;
  
  &printCredEmployees($Pharmacy_ID, $PROGRAM, $dochost, "BW", "none", "");
  
  print qq#<p>I acknowledge that the pharmacy has completed a qualified Fraud, Waste and Abuse Program and HIPAA Training Program as stated in the Pharmacy Policy and Procedure Manual. All pharmacy employees have completed these training programs and are recertified annually to ensure continued compliance with all applicable laws.</p>\n#;
  
  print qq#<table style="width: 100%;">\n#;
  print qq#<tr><td>___________________________________________</td><td>_________________</td></tr>\n#;
  print qq#<tr><td>Pharmacy Owner/Compliance Officer Signature</td><td>Date</td></tr>\n#;
  print qq#</table>\n#;
  print qq#<br /><br />\n#;
  
  print qq#</body>\n#;
  print qq#</html>\n#;

}

#_______________________________________________________________________________

sub printPSPInfo {

  my ($NCPDP, $PROGRAM) = @_;

  #Master source for document links ($dochost)
  #The master will be on pharmassess.com
  $HTTP_HOST = $ENV{'HTTP_HOST'};
  if ($HTTP_HOST =~ /^dev/i) {
    $dochost = "http://dev.pharmassess.com";
  } else {
    $dochost = "http://members.pharmassess.com";
  }
  #------------------------------------------#

  print qq#
  <script>
  \$(function() {
    \$( ".expander" ).click(function() {
    
  	var wasOpen = 0;
  	
  	if ( \$(this).next('.content').is(":visible") ) {
        wasOpen = 1;
  	}
  	
  	\$('.content').slideUp();
  	\$('.sign').html('+');
  	
  	if ( wasOpen > 0 ) {
  	  //Do Nothing
  	} else { 
  	  \$(this).next('.content').slideDown();
  	  \$(this).find('.sign').html('>');
  	}
  	
    });
  });
  </script>
  #;
  
  print qq#<div id="expander_area">\n\n#;
  print qq#<p>Expand categories below for more information.</p>\n#;
  print qq#<hr />\n#;
  
  #----------------------------------------------------------------------------------------------------#
  print qq#<h2 id="expanderHead3" class="expander" style="cursor:pointer;"><span id="expanderSign3" class="sign">></span> Prescription Savings Program Coupon Links</h2>\n#;
  print qq#<div class="content credentialing_category" >\n#;
  
    print qq#<p><a href="psp_table.cgi">Comprehensive Trial/Copay Card Table</a></p>\n#;
    print qq#<p><a href="${dochost}/members/WebShare/Prescription_Savings_Program/Drugs_with_Copay_Cards.pdf" target="_blank">Drugs with Copay Cards (PDF)</a></p>\n#;
    print qq#<p><a href="${dochost}/members/WebShare/Prescription_Savings_Program/Drugs_with_Trial_Cards.pdf" target="_blank">Drugs with Trial Cards (PDF)</a></p>\n#;
  
  print qq#<hr />#;
  print qq#</div>\n#;
  #----------------------------------------------------------------------------------------------------#
  
  #----------------------------------------------------------------------------------------------------#
  print qq#<h2 class="expander" style="cursor:pointer;"><span id="expanderSign4" class="sign">+</span> Patient Marketing Material</h2>\n#;
  print qq#<div class="content credentialing_category" style="display:none">\n#;
  
    print qq#<p>Place this marketing flyer in your pharmacy's window or on your countertop.  If you are in need of marketing assistance for this program in any other form, we would be glad to recommend other content for your pharmacy's website or Facebook page upon request.</p>\n#;
    
    print qq#<p><a href="${dochost}/members/WebShare/Prescription_Savings_Program/PSP_Patient_Marketing_Flyer.pdf" target="_blank">Patient Marketing Flyer (PDF)</a></p>\n#;
  
  print qq#<hr />#;
  print qq#</div>\n#;
  #----------------------------------------------------------------------------------------------------#
  
  #----------------------------------------------------------------------------------------------------#
  print qq#<h2 class="expander" style="cursor:pointer;"><span id="expanderSign1" class="sign">+</span> What is the Prescription Savings Program?</h2>\n#;
  print qq#<div class="content credentialing_category" style="display:none">\n#;
  
    print qq#
    <p>This program will provide your pharmacy with a comprehensive table including: brand name medications with available manufacturer trial/copay cards, links to the online trial/copay cards, the amount of savings available to the patient, the amount of time the card is active, and the card's specific limitations or requirements. Using our Comprehensive trial/copay card table and the implementation plan, your pharmacy staff will be able to quickly access and apply the necessary trial or copay card to patient's brand name medications.</p>
    \n#;
  
  print qq#<hr />#;
  print qq#</div>\n#;
  #----------------------------------------------------------------------------------------------------#
  
  #----------------------------------------------------------------------------------------------------#
  print qq#<h2 class="expander" style="cursor:pointer;"><span id="expanderSign2" class="sign">+</span> How to implement the program </h2>\n#;
  print qq#<div class="content credentialing_category" style="display:none">\n#;
  
    print qq#<p>We believe that the most effective way to implement this program into your pharmacy workflow is by a sticker system. Use the Quick Reference Trial/Copay Card List and walk your shelves to mark and distinguish which brand name medications have trial cards and/or copay cards available. Once the stickers are in place, the employee pulling the medication to fill a prescription will be able to immediately recognize which medication has a trial/copay card available. At that point, the employee can either sign up the patient for a trial/copay card or apply the copay card already on file for the patient in a timely manner without disrupting the work flow.</p>\n#;
  
##    print qq#<p>Please complete the Prescription Savings Program enrollment form to receive all of the materials your pharmacy will need to implement the program.  You may also contact Pharm Assess via phone at (888) 255-6526 or email at <a href="mailto:RBS\@tdsclinical.com">RBS\@tdsclinical.com</a> with any questions.</p>\n#;
  
    print qq#<p><a href="${dochost}/members/WebShare/Prescription_Savings_Program/PSP_StepbyStep_ImplementationPlan.pdf" target="_new">Step by Step Implementation Plan (document)</a></p>\n#;
  
  print qq#<hr />#;
  print qq#</div>\n#;
##  #----------------------------------------------------------------------------------------------------#
##  print qq#<h2 class="expander" style="cursor:pointer;"><span id="expanderSign5" class="sign">+</span> Enrollment Information</h2>\n#;
##  print qq#<div class="content credentialing_category" style="display:none;">\n#;
##  
##    print qq#<p><a href="${dochost}/members/WebShare/Prescription_Savings_Program/PSP_Enrollment_Form.pdf" target="_blank">Prescription Savings Program Enrollment Form (PDF)</a></p>\n#;
##    print qq#<p>Once your pharmacy has completed the enrollment form you will receive your Prescription Savings Program Welcome Packet via mail. </p>\n#;
##    print qq#<p>If you are in need of additional Prescription Savings Program stickers please contact Pharm AssessRBS via phone at (888) 255-6526 or email at <a href="mailto:RBS\@tdsclinical.com">RBS\@tdsclinical.com</a>. </p>\n#;
##    print qq#<p>Note:   The welcome packet will include a brief letter, a print out of the 2 Lists to walk the shelves (or the quick reference list which will be color coded), the stickers, a step by step implementation plan and the patient marketing flyer.</p>\n#;
  
##  print qq#<hr />#;  
##  print qq#</div>\n#;
  #----------------------------------------------------------------------------------------------------#
  
  print qq#</div>\n#;
  
}

#_______________________________________________________________________________

sub displayInterventionsGlobal {
  my ($Entity_ID, $intPROGRAM) = @_;
  
  #Display Active first, then Closed
  #Only show Closed within 30 days
  #Show oldest main intervention on top, but newest first on updates under it
  #Add a search feature
  #Add a "Skip to closed" feature
  #Localize CSS
  #Localize data calls

  print qq#<div class="all_interventions"> <!-- displayInterventions -->\n#;
  
  #Embedded styles required for global interventions.
  print qq#
  <style>
  
  /* Interventions */
  
  .int_block {
    margin: 0 0 15px 0;
  }
  
  .int_pri {
    position: relative;
    width: 750px;
    margin: 0px;
    padding: 0px;
    border: 1px solid \#777;
    border-radius: 10px 10px 10px 10px;
  }
  .int_header {
    position: relative;
    padding: 3px;
    border-radius: 9px 9px 0 0;
  }
  .int_header_open {
    background: \#5FC8ED;
    color: \#FFFFFF;
  }
  .int_header_closed {
    background: \#133562;
    color: \#FFFFFF;
  }
  .int_comments {
    position: relative;
    padding: 5px;
  }
  .int_category {
    float: right; 
	font-size: 10px; 
	color: \#777; 
	padding: 0 6px 2px 0;
  }
  
  .int_update {
    position: relative;
    width: 710px;
    margin: 0 0 0 30px;
    padding: 0px;
    border-right: 1px solid \#DDD;
    border-left: 1px solid \#DDD;
    border-bottom: 1px solid \#DDD;
  }
  .int_update_header {
    position: relative;
    background: \#f2f2f2;
    padding: 3px;
    font-size: 11px;
  }
  .int_update_comments {
    position: relative;
    padding: 5px 5px 5px 15px;
  }
  \#search {
    height:25px;
    margin-top: 5px;
    margin-right: 5px;
    padding-left: 5px;
  }  
  
  </style>
  #;
  
  #Embedded jQuery/javascript required for global interventions
  print qq#
  <script>
  \$(function(){
	
    \$( ".all_interventions" ).on( "click", ".toggle_comments", function() {
      \$(this).parent("div").find(".int_update").show();
	  \$(this).hide();
    });
	
  });
  
  \$(function(){
  
    var orig = 0;
	var saveText = [];
	
	var foundCount = 0;
  
    \$( "\#search" ).keyup(function() {
	
	  foundCount = 0;
	
	  var searchString = \$(this).val();
	  
      var i = 0;
	  var intNum = 1;
      while (i === 0) {
	  
	    var intDiv = \$('\#intNum'+intNum);
	   		
		if (orig === 0) {
		  saveText[intNum] = intDiv.html();
		} else {
		  intDiv.html(saveText[intNum]);
		}
		
		var searchText = intDiv.html();

		if (searchString.length > 2) {
		
		  if (
		    intDiv.find('.int_header').text().toLowerCase().indexOf(searchString.toLowerCase()) >= 0 || 
			intDiv.find('.int_comments').text().toLowerCase().indexOf(searchString.toLowerCase()) >= 0 || 
			intDiv.find('.int_update_header').text().toLowerCase().indexOf(searchString.toLowerCase()) >= 0 || 
			intDiv.find('.int_update_comments').text().toLowerCase().indexOf(searchString.toLowerCase()) >= 0
		  ) {
		
		    if (/^int\$|^div\$|^span\$|^tabl\$|^clas\$/i.test(searchString.toLowerCase())) {
		      //don't do anything
		    } else {
			  var regex = new RegExp('('+searchString+')', 'gi');
			  
			  //if (intDiv.text().match()) {
			    var newhtml = searchText.replace(regex, "<span style='background: \#FF0;'>\$1</span>"); 
		        intDiv.html(newhtml);
				foundCount += 1;
			  //}
			  
		      intDiv.show();
		    }
		  
		  } else {
		
		    intDiv.fadeOut();
		  
		  }
		  
		} else {
		  intDiv.fadeIn();
		}
	    
	    intNum += 1;
	  
	    if (\$('\#intNum'+intNum).length == 0) {
	      i = 1;
	    }
		
	  }
	  
	  orig += 1;
	  
	  if (searchString.length > 2) {
	    \$('\#foundCount').text(foundCount);
	    \$('\#found').show();
	  } else {
	    \$('\#found').hide();
	  }
	  
    });
  
  }); 
  </script>
  #;

  my $intNum = 0;
  my $activeCount = 0;
  my $closedCount = 0;
  
  if ($intPROGRAM =~ /RBS/i || $intPROGRAM =~ /^\s*$/) {
    $sql_whereProgram = ''
  } else {
    $sql_whereProgram = "&& Program LIKE '%$intPROGRAM%'";
  }
  
  my $DB = '';
  my $Entity_ID_Field = '';

  if ($intPROGRAM =~ /QCP/i) {
    $DB = "qcp";
	$Entity_ID_Field = 'Clinic_ID';
  } 
  else {
    $DB = "officedb";
    $Entity_ID_Field = 'Pharmacy_ID';
  }
  
  $sql = "SELECT Intervention_ID, $Entity_ID_Field, Program, a.Type, Type_ID, Category, CSR_ID, CSR_Name, a.Status, Opened_Date, Closed_Date, Comments,
                 b.Third_Party_Payer_Name, c.Vendor_Name, d.Affiliate_Name 
            FROM $DB.interventions a 
       LEFT JOIN $DB.third_party_payers b ON a.Type_ID = b.Third_Party_Payer_ID
       LEFT JOIN $DB.vendor c ON a.Type_ID = c.Vendor_ID
       LEFT JOIN $DB.affiliate d ON a.Type_ID = d.Affiliate_ID
           WHERE $Entity_ID_Field = $Entity_ID 
                 $sql_whereProgram
              && a.Status IN ('Active', 'Closed') 
              && (a.Status = 'Active' || (a.Status = 'Closed' && Closed_Date >= CURDATE() - INTERVAL 30 DAY))
        ORDER BY a.Status ASC, Opened_Date ASC";

  $sthi = $dbx->prepare($sql);

  $sthi->execute();
  my $intsFound = $sthi->rows;

  if ($intsFound > 0) {
    print qq#<p>
	<input id="search" placeholder="Search" name="search" type="text">
	<span id="found" style="display: none;">(Found <span id="foundCount"></span> interventions) </span>
	&nbsp;-&nbsp;
	Jump to: <a href="\#Active">Active</a> or <a href="\#Closed">Closed</a>
	</p>\n#;
	print "<hr />\n";
  
    while (my @row = $sthi->fetchrow_array()) {
      my ($Intervention_ID, $Pharmacy_ID, $Program, $Type, $Type_ID, $Category, $CSR_ID, $CSR_Name, $Status, $Opened_Date, $Closed_Date, $Comments, $TPP_Name, $VName, $AName ) = @row;
	  
      $intNum++;
  	
      my ($Opened_Date_Out) = &FixDBDate($Opened_Date);
      my ($Closed_Date_Out) = &FixDBDate($Closed_Date);
      $EName = $TPP_Name if($Type eq 'ThirdPartyPayer');
      $EName = $VName if($Type eq 'Vendor');
      $EName = $AName if($Type eq 'Affiliate');

      if ($activeCount == 0) {
        print qq#<h1 class="page_title">Active Interventions</h1><a name="Active"></a>#;
 	if ($closedCount == 0 && $Status =~ /^Closed/i) {
	  print "<p>No Active interventions found.</p>\n";
	}
      }
	  
      if ($closedCount == 0 && $Status =~ /^Closed/i) {
        print "<hr />\n";
        print qq#<h1 class="page_title">Closed Interventions</h1><a name="Closed"></a>#;
	print "<p>(searching closed within 30 days.)</p>\n";
      }
  	
      if ( $Status =~ /^Active/i ) {
	    $activeCount++;
        $bgcolor = "red";
        $headerclass = 'int_header_open';
      } elsif ( $Status =~ /^Closed/i ) {
	    $closedCount++;
        $bgcolor = "green";
        $headerclass = 'int_header_closed';
      } else {
        #Pending or not set yet!
        $bgcolor = "yellow";
      }
  	
      ### Display initial intervention info...
      print qq#<div id="intNum${intNum}" class="int_block">\n#;
	  
      print qq#<div class="int_pri">\n#;
      $Comments =~ s/\r\n/<br>/g if ( $Comments !~ /<\s*table\s*/i );
      print qq#<div class="int_header $headerclass">
	    Int: $Intervention_ID <strong>($Status)</strong> Opened by $CSR_Name on $Opened_Date_Out ($EName)
	  </div>\n#;
      print qq#<div class="int_comments">$Comments</div>\n#;
	  print qq#<div class="int_category" style="">$Category</div>\n#;
	  print qq#<div style="clear: both;"></div>\n#;
      print qq#</div>\n\n#; #End int_pri
  	
      #Process intervention updates...
      $sql = "SELECT Row_CSR_ID, Row_CSR_Name, Row_Date, Row_Comments
                FROM $DB.int_rows 
               WHERE Row_Intervention_ID = $Intervention_ID 
            ORDER BY Row_Date DESC";
      $sthiu = $dbx->prepare($sql);
      $sthiu->execute();
      my $intUpdatesFound = $sthiu->rows;
	  
      $row_update = 1;
      $hide_by_default = '';
      $max_updates_to_display = 3;
	  
      if ($intUpdatesFound > 0) {
        while (my @row = $sthiu->fetchrow_array()) {
          my ($Row_CSR_ID, $Row_CSR_Name, $Row_Date, $Row_Comments) = @row;
          my ($Row_Date_Out) = &FixDBDate($Row_Date);
		  
	  if ($row_update > $max_updates_to_display) {
	    $hide_by_default = qq#style="display: none;"#;
	  }
		  
	  ### Display intervention updates...
	  print qq#<div class="int_update updates${intNum}" $hide_by_default>\n#;
	  print qq#<div class="int_update_header">Updated $Row_Date_Out (by $Row_CSR_Name)</div>\n#;
	  print qq#<div class="int_update_comments">$Row_Comments</div>\n#;
	  print qq#</div>\n#; #End int_update
		  
          $row_update++;
	}

	if ($row_update > $max_updates_to_display) {
	  print qq#<p class="toggle_comments" style="float: right;"><a href="\#" onclick="return false;">show all $row_update updates...</a></p>\n#;
	  print qq#<div style="clear: both;"></div>\n#;
	}
      }
      $sthiu->finish;
	
      print qq#</div>\n\n#; #End int_block
    }
	
    if ($closedCount == 0) {
	  print "<hr />\n";
      print qq#<h1 class="page_title">Closed Interventions</h1><a name="Closed"></a>#;
      print "<p>No Closed interventions found within 30 days.</p>\n";
    }
	
  } else {
    print "<p>You do not have any Active interventions, or Closed interventions within the past 30 days.</p>\n";
  }
  $sthi->finish;

  print qq#</div> <!-- end div interventions -->\n#;
}

#______________________________________________________________________________

sub disp_Pharmacy_Store_Hours {

# my $debug++;
# my $verbose++;
 
  my ($TYPE, $Pharmacy_ID) = @_;

  @OC = ('Open', 'Closed');
  @HR = ("01","02","03","04","05","06","07","08","09","10","11","12");
  @MN = ("00", "15", "30", "45");
  @AMPM = ("AM", "PM");
  $OC  = "OC";
  $OHR = "OHR";
  $OMN = "OMN";
  $OAP = "OAP";
  $CHR = "CHR";
  $CMN = "CMN";
  $CAP = "CAP";

print <<BM;
<script>
\$(function() {
	\$(".OCsunday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".sunday").prop('disabled', false);
		} else {
			\$(".sunday").prop('disabled', true);
		}
	}); 
	\$(".OCsunday").change();
        // ---
	
	\$(".OCmonday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".monday").prop('disabled', false);
		} else {
			\$(".monday").prop('disabled', true);
		}
	}); 
	\$(".OCmonday").change();
        // ---
	
	\$(".OCtuesday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".tuesday").prop('disabled', false);
		} else {
			\$(".tuesday").prop('disabled', true);
		}
	}); 
	\$(".OCtuesday").change();
        // ---
	
	\$(".OCwednesday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".wednesday").prop('disabled', false);
		} else {
			\$(".wednesday").prop('disabled', true);
		}
	}); 
	\$(".OCwednesday").change();
        // ---
	
	\$(".OCthursday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".thursday").prop('disabled', false);
		} else {
			\$(".thursday").prop('disabled', true);
		}
	}); 
	\$(".OCthursday").change();
        // ---
	
	\$(".OCfriday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".friday").prop('disabled', false);
		} else {
			\$(".friday").prop('disabled', true);
		}
	}); 
	\$(".OCfriday").change();
        // ---
	
	\$(".OCsaturday").change(function(){
		if ( \$(this).val() == "Open" ) { 
			\$(".saturday").prop('disabled', false);
		} else {
			\$(".saturday").prop('disabled', true);
		}
	}); 
	\$(".OCsaturday").change();
        // ---
	
});

</script>

BM

  $URLH = "${prog}${ext}#top";
  print qq#<FORM NAME="hours" ACTION="$URLH" METHOD="POST">\n#;
  print qq#<INPUT TYPE="hidden" NAME="debug"    VALUE="$debug">\n#;
  print qq#<INPUT TYPE="hidden" NAME="verbose"  VALUE="$verbose">\n#;
  print qq#<INPUT TYPE="hidden" NAME="db"       VALUE="$dbin">\n#;
  print qq#<INPUT TYPE="hidden" NAME="opt"      VALUE="$opt">\n#;
  print qq#<INPUT TYPE="hidden" NAME="sf"       VALUE="$sf">\n#;
  print qq#<INPUT TYPE="hidden" NAME="sfStatus" VALUE="$sfStatus">\n#;
  print qq#<INPUT TYPE="hidden" NAME="inNCPDP"  VALUE="$inNCPDP">\n#;
  print qq#<INPUT TYPE="hidden" NAME="inNPI"    VALUE="$inNPI">\n#;
  print qq#<INPUT TYPE="hidden" NAME="SHOWALL"  VALUE="Yes">\n#;
  print qq#<INPUT TYPE="hidden" NAME="ACTION"   VALUE="$ACTION">\n#;
  print qq#<INPUT TYPE="hidden" NAME="SELD"     VALUE="$SELD">\n#;

  print "<h2>", ucfirst($TYPE), " Hours</h2>\n";
  print "Please input the hours of operation for open days. Indicate if the ", lc($TYPE), " is open or closed each day of the week on the left.<br>\n";

  print "<table border=0>\n";
  foreach $key (sort keys %FULLDAYS) {
    $DAY  = $FULLDAYS{$key};
    $formday = lc($DAY);
    $TDAY = "Hours_" . $DAY;
    $varOC  = "${DAY}${OC}";
    $varOHR = "${DAY}${OHR}";
    $varOMN = "${DAY}${OMN}";
    $varOAP = "${DAY}${OAP}";
    $varCHR = "${DAY}${CHR}";
    $varCMN = "${DAY}${CMN}";
    $varCAP = "${DAY}${CAP}";
    print "<tr>";
    print "<td>DAY</td><td>doldolTDAY</td>\n" if ($debug);
    print "<th align=left>Open/Closed</th><th>$nbsp</th><th align=left colspan=7>$DAY</th>";
    print "</tr>\n";
#   print "TDAY: $TDAY, doldolTDAY: $$TDAY<br>\n";
#
    if ( $$TDAY !~ /^\s*$|Closed/i ) {
      $$varOC = "Open";
      ($ohour, $omin, $oampm, $to, $chour, $cmin, $campm) = split(/ |:/, $$TDAY, 7);
      print "($ohour, $omin, $oampm, $to, $chour, $cmin, $campm)<br>\n" if ($debug);
      $$varOHR = $ohour;
      $$varOMN = $omin;
      $$varOAP = $oampm;
      $$varCHR = $chour;
      $$varCMN = $cmin;
      $$varCAP = $campm;
      print "<tr><td>varOC: $varOC</td> <td>varOHR: $varOHR</td><td> val: $$varOHR</td><td> varOMN: $varOMN</td><td> val: $$varOMN</td><td> varOAP: $varOAP</td><td> val: $$varOAP</td></tr>\n" if ($debug);
    } else {
      $$varOC = "Closed";
    }
    print qq#<tr>\n#;
    print "<td>$DAY</td><td>$$TDAY</td>\n" if ($debug);
    &dodropdown2( "$varOC", $formday,  $color, @OC);
    print qq#<td>$nbsp</td>#;
    &dodropdown2( $varOHR, $formday, $color, @HR);
    &dodropdown2( $varOMN, $formday, $color, @MN);
    &dodropdown2( $varOAP, $formday, $color, @AMPM);
    print "<td>to</td>\n";
    &dodropdown2( $varCHR, $formday, $color, @HR);
    &dodropdown2( $varCMN, $formday, $color, @MN);
    &dodropdown2( $varCAP, $formday, $color, @AMPM);
    print qq#</tr>\n#;
    print qq#<tr style="height:15px;"><td colspan=9><hr></td></tr>\n#;
  }
  print qq#<tr><th><INPUT TYPE="Submit" NAME="SORT" VALUE="Change Hours"></th></tr>\n#;

  print "</table>\n";
  print qq#  </FORM>\n#;

}

#______________________________________________________________________________

sub dodropdown2 {

# my $debug++;
# my $verbose++;

  my ($dbvar, $formday, $color, @OPTS) = @_;
  $dbvarval = $$dbvar;
# $formname = "UpDB_" . "$dbvar";
  $formname = $dbvar;
  print "sub dodropdown2: dbvar: $dbvar, formday: $formday, dbvarval: $dbvarval, dolOPTS: $#OPTS<br>\n" if ($debug);

  my $formid = "open_closed_${formday}";
  if ( $dbvar =~ /OC$/ ) {
     $class = "OC${formday}";
  } else {
     $class = "${formday}";
  }

# if only one item in array, set default value to that
  if ( $#OPTS == 0 ) {
     $dbvarval = $OPTS[0];
  }

  my $foundmatch = 0;

  print qq#  <td class="$color">\n#;
  print qq#    <SELECT NAME="$formname" autocomplete="off" class="$class">\n#;
  foreach $OPT (@OPTS) {
    if ( $dbvarval =~ /^$OPT/i ) {
       $SEL = "SELECTED";
       $foundmatch++;
    } else {
       $SEL = "";
    }
    print qq#      <OPTION $SEL VALUE="$OPT">$OPT</OPTION>\n#;
  }
  if ( $foundmatch <= 0 ) {
    print qq#      <OPTION SELECTED VALUE="$OPT">$OPT</OPTION>\n#;
  }
  print qq#    </SELECT>\n#;
  print qq#  </td>\n#;

# print "sub dodropdown2: dbvar: exit.<br>\n" if ($debug);

}

#_______________________________________________________________________________

sub hasAccess {
# my $debug++;
# my $verbose++;

  my ($USER) = @_;

  my ($ENV) = &What_Env_am_I_in;
  my $dbin     = "WADBNAME";
  my $db       = $dbin;
  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  my $FIELDS   = $DBFLDS{"$dbin"};
  my $FIELDS2  = $DBFLDS{"$dbin"} . "2";
  my $fieldcnt = $#${FIELDS2} + 2;

  my @KEYFs = split(":", $DBKEYF{"$dbin"});
  my @SELDs = split(/:/, $SELD);

  my $HASH   = $HASHNAMES{$dbin};
 
# Connect to the database

  my $closeDB = 0;
  if ( !$dbx ) {
    $closeDB++;
    my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error );
    $dbx = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd, \%attr) || &handle_error;
   
    DBI->trace(1) if ($dbitrace);
  }
 
  my $sql = "SELECT $$FIELDS
               FROM $DBNAME.$TABLE
              WHERE (1=1)
                 && WLSuperUser = $USER";

  my $sthx = $dbx->prepare("$sql");
  $sthx->execute;

  while ( my @row = $sthx->fetchrow_array() ) {
    my $ptr = 0;
    my $pc  = "";
    foreach $pc (@row) {
       $jfieldname  = &trim(@$FIELDS2[$ptr]);
       $$jfieldname = $pc;
       $ptr++;
    }
  }
  $sthx->finish;

#______________________________________________________________________________
# Close the Database

  if ($closeDB > 0) {
    $dbx->disconnect;
  }
}

#_______________________________________________________________________________


sub eftForm {

  my ($inNCPDP, $pdfSaveDir, $pdfDownloadDir) = @_;
  
  my $eft_pharmacy_name = $Pharmacy_Names{$inNCPDP} || $Clinic_Names{$inNCPDP};
  
  #Relies on &readPharmacies, &eftPDF
  #Template PDF located in D:/WWW/www.paidesktop.com/docs/EFT/EFT_Master_File.pdf
  
  my ($prog, $dir, $ext) = fileparse($0, '\..*');
  
  if ($inNCPDP > 0 && $in{'inAuthName'} !~ /^\s*$/) {
    my ($builtPDF, $eft_output) = &eftPDF($pdfSaveDir);
    if ($builtPDF > 0) {
      print qq#<p>Please follow the instructions in the cover pages of the PDF download in order to submit your form(s) directly to the third party payer(s).</p>\n#;
    
      print qq#<div class="lj_blue" style="margin: 10px 0 10px 0; padding: 10px; width: 350px; text-align: center;"><a href="${pdfDownloadDir}/${eft_output}.pdf" download target="_blank"><strong>Download EFT Packet (PDF) for ${eft_pharmacy_name}</strong></a></div>\n#;      
    }
  } else {
  
    print qq#<p>Complete the following fields and click "Populate EFT Documents" at the bottom of the page. This will build a PDF file to download containing all EFT documents pre-populated with your information, as well as instructions with how to proceed.</p>\n
	#;
	
	
	if($ENV{'HTTP_HOST'} =~/qcpnetworx.com/i || $ENV{'HTTP_HOST'} =~/cipnetwork.com/i){
	
	    print qq#<p><i>Important Note:</i> Some third party payers may request for remittances to be set up electronically via 835 in order to receive payment via EFT.</p>\n#;
    }
    print qq#<FORM ACTION="${prog}.cgi" METHOD="POST" onSubmit="return checkRequiredFields(this);">\n#;
    
    if ($in{'inAuthName'} =~ /^\s*$/) {
      $in{'inAuthName'} = $Pharmacy_Primary_Contact_Name{$inNCPDP};
    }
    if ($in{'inAuthEmail'} =~ /^\s*$/) {
      $in{'inAuthEmail'} = $Pharmacy_Email_Address{$inNCPDP};
    }
    if ($in{'inAuthPhone'} =~ /^\s*$/) {
      $in{'inAuthPhone'} = $Pharmacy_Business_Phones{$inNCPDP};
    }
    if ($in{'inAuthFax'} =~ /^\s*$/) {
      $in{'inAuthFax'} = $Pharmacy_Fax_Number{$inNCPDP};
    }
    
    if ($inNCPDP =~ /1111111|2222222/) {
      $in{'inAuthTitle'}   = "Owner";
      
      $in{'inBankName'}    = "First National Bank";
      $in{'inBankPhone'}   = "(913) 555-5555";
      $in{'inBankStreet'}  = "123 N. 3rd St.";
      $in{'inBankCity'}    = "Louisburg";
      $in{'inBankState'}   = "KS";
      $in{'inBankZip'}     = "66053";
      
      $in{'inAcctName'}    = "MY LLC ACCT";
      $in{'inAcctRouting'} = "1234567890";
      $in{'inAcctAccount'} = "980085868";
    }

    print qq#<p><strong>EFT Setup Authorized Signer Information:</strong></p>\n#;
    print qq#<table>\n#;
    print qq#<tr><td>Auth. Signer Name:</td><td><input name="inAuthName"   value="$in{'inAuthName'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Auth. Signer Title:</td><td><input name="inAuthTitle" value="$in{'inAuthTitle'}" class="required" /></td></tr>\n#;
    if ($in{'inAuthDepartment'} =~ /^\s*$/) { $in{'inAuthDepartment'} = "Accounts Receivables"; }
    print qq#<tr><td>Department:</td><td><input name="inAuthDepartment" value="$in{'inAuthDepartment'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Email:</td><td><input name="inAuthEmail" value="$in{'inAuthEmail'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Phone:</td><td><input name="inAuthPhone" value="$in{'inAuthPhone'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Fax:</td><td><input name="inAuthFax" value="$in{'inAuthFax'}" class="required" /></td></tr>\n#;
    print qq#</table>\n#;
    print qq#<br /><hr /><br />\n#;

    print qq#<p><strong>Bank Information:</strong></p>\n#;
    print qq#<table>\n#;
    print qq#<tr><td>Bank Name:</td><td><input name="inBankName" value="$in{'inBankName'}" class="required" /></td></tr>\n#;
    if ($in{'inBankContact'} =~ /^\s*$/) { $in{'inBankContact'} = "EFT Setup"; }
    print qq#<tr><td>Bank Contact:</td><td><input name="inBankContact" value="$in{'inBankContact'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Bank Phone:</td><td><input name="inBankPhone" value="$in{'inBankPhone'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Bank Street:</td><td><input name="inBankStreet" value="$in{'inBankStreet'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Bank City:</td><td><input name="inBankCity" value="$in{'inBankCity'}" class="required" /></td></tr>\n#;
    
    print qq#
    <tr>
    <td>Bank State:</td>
    <td><!-- <input name="inBankState" value="$in{'inBankState'}" class="required" /> -->
      <select name="inBankState" size="1" class="required">
        <option value="$in{'inBankState'}">$in{'inBankState'}</option>
        <option value="AK">AK</option>
        <option value="AL">AL</option>
        <option value="AR">AR</option>
        <option value="AZ">AZ</option>
        <option value="CA">CA</option>
        <option value="CO">CO</option>
        <option value="CT">CT</option>
        <option value="DC">DC</option>
        <option value="DE">DE</option>
        <option value="FL">FL</option>
        <option value="GA">GA</option>
        <option value="HI">HI</option>
        <option value="IA">IA</option>
        <option value="ID">ID</option>
        <option value="IL">IL</option>
        <option value="IN">IN</option>
        <option value="KS">KS</option>
        <option value="KY">KY</option>
        <option value="LA">LA</option>
        <option value="MA">MA</option>
        <option value="MD">MD</option>
        <option value="ME">ME</option>
        <option value="MI">MI</option>
        <option value="MN">MN</option>
        <option value="MO">MO</option>
        <option value="MS">MS</option>
        <option value="MT">MT</option>
        <option value="NC">NC</option>
        <option value="ND">ND</option>
        <option value="NE">NE</option>
        <option value="NH">NH</option>
        <option value="NJ">NJ</option>
        <option value="NM">NM</option>
        <option value="NV">NV</option>
        <option value="NY">NY</option>
        <option value="OH">OH</option>
        <option value="OK">OK</option>
        <option value="OR">OR</option>
        <option value="PA">PA</option>
        <option value="PR">PR</option>
        <option value="RI">RI</option>
        <option value="SC">SC</option>
        <option value="SD">SD</option>
        <option value="TN">TN</option>
        <option value="TX">TX</option>
        <option value="UT">UT</option>
        <option value="VA">VA</option>
        <option value="VT">VT</option>
        <option value="WA">WA</option>
        <option value="WI">WI</option>
        <option value="WV">WV</option>
        <option value="WY">WY</option>
      </select>
    </td>
    </tr>
    \n#;
    
    print qq#<tr><td>Bank Zip:</td><td><input name="inBankZip" value="$in{'inBankZip'}" class="required" /></td></tr>\n#;
    print qq#</table>\n#;
    print qq#<br /><hr /><br />\n#;

    print qq#<p><strong>Account Information:</strong></p>\n#;
    print qq#<table>\n#;
    print qq#<tr><td>Name on Bank Account:</td><td><input name="inAcctName" value="$in{'inAcctName'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Routing\#:</td><td><input name="inAcctRouting" value="$in{'inAcctRouting'}" class="required" /></td></tr>\n#;
    print qq#<tr><td>Account\#:</td><td><input name="inAcctAccount" value="$in{'inAcctAccount'}" class="required" /></td></tr>\n#;

    $CHECKED_inAcctType_Checking = '';
    $CHECKED_inAcctType_Savings  = '';
    if ($in{'inAcctType'} =~ /savings/i) {
      $CHECKED_inAcctType_Savings  = 'CHECKED';
    } elsif ($in{'inAcctType'} =~ /checking/i) {
      $CHECKED_inAcctType_Checking = 'CHECKED';
    }
    print qq#<tr><td>Account Type:</td><td>
      <input type="radio" name="inAcctType" value="checking" class="required" $CHECKED_inAcctType_Checking /> Checking &nbsp; <i>or</i> &nbsp; 
      <input type="radio" name="inAcctType" value="savings" $CHECKED_inAcctType_Savings/> Savings 
    </td></tr>\n#;

    print qq#<input type="hidden" name="inAcctPharmType" value="independent" />#;

    $CHECKED_inAcctEFT_New = '';
    $CHECKED_inAcctEFT_Update  = '';
    if ($in{'inAcctEFT'} =~ /update/i) {
      $CHECKED_inAcctEFT_Update  = 'CHECKED';
    } elsif ($in{'inAcctEFT'} =~ /new/i) {
      $CHECKED_inAcctEFT_New = 'CHECKED';
    }
    print qq#<tr><td>EFT Type:</td><td>
      <input type="radio" name="inAcctEFT" value="eft_new" class="required" $CHECKED_inAcctEFT_New /> NEW EFT &nbsp; <i>or</i> &nbsp; 
      <input type="radio" name="inAcctEFT" value="eft_update" $CHECKED_inAcctEFT_Update /> UPDATE to Existing Account 
    </td></tr>\n#;

    $CHECKED_inAcctIncluded_Bank = '';
    $CHECKED_inAcctIncluded_Check  = '';
    if ($in{'inAcctIncluded'} =~ /bank/i) {
      $CHECKED_inAcctIncluded_Bank  = 'CHECKED';
    } elsif ($in{'inAcctIncluded'} =~ /check/i) {
      $CHECKED_inAcctIncluded_Check = 'CHECKED';
    }
    print qq#<tr><td>Included Info:</td><td>
      <input type="radio" name="inAcctIncluded" value="eft_check" class="required" $CHECKED_inAcctIncluded_Check /> Voided Check &nbsp; <i>or</i> &nbsp; 
      <input type="radio" name="inAcctIncluded" value="eft_bank" $CHECKED_inAcctIncluded_Bank /> Bank Letter 
    </td></tr>\n#;

    print qq#</table>\n#;
    print qq#<br /><hr />\n#;
    
    print qq#<p id="errors" style="color: \#F00;"></p>\n#;

    print qq#<br /><INPUT TYPE="Submit" VALUE="Populate Documents" class="button-form">\n#;
    print qq#</FORM>\n#;
    
    print qq#
    <script>
    var checkRequiredFields = function(form) {
      
      var errors = '';
      var error_found = 0;
      
      var checkClass = /(^|\\s)required(\\s|\$)/;  // Field is required
      var checkValue = /^\\s*\$/;                 // Match all whitespace
      
      for(var i=0; i < form.length; i++) {
        
        error_found = 0;
        
        if ( checkClass.test(form[i].className) ) {
          // Required field has no value or only whitespace
          
          if (form[i].type === 'radio') {
            var radios = document.getElementsByName(form[i].name);
            var checked = 0;
            for (var j=0; j < radios.length; j++) {
              if (radios[j].checked) {
                checked += 1;
              }
            }
            if ( checked <= 0 ) {
              error_found = 1;
            }
          } else if (checkValue.test(form[i].value)) {
            error_found = 1;
          }
          
          if (error_found > 0) {
            var name = form[i].name;
            name = name.replace(/^in/g, '');
            name = name.replace(/_/g, ' ');
            name = name.split(/(?=[A-Z])/).join(" ");
            errors += '(' + name + ') \\n';
          }
        }
        
      }
      
      if (errors) {
        errors = 'Please fill out all required fields: \\n' + errors;
        var displayErrorsID = document.getElementById("errors");
        if (displayErrorsID === null) {
          alert(errors);
        } else {
          errors = errors.replace(new RegExp('\\r?\\n','g'), '<br />');
          displayErrorsID.innerHTML = errors;
        }
        return false;
      }
      
    }
    </script>
    #;
  
  }

}

#______________________________________________________________________________

sub read_DB_Table_Keys {

  my ($DBNAME, $TABLE) = @_;
  #my $debug++;

  print "read_DB_Table_Keys. Entry. DBNAME: $DBNAME, TABLE: $TABLE<br>\n" if ($debug);

  $sql = qq#
SELECT COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE (1=1)
&& TABLE_SCHEMA = '$DBNAME'
&& TABLE_NAME   = '$TABLE'
#;

  print "sql:<br>\n$sql<br>\n" if ($debug);

  my $sthx = $dbx->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows found: $NumOfRows<br>\n" if ($debug);

  my $ptr = 0;
  while ( my @row = $sthx->fetchrow_array() ) {
     ($COLUMN_NAME) = @row;
     $ptr++;
     $rdbtk_Column_Names{$COLUMN_NAME} = $ptr;
     print "set rdbtk_Column_Names($COLUMN_NAME) = $ptr<br>\n" if ($debug);
  }
  print "<br>read_DB_Table_Keys. Exit.<br><hr>\n\n" if ($debug);
}

#_______________________________________________________________________________

sub potential_dup {

  my ($sql,$FTP_Filename) = @_;
  my $IMADUP = 0;
  my $ROWCNT = 0;

  my $debug = 0;
#  my $debug++;
  my ($package, $filename, $line) = caller;

  print "sub potential_dup. Entry.\n" if ($debug);

  $sql =~ s/<br>/ /g;	# remove web carriage returns for comparisons below
  $sql =~ s/\n/ /g; 	# remove carriage returns for comparisons below

  my $MYSQL = "SELECT count(*) FROM ";
  my $pc  = "";
  ($p1, $p2) = split(/ SET /i, $sql, 2);
  my @tmp = split(/\s+/, $p1);
  my $table = $tmp[$#tmp];
  $MYSQL .= " $table WHERE ";

  my @pcs = &parse_csv($p2);
  foreach $pc (@pcs) {
    $pc =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
    if ( $pc =~ /R_TPP\s*=|R_Sequence_in_File\s*=/i ) {
       print "\tSKIPPING pc: $pc\n" if ($debug);
       next;
    }

    foreach $column_name (sort { $rdbtk_Column_Names{$a} <=> $rdbtk_Column_Names{$b} } keys %rdbtk_Column_Names) {
      if ( $column_name =~ /^R_TPP$|^R_ISA_BIN$/i ) {
         # jlh. 09/19/2016. Causing duplicates on these two columns if different. SXC-IRX and SXC-VAH are good examples
#        print "SKIPPING key check for key field: $column_name\n" if ($debug);
         next;
      }

      if ($pc =~ /$column_name/i ) {
         $pc  =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
         $MYSQL .= "$pc && ";
         if ( $debug ) {
#           print "... MYSQL: $MYSQL\n";
#           print "-"x72, "\n";
         }
      }
    }
  }
  $MYSQL =~ s/&&\s*$//;
  $MYSQL =~ s/\s+$/ /g;		                      # jlh. 08/26/2016. Added "$" at end and fixed errors comparing.
#  $MYSQL .= " && (DATE(R_JAddedDate) <> DATE(NOW()) OR R_FTP_Filename <> '$FTP_Filename')" if ($table =~ /835remitstb$/);  # smd. 1/3/2016. Modified and added Filename. 12/28/2016 Added at end to stop finding dups in the same file on 835remits.
  $MYSQL .= " && DATE(R_JAddedDate) <> DATE(NOW())" if ($table =~ /835remitstb$/);  # smd. 12/28/2016. Added at end to stop finding dups in the same file on 835remits.
  print "PROD MYSQL:\n$MYSQL\n\n" if ($debug);

  my $sthx = $dbx->prepare("$MYSQL");
  $sthx->execute;
  while ( my @row = $sthx->fetchrow_array() ) {
     ($ROWCNT) = @row;
  }

  print "Number of rows found: $ROWCNT<br>\n" if ($debug);
  $sthx->finish;

  print "PROD - ROWCNT: $ROWCNT\n" if ($debug);
  $IMADUP++ if ( $ROWCNT > 0 );

  if ( $IMADUP ) {
    print "Already found dup in prod. Don't need to also check archive\n";
  } else {
    $MYSQL =~ s/835remitstb /835remitstb_archive /gi;
    print "Check Archive now. MYSQL:\n$MYSQL\n\n" if ($debug);

    my $sthy = $dbx->prepare("$MYSQL");
    $sthy->execute;
    while ( my @row = $sthy->fetchrow_array() ) {
       ($ROWCNT) = @row;
    }
    print "Check Archive count: Number of rows found: $ROWCNT<br>\n" if ($debug);
    $sthy->finish;
    print "ARCH - ROWCNT: $ROWCNT\n" if ($debug);
    $IMADUP++ if ( $ROWCNT > 0 );
  }

#----------------------------------------------------------
# jlh. 05/19/2016. Automatically put it into the dups table
#  print "JDH - IMADUP: $IMADUP. Since at claim level, don't add to DUPS as it is an exact match on KEY FIELDS.\n\n";
  if ( $IMADUP ) {
     my $MYSQLDUPS = $sql;
     $MYSQLDUPS =~ s/835remitstb /835remitstb_DUPS /gi;
     $MYSQLDUPS =~ s/^\s*INSERT /REPLACE /gi;
     
     print "Running SQL\n$MYSQLDUPS\n";
     my $sthy = $dbx->prepare("$MYSQLDUPS");
     $sthy->execute;
    
     $sthy->finish;
    
     print "IMADUP. A dup found! Replaced now into 835remitstb_DUPS\n";
  }
  
#----------------------------------------------------------

  print "sub potential_dup. Exit. IMADUP: $IMADUP\n" if ($debug);

  return($IMADUP);

}

#_______________________________________________________________________________
#
sub get_cash_clients {


  $sql = qq#
    SELECT file_name, id 
      FROM cashclaims.client_list
  #;

  print "sql:\n$sql\n" if ($debug);

  $sth = $dbx->prepare($sql);
  $NumOfRows = $sth->execute();
  print "Number of rows found: $NumOfRows\n" if ($debug);

  while ( my @row = $sth->fetchrow_array() ) {
     my ($name,$id) = @row;
     $cash_client_id{$name} = $id;
  }

  $sth->finish;
}


sub get_Medicare_Medicaid {

  my $debug = 0;

  $sql = qq#
SELECT BIN, PCN, Comm_MedD_Medicaid
FROM rbsreporting.plan_name_lookup
WHERE (1=1)
&& (Comm_MedD_Medicaid LIKE '%Medicaid%'
 || Comm_MedD_Medicaid LIKE '%Medicare%'
 || Comm_MedD_Medicaid LIKE '%Med D%'
 || Comm_MedD_Medicaid LIKE '%Government Program%')
GROUP BY BIN, PCN
ORDER BY BIN, PCN
#;

  print "sql:\n$sql\n" if ($debug);

  $sth = $dbx->prepare($sql);
  $NumOfRows = $sth->execute();
  print "Number of rows found: $NumOfRows\n" if ($debug);

  while ( my @row = $sth->fetchrow_array() ) {
     my ($BIN, $PCN, $GRP, $TYPE) = @row;

     $key = "$BIN##$PCN";
     $MM_BINs{$key}  = $BIN;
     $MM_PCNs{$key}  = $PCN;
     $MM_TYPEs{$key} = $TYPE;
     print "found: key: $key - TYPE: $TYPE\n" if ($debug);
  }

  $sth->finish;
}

#_______________________________________________________________________________

sub readTPPDisplayNameOverrides {

# my $debug++;
  print "sub readTPPDisplayNameOverrides: Entry.<br>\n" if ($debug);
  
  my $DBNAME = 'ReconRxDB';
  my $TABLE  = '835_tpp_display_name_overrides';
  
  my $closeDB = 0;
  if ( !$dbx ) {
    $closeDB++;
    my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error );
    $dbx = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd, \%attr) || &handle_error;
   
    DBI->trace(1) if ($dbitrace);
  }
  
  %TPP_Overrides_ID;
  %TPP_Overrides_ISA;
  %TPP_Overrides_Check_Number;
  %TPP_Overrides_Check_Number_Length;
  %TPP_Overrides_Description;
  %TPP_Overrides_Display_Name;
  %TPP_Overrides_BIN;
  
  my $sql = "";
  my $ISA_IDs = 10;
  
  #The goal of this for loop is to find all possible ISA IDs based on our display name exceptions table via join with the third_party_payers table. The ISA ID will ultimately be used to match against a check later and override its user facing displayed TPP name.
  
  #I'm using a loop here a few reasons:
  # 1) Can easily adjust if more ISA columns are added in the future
  # 2) Constructing the query with UNION ALL gives us a row for each ISA to easily use as the hash key
  # 3) Can use WHERE to easily filter out NULL ISA columns
  # 4) Greatly condensed code
  for (my $i = 1; $i <= $ISA_IDs; $i++) {
    $number = sprintf("%02d", $i);
    $sql .= "
    SELECT TPP_ID, Check_Number, Check_Number_Length, Description, Display_Name, BIN, ISA_ID_$number as 'ISA ID'
    FROM $DBNAME.$TABLE
    LEFT JOIN officedb.third_party_payers
      ON TPP_ID = Third_Party_Payer_ID
    WHERE ISA_ID_$number IS NOT NULL && ISA_ID_$number <> ''
    ";
    if ($i < $ISA_IDs) {
      $sql .= " UNION ALL ";
    }
  }
  
  my $sqlout = $sql;
  $sqlout =~ s/\n/<br>\n/g;
  print "sub readTPPDisplayNameOverrides: sql:<br>$sqlout<hr>\n" if ($debug);

  my $sthsp  = $dbx->prepare("$sql");
  $sthsp->execute;
  my $numofrows = $sthsp->rows;

  if ($numofrows > 0) {
    while ( my @row = $sthsp->fetchrow_array() ) {
      my ($TPP_ID, $Check_Number, $Check_Number_Length, $Description, $Display_Name, $BIN, $ISA_ID) = @row;
      my $key = "$ISA_ID##$Check_Number##$Check_Number_Length";
#     print "key: $key<br>\n";
      $TPP_Overrides_ID{$key}                  = $TPP_ID;
      $TPP_Overrides_ISA{$key}                 = $ISA_ID;
      $TPP_Overrides_Check_Number{$key}        = $Check_Number;
      $TPP_Overrides_Check_Number_Length{$key} = $Check_Number_Length;
      $TPP_Overrides_Description{$key}         = $Description;
      $TPP_Overrides_Display_Name{$key}        = $Display_Name;
      $TPP_Overrides_BIN{$key}                 = $BIN;
      
      $TPP_Overrides_BIN{$Display_Name}        = $BIN;
    }
  }
  $sthsp->finish;
  
# my $showOverrideResults++;
  #Show results of loaded hashes (hashi?)
  if ($showOverrideResults) {
    print "<hr /><div style=\"opacity: 0.4;\">\n";
    print "<p><strong>Override ISA Breakdown (Hash Readout):</strong></p>\n";
    print "<table>\n";
    print "<tr><th>TPP ID</th><th>ISA ID</th><th>BIN</th><th>Check \#<br />(^begins with)</th><th>Check \#<br />Length (opt.)</th><th>Display Name</th><th>Description</th></tr>\n";
    foreach my $key (sort keys %TPP_Overrides_ISA) {
      my $TPP_ID = $TPP_Overrides_ID{$key};
      my $ISA_ID = $TPP_Overrides_ISA{$key};
      my $Check_Number = $TPP_Overrides_Check_Number{$key};
      my $Check_Number_Length = $TPP_Overrides_Check_Number_Length{$key};
      my $Description = $TPP_Overrides_Description{$key};
      my $Display_Name = $TPP_Overrides_Display_Name{$key};
      my $BIN = $TPP_Overrides_BIN{$key};
      print "<tr><td>$TPP_ID</td><td>$ISA_ID</td><td>$BIN</td><td>$Check_Number</td><td>$Check_Number_Length</td><td>$Display_Name</td><td>$Description</td></tr>\n";
    }
    print "</table>\n";
    print "</div>\n";
  }
  
  if ($closeDB > 0) {
    $dbx->disconnect;
  }

  print "sub readTPPDisplayNameOverrides: Exit.<br>\n" if ($debug);

}

#_______________________________________________________________________________

sub findTPPDisplayNameOverride {

  my ($ISA, $CheckNumber) = @_;

  print "sub findTPPDisplayNameOverride: Entry. ISA: $ISA, CheckNumber: $CheckNumber<br>\n" if ($debug);
  
  #If override hashes have not been set, set them:
  if (keys %TPP_Overrides_ID == 0) {
    &readTPPDisplayNameOverrides();
  }
  
  my $DisplayNameOverride = '';
  
  #Remove any leading zeros and force lowercase (for better comparison):
  $CheckNumber =~ s/^0+//g;
  $CheckNumber = lc($CheckNumber);
  #---------------------------------------------------------------------
  
  #Override hash keys contain the ISA as well as other info (ISA##CheckNumber##CheckNumberLength)
  foreach my $key (keys %TPP_Overrides_Display_Name) {
    #Cycle through all keys, find any potential matches based on ISA passed into subroutine
    if ($key =~ /$ISA/) {
    
      #Assign variable for more readable conditionals
      my $Check_Number_Starts_With = $TPP_Overrides_Check_Number{$key};
      
      #Remove any leading zeros and force lowercase (for better comparison):
      $Check_Number_Starts_With =~ s/^0+//g;
      $Check_Number_Starts_With = lc($Check_Number_Starts_With);
      #---------------------------------------------------------------------
  
      #Compare passed in parameters to exceptions, if a match is found return a display name override
      if (
        $TPP_Overrides_ID{$key} && 
        $CheckNumber =~ /^$Check_Number_Starts_With/ &&
        (
          $TPP_Overrides_Check_Number_Length{$key} =~ /^\s*$/ ||
          length($CheckNumber) == $TPP_Overrides_Check_Number_Length{$key}
        )
      ) {
        $DisplayNameOverride = $TPP_Overrides_Display_Name{$key};
      }
    
    }
  }
  
  print "sub findTPPDisplayNameOverride: Exit. Returning (DisplayNameOverride): $DisplayNameOverride<br>\n" if ($debug);
  
  #Should return either a name to use (found exception) or empty string (no exception found)
  return $DisplayNameOverride;

}

#_______________________________________________________________________________

sub SET_ISOLATION_LEVEL_BEG {

# my $debug++;

  print "sub SET_ISOLATION_LEVEL_BEG. Entry.\n" if ($debug);

# jlh. 08/04/2016. Trying to fix lock outs

  $sql = "SET TRANSACTION ISOLATION LEVEL READ COMMITTED";
  print "Executing sql: $sql\n\n" if ($debug);
  $rows = $dbx->do("$sql") or warn $DBI::errstr;

  print "sub SET_ISOLATION_LEVEL_BEG. Exit.\n" if ($debug);

}
#_______________________________________________________________________________

sub SET_ISOLATION_LEVEL_END {

# my $debug++;

  print "sub SET_ISOLATION_LEVEL_END. Entry.\n" if ($debug);

# jlh. 08/04/2016. Trying to fix lock outs

  $sql = "SET TRANSACTION ISOLATION LEVEL READ COMMITTED";
  print "Executing sql: $sql\n\n" if ($debug);
  $rows = $dbx->do("$sql") or warn $DBI::errstr;

  print "sub SET_ISOLATION_LEVEL_END. Exit.\n" if ($debug);

}

#______________________________________________________________________________

sub set_var_for_query {


  my ($INVAR) = @_;

  # Example:
  # my ($CN) = &set_var_for_query($R_TRN02_Check_Number);

# my $debug++;

  if ( $debug ) {
    print "-"x72, "\n";
    print "*** sub set_var_for_query. Entry. INVAR: $INVAR\n";
  }

  my $RTRNVAR1 = "";	# No   Quotes
  my $RTRNVAR2 = "";	# With Quotes

  ($RTRNVAR1 = $INVAR) =~ s/^\s*0+//;
  $RTRNVAR2 = "'%${RTRNVAR1}%'";

  if ( $debug ) {
    print "*** sub set_var_for_query. Exit. RTRNVAR1: $RTRNVAR1, RTRNVAR2: $RTRNVAR2\n";
    print "-"x72, "\n";
  }

  return($RTRNVAR1, $RTRNVAR2);

}

#_______________________________________________________________________________

sub Wait_on_jobs {

  my ($KILLTIME, $SLEEPTIME, $SENDTO, $TASKS) = @_;
  my $RETVAL = 0;
#  my $debug  = 0;
#  my $debug++;

  my $NumOfTasks = keys %TASKS;

  print "\n";
  print "sub Wait_on_jobs. Entry.\n";
  print "  KILLTIME : $KILLTIME  (in minutes)\n";
  print "  SLEEPTIME: $SLEEPTIME (in minutes)\n";
  print "  SENDTO   : $SENDTO\n";

  print "Tasks this job will wait on to run. Verify this list and keep up to date!!!!\n";
  print "----------------------------------------------------------------------------\n";
  foreach $task (sort keys %TASKS) {
    print "\t$task\n";
  }
  print "----------------------------------------------------------------------------\n";
  print "\n";
  print "NumOfTasks: $NumOfTasks\n";
  print "  NOERREMAIL : $NOERREMAIL\n";

#______________________________________________________________________________

  $SLEEPTIME = $SLEEPTIME * 60;	# Convert to seconds
  $KILLTIME  = $KILLTIME  * 60;	# Convert to seconds
  
  print "="x96, "\n\n";

  # Parms required for this routine
  # $TASKS     - Pointer to hash containing tasks to see if running or ready
  # $KILLTIME  - Time in minutes to run this subroutine before forcing setting code and exiting
  # $SLEEPTIME - Time to wait between checks on each task status
  # $SENDTO    - Who to send errors to from this routine

  my $START    = time();
  my $killsecs = $KILLTIME  || 64800;	# Default to 18 hours
  my $sleepval = $SLEEPTIME ||    60;	# Default to 1 minute
  my $sendto   = $SENDTO    || 'PAIT@tdsclinical.com'; # Default to IT email address

  if ( $debug ) {
     print "-"x96, "\n";
     print "AFTER part 1:\n";
     print "\tSTART   : $START\n";
     print "\tKILLTIME: $KILLTIME\n";
     print "SLEEPTIME : $SLEEPTIME\n";
     print "sendto    : $sendto\n";
     print "Waiting on TASKS: \n";
     foreach $task (sort keys %TASKS) {
       print "\t$task\n";
     }
     print "-"x96, "\n";
  }
  
  my $pass = 0;
  my $goon = 0;
  my $from = "NoReply";
  my $subject = "";
  my $msg     = "";
  
  # Give the other "put switch data in database" programs a chance to start before we test if they are running or done
  sleep 10;
  
  do {
    $goon = 0;
    $pass++;
    foreach $task (sort keys %TASKS) {
      $cmd = qq#schtasks /query /tn "$task" /fo list | find "Status:"#;
#     print "cmd: $cmd\n" if (!$debug);
    
      ($cmd, $out) = &docmd($cmd);
#     print "$out\n\n" if ( !$debug );
      $goon++ if ( $out =~ /Ready/i );
      print "-"x80, "\n";
    }
  
    my $NOW = time();
    print "\nNOW: $NOW, goon: $goon  of  $NumOfTasks NumOfTasks\n\n";
  
    if ( $NOW - $START >= $killsecs ) {
      print "We've been in this program more than 18 hours. Send email to IT and exit\n\n";
  
      if ( $NOERREMAIL ) {
         print "\n\nDo not send Email. NOERREMAIL: $NOERREMAIL\n\n";
      } else {
        # sendmessage From, To, Subject, Msg
        my $subject = qq#$prog job failed! - Over 18 hours and still running. Killed it.#;
        my $msg     = qq#$subject<br><br>\n\n#;
           $msg    .= qq#This job has been running over 18 hours without finishing. Exit!<br>\n#;
        if ( $debug ) {
           print "1. subject: $subject\n";
           print "1. msg    : $msg\n";
        }
        print "call sendmessage($from, $sendto, $subject, $msg)\n" if ($debug);
#        &sendmessage($from, $sendto, $subject, $msg);
        &send_email($from, $sendto, $subject, $msg);
      }
      $RETVAL = 1;
      $goon = $NumOfTasks;	# to force out of do until loop
  
    } elsif ( $pass == 1 && $goon == $NumOfTasks ) {
  
      print "pass: $pass, goon: $goon - First pass too fast to 'Ready' state!\n\n";
      if ( $NOERREMAIL ) {
         print "\n\nDo not send Email. NOERREMAIL: $NOERREMAIL\n\n";
      } else {
        # sendmessage From, To, Subject, Msg
        my $subject = qq#$prog job too fast! - First pass too fast to 'Ready' state.#;
        my $msg     = qq#$subject<br><br>\n\n#;
           $msg    .= qq#First pass through and each "Put switch data in db" jobs are done already? No way.<br>\n#;
        if ( $debug ) {
           print "2. subject: $subject\n";
           print "2. msg    : $msg\n";
        }
#        &sendmessage($from, $sendto, $subject, $msg) if ($NumOfTasks != 1);
#        &send_email($from, $sendto, $subject, $msg) if ($NumOfTasks != 1);
      }
      $RETVAL = 2;
  
    } elsif ( $goon < $NumOfTasks ) {
      # Not all done yet. Wait $sleepval seconds and then start loop again and keep trying...
      print "goon: $goon, waiting on more to finish. sleep $sleepval\n";
      sleep $sleepval;
    }
    print "="x96, "\n";
  
  } until ($goon == $NumOfTasks);
  
  print "\n";
  print "sub Wait_on_jobs. Exit. RETVAL: $RETVAL\n";
  if      ( $RETVAL == 0 ) {
    print "\tRETVAL = 0 !\n";
  } elsif ( $RETVAL == 1 ) {
    print "\tError! We've been in this program more than ", $killsecs / 60 / 60, " hours. Send email to IT and exit\n\n";
  } elsif ( $RETVAL == 2 ) {
    print "\tFirst pass too fast to 'Ready' state.\n";
  }
  print "="x96, "\n\n";

  return($RETVAL);
}

#_______________________________________________________________________________

sub getFilterPayers {

# my $debug++;
# my $testing++;

  my ($in_TPP_ID,$in_TPP_BIN,$in_TPP_NAME) = @_;

  my $filterPCN = "";
  my $key = "";
  &readReconExceptionRouting2;	# jlh. 05/23/2017

  %filter_PayerIDs   = ();
  %filter_PayerBINs  = ();
  %filter_PayerNames = ();

  my $DBNAME = "officedb";
  my $TABLE  = "third_party_payers";
  my $sql = "
SELECT Third_Party_Payer_ID, BIN, Third_Party_Payer_Name  
FROM $DBNAME.$TABLE 
WHERE 1=1
&& Status = 'Active' 
&& Primary_Secondary = 'Pri' 
&& Reconcile = 'Yes' 
ORDER BY Third_Party_Payer_Name 
";

# jlh. 06/12/2017. Removed for "Central_Pay_Entity" field
##### && BIN NOT LIKE '99999%' 

  print "<hr> sql:<br><pre>$sql</pre><hr>\n" if ($debug || $testing);

  my $sthx  = $dbx->prepare("$sql");
  $sthx->execute;
  my $NumOfRows = $sthx->rows;
  print "<hr>NumOfRows: $NumOfRows<hr>\n" if ($debug || $testing);

  while ( my @row = $sthx->fetchrow_array() ) {
    my ($TPP_ID, $TPP_BIN, $TPP_NAME) = @row;
	
#   $key = "$TPP_BIN##$TPP_NAME";

	$key = "$TPP_ID##$TPP_BIN##$TPP_NAME";
	
	$filter_PayerIDs{$key}   = $TPP_ID;
	$filter_PayerBINs{$key}  = $TPP_BIN;
	$filter_PayerNames{$key} = $TPP_NAME;
	
  }
  $sthx->finish;

  foreach $key (sort keys %ExceptionBins) {
     my $TPP_ID    = $ExceptiondbKeys{$key};
     my $TPP_BIN   = sprintf("%06d", $ExceptionBins{$key});
     my $TPP_NAMES = $ExceptionComments{$key};
     $key2 = "$TPP_ID##$TPP_BIN##$TPP_NAMES";
     print "key2: $key2<br>\n" if ($debug);

     if ( $filter_PayerIDs{$key2} ) {
        print "NOT ADDING $key2. Exists!<br>\n" if ($debug);
     } else {
#       $filter_PayerIDs{$key2}   = "9999_" . $ExceptiondbKeys{$key};
        $filter_PayerIDs{$key2}   = $ExceptiondbKeys{$key};
        $filter_PayerBINs{$key2}  = $ExceptionBins{$key};
        $filter_PayerNames{$key2} = $ExceptionComments{$key};
     }
     next if ( $in_TPP_ID > 0 && $ExceptiondbKeys{$key} != $in_TPP_ID);

     my ($jbin, $jpcn, $jgr) = split("##", $key, 3);
     if ( $jpcn =~ /^ANY$/i ) {
        print "Skipping key: jpcn: $jpcn<br>\n" if ($debug);
     } else {
        $filterPCN .= qq#"$jpcn",#;
     }
     print "key: $key, $jbin, $jpcn, $jgr // ExceptiondbKeys(): $ExceptiondbKeys{$key}<br>\n" if ($debug);
  }
  $filterPCN =~ s/,\s*$//g;
  print "<hr size=8 color=red>filterPCN: $filterPCN<hr>\n" if ($debug);

  if ( $debug ) {
    print "<hr>\n";
    print "2. Dump filter_Payerxxx<br>\n";
    print "<table border=2>\n";
    print "<tr><th>ID</th> <th>BIN</th> <th>Name</th> </tr>\n";
    $jptr = 0;
    foreach $key (sort { $filter_PayerNames{$a} cmp $filter_PayerNames{$b} } keys %filter_PayerBINs) {
       $jptr++;
       print "<tr> <td>$jptr</td> <td>$filter_PayerIDs{$key}</td> <td>$filter_PayerBINs{$key}</td> <td>$filter_PayerNames{$key}</td> </tr>\n";
    }
    print "</table>\n";
    print "<hr>\n";
  }

  return ($filterPCN);
}
sub Find_RBSDirect_Pharmacies {
  my $includesample = shift;
  my @RBSNCPDP;
  $dbinPH    = "PHDBNAME";
  $DBNAMEPH  = $DBNAMES{"$dbinPH"};
  $TABLEPH   = $DBTABN{"$dbinPH"};
  $AND = "&& ncpdp != 2222222 && ncpdp > 20";
  $AND = "" if($includesample == 1);

  $sql  = qq#
    SELECT NCPDP
      FROM $DBNAMEPH.$TABLEPH 
     WHERE (1=1)
        && Type LIKE '%RBS%'
        && Status_RBS_Direct='Active'
      $AND
    ORDER BY Pharmacy_Name
    #;

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;

  my $RowsFound = $sth99->rows;

  while ( my ($row) = $sth99->fetchrow_array() ) {
    push(@RBSNCPDP, "$row");
  }

  $sth99->finish;
  return (\@RBSNCPDP);

}

sub Find_RBS_Pharmacies_No_Recon {
  my @RBSNCPDP;
  $dbinPH    = "PHDBNAME";
  $DBNAMEPH  = $DBNAMES{"$dbinPH"};
  $TABLEPH   = $DBTABN{"$dbinPH"};

  $sql  = qq#
    SELECT NCPDP
      FROM $DBNAMEPH.$TABLEPH 
     WHERE (1=1)
        && Type LIKE '%RBS%'
        && Type NOT LIKE '%Recon%'
        && Status_RBS='Active'
    ORDER BY Pharmacy_Name
    #;

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;

  my $RowsFound = $sth99->rows;

  while ( my ($row) = $sth99->fetchrow_array() ) {
    push(@RBSNCPDP, "$row");
  }

  $sth99->finish;
  return (\@RBSNCPDP);

}

sub Find_Recon_Pharmacies_with_transition_ref {

  my $print = shift;
  my @ReconNCPDP;
  my $NCPDP;
  print "Getting ReconRx Pharmacies\n";

  $dbinPH    = "PHDBNAME";
  $DBNAMEPH  = $DBNAMES{"$dbinPH"};
  $TABLEPH   = $DBTABN{"$dbinPH"};

  $sql  = qq#

  SELECT NCPDP, Pharmacy_ID
    FROM $DBNAMEPH.$TABLEPH 
   WHERE (1=1)
      && Type LIKE '%ReconRx%'
      && Status_ReconRx IN ('Active','Transition')
      && pharmacy_id > 33 
      
  ORDER BY Pharmacy_Name
  #;

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;
  my $RowsFound = $sth99->rows;
  print "Number of rows found: $RowsFound\n" if ($debug);

  while ( (my $NCPDP,$PID) = $sth99->fetchrow_array() ) {
     push (@ReconNCPDP, $NCPDP);
     $ATNCPDP{$NCPDP} = $PID;
  }

  $sth99->finish;
  print "Finished getting ReconRx Pharmacies\n";
  return (\@ReconNCPDP);
}


sub Find_Recon_Pharmacies_ref {

  my $print = shift;
  my @ReconNCPDP;
  my $NCPDP;

  $dbinPH    = "PHDBNAME";
  $DBNAMEPH  = $DBNAMES{"$dbinPH"};
  $TABLEPH   = $DBTABN{"$dbinPH"};

  $sql  = qq#
  SELECT Pharmacy_Name, NCPDP, NPI, Type, Status_ReconRx, Term_Date_ReconRx, Status_ReconRx_Clinic, Term_Date_ReconRx_Clinic
    FROM $DBNAMEPH.$TABLEPH 
   WHERE (1=1)
      && Type LIKE '%ReconRx%'
      && (Status_ReconRx='Active' && Term_Date_ReconRx IS NULL)
  ORDER BY Pharmacy_Name
  #;
  #Changed per Jessie on 2021-01-13 to exclude any pharmacy with a term date

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;
  my $RowsFound = $sth99->rows;
  print "Number of rows found: $RowsFound\n" if ($debug);

  while ( my @row = $sth99->fetchrow_array() ) {
     my ( $Pharmacy_Name, $NCPDP, $NPI, $Type ) = @row;

     push (@ReconNCPDP, $NCPDP);

     $NCPDPsTotal++;
     my $PN = substr($Pharmacy_Name,0,40);
     printf("%3d) %07d | %10d | %-40s | %-s\n", $NCPDPsTotal, $NCPDP, $NPI, $PN, $Type) if($print);

  }

  $sth99->finish;
  return (\@ReconNCPDP);
}

sub Find_TDS_Pharmacies_ref {

  my @RBSBNCPDP;
  my $NCPDP;

  $DBNAMEPH  = 'NCPDP';
  $TABLEPH   = 'NCPDP_LIST';

  $sql  = qq#
  SELECT ProviderID 
    FROM $DBNAMEPH.$TABLEPH 
  ORDER BY Pharmacy_Name
  #;

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;
  my $RowsFound = $sth99->rows;
  print "Number of rows found: $RowsFound\n" if ($debug);

  while ( my @row = $sth99->fetchrow_array() ) {
     my ($NCPDP) = @row;

     push (@RBSBNCPDP, $NCPDP);

     $NCPDPsTotal++;
  }

  $sth99->finish;
  return (\@RBSBNCPDP);
}


sub Find_DefaultCash_Pharmacies_ref {

  my @RBSBNCPDP;
  my $NCPDP;

  $DBNAMEPH  = 'officedb';
  $TABLEPH   = 'pharmacy';

  $sql  = qq#
  SELECT NCPDP
    FROM $DBNAMEPH.$TABLEPH 
   WHERE Status_DefaultCash = 'Active' 
  ORDER BY Pharmacy_Name
  #;

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;
  my $RowsFound = $sth99->rows;
  print "Number of rows found: $RowsFound\n" if ($debug);

  while ( my @row = $sth99->fetchrow_array() ) {
     my ($NCPDP) = @row;

     push (@RBSBNCPDP, $NCPDP);

     $NCPDPsTotal++;
  }

  $sth99->finish;
  return (\@RBSBNCPDP);
}

sub get_Pharmacy_Ids {

  my $program = shift;
  my @Ids = ();
  my $where;

  print "-"x72, "\n";
  print "sub get_Pharmacy_Ids. Entry.\n";

  $dbinPH    = "PHDBNAME";
  $DBNAMEPH  = $DBNAMES{"$dbinPH"};
  $TABLEPH   = $DBTABN{"$dbinPH"};

  if ( $program =~ /RBS/i ) {
     $where = "&& Type LIKE '%RBS%'
               && Status_RBS = 'Active' 
               && RBSReporting = 'Yes' ";
  }
  elsif ( $program =~ /TDSB/i ) {
     $where = "&& Type LIKE '%TDSB%'
               && Status_TDS = 'Active'
               && (Status_RBS != 'Active' || Status_RBS IS NULL) ";
  }
  elsif ( $program =~ /ReconRx/i ) {
     $where = "&& Type LIKE '%ReconRx%'
               && ((Status_ReconRx='Active' || Status_ReconRx_Clinic='Active') 
                   || (Status_ReconRx NOT IN ('Active', '') && (Term_Date_ReconRx IS NOT NULL && Term_Date_ReconRx > (DATE_SUB(CURDATE(), INTERVAL 8 WEEK))))
                   || (Status_ReconRx_Clinic NOT IN ('Active', '') && (Term_Date_ReconRx_Clinic IS NOT NULL && Term_Date_ReconRx_Clinic > (DATE_SUB(CURDATE(), INTERVAL 8 WEEK)))) 
		  ) ";
  }
  elsif ( $program =~ /Cash/i ) {
     $where = "&& Type LIKE '%Cash%'
               && ((Status_DefaultCash='Active') 
                   || (Status_DefaultCash NOT IN ('Active', '') && (Term_Date_DefaultCash IS NOT NULL && Term_Date_DefaultCash > (DATE_SUB(CURDATE(), INTERVAL 8 WEEK))))
		  ) ";
  } else {
    print "Invalid Program parameter passed";
    $where = "&& Pharmacy_ID = 0 ";
  }	  

  $sql  = "SELECT Pharmacy_ID
             FROM $DBNAMEPH.$TABLEPH 
            WHERE (1=1)
                  $where
         ORDER BY Pharmacy_Name";

  $sth99 = $dbx->prepare($sql) || warn "Error preparing query" . $dbx->errstr;
  $sth99->execute() or die $DBI::errstr;
  my $RowsFound = $sth99->rows;
  print "Number of rows found: $RowsFound\n" if ($debug);

  while ( my $Pharmacy_ID = $sth99->fetchrow_array() ) {
     push (@Ids, $Pharmacy_ID);
  }

  $sth99->finish;
  return (\@Ids);

  print "sub get_Pharmacy_Ids. Exit. Count found: $RowsFound\n";
  print "-"x72, "\n";
}

sub get_rc_access_token {

  use HTTP::Request::Common qw(POST);
  use LWP::UserAgent;

  my $success = 0;
  my $token   = '';

  my $RC_API_URL = "https://platform.ringcentral.com/restapi/oauth/token";
  my $AuthKey    = "Basic NUJkUUxYMDhScS1oSTljbEFLcEIydzpWZHUySGtEeFR3YWJQS05MTGFOTDBBdW50dFhqTDhSbEc3ajJoaGdBMnJNZw==";

  my $JWT = "eyJraWQiOiI4NzYyZjU5OGQwNTk0NGRiODZiZjVjYTk3ODA0NzYwOCIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJhdWQiOiJodHRwczovL3BsYXRmb3JtLnJpbmdjZW50cmFsLmNvbS9yZXN0YXBpL29hdXRoL3Rva2VuIiwic3ViIjoiMTg2MzI1MDEwIiwiaXNzIjoiaHR0cHM6Ly9wbGF0Zm9ybS5yaW5nY2VudHJhbC5jb20iLCJleHAiOjM4NzIzNDgwMzQsImlhdCI6MTcyNDg2NDM4NywianRpIjoiVVV3aWpJeFFRX1c1Vk9sLWdOTGpBdyJ9.Q02Uiv_gp4CFwfMbh6_EX9sw0wvIW7ts5vkBxZ5FsStDuXovb9AXKTCEgde7kinyZTjVyagFSLiKi_qLVxtn4PPZtgPzocav51Rr76hayODtm90vLJWD4qCrrSOEfv9sNwgR2-ZHAinDogA0WBj4Rbqd1IHzItkYbtg4WIyTdZaSSer5bywSFTZmx2yEY3WMiXME4O8go-5_cjpbtKFstmWW9JvLowybSONrZoYa4aYa1ceg-EB1Mrwk52x0wKjbfbpJLX39gyxTsGS5MfQJ1v00fRIIL24c4sGgL8S7jLvPZS4A6zwaBfabc_OSZhLefOMG_HY5bnmMZ2fVBs7Rig";

  my $request =   POST "$RC_API_URL", 
    Content_Type   => 'application/x-www-form-urlencoded',
    Authorization  => "$AuthKey",
    Content        => [
      grant_type   => "urn:ietf:params:oauth:grant-type:jwt-bearer", 
      assertion    => "$JWT"
    ];
    
  my $useragent = LWP::UserAgent->new();
  my $response  = $useragent->request( $request );

  if ($response->is_success) {
    $d_req = $response->decoded_content;
    $decoded_response = from_json( $d_req );
    $token = $decoded_response->{"access_token"};
    $success++;
  }
  else {
    $from    = "NoReply";
    $to      = "PAIT\@outcomes.com";
    $subject = "RingCentral Authorization Token Request Failed";
     my $msg     = qq#$subject<br><br>\n\n#;
     $msg    .= qq#Cannot get access token from Ring Central. Please check!<br>\n#;
    &send_email($from, $sendto, $subject, $msg);
  }	  

  return($success, $token);
}

sub get_rc_access_token_old {
  use URI::Escape;
  use HTTP::Request::Common qw(POST);
  use LWP::UserAgent;
  use JSON qw( decode_json from_json );

  my $success = 0;
  my $token   = '';

  my $RC_API_URL = "https://platform.ringcentral.com:443/restapi/oauth/token";
  my $AuthKey = "Basic NUJkUUxYMDhScS1oSTljbEFLcEIydzpWZHUySGtEeFR3YWJQS05MTGFOTDBBdW50dFhqTDhSbEc3ajJoaGdBMnJNZw==";

  my $RCUsername = "+18558975937";
  my $RCPassword = 'Dose$724';        # 5 - 10 digit RC password

  my $request =   POST "$RC_API_URL", 
    Content_Type    => 'application/x-www-form-urlencoded',
    Authorization   => "$AuthKey",
      Content       => [
      username      =>"$RCUsername",       # RingCentral Fax Username (10-digit RC phone number)
      password      =>"$RCPassword",       # RingCentral Fax Password
      grant_type    =>"password"           # RingCentral Fax Password
      ];
    
  my $useragent = LWP::UserAgent->new();
  my $response  = $useragent->request( $request );

  if ($response->is_success) {
    $d_req = $response->decoded_content;
    $decoded_response = from_json( $d_req );
    $token = $decoded_response->{"access_token"};
    $success++;
  }
  else {
    $from    = "IT";
    $to      = "PAIT\@tdsclinical.com";
    $subject = "RingCentral Authorization Token Request Failed";
    print "$subject\n";
    ##&sendmessage_External($from, $to, $subject, 'Access Token Request Failed.  Please look into this.');
  }	  

  return($success, $token);
}

sub send_rc_fax {
  my $token = shift;
  my $fax_num = shift;
  my (@files) = @_;

  my $success = 0;
  my $file1;
  my $file2;
  my $file3;
  my $fax_req;

  my $RC_API_URL = "https://platform.ringcentral.com/restapi/v1.0/account/~/extension/~/fax";
  
  $fax_num =~ s/\D+//g;

  $file_cnt = @files;

  print "FAX: $fax_num\n";

#        "to"           => ( phoneNumber => "$fax_num" ),

  if ($file_cnt == 1) {
    $file1 = $files[0];

    $fax_req =   POST "$RC_API_URL", 
      Content_Type  => 'multipart/form-data',
      Authorization => "Bearer $token",
      Content       => [
        "to"           => "$fax_num",
        "coverIndex"    => "0",                 # Should always be '0' for none or else default will be used
        "faxResolution" => "High",
        "attachment"    => [$file1]
        ];
  }
  elsif ($file_cnt == 2) { 
    $file1 = $files[0];
    $file2 = $files[1];

    $fax_req =   POST "$RC_API_URL", 
      Content_Type  => 'multipart/form-data',
      Authorization => "Bearer $token",
      Content       => [
        "to"          => "$fax_num",
        "coverIndex"    => "0",                 # Should always be '0' for none or else default will be used
        "faxResolution" => "High",
        "attachment"    => [$file1],
        "attachment"    => [$file2]
        ];
  }
  elsif ($file_cnt == 3) {
    $file1 = $files[0];
    $file2 = $files[1];
    $file3 = $files[2];

    $fax_req =   POST "$RC_API_URL", 
      Content_Type  => 'multipart/form-data',
      Authorization => "Bearer $token",
      Content       => [
        "to"          => "$fax_num",
        "coverIndex"    => "0",                 # Should always be '0' for none or else default will be used
        "faxResolution" => "High",
        "attachment"    => [$file1],
        "attachment"    => [$file2],
        "attachment"    => [$file3]
        ];
  }
  else {
    $from    = "IT";
    $to      = "PAIT\@tdsclinical.com";
    $subject = "RingCentral Fax Attachments not Supported";

    print "$subject\n";
    die;
    ##&sendmessage_External($from, $to, $subject, 'Fax attachments exceeds three and is not supported.  Please look into this.');
  }  

  if ($fax_req) {
	  print "Sending Fax\n\n";
    my $useragent = LWP::UserAgent->new();
    my $response  = $useragent->request( $fax_req );
    my $result    = $response->content;

#    print "REQUEST: " . $fax_req->as_string() . "\n";    
    print "RESPONSE: " . $response->as_string() . "\n";    
    
    if ($response->is_success) {
      print "Fax Successful\n";
      $success++;
    }
    else {
      print "Fax Failed: $result\n";
    }	 
  } else {
     print "ERROR: Call Not Attempted\n";
  }
    
  sleep 15;
  return($success);
}

sub convert_html_to_pdf {

  my $file = shift;
  my $pdf_file = $file;

  $pdf_file =~ s/html/pdf/;
            
  $progLocation   = "C:\\Program Files\\wkhtmltopdf\\bin\\wkhtmltopdf.exe";
  $cmd = "\"${progLocation}\" \"${file}\" \"${pdf_file}\"";
  `$cmd`;

  return $pdf_file;
}

sub save_singlepay_notes {

  my $notes = shift;
  my $group = shift;
  my $tdate = shift;
  my $DBNAME = 'reconrxdb';
  $notes =~ s/\r\n/<br>/g; 

  if ( !$dbx ) {
    $closeDB++;
    $dbx = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd, \%attr) || &handle_error_batch;
   
  }

  $sql = qq#
            REPLACE INTO reconrxdb.singlepay_notes(sp_group, trans_date, notes)
             VALUES("$group", "$tdate", "$notes") 
           #;

  $rows = $dbx->do("$sql");
  $dbx->disconnect;
  return $rows;
}

sub readOtherSources {

  my $DBNAME = 'reconrxdb';
  my $TABLE  = 'other_sources_835s_lookup';

  if ( !$dbx ) {
    $closeDB++;
    $dbx = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd, \%attr) || &handle_error_batch;
   
  }

     $sql  = "SELECT Lookup_Other_Source_TPP_ID, Lookup_BIN_REF, Lookup_TPP_Display_on_Remit_TPP_ID 
                FROM $DBNAME.$TABLE
             ";
     my $sthx = $dbx->prepare("$sql");
     $sthx->execute;

     while ( my ($FROM_ID,$BIN_REF, $TO_ID ) = $sthx->fetchrow_array() ) {
        $OtherSourceTPP{$FROM_ID}{$BIN_REF} = $TO_ID;
        $OtherSourceREF{$FROM_ID}{$TO_ID}   = $BIN_REF;
     }

     $sthx->finish;
}

sub load_otc_exclusions {

  my $tbl = 'diabetic_supply_list_otc';
  my $db  = 'defaultcash';

  my $sql = "SELECT ndc FROM $db.$tbl"; 

  my $sth = $dbx->prepare($sql);
  my $exclusion_cnt = $sth->execute;

  while ( my $n = $sth->fetchrow_array) {
    $exclusions{$n}++ ;
  }
}

sub load_835setup_exclusions {

  my $db_recon      = 'reconrxdb';
  my $tbl_exc       = '835setup_exclusions';

  $sql = "SELECT type,id 
            FROM $db_recon.$tbl_exc 
         ";

  my $sth       = $dbi->prepare("$sql");
  $sth->execute;

  while (($type,$id) = $sth->fetchrow_array) {
    if ($type eq 'NCPDP') {
      push (@exc,$id);
    }
    else {
      push (@setup_exc_tpp,$id);
      $setup_excl_psao{$id} = 1;
    }
  }
  $setup_exc     = join(',', @exc);
  $setup_exc_tpp = join(',', @exc_tpp);
}

sub save_arete835_counts {
  $count = shift;
  $type  = shift;

  $count = 0 if(!$count);
  $sql = " INSERT INTO reconrxdb.arete_835_counts (count, type)
           VALUES($count,'$type')
         ";
 
  $sth = $dbx->prepare($sql);
  $sth->execute();
 print "Updating 835 counts for today:$fdate->$count\n"; 
}

sub create_cashclaims_rebatesummary_record {
  $prog_id = shift;
  $type    = shift;
  $period  = shift;
  $fdate   = shift;

  $sql = " INSERT INTO cashclaims.rebate_summary (program_id, type, period, received)
           VALUES($prog_id,'$type','$period', '$fdate')
         ";
 
  print $sql;
  $sth = $dbx->prepare($sql);
  $sth->execute();
  print "Updating cashclaims rebate summary for today:$fdate\n"; 
}

sub load_ltc_locations {

  my $tbl_ltcs = 'ltc_locations';
  my $db       = 'reconrxdb';

  my $sql = " SELECT a.NPI, b.Pharmacy_ID, b.NCPDP FROM $db.$tbl_ltcs a
                JOIN officedb.pharmacy b on a.NPI = b.NPI
            ";

  my $sth = $dbi->prepare($sql);
  my $location_cnt = $sth->execute;

  while (($NPI, $ID, $NCPDP)   = $sth->fetchrow_array()) {
    $ltc_locations{$NPI} = $ID ;
  }
}

sub load_covid {
  print "Loading Covid NDCs\n";
  my $tbl = 'covid_ndcs';
  my $db_cc = 'cashclaims';

  $sql = "SELECT NDC FROM $db_cc.$tbl";
  my $sth       = $dbx->prepare("$sql");
  $sth->execute;

  while (($cvd) = $sth->fetchrow_array) {
    $covid{$cvd}++;
  }
}

sub Archive_TCode_Set {

  my $db_reconrx     = 'reconrxdb';
  my $tbl_a_incoming = 'incomingtb_archive';
  my $tbl_p_incoming = 'incomingtb';
  


  print "sub TCODE Archive: Entry.\n";

  my $rowsfoundInsert = 0;
  my $rowsfoundDelete = 0;
  my $sql;
  my $sthINSERT;

  $sqlST = qq#START TRANSACTION#;
  
  my $sthSTART  = $dbx->prepare($sqlST);
  $rowsfound = $sthSTART->execute;

  $sql = qq#
    INSERT INTO $db_reconrx.$tbl_a_incoming
      SELECT * FROM $db_reconrx.$tbl_p_incoming 
       WHERE dbTCode IN ('AABR','RECNO','BR','CUP','PDEV','RVL','DN','PD','PDR','PDR TSP','EV') 
  #;

  $sthINSERT  = $dbx->prepare("$sql");
  $rowsfoundInsert = $sthINSERT->execute;

  print "Rows Inserted: $rowsfoundInsert\n";

  if ( $rowsfoundInsert > 0 ) {

     $sql = "";
     $sql = qq#
       DELETE FROM $db_reconrx.$tbl_p_incoming 
       WHERE dbTCode IN ('AABR','RECNO','BR','CUP','PDEV','RVL','DN','PD','PDR', 'PDR TSP','EV') 
       #;

     $sthDELETE  = $dbx->prepare("$sql");
     $rowsfoundDelete = $sthDELETE->execute;
     print "Rows Deleted: $rowsfoundDelete\n";
  }

  if ( $rowsfoundInsert == $rowsfoundDelete ) {
     $sql  = qq#COMMIT; #;
     $sthCOMMIT  = $dbx->prepare("$sql");
     $rowsfound = $sthCOMMIT->execute;
     print "COMMIT!!!!!!!!!!!\n";
  } else {
     $sql  = qq#ROLLBACK #;
     $sthCOMMIT  = $dbx->prepare("$sql");
     $rowsfound = $sthCOMMIT->execute;
     print "\nROLLBACK!!!!!!!!!!!\n\n";
  }
  $sthSTART->finish;
  $sthINSERT->finish;
  $sthDELETE->finish;
  $sthCOMMIT->finish;

  print "sub Archive: Exit. \n";
}

sub MEV_Check { 
  my ($amNCPDP, $amProgram) = @_;
  my %PharmacyProgramsAM    = ();
  
  if ( $amProgram =~ /rbs/i ) {
      $amProgram = 'CRED';
  }
  
  if ( $amProgram =~ /CIPN|CRED/i ) {
    $emp_db = 'pharmassess';
    $db_office = 'officedb';
  }
  else {
    $emp_db = 'qcp';
  }

  my $sqlAM = "SELECT a.NCPDP, a.Program, count(*) AS emp_count
                 FROM $db_office.mev_ncpdps a
            LEFT JOIN $emp_db.credentialing_employees b ON (a.NCPDP = b.NCPDP)		 
		WHERE a.NCPDP = '$amNCPDP'		
		   && a.Program = '$amProgram'";
  
  my $sthxAM    = $dbx->prepare("$sqlAM");
  
  my $numrowsAM = $sthxAM->execute;

  my $lockoutCIPN;
  my $lockoutRBS;
  my $lockoutQCPN;
    
  while ( my @row = $sthxAM->fetchrow_array() ) {
     my ($amNCPDPs, $amProgramIs, $employee_count ) = @row;
     next if ( $employee_count <= 1 );
	 my $sqlDM;
	 if ( $amProgram =~ /CIPN|CRED/i ) {
	     $amDBNamee = 'officedb.pharmacy';
		 $sqlDM     = qq# SELECT Pharmacy_Name FROM $amDBNamee WHERE NCPDP = "$amNCPDPs" #;
	 }
	 
	 if ( $amProgram =~ /QCPN/i ) {
	     $amDBNamee = 'qcp.clinic_dispensary';
		 $sqlDM     = qq# SELECT Clinic_Name FROM $amDBNamee WHERE NCPDP = "$amNCPDPs" #;
	 }
	 
	 
	 
	 
	 my $sthxDM    = $dbx->prepare("$sqlDM");
	 my $numrowsDM = $sthxDM->execute;
	 
	 while ( my @row = $sthxDM->fetchrow_array() ){
	     ($amPhName) = @row;
	 }
	 
	 if ( $amProgramIs =~ /CIPN/i ) {
	    $lockoutCIPN++;
       if ( $lockoutCIPN ){
          print "<script>alert(\"$amPhName\\nAction is Required - According to our records, we did not\\nreceive your required Monthly Employee Verification Report.\\n\\nIn order for us to perform the required monthly OIG and GSA\\nexclusion database checks as mandated by CMS, your\\npharmacy will need to fax your Monthly Employee\\nVerification Form to CIPN at (855) 998-4954 as soon as possible.\")</script>";
	  ## print "<script> window.history.go(-1)</script>";
       }
	 }
	 
	 if ( $amProgramIs =~ /CRED/i ) {
	    $lockoutRBS++;
       if ( $lockoutRBS ){
          print "<script>alert(\"$amPhName\\nAction is Required - According to our records, we did not\\nreceive your required Monthly Employee Verification Form.\\n\\nIn order for us to perform the required monthly OIG and GSA\\nexclusion database checks as mandated by CMS, your\\npharmacy will need to fax your Monthly Employee\\nVerification Form to RBS at (888) 825-4157 as soon as possible.\")</script>";
	  ## print "<script> window.history.go(-1)</script>";
       }		
	 }

     if ( $amProgramIs =~ /QCPN/i ) {
        $lockoutQCPN++;
       if ( $lockoutQCPN ){
          print "<script>alert(\"$amPhName\\nAction is Required - According to our records, we did not\\nreceive your required Monthly Employee Verification Form.\\n\\nIn order for us to perform the required monthly OIG and GSA\\nexclusion database checks as mandated by CMS, your\\npharmacy will need to fax your Monthly Employee\\nVerification Form to QCPN at (855) 998-4954 as soon as possible.\")</script>";
	  ## print "<script> window.history.go(-1)</script>";
       }     
	 }
  }
  
  $sthxAM->finish();
  
  return ($lockoutCIPN, $lockoutRBS, $lockoutQCPN);
  
}

sub readPharmaciesTermed {

  my ($INNCPDP) = @_;

  ##my $debug++;
  ##my $incdebug++;

  print "<hr>sub readPharmacies: Entry. NoTest: $NoTest, PROGRAM: $PROGRAM, INNCPDP: $INNCPDP<br>\n" if ( $incdebug );
  
  $RBSPharmaciesCount   = 0;
  $ReconPharmaciesCount = 0;

  my $dbin    = "PHDBNAME";
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $TABLE_COO = 'pharmacy_coo';
  my $tbl_arch  = 'pharmacy_archive';
  my $PHARM_FIELDS = ' 
                      Pharmacy_ID, Pharmacy_Name, Legal_Name, NPI, LPAD(NCPDP,7,"0") as NCPDP, Business_Phone, Address, City, State, Zip, County, Monthly_Charge, Status, Affiliate_Name, Affiliate_Customer_ID, Software_Vendor,
	              Current_PSAO, Chain, Email_Address, Fax_Number, State_Permit_Number, State_Permit_Expiration_Date, PIC_License_Number, PIC_License_Expiration_Date, Medicare_Part_B_ID_PTAN, ReconRx_Account_Manager,
	              Medicaid_Primary_Num, Medicaid_Primary_State, Pharmacy_with_24Hour_Service, Mail_Service_Pharmacy, Compounding_Pharmacy, ePrescribing_Capabilities, Comm_Pref, Contracted_to_Distribute_Under_340B, Website_Mgmt,
           	      RBS_Fee, CIPN_Fee, ReconRx_Clinic_Fee, ReconRx_Fee, Cred_Fee, Type, FEIN, DEA, DEA_Expiration, Liability_Ins_Policy_Number, Liability_Ins_Expiration_Date, State_Controlled_Substance_License,
	              State_Controlled_Substance_License_Exp_Date, Last_Onsite_Visit_Date, Status_RBS, Active_Date_RBS, Term_Date_RBS, Status_RBS_Direct, Active_Date_RBS_Direct, Term_Date_RBS_Direct, Status_ReconRx_Clinic, Status_Cred,
		      Status_RedeemRx, Active_Date_ReconRx_Clinic, Term_Date_ReconRx_Clinic, Status_ReconRx, Active_Date_ReconRx, Term_Date_ReconRx, Active_Date_Cred, Term_Date_Cred, Active_Date_RedeemRx, Term_Date_RedeemRx, Status_CIPN,
		      Active_Date_CIPN, Term_Date_CIPN, Status_CIPN_Direct, Active_Date_CIPN_Direct, Term_Date_CIPN_Direct, Active_Date, Term_Date, Status_TDS, Active_Date_TDS, Term_Date_TDS, RBSReporting,
		      FluVaccineMarketProgram, FVMPInvoiceMonth, EOY_Report_Date, Single_Pay, PQS, PQS_Fee, Rural, Store_User, Store_Pass, CIPN_Plus, Active_Date_CIPN_Plus, CentralPay835, CentralPayOrg, Hours_Sunday, Hours_Monday, 
		      Hours_Tuesday, Hours_Wednesday, Hours_Thursday, Hours_Friday, Hours_Saturday, Inactivate_Date, LTC, Wants835Files, Status_VacOnly, Active_Date_VacOnly, Term_Date_VacOnly, Status_DefaultCash, 
		      Active_Date_DefaultCash, Term_Date_DefaultCash, Status_Special_Programs, Active_Date_Special_Programs, Term_Date_Special_Programs, Status_ReconRx_SP, Active_Date_ReconRx_SP, Term_Date_ReconRx_SP, 
		      cipn_insurance_carrier, cipn_insurance_aggregate, cipn_insurance_amount_per, CMEA_Certification_Number, CMEA_Certification_Expiration_Date, AdvCred, Arete_Type, Display_ESI, Pharmacy_Data_Feed, Auto_PostPayment
                    ';

  #______________________________________________________________________________
  
  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
     { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  
  DBI->trace(1) if ($dbitrace);
  my $sql = qq# SELECT * FROM (
		SELECT $PHARM_FIELDS, 'ARCH' as 'tbl' 
                FROM   $DBNAME.$tbl_arch
	   ) a
		WHERE 1=1
  #;
  
  if ( $INNCPDP ) {
     $sql .= " && NCPDP=$INNCPDP";
  }

  if ( $NoTest ) {
    $sql .= " && NCPDP!=1111111 && NCPDP!=2222222 && NCPDP!=3333333 && NCPDP!=9879879";
  }

  $sql .= " ORDER BY NCPDP, tbl desc ";
  
  print "sql:<br><pre>$sql</pre><br>\n" if ($incdebug);
  
  my $sthx  = $dbm->prepare("$sql");
  $sthx->execute;
  
  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);
  
  push(@OPTSPharmacies, "All");
  
  while ( my @row = $sthx->fetchrow_array() ) {
  
    my ($Pharmacy_ID, $Pharmacy_Name, $Legal_Name, $jNPI, $jNCPDP, $Business_Phone, $Address, $City, $State, $Zip, $County, $Monthly_Charge, $Status, $Affiliate_Name, $Affiliate_Customer_ID, $Software_Vendor, 
	$Current_PSAO, $Chain, $Email_Address, $Fax_Number, $State_Permit_Number, $State_Permit_Expiration_Date, $PIC_License_Number, $PIC_License_Expiration_Date, $Medicare_Part_B_ID_PTAN, $ReconRx_Account_Manager, $Medicaid_Primary_Num, 
        $Medicaid_Primary_State, $Pharmacy_with_24Hour_Service, $Mail_Service_Pharmacy, $Compounding_Pharmacy, $ePrescribing_Capabilities, $Comm_Pref, $Contracted_to_Distribute_Under_340B, $Website_Mgmt, $RBS_Fee, $CIPN_Fee, $ReconRx_Clinic_Fee, 
        $ReconRx_Fee, $Cred_Fee, $Type, $FEIN, $DEA, $DEA_Expiration, $Liability_Ins_Policy_Number, $Liability_Ins_Expiration_Date, $State_Controlled_Substance_License, 
        $State_Controlled_Substance_License_Exp_Date, $Last_Onsite_Visit_Date, $Status_RBS, $Active_Date_RBS, $Term_Date_RBS, $Status_RBS_Direct, $Active_Date_RBS_Direct, $Term_Date_RBS_Direct, $Status_ReconRx_Clinic, $Status_Cred, $Status_RedeemRx, 
        $Active_Date_ReconRx_Clinic, $Term_Date_ReconRx_Clinic, $Status_ReconRx, $Active_Date_ReconRx, $Term_Date_ReconRx, $Active_Date_Cred, $Term_Date_Cred, $Active_Date_RedeemRx, $Term_Date_RedeemRx,
        $Status_CIPN, $Active_Date_CIPN, $Term_Date_CIPN, $Status_CIPN_Direct, $Active_Date_CIPN_Direct, $Term_Date_CIPN_Direct, $Active_Date, $Term_Date, $Status_TDS, $Active_Date_TDS, $Term_Date_TDS, $RBSReporting, $FluVaccineMarketProgram, $FVMPInvoiceMonth,
        $EOY_Report_Date, $Single_Pay, $PQS, $PQS_Fee, $Rural, $Store_User, $Store_Pass, $CIPN_Plus, $Active_Date_CIPN_Plus, $CentralPay835, $CentralPayOrg,
        $Hours_Sunday,$Hours_Monday,$Hours_Tuesday,$Hours_Wednesday,$Hours_Thursday,$Hours_Friday,$Hours_Saturday, $Inactivate_Date, $LTC, $Wants835Files,
        $Status_VacOnly, $Active_Date_VacOnly, $Term_Date_VacOnly, $Status_DefaultCash, $Active_Date_DefaultCash, $Term_Date_DefaultCash, $Status_Special_Programs, $Active_Date_Special_Programs, $Term_Date_Special_Programs,
	$Status_ReconRx_SP, $Active_Date_ReconRx_SP, $Term_Date_ReconRx_SP, $cipn_insurance_carrier, $cipn_insurance_aggregate, $cipn_insurance_amount_per, $CMEA_Certification_Number, $CMEA_Certification_Expiration_Date, $AdvCred,
	$Arete_Type, $Display_ESI, $Data_Feed, $Auto_PostPayment, $Pharmacy_tbl
     ) = @row;
  
    $Pharmacy_IDs{$Pharmacy_ID}++;
    $Pharmacy_PROGRAM{$Pharmacy_ID}         = $PROGRAM;
    $Pharmacy_Names{$Pharmacy_ID}           = $Pharmacy_Name;
    $Pharmacy_Legal_Names{$Pharmacy_ID}     = $Legal_Name;
    $Pharmacy_NPIs{$Pharmacy_ID}            = $jNPI;
    $Pharmacy_NCPDPs{$Pharmacy_ID}          = $jNCPDP;
    $Pharmacy_Store_User{$Pharmacy_ID}      = $Store_User;
  
    $Pharmacy_Store_Pass{$Pharmacy_ID}      = $Store_Pass;
  
    $Pharmacy_Comm_Prefs{$Pharmacy_ID}      = $Comm_Pref;
    $Pharmacy_Software_Vendors{$Pharmacy_ID}= $Software_Vendor;
    $Pharmacy_Current_PSAOs{$Pharmacy_ID}   = $Current_PSAO;
    $Pharmacy_Business_Phones{$Pharmacy_ID} = $Business_Phone;
    $Pharmacy_Addresses{$Pharmacy_ID}       = $Address;
    $Pharmacy_Citys{$Pharmacy_ID}           = $City;
    $Pharmacy_States{$Pharmacy_ID}          = $State;
    $Pharmacy_Zips{$Pharmacy_ID}            = $Zip;
    $Pharmacy_Countys{$Pharmacy_ID}         = $County;
    $Pharmacy_Monthly_Charges{$Pharmacy_ID} = $Monthly_Charge;
    $Pharmacy_Statuses{$Pharmacy_ID}        = $Status;
    $Pharmacy_Affiliate_Names{$Pharmacy_ID} = $Affiliate_Name;
    $Pharmacy_Affiliate_Customer_IDs{$Pharmacy_ID} = $Affiliate_Customer_ID;
    $Pharmacy_Chains{$Pharmacy_ID}          = $Chain;
    $Pharmacy_RBS_Fees{$Pharmacy_ID}        = $RBS_Fee;
    $Pharmacy_CIPN_Fees{$Pharmacy_ID}       = $CIPN_Fee;
    $Pharmacy_Cred_Fees{$Pharmacy_ID}       = $Cred_Fee;
    $Pharmacy_ReconRx_Clinic_Fees{$Pharmacy_ID}= $ReconRx_Clinic_Fee;
    $Pharmacy_ReconRx_Fees{$Pharmacy_ID}    = $ReconRx_Fee;
    $Pharmacy_AdvCred{$Pharmacy_ID}         = $AdvCred;
    $Pharmacy_Auto_PostPayments{$Pharmacy_ID}  = $Auto_PostPayment;
  
    $Pharmacy_Types{$Pharmacy_ID}           .= $Type if ( $Pharmacy_Types{$Pharmacy_ID} !~ /$Type/i );
    
    $Pharmacy_ReconRx_Account_Managers{$Pharmacy_ID}            = $ReconRx_Account_Manager;
 
    $Pharmacy_Email_Address{$Pharmacy_ID}                       = $Email_Address;
    $Pharmacy_Fax_Number{$Pharmacy_ID}                          = $Fax_Number;
    $Pharmacy_Medicare_Part_B_ID_PTAN{$Pharmacy_ID}             = $Medicare_Part_B_ID_PTAN;
    $Pharmacy_Medicaid_Primary_Num{$Pharmacy_ID}                = $Medicaid_Primary_Num;
    $Pharmacy_Medicaid_Primary_State{$Pharmacy_ID}              = $Medicaid_Primary_State;
    $Pharmacy_Pharmacy_with_24Hour_Service{$Pharmacy_ID}        = $Pharmacy_with_24Hour_Service;
    $Pharmacy_Mail_Service_Pharmacy{$Pharmacy_ID}               = $Mail_Service_Pharmacy;
    $Pharmacy_Compounding_Pharmacy{$Pharmacy_ID}                = $Compounding_Pharmacy;
    $Pharmacy_ePrescribing_Capabilities{$Pharmacy_ID}           = $ePrescribing_Capabilities;
    $Pharmacy_Contracted_to_Distribute_Under_340B{$Pharmacy_ID} = $Contracted_to_Distribute_Under_340B;
    $Pharmacy_FEINs{$Pharmacy_ID}                               = $FEIN;
    $Pharmacy_Website_Mgmt{$Pharmacy_ID}                        = $Website_Mgmt;
    $Pharmacy_Last_Onsite_Visit_Dates{$Pharmacy_ID}             = $Last_Onsite_Visit_Date;
    $Pharmacy_RBSReporting{$Pharmacy_ID}                        = $RBSReporting;
    $Pharmacy_FluVaccineMarketProgram{$Pharmacy_ID}             = $FluVaccineMarketProgram;
    $Pharmacy_FVMPInvoiceMonth{$Pharmacy_ID}                    = $FVMPInvoiceMonth;
    $Pharmacy_EOY_Report_Dates{$Pharmacy_ID}                    = $EOY_Report_Date;
    $Pharmacy_Single_Pays{$Pharmacy_ID}                         = $Single_Pay;

    $Pharmacy_DEA{$Pharmacy_ID}                                 = $DEA;
    $Pharmacy_DEA_Expiration{$Pharmacy_ID}                      = $DEA_Expiration;
    $Pharmacy_Liability_Ins_Policy_Number{$Pharmacy_ID}         = $Liability_Ins_Policy_Number;
    $Pharmacy_Liability_Ins_Expiration_Date{$Pharmacy_ID}       = $Liability_Ins_Expiration_Date;
    $Pharmacy_PIC_License_Number{$Pharmacy_ID}                  = $PIC_License_Number;
    $Pharmacy_PIC_License_Expiration_Date{$Pharmacy_ID}         = $PIC_License_Expiration_Date;
    $Pharmacy_State_Permit_Number{$Pharmacy_ID}                 = $State_Permit_Number;
    $Pharmacy_State_Permit_Expiration_Date{$Pharmacy_ID}        = $State_Permit_Expiration_Date;
    $Pharmacy_State_Controlled_Substance_License{$Pharmacy_ID}  = $State_Controlled_Substance_License;
    $Pharmacy_State_Controlled_Substance_License_Exp_Date{$Pharmacy_ID}= $State_Controlled_Substance_License_Exp_Date;
  
    $Pharmacy_Status_RBSs{$Pharmacy_ID}                    = $Status_RBS;
    $Pharmacy_Status_RBS_Directs{$Pharmacy_ID}             = $Status_RBS_Direct;
    $Pharmacy_Status_ReconRx_Clinics{$Pharmacy_ID}         = $Status_ReconRx_Clinic;
    $Pharmacy_Status_ReconRxs{$Pharmacy_ID}                = $Status_ReconRx;
    $Pharmacy_Status_Creds{$Pharmacy_ID}                   = $Status_Cred;
    $Pharmacy_Status_RedeemRxs{$Pharmacy_ID}               = $Status_RedeemRx;
    $Pharmacy_Status_CIPNs{$Pharmacy_ID}                   = $Status_CIPN;
    $Pharmacy_Status_CIPN_Directs{$Pharmacy_ID}            = $Status_CIPN_Direct;
    $Pharmacy_Status_VacOnlys{$Pharmacy_ID}                = $Status_VacOnly;
    $Pharmacy_Status_DefaultCashs{$Pharmacy_ID}            = $Status_DefaultCash;
    $Pharmacy_Status_Special_Programss{$Pharmacy_ID}       = $Status_Special_Programs;
    $Pharmacy_Status_ReconRx_SPs{$Pharmacy_ID}             = $Status_ReconRx_SP;
    $Pharmacy_Status_TDSs{$Pharmacy_ID}                    = $Status_TDS;
 
    $Pharmacy_Active_Dates{$Pharmacy_ID}                   = $Active_Date;
    $Pharmacy_Active_Date_RBSs{$Pharmacy_ID}               = $Active_Date_RBS;
    $Pharmacy_Active_Date_RBS_Directs{$Pharmacy_ID}        = $Active_Date_RBS_Direct;
    $Pharmacy_Active_Date_ReconRx_Clinics{$Pharmacy_ID}    = $Active_Date_ReconRx_Clinic;
    $Pharmacy_Active_Date_ReconRxs{$Pharmacy_ID}           = $Active_Date_ReconRx;
    $Pharmacy_Active_Date_Creds{$Pharmacy_ID}              = $Active_Date_Cred;
    $Pharmacy_Active_Date_RedeemRxs{$Pharmacy_ID}          = $Active_Date_RedeemRx;
    $Pharmacy_Active_Date_CIPNs{$Pharmacy_ID}              = $Active_Date_CIPN;
    $Pharmacy_Active_Date_CIPN_Directs{$Pharmacy_ID}       = $Active_Date_CIPN_Direct;
    $Pharmacy_Active_Date_VacOnlys{$Pharmacy_ID}           = $Active_Date_VacOnly;
    $Pharmacy_Active_Date_DefaultCashs{$Pharmacy_ID}       = $Active_Date_DefaultCash;
    $Pharmacy_Active_Date_Special_Programss{$Pharmacy_ID}  = $Active_Date_Special_Programs;
    $Pharmacy_Active_Date_ReconRx_SPs{$Pharmacy_ID}        = $Active_Date_ReconRx_SP;
    $Pharmacy_Active_Date_TDSs{$Pharmacy_ID}               = $Active_Date_TDS;

    $Pharmacy_Term_Dates{$Pharmacy_ID}                     = $Term_Date;
    $Pharmacy_Term_Date_RBSs{$Pharmacy_ID}                 = $Term_Date_RBS;
    $Pharmacy_Term_Date_RBS_Directs{$Pharmacy_ID}          = $Term_Date_RBS_Direct;
    $Pharmacy_Term_Date_ReconRx_Clinics{$Pharmacy_ID}      = $Term_Date_ReconRx_Clinic;
    $Pharmacy_Term_Date_ReconRxs{$Pharmacy_ID}             = $Term_Date_ReconRx;
    $Pharmacy_Term_Date_Creds{$Pharmacy_ID}                = $Term_Date_Cred;
    $Pharmacy_Term_Date_RedeemRxs{$Pharmacy_ID}            = $Term_Date_RedeemRx;
    $Pharmacy_Term_Date_CIPNs{$Pharmacy_ID}                = $Term_Date_CIPN;
    $Pharmacy_Term_Date_CIPN_Directs{$Pharmacy_ID}         = $Term_Date_CIPN_Direct;
    $Pharmacy_Term_Date_VacOnlys{$Pharmacy_ID}             = $Term_Date_VacOnly;
    $Pharmacy_Term_Date_DefaultCashs{$Pharmacy_ID}         = $Term_Date_DefaultCash;
    $Pharmacy_Term_Date_Special_Programss{$Pharmacy_ID}    = $Term_Date_Special_Programs;
    $Pharmacy_Term_Date_ReconRx_SPs{$Pharmacy_ID}          = $Term_Date_ReconRx_SP;
    $Pharmacy_Term_Date_TDSs{$Pharmacy_ID}                 = $Term_Date_TDS;

    $Pharmacy_PQSs{$Pharmacy_ID}                           = $PQS;
    $Pharmacy_PQS_Fees{$Pharmacy_ID}                       = $PQS_Fee;

    $Pharmacy_Rurals{$Pharmacy_ID}                         = $Rural;
  
    $Pharmacy_CIPN_Plus{$Pharmacy_ID}                      = $CIPN_Plus;
    $Pharmacy_Active_Date_CIPN_Plus{$Pharmacy_ID}          = $Active_Date_CIPN_Plus;
    $Pharmacy_Term_Date_CIPN_Plus{$Pharmacy_ID}            = $Term_Date_CIPN_Plus;

    $Pharmacy_CentralPay835s{$Pharmacy_ID}                 = $CentralPay835;
    $Pharmacy_CentralPayOrgs{$Pharmacy_ID}                 = $CentralPayOrg;

    $Pharmacy_Hours_Sunday{$Pharmacy_ID}                   = $Hours_Sunday;
    $Pharmacy_Hours_Monday{$Pharmacy_ID}                   = $Hours_Monday;
    $Pharmacy_Hours_Tuesday{$Pharmacy_ID}                  = $Hours_Tuesday;
    $Pharmacy_Hours_Wednesday{$Pharmacy_ID}                = $Hours_Wednesday;
    $Pharmacy_Hours_Thursday{$Pharmacy_ID}                 = $Hours_Thursday;
    $Pharmacy_Hours_Friday{$Pharmacy_ID}                   = $Hours_Friday;
    $Pharmacy_Hours_Saturday{$Pharmacy_ID}                 = $Hours_Saturday;
    $Pharmacy_Inactivate_Date                              = $Inactivate_Date ;

    $Pharmacy_LTCs{$Pharmacy_ID}                           = $LTC;
    $Pharmacy_Wants835Files{$Pharmacy_ID}                  = $Wants835Files;

    $Pharmacy_cipn_insurance_carrier{$Pharmacy_ID}         = $cipn_insurance_carrier;
    $Pharmacy_cipn_insurance_aggregate{$Pharmacy_ID}       = $cipn_insurance_aggregate;
    $Pharmacy_cipn_insurance_amount_per{$Pharmacy_ID}      = $cipn_insurance_amount_per;
    $Pharmacy_CMEA_Certification_Number{$Pharmacy_ID}      = $CMEA_Certification_Number;
    $Pharmacy_CMEA_Expiration_Date{$Pharmacy_ID}           = $CMEA_Certification_Expiration_Date;
    $Pharmacy_Data_Feed{$Pharmacy_ID}                      = $Data_Feed;
  
    $Reverse_Pharmacy_NPIs{$jNPI}      = $Pharmacy_ID ;	# Reverse lookup for Interventions Search!
    $Reverse_Pharmacy_NCPDPs{$jNCPDP}  = $Pharmacy_ID ;	# Reverse lookup for Interventions Search!
#    $Reverse_Pharmacy_NCPDPs{$jNCPDP}  = $Pharmacy_ID;	# Reverse lookup for Interventions Search!

    $RBSPharmaciesCount++   if ( $Type =~ /RBS/i   && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $ReconPharmaciesCount++ if ( $Type =~ /Recon/i && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $QCPPharmaciesCount++   if ( $Type =~ /QCP/i   && $Status =~ /^Active$/i && $jNCPDP !~/1111111|2222222/ );
    $Pharmacy_Arete{$Pharmacy_ID}      = $Arete_Type if ($Arete_Type =~ /E|B/);
    $Pharmacy_DisplayESI{$Pharmacy_ID} = $Display_ESI;
  
  }
  $sthx->finish;
  $dbm->disconnect;
  
  foreach $id ( sort keys %Pharmacy_Names) {
    $name = $Pharmacy_Names{$id};
    $key  = "${id} - $name";
    push(@OPTSPharmacies, "$key");
    $HASHPharmacies{$key} = $name;
  }

  print "sub readPharmacies: Exit. RBSPharmaciesCount: $RBSPharmaciesCount, ReconPharmaciesCount: $ReconPharmaciesCount<br>\n" if ( $incdebug );
  print "<hr size=4 color=red noshade>\n" if ( $incdebug );

}

sub load_tertiary_ndcs {
	
  my $db_cash = 'defaultcash';
  my $tbl_ndcs = 'hrgi_tertiary_ndcs';

  $sql = " SELECT NDC 
             FROM ${db_cash}.${tbl_ndcs}
         ";
  print "$sql\n";

  $sth     = $dbx->prepare("$sql");
  $row_cnt = $sth->execute;

  while  (($ndc) = $sth->fetchrow()) {
    $tert_ndcs{$ndc}++;
  }
}

sub load_340B_pharmacies {

  my $db_ncpdp     = 'ncpdp';
  my $tbl_services = 'servicesoffered';
  my $tbl_provider = 'provider';
  my $tbl_taxonomy = 'taxonomy';

  $sql = " SELECT b.NCPDPProviderID, b.NationalProviderId 
             FROM ${db_ncpdp}.${tbl_services} a
             JOIN ${db_ncpdp}.${tbl_provider} b on a.NCPDPProviderID = b.NCPDPProviderID
 	    WHERE 340bStatusCode IN (38,39)
              AND 340Bstatusindicator = 'Y'
         ";
  print "$sql\n";

  $sth     = $dbx->prepare("$sql");
  $row_cnt = $sth->execute;

  while  (($ncp, $npi) = $sth->fetchrow()) {
    $pharmacies_340B{$ncp}++;
    $pharmaciesNPI_340B{$npi}++;
  }
}

sub load_LTC_pharmacies {
  my $db_ncpdp     = 'ncpdp';
  my $tbl_provider = 'provider';
  my $tbl_taxonomy = 'taxonomy';

  $sql = " SELECT b.NCPDPProviderID, b.NationalProviderId 
             FROM ${db_ncpdp}.${tbl_taxonomy} a
             LEFT JOIN ${db_ncpdp}.${tbl_provider} b on a.NCPDPProviderID = b.NCPDPProviderID
             WHERE  TaxonomyCode = '3336L0003X'
            
         ";
  print "$sql\n";

  $sth     = $dbx->prepare("$sql");
  $row_cnt = $sth->execute;

  while  (($ncp, $npi) = $sth->fetchrow()) {
    $pharmacies_LTC{$ncp}++;
    $pharmaciesNPI_LTC{$npi}++;
  }
}

sub load_pharmacy_ctl {

  my $tbl_pharmacy_ctl = 'pharmacy_ctl';
  my $db_office = 'officedb';

  $sql = " SELECT PharmacyID, upload835, EOBConversion, populate_NM_835 
             FROM $db_office.$tbl_pharmacy_ctl
         ";
  #  print "sql:$sql\n";

  $sth  = $dbx->prepare("$sql");
  $sth->execute;

  while ( my @row = $sth->fetchrow_array() ) {
     my ($PID, $upload, $eob, $nm) = @row;
     $Pharmacy_Upload835{$PID} = "$upload";
     $Pharmacy_EOBConversion{$PID} = "$eob";
     $Pharmacy_PopulateNM{$PID} = "$nm";
  }
}

sub add_email_sig {
  my $ram     = shift @_;
  my $user    = shift @_;
  my $display = shift @_;
  my $sig_loc   = "cid:Outcomes_ReconRx_sig.png";
  $sig_loc   = "../images/Outcomes_ReconRx_sig.png" if ( $display =~ /Web/i );

  @pcs = split(/\,\s/, $ram);
  $sig_name = "$pcs[1] $pcs[0]";
  $sig_email = $EMAILACCT{$user};
  $sig_title = $EMAIL_SIG_TITLE{$user};

  my $sig .= "<p>Thank You,</p><table>
                <tr>
                  <td style='background:white;padding:0in 6.0pt 0in 6.0pt'>
                    <b><span style='font-size:12.0pt;color:#002060;text-transform:uppercase'>$sig_name</span></b><br>
                    <span style='color:#002060;text-transform:uppercase'>$sig_title<br></span>
                  </td>
                <tr>
                  <td>
                    <img border=0 width=315 height=36 src='$sig_loc' align=left hspace=12>
                  </td>
                </tr>
                <tr>
                  <td style='background:white;padding:0in 1.0pt 0in 1.0pt'>
                    <span style='color:blue'><a href='mailto:$sig_email'>$sig_email</a></span></br>
                    <span style='color:#002060;text-transform:uppercase'>TEL: (888) 255-6526</span></br>
                    <a href='http://www.outcomes.com/'><span style='color:#767171;text-transform:uppercase'>Outcomes.com</span></a></br>
                    <p class=MsoNormal style='mso-margin-top-alt:auto;line-height:105%'>
                      <span style='font-size:9.0pt;line-height:105%;color:#767171'>
                        The information contained in this transmission may contain privileged and confidential information, including patient information protected by federal and state privacy laws. It is intended only for the use of the person(s) named above. If you are not the intended recipient, you are hereby notified that any review, dissemination, distribution, or duplication of this communication is strictly prohibited. If you are not the intended recipient, please contact the sender by reply email and destroy all copies of the original message.
                      </span>
                    </p>
                  </td>
                </tr>
              </table>";
  return $sig
}

sub login_rpt_ctl {
   my $db_office = 'officedb';
   my $tbl_webrpt_ctl = 'weblogin_report_ctl';

  my $dbm = DBI->connect("DBI:mysql:$db_office:$DBHOST",$dbuser,$dbpwd,
     { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  
  DBI->trace(1) if ($dbitrace);

   $sql = "SELECT weblogin_ID, Copay_Report, NRID_Report FROM $db_office.$tbl_webrpt_ctl";
   $sthx = $dbm->prepare($sql);
   $sthx->execute();

  while (($webid,$cp, $nrid) = $sthx->fetchrow_array) {
    $copay_rpt{$webid} = $cp;
    $nrid_rpt{$webid} = $nrid;
  }  
  $sthx->finish;
  $dbm->disconnect;
}  

#_______________________________________________________________________________
#_______________________________________________________________________________

1;	# Required for a Perl include file
