#______________________________________________________________________________
#
# Date: 01/29/2014
# Mods: Daily. :-)
# Mods: MM/DD/YYYY. Comment
#______________________________________________________________________________
# RBSReporting_routines.pl
#______________________________________________________________________________
$incdebug = 0;   # set to 1 for seeing debug output for these routines

$|++;                            #sets $| for STDOUT
my $old_handle = select( STDERR );  #change to STDERR
$|++;                            #sets $| for STDERR
select( $old_handle );           #change back to STDOUT
open(STDERR, ">&STDOUT") || die "Can't dup stdout\n\t$!\n\n";

$dbTCodes = " 'RVL', 'PDR', 'RNM', 'DUP', 'PDUP', 'PDR TSP', 'OTC', 'DEL' ";
#$dbTCodes = " 'RVL' ";

($dbTCodesList = $dbTCodes) =~ s/, /\|/g;
$dbTCodesList =~ s/'//g;


#______________________________________________________________________________
#______________________________________________________________________________

sub Get_RBSReporting_Data {
  my ($NCPDP, $StartDate, $EndDate, $Detail, $RebateBrand, $RebateGeneric, $NPIstring, $ExcBINstring, $TDS) = @_;

  my %cob;
  my %tap;
  my %ic;
  my %icp;
  my %pct;
  my %mpf;
  my %ttr;
  my %record;
  my %bn;
  my %pcn;
  my %gid;
  my $dbin;

  if ( $incdebug ) {
     print "-"x96, "<br>\n";
     print "sub Get_RBSReporting_Data. Entry. NCPDP: $NCPDP, StartDate: $StartDate, EndDate: $EndDate, Detail: $Detail, RebateBrand: $RebateBrand, RebateGeneric: $RebateGeneric<br>\n  NPIstring: $NPIstring<br>  ExcBINstring: $ExcBINstring<br> <br>\n";
     print "$prog: dbTCodes: $dbTCodes<hr>\n\n" if ($incdebug);
     print "DOPHARMACY($NCPDP): $DOPHARMACY{$NCPP}<hr>\n";

  }
  print "testing: $testing<br>\n" if ($debug || $incdebug || $testing);

  my ( %RxNumbers, %FillNumbers, %BGs, %SALEs, %COSTs, %BinNumbers, %DBs,
       %CASHorTPPs, %GMs, %salecalcs, %costcalcs, %DOSs, %DateTransmitteds,
       %PCNs, %Groups, %NDCs, %TCodes, %Quantity, %DaysSupply, 
       %RCOSTs, %RGMs, %PBMs, %PAI_Payer_Names, %Comm_MedD_Medicaids, 
       %PrescriberIDs, %CashFlags);

  my ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
       $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
       $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost, $TotalIngredientCost);
     
  # Load data lookup hashes on first run only
  # ---------------------------------------------------------------- #
  
  if ( !$rebatesLoaded || $rebatesLoaded != $NCPDP ) {
    &loadRebateLookup($NCPDP);
  }
  if( !$plansLoaded || $plansLoaded <= 0 ) {
    if ($TDS && $TDS =~ /^Y/i) {
      &loadPlanLookupBasic;
    }
    else {
      &loadPlanLookup;
    }    
  }

  # ---------------------------------------------------------------- #

  if ( $incdebug) {
     print "NPIstring   : $NPIstring<br>\n";
     print "ExcBINstring: $ExcBINstring<br>\n";
  }

  if ( $NPIstring =~ /^\s*$/ ) {
    $doPrescriberID = qq##;
  } else {
    $doPrescriberID = qq# && dbPrescriberID in($NPIstring) #;
  }
  print "<hr>doPrescriberID: $doPrescriberID<hr><br>\n" if ($incdebug);
  #-------------

  if ( $ExcBINstring =~ /^\s*$/ ) {
    $ExcBINs = qq##;
  } else {
    $ExcBINs = qq# && dbBinNumber NOT in($ExcBINstring) #;
  }
  print "<hr>ExcBINs: $ExcBINs<hr><br>\n" if ($incdebug);
  #-------------

  if ($TDS && $TDS =~ /^Y/i) {
    $dbin = "TDDBNAME";
  }
  else {  
    $dbin = "RRDBNAME";
  }

  if ( $testing ) {

    print "\n\n\n FATAL: FIX ME!!!!!!!!!!!!!!!!!!!!!!!! \n\n\n<br>\n";
  
    ########################################
    # BEG - TESTING SECTION SETUP
    ########################################
    
    # Comment out this block when done testing!!!!!
    
      $JJJ = $DBNAMES{$dbin}; print "JJJ: $JJJ<br>\n";
    
      $WHICHDB = "testing";		# Valid Values: "Testing" or "Webinar"
      &set_Webinar_or_Testing_DBNames;
      if ( $DBNAMES{$dbin} =~ /^\s*$/ ) {
         $DBNAMES{$dbin} = $JJJ;
         print qq#Found dbin's ($dbin) DBNAME was blank. Setting to "testing"<br>\n# if ($debug || $testing);
      } else {
      }
    
      $HHH = $DBNAMES{$dbin}; print "HHH: $HHH<br>\n";
    
    ########################################
    # END - TESTING SECTION SETUP
    ########################################
  
  }

  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  $DBNAME = 'Webinar' if($USER == 2182);

  $Pharmacy_Name  = "";
  $SoftwareVendor = "";
  $PrimarySwitch  = "";

  #-------------------------------------------------------------
  
  if ( !$PharmacyWanted ) {
     $PharmacyWanted = $NCPDP;
  }
  if ( !$NCPDP ) {
     $NCPDP = $PharmacyWanted;
  }
  print "<hr>J 2. NCPDP: $NCPDP, PharmacyWanted: $PharmacyWanted, DOPHARMACY($PharmacyWanted): $DOPHARMACY{$PharmacyWanted}<br>\n" if ($debug);

  if ( $GRRD_Pharmacy_Name && $DOPHARMACY{$PharmacyWanted} > 1 ) {

#    $Pharmacy_Name  = $GRRD_Pharmacy_Name;
#    $SoftwareVendor = $GRRD_SoftwareVendor;
#    $PrimarySwitch  = $GRRD_PrimarySwitch;

    print "Skipping DB Query. Using GRRD vars. GRRD_Pharmacy_Name: $GRRD_Pharmacy_Name, GRRD_SoftwareVendor: $GRRD_SoftwareVendor, GRRD_PrimarySwitch: $GRRD_PrimarySwitch<hr>\n" ;#if ($debug || $incdebug);

  } else {

    my $sql = "";
    $sql = qq#
SELECT Pharmacy_Name, Software_Vendor, Primary_Switch
FROM OfficeDB.Pharmacy 
WHERE NCPDP = $NCPDP
#;
    (my $sqlout = $sql) =~ s/\n/<br>\n/g;
    print "1. sql:<br>$sqlout<br>\n" if ($testing || $incdebug || $debug);

    my $sth22 = $dbx->prepare($sql);
    my $rowsfoundPharmacy = $sth22->execute;
    if ( $rowsfoundPharmacy =~ /^0|0E0/i ) {
      $rowsfoundPharmacy = 0;
    }
  
    my $Pharmacy_Name  = "";
    my $SoftwareVendor = "";
    my $PrimarySwitch  = "";
  
    if ( $rowsfoundPharmacy <= 0 ) {
      print "No Pharmacy Rows Found<br>\n";
    } else {
      print "#"x96,"<br>\n" if ($incdebug);
      while ( my @row = $sth22->fetchrow_array() ) {
        ($Pharmacy_Name, $SoftwareVendor, $PrimarySwitch) = @row;
      }
      $sth22->finish;
      print "Setting GRRD variables<br>\n" if ($debug);
      $GRRD_Pharmacy_Name  = $Pharmacy_Name;
      $GRRD_SoftwareVendor = $SoftwareVendor;
      $GRRD_PrimarySwitch  = $PrimarySwitch;
    }

  }
  $Pharmacy_Name  = $GRRD_Pharmacy_Name;
  $SoftwareVendor = $GRRD_SoftwareVendor;
  $PrimarySwitch  = $GRRD_PrimarySwitch;

  if ( $debug ) {
#    print "<hr><br>Using:<br>\n";
     print "<hr>\n";
     print "<table border=1 width=100%>\n";
     print "<tr><td width=50%>Pharmacy_Name </td><td>  $Pharmacy_Name</td></tr>\n";
     print "<tr><td width=50%>SoftwareVendor</td><td>  $SoftwareVendor</td></tr>\n";
     print "<tr><td>PrimarySwitch </td><td>  $PrimarySwitch\n</td></tr>";
     print "</table>\n";
  }

  #-------------------------------------------------------------

  $FIELDS = qq# dbNCPDPNumber, dbBinNumber, dbBinParentdbkey, dbRxNumber, dbFillNumber, dbDateOfService, dbMediSpanBrandOrGeneric, dbBrandOrGeneric, dbParishCountyTax, dbMedicaidProviderFee, dbPatientPayAmount, dbPatientPayAmountPaid, dbIngredientCost, dbIngredientCostPaid, dbGrossAmountDue, dbDispensingFeePaid, dbTotalAmountPaid, dbUsualAndCustomaryCharge, dbSwVendor, dbPrescriberID, dbPrescriberLastName, dbNDC, dbTCode, dbDateTransmitted, dbProcessorControlNumber, dbGroupID, dbQuantityDispensed, dbDaysSupply, dbCompoundCode, dbOtherPayerCoverageType, dbCash, 340BFillFee, 340BType, Medispan_AWP, incomingtbID #;

  $sql = qq# 
SELECT $FIELDS, DB
FROM (
  SELECT $FIELDS, DB
  FROM ( 
    SELECT $FIELDS, 'RBSDATA' as DB
    FROM $DBNAME.$TABLE
    WHERE (1=1)#;
  
  if ( $Detail =~ /Rx/i ) {
    my @pcsx = split(/##/, $Detail);
    my $jNCPDP   = $pcsx[1];
    my $rxnumber = $pcsx[2];
    my $dosx     = $pcsx[3];
    my $fillnum  = $pcsx[4];
    #print "jNCPDP: $jNCPDP, rxnumber: $rxnumber, dosx: $dosx, fillnum: $fillnum<br>\n";
  
    $sql .= qq#
    && dbNCPDPNumber= $jNCPDP 
    && dbRxNumber   = $rxnumber#;
    if ( $fillnum =~ /^(0|[1-9][0-9]*)$/ ) {
      #If fillnum is numeric, us it
      $sql .= qq#
    && dbFillNumber = $fillnum#;
    } else {
      $sql .= qq#
    && dbDateOfService = $dosx#;
    }
  } else {
    $sql .= qq#
    && dbNCPDPNumber = $NCPDP#;
  }
  
  $sql .= qq#
    && dbDateTransmitted >= 0 
    && (dbDateOfService>=$StartDate && dbDateOfService<=$EndDate)#;
  $sql .= qq#
    $doPrescriberID# if ( $doPrescriberID );
  $sql .= qq#
    $ExcBINs#        if ( $ExcBINs );
  $sql .= qq#
  ) alldata
  WHERE (1=1)
  && (dbTCode = '' || dbTCode IS NULL)
  ORDER BY dbRxNumber, dbDateOfService, dbOtherPayerCoverageType asc
) filtered
  #;

  my $sqlout = "";
  if ( $ENV{"COMPUTERNAME"} =~ /$BATCHSERVERS/i ) {
     $sqlout = $sql;
  } else {
     ($sqlout = $sql) =~ s/\n/<br>\n/g;
  }

  if ( $testing ) {
     print "<br>\n", "-"x96, "<br>\n", "2. find sql:<br>\n$sqlout\n<br>\n", "-"x96, "\n<br>\n";
  } else {
     print "<hr>2. sql:<br>\n$sqlout<br>\n<hr><br>\n" if ($incdebug);
  }
  
  $TotalScriptCount    = 0;
  $BrandScriptCount    = 0;
  $GenericScriptCount  = 0;
  $UnknownScriptCount  = 0;

  $BrandDaySupplyCount   = 0;
  $GenericDaySupplyCount = 0;

  $TotalTotalRevenue   = 0;
  $BrandTotalRevenue   = 0;
  $GenericTotalRevenue = 0;
  $UnknownTotalRevenue = 0;

  $TotalTotalCost      = 0;
  $BrandTotalCost      = 0;
  $GenericTotalCost    = 0;
  $UnknownTotalCost    = 0;
  $TotalIngredientCost = 0;
  $IngredientTotalCost = 0;
  $Medispan_AWP        = 0;
  
  print "sth24: here!\n\n" if ($incdebug);
  my $sth24 = $dbx->prepare($sql);
  my $rowsfoundSelect = $sth24->execute;

  if ( $rowsfoundSelect =~ /^0|0E0/i ) {
     $rowsfoundSelect = 0;
  }

  if ( $rowsfoundSelect <= 0 ) {
   
    if ( $Detail =~ /Rx/i ) {
      $key = "0##0##0";
      $RxNumbers{$key}   = "NA";
      $FillNumbers{$key} = "NA";
      $BGs{$key}         = "NA";
      $SALEs{$key}       = "NA";
      $COSTs{$key}       = "NA";
      $BinNumbers{$key}  = "NA";
      $salecalcs{$key}   = "NA";
      $costcalcs{$key}   = "NA";
      $DBs{$key}         = "NA";
      $CASHorTPPs{$key}  = "NA";
      $GMs{$key}         = "NA";
      $DOSs{$key}        = "NA";
      $DateTransmitteds{$key} = "NA";
      $PCNs{$key}        = "NA";
      $Groups{$key}      = "NA";
      $NDCs{$key}        = "NA";
      $TCodes{$key}      = "NA";
      $Quantity{$key}    = "NA"; #Added 10/27/2014
      $DaysSupply{$key}  = "NA"; #Added 11/14/2014
      $RCOSTs{$key}      = "NA"; #Added 11/14/2014
      $RGMs{$key}        = "NA"; #Added 11/14/2014
      $PBMs{$key}        = "NA"; #Added 11/14/2014
      $PAI_Payer_Names{$key} = "NA"; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = "NA"; #Added 11/14/2014
      $PrescriberIDs{$key} = "NA"; #Added 05/20/2015
      $Medispan_AWPs{$key} = "NA"; #Added 05/20/2020
      $Incoming_IDs{$key}  = "NA"; #Added 06/18/2020
	  $CashFlags{$key} = "NA"; #Added 05/11/2018
    } else {
      print "No Rows Found for $NCPDP<br>\n";
    }
    
  } else {
    print "#"x96,"<br>\n" if ($incdebug);

    #Should stay default, unless any calculation exceptions are used.
    $using = "Default";

    #Start Per Claim Calculations

    my $jcnt = 0;

    while ( my @row = $sth24->fetchrow_array() ) {

      ($dbNCPDPNumber, $dbBinNumber, $dbBinParentdbkey, $dbRxNumber, $dbFillNumber, $dbDateOfService, $dbMediSpanBrandOrGeneric, $dbBrandOrGeneric, $dbParishCountyTax, $dbMedicaidProviderFee, $dbPatientPayAmount, $dbPatientPayAmountPaid, $dbIngredientCost, $dbIngredientCostPaid, $dbGrossAmountDue, $dbDispensingFeePaid, $dbTotalAmountPaid, $dbUsualAndCustomaryCharge, $dbSwVendor, $dbPrescriberID, $dbPrescriberLastName, $dbNDC, $dbTCode, $dbDateTransmitted, $dbProcessorControlNumber, $dbGroupID, $dbQuantityDispensed, $dbDaysSupply, $dbCompoundCode, $dbOtherPayerCoverageType, $dbCash, $BFillFee, $BType, $dbMedispan_AWP, $incoming_id, $DB) = @row;
      
      $jcnt++;
      printf ("%i) yo2. NCPDP: $dbNCPDPNumber, BIN: $dbBinNumber, PCN: $dbProcessorControlNumber, Group: $dbGroupID, Rx: $dbRxNumber\n", $jcnt) if ($incdebug);

      my $NOVALUE = -20000;
     
      #Zero out any unknown values
      #
      if ( $dbParishCountyTax         == $NOVALUE ) { $dbParishCountyTax         = 0; }
      if ( $dbMedicaidProviderFee     == $NOVALUE ) { $dbMedicaidProviderFee     = 0; }
      if ( $dbPatientPayAmountPaid    == $NOVALUE ) { $dbPatientPayAmountPaid    = 0; }
      if ( $dbPatientPayAmount        == $NOVALUE ) { $dbPatientPayAmount        = 0; }
      if ( $dbIngredientCost          == $NOVALUE ) { $dbIngredientCost          = 0; }
      if ( $dbIngredientCostPaid      == $NOVALUE ) { $dbIngredientCostPaid      = 0; }
      if ( $dbDispensingFeePaid       == $NOVALUE ) { $dbDispensingFeePaid       = 0; }
      if ( $dbGrossAmountDue          == $NOVALUE ) { $dbGrossAmountDue          = 0; }
      if ( $dbTotalAmountPaid         == $NOVALUE ) { $dbTotalAmountPaid         = 0; }
      if ( $dbUsualAndCustomaryCharge == $NOVALUE ) { $dbUsualAndCustomaryCharge = 0; }
      if ( $dbQuantityDispensed       == $NOVALUE ) { $dbQuantityDispensed       = 0; }
      if ( $dbIngredientCost          == 999999.99) { $dbIngredientCost          = 0; }
      if ( $dbMedispan_AWP            == $NOVALUE ) { $dbMedispan_AWP            = 0; }

      # do calculations on these values
       
      $salecalc  = "";
      $costcalc  = "";
      $CASHorTPP = "";
      $bg        = "";

      #Determine Brand/Generic
      if ( $dbMediSpanBrandOrGeneric !~ /^\s*$/ ) {
        $bg = $dbMediSpanBrandOrGeneric;
      } else {
        $bg = "";
      }
     
      #####################################################################################
      #Start Claim Filter
      #####################################################################################
     
      #Filter out Medicare Part B
      if ($dbBinNumber == 4766) {
        next;
      }
      
      #Filter out 'bogus' non-compound NDC values
      if ( $dbCompoundCode != 2 #NOT a compound
           && (
             $dbNDC <= 0 || 
             $dbNDC =~ /^00000/ || 
             $dbNDC =~ /^11111/ || 
             $dbNDC =~ /^22222/ || 
             $dbNDC =~ /^33333/ || 
             $dbNDC =~ /^44444/ || 
             $dbNDC =~ /^55555/ || 
             $dbNDC =~ /^66666/ || 
             $dbNDC =~ /^77777/ || 
             $dbNDC =~ /^88888/ || 
             $dbNDC =~ /^99999/ 
           )
         ) {
        next;
      }


      #This will capture the COB information needed for calculations && should get rid of duplicates
      next if $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0}{$dbOtherPayerCoverageType};
      if (!$cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
        $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbTotalAmountPaid;  
        if ( $BType =~ /Cash/i ) {
          $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = 0;  
	} else {
          $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbIngredientCost;  
        }
        $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbIngredientCostPaid;  
        $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbParishCountyTax;  
        $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbMedicaidProviderFee;  
        $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbBinNumber;  
        $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbProcessorControlNumber;  
        $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbGroupID;  
        $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} = $BType;  
        $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} = $BFillFee;  
        $awp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbMedispan_AWP;
        $TotalScriptCount++;

        #Brand/Generic Counts
        if      ( $bg =~ /B/i ) { 
          $BrandScriptCount++; 
          $BrandDaySupplyCount  += $dbDaysSupply;
        } elsif ( $bg =~ /G/i ) { 
          $GenericScriptCount++; 
          $GenericDaySupplyCount  += $dbDaysSupply;
        } else { 
          $UnknownScriptCount++; 
        }
      }

      $ISCASH = 0;
          
      if ($dbBinNumber == 14798 || $dbBinNumber == 0 || $dbBinNumber == 747474) {
        $ISCASH++;
      }

      ###Calculate revenue based on CASH or TPP sale


      if ( ($BType =~ /Cash/i) || ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} && $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i) ) {
#      if ( ($BType =~ /Cash/i) ) {
        $salecalc .= "CASH | ";
        $CASHorTPP = "CASH";
       
        if ( $cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} ) {
          $SALE = $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
          $salecalc .= "BFF : $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}";
	} else {
          $SALE = $BFillFee;
          $salecalc .= "BFF : $BFillFee";
	}
      }
      elsif ( $ISCASH ) {
        #CASH Sale, CASH determined by BIN Number (above)
           
        $salecalc .= "CASH | ";
        $CASHorTPP = "CASH";
       
        if ($SoftwareVendor =~ /ComputerRx/i ) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - ComputerRx: $dbPatientPayAmountPaid";
#            print "1. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
        } else {
          if        ( $dbGrossAmountDue  != 0 ) {
            $SALE = $dbGrossAmountDue;
            $salecalc .= "GAD: $dbGrossAmountDue";
            print "4. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } elsif ( $dbTotalAmountPaid != 0 ) {
            $SALE = $dbTotalAmountPaid;
            $salecalc .= "TAP: $dbTotalAmountPaid";
            print "5. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
#          } elsif ( $dbUsualAndCustomaryCharge != 0 ) {
#            $SALE = $dbUsualAndCustomaryCharge;
#            $salecalc .= "U&C: $dbUsualAndCustomaryCharge";
#            print "6. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } else {
            $SALE = $dbIngredientCostPaid;
            $salecalc .= "ICP: $dbIngredientCostPaid";
            print "7. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          }
        }
      
        if ($SoftwareVendor =~ /Pioneer/i ) {
          if ($dbProcessorControlNumber =~ /^CP$/i && $dbGroupID =~ /^95NONE$/i) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - CP Exception: $dbPatientPayAmountPaid";
            print "8. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } 
        }
        
      } else {
            
        #TPP Sale
     
        $salecalc .= "TPP | ";
        $CASHorTPP = "TPP";
           
        if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
          if ($dbSwVendor ne 'Rx30' && $dbOtherPayerCoverageType > 0 || $dbSwVendor eq 'Rx30' && $dbOtherPayerCoverageType == 0) { 
            if ( $tfb{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i ) {
              $dbTotalAmountPaid        = $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};   
	    } else { 
              $dbTotalAmountPaid        += $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};   
            }
            $dbIngredientCost         = $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
            $dbIngredientCostPaid     = $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
	    $dbParishCountyTax        = $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbBinNumber              = $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbProcessorControlNumber = $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbGroupID                = $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
	    $dbMedicaidProviderFee    = $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
          }
	  else {
            next;
	  }
        }


        if ( $dbSwVendor =~ /RedSail/i ) {
          #QS1 per claim exception...
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid
          );
          $salecalc .= "TAP - QS1/RedSail Exception: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid";
        } else {
          #Default TPP Sale Calculation
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid - $dbMedicaidProviderFee 
          );
          $salecalc .= "TAP: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid - Med: $dbMedicaidProviderFee";
        }
      }
         
      ##Controls the COB Amounts
      my $TSALE = $SALE;
      $TSALE    = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
#        print "$dbRxNumber $dbBiNumber - $TSALE = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0}<br>";
        $TSALE    = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0};
      }

      #Add to total revenue
      $TotalTotalRevenue += $TSALE;

      #Add to B/G/U revenue
      if ($bg =~ /B/i ) { 
        $BrandTotalRevenue   += $TSALE;
      } elsif ($bg =~ /G/i ) { 
        $GenericTotalRevenue += $TSALE;
      } else { 
        $UnknownTotalRevenue += $TSALE;
      }

      $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} = $SALE;   

      ###Calculate cost
      if ($dbIngredientCost != 0) {
        $COST = $dbIngredientCost;
        $costcalc .= "IC - $dbIngredientCost";
      } elsif ($dbIngredientCostPaid != 0) {
        $COST = $dbIngredientCostPaid;
        $costcalc .= "ICP - $dbIngredientCostPaid";
      } else {
        $COST = 0;
        $costcalc .= "NONE";
      }

      $IngredientTotalCost += $COST if (!$cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      $IC = $COST;

      ###Override cost if 340B Cash
      if ( ($BType =~ /Cash/i) || ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} && $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i) ) {
#      if ( ($BType =~ /Cash/i) ) {
        $COST = 0;
        $costcalc .= "BFF - NONE";
      }
       
      ##Controls the COB Amounts
      my $TCOST = $COST;
      $TCOST    = 0 if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      #Add to total cost
      $TotalTotalCost += $TCOST;

      #Add to B/G/U cost
      if ($bg =~ /B/i) { 
        $BrandTotalCost += $TCOST;
      } elsif ($bg =~ /G/i) { 
        $GenericTotalCost += $TCOST;
      } else { 
        $UnknownTotalCost += $TCOST;
      }

      if      ( $bg =~ /B/i ) {
        $COST = $COST * (1-$RebateBrand);
      } elsif ( $bg =~ /G/i ) {
        $COST = $COST * (1-$RebateGeneric);
      }

      #Add to GER_AWP
      $Medispan_AWP += $awp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0};
     
      #Create plan lookup key, remove leading zeros
      my $BIN_KEY   = $dbBinNumber;
      my $PCN_KEY   = $dbProcessorControlNumber;
      my $GROUP_KEY = $dbGroupID;
     
      $BIN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $PCN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $GROUP_KEY =~ s/^0+//gi; #Remove leading zeros
      
      $BIN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $PCN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $GROUP_KEY =~ s/^\s+//gi; #Remove leading spaces
     
      if ($TDS && $TDS =~ /^Y/i) {
        $planKEY   = uc("$BIN_KEY##$PCN_KEY");
      }
      else {
        $planKEY   = uc("$BIN_KEY##$PCN_KEY##$GROUP_KEY");
      }
     
      #Tie in with plan from &loadPlanLookup
      my $PBM = $PBM{$planKEY} || "";
      my $PAI_Payer_Name = $PAI_Payer_Name{$planKEY} || $planKEY;
      my $Comm_MedD_Medicaid = $Comm_MedD_Medicaid{$planKEY} || "";
     
      #IF the BIN is blank, 0, or -20000, the plan is CASH, override here.
      if ($BIN_KEY =~ /^\s*$|^0+$|-20000/) {
        $PBM                = "CASH";
        $PAI_Payer_Name     = "CASH";
        $Comm_MedD_Medicaid = "CASH";
      }
     
      #Use &loadRebateLookup data to create rebated (R)COST and rebated (R)GM
      my $YYYYMM_lookup = substr($dbDateOfService, 0, 6);
      if ($bg =~ /B/i) {
        my $brand_rebate = $rebateBrandDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $brand_rebate);
      } elsif ($bg =~ /G/i) {
        my $generic_rebate = $rebateGenericDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $generic_rebate);
      } else {
        $RCOST = $COST;
      }
     
      $RGM = $SALE - $RCOST; #Rebated GM
      $GM  = $SALE - $COST; #Non-Rebated GM
     
      $dbNDC = sprintf("%011d", $dbNDC); #Format NDC to 11 digits
     
      $key = "$dbNCPDPNumber##$dbRxNumber##$dbFillNumber##$dbDateOfService";
      $RxNumbers{$key}   = $dbRxNumber;
      $FillNumbers{$key} = $dbFillNumber;
      $BGs{$key}         = $bg;
      $SALEs{$key}       = sprintf("%.2f", $SALE);
      $COSTs{$key}       = sprintf("%.2f", $COST);
      $BinNumbers{$key}  = $dbBinNumber;
      $DBs{$key}         = $DB;
      $CASHorTPPs{$key}  = $CASHorTPP;
      $GMs{$key}         = sprintf("%.2f", $GM);
      $salecalcs{$key}   = $salecalc;
      $costcalcs{$key}   = $costcalc;
      $DOSs{$key}        = $dbDateOfService;
      $DateTransmitteds{$key} = $dbDateTransmitted;
      $PCNs{$key}        = $dbProcessorControlNumber;
      $Groups{$key}      = $dbGroupID;
      $NDCs{$key}        = $dbNDC;
      $TCodes{$key}      = $dbTCode;
      $Quantity{$key}    = $dbQuantityDispensed; #Added 10/27/2014
      $DaysSupply{$key}  = $dbDaysSupply; #Added 11/14/2014
     
      $RCOSTs{$key}      = $RCOST; #Added 11/14/2014
      $RGMs{$key}        = $RGM; #Added 11/14/2014
     
      $PBMs{$key}                = $PBM; #Added 11/14/2014
      $PAI_Payer_Names{$key}     = $PAI_Payer_Name; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = $Comm_MedD_Medicaid; #Added 11/14/2014
     
      $PrescriberIDs{$key} = $dbPrescriberID; #Added 05/20/2015
      $PrescriberLastName{$key} = $dbPrescriberLastName; 
      $CashFlags{$key}          = $dbCash; #Added 05/11/2018
      $BinParentdbkeys{$key}    = $dbBinParentdbkey; #Added 02/20/2020
      $ICs{$key}        = sprintf("%.2f", $IC);
      $Medispan_AWPs{$key}      = $dbMedispan_AWP; #Added 05/22/2020
      $Incoming_IDs{$key}   = $incoming_id;

      $cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}                               = 1;
      $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}{$dbOtherPayerCoverageType} = 1;
#      print "Bindbkey: $dbBinParentdbkey - $key\n";
    }
    $sth24->finish;
#    print "total jcnt: $jcnt, NCPDP: $dbNCPDPNumber\n" if ($incdebug);
  }

  print qq#sub Get_RBSReporting_Data. Exit. Detail: $Detail<br>\n# if ($incdebug);
  print "-"x96, "<br>\n" if ($incdebug);

  if ( $Detail =~ /Y|YH|Rx/i ) {

    return ( \%RxNumbers, \%FillNumbers, \%BGs, \%SALEs, \%COSTs, \%BinNumbers, \%DBs,
             \%CASHorTPPs, \%GMs, \%salecalcs, \%costcalcs, \%DOSs, \%DateTransmitteds,
             \%PCNs, \%Groups, \%NDCs, \%TCodes, \%Quantity, \%DaysSupply, 
             \%RCOSTs, \%RGMs, \%PBMs, \%PAI_Payer_Names, \%Comm_MedD_Medicaids, 
             \%PrescriberIDs, \%CashFlags, \%PrescriberLastName, \%ICs, \%BinParentdbkeys, \%Medispan_AWPs, \%Incoming_IDs);

  } else {
    $BrandScriptCount  += $UnknownScriptCount;
    $BrandTotalRevenue += $UnknownTotalRevenue;
    $BrandTotalCost    += $UnknownTotalCost;

    $BrandTotalRevenue   = sprintf("%.2f", $BrandTotalRevenue);
    $BrandTotalCost      = sprintf("%.2f", $BrandTotalCost);
    $GenericTotalRevenue = sprintf("%.2f", $GenericTotalRevenue);
    $GenericTotalCost    = sprintf("%.2f", $GenericTotalCost);
    $TotalTotalRevenue   = sprintf("%.2f", $TotalTotalRevenue);
    $TotalTotalCost      = sprintf("%.2f", $TotalTotalCost);
    $TotalIngredientCost = sprintf("%.2f", $IngredientTotalCost);

    return ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
             $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
             $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost,
             $TotalIngredientCost,$BrandDaySupplyCount, $GenericDaySupplyCount);
  }
}

#______________________________________________________________________________

sub loadRebateLookup_old {

  my ($NCPDP) = @_;

  print "<hr>sub loadRebateLookup: Entry. NCPDP: $NCPDP, testing: $testing<br>\n" if ($debug || $testing);
  print "<p>Loading Rebate Lookup!</p>\n" if ($debug);
  
  %rebateBrandDB   = ();
  %rebateGenericDB = ();
  
  my $count = 0;
  my $DBNAME = "rbsreporting";
  $DBNAME = 'Webinar' if($USER == 2182);
  if ( $testing ) {
     $DBNAME = "testing";
  }
  
  if ($NCPDP > 0 && $NCPDP !~ /^\s*$/) {

    $sql = "
    SELECT YYYYMM, Brand_Rebate, Generic_Rebate
    FROM $DBNAME.rebates 
    WHERE 
    NCPDP = $NCPDP
    ";
  
    print "sql<br>$sql<br><hr>\n" if ($debug || $testing || $incdebug);
    
    my $sthx  = $dbx->prepare("$sql");
    $sthx->execute;
    my $NumOfRows = $sthx->rows;
  
    if ( $NumOfRows > 0 ) {
      while ( my @row = $sthx->fetchrow_array() ) {
        my ($YYYYMM, $Brand_Rebate, $Generic_Rebate) = @row;
        my $key = $YYYYMM;
        $rebateBrandDB{$key}   = $Brand_Rebate;
        $rebateGenericDB{$key} = $Generic_Rebate;
        if ($Brand_Rebate > 0 || $Generic_Rebate > 0) {
          $count++;
        }
      }
    }
    $sthx->finish;
    
  } else {
    print "No NCPDP sent to loadRebateLookup!<br>\n";
  }
  
  $rebatesCount  = $count;
  $rebatesLoaded = $NCPDP;

  print "sub loadRebateLookup: Exit. Rows found: $NumOfRows<hr>\n\n" if ($debug);

}

#______________________________________________________________________________

sub loadRebateLookup {
  my ($NCPDP) = @_;

  print "<hr>sub loadRebateLookup: Entry. NCPDP: $NCPDP, testing: $testing<br>\n" if ($debug || $testing);
  print "<p>Loading Rebate Lookup!</p>\n" if ($debug);
  
  %rebateBrandDB   = ();
  %rebateGenericDB = ();
  my %Brand_Cost   = ();
  my %Generic_Cost = ();
  
  my $count = 0;
  my $DBNAME = "rbsreporting";
  $DBNAME = 'Webinar' if($USER == 2182);
  if ( $testing ) {
     $DBNAME = "testing";
  }
  
  if ($NCPDP > 0 && $NCPDP !~ /^\s*$/) {
    $sql = "
    SELECT Date, Total_Brand_Cost, Total_Generic_Cost
    FROM $DBNAME.monthly
    WHERE 
    NCPDP = $NCPDP
    ";
  
    print "sql<br>$sql<br><hr>\n" if ($debug || $testing || $incdebug);
    
    my $sthx  = $dbx->prepare("$sql");
    $sthx->execute;
    my $NumOfRows = $sthx->rows;
  
    if ( $NumOfRows > 0 ) {
      while ( my @row = $sthx->fetchrow_array() ) {
        my ($Dte, $Brand_Cost, $Generic_Cost) = @row;
	my $key = $Dte;
	$key =~ s/-//g;
	$key = substr($key,0,6);
        $Brand_Cost{$key}   = $Brand_Cost;
        $Generic_Cost{$key} = $Generic_Cost;
      }
    }
    $sthx->finish;

    $sql = "
    SELECT YYYYMM, Rebate_Type, Brand_Rebate, Generic_Rebate
    FROM $DBNAME.rebates 
    WHERE 
    NCPDP = $NCPDP
    ";
  
    print "sql<br>$sql<br><hr>\n" if ($debug || $testing || $incdebug);
    
    my $sthx  = $dbx->prepare("$sql");
    $sthx->execute;
    my $NumOfRows = $sthx->rows;
  
    if ( $NumOfRows > 0 ) {
      while ( my @row = $sthx->fetchrow_array() ) {
        my ($YYYYMM, $Rebate_Type, $Brand_Rebate, $Generic_Rebate) = @row;
        my $key = $YYYYMM;

	if ( $Rebate_Type =~ /D/i ) {
	  if ( $Brand_Cost{$key} > 0 ) {
            $rebateBrandDB{$key}   = $Brand_Rebate/$Brand_Cost{$key};
#            print "$rebateBrandDB{$key}   = $Brand_Rebate/$Brand_Cost{$key}<br>";
	  }
	  else {
            $rebateBrandDB{$key}   = 0;
	  }

	  if ( $Generic_Cost{$key} > 0 ) {
            $rebateGenericDB{$key} = $Generic_Rebate/$Generic_Cost{$key};
#            print "$rebateGenericDB{$key} = $Generic_Rebate/$Generic_Cost{$key}<br>";
	  }
	  else {
            $rebateGenericDB{$key} = 0;
	  }
        }
	else {
          $rebateBrandDB{$key}   = $Brand_Rebate;
          $rebateGenericDB{$key} = $Generic_Rebate;
	}

        if ($Brand_Rebate > 0 || $Generic_Rebate > 0) {
          $count++;
        }
      }
    }
    $sthx->finish;
    
  } else {
    print "No NCPDP sent to loadRebateLookup!<br>\n";
  }
  
  $rebatesCount  = $count;
  $rebatesLoaded = $NCPDP;

  print "sub loadRebateLookup: Exit. Rows found: $NumOfRows<hr>\n\n" if ($debug);

}

#______________________________________________________________________________

sub loadPlanLookup {

  if ( $debug ) {
     print "<hr>sub loadPlanLookup: Entry.<br>\n";
     print "<p>Loading Plan Lookup!</p>\n";
  }

  my $DBNAME = "rbsreporting";
  $DBNAME = 'Webinar' if($USER == 2182);
  if ( $testing ) {
     $DBNAME = "testing";
  }
  
  $sql = "
  SELECT BIN, PCN, lookup.GROUP, PBM, PAI_Payer_Name, Comm_MedD_Medicaid 
  FROM $DBNAME.plan_name_lookup lookup 
  ";

  print "sql:<br>$sql<br>\n" if ($debug || $testing);
  
  my $sthx  = $dbx->prepare("$sql");
  $sthx->execute;
  my $NumOfRows = $sthx->rows;

  if ( $NumOfRows > 0 ) {
  
    %PBM = ();
    %PAI_Payer_Name = ();
    %Comm_MedD_Medicaid = ();
  
    while ( my @row = $sthx->fetchrow_array() ) {
      my ($BIN, $PCN, $GROUP, $PBM, $PAI_Payer_Name, $Comm_MedD_Medicaid) = @row;
      $BIN   =~ s/^0+//gi; #Remove leading zeros
      $PCN   =~ s/^0+//gi; #Remove leading zeros
      $GROUP =~ s/^0+//gi; #Remove leading zeros
      
      $BIN   =~ s/^\s+//gi; #Remove leading spaces
      $PCN   =~ s/^\s+//gi; #Remove leading spaces
      $GROUP =~ s/^\s+//gi; #Remove leading spaces
      
      my $key = "$BIN##$PCN##$GROUP";
      $PBM{$key} = $PBM;
      $PAI_Payer_Name{$key} = $PAI_Payer_Name;
      $Comm_MedD_Medicaid{$key} = $Comm_MedD_Medicaid;
    }
  }
  $sthx->finish;
  
  $plansLoaded++;

  print "sub loadPlanLookup: Exit. Rows found: $NumOfRows<hr>\n\n" if ($debug);

}

#______________________________________________________________________________

sub loadPlanLookupBasic {

  if ( $debug ) {
     print "<hr>sub loadPlanLookupBasic: Entry.<br>\n";
     print "<p>Loading Plan Lookup!</p>\n";
  }

  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }
  
  $sql = "SELECT BIN, PCN, PAI_Payer_Name, Comm_MedD_Medicaid 
            FROM $DBNAME.plan_name_lookup_basic";

  print "sql:<br>$sql<br>\n" if ($debug || $testing);
  
  my $sthx  = $dbx->prepare("$sql");
  $sthx->execute;
  my $NumOfRows = $sthx->rows;

  if ( $NumOfRows > 0 ) {
  
    %PBM = ();
    %PAI_Payer_Name = ();
    %Comm_MedD_Medicaid = ();
  
    while ( my @row = $sthx->fetchrow_array() ) {
      my ($BIN, $PCN, $PAI_Payer_Name, $Comm_MedD_Medicaid) = @row;
      $BIN   =~ s/^0+//gi; #Remove leading zeros
      $PCN   =~ s/^0+//gi; #Remove leading zeros
      
      $BIN   =~ s/^\s+//gi; #Remove leading spaces
      $PCN   =~ s/^\s+//gi; #Remove leading spaces
      
      my $key = "$BIN##$PCN";
      $PAI_Payer_Name{$key} = $PAI_Payer_Name;
      $Comm_MedD_Medicaid{$key} = $Comm_MedD_Medicaid;
    }
  }
  $sthx->finish;
  
  $plansLoaded++;

  print "sub loadPlanLookupBasic: Exit. Rows found: $NumOfRows<hr>\n\n" if ($debug);

}

#______________________________________________________________________________


sub read340BFillFees {
  my $DBNAME = "rbsreporting";
  my $sql = "SELECT Admin, NCPDP, HealthCenter, FillFee 
               FROM $DBNAME.340b_Fill_Fees
            ";

  my $sthread  = $dbx->prepare($sql);
  $sthread->execute;
  my $NumOfRows = $sthread->rows;

  if ( $NumOfRows > 0 ) {
    while ( my @row = $sthread->fetchrow_array() ) {
      my ($Entity, $NCPDP, $HC, $FF) = @row;
      my $key = "$Entity##$NCPDP##$HC";
      $FillFees340B{$key}   = "$FF";
    }
  }  
  $sthread->finish();
  return(%FillFees340B);
}

sub read340BPharmAdmin {
  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }

  my $sql = "SELECT data340b.Pharmacy_ID, data340b.NCPDP, Admin340B, Pharmacy_Name, HealthCenter
               FROM $DBNAME.data340b
               JOIN officedb.pharmacy 
	         ON data340b.Pharmacy_ID = Pharmacy.Pharmacy_ID
           GROUP BY data340b.Pharmacy_ID, data340b.NCPDP, Admin340B, HealthCenter
           ORDER BY Pharmacy_Name";

  (my $sqlout = $sql) =~ s/\n/<br>\n/g;
  $sqlout =~ s/\t/$nbsp $nbsp $nbsp $nbsp/g;
  print "sql<br>$sqlout<hr>\n" if ($debug);
  
  my $sthread  = $dbx->prepare($sql);
  $sthread->execute;
  my $NumOfRows = $sthread->rows;
  
  my $keysset = 0;

  if ( $NumOfRows > 0 ) {
    my $outcount     = 0;
    while ( my @row = $sthread->fetchrow_array() ) {
      my ($Pharmacy_ID, $NCPDP, $Admin340B, $Pharmacy_Name, $HealthCenter) = @row;
      my $key = "$Pharmacy_ID##$NCPDP##$Admin340B##$HealthCenter";
      $NCPDPAdmin340B{$key}   = $Pharmacy_Name;
      $keysset++;
    }
  }  
  $sthread->finish();

  return(%NCPDPAdmin340B);
}

#______________________________________________________________________________

sub calculate_unique_patients {

  print "\n" , "-"x80, "\n";
  print "sub calculate_unique_patients. Entry. DBNAMELOCAL: $DBNAMELOCAL, TABLELOCAL: $TABLELOCAL\n\n";

  my ($Pharmacy_ID, $ncpdp, $DateRangeStart, $DateRangeEnd) = @_;

  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }
  my $table = "Monthly";
  
  my $numrows = 0;
  my $unique_patients = 0;
  
  my $checked = 0;
  $check_sql = "SELECT Date 
                  FROM $DBNAME.$table 
                 WHERE (1=1)
                    && Pharmacy_ID = $Pharmacy_ID
                    && Date  = '$DateRangeStart'";

  print "\n", "-"x96, "\n", "check_sql:\n$check_sql\n\n", "-"x96, "\n\n";

  my $sthc  = $dbx->prepare("$check_sql");
  $sthc->execute;
  $checked = $sthc->rows;
  $sthc->finish();
  
  if ($checked > 0) {
  
    #A row for this month exists, first calculate unique patient count within time frame.
    $unique_patient_sql = "SELECT count(*) as count 
                             FROM ( SELECT Pharmacy_ID 
                                      FROM $DBNAME.incomingtb_rbsdata  
                                     WHERE (1=1)
                                        && Pharmacy_ID = $Pharmacy_ID
                                        && dbDateOfService >= $DateRangeStart && dbDateOfService <= $DateRangeEnd 
                                        && (dbTCode NOT IN('RVL', 'PDR', 'RNM', 'DUP', 'PDUP', 'PDR TSP') || dbTCode = '' || dbTCode IS NULL) 
                                  GROUP BY dbNCPDPNumber, dbDateOfBirth, dbPatientFirstName, dbPatientLastName, dbPatientZip, dbPatientCityAddress, dbPatientStateAddress
                                  ORDER BY dbNCPDPNumber, dbDateOfBirth, dbPatientFirstName, dbPatientLastName, dbPatientZip, dbPatientCityAddress, dbPatientStateAddress
                                  ) up";

    print "\n", "-"x96, "\n", "unique_patient_sql:\n$unique_patient_sql\n\n", "-"x96, "\n\n";

    my $sthup  = $dbx->prepare("$unique_patient_sql");
    $sthup->execute;
    $numrows = $sthup->rows;
    if ($numrows > 0) {
      while ( my @row = $sthup->fetchrow_array() ) {
        ($unique_patients) = @row;
      }
    }
  
    print "Calculating unique patients... found $unique_patients between $DateRangeStart and $DateRangeEnd\n";
    $sthup->finish();
  
  
    #Update month row with unique patient data...
    $unique_patient_update_sql = "UPDATE $DBNAME.$table 
                                     SET Unique_Patients = $unique_patients 
                                   WHERE Pharmacy_ID = $Pharmacy_ID
                                      && Date = '$DateRangeStart'";
    my $sthupu  = $dbx->prepare("$unique_patient_update_sql");
    my $numrows = $sthupu->execute;
    if ($numrows > 0) {
      print "Monthly table ($table) row updated with patient count...\n";
    } else {
      print "ERROR! ($table) was not updated with patient count!\n";
    }
    $sthupu->finish();
  
  } else {
    print "&calculate_unique_patients: No row found for month ($DateRangeStart), store ($ncpdp)\n";
  }

  
  print "-"x80, "\n";
  print "sub calculate_unique_patients. Exit.\n\n";
  
}

#______________________________________________________________________________

sub calculate_unique_patients_tds {

  print "\n" , "-"x80, "\n";
  print "sub calculate_unique_patients. Entry. DBNAMELOCAL: $DBNAMELOCAL, TABLELOCAL: $TABLELOCAL\n\n";

  my ($Pharmacy_ID, $ncpdp, $DateRangeStart, $DateRangeEnd) = @_;

  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }
  my $table = "Monthly";
  
  my $numrows = 0;
  my $unique_patients = 0;
  
  my $checked = 0;
  $check_sql = "SELECT Date 
                  FROM $DBNAME.$table 
                 WHERE (1=1)
                    && Pharmacy_ID = $Pharmacy_ID
                    && Date  = '$DateRangeStart'";

  print "\n", "-"x96, "\n", "check_sql:\n$check_sql\n\n", "-"x96, "\n\n";

  my $sthc  = $dbx->prepare("$check_sql");
  $sthc->execute;
  $checked = $sthc->rows;
  $sthc->finish();
  
  if ($checked > 0) {
  
    #A row for this month exists, first calculate unique patient count within time frame.
    $unique_patient_sql = "SELECT count(*) as count 
                             FROM ( SELECT Pharmacy_ID 
                                      FROM $DBNAME.incomingtb
                                     WHERE (1=1)
                                        && Pharmacy_ID = $Pharmacy_ID
                                        && dbDateOfService >= $DateRangeStart && dbDateOfService <= $DateRangeEnd 
                                        && (dbTCode NOT IN('RVL', 'PDR', 'RNM', 'DUP', 'PDUP', 'PDR TSP') || dbTCode = '' || dbTCode IS NULL) 
                                  GROUP BY dbNCPDPNumber, dbDateOfBirth, dbPatientFirstName, dbPatientLastName, dbPatientZip, dbPatientCityAddress, dbPatientStateAddress
                                  ORDER BY dbNCPDPNumber, dbDateOfBirth, dbPatientFirstName, dbPatientLastName, dbPatientZip, dbPatientCityAddress, dbPatientStateAddress
                                  ) up";

    print "\n", "-"x96, "\n", "unique_patient_sql:\n$unique_patient_sql\n\n", "-"x96, "\n\n";

    my $sthup  = $dbx->prepare("$unique_patient_sql");
    $sthup->execute;
    $numrows = $sthup->rows;
    if ($numrows > 0) {
      while ( my @row = $sthup->fetchrow_array() ) {
        ($unique_patients) = @row;
      }
    }
  
    print "Calculating unique patients... found $unique_patients between $DateRangeStart and $DateRangeEnd\n";
    $sthup->finish();
  
  
    #Update month row with unique patient data...
    $unique_patient_update_sql = "UPDATE $DBNAME.$table 
                                     SET Unique_Patients = $unique_patients 
                                   WHERE Pharmacy_ID = $Pharmacy_ID
                                      && Date = '$DateRangeStart'";
    my $sthupu  = $dbx->prepare("$unique_patient_update_sql");
    my $numrows = $sthupu->execute;
    if ($numrows > 0) {
      print "Monthly table ($table) row updated with patient count...\n";
    } else {
      print "ERROR! ($table) was not updated with patient count!\n";
    }
    $sthupu->finish();
  
  } else {
    print "&calculate_unique_patients: No row found for month ($DateRangeStart), store ($ncpdp)\n";
  }

  
  print "-"x80, "\n";
  print "sub calculate_unique_patients. Exit.\n\n";
  
}

#______________________________________________________________________________

sub calcRebatePercent {

# my $debug++;

  #Currently (2014-12-08) only doing GENERIC rebates, however can support BRAND.
  
  print "sub calcRebatePercent: Entry.\n" if ($debug);

  my ($Pharmacy_ID, $NCPDP, $Pharmacy_Name, $YYYYMM, $Total_Brand_Cost, $Total_Generic_Cost) = @_;

  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }
  
  my $update_percentages = 0;
  
  if ($YYYYMM =~ /-/) {
    my @pcs = split('-', $YYYYMM);
    $YYYYMM  = sprintf("%04d%02d", $pcs[0], $pcs[1]);
  }
  
  if (length($YYYYMM) == 8 && substr($YYYYMM, -2) =~ /01/) {
    $YYYYMM = substr($YYYYMM, 0, 6);
  }
  
  my $brand_rebate_percent = 0;
  my $brand_rebate_dollars = 0;
  
  my $generic_rebate_percent = 0;
  my $generic_rebate_dollars = 0;
  
  my $sql = "SELECT Brand_Rebate, Generic_Rebate 
               FROM $DBNAME.rebate_dollars 
              WHERE (1=1) 
                 && Pharmacy_ID = $Pharmacy_ID
                 && YYYYMM = $YYYYMM";
  
  (my $sqlout = $sql) =~ s/\n/<br>\n/g;
  if ( $testing ) {
     print "\n", "-"x96, "\n", "sql:\n$sqlout\n\n", "-"x96, "\n\n";
  } else {
     print "<hr>sql:<br>\n$sqlout<br>\n<hr>\n" if ($incdebug);
  }
  
  $sthc = $dbx->prepare($sql);
  $sthc->execute;
  $NumOfRows = $sthc->rows;
  if ( $NumOfRows > 0 ) {
    while ( my @row = $sthc->fetchrow_array() ) {
      ($brand_rebate_dollars, $generic_rebate_dollars) = @row;
    }  
  }
  $sthc->finish;
  
  print "brand_rebate_dollars: $brand_rebate_dollars\n" if ($debug);
  print "Total_Brand_Cost: $Total_Brand_Cost\n\n" if ($debug);
  
  print "generic_rebate_dollars: $generic_rebate_dollars\n" if ($debug);
  print "Total_Generic_Cost: $Total_Generic_Cost\n\n" if ($debug);
  
  if ($brand_rebate_dollars > 0 && $Total_Brand_Cost > 0) {
    $brand_rebate_percent = ($brand_rebate_dollars / $Total_Brand_Cost);
    $brand_rebate_percent = sprintf("%0.6f", $brand_rebate_percent);  
    $update_percentages++;
  }
  
  if ($generic_rebate_dollars > 0 && $Total_Generic_Cost > 0) {
    $generic_rebate_percent = ($generic_rebate_dollars / $Total_Generic_Cost);
    $generic_rebate_percent = sprintf("%0.6f", $generic_rebate_percent);  
    $update_percentages++;
  }
  
  if ($update_percentages > 0) {
    my $sql = "REPLACE INTO $DBNAME.rebates 
                   SET Pharmacy_Name = \"$Pharmacy_Name\", 
                       NCPDP = $NCPDP, 
                       YYYYMM = $YYYYMM, 
                       Brand_Rebate = $brand_rebate_percent, 
                       Generic_Rebate = $generic_rebate_percent,
		       Pharmacy_ID = $Pharmacy_ID";
    
    print "Update rebate percentage based on rebate dollar amount in $DBNAME.rebate_dollars\n$sql\n";
  
    $sthi = $dbx->prepare($sql);
    $sthi->execute;
    $NumOfRows = $sthi->rows;
    $sthi->finish;
  }
  
  return ($brand_rebate_percent, $generic_rebate_percent);
  
  print "sub calcRebatePercent: Exit.\n" if ($debug);
  
}

#______________________________________________________________________________

sub refillClaimsInfo {

# my $debug++;

  print "\n" , "-"x80, "\n";

  my ($Pharmacy_ID, $ncpdp, $DateRangeStart, $DateRangeEnd, $TDS) = @_;
  
  my $checked = 0;
  $check_sql = "SELECT Date 
                  FROM $RMDBNAME.$RMTABLE
                 WHERE (1=1)
                    && Pharmacy_ID = $Pharmacy_ID
                    && Date  = '$DateRangeStart'";

  my $sthc  = $dbx->prepare("$check_sql");
  $sthc->execute;
  $checked = $sthc->rows;
  $sthc->finish();
  
  if ($checked > 0) {
  
    my $new_claim_count = 0;
    my $new_claim_sales = 0;
  
    my $refill_claim_count = 0;
    my $refill_claim_sales = 0;
  
    #----------------------------------------------------------------
    my $PharmacyWanted   = $ncpdp;
  
    my $Detail           = 'YRBS'; #Claim Detail Data - RBS Database
    my $RebateBrand      = 0;      #Rebate factored later.
    my $RebateGeneric    = 0;      #Rebate factored later.
    my $NPIstring        = '';     #No NPI string.
    my $ExcBINstring     = '';     #No BIN exclusion string.
    #----------------------------------------------------------------
  
    #Get RBS Reporting data via subroutine
    ($RxNumbersref, $FillNumbersref, $BGsref, $SALEsref, $COSTsref, $BinNumbersref,
    $DBsref, $CASHorTPPsref, $GMsref, $salecalcsref, $costcalcsref, $DOSsref, $DateTransmittedsref,
    $PCNsref, $Groupsref, $NDCsref, $TCodesref, $Quantitysref, $DaySupplyref, 
    $RCOSTsref, $RGMsref, $PBMsref, $PAI_Payer_Namesref, $Comm_MedD_Medicaidref) =
    &Get_RBSReporting_Data($PharmacyWanted, $DateRangeStart, $DateRangeEnd, $Detail, 
    $RebateBrand, $RebateGeneric, "$NPIstring", "$ExcBINstring", $TDS);
  
    foreach $key (sort keys %$RxNumbersref) {
  
      $FillNumber = $FillNumbersref->{$key};
      $SALE       = $SALEsref->{$key};
  
      if      ($FillNumber == 0) {
        $new_claim_count++;
        $new_claim_sales += $SALE;
      } elsif ($FillNumber >  0) {
        $refill_claim_count++;
        $refill_claim_sales += $SALE;
      }
  
    }
  
    #Update month row with data...
    $update_sql = "
    UPDATE $RMDBNAME.$RMTABLE 
    SET 
    New_Claim_Count    = $new_claim_count, 
    New_Claim_Sales    = $new_claim_sales, 
    Refill_Claim_Count = $refill_claim_count, 
    Refill_Claim_Sales = $refill_claim_sales 
    WHERE 
    Pharmacy_ID = $Pharmacy_ID
    && Date = '$DateRangeStart' 
    ";
    my $sthu  = $dbx->prepare("$update_sql");
    my $numrows = $sthu->execute;
    if ($numrows > 0) {
      print "Monthly table ($RMTABLE) row updated with new vs refill claim info...\n";
    } else {
      print "ERROR! ($RMTABLE) was not updated with new vs refill claim info!\n";
    }
    $sthu->finish();
  
  } else {
    print "&refillClaimsInfo: No row found for month ($DateRangeStart), store ($ncpdp)\n";
  }
  
  print "-"x80, "\n";
  
  #return ($new_claim_count, $new_claim_sales, $refill_claim_count, $refill_claim_sales);

}

#______________________________________________________________________________

sub medsyncClaimsInfo {

  print "-"x80, "\n";
  print "sub calculate_unique_patients. Exit.\n\n";

  my ($Pharmacy_ID, $ncpdp, $DateRangeStart, $DateRangeEnd) = @_;
  my  $syncpatientcnt;
  my  $synctxncnt;
  my  %synced;
  my  %Tcount;

  my $DBNAME = "rbsreporting";
  if ( $testing ) {
     $DBNAME = "testing";
  }
  my $table = "Monthly";
  
  my $numrows = 0;
  my $unique_patients = 0;
  
  my $checked = 0;
  $check_sql = "SELECT Date 
                  FROM $DBNAME.$table 
                 WHERE (1=1)
                    && Pharmacy_ID = $Pharmacy_ID
                    && Date  = '$DateRangeStart'";

  print "\n", "-"x96, "\n", "check_sql:\n$check_sql\n\n", "-"x96, "\n\n";

  my $sthc  = $dbx->prepare("$check_sql");
  $sthc->execute;
  $checked = $sthc->rows;
  $sthc->finish();
  
  if ($checked > 0) {
  
    #A row for this month exists, first calculate unique patient count within time frame.
    $medsync_sql  = "
      SELECT dbPatientFirstName, dbPatientLastName,YearofBirth, monthofservice, dbSyncPatient, count(*) from (
        SELECT dbpatientfirstname, dbpatientlastname, SUBSTR(dbdateofbirth,1,4) as YearOfBirth, dbrxnumber, dbSyncPatient, dbNDC, SUBSTR(dbdateofservice,1,6) AS monthofservice
          FROM $DBNAME.incomingtb_rbsdata a
          JOIN officedb.msborg_lookup_table_new b ON a.dbNDC = b.NDC
         WHERE (1=1)
            && dbDateOfService >= $DateRangeStart
      	    && dbDateOfService <= $DateRangeEnd 
            && Pharmacy_ID = $Pharmacy_ID
            && dbTcode = '' 
         GROUP BY dbrxnumber,monthofservice
      ) a
      GROUP BY dbPatientFirstName,dbPatientLastName, YearofBirth, monthofservice, dbSyncPatient
      ORDER BY dbPatientFirstName, dbPatientLastName, YearofBirth, monthofService, dbSyncPatient
    ";
    my $sthup  = $dbx->prepare("$medsync_sql");
    $sthup->execute;
    $numrows = $sthup->rows;
    $syncpatientcnt = 0;
    $synctxncnt = 0;
    %Tcount = ();
    %synced = ();

    my $NumOfsyncRows = $sthup->rows;
    while ( my @row = $sthup->fetchrow_array() ) {
      $cnt++;
      my ($fname,$lname,$yob,$mos, $synced,  $count) = @row;
      $fname =~ s/'/\\'/g;
      $lname =~ s/'/\\'/g;
      $RepKey = "$fname##$lname##$yob";

      $synced{$RepKey}++ if ( $synced =~ /Y/i );
      $Tcount{$RepKey}+= $count;
    }
    if ( $NumOfsyncRows > 0 ) {
      foreach $key (sort keys %synced) {
        $syncpatientcnt++;
        $synctxncnt += $Tcount{$key};
      }
    }
  
  print "Calculating medsync_information between $DateRangeStart and $DateRangeEnd\n";
  $sthup->finish();
 
  $update_medsync = "UPDATE $DBNAME.$table 
                        SET Synced_Claim_Count= $synctxncnt,
	                    Synced_Patients = $syncpatientcnt
                      WHERE Pharmacy_ID = $Pharmacy_ID
                         && Date = '$DateRangeStart'";

    my $sthupu  = $dbx->prepare("$update_medsync");
    my $numrows = $sthupu->execute;
    if ($numrows > 0) {
      print "Monthly table ($table) row updated with Synced_Claim_Count:$synctxncnt and Synced_Patients:$syncpatientcnt...\n";
    } else {
      print "ERROR! ($table) was not updated with medsync count!\n";
    }
    $sthupu->finish();
  
  } else {
    print "&medsyncClaimsInfo: No row found for month ($DateRangeStart), store ($ncpdp)\n";
  }

  
  print "-"x80, "\n";
  print "sub medsyncClaimsInfo Exit.\n\n";
  
}

# _____________________________________________________________________________
#

sub readRebates {

  print "sub readRebates. Entry. NCPDP: $USER<br>\n" if ($debug);

  $sql = "
  SELECT Date, Total_Brand_Cost, Total_Generic_Cost
  FROM $DBNAMERM.monthly
  WHERE Date >= '${yearm2}-01-01'
  AND Pharmacy_ID = $Pharmacy_ID
    ";
  
  print "sql<br>$sql<br><hr>\n" if ($debug || $testing || $incdebug);
    
  my $sthx  = $dbx->prepare("$sql");
  $sthx->execute;
  my $NumOfRows = $sthx->rows;
  
  if ( $NumOfRows > 0 ) {
    while ( my @row = $sthx->fetchrow_array() ) {
      my ($Dte, $Brand_Cost, $Generic_Cost) = @row;
      my $key = $Dte;
      $key =~ s/-//g;
      $key = substr($key,0,6);
      $Brand_Cost{$key}   = $Brand_Cost;
      $Generic_Cost{$key} = $Generic_Cost;
    }
  }
  $sthx->finish;

  my $sql = "
  SELECT 
  YYYYMM, Rebate_Type, Brand_Rebate, Generic_Rebate
  FROM $DBNAMERM.$TABLERB 
  WHERE Pharmacy_ID = $Pharmacy_ID
  && YYYYMM >= '${yearm2}01'
  ";

  print "sql:<br>$sql<br>\n" if ($debug);

  $sthx  = $dbx->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
     my ( $YYYYMM, $Rebate_Type, $Brand_Rebate, $Generic_Rebate) = @row;

     $RebateKey                          = "$inNCPDP##$YYYYMM";
     $Rebate_YYYYMM{$RebateKey}          = $YYYYMM;

     if ( $Rebate_Type =~ /D/i ) {
       if ( $Brand_Cost{$YYYYMM} > 0 ) {
         $Rebate_Brand_Rebate{$RebateKey}  = $Brand_Rebate/$Brand_Cost{$YYYYMM};
       }
       else {
         $Rebate_Brand_Rebate{$RebateKey}   = 0;
       }

       if ( $Generic_Cost{$YYYYMM} > 0 ) {
         $Rebate_Generic_Rebate{$RebateKey} = $Generic_Rebate/$Generic_Cost{$YYYYMM};
       }
       else {
         $Rebate_Generic_Rebate{$RebateKey} = 0;
       }
     }
     else {
       $Rebate_Brand_Rebate{$RebateKey}    = $Brand_Rebate;
       $Rebate_Generic_Rebate{$RebateKey}  = $Generic_Rebate;
     }
  }
  $sthx->finish;
  
  print "sub readRebates. Exit.<br>\n" if ($debug);
}

#______________________________________________________________________________

sub readMonthlyData {

  print "sub readMonthlyData. Entry. NCPDP: $USER<br>\n" if ($debug);

  # open RBSReporting DB, read Monthly data
  my $sql = "
  SELECT 
  Pharmacy_Name, m.NCPDP, m.Date, Total_Brand, Total_Generic, Total_Brand_Revenue, Total_Generic_Revenue, Total_Brand_Cost, Total_Generic_Cost, Unique_Patients, New_Claim_Count, New_Claim_Sales, Refill_Claim_Count, Refill_Claim_Sales, Comments, Inventory_Value, Maintenance_Med_Patients, Maintenance_Med_Claim_Count, Synced_Patients, Synced_Claim_Count, Total_DaySupply_Brand, Total_DaySupply_Generic
  FROM $DBNAMERM.$TABLERM m
  
  LEFT JOIN $DBNAMERM.inventory_values iv
    ON m.Pharmacy_ID = iv.Pharmacy_ID
    && m.Date = iv.Date
  
  WHERE 1=1 
  && m.Pharmacy_ID = $Pharmacy_ID
  && m.Date >= '$yearm2-01-01' 
  && m.Date <= '$ReportMonth'
  ";

  print "sql:<br>$sql<br>\n" if ($debug);

  $sthx  = $dbx->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {

     my ( $Pharmacy_Name, $NCPDP, $Date, $Total_Brand, $Total_Generic, $Total_Brand_Revenue, $Total_Generic_Revenue, $Total_Brand_Cost, $Total_Generic_Cost, $Unique_Patients, $New_Claim_Count, $New_Claim_Sales, $Refill_Claim_Count, $Refill_Claim_Sales, $Comments, $Inventory_Valuei, $Maintenance_Med_Patients, $Maintenance_Med_Claim_Count, $Synced_Patients, $Synced_Claim_Count, $DaySupply_Brand, $DaySupply_Generic) = @row;

     ($DateCheck = $Date) =~ s/-//g;
     ($ReportMonthCheck = $ReportMonth) =~ s/-//g;

     next if ( $DateCheck > $ReportMonthCheck ); #Skip any future data
   
     $Pharmacy_Name_Global = $Pharmacy_Name;
 
     ###################################################################################################
     # Remove last two characters from end of DateCheck
     chop($DateCheck);
     chop($DateCheck);
     print "Date: $Date, DateCheck: $DateCheck<br>" if ($debug);

     $YYYYMM    = $DateCheck;
     $lookupkey = "$NCPDP##$YYYYMM";
     $Brand_Rebate   = $Rebate_Brand_Rebate{$lookupkey}   || 0;
     $Generic_Rebate = $Rebate_Generic_Rebate{$lookupkey} || 0;
  
     if ( $debug ) {
        print "<hr size=4 noshade color=blue>\n";
        print "lookupkey         : $lookupkey<br>\n";
        print "Total_Brand_Cost  : $Total_Brand_Cost, Brand_Rebate: $Brand_Rebate<br>\n";
        print "Total_Generic_Cost: $Total_Generic_Cost, Generic_Rebate: $Generic_Rebate<br>\n";
     }
     
     $Total_Brand_Cost_NR   = $Total_Brand_Cost;
     $Total_Generic_Cost_NR = $Total_Generic_Cost;
 
     #Factor in rebates...
     $Total_Brand_Cost   = $Total_Brand_Cost   * (1-$Brand_Rebate);
     $Total_Generic_Cost = $Total_Generic_Cost * (1-$Generic_Rebate);

     if ( $debug ) {
        print "NEW VALUES:<br>\n";
        print "Total_Brand_Cost  : $Total_Brand_Cost<br>\n";
        print "Total_Generic_Cost: $Total_Generic_Cost<br>\n";
     }
     ###################################################################################################

     #Save MONTHLY data to hashes
     $RepKey                                   = "$NCPDP##$Date";
     $Rep_MWType{$RepKey}                      = "Month";
     $Rep_Pharmacy_Name{$RepKey}               = $Pharmacy_Name;
     $Rep_NCPDP{$RepKey}                       = $NCPDP;
     $Rep_Date{$RepKey}                        = $Date;
     $Rep_Total_Brand{$RepKey}                 = $Total_Brand;
     $Rep_Total_Generic{$RepKey}               = $Total_Generic;
     $Rep_Total_Brand_Revenue{$RepKey}         = $Total_Brand_Revenue;
     $Rep_Total_Generic_Revenue{$RepKey}       = $Total_Generic_Revenue;
     $Rep_Total_Brand_Cost{$RepKey}            = $Total_Brand_Cost;      #INCLUDES REBATES
     $Rep_Total_Generic_Cost{$RepKey}          = $Total_Generic_Cost;    #INCLUDES REBATES
     $Rep_Total_Brand_Cost_NR{$RepKey}         = $Total_Brand_Cost_NR;      #NO REBATES
     $Rep_Total_Generic_Cost_NR{$RepKey}       = $Total_Generic_Cost_NR;    #NO REBATES
     $Rep_Unique_Patients{$RepKey}             = $Unique_Patients;
     $Rep_New_Claim_Count{$RepKey}             = $New_Claim_Count;
     $Rep_New_Claim_Sales{$RepKey}             = $New_Claim_Sales;
     $Rep_Refill_Claim_Count{$RepKey}          = $Refill_Claim_Count;
     $Rep_Refill_Claim_Sales{$RepKey}          = $Refill_Claim_Sales;
     $Rep_Comments{$RepKey}                    = $Comments;
     $Rep_Inventory_Value{$RepKey}             = $Inventory_Value;
     $Rep_Maintenance_Med_Patients{$RepKey}   = $Maintenance_Med_Patients;
     $Rep_Maintenance_Med_Claim_Count{$RepKey} = $Maintenance_Med_Claim_Count;
     $Rep_Synced_Patients{$RepKey}             = $Synced_Patients;
     $Rep_Synced_Claim_Count{$RepKey}          = $Synced_Claim_Count;
     $Rep_DaySupply_Brand{$RepKey}             = $DaySupply_Brand;
     $Rep_DaySupply_Generic{$RepKey}           = $DaySupply_Generic;
   
     my ($year, $month, $day) = split("-", $Date, 3);
     if      ( $month >= 1 && $month <= 3 ) {
        $QTR    = "${year}##Q1";
     } elsif ( $month >= 4 && $month <= 6 ) {
        $QTR    = "${year}##Q2";
     } elsif ( $month >= 7 && $month <= 9 ) {
        $QTR    = "${year}##Q3";
     } elsif ( $month >= 10 && $month <= 12 ) {
        $QTR    = "${year}##Q4";
     }
     $QTRkey = "$NCPDP##$QTR";

     #Save QUARTERLY data to hashes
     $Rep_MWType{$QTRkey}                = "Quarter";
     $Rep_Pharmacy_Name{$QTRkey}         = $Pharmacy_Name;
     $Rep_NCPDP{$QTRkey}                 = $NCPDP;
     $Rep_Date{$QTRkey}                  = $QTR;
     $Rep_Total_Brand{$QTRkey}           += $Total_Brand;
     $Rep_Total_Generic{$QTRkey}         += $Total_Generic;
     $Rep_Total_Brand_Revenue{$QTRkey}   += $Total_Brand_Revenue;
     $Rep_Total_Generic_Revenue{$QTRkey} += $Total_Generic_Revenue;
     $Rep_Total_Brand_Cost{$QTRkey}      += $Total_Brand_Cost;     #INCLUDES REBATES
     $Rep_Total_Generic_Cost{$QTRkey}    += $Total_Generic_Cost;   #INCLUDES REBATES
     $Rep_Total_Brand_Cost_NR{$QTRkey}   += $Total_Brand_Cost_NR;      #NO REBATES
     $Rep_Total_Generic_Cost_NR{$QTRkey} += $Total_Generic_Cost_NR;    #NO REBATES
     $Rep_Unique_Patients{$QTRkey}       += $Unique_Patients;
     $Rep_New_Claim_Count{$QTRkey}       += $New_Claim_Count;
     $Rep_New_Claim_Sales{$QTRkey}       += $New_Claim_Sales;
     $Rep_Refill_Claim_Count{$QTRkey}    += $Refill_Claim_Count;
     $Rep_Refill_Claim_Sales{$QTRkey}    += $Refill_Claim_Sales;
     $Rep_Comments{$QTRKey}              .= "$Comments<br>";
   
   
     #Save YEARLY data to hashes
     $YearKey                             = "$year";
     $Rep_Total_Brand{$YearKey}           += $Total_Brand;
     $Rep_Total_Generic{$YearKey}         += $Total_Generic;
     $Rep_Total_Brand_Revenue{$YearKey}   += $Total_Brand_Revenue;
     $Rep_Total_Generic_Revenue{$YearKey} += $Total_Generic_Revenue;
   
  }
  $sthx->finish;

  print "sub readMonthlyData. Exit.<br>\n" if ($debug);
}

sub Get_RBSReporting_Data_old {
  my ($NCPDP, $StartDate, $EndDate, $Detail, $RebateBrand, $RebateGeneric, $NPIstring, $ExcBINstring, $TDS) = @_;

  my %cob;
  my %tap;
  my %ic;
  my %icp;
  my %pct;
  my %mpf;
  my %ttr;
  my %record;
  my %bn;
  my %pcn;
  my %gid;
  my $dbin;

  if ( $incdebug ) {
     print "-"x96, "<br>\n";
     print "sub Get_RBSReporting_Data. Entry. NCPDP: $NCPDP, StartDate: $StartDate, EndDate: $EndDate, Detail: $Detail, RebateBrand: $RebateBrand, RebateGeneric: $RebateGeneric<br>\n  NPIstring: $NPIstring<br>  ExcBINstring: $ExcBINstring<br> <br>\n";
     print "$prog: dbTCodes: $dbTCodes<hr>\n\n" if ($incdebug);
     print "DOPHARMACY($NCPDP): $DOPHARMACY{$NCPP}<hr>\n";

  }
  print "testing: $testing<br>\n" if ($debug || $incdebug || $testing);

  my ( %RxNumbers, %FillNumbers, %BGs, %SALEs, %COSTs, %BinNumbers, %DBs,
       %CASHorTPPs, %GMs, %salecalcs, %costcalcs, %DOSs, %DateTransmitteds,
       %PCNs, %Groups, %NDCs, %TCodes, %Quantity, %DaysSupply, 
       %RCOSTs, %RGMs, %PBMs, %PAI_Payer_Names, %Comm_MedD_Medicaids, 
       %PrescriberIDs, %CashFlags);

  my ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
       $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
       $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost);
     
  # Load data lookup hashes on first run only
  # ---------------------------------------------------------------- #
 
  
  if ( !$rebatesLoaded || $rebatesLoaded != $NCPDP ) {
    &loadRebateLookup($NCPDP);
  }
  if( !$plansLoaded || $plansLoaded <= 0 ) {
    &loadPlanLookup;
  }

  # ---------------------------------------------------------------- #

  if ( $incdebug) {
     print "NPIstring   : $NPIstring<br>\n";
     print "ExcBINstring: $ExcBINstring<br>\n";
  }

  if ( $NPIstring =~ /^\s*$/ ) {
    $doPrescriberID = qq##;
  } else {
    $doPrescriberID = qq# && dbPrescriberID in($NPIstring) #;
  }
  print "<hr>doPrescriberID: $doPrescriberID<hr><br>\n" if ($incdebug);
  #-------------

  if ( $ExcBINstring =~ /^\s*$/ ) {
    $ExcBINs = qq##;
  } else {
    $ExcBINs = qq# && dbBinNumber NOT in($ExcBINstring) #;
  }
  print "<hr>ExcBINs: $ExcBINs<hr><br>\n" if ($incdebug);
  #-------------

  if ($TDS && $TDS =~ /^Y/i) {
    $dbin = "TDDBNAME";
  }
  else {  
    $dbin = "RRDBNAME";
  }

  if ( $testing ) {

    print "\n\n\n FATAL: FIX ME!!!!!!!!!!!!!!!!!!!!!!!! \n\n\n<br>\n";
  
    ########################################
    # BEG - TESTING SECTION SETUP
    ########################################
    
    # Comment out this block when done testing!!!!!
    
      $JJJ = $DBNAMES{$dbin}; print "JJJ: $JJJ<br>\n";
    
      $WHICHDB = "testing";		# Valid Values: "Testing" or "Webinar"
      &set_Webinar_or_Testing_DBNames;
      if ( $DBNAMES{$dbin} =~ /^\s*$/ ) {
         $DBNAMES{$dbin} = $JJJ;
         print qq#Found dbin's ($dbin) DBNAME was blank. Setting to "testing"<br>\n# if ($debug || $testing);
      } else {
#        print "HHHHHHHHHHH\n";
      }
    
      $HHH = $DBNAMES{$dbin}; print "HHH: $HHH<br>\n";
    
    ########################################
    # END - TESTING SECTION SETUP
    ########################################
  
  }

  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};

  $Pharmacy_Name  = "";
  $SoftwareVendor = "";
  $PrimarySwitch  = "";

  #-------------------------------------------------------------
  
  if ( !$PharmacyWanted ) {
     $PharmacyWanted = $NCPDP;
  }
  if ( !$NCPDP ) {
     $NCPDP = $PharmacyWanted;
  }
  print "<hr>2. NCPDP: $NCPDP, PharmacyWanted: $PharmacyWanted, DOPHARMACY($PharmacyWanted): $DOPHARMACY{$PharmacyWanted}<br>\n" if ($debug);

  if ( $GRRD_Pharmacy_Name && $DOPHARMACY{$PharmacyWanted} > 1 ) {

    print "Skipping DB Query. Using GRRD vars. GRRD_Pharmacy_Name: $GRRD_Pharmacy_Name, GRRD_SoftwareVendor: $GRRD_SoftwareVendor, GRRD_PrimarySwitch: $GRRD_PrimarySwitch<hr>\n" ;#if ($debug || $incdebug);

  } else {

    my $sql = "";
    $sql = qq#
SELECT Pharmacy_Name, Software_Vendor, Primary_Switch
FROM OfficeDB.Pharmacy 
WHERE NCPDP = $NCPDP
#;
    (my $sqlout = $sql) =~ s/\n/<br>\n/g;
    print "1. sql:<br>$sqlout<br>\n" if ($testing || $incdebug || $debug);

    my $sth22 = $dbx->prepare($sql);
    my $rowsfoundPharmacy = $sth22->execute;
    if ( $rowsfoundPharmacy =~ /^0|0E0/i ) {
      $rowsfoundPharmacy = 0;
    }
  
    my $Pharmacy_Name  = "";
    my $SoftwareVendor = "";
    my $PrimarySwitch  = "";
  
    if ( $rowsfoundPharmacy <= 0 ) {
      print "No Pharmacy Rows Found<br>\n";
    } else {
      print "#"x96,"<br>\n" if ($incdebug);
      while ( my @row = $sth22->fetchrow_array() ) {
        ($Pharmacy_Name, $SoftwareVendor, $PrimarySwitch) = @row;
      }
      $sth22->finish;
      print "Setting GRRD variables<br>\n" if ($debug);
      $GRRD_Pharmacy_Name  = $Pharmacy_Name;
      $GRRD_SoftwareVendor = $SoftwareVendor;
      $GRRD_PrimarySwitch  = $PrimarySwitch;
    }

  }
  $Pharmacy_Name  = $GRRD_Pharmacy_Name;
  $SoftwareVendor = $GRRD_SoftwareVendor;
  $PrimarySwitch  = $GRRD_PrimarySwitch;

  if ( $debug ) {
#    print "<hr><br>Using:<br>\n";
     print "<hr>\n";
     print "<table border=1 width=100%>\n";
     print "<tr><td width=50%>Pharmacy_Name </td><td>  $Pharmacy_Name</td></tr>\n";
     print "<tr><td width=50%>SoftwareVendor</td><td>  $SoftwareVendor</td></tr>\n";
     print "<tr><td>PrimarySwitch </td><td>  $PrimarySwitch\n</td></tr>";
     print "</table>\n";
  }

  #-------------------------------------------------------------

  $FIELDS = qq# dbNCPDPNumber, dbBinNumber, dbRxNumber, dbFillNumber, dbDateOfService, dbMediSpanBrandOrGeneric, dbBrandOrGeneric, dbParishCountyTax, dbMedicaidProviderFee, dbPatientPayAmount, dbPatientPayAmountPaid, dbIngredientCost, dbIngredientCostPaid, dbGrossAmountDue, dbDispensingFeePaid, dbTotalAmountPaid, dbUsualAndCustomaryCharge, dbSwVendor, dbPrescriberID, dbPrescriberLastName, dbNDC, dbTCode, dbDateTransmitted, dbProcessorControlNumber, dbGroupID, dbQuantityDispensed, dbDaysSupply, dbCompoundCode, dbOtherPayerCoverageType, dbCash #;

  $sql = qq# 
SELECT $FIELDS, DB
FROM (
  SELECT $FIELDS, DB
  FROM ( 
    SELECT $FIELDS, 'RBSDATA' as DB
    FROM $DBNAME.$TABLE
    WHERE (1=1)#;
  
  if ( $Detail =~ /Rx/i ) {
    my @pcsx = split(/##/, $Detail);
    my $jNCPDP   = $pcsx[1];
    my $rxnumber = $pcsx[2];
    my $dosx     = $pcsx[3];
    my $fillnum  = $pcsx[4];
    #print "jNCPDP: $jNCPDP, rxnumber: $rxnumber, dosx: $dosx, fillnum: $fillnum<br>\n";
  
    $sql .= qq#
    && dbNCPDPNumber= $jNCPDP 
    && dbRxNumber   = $rxnumber#;
    if ( $fillnum =~ /^(0|[1-9][0-9]*)$/ ) {
      #If fillnum is numeric, us it
      $sql .= qq#
    && dbFillNumber = $fillnum#;
    } else {
      $sql .= qq#
    && dbDateOfService = $dosx#;
    }
  } else {
    $sql .= qq#
    && dbNCPDPNumber = $NCPDP#;
  }
  
  $sql .= qq#
    && dbDateTransmitted >= 0 
    && (dbDateOfService>=$StartDate && dbDateOfService<=$EndDate)#;
  $sql .= qq#
    $doPrescriberID# if ( $doPrescriberID );
  $sql .= qq#
    $ExcBINs#        if ( $ExcBINs );
  $sql .= qq#
  ) alldata
  WHERE (1=1)
  && (dbTCode = '' || dbTCode IS NULL)
  ORDER BY dbRxNumber, dbDateOfService, dbOtherPayerCoverageType asc
) filtered
  #;

  my $sqlout = "";
  if ( $ENV{"COMPUTERNAME"} =~ /$BATCHSERVERS/i ) {
     $sqlout = $sql;
  } else {
     ($sqlout = $sql) =~ s/\n/<br>\n/g;
  }

  if ( $testing ) {
     print "<br>\n", "-"x96, "<br>\n", "2. find sql:<br>\n$sqlout\n<br>\n", "-"x96, "\n<br>\n";
  } else {
     print "<hr>2. sql:<br>\n$sqlout<br>\n<hr><br>\n" if ($incdebug);
  }
  
  $TotalScriptCount    = 0;
  $BrandScriptCount    = 0;
  $GenericScriptCount  = 0;
  $UnknownScriptCount  = 0;

  $TotalTotalRevenue   = 0;
  $BrandTotalRevenue   = 0;
  $GenericTotalRevenue = 0;
  $UnknownTotalRevenue = 0;

  $TotalTotalCost      = 0;
  $BrandTotalCost      = 0;
  $GenericTotalCost    = 0;
  $UnknownTotalCost    = 0;
  
  print "sth24: here!\n\n" if ($incdebug);
  my $sth24 = $dbx->prepare($sql);
  my $rowsfoundSelect = $sth24->execute;

  if ( $rowsfoundSelect =~ /^0|0E0/i ) {
     $rowsfoundSelect = 0;
  }

  if ( $rowsfoundSelect <= 0 ) {
   
    if ( $Detail =~ /Rx/i ) {
      $key = "0##0##0";
      $RxNumbers{$key}   = "NA";
      $FillNumbers{$key} = "NA";
      $BGs{$key}         = "NA";
      $SALEs{$key}       = "NA";
      $COSTs{$key}       = "NA";
      $BinNumbers{$key}  = "NA";
      $salecalcs{$key}   = "NA";
      $costcalcs{$key}   = "NA";
      $DBs{$key}         = "NA";
      $CASHorTPPs{$key}  = "NA";
      $GMs{$key}         = "NA";
      $DOSs{$key}        = "NA";
      $DateTransmitteds{$key} = "NA";
      $PCNs{$key}        = "NA";
      $Groups{$key}      = "NA";
      $NDCs{$key}        = "NA";
      $TCodes{$key}      = "NA";
      $Quantity{$key}    = "NA"; #Added 10/27/2014
      $DaysSupply{$key}  = "NA"; #Added 11/14/2014
      $RCOSTs{$key}      = "NA"; #Added 11/14/2014
      $RGMs{$key}        = "NA"; #Added 11/14/2014
      $PBMs{$key}        = "NA"; #Added 11/14/2014
      $PAI_Payer_Names{$key} = "NA"; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = "NA"; #Added 11/14/2014
      $PrescriberIDs{$key} = "NA"; #Added 05/20/2015
	  $CashFlags{$key} = "NA"; #Added 05/11/2018
    } else {
      print "No Rows Found<br>\n";
    }
    
  } else {
    print "#"x96,"<br>\n" if ($incdebug);

    #Should stay default, unless any calculation exceptions are used.
    $using = "Default";

    #Start Per Claim Calculations

    my $jcnt = 0;

    while ( my @row = $sth24->fetchrow_array() ) {

      ($dbNCPDPNumber, $dbBinNumber, $dbRxNumber, $dbFillNumber, $dbDateOfService, $dbMediSpanBrandOrGeneric, $dbBrandOrGeneric, $dbParishCountyTax, $dbMedicaidProviderFee, $dbPatientPayAmount, $dbPatientPayAmountPaid, $dbIngredientCost, $dbIngredientCostPaid, $dbGrossAmountDue, $dbDispensingFeePaid, $dbTotalAmountPaid, $dbUsualAndCustomaryCharge, $dbSwVendor, $dbPrescriberID, $dbPrescriberLastName, $dbNDC, $dbTCode, $dbDateTransmitted, $dbProcessorControlNumber, $dbGroupID, $dbQuantityDispensed, $dbDaysSupply, $dbCompoundCode, $dbOtherPayerCoverageType, $dbCash, $DB) = @row;

      $jcnt++;
      printf ("%i5) yo2. NCPDP: $dbNCPDPNumber, BIN: $dbBinNumber, PCN: $dbProcessorControlNumber, Group: $dbGroupID, Rx: $dbRxNumber\n", $jcnt) if ($incdebug);

      my $NOVALUE = -20000;
     
      #Zero out any unknown values
      #
      if ( $dbParishCountyTax         == $NOVALUE ) { $dbParishCountyTax         = 0; }
      if ( $dbMedicaidProviderFee     == $NOVALUE ) { $dbMedicaidProviderFee     = 0; }
      if ( $dbPatientPayAmountPaid    == $NOVALUE ) { $dbPatientPayAmountPaid    = 0; }
      if ( $dbPatientPayAmount        == $NOVALUE ) { $dbPatientPayAmount        = 0; }
      if ( $dbIngredientCost          == $NOVALUE ) { $dbIngredientCost          = 0; }
      if ( $dbIngredientCostPaid      == $NOVALUE ) { $dbIngredientCostPaid      = 0; }
      if ( $dbDispensingFeePaid       == $NOVALUE ) { $dbDispensingFeePaid       = 0; }
      if ( $dbGrossAmountDue          == $NOVALUE ) { $dbGrossAmountDue          = 0; }
      if ( $dbTotalAmountPaid         == $NOVALUE ) { $dbTotalAmountPaid         = 0; }
      if ( $dbUsualAndCustomaryCharge == $NOVALUE ) { $dbUsualAndCustomaryCharge = 0; }
      if ( $dbQuantityDispensed       == $NOVALUE ) { $dbQuantityDispensed       = 0; }
      if ( $dbIngredientCost          == 999999.99) { $dbIngredientCost          = 0; }

      # do calculations on these values
       
      $salecalc  = "";
      $costcalc  = "";
      $CASHorTPP = "";
      $bg        = "";

      #Determine Brand/Generic
      if ( $dbMediSpanBrandOrGeneric !~ /^\s*$/ ) {
        $bg = $dbMediSpanBrandOrGeneric;
      } else {
        $bg = "";
      }
     
      #####################################################################################
      #Start Claim Filter
      #####################################################################################
     
      #Filter out Medicare Part B
      if ($dbBinNumber == 4766) {
        next;
      }
      
      #Filter out 'bogus' non-compound NDC values
      if ( $dbCompoundCode != 2 #NOT a compound
           && (
             $dbNDC <= 0 || 
             $dbNDC =~ /^00000/ || 
             $dbNDC =~ /^11111/ || 
             $dbNDC =~ /^22222/ || 
             $dbNDC =~ /^33333/ || 
             $dbNDC =~ /^44444/ || 
             $dbNDC =~ /^55555/ || 
             $dbNDC =~ /^66666/ || 
             $dbNDC =~ /^77777/ || 
             $dbNDC =~ /^88888/ || 
             $dbNDC =~ /^99999/ 
           )
         ) {
        next;
      }

      #This will capture the COB information needed for calculations && should get rid of duplicates
      next if $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0}{$dbOtherPayerCoverageType};
      if (!$cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
        $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbTotalAmountPaid;  
        $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbIngredientCost;  
        $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbIngredientCostPaid;  
        $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbParishCountyTax;  
        $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbMedicaidProviderFee;  
        $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbBinNumber;  
        $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbProcessorControlNumber;  
        $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbGroupID;  
        $TotalScriptCount++;

        #Brand/Generic Counts
        if      ( $bg =~ /B/i ) { 
          $BrandScriptCount++; 
        } elsif ( $bg =~ /G/i ) { 
          $GenericScriptCount++; 
        } else { 
          $UnknownScriptCount++; 
        }
      }

      $ISCASH = 0;
          
      if ($dbBinNumber == 14798 || $dbBinNumber == 0 || $dbBinNumber == 747474) {
        $ISCASH++;
      }

      ###Calculate revenue based on CASH or TPP sale

      if ( $ISCASH ) {
        if ( $debug ) {
           print "<hr size=8 color=red>ISCASH! SoftwareVendor: $SoftwareVendor<br>\n";
           $jjptr++;
        }

        #CASH Sale, CASH determined by BIN Number (above)
           
        $salecalc .= "CASH | ";
        $CASHorTPP = "CASH";
       
        if ($SoftwareVendor =~ /ComputerRx/i ) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - ComputerRx: $dbPatientPayAmountPaid";
            print "1. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);

        } elsif ($SoftwareVendor =~ /Prism/i || ($NCPDP == 1917078 && $dbDateOfService < 20140901) ) {
          #Causey Prism Software Transition Exception
          if ($dbPatientPayAmount != 0) {
            $SALE = $dbPatientPayAmount;
            $salecalc .= "PPA - PRISM: $dbPatientPayAmount";
            print "2. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } else {
            $SALE = $dbGrossAmountDue;
            $salecalc .= "GAD - PRISM: $dbGrossAmountDue";
            print "3. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          }
          
        } else {

          if        ( $dbGrossAmountDue  != 0 ) {
            $SALE = $dbGrossAmountDue;
            $salecalc .= "GAD: $dbGrossAmountDue";
            print "4. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } elsif ( $dbTotalAmountPaid != 0 ) {
            $SALE = $dbTotalAmountPaid;
            $salecalc .= "TAP: $dbTotalAmountPaid";
            print "5. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } elsif ( $dbUsualAndCustomaryCharge != 0 ) {
            $SALE = $dbUsualAndCustomaryCharge;
            $salecalc .= "U&C: $dbUsualAndCustomaryCharge";
            print "6. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } else {
            $SALE = $dbIngredientCostPaid;
            $salecalc .= "ICP: $dbIngredientCostPaid";
            print "7. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          }
        }
      
        if ($SoftwareVendor =~ /Pioneer/i ) {
          if ($dbProcessorControlNumber =~ /^CP$/i && $dbGroupID =~ /^95NONE$/i) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - CP Exception: $dbPatientPayAmountPaid";
            print "8. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } 
        }
        
      } else {
            
        #TPP Sale
     
        $salecalc .= "TPP | ";
        $CASHorTPP = "TPP";
           
        if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
          if ($dbSwVendor ne 'Rx30' && $dbOtherPayerCoverageType > 0 || $dbSwVendor eq 'Rx30' && $dbOtherPayerCoverageType == 0) { 
            $dbTotalAmountPaid        += $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};   
            $dbIngredientCost         = $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
            $dbIngredientCostPaid     = $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
	    $dbParishCountyTax        = $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbBinNumber              = $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbProcessorControlNumber = $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbGroupID                = $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
	    $dbMedicaidProviderFee = $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
          }
	  else {
            next;
	  }
        }


        if ( $dbSwVendor =~ /RedSail/i ) {
          #QS1 per claim exception...
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid
          );
          $salecalc .= "TAP - QS1/RedSail Exception: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid";
        } else {
          #Default TPP Sale Calculation
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid - $dbMedicaidProviderFee 
          );
          $salecalc .= "TAP: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid - Med: $dbMedicaidProviderFee";
        }
      }
         
      ##Controls the COB Amounts
      my $TSALE = $SALE;
      $TSALE    = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});

      #Add to total revenue
      $TotalTotalRevenue += $TSALE;

      #Add to B/G/U revenue
      if ($bg =~ /B/i ) { 
        $BrandTotalRevenue   += $TSALE;
      } elsif ($bg =~ /G/i ) { 
        $GenericTotalRevenue += $TSALE;
      } else { 
        $UnknownTotalRevenue += $TSALE;
      }

      $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} = $SALE;   

      ###Calculate cost
#      if ( $340BType =~ /Cash/i ) {
#        $COST = 0;
#        $costcalc .= "BFF - NONE";
#      elsif ($dbIngredientCost != 0) {
      if ($dbIngredientCost != 0) {
        $COST = $dbIngredientCost;
        $costcalc .= "IC - $dbIngredientCost";
      } elsif ($dbIngredientCostPaid != 0) {
        $COST = $dbIngredientCostPaid;
        $costcalc .= "ICP - $dbIngredientCostPaid";
      } else {
        $COST = 0;
        $costcalc .= "NONE";
      }
       
      ##Controls the COB Amounts
      my $TCOST = $COST;
      $TCOST    = 0 if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      #Add to total cost
      $TotalTotalCost += $TCOST;

      #Add to B/G/U cost
      if ($bg =~ /B/i) { 
        $BrandTotalCost += $TCOST;
      } elsif ($bg =~ /G/i) { 
        $GenericTotalCost += $TCOST;
      } else { 
        $UnknownTotalCost += $TCOST;
      }

      if      ( $bg =~ /B/i ) {
        $COST = $COST * (1-$RebateBrand);
      } elsif ( $bg =~ /G/i ) {
        $COST = $COST * (1-$RebateGeneric);
      }
     
      #Create plan lookup key, remove leading zeros
      my $BIN_KEY   = $dbBinNumber;
      my $PCN_KEY   = $dbProcessorControlNumber;
      my $GROUP_KEY = $dbGroupID;
     
      $BIN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $PCN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $GROUP_KEY =~ s/^0+//gi; #Remove leading zeros
      
      $BIN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $PCN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $GROUP_KEY =~ s/^\s+//gi; #Remove leading spaces
     
      my $planKEY   = uc("$BIN_KEY##$PCN_KEY##$GROUP_KEY");
     
      #Tie in with plan from &loadPlanLookup
      my $PBM = $PBM{$planKEY} || "";
      my $PAI_Payer_Name = $PAI_Payer_Name{$planKEY} || $planKEY;
      my $Comm_MedD_Medicaid = $Comm_MedD_Medicaid{$planKEY} || "";
     
      #IF the BIN is blank, 0, or -20000, the plan is CASH, override here.
      if ($BIN_KEY =~ /^\s*$|^0+$|-20000/) {
        $PBM                = "CASH";
        $PAI_Payer_Name     = "CASH";
        $Comm_MedD_Medicaid = "CASH";
      }
     
      #Use &loadRebateLookup data to create rebated (R)COST and rebated (R)GM
      my $YYYYMM_lookup = substr($dbDateOfService, 0, 6);
      if ($bg =~ /B/i) {
        my $brand_rebate = $rebateBrandDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $brand_rebate);
      } elsif ($bg =~ /G/i) {
        my $generic_rebate = $rebateGenericDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $generic_rebate);
      } else {
        $RCOST = $COST;
      }
     
      $RGM = $SALE - $RCOST; #Rebated GM
      $GM  = $SALE - $COST; #Non-Rebated GM
     
      $dbNDC = sprintf("%011d", $dbNDC); #Format NDC to 11 digits
     
      $key = "$dbNCPDPNumber##$dbRxNumber##$dbFillNumber##$dbDateOfService";
      $RxNumbers{$key}   = $dbRxNumber;
      $FillNumbers{$key} = $dbFillNumber;
      $BGs{$key}         = $bg;
      $SALEs{$key}       = sprintf("%.2f", $SALE);
      $COSTs{$key}       = sprintf("%.2f", $COST);
      $BinNumbers{$key}  = $dbBinNumber;
      $DBs{$key}         = $DB;
      $CASHorTPPs{$key}  = $CASHorTPP;
      $GMs{$key}         = sprintf("%.2f", $GM);
      $salecalcs{$key}   = $salecalc;
      $costcalcs{$key}   = $costcalc;
      $DOSs{$key}        = $dbDateOfService;
      $DateTransmitteds{$key} = $dbDateTransmitted;
      $PCNs{$key}        = $dbProcessorControlNumber;
      $Groups{$key}      = $dbGroupID;
      $NDCs{$key}        = $dbNDC;
      $TCodes{$key}      = $dbTCode;
      $Quantity{$key}    = $dbQuantityDispensed; #Added 10/27/2014
      $DaysSupply{$key}  = $dbDaysSupply; #Added 11/14/2014
     
      $RCOSTs{$key}      = $RCOST; #Added 11/14/2014
      $RGMs{$key}        = $RGM; #Added 11/14/2014
     
      $PBMs{$key}                = $PBM; #Added 11/14/2014
      $PAI_Payer_Names{$key}     = $PAI_Payer_Name; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = $Comm_MedD_Medicaid; #Added 11/14/2014
     
      $PrescriberIDs{$key} = $dbPrescriberID; #Added 05/20/2015
      $PrescriberLastName{$key} = $dbPrescriberLastName; 
      $CashFlags{$key}     = $dbCash; #Added 05/11/2018

      $cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}                               = 1;
      $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}{$dbOtherPayerCoverageType} = 1;
    }
    $sth24->finish;
    print "total jcnt: $jcnt, NCPDP: $dbNCPDPNumber\n" if ($incdebug);
  }

  print qq#sub Get_RBSReporting_Data. Exit. Detail: $Detail<br>\n# if ($incdebug);
  print "-"x96, "<br>\n" if ($incdebug);

  if ( $Detail =~ /Y|YH|Rx/i ) {

    return ( \%RxNumbers, \%FillNumbers, \%BGs, \%SALEs, \%COSTs, \%BinNumbers, \%DBs,
             \%CASHorTPPs, \%GMs, \%salecalcs, \%costcalcs, \%DOSs, \%DateTransmitteds,
             \%PCNs, \%Groups, \%NDCs, \%TCodes, \%Quantity, \%DaysSupply, 
             \%RCOSTs, \%RGMs, \%PBMs, \%PAI_Payer_Names, \%Comm_MedD_Medicaids, 
             \%PrescriberIDs, \%CashFlags, \%PrescriberLastName );

  } else {
    $BrandScriptCount  += $UnknownScriptCount;
    $BrandTotalRevenue += $UnknownTotalRevenue;
    $BrandTotalCost    += $UnknownTotalCost;

    $BrandTotalRevenue   = sprintf("%.2f", $BrandTotalRevenue);
    $BrandTotalCost      = sprintf("%.2f", $BrandTotalCost);
    $GenericTotalRevenue = sprintf("%.2f", $GenericTotalRevenue);
    $GenericTotalCost    = sprintf("%.2f", $GenericTotalCost);
    $TotalTotalRevenue   = sprintf("%.2f", $TotalTotalRevenue);
    $TotalTotalCost      = sprintf("%.2f", $TotalTotalCost);

    return ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
             $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
             $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost);
  }
}

#______________________________________________________________________________
# _____________________________________________________________________________
#

sub Get_RBSReporting_Data_340B {
  my ($NCPDP, $StartDate, $EndDate, $Detail, $RebateBrand, $RebateGeneric, $NPIstring, $ExcBINstring, $TDS, $Pharmacy_ID) = @_;

  my %cob;
  my %tap;
  my %ic;
  my %icp;
  my %pct;
  my %mpf;
  my %ttr;
  my %record;
  my %bn;
  my %pcn;
  my %gid;
  my $dbin;

# my $incdebug++;
# my $debug++;
  
  if ( $incdebug ) {
     print "-"x96, "<br>\n";
     print "sub Get_RBSReporting_Data. Entry. NCPDP: $NCPDP, StartDate: $StartDate, EndDate: $EndDate, Detail: $Detail, RebateBrand: $RebateBrand, RebateGeneric: $RebateGeneric<br>\n  NPIstring: $NPIstring<br>  ExcBINstring: $ExcBINstring<br> <br>\n";
     print "$prog: dbTCodes: $dbTCodes<hr>\n\n" if ($incdebug);
     print "DOPHARMACY($NCPDP): $DOPHARMACY{$NCPP}<hr>\n";

  }
  print "testing: $testing<br>\n" if ($debug || $incdebug || $testing);

  my ( %RxNumbers, %FillNumbers, %BGs, %SALEs, %COSTs, %BinNumbers, %DBs,
       %CASHorTPPs, %GMs, %salecalcs, %costcalcs, %DOSs, %DateTransmitteds,
       %PCNs, %Groups, %NDCs, %TCodes, %Quantity, %DaysSupply, 
       %RCOSTs, %RGMs, %PBMs, %PAI_Payer_Names, %Comm_MedD_Medicaids, 
       %PrescriberIDs, %CashFlags);

  my ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
       $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
       $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost, $TotalIngredientCost);
     
  # Load data lookup hashes on first run only
  # ---------------------------------------------------------------- #
 
  #if( ! defined $rebatesLoaded || $rebatesLoaded <= 0 )  
  
  if ( !$rebatesLoaded || $rebatesLoaded != $NCPDP ) {
    &loadRebateLookup($NCPDP);
  }
  if( !$plansLoaded || $plansLoaded <= 0 ) {
    &loadPlanLookup;
  }
# print "here!<br>\n";

  # ---------------------------------------------------------------- #

  if ( $incdebug) {
     print "NPIstring   : $NPIstring<br>\n";
     print "ExcBINstring: $ExcBINstring<br>\n";
  }

  if ( $NPIstring =~ /^\s*$/ ) {
    $doPrescriberID = qq##;
  } else {
    $doPrescriberID = qq# && dbPrescriberID in($NPIstring) #;
  }
  print "<hr>doPrescriberID: $doPrescriberID<hr><br>\n" if ($incdebug);
  #-------------

  if ( $ExcBINstring =~ /^\s*$/ ) {
    $ExcBINs = qq##;
  } else {
    $ExcBINs = qq# && dbBinNumber NOT in($ExcBINstring) #;
  }
  print "<hr>ExcBINs: $ExcBINs<hr><br>\n" if ($incdebug);
  #-------------

  if ($TDS && $TDS =~ /^Y/i) {
    $dbin = "TDDBNAME";
  }
  else {  
    $dbin = "RRDBNAME";
  }

  if ( $testing ) {

    print "\n\n\n FATAL: FIX ME!!!!!!!!!!!!!!!!!!!!!!!! \n\n\n<br>\n";
  
    ########################################
    # BEG - TESTING SECTION SETUP
    ########################################
    
    # Comment out this block when done testing!!!!!
    
      $JJJ = $DBNAMES{$dbin}; print "JJJ: $JJJ<br>\n";
    
      $WHICHDB = "testing";		# Valid Values: "Testing" or "Webinar"
      &set_Webinar_or_Testing_DBNames;
      if ( $DBNAMES{$dbin} =~ /^\s*$/ ) {
         $DBNAMES{$dbin} = $JJJ;
         print qq#Found dbin's ($dbin) DBNAME was blank. Setting to "testing"<br>\n# if ($debug || $testing);
      } else {
#        print "HHHHHHHHHHH\n";
      }
    
      $HHH = $DBNAMES{$dbin}; print "HHH: $HHH<br>\n";
    
    ########################################
    # END - TESTING SECTION SETUP
    ########################################
  
  }

  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  $DBNAME = 'Webinar' if($USER == 2182);

  $Pharmacy_Name  = "";
  $SoftwareVendor = "";
  $PrimarySwitch  = "";

  #-------------------------------------------------------------
  
  if ( !$PharmacyWanted ) {
     $PharmacyWanted = $NCPDP;
  }
  if ( !$NCPDP ) {
     $NCPDP = $PharmacyWanted;
  }
  print "<hr> 2. NCPDP: $NCPDP, PharmacyWanted: $PharmacyWanted, DOPHARMACY($PharmacyWanted): $DOPHARMACY{$PharmacyWanted}<br>\n" if ($debug);

  if ( $GRRD_Pharmacy_Name && $DOPHARMACY{$PharmacyWanted} > 1 ) {

    print "Skipping DB Query. Using GRRD vars. GRRD_Pharmacy_Name: $GRRD_Pharmacy_Name, GRRD_SoftwareVendor: $GRRD_SoftwareVendor, GRRD_PrimarySwitch: $GRRD_PrimarySwitch<hr>\n" ;#if ($debug || $incdebug);

  } else {

    my $sql = "";
    $sql = qq#
SELECT Pharmacy_Name, Software_Vendor, Primary_Switch
FROM OfficeDB.Pharmacy 
WHERE Pharmacy_ID = $Pharmacy_ID
#;
    (my $sqlout = $sql) =~ s/\n/<br>\n/g;
    print "1. sql:<br>$sqlout<br>\n" if ($testing || $incdebug || $debug);

    my $sth22 = $dbx->prepare($sql);
    my $rowsfoundPharmacy = $sth22->execute;
    if ( $rowsfoundPharmacy =~ /^0|0E0/i ) {
      $rowsfoundPharmacy = 0;
    }
  
    my $Pharmacy_Name  = "";
    my $SoftwareVendor = "";
    my $PrimarySwitch  = "";
  
    if ( $rowsfoundPharmacy <= 0 ) {
      print "No Pharmacy Rows Found<br>\n";
    } else {
      print "#"x96,"<br>\n" if ($incdebug);
      while ( my @row = $sth22->fetchrow_array() ) {
        ($Pharmacy_Name, $SoftwareVendor, $PrimarySwitch) = @row;
      }
      $sth22->finish;
      print "Setting GRRD variables<br>\n" if ($debug);
      $GRRD_Pharmacy_Name  = $Pharmacy_Name;
      $GRRD_SoftwareVendor = $SoftwareVendor;
      $GRRD_PrimarySwitch  = $PrimarySwitch;
    }

  }
  $Pharmacy_Name  = $GRRD_Pharmacy_Name;
  $SoftwareVendor = $GRRD_SoftwareVendor;
  $PrimarySwitch  = $GRRD_PrimarySwitch;

  if ( $debug ) {
#    print "<hr><br>Using:<br>\n";
     print "<hr>\n";
     print "<table border=1 width=100%>\n";
     print "<tr><td width=50%>Pharmacy_Name </td><td>  $Pharmacy_Name</td></tr>\n";
     print "<tr><td width=50%>SoftwareVendor</td><td>  $SoftwareVendor</td></tr>\n";
     print "<tr><td>PrimarySwitch </td><td>  $PrimarySwitch\n</td></tr>";
     print "</table>\n";
  }

  #-------------------------------------------------------------

  $FIELDS = qq# dbNCPDPNumber, dbBinNumber, dbBinParentdbkey, dbRxNumber, dbFillNumber, dbDateOfService, dbMediSpanBrandOrGeneric, dbBrandOrGeneric, dbParishCountyTax, dbMedicaidProviderFee, dbPatientPayAmount, dbPatientPayAmountPaid, dbIngredientCost, dbIngredientCostPaid, dbGrossAmountDue, dbDispensingFeePaid, dbTotalAmountPaid, dbUsualAndCustomaryCharge, dbSwVendor, dbPrescriberID, dbPrescriberLastName, dbNDC, dbTCode, dbDateTransmitted, dbProcessorControlNumber, dbGroupID, dbQuantityDispensed, dbDaysSupply, dbCompoundCode, dbOtherPayerCoverageType, dbCash, 340BFillFee, 340BType #;

  $sql = qq# 
SELECT $FIELDS, DB
FROM (
  SELECT $FIELDS, DB
  FROM ( 
    SELECT $FIELDS, 'RBSDATA' as DB
    FROM $DBNAME.$TABLE
    WHERE (1=1)#;
  
  if ( $Detail =~ /Rx/i ) {
    my @pcsx = split(/##/, $Detail);
    my $jNCPDP   = $pcsx[1];
    my $rxnumber = $pcsx[2];
    my $dosx     = $pcsx[3];
    my $fillnum  = $pcsx[4];
    #print "jNCPDP: $jNCPDP, rxnumber: $rxnumber, dosx: $dosx, fillnum: $fillnum<br>\n";
  
    $sql .= qq#
    && Pharmacy_ID= $Pharmacy_ID
    && dbRxNumber   = $rxnumber#;
    if ( $fillnum =~ /^(0|[1-9][0-9]*)$/ ) {
      #If fillnum is numeric, us it
      $sql .= qq#
    && dbFillNumber = $fillnum#;
    } else {
      $sql .= qq#
    && dbDateOfService = $dosx#;
    }
  } else {
    $sql .= qq#
    && dbNCPDPNumber = $NCPDP#;
  }
  
  $sql .= qq#
    && dbDateTransmitted >= 0 
    && (dbDateOfService>=$StartDate && dbDateOfService<=$EndDate)#;
  $sql .= qq#
    $doPrescriberID# if ( $doPrescriberID );
  $sql .= qq#
    $ExcBINs#        if ( $ExcBINs );
  $sql .= qq#
  ) alldata
  WHERE (1=1)
  && (dbTCode = '' || dbTCode IS NULL)
  ORDER BY dbRxNumber, dbDateOfService, dbOtherPayerCoverageType asc
) filtered
  #;

  my $sqlout = "";
  if ( $ENV{"COMPUTERNAME"} =~ /$BATCHSERVERS/i ) {
     $sqlout = $sql;
  } else {
     ($sqlout = $sql) =~ s/\n/<br>\n/g;
  }

  if ( $testing ) {
     print "<br>\n", "-"x96, "<br>\n", "2. find sql:<br>\n$sqlout\n<br>\n", "-"x96, "\n<br>\n";
  } else {
     print "<hr>2. sql:<br>\n$sqlout<br>\n<hr><br>\n" if ($incdebug);
  }
  
  $TotalScriptCount    = 0;
  $BrandScriptCount    = 0;
  $GenericScriptCount  = 0;
  $UnknownScriptCount  = 0;

  $TotalTotalRevenue   = 0;
  $BrandTotalRevenue   = 0;
  $GenericTotalRevenue = 0;
  $UnknownTotalRevenue = 0;

  $TotalTotalCost      = 0;
  $BrandTotalCost      = 0;
  $GenericTotalCost    = 0;
  $UnknownTotalCost    = 0;
  $TotalIngredientCost = 0;
  $IngredientTotalCost = 0;
  
  print "sth24: here!\n\n" if ($incdebug);
  my $sth24 = $dbx->prepare($sql);
  my $rowsfoundSelect = $sth24->execute;

  if ( $rowsfoundSelect =~ /^0|0E0/i ) {
     $rowsfoundSelect = 0;
  }

  if ( $rowsfoundSelect <= 0 ) {
   
    if ( $Detail =~ /Rx/i ) {
      $key = "0##0##0";
      $RxNumbers{$key}   = "NA";
      $FillNumbers{$key} = "NA";
      $BGs{$key}         = "NA";
      $SALEs{$key}       = "NA";
      $COSTs{$key}       = "NA";
      $BinNumbers{$key}  = "NA";
      $salecalcs{$key}   = "NA";
      $costcalcs{$key}   = "NA";
      $DBs{$key}         = "NA";
      $CASHorTPPs{$key}  = "NA";
      $GMs{$key}         = "NA";
      $DOSs{$key}        = "NA";
      $DateTransmitteds{$key} = "NA";
      $PCNs{$key}        = "NA";
      $Groups{$key}      = "NA";
      $NDCs{$key}        = "NA";
      $TCodes{$key}      = "NA";
      $Quantity{$key}    = "NA"; #Added 10/27/2014
      $DaysSupply{$key}  = "NA"; #Added 11/14/2014
      $RCOSTs{$key}      = "NA"; #Added 11/14/2014
      $RGMs{$key}        = "NA"; #Added 11/14/2014
      $PBMs{$key}        = "NA"; #Added 11/14/2014
      $PAI_Payer_Names{$key} = "NA"; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = "NA"; #Added 11/14/2014
      $PrescriberIDs{$key} = "NA"; #Added 05/20/2015
	  $CashFlags{$key} = "NA"; #Added 05/11/2018
    } else {
      print "No Rows Found<br>\n";
    }
    
  } else {
    print "#"x96,"<br>\n" if ($incdebug);

    #Should stay default, unless any calculation exceptions are used.
    $using = "Default";

    #Start Per Claim Calculations

    my $jcnt = 0;

    while ( my @row = $sth24->fetchrow_array() ) {

      ($dbNCPDPNumber, $dbBinNumber, $dbBinParentdbkey, $dbRxNumber, $dbFillNumber, $dbDateOfService, $dbMediSpanBrandOrGeneric, $dbBrandOrGeneric, $dbParishCountyTax, $dbMedicaidProviderFee, $dbPatientPayAmount, $dbPatientPayAmountPaid, $dbIngredientCost, $dbIngredientCostPaid, $dbGrossAmountDue, $dbDispensingFeePaid, $dbTotalAmountPaid, $dbUsualAndCustomaryCharge, $dbSwVendor, $dbPrescriberID, $dbPrescriberLastName, $dbNDC, $dbTCode, $dbDateTransmitted, $dbProcessorControlNumber, $dbGroupID, $dbQuantityDispensed, $dbDaysSupply, $dbCompoundCode, $dbOtherPayerCoverageType, $dbCash, $BFillFee, $BType, $DB) = @row;
      
      $jcnt++;
      printf ("%i) yo2. NCPDP: $dbNCPDPNumber, BIN: $dbBinNumber, PCN: $dbProcessorControlNumber, Group: $dbGroupID, Rx: $dbRxNumber\n", $jcnt) if ($incdebug);

      my $NOVALUE = -20000;
     
      #Zero out any unknown values
      #
      if ( $dbParishCountyTax         == $NOVALUE ) { $dbParishCountyTax         = 0; }
      if ( $dbMedicaidProviderFee     == $NOVALUE ) { $dbMedicaidProviderFee     = 0; }
      if ( $dbPatientPayAmountPaid    == $NOVALUE ) { $dbPatientPayAmountPaid    = 0; }
      if ( $dbPatientPayAmount        == $NOVALUE ) { $dbPatientPayAmount        = 0; }
      if ( $dbIngredientCost          == $NOVALUE ) { $dbIngredientCost          = 0; }
      if ( $dbIngredientCostPaid      == $NOVALUE ) { $dbIngredientCostPaid      = 0; }
      if ( $dbDispensingFeePaid       == $NOVALUE ) { $dbDispensingFeePaid       = 0; }
      if ( $dbGrossAmountDue          == $NOVALUE ) { $dbGrossAmountDue          = 0; }
      if ( $dbTotalAmountPaid         == $NOVALUE ) { $dbTotalAmountPaid         = 0; }
      if ( $dbUsualAndCustomaryCharge == $NOVALUE ) { $dbUsualAndCustomaryCharge = 0; }
      if ( $dbQuantityDispensed       == $NOVALUE ) { $dbQuantityDispensed       = 0; }
      if ( $dbIngredientCost          == 999999.99) { $dbIngredientCost          = 0; }

      # do calculations on these values
       
      $salecalc  = "";
      $costcalc  = "";
      $CASHorTPP = "";
      $bg        = "";

      #Determine Brand/Generic
      if ( $dbMediSpanBrandOrGeneric !~ /^\s*$/ ) {
        $bg = $dbMediSpanBrandOrGeneric;
      } else {
        $bg = "";
      }
     
      #####################################################################################
      #Start Claim Filter
      #####################################################################################
     
      #Filter out Medicare Part B
      if ($dbBinNumber == 4766) {
        next;
      }
      
      #Filter out 'bogus' non-compound NDC values
      if ( $dbCompoundCode != 2 #NOT a compound
           && (
             $dbNDC <= 0 || 
             $dbNDC =~ /^00000/ || 
             $dbNDC =~ /^11111/ || 
             $dbNDC =~ /^22222/ || 
             $dbNDC =~ /^33333/ || 
             $dbNDC =~ /^44444/ || 
             $dbNDC =~ /^55555/ || 
             $dbNDC =~ /^66666/ || 
             $dbNDC =~ /^77777/ || 
             $dbNDC =~ /^88888/ || 
             $dbNDC =~ /^99999/ 
           )
         ) {
        next;
      }


      #This will capture the COB information needed for calculations && should get rid of duplicates
      next if $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0}{$dbOtherPayerCoverageType};
      if (!$cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
        $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbTotalAmountPaid;  
        if ( $BType =~ /Cash/i ) {
          $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = 0;  
	} else {
          $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbIngredientCost;  
        }
        $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbIngredientCostPaid;  
        $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbParishCountyTax;  
        $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbMedicaidProviderFee;  
        $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}   = $dbBinNumber;  
        $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbProcessorControlNumber;  
        $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $dbGroupID;  
        $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $BType;  
        $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}  = $BFillFee;  
        $TotalScriptCount++;

        #Brand/Generic Counts
        if      ( $bg =~ /B/i ) { 
          $BrandScriptCount++; 
        } elsif ( $bg =~ /G/i ) { 
          $GenericScriptCount++; 
        } else { 
          $UnknownScriptCount++; 
        }
      }

      $ISCASH = 0;
          
      if ($dbBinNumber == 14798 || $dbBinNumber == 0 || $dbBinNumber == 747474) {
        $ISCASH++;
      }

      ###Calculate revenue based on CASH or TPP sale


      if ( ($BType =~ /Cash/i) || ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} && $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i) ) {
#      if ( ($BType =~ /Cash/i) ) {
        $salecalc .= "CASH | ";
        $CASHorTPP = "CASH";
       
        if ( $cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} ) {
          $SALE = $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
          $salecalc .= "BFF : $tfbf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber}";
	} else {
          $SALE = $BFillFee;
          $salecalc .= "BFF : $BFillFee";
	}
      }
      elsif ( $ISCASH ) {
        #CASH Sale, CASH determined by BIN Number (above)
           
        $salecalc .= "CASH | ";
        $CASHorTPP = "CASH";
       
        if ($SoftwareVendor =~ /ComputerRx/i ) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - ComputerRx: $dbPatientPayAmountPaid";
#            print "1. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
        } else {
          if        ( $dbGrossAmountDue  != 0 ) {
            $SALE = $dbGrossAmountDue;
            $salecalc .= "GAD: $dbGrossAmountDue";
            print "4. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } elsif ( $dbTotalAmountPaid != 0 ) {
            $SALE = $dbTotalAmountPaid;
            $salecalc .= "TAP: $dbTotalAmountPaid";
            print "5. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } elsif ( $dbUsualAndCustomaryCharge != 0 ) {
            $SALE = $dbUsualAndCustomaryCharge;
            $salecalc .= "U&C: $dbUsualAndCustomaryCharge";
            print "6. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } else {
            $SALE = $dbIngredientCostPaid;
            $salecalc .= "ICP: $dbIngredientCostPaid";
            print "7. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          }
        }
      
        if ($SoftwareVendor =~ /Pioneer/i ) {
          if ($dbProcessorControlNumber =~ /^CP$/i && $dbGroupID =~ /^95NONE$/i) {
            $SALE = $dbPatientPayAmountPaid;
            $salecalc .= "PPAP - CP Exception: $dbPatientPayAmountPaid";
            print "8. here. NCPDP: $NPCPD, jjptr: $jjptr, SALE: $SALE, salecalc: $salecalc<br>\n" if ($debug);
          } 
        }
        
      } else {
            
        #TPP Sale
     
        $salecalc .= "TPP | ";
        $CASHorTPP = "TPP";
           
        if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
          if ($dbSwVendor ne 'Rx30' && $dbOtherPayerCoverageType > 0 || $dbSwVendor eq 'Rx30' && $dbOtherPayerCoverageType == 0) { 
            if ( $tfb{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i ) {
              $dbTotalAmountPaid        = $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};   
	    } else { 
              $dbTotalAmountPaid        += $tap{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};   
            }
            $dbIngredientCost         = $ic{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
            $dbIngredientCostPaid     = $icp{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};
	    $dbParishCountyTax        = $pct{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbBinNumber              = $bn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbProcessorControlNumber = $pcn{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
            $dbGroupID                = $gid{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
	    $dbMedicaidProviderFee    = $mpf{$dbRxNumber}{$dbDateOfService}{$dbFillNumber};  
          }
	  else {
            next;
	  }
        }


        if ( $dbSwVendor =~ /RedSail/i ) {
          #QS1 per claim exception...
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid
          );
          $salecalc .= "TAP - QS1/RedSail Exception: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid";
        } else {
          #Default TPP Sale Calculation
          $SALE = (
            $dbTotalAmountPaid + $dbPatientPayAmountPaid - $dbMedicaidProviderFee 
          );
          $salecalc .= "TAP: $dbTotalAmountPaid + PPAP: $dbPatientPayAmountPaid - Med: $dbMedicaidProviderFee";
        }
      }
         
      ##Controls the COB Amounts
      my $TSALE = $SALE;
      $TSALE    = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}) {
#        print "$dbRxNumber $dbBiNumber - $TSALE = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0}<br>";
        $TSALE    = $SALE - $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0};
      }

      #Add to total revenue
      $TotalTotalRevenue += $TSALE;

      #Add to B/G/U revenue
      if ($bg =~ /B/i ) { 
        $BrandTotalRevenue   += $TSALE;
      } elsif ($bg =~ /G/i ) { 
        $GenericTotalRevenue += $TSALE;
      } else { 
        $UnknownTotalRevenue += $TSALE;
      }

      $ttr{$dbRxNumber}{$dbDateOfService}{$dbFillNumber+0} = $SALE;   

      ###Calculate cost
      if ($dbIngredientCost != 0) {
        $COST = $dbIngredientCost;
        $costcalc .= "IC - $dbIngredientCost";
      } elsif ($dbIngredientCostPaid != 0) {
        $COST = $dbIngredientCostPaid;
        $costcalc .= "ICP - $dbIngredientCostPaid";
      } else {
        $COST = 0;
        $costcalc .= "NONE";
      }

      $IngredientTotalCost += $COST if (!$cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      $IC = $COST;

      ###Override cost if 340B Cash
      if ( ($BType =~ /Cash/i) || ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0} && $tfbt{$dbRxNumber}{$dbDateOfService}{$dbFillNumber} =~ /Cash/i) ) {
#      if ( ($BType =~ /Cash/i) ) {
        $COST = 0;
        $costcalc .= "BFF - NONE";
      }
       
      ##Controls the COB Amounts
      my $TCOST = $COST;
      $TCOST    = 0 if ($cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0});
      #Add to total cost
      $TotalTotalCost += $TCOST;

      #Add to B/G/U cost
      if ($bg =~ /B/i) { 
        $BrandTotalCost += $TCOST;
      } elsif ($bg =~ /G/i) { 
        $GenericTotalCost += $TCOST;
      } else { 
        $UnknownTotalCost += $TCOST;
      }

      if      ( $bg =~ /B/i ) {
        $COST = $COST * (1-$RebateBrand);
      } elsif ( $bg =~ /G/i ) {
        $COST = $COST * (1-$RebateGeneric);
      }
     
      #Create plan lookup key, remove leading zeros
      my $BIN_KEY   = $dbBinNumber;
      my $PCN_KEY   = $dbProcessorControlNumber;
      my $GROUP_KEY = $dbGroupID;
     
      $BIN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $PCN_KEY   =~ s/^0+//gi; #Remove leading zeros
      $GROUP_KEY =~ s/^0+//gi; #Remove leading zeros
      
      $BIN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $PCN_KEY   =~ s/^\s+//gi; #Remove leading spaces
      $GROUP_KEY =~ s/^\s+//gi; #Remove leading spaces
     
      my $planKEY   = uc("$BIN_KEY##$PCN_KEY##$GROUP_KEY");
     
      #Tie in with plan from &loadPlanLookup
      my $PBM = $PBM{$planKEY} || "";
      my $PAI_Payer_Name = $PAI_Payer_Name{$planKEY} || $planKEY;
      my $Comm_MedD_Medicaid = $Comm_MedD_Medicaid{$planKEY} || "";
     
      #IF the BIN is blank, 0, or -20000, the plan is CASH, override here.
      if ($BIN_KEY =~ /^\s*$|^0+$|-20000/) {
        $PBM                = "CASH";
        $PAI_Payer_Name     = "CASH";
        $Comm_MedD_Medicaid = "CASH";
      }
     
      #Use &loadRebateLookup data to create rebated (R)COST and rebated (R)GM
      my $YYYYMM_lookup = substr($dbDateOfService, 0, 6);
      if ($bg =~ /B/i) {
        my $brand_rebate = $rebateBrandDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $brand_rebate);
      } elsif ($bg =~ /G/i) {
        my $generic_rebate = $rebateGenericDB{$YYYYMM_lookup} || 0;
        $RCOST = $COST*(1 - $generic_rebate);
      } else {
        $RCOST = $COST;
      }
     
      $RGM = $SALE - $RCOST; #Rebated GM
      $GM  = $SALE - $COST; #Non-Rebated GM
     
      $dbNDC = sprintf("%011d", $dbNDC); #Format NDC to 11 digits
     
      $key = "$dbNCPDPNumber##$dbRxNumber##$dbFillNumber##$dbDateOfService";
      $RxNumbers{$key}   = $dbRxNumber;
      $FillNumbers{$key} = $dbFillNumber;
      $BGs{$key}         = $bg;
      $SALEs{$key}       = sprintf("%.2f", $SALE);
      $COSTs{$key}       = sprintf("%.2f", $COST);
      $BinNumbers{$key}  = $dbBinNumber;
      $DBs{$key}         = $DB;
      $CASHorTPPs{$key}  = $CASHorTPP;
      $GMs{$key}         = sprintf("%.2f", $GM);
      $salecalcs{$key}   = $salecalc;
      $costcalcs{$key}   = $costcalc;
      $DOSs{$key}        = $dbDateOfService;
      $DateTransmitteds{$key} = $dbDateTransmitted;
      $PCNs{$key}        = $dbProcessorControlNumber;
      $Groups{$key}      = $dbGroupID;
      $NDCs{$key}        = $dbNDC;
      $TCodes{$key}      = $dbTCode;
      $Quantity{$key}    = $dbQuantityDispensed; #Added 10/27/2014
      $DaysSupply{$key}  = $dbDaysSupply; #Added 11/14/2014
     
      $RCOSTs{$key}      = $RCOST; #Added 11/14/2014
      $RGMs{$key}        = $RGM; #Added 11/14/2014
     
      $PBMs{$key}                = $PBM; #Added 11/14/2014
      $PAI_Payer_Names{$key}     = $PAI_Payer_Name; #Added 11/14/2014
      $Comm_MedD_Medicaids{$key} = $Comm_MedD_Medicaid; #Added 11/14/2014
     
      $PrescriberIDs{$key} = $dbPrescriberID; #Added 05/20/2015
      $PrescriberLastName{$key} = $dbPrescriberLastName; 
      $CashFlags{$key}          = $dbCash; #Added 05/11/2018
      $BinParentdbkeys{$key}    = $dbBinParentdbkey; #Added 02/20/2020
      $ICs{$key}        = sprintf("%.2f", $IC);

      $cob{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}                               = 1;
      $record{$dbRxNumber}{$dbDateOfService}{$dbFillNumber + 0}{$dbOtherPayerCoverageType} = 1;
#      print "Bindbkey: $dbBinParentdbkey - $key\n";
    }
    $sth24->finish;
#    print "total jcnt: $jcnt, NCPDP: $dbNCPDPNumber\n" if ($incdebug);
  }

  print qq#sub Get_RBSReporting_Data. Exit. Detail: $Detail<br>\n# if ($incdebug);
  print "-"x96, "<br>\n" if ($incdebug);

  if ( $Detail =~ /Y|YH|Rx/i ) {

    return ( \%RxNumbers, \%FillNumbers, \%BGs, \%SALEs, \%COSTs, \%BinNumbers, \%DBs,
             \%CASHorTPPs, \%GMs, \%salecalcs, \%costcalcs, \%DOSs, \%DateTransmitteds,
             \%PCNs, \%Groups, \%NDCs, \%TCodes, \%Quantity, \%DaysSupply, 
             \%RCOSTs, \%RGMs, \%PBMs, \%PAI_Payer_Names, \%Comm_MedD_Medicaids, 
             \%PrescriberIDs, \%CashFlags, \%PrescriberLastName, \%ICs, \%BinParentdbkeys );

  } else {
    $BrandScriptCount  += $UnknownScriptCount;
    $BrandTotalRevenue += $UnknownTotalRevenue;
    $BrandTotalCost    += $UnknownTotalCost;

    $BrandTotalRevenue   = sprintf("%.2f", $BrandTotalRevenue);
    $BrandTotalCost      = sprintf("%.2f", $BrandTotalCost);
    $GenericTotalRevenue = sprintf("%.2f", $GenericTotalRevenue);
    $GenericTotalCost    = sprintf("%.2f", $GenericTotalCost);
    $TotalTotalRevenue   = sprintf("%.2f", $TotalTotalRevenue);
    $TotalTotalCost      = sprintf("%.2f", $TotalTotalCost);
    $TotalIngredientCost = sprintf("%.2f", $IngredientTotalCost);

    return ( $BrandScriptCount,   $BrandTotalRevenue,   $BrandTotalCost,
             $GenericScriptCount, $GenericTotalRevenue, $GenericTotalCost,
             $TotalScriptCount,   $TotalTotalRevenue,   $TotalTotalCost,
             $TotalIngredientCost);
  }
}


1;    # Required for a Perl include file
