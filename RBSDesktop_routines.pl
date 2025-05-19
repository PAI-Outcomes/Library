#______________________________________________________________________________
#
# RBSDesktop_routines.pl
#______________________________________________________________________________
#
$incdebug = 0;    # set to 1 for seeing debug output for these routines

my $myvarspl = "D:/RedeemRx/MyData/vars.pl";
if ( -e "$myvarspl" ) {
   require "$myvarspl";    # MUST BE FIRST
}

my $mycommonroutines = "D:/RedeemRx/MyData/Common_routines.pl";
require "$mycommonroutines";
#______________________________________________________________________________

use DBI qw(:sql_types);
use DateTime;
use Time::Local;

$|++;                            #sets $| for STDOUT
my $old_handle = select( STDERR );  #change to STDERR
$|++;                            #sets $| for STDERR
select( $old_handle );           #change back to STDOUT
open(STDERR, ">&STDOUT") || die "Can't dup stdout\n\t$!\n\n";

$HTTP_HOST   = $ENV{"HTTP_HOST"};
$SERVER_NAME = $ENV{"SERVER_NAME"};
$DOT = ".";

$cookie_server = "$DOT" . $SERVER_NAME;

my ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
$year      += 1900;    # reported as "years since 1900".
$lyear = $year;
$lmonth = $month;
$month     += 1;    # reported ast 0-11, 0==January

if($lmonth == 0) {
  $lmonth = 12;
  $lyear--;
}

$ldopm = DateTime->last_day_of_month({
    year  => $lyear ,
    month => $lmonth
})->ymd('');

$ldocm = DateTime->last_day_of_month({
    year  => $year ,
    month => $month
})->ymd('');

$pperiod        = sprintf("%04d%02d", $lyear, $lmonth);
$cperiod        = sprintf("%04d%02d", $year, $year);
$current_date   = sprintf("%04d%02d%02d", $year, $month, $day);
$current_time   = sprintf("%02d:%02d", $hour, $min);

$TIMESTMP       = sprintf("%04d%02d%02d%02d%02d", $year, $month, $day,$hour,$min);

$testPharmacies = "(1111111, 2222222, 3333333, 9879879)";

$HOMESERVER     = "home.pharmassess.com";
$WEBTABLE       = qq#<TABLE class="main" order=1 cellspacing=2 cellpadding=2>#;
$COMPANY        = "PAI Desktop";
$RECONRXCOMPANY = "Recon-Rx";
$COLOR          = "#93FE50";
$INACTIVECOLOR  = "yellow";
$COMMENTLINE    = "<!-- ------------------------------------------------------------------------- -->\n";
$RxAdmin        = 99887766;

$FTPSPREADSHEETReconRx = "\\\\$FLSERVER\\DataShare\\ReconRx\\Documents\\FTP\\home.recon-rx.com_users.xlsx";
$FTPSPREADSHEETPioneer = "\\\\$FLSERVER\\DataShare\\ReconRx\\Pioneer\\FTP\\home.ntremitcom_users.xlsx";

%DoNotAddBINSToDB = ();
%DoNotAddMarkCash015433 = ();

my @ESIBINS = ( "003858","004451","010033","013337","013344","013550","013865","015748","400004","400023","600568","610014","610031","610053","610056","610544","610575","900002", "012924", "019363");
foreach $jbin (@ESIBINS ) {
   $DoNotAddBINSToDB{$jbin} = "08/10/2016. DO NOT ADD Express Scripts, Inc (ESI) BIN: $jbin";
}

my @GROUPS = ("CIPN504","CIPN505","CIPN506","CIPN507","RRX001","RRX003","RRX004","RRX006","RRX007","RRX008","RRX009","RRX010","RRX011","RRX012","RRX013","RRX014","RRX015","RRX016","RRX017","RRX018","RRX019","RRX020","RRX021","RRX022","RRX023","RRX024","RRX025","RRX026","RRX027","RRX028","RRX029","RRX030","RRX2012","RRX900","RRXTEST1","WCRX02","WCRX05","WCRX06");
foreach $group (@GROUPS) {
  $DoNotAddMarkCash015433{"$group"}  = "08/10/2016. DO NOT ADD IF BIN 015433 & group $group";
}

#______________________________________________________________________________
# Third Party ID, Fee charged
$Recon_Fees{700009} = .05;    # Prime Therapeutics
$Recon_Fees{700006} = .06;    # Express Script, Inc.
$Recon_Fees{700137} = .09;    # Opus Health Systems
#______________________________________________________________________________
#______________________________________________________________________________

$DBHOST        = "$dbhost";    # Set in vars.pl. 

$PHDBNAME      = "officedb";
$PHTABLE       = "pharmacy";
$PHTABLEINACT  = "pharmacySAVE";
$PHNAME        = "Pharmacy";
$PHDESC        = "RBSDesktop Pharmacy Database";

$P2DBNAME      = "officedb";
$P2TABLE       = "pharmacy_coo";
$P2TABLEINACT  = "pharmacycoo";
$P2NAME        = "Pharmacy";
$P2DESC        = "RBSDesktop Pharmacy COO Database";

$CODBNAME      = "officedb";
$COTABLE       = "company";
$COTABLEINACT  = "companySAVE";
$CONAME        = "Pharmacy";
$CODESC        = "RBSDesktop Company Database";

$TPDBNAME      = "officedb";
$TPTABLE       = "third_party_payers";
$TPNAME        = "Third Party";
$TPDESC        = "RBSDesktop Third Party Payers Database";

$AFDBNAME      = "officedb";
$AFTABLE       = "affiliate";
$AFNAME        = "Affiliate";
$AFDESC        = "RBSDesktop Affiliate Database";

$WADBNAME      = "officedb";
$WATABLE       = "WebLoginAccess";
$WANAME        = "Web Login Access";
$WADESC        = "All PAI Programs Login Access Table";

$INDBNAME      = "officedb";
$INTABLE       = "Interventions";
$INTABLEINACT  = "InterventionsSAVE";
$INNAME        = "Interventions";
$INDESC        = "RBSDesktop Interventions Database";

$IRDBNAME      = "officedb";
$IRTABLE       = "Int_Rows";
$IRTABLEINACT  = "Int_RowsSAVE";
$IRNAME        = "Int_Rows";
$IRDESC        = "RBSDesktop Intervention Rows Database";

$VNDBNAME      = "officedb";
$VNTABLE       = "vendor";
$VNNAME        = "Vendor";
$VNDESC        = "RBSDesktop Vendor Database";

$PVDBNAME      = "officedb";
$PVTABLE       = "Pharmacys_Vendors";
$PVNAME        = "Pharmacies-Vendors";
$PVDESC        = "RBSDesktop Pharmacies-Vendor Database";

$PTDBNAME      = "officedb";
$PTTABLE       = "Pharmacys_TPPs";
$PTNAME        = "Pharmacies-Third Party Payers";
$PTDESC        = "RBSDesktop Pharmacies-Third Party Payers Database";

$PSDBNAME      = "officedb";
$PSTABLE       = "TPP_Pri_Sec";
$PSNAME        = "Third Party Payers - Pri/Sec Relationships";
$PSDESC        = "RBSDesktop/Recon-Rx -Third Party Payers Pri/Sec Relationships DB";

$OPDBNAME      = "officedb";
$OPTABLE       = "opts";
$OPNAME        = "OPTS";
$OPDESC        = "RBSDesktop OPTS Database";

$ACDBNAME      = "officedb";
$ACTABLE       = "Accesstb";
$ACNAME        = "Access";
$ACDESC        = "RBSDesktop Access Database";

$PWDBNAME      = "officedb";
$PWTABLE       = "Pharmacy_Warnings_Sent";
$PWNAME        = "Pharmacy_Warnings_Sent";
$PWDESC        = "ReconRx Pharmacy Warnings Sent";

##$MADBNAME      = "officedb";
##$MATABLE       = "mac_appeal_info";
##$MANAME        = "MAC Appeal Info";
##$MADESC        = "MAC Appeal Info";

##$M2DBNAME      = "officedb";
##$M2TABLE       = "mac_appeal_info_archive";
##$M2NAME        = "MAC Appeal Info_archive";
##$M2DESC        = "MAC Appeal Info_archive";

$LTDBNAME      = "officedb";
$LTTABLE       = "MSBorG_Lookup_Table";
$LTNAME        = "MSBorG_Lookup_Table";
$LTDESC        = "MSBorG_Lookup_Table";

$TNDBNAME      = "officedb";
$TNTABLE       = "Network_Rates";
$TNNAME        = "Network_Rates";
$TNDESC        = "Network_Rates";

$RIDBNAME      = "ReconRxDB";
$RITABLE       = "incomingtb";
$RINAME        = "ReconRx Incoming Data Database";
$RIDESC        = "ReconRx Incoming Data Database";

$RADBNAME      = "ReconRxDB";
$RATABLE       = "incomingtb_archive";
$RANAME        = "ReconRxIncomingArchive";
$RADESC        = "ReconRx Incoming Data Database Archive";

$R8DBNAME      = "ReconRxDB";
$R8TABLE       = "835remitstb";
$R8NAME        = "ReconRx835remits";
$R8DESC        = "ReconRx 835 Remits Database";

$P8DBNAME      = "ReconRxDB";
$P8TABLE       = "835remitstb_Archive";
$P8NAME        = "ReconRx835remits";
$P8DESC        = "ReconRx 835 Remits Archive Database";

##$RDDBNAME      = "ReconRxDB";
##$RDTABLE       = "835remitstb_Dups";
##$RDNAME        = "ReconRx835 Duplicates";
##$RDDESC        = "ReconRx 835 Remits Duplicates";

$REDBNAME      = "ReconRxDB";
$RETABLE       = "ExceptionRouting";
$RENAME        = "ReconRxExceptionRouting";
$REDESC        = "ReconRx Exception Routing";

$RXDBNAME      = "ReconRxDB";
$RXTABLE       = "PlanExceptions";
$RXNAME        = "ReconRxPlanExceptions";
$RXDESC        = "ReconRx Plan Exceptions";

$RNDBNAME      = "ReconRxDB";
$RNTABLE       = "PaymentNoRemit";
$RNNAME        = "ReconRxPaymentNoRemit";
$RNDESC        = "ReconRx Payment No Remit";

$PADBNAME      = "ReconRxDB";
$PATABLE       = "PaymentNoRemit_Archive";
$PANAME        = "ReconRxPaymentNoRemit Archive";
$PADESC        = "ReconRx Payment No Remit Archive";

$FRDBNAME      = "ReconRxDB";
$FRTABLE       = "First_Remit_Dates";
$FRNAME        = "First Remit Dates";
$FRDESC        = "ReconRx First Remit Dates";

$CCDBNAME      = "Transfers";
$CCTABLE       = "transfertable";
$CCNAME        = "Cash Claims Transfers Table";
$CCDESC        = "Cash Claims Transfers Table";

$MCDBNAME      = "Claims";
$MCTABLE       = "Claims";
$MCNAME        = "Claims Table";
$MCDESC        = "Claims Table";

$CIDBNAME      = "Claims";
$CITABLE       = "ClaimInfo";
$CINAME        = "Claims Info Table";
$CIDESC        = "Claims Info Table";

$BXDBNAME      = "Transfers";
$BXTABLE       = "Brand_Generic_Counts";
$BXNAME        = "Transfers Brand Generic Counts Table";
$BXDESC        = "Transfers Brand Generic Counts Table";

$WBDBNAME      = "Webinar";
$WBDESC        = "Webinar DB";

$CEDBNAME      = "CIPN";
$CETABLE       = "Enrollment";
$CENAME        = "CIPN Enrollment database table";
$CEDESC        = "CIPN Enrollment database table";

$C8DBNAME      = "CIPN";
$C8TABLE       = "PT_835remitstb";
$C8NAME        = "CIPN 835 Prime Therapeutics Remits";
$C8DESC        = "CIPN E835 Prime Therapeutics Remits";

$CADBNAME      = "CIPN";
$CATABLE       = "PT_835remitstb_Archive";
$CANAME        = "CIPN 835 Prime Therapeutics Remits Archive";
$CADESC        = "CIPN 835 Prime Therapeutics Remits Archive";

$CDDBNAME      = "CIPN";
$CDTABLE       = "PT_835remitstb_Dups";
$CDNAME        = "CIPN835 Duplicates";
$CDDESC        = "CIPN 835 Remits Duplicates";

$CBDBNAME      = "CIPN";
$CBTABLE       = "BinListing_EnhancedContractstb";
$CBNAME        = "Bin Listing info for Enhanced Contracts";
$CBDESC        = "Bin Listing info for Enhanced Contracts";

$IGDBNAME      = "ReconRxDB";
$IGTABLE       = "ignore_these_binstb";
$IGNAME        = "Ignore these bins";
$IGDESC        = "ReconRxDB Ignore these bins";

$RMDBNAME      = "RBSReporting";
$RMTABLE       = "Monthly";
$RMNAME        = "Monthly";
$RMDESC        = "RBS Reporting Monthly Data";

$RWDBNAME      = "RBSReporting";
$RWTABLE       = "Weekly";
$RWNAME        = "Weekly";
$RWDESC        = "RBS Reporting Weekly Data";

$RBDBNAME      = "RBSReporting";
$RBTABLE       = "rebates";
$RBNAME        = "rebates";
$RBDESC        = "RBS Reporting rebates Data";

$R3DBNAME      = "RBSReporting";
$R3TABLE       = "Data340B";
$R3NAME        = "Data340B";
$R3DESC        = "RBS Reporting Data340B Data";

$RSDBNAME      = "ReconRxDB";
$RSTABLE       = "Reconciled_Totalstb";
$RSNAME        = "ReconRx Reconciliation Daily Values";
$RSDESC        = "ReconRx Reconciliation Daily Values";

$M01DBNAME      = "MediSpan";
$M01TABLE       = "MF2COPY";
$M01NAME        = "MF2COPY";
$M01DESC        = "Medi-Span data file";

$M02DBNAME      = "MediSpan";
$M02TABLE       = "MF2DICT";
$M02NAME        = "MF2DICT";
$M02DESC        = "Medi-Span data file";

$M03DBNAME      = "MediSpan";
$M03TABLE       = "MF2ERR";
$M03NAME        = "MF2ERR";
$M03DESC        = "Medi-Span data file";

$M04DBNAME      = "MediSpan";
$M04TABLE       = "MF2GPPC";
$M04NAME        = "MF2GPPC";
$M04DESC        = "Medi-Span data file";

$M05DBNAME      = "MediSpan";
$M05TABLE       = "MF2GPR";
$M05NAME        = "MF2GPR";
$M05DESC        = "Medi-Span data file";

$M06DBNAME      = "MediSpan";
$M06TABLE       = "MF2LAB";
$M06NAME        = "MF2LAB";
$M06DESC        = "Medi-Span data file";

$M07DBNAME      = "MediSpan";
$M07TABLE       = "MF2MOD";
$M07NAME        = "MF2MOD";
$M07DESC        = "Medi-Span data file";

$M08DBNAME      = "MediSpan";
$M08TABLE       = "MF2NAME";
$M08NAME        = "MF2NAME";
$M08DESC        = "Medi-Span data file";

$M09DBNAME      = "MediSpan";
$M09TABLE       = "MF2NDC";
$M09NAME        = "MF2NDC";
$M09DESC        = "Medi-Span data file";

$M10DBNAME      = "MediSpan";
$M10TABLE       = "MF2NDCM";
$M10NAME        = "MF2NDCM";
$M10DESC        = "Medi-Span data file";

$M11DBNAME      = "MediSpan";
$M11TABLE       = "MF2PRC";
$M11NAME        = "MF2PRC";
$M11DESC        = "Medi-Span data file";

$M12DBNAME      = "MediSpan";
$M12TABLE       = "MF2READ";
$M12NAME        = "MF2READ";
$M12DESC        = "Medi-Span data file";

$M13DBNAME      = "MediSpan";
$M13TABLE       = "MF2SEC";
$M13NAME        = "MF2SEC";
$M13DESC        = "Medi-Span data file";

$M14DBNAME      = "MediSpan";
$M14TABLE       = "MF2SUM";
$M14NAME        = "MF2SUM";
$M14DESC        = "Medi-Span data file";

$M15DBNAME      = "MediSpan";
$M15TABLE       = "MF2TCGPI";
$M15NAME        = "MF2TCGPI";
$M15DESC        = "Medi-Span data file";

$M16DBNAME      = "MediSpan";
$M16TABLE       = "MF2VAL";
$M16NAME        = "MF2VAL";
$M16DESC        = "Medi-Span data file";

$TCDBNAME       = "ReconRxDB";
$TCTABLE        = "TCodeDefs";
$TCNAME         = "TCodeDefs";
$TCDESC         = "ReconRxDB TCode Definitions";

$RRDBNAME      = "RBSReporting";
$RRTABLE       = "incomingtb_rbsdata";
$RRNAME        = "RBS Reporting Incomingtb RBSData";
$RRDESC        = "RBS Reporting Incomingtb RBSData";

$ZZDBNAME      = "RBSReporting";
$ZZTABLE       = "incomingtb_rbsdata";
$ZZNAME        = "RBS Reporting Incomingtb RBSData";
$ZZDESC        = "RBS Reporting Incomingtb RBSData";

$OVDBNAME      = "ReconRxDB";
$OVTABLE       = "incomingtb_overflow";
$OVNAME        = "RBS Reporting Incomingtb Overflow";
$OVDESC        = "RBS Reporting Incomingtb Overflow";

$RPDBNAME      = "OfficeDB";
$RPTABLE       = "Reps";
$RPNAME        = "CIPN Reps";
$RPDESC        = "CIPN Reps";

$RODBNAME      = "OfficeDB";
$ROTABLE       = "Reps_Managers";
$RONAME        = "CIPN Rep Managers";
$RODESC        = "CIPN Rep Managers";

$RTDBNAME      = "OfficeDB";
$RTTABLE       = "Reps_Stores";
$RTNAME        = "CIPN Rep Stores";
$RTDESC        = "CIPN Rep Stores";

$SGDBNAME      = "Claims";
$SGTABLE       = "Saga";
$SGNAME        = "Saga Claims Table";
$SGDESC        = "Saga Claims Table";

$DCDBNAME      = "DefaultCash";
$DCTABLE       = "Claims";
$DCNAME        = "Default Cash Claims Data Database";
$DCDESC        = "Default Cash Claims Data Database";

$DIDBNAME      = "DefaultCash";
$DITABLE       = "Incoming";
$DINAME        = "Default Cash Incoming Data Database";
$DIDESC        = "Default Cash Incoming Data Database";

$CLDBNAME      = "ClaimsData";
$CLTABLE       = "Claims";
$CLNAME        = "Claims Data Database";
$CLDESC        = "Claims Data Database";

@RBSDesktopDBs = (
"ACDBNAME", "AFDBNAME", "BXDBNAME",  "CIDBNAME", "CODBNAME", "FRDBNAME",
"DCDBNAME", "DIDBNAME","CLDBNAME",
"IGDBNAME",
"INDBNAME", "IRDBNAME", "LTDBNAME", "MCDBNAME",  
"OPDBNAME", "OVDBNAME", "P2DBNAME", "P8DBNAME", "PADBNAME", "PHDBNAME",  "PSDBNAME", "PTDBNAME", 
"PWDBNAME", "R3DBNAME", "R8DBNAME", "RADBNAME", "REDBNAME", "RIDBNAME", "RMDBNAME", "RNDBNAME",
"RRDBNAME", "RSDBNAME", "RWDBNAME", "RXDBNAME", "ZZDBNAME", 
"TCDBNAME", "TNDBNAME", "TPDBNAME", "VNDBNAME", "WADBNAME" 
 
); 

foreach $db (@RBSDesktopDBs) {
  my $first2 = substr($db, 0, 2);
  my $desc = "${first2}DESC";
  $RBSDesktopDBd{$db} = $$desc;
}

$DBNAMES{"P2DBNAME"} = $P2DBNAME;
$DBDESCS{"P2DBNAME"} = $P2DESC;
$DBNAME{"P2DBNAME"}  = $P2NAME;
$DBTABN{"P2DBNAME"}  = "$P2TABLE";
$DBFLDS{"P2DBNAME"}  = "P2FIELDS";
$DBKEYF{"P2DBNAME"}  = "NPI:NCPDP";
$HASHNAMES{"P2DBNAME"}  = "P2HASH";

$DBNAMES{"PHDBNAME"} = $PHDBNAME;
$DBDESCS{"PHDBNAME"} = $PHDESC;
$DBNAME{"PHDBNAME"}  = $PHNAME;
$DBTABN{"PHDBNAME"}  = "$PHTABLE";
$DBFLDS{"PHDBNAME"}  = "PHFIELDS";
$DBKEYF{"PHDBNAME"}  = "NPI:NCPDP";
$HASHNAMES{"PHDBNAME"}  = "PHHASH";

$DBNAMES{"CODBNAME"} = $CODBNAME;
$DBDESCS{"CODBNAME"} = $CODESC;
$DBNAME{"CODBNAME"}  = $CONAME;
$DBTABN{"CODBNAME"}  = "$COTABLE";
$DBFLDS{"CODBNAME"}  = "COFIELDS";
$DBKEYF{"CODBNAME"}  = "Company_ID";
$HASHNAMES{"CODBNAME"}  = "COHASH";

$DBNAMES{"TPDBNAME"} = $TPDBNAME;
$DBDESCS{"TPDBNAME"} = $TPDESC;
$DBNAME{"TPDBNAME"}  = $TPNAME;
$DBTABN{"TPDBNAME"}  = "$TPTABLE";
$DBFLDS{"TPDBNAME"}  = "TPFIELDS";
$DBKEYF{"TPDBNAME"}  = "Third_Party_Payer_ID:BIN";
$HASHNAMES{"TPDBNAME"}  = "TPHASH";

$DBNAMES{"AFDBNAME"} = $AFDBNAME;
$DBDESCS{"AFDBNAME"} = $AFDESC;
$DBNAME{"AFDBNAME"}  = $AFNAME;
$DBTABN{"AFDBNAME"}  = "$AFTABLE";
$DBFLDS{"AFDBNAME"}  = "AFFIELDS";
$DBKEYF{"AFDBNAME"}  = "Affiliate_ID:Affiliate_Name";
$HASHNAMES{"AFDBNAME"} = "AFHASH";

$DBNAMES{"WADBNAME"} = $WADBNAME;
$DBDESCS{"WADBNAME"} = $WADESC;
$DBNAME{"WADBNAME"}  = $WANAME;
$DBTABN{"WADBNAME"}  = "$WATABLE";
$DBFLDS{"WADBNAME"}  = "WAFIELDS";
$DBKEYF{"WADBNAME"}  = "WLSuperUser:WLLoginID";
$HASHNAMES{"WADBNAME"}  = "WAHASH";

$DBNAMES{"INDBNAME"} = $INDBNAME;
$DBDESCS{"INDBNAME"} = $INDESC;
$DBNAME{"INDBNAME"}  = $INNAME;
$DBTABN{"INDBNAME"}  = "$INTABLE";
$DBFLDS{"INDBNAME"}  = "INFIELDS";
$DBKEYF{"INDBNAME"}  = "Intervention_ID:Pharmacy_ID";
$HASHNAMES{"INDBNAME"}  = "INHASH";

$DBNAMES{"IRDBNAME"} = $IRDBNAME;
$DBDESCS{"IRDBNAME"} = $IRDESC;
$DBNAME{"IRDBNAME"}  = $IRNAME;
$DBTABN{"IRDBNAME"}  = "$IRTABLE";
$DBFLDS{"IRDBNAME"}  = "IRFIELDS";
$DBKEYF{"IRDBNAME"}  = "Row_Intervention_Row_ID:Row_Intervention_ID";
$HASHNAMES{"IRDBNAME"}  = "IRHASH";

$DBNAMES{"VNDBNAME"} = $VNDBNAME;
$DBDESCS{"VNDBNAME"} = $VNDESC;
$DBNAME{"VNDBNAME"}  = $VNNAME;
$DBTABN{"VNDBNAME"}  = "$VNTABLE";
$DBFLDS{"VNDBNAME"}  = "VNFIELDS";
$DBKEYF{"VNDBNAME"}  = "Vendor_ID";
$HASHNAMES{"VNDBNAME"}  = "VNHASH";

##$DBNAMES{"PVDBNAME"} = $PVDBNAME;
##$DBDESCS{"PVDBNAME"} = $PVDESC;
#$DBNAME{"PVDBNAME"}  = $PVNAME;
#$DBTABN{"PVDBNAME"}  = "$PVTABLE";
##$DBFLDS{"PVDBNAME"}  = "PVFIELDS";
##$DBKEYF{"PVDBNAME"}  = "Pharmacys_Vendor_ID";
##$HASHNAMES{"PVDBNAME"}  = "PVHASH";

$DBNAMES{"PTDBNAME"} = $PTDBNAME;
$DBDESCS{"PTDBNAME"} = $PTDESC;
$DBNAME{"PTDBNAME"}  = $PTNAME;
$DBTABN{"PTDBNAME"}  = "$PTTABLE";
$DBFLDS{"PTDBNAME"}  = "PTFIELDS";
$DBKEYF{"PTDBNAME"}  = "Pharmacys_TPP_ID";
$HASHNAMES{"PTDBNAME"}  = "PTHASH";

$DBNAMES{"PSDBNAME"} = $PSDBNAME;
$DBDESCS{"PSDBNAME"} = $PSDESC;
$DBNAME{"PSDBNAME"}  = $PSNAME;
$DBTABN{"PSDBNAME"}  = "$PSTABLE";
$DBFLDS{"PSDBNAME"}  = "PSFIELDS";
$DBKEYF{"PSDBNAME"}  = "TPP_Pri_Sec_ID:TPP_Pri_ID:TPP_Sec_ID";
$HASHNAMES{"PSDBNAME"}  = "PSHASH";

$DBNAMES{"RIDBNAME"} = $RIDBNAME;
$DBDESCS{"RIDBNAME"} = $RIDESC;
$DBNAME{"RIDBNAME"}  = $RINAME;
$DBTABN{"RIDBNAME"}  = "$RITABLE";
$DBFLDS{"RIDBNAME"}  = "RIFIELDS";
$DBKEYF{"RIDBNAME"}  = "dbSwVendor:dbDateTransmitted:dbNCPDPNumber:dbDateOfService:dbRxNumber:dbTransactionCode:dbDateOfBirth:dbTotalAmountPaid:dbBinNumber:dbFillNumber";
$HASHNAMES{"RIDBNAME"}  = "RIHASH";

$DBNAMES{"R8DBNAME"} = $R8DBNAME;
$DBDESCS{"R8DBNAME"} = $R8DESC;
$DBNAME{"R8DBNAME"}  = $R8NAME;
$DBTABN{"R8DBNAME"}  = "$R8TABLE";
$DBFLDS{"R8DBNAME"}  = "R8FIELDS";
$DBKEYF{"R8DBNAME"}  = "R_TRN02_Check_Number:R_BPR02_Check_Amount:R_BPR16_Date:R_CLP01_Rx_Number:R_ISA_BIN:R_CLP07_Ref_Number_of_Claim:R_TS3_NCPDP:R_TPP:R_BPR04_Payment_Method_Code:R_CLP03_Amount_Billed:R_CLP04_Amount_Payed:R_CLP05_Amount_CoPayed:R_CLP12_Quantity:R_ISA06_Interchange_Sender_ID";
$HASHNAMES{"R8DBNAME"}  = "R8HASH";

$DBNAMES{"P8DBNAME"} = $P8DBNAME;
$DBDESCS{"P8DBNAME"} = $P8DESC;
$DBNAME{"P8DBNAME"}  = $P8NAME;
$DBTABN{"P8DBNAME"}  = "$P8TABLE";
$DBFLDS{"P8DBNAME"}  = "P8FIELDS";
$DBKEYF{"P8DBNAME"}  = $DBKEYF{"P8DBNAME"};
$HASHNAMES{"P8DBNAME"}  = "P8HASH";

##$DBNAMES{"RDDBNAME"} = $RDDBNAME;
##$DBDESCS{"RDDBNAME"} = $RDDESC;
##$DBNAME{"RDDBNAME"}  = $RDNAME;
####$DBTABN{"RDDBNAME"}  = "$RDTABLE";
##$DBFLDS{"RDDBNAME"}  = "RDFIELDS";
##$DBKEYF{"RDDBNAME"}  = "R_TRN02_Check_Number:R_BPR02_Check_Amount:R_BPR16_Date:R_CLP01_Rx_Number:R_ISA_BIN:R_CLP07_Ref_Number_of_Claim:R_TS3_NCPDP:R_TPP:R_BPR04_Payment_Method_Code:R_CLP03_Amount_Billed:R_CLP04_Amount_Payed:R_CLP05_Amount_CoPayed:R_CLP12_Quantity:R_ISA06_Interchange_Sender_ID";
##$HASHNAMES{"RDDBNAME"}  = "RDHASH";

$DBNAMES{"LTDBNAME"} = $LTDBNAME;
$DBDESCS{"LTDBNAME"} = $LTDESC;
$DBNAME{"LTDBNAME"}  = $LTNAME;
$DBTABN{"LTDBNAME"}  = "$LTTABLE";
$DBFLDS{"LTDBNAME"}  = "LTFIELDS";
$DBKEYF{"LTDBNAME"}  = "NDC";
$HASHNAMES{"LTDBNAME"}  = "LTHASH";

$DBNAMES{"TNDBNAME"} = $TNDBNAME;
$DBDESCS{"TNDBNAME"} = $TNDESC;
$DBNAME{"TNDBNAME"}  = $TNNAME;
$DBTABN{"TNDBNAME"}  = "$TNTABLE";
$DBFLDS{"TNDBNAME"}  = "TNFIELDS";
$DBKEYF{"TNDBNAME"}  = "";
$HASHNAMES{"TNDBNAME"}  = "TNHASH";

$DBNAMES{"RADBNAME"} = $RADBNAME;
$DBDESCS{"RADBNAME"} = $RADESC;
$DBNAME{"RADBNAME"}  = $RANAME;
$DBTABN{"RADBNAME"}  = "$RATABLE";
$DBFLDS{"RADBNAME"}  = "RAFIELDS";
$DBKEYF{"RADBNAME"}  = $DBKEYF{"RIDBNAME"};
$HASHNAMES{"RADBNAME"}  = "RAHASH";

$DBNAMES{"REDBNAME"} = $REDBNAME;
$DBDESCS{"REDBNAME"} = $REDESC;
$DBNAME{"REDBNAME"}  = $RENAME;
$DBTABN{"REDBNAME"}  = "$RETABLE";
$DBFLDS{"REDBNAME"}  = "REFIELDS";
$DBKEYF{"REDBNAME"}  = "id:BIN";
$HASHNAMES{"REDBNAME"}  = "REHASH";

$DBNAMES{"RXDBNAME"} = $RXDBNAME;
$DBDESCS{"RXDBNAME"} = $RXDESC;
$DBNAME{"RXDBNAME"}  = $RXNAME;
$DBTABN{"RXDBNAME"}  = "$RXTABLE";
$DBFLDS{"RXDBNAME"}  = "RXFIELDS";
$DBKEYF{"RXDBNAME"}  = "id:BinFrom";
$HASHNAMES{"RXDBNAME"}  = "RXHASH";

$DBNAMES{"RNDBNAME"} = $RNDBNAME;
$DBDESCS{"RNDBNAME"} = $RNDESC;
$DBNAME{"RNDBNAME"}  = $RNNAME;
$DBTABN{"RNDBNAME"}  = "$RNTABLE";
$DBFLDS{"RNDBNAME"}  = "RNFIELDS";
$DBKEYF{"RNDBNAME"}  = "NCPDP:DateAdded:BIN:ThirdParty:PaymentType:CheckNumber:CheckAmount:CheckDate:CheckReceivedDate";
$HASHNAMES{"RNDBNAME"}  = "RNHASH";

$DBNAMES{"PADBNAME"} = $PADBNAME;
$DBDESCS{"PADBNAME"} = $PADESC;
$DBNAME{"PADBNAME"}  = $PANAME;
$DBTABN{"PADBNAME"}  = "$PATABLE";
$DBFLDS{"PADBNAME"}  = "PAFIELDS";
$DBKEYF{"PADBNAME"}  = $DBKEYF{"RNDBNAME"};
$HASHNAMES{"PADBNAME"}  = "PAHASH";

$DBNAMES{"FRDBNAME"} = $FRDBNAME;
$DBDESCS{"FRDBNAME"} = $FRDESC;
$DBNAME{"FRDBNAME"}  = $FRNAME;
$DBTABN{"FRDBNAME"}  = "$FRTABLE";
$DBFLDS{"FRDBNAME"}  = "FRFIELDS";
$DBKEYF{"FRDBNAME"}  = "NCPDP:BIN";
$HASHNAMES{"FRDBNAME"}  = "FRHASH";

$DBNAMES{"PWDBNAME"} = $PWDBNAME;
$DBDESCS{"PWDBNAME"} = $PWDESC;
$DBNAME{"PWDBNAME"}  = $PWNAME;
$DBTABN{"PWDBNAME"}  = "$PWTABLE";
$DBFLDS{"PWDBNAME"}  = "PWFIELDS";
$DBKEYF{"PWDBNAME"}  = $DBKEYF{"RNDBNAME"};
$HASHNAMES{"PWDBNAME"}  = "PWHASH";

$DBNAMES{"CCDBNAME"} = $CCDBNAME;
$DBDESCS{"CCDBNAME"} = $CCDESC;
$DBNAME{"CCDBNAME"}  = $CCNAME;
$DBTABN{"CCDBNAME"}  = "$CCTABLE";
$DBFLDS{"CCDBNAME"}  = "CCFIELDS";
$DBKEYF{"CCDBNAME"}  = "R_ID";
$HASHNAMES{"CCDBNAME"}  = "CCHASH";

$DBNAMES{"OPDBNAME"} = $OPDBNAME;
$DBDESCS{"OPDBNAME"} = $OPDESC;
$DBNAME{"OPDBNAME"}  = $OPNAME;
$DBTABN{"OPDBNAME"}  = "$OPTABLE";
$DBFLDS{"OPDBNAME"}  = "OPFIELDS";
$DBKEYF{"OPDBNAME"}  = "OPTS_ID";
$HASHNAMES{"OPDBNAME"}  = "OPHASH";

$DBNAMES{"OVDBNAME"} = $OVDBNAME;
$DBDESCS{"OVDBNAME"} = $OVDESC;
$DBNAME{"OVDBNAME"}  = $OVNAME;
$DBTABN{"OVDBNAME"}  = "$OVTABLE";
$DBFLDS{"OVDBNAME"}  = "OVFIELDS";
$DBKEYF{"OVDBNAME"}  = $DBKEYF{"RIDBNAME"};
$HASHNAMES{"OVDBNAME"}  = "OVHASH";

$DBNAMES{"ACDBNAME"} = $ACDBNAME;
$DBDESCS{"ACDBNAME"} = $ACDESC;
$DBNAME{"ACDBNAME"}  = $ACNAME;
$DBTABN{"ACDBNAME"}  = "$ACTABLE";
$DBFLDS{"ACDBNAME"}  = "ACFIELDS";
$DBKEYF{"ACDBNAME"}  = "id";
$HASHNAMES{"ACDBNAME"}  = "ACHASH";

$DBNAMES{"WBDBNAME"} = $WBDBNAME;
$DBDESCS{"WBDBNAME"} = $WBDESC;
$DBNAME{"WBDBNAME"}  = $WBNAME;
$HASHNAMES{"WBDBNAME"}  = "WBHASH";

$DBNAMES{"C8DBNAME"} = $C8DBNAME;
$DBDESCS{"C8DBNAME"} = $C8DESC;
$DBNAME{"C8DBNAME"}  = $C8NAME;
$DBTABN{"C8DBNAME"}  = "$C8TABLE";
$DBFLDS{"C8DBNAME"}  = "C8FIELDS";
$DBKEYF{"C8DBNAME"}  = "R_TRN02_Check_Number:R_BPR02_Check_Amount:R_BPR16_Date:R_CLP01_Rx_Number:R_ISA_BIN:R_CLP07_Ref_Number_of_Claim:R_TS3_NCPDP:R_TPP:R_BPR04_Payment_Method_Code:R_CLP03_Amount_Billed:R_CLP04_Amount_Payed:R_CLP05_Amount_CoPayed:R_CLP12_Quantity:R_ISA06_Interchange_Sender_ID";
$HASHNAMES{"C8DBNAME"}  = "C8HASH";

$DBNAMES{"CADBNAME"} = $CADBNAME;
$DBDESCS{"CADBNAME"} = $CADESC;
$DBNAME{"CADBNAME"}  = $CANAME;
$DBTABN{"CADBNAME"}  = "$CATABLE";
$DBFLDS{"CADBNAME"}  = "CAFIELDS";
$DBKEYF{"CADBNAME"}  = "R_TRN02_Check_Number:R_BPR02_Check_Amount:R_BPR16_Date:R_CLP01_Rx_Number:R_ISA_BIN:R_CLP07_Ref_Number_of_Claim:R_TS3_NCPDP:R_TPP:R_BPR04_Payment_Method_Code:R_CLP03_Amount_Billed:R_CLP04_Amount_Payed:R_CLP05_Amount_CoPayed:R_CLP12_Quantity:R_ISA06_Interchange_Sender_ID";
$HASHNAMES{"CADBNAME"}  = "CAHASH";

$DBNAMES{"CDDBNAME"} = $CDDBNAME;
$DBDESCS{"CDDBNAME"} = $CDDESC;
$DBNAME{"CDDBNAME"}  = $CDNAME;
$DBTABN{"CDDBNAME"}  = "$CDTABLE";
$DBFLDS{"CDDBNAME"}  = "CDFIELDS";
$DBKEYF{"CDDBNAME"}  = "R_TRN02_Check_Number:R_BPR02_Check_Amount:R_BPR16_Date:R_CLP01_Rx_Number:R_ISA_BIN:R_CLP07_Ref_Number_of_Claim:R_TS3_NCPDP:R_TPP:R_BPR04_Payment_Method_Code:R_CLP03_Amount_Billed:R_CLP04_Amount_Payed:R_CLP05_Amount_CoPayed:R_CLP12_Quantity:R_ISA06_Interchange_Sender_ID";
$HASHNAMES{"CDDBNAME"}  = "CDHASH";

$DBNAMES{"CEDBNAME"} = $CEDBNAME;
$DBDESCS{"CEDBNAME"} = $CEDESC;
$DBNAME{"CEDBNAME"}  = $CENAME;
$DBTABN{"CEDBNAME"}  = "$CETABLE";
$DBFLDS{"CEDBNAME"}  = "CEFIELDS";
$DBKEYF{"CEDBNAME"}  = "id";
$HASHNAMES{"CEDBNAME"}  = "CEHASH";

$DBNAMES{"CBDBNAME"} = $CBDBNAME;
$DBDESCS{"CBDBNAME"} = $CBDESC;
$DBNAME{"CBDBNAME"}  = $CBNAME;
$DBTABN{"CBDBNAME"}  = "$CBTABLE";
$DBFLDS{"CBDBNAME"}  = "CBFIELDS";
$DBKEYF{"CBDBNAME"}  = "id";
$HASHNAMES{"CBDBNAME"}  = "CBHASH";

$DBNAMES{"IGDBNAME"} = $IGDBNAME;
$DBDESCS{"IGDBNAME"} = $IGDESC;
$DBNAME{"IGDBNAME"}  = $IGNAME;
$DBTABN{"IGDBNAME"}  = "$IGTABLE";
$DBFLDS{"IGDBNAME"}  = "IGFIELDS";
$DBKEYF{"IGDBNAME"}  = "BIN";
$HASHNAMES{"IGDBNAME"}  = "IGHASH";

$DBNAMES{"R3DBNAME"} = $R3DBNAME;
$DBDESCS{"R3DBNAME"} = $R3DESC;
$DBNAME{"R3DBNAME"}  = $R3NAME;
$DBTABN{"R3DBNAME"}  = "$R3TABLE";
$DBFLDS{"R3DBNAME"}  = "R3FIELDS";
$DBKEYF{"R3DBNAME"}  = "BIN";
$HASHNAMES{"R3DBNAME"}  = "R3HASH";

$DBNAMES{"RWDBNAME"} = $RWDBNAME;
$DBDESCS{"RWDBNAME"} = $RWDESC;
$DBNAME{"RWDBNAME"}  = $RWNAME;
$DBTABN{"RWDBNAME"}  = "$RWTABLE";
$DBFLDS{"RWDBNAME"}  = "RWFIELDS";
$DBKEYF{"RWDBNAME"}  = "BIN";
$HASHNAMES{"RWDBNAME"}  = "RWHASH";

$DBNAMES{"RBDBNAME"} = $RBDBNAME;
$DBDESCS{"RBDBNAME"} = $RBDESC;
$DBNAME{"RBDBNAME"}  = $RBNAME;
$DBTABN{"RBDBNAME"}  = "$RBTABLE";
$DBFLDS{"RBDBNAME"}  = "RBFIELDS";
$DBKEYF{"RBDBNAME"}  = "BIN";
$HASHNAMES{"RBDBNAME"}  = "RBHASH";

$DBNAMES{"RMDBNAME"} = $RMDBNAME;
$DBDESCS{"RMDBNAME"} = $RMDESC;
$DBNAME{"RMDBNAME"}  = $RMNAME;
$DBTABN{"RMDBNAME"}  = "$RMTABLE";
$DBFLDS{"RMDBNAME"}  = "RMFIELDS";
$DBKEYF{"RMDBNAME"}  = "BIN";
$HASHNAMES{"RMDBNAME"}  = "RMHASH";

$DBNAMES{"RSDBNAME"} = $RSDBNAME;
$DBDESCS{"RSDBNAME"} = $RSDESC;
$DBNAME{"RSDBNAME"}  = $RSNAME;
$DBTABN{"RSDBNAME"}  = "$RSTABLE";
$DBFLDS{"RSDBNAME"}  = "RSFIELDS";
$DBKEYF{"RSDBNAME"}  = "BIN";
$HASHNAMES{"RSDBNAME"}  = "RSHASH";

$DBNAMES{"M01DBNAME"} = $M01DBNAME;
$DBDESCS{"M01DBNAME"} = $M01DESC;
$DBNAME{"M01DBNAME"}  = $M01NAME;
$DBTABN{"M01DBNAME"}  = "$M01TABLE";
$DBFLDS{"M01DBNAME"}  = "M01FIELDS";
$DBKEYF{"M01DBNAME"}  = "";
$HASHNAMES{"M01DBNAME"} = "M01HASH";

$DBNAMES{"M02DBNAME"} = $M02DBNAME;
$DBDESCS{"M02DBNAME"} = $M02DESC;
$DBNAME{"M02DBNAME"}  = $M02NAME;
$DBTABN{"M02DBNAME"}  = "$M02TABLE";
$DBFLDS{"M02DBNAME"}  = "M02FIELDS";
$DBKEYF{"M02DBNAME"}  = "field_identifier";
$HASHNAMES{"M02DBNAME"} = "M02HASH";

$DBNAMES{"M03DBNAME"} = $M03DBNAME;
$DBDESCS{"M03DBNAME"} = $M03DESC;
$DBNAME{"M03DBNAME"}  = $M03NAME;
$DBTABN{"M03DBNAME"}  = "$M03TABLE";
$DBFLDS{"M03DBNAME"}  = "M03FIELDS";
$DBKEYF{"M03DBNAME"}  = "key_identifier:data_element_code:unique_key";
$HASHNAMES{"M03DBNAME"} = "M03HASH";

$DBNAMES{"M04DBNAME"} = $M04DBNAME;
$DBDESCS{"M04DBNAME"} = $M04DESC;
$DBNAME{"M04DBNAME"}  = $M04NAME;
$DBTABN{"M04DBNAME"}  = "$M04TABLE";
$DBFLDS{"M04DBNAME"}  = "M04FIELDS";
$DBKEYF{"M04DBNAME"}  = "generic_product_pack_code";
$HASHNAMES{"M04DBNAME"} = "M04HASH";

$DBNAMES{"M05DBNAME"} = $M05DBNAME;
$DBDESCS{"M05DBNAME"} = $M05DESC;
$DBNAME{"M05DBNAME"}  = $M05NAME;
$DBTABN{"M05DBNAME"}  = "$M05TABLE";
$DBFLDS{"M05DBNAME"}  = "M05FIELDS";
$DBKEYF{"M05DBNAME"}  = "generic_product_pack_code:gppc_price_code:effective_date";
$HASHNAMES{"M05DBNAME"} = "M05HASH";

$DBNAMES{"M06DBNAME"} = $M06DBNAME;
$DBDESCS{"M06DBNAME"} = $M06DESC;
$DBNAME{"M06DBNAME"}  = $M06NAME;
$DBTABN{"M06DBNAME"}  = "$M06TABLE";
$DBFLDS{"M06DBNAME"}  = "M06FIELDS";
$DBKEYF{"M06DBNAME"}  = "medispan_labeler_id";
$HASHNAMES{"M06DBNAME"} = "M06HASH";

$DBNAMES{"M07DBNAME"} = $M07DBNAME;
$DBDESCS{"M07DBNAME"} = $M07DESC;
$DBNAME{"M07DBNAME"}  = $M07NAME;
$DBTABN{"M07DBNAME"}  = "$M07TABLE";
$DBFLDS{"M07DBNAME"}  = "M07FIELDS";
$DBKEYF{"M07DBNAME"}  = "modifier_code";
$HASHNAMES{"M07DBNAME"} = "M07HASH";

$DBNAMES{"M08DBNAME"} = $M08DBNAME;
$DBDESCS{"M08DBNAME"} = $M08DESC;
$DBNAME{"M08DBNAME"}  = $M08NAME;
$DBTABN{"M08DBNAME"}  = "$M08TABLE";
$DBFLDS{"M08DBNAME"}  = "M08FIELDS";
$DBKEYF{"M08DBNAME"}  = "drug_descriptor_id";
$HASHNAMES{"M08DBNAME"} = "M08HASH";

$DBNAMES{"M09DBNAME"} = $M09DBNAME;
$DBDESCS{"M09DBNAME"} = $M09DESC;
$DBNAME{"M09DBNAME"}  = $M09NAME;
$DBTABN{"M09DBNAME"}  = "$M09TABLE";
$DBFLDS{"M09DBNAME"}  = "M09FIELDS";
$DBKEYF{"M09DBNAME"}  = "ndc_upc_hri";
$HASHNAMES{"M09DBNAME"} = "M09HASH";

$DBNAMES{"M10DBNAME"} = $M10DBNAME;
$DBDESCS{"M10DBNAME"} = $M10DESC;
$DBNAME{"M10DBNAME"}  = $M10NAME;
$DBTABN{"M10DBNAME"}  = "$M10TABLE";
$DBFLDS{"M10DBNAME"}  = "M10FIELDS";
$DBKEYF{"M10DBNAME"}  = "ndc_upc_hri:modifier_code";
$HASHNAMES{"M10DBNAME"} = "M10HASH";

$DBNAMES{"M11DBNAME"} = $M11DBNAME;
$DBDESCS{"M11DBNAME"} = $M11DESC;
$DBNAME{"M11DBNAME"}  = $M11NAME;
$DBTABN{"M11DBNAME"}  = "$M11TABLE";
$DBFLDS{"M11DBNAME"}  = "M11FIELDS";
$DBKEYF{"M11DBNAME"}  = "ndc_upc_hri:price_code:price_effective_date";
$HASHNAMES{"M11DBNAME"} = "M11HASH";

$DBNAMES{"M12DBNAME"} = $M12DBNAME;
$DBDESCS{"M12DBNAME"} = $M12DESC;
$DBNAME{"M12DBNAME"}  = $M12NAME;
$DBTABN{"M12DBNAME"}  = "$M12TABLE";
$DBFLDS{"M12DBNAME"}  = "M12FIELDS";
$DBKEYF{"M12DBNAME"}  = "";
$HASHNAMES{"M12DBNAME"} = "M12HASH";

$DBNAMES{"M13DBNAME"} = $M13DBNAME;
$DBDESCS{"M13DBNAME"} = $M13DESC;
$DBNAME{"M13DBNAME"}  = $M13NAME;
$DBTABN{"M13DBNAME"}  = "$M13TABLE";
$DBFLDS{"M13DBNAME"}  = "M13FIELDS";
$DBKEYF{"M13DBNAME"}  = "external_drug_id:external_drug_id_type_code:alternate_drug_id";
$HASHNAMES{"M13DBNAME"} = "M13HASH";

$DBNAMES{"M14DBNAME"} = $M14DBNAME;
$DBDESCS{"M14DBNAME"} = $M14DESC;
$DBNAME{"M14DBNAME"}  = $M14NAME;
$DBTABN{"M14DBNAME"}  = "$M14TABLE";
$DBFLDS{"M14DBNAME"}  = "M14FIELDS";
$DBKEYF{"M14DBNAME"}  = "";
$HASHNAMES{"M14DBNAME"} = "M14HASH";

$DBNAMES{"M15DBNAME"} = $M15DBNAME;
$DBDESCS{"M15DBNAME"} = $M15DESC;
$DBNAME{"M15DBNAME"}  = $M15NAME;
$DBTABN{"M15DBNAME"}  = "$M15TABLE";
$DBFLDS{"M15DBNAME"}  = "M15FIELDS";
$DBKEYF{"M15DBNAME"}  = "tcgpi_id:record_type";
$HASHNAMES{"M15DBNAME"} = "M15HASH";

$DBNAMES{"M16DBNAME"} = $M16DBNAME;
$DBDESCS{"M16DBNAME"} = $M16DESC;
$DBNAME{"M16DBNAME"}  = $M16NAME;
$DBTABN{"M16DBNAME"}  = "$M16TABLE";
$DBFLDS{"M16DBNAME"}  = "M16FIELDS";
$DBKEYF{"M16DBNAME"}  = "";
$HASHNAMES{"M16DBNAME"} = "M16HASH";

$DBNAMES{"TCDBNAME"} = $TCDBNAME;
$DBDESCS{"TCDBNAME"} = $TCDESC;
$DBNAME{"TCDBNAME"}  = $TCNAME;
$DBTABN{"TCDBNAME"}  = "$TCTABLE";
$DBFLDS{"TCDBNAME"}  = "TCFIELDS";
$DBKEYF{"TCDBNAME"}  = "";
$HASHNAMES{"TCDBNAME"} = "TCHASH";

##$DBNAMES{"MADBNAME"} = $MADBNAME;
##$DBDESCS{"MADBNAME"} = $MADESC;
##$DBNAME{"MADBNAME"}  = $MANAME;
##$DBTABN{"MADBNAME"}  = "$MATABLE";
##$DBFLDS{"MADBNAME"}  = "MAFIELDS";
##$DBKEYF{"MADBNAME"}  = "";
##$HASHNAMES{"MADBNAME"} = "MAHASH";

##$DBNAMES{"M2DBNAME"} = $M2DBNAME;
##$DBDESCS{"M2DBNAME"} = $M2DESC;
##$DBNAME{"M2DBNAME"}  = $M2NAME;
##$DBTABN{"M2DBNAME"}  = "$M2TABLE";
##$DBFLDS{"M2DBNAME"}  = "M2FIELDS";
##$DBKEYF{"M2DBNAME"}  = "";
##$HASHNAMES{"M2DBNAME"} = "M2HASH";

$DBNAMES{"MCDBNAME"} = $MCDBNAME;
$DBDESCS{"MCDBNAME"} = $MCDESC;
$DBNAME{"MCDBNAME"}  = $MCNAME;
$DBTABN{"MCDBNAME"}  = "$MCTABLE";
$DBFLDS{"MCDBNAME"}  = "MCFIELDS";
$DBKEYF{"MCDBNAME"}  = "C10_Service_Provider_ID, C231_New_Pass_Through, C242_Hierarchy_Level_1, C243_Hierarchy_Level_2, C244_Hierarchy_Level_3, C245_Hierarchy_Level_4, C105_User_Defined, C12_Prescription_Rx_Number, C13_Fill_Number";
$HASHNAMES{"MCDBNAME"} = "MCHASH";

$DBNAMES{"BXDBNAME"} = $BXDBNAME;
$DBDESCS{"BXDBNAME"} = $BXDESC;
$DBNAME{"BXDBNAME"}  = $BXNAME;
$DBTABN{"BXDBNAME"}  = "$BXTABLE";
$DBFLDS{"BXDBNAME"}  = "BXFIELDS";
$DBKEYF{"BXDBNAME"}  = "Date_Added";
$HASHNAMES{"BXDBNAME"} = "BXHASH";

$DBNAMES{"CIDBNAME"} = $CIDBNAME;
$DBDESCS{"CIDBNAME"} = $CIDESC;
$DBNAME{"CIDBNAME"}  = $CINAME;
$DBTABN{"CIDBNAME"}  = "$CITABLE";
$DBFLDS{"CIDBNAME"}  = "CIFIELDS";
$DBKEYF{"CIDBNAME"}  = "FORD";
$HASHNAMES{"CIDBNAME"} = "CIHASH";

$DBNAMES{"RRDBNAME"} = $RRDBNAME;
$DBDESCS{"RRDBNAME"} = $RRDESC;
$DBNAME{"RRDBNAME"}  = $RRNAME;
$DBTABN{"RRDBNAME"}  = "$RRTABLE";
$DBFLDS{"RRDBNAME"}  = "RRFIELDS";
$DBKEYF{"RRDBNAME"}  = $DBKEYF{"RIDBNAME"};
$HASHNAMES{"RRDBNAME"} = "RRHASH";

$DBNAMES{"ZZDBNAME"} = $ZZDBNAME;
$DBDESCS{"ZZDBNAME"} = $ZZDESC;
$DBNAME{"ZZDBNAME"}  = $ZZNAME;
$DBTABN{"ZZDBNAME"}  = "$ZZTABLE";
$DBFLDS{"ZZDBNAME"}  = "ZZFIELDS";
$DBKEYF{"ZZDBNAME"}  = $DBKEYF{"RIDBNAME"};
$HASHNAMES{"ZZDBNAME"} = "ZZHASH";

$DBNAMES{"SSDBNAME"} = $SSDBNAME;
$DBDESCS{"SSDBNAME"} = $SSDESC;
$DBNAME{"SSDBNAME"}  = $SSNAME;
$DBTABN{"SSDBNAME"}  = "$SSTABLE";
$DBFLDS{"SSDBNAME"}  = "SSFIELDS";
$DBKEYF{"SSDBNAME"}  = "";
$HASHNAMES{"SSDBNAME"} = "SSHASH";

$DBNAMES{"RPDBNAME"} = $RPDBNAME;
$DBDESCS{"RPDBNAME"} = $RPDESC;
$DBNAME{"RPDBNAME"}  = $RPNAME;
$DBTABN{"RPDBNAME"}  = "$RPTABLE";
$DBFLDS{"RPDBNAME"}  = "RPFIELDS";
$DBKEYF{"RPDBNAME"}  = "ID:Level";
$HASHNAMES{"RPDBNAME"} = "RPHASH";

$DBNAMES{"RODBNAME"} = $RODBNAME;
$DBDESCS{"RODBNAME"} = $RODESC;
$DBNAME{"RODBNAME"}  = $RONAME;
$DBTABN{"RODBNAME"}  = "$ROTABLE";
$DBFLDS{"RODBNAME"}  = "ROFIELDS";
$DBKEYF{"RODBNAME"}  = "ID_Manager:ID_Rep";
$HASHNAMES{"RODBNAME"} = "ROHASH";

$DBNAMES{"RTDBNAME"} = $RTDBNAME;
$DBDESCS{"RTDBNAME"} = $RTDESC;
$DBNAME{"RTDBNAME"}  = $RTNAME;
$DBTABN{"RTDBNAME"}  = "$RTTABLE";
$DBFLDS{"RTDBNAME"}  = "RTFIELDS";
$DBKEYF{"RTDBNAME"}  = "ID_Rep:NCPDP:Acctno";
$HASHNAMES{"RTDBNAME"} = "RTHASH";

$DBNAMES{"SGDBNAME"} = $SGDBNAME;
$DBDESCS{"SGDBNAME"} = $SGDESC;
$DBNAME{"SGDBNAME"}  = $SGNAME;
$DBTABN{"SGDBNAME"}  = "$SGTABLE";
$DBFLDS{"SGDBNAME"}  = "SGFIELDS";
$DBKEYF{"SGDBNAME"}  = "";

$DBNAMES{"DIDBNAME"} = $DIDBNAME;
$DBDESCS{"DIDBNAME"} = $DIDESC;
$DBNAME{"DIDBNAME"}  = $DINAME;
$DBTABN{"DIDBNAME"}  = "$DITABLE";
$DBFLDS{"DIDBNAME"}  = "DIFIELDS";
$DBKEYF{"DIDBNAME"}  = "claim_id";
$HASHNAMES{"DIDBNAME"}  = "DIHASH";

$DBNAMES{"DCDBNAME"} = $DCDBNAME;
$DBDESCS{"DCDBNAME"} = $DCDESC;
$DBNAME{"DCDBNAME"}  = $DCNAME;
$DBTABN{"DCDBNAME"}  = "$DCTABLE";
$DBFLDS{"DCDBNAME"}  = "DCFIELDS";
$DBKEYF{"DCDBNAME"}  = "SwVendor:DateTransmitted:NCPDPNumber:DateOfService:RxNumber:TransactionCode:DateOfBirth:TotalAmountPaid:BinNumber:FillNumber";
$HASHNAMES{"DCDBNAME"}  = "DCHASH";

$DBNAMES{"CLDBNAME"} = $CLDBNAME;
$DBDESCS{"CLDBNAME"} = $CLDESC;
$DBNAME{"CLDBNAME"}  = $CLNAME;
$DBTABN{"CLDBNAME"}  = "$CLTABLE";
$DBFLDS{"CLDBNAME"}  = "CLFIELDS";
$DBKEYF{"CLDBNAME"}  = "SwVendor:DateTransmitted:NCPDPNumber:DateOfService:RxNumber:TransactionCode:DateOfBirth:TotalAmountPaid:BinNumber:FillNumber";
$HASHNAMES{"CLDBNAME"}  = "CLHASH";

#______________________________________________________________________________

$REPTOPNUM = 6;

#______________________________________________________________________________

# All above defs need to be in place for set_fields_types to work

&set_fields_types;

&setheadings;

&set_OPTS_arrays;

$SALT = "King Biscuit Flower Hour";    # DO NOT DELETE...

$ANCIENT       = 180;        # if incoming table data is over 180 days, remove it
$SECONDSINADAY = 60 * 60 * 24;

######## NEW GLOBALS TO GET RID OF WALLY REFERENCE#####

$RECONRXNR = "NoReply\@recon-rx.com";
$RECONRXCS = "Recon\@outcomes.com";
$EMAILUSER{"NoReply"}        = "PharmAssess\@computer-rx.net";
$EMAILACCT{"NoReply"}        = "DoNotReply\@tdsclinical.com";
$EMAILACCTPWD{"NoReply"}     = "799Crx!!";
$EMAILACCT{"PAIT"}           = "PAIT\@outcomes.com";
$EMAILACCTPWD{"PAIT"}        = "799Crx!!";
$EMAILACCT{"Recon"}          = "Recon\@outcomes.com";
$EMAILACCTPWD{"Recon"}       = "799Crx!!";
$EMAILACCT{"RBS"}            = "RBS\@outcomes.com";
$EMAILACCTPWD{"RBS"}         = "799Crx!!";

######## NEW GLOBALS TO GET RID OF WALLY REFERENCE#####

$RECONRXSUPPORT= "PAIT\@outcomes.com";
$RECONRXEMAIL  = "JKanatzar\@outcomes.com, PAIT\@outcomes.com, apritchard\@outcomes.com ";
$FIXRECONRX    = "jkanatzar\@outcomes.com, bpeterson\@outcomes.com, PAIT\@outcomes.com";

$CANNEDFILESDIR           = "D:/RedeemRx/CannedFiles";


$ContactProgram{"RBS"}      = "Pharm AssessRBS";
$ContactEmail{"RBS"}        = "RBS\@outcomes.com";
$ContactPhone{"RBS"}        = "(913) 897-4343";
$ContactTollFree{"RBS"}     = "(888) 255-6526";
$ContactFaxCred{"RBS"}      = "(888) 825-4157";
$ContactProgram{"ReconRx"}  = "ReconRx";
$ContactEmail{"ReconRx"}    = "Recon\@outcomes.com";
$ContactPhone{"ReconRx"}    = "(913) 897-4343";
$ContactTollFree{"ReconRx"} = "(888) 255-6526";
$ContactFaxReg{"ReconRx"}   = "(888) 618-8535";
$ContactProgram{"PAI"}      = "Pharm Assess";
$ContactEmail{"PAI"}        = "info\@Pharmassess.com";
$ContactPhone{"PAI"}        = "(913) 897-4343";
$ContactTollFree{"PAI"}     = "(888) 255-6526";
$ContactFaxCred{"PAI"}      = "(888) 825-4157";

@PAINOTINOFFICE = (
"Memorial Day",
"Independence Day",
"Labor Day",
"Thanksgiving",
"Christmas Eve",
"Christmas",
"New Years Day"
);

(@CCNCOLUMNS) = &get_column_names('claimsdata', 'claims');

#______________________________________________________________________________
#
# Constants

$months{Jan} =  1; $months{Feb} =  2; $months{Mar} =  3; $months{Apr} =  4;
$months{May} =  5; $months{Jun} =  6; $months{Jul} =  7; $months{Aug} =  8;
$months{Sep} =  9; $months{Oct} = 10; $months{Nov} = 11; $months{Dec} = 12;

$MONTHS{1} = "Jan"; $MONTHS{2}  = "Feb"; $MONTHS{3}  = "Mar"; $MONTHS{4}  = "Apr";
$MONTHS{5} = "May"; $MONTHS{6}  = "Jun"; $MONTHS{7}  = "Jul"; $MONTHS{8}  = "Aug";
$MONTHS{9} = "Sep"; $MONTHS{10} = "Oct"; $MONTHS{11} = "Nov"; $MONTHS{12} = "Dec";

$FMONTHS{1}  = "January"; $FMONTHS{2}  = "February"; $FMONTHS{3}  = "March";
$FMONTHS{4}  = "April";   $FMONTHS{5}  = "May";      $FMONTHS{6}  = "June";
$FMONTHS{7}  = "July";    $FMONTHS{8}  = "August";   $FMONTHS{9}  = "September";
$FMONTHS{10} = "October"; $FMONTHS{11} = "November"; $FMONTHS{12} = "December";
$THISMONTH = $FMONTHS{$month};
$LASTMONTH = $FMONTHS{$lmonth};

$DAYS{0} = "Sun"; $DAYS{1} = "Mon"; $DAYS{2} = "Tue"; $DAYS{3} = "Wed";
$DAYS{4} = "Thu"; $DAYS{5} = "Fri"; $DAYS{6} = "Sat";
$FULLDAYS{0} = "Sunday";   $FULLDAYS{1} = "Monday"; $FULLDAYS{2} = "Tuesday";   $FULLDAYS{3} = "Wednesday";
$FULLDAYS{4} = "Thursday"; $FULLDAYS{5} = "Friday"; $FULLDAYS{6} = "Saturday";

#______________________________________________________________________________

sub isMember {
  my ($USER, $PASS) = @_;
  $PROGRAM = "RBS";
  my ($isMember, $VALID) = &isAuthorizedMember($USER, $PASS, $PROGRAM);
  return($isMember, $VALID);
}

sub dispHeadings {
  
  my ($ismain) = @_;

  if ( $ismain ) {
  
     my $mytd = qq#<td align=left valign=middle>#;
     print qq#<!-- Start dispHeadings -->\n#;
     print qq#<table border=0 cellpadding=0 cellspacing=0>\n#;
     print qq#<tr>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = "Affiliates";
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = "ThirdPartyMenu,Third Party";
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = qq#Pharmacies.cgi?doCOO=0", Pharmacies#;
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = "Companies";
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = "Vendors";
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     print qq#${mytd}\n#;
       $WHAT = "Reports";
       &doform($WHAT);
     print qq#</td>\n#;
     #----------------------------
     if ( $TYPE =~ /All|Admin/i ) {
        print qq#${mytd}\n#;
          $WHAT = "Utilities";
          &doform($WHAT);
        print qq#</td>\n#;
        print qq#${mytd}\n#;
     }

     #----------------------------
     print qq#<tr>\n#;
     print qq#<td align=left valign=middle colspan=8>#;
     print qq#<hr size=4 color=green noshade>#;
     print qq#</td>\n#;
     print qq#</tr>\n#;
     #----------------------------
     print "</table>\n";
  }

  $JFIRSTTIME = 0;

}

#______________________________________________________________________________

sub doform {

  my ($WHAT) = @_;
  my $display;

  if ( $WHAT =~ /,/ ) {
     ($page, $display) = split(",", $WHAT, 2);
     $page    =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
     $display =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
     if ( $page =~ /.php/i ) {
        $URL  = "${page}";
     } else {
        $URL  = "${page}.cgi";
     }
     $submitvalue = "$display";
  } else {
     if ( $page =~ /.php/i ) {
        $URL  = "${WHAT}";
     } else {
        $URL  = "${WHAT}.cgi";
     }
     $submitvalue = "$WHAT";
  }
  print qq#  <FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="CUSTOMERID" VALUE="$CUSTOMERID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="display" VALUE="$display">\n#;
  if ( $JFIRSTTIME ) {
    print qq#    <INPUT TYPE="hidden" NAME="USER"    VALUE="$USER">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="PASS"    VALUE="$PASS">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="VALID"   VALUE="$VALID">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="isAdmin" VALUE="$isAdmin">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="isMember" VALUE="$isMember">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="LFIRSTLOGIN" VALUE="$LFIRSTLOGIN">\n#;
    print qq#    <INPUT TYPE="hidden" NAME="LPERMISSIONLEVEL" VALUE="$LPERMISSIONLEVEL">\n#;
  }
  print qq#    <INPUT TYPE="Submit" VALUE="$submitvalue">\n#;
  print qq#  </FORM>\n#;

}

#______________________________________________________________________________

sub doformT {

  my ($WHAT, $URL) = @_;

  # $URL  = "${WHAT}.cgi";
  $submitvalue = "$WHAT";

  print qq#  <FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="debug"    VALUE="$debug">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="verbose"  VALUE="$verbose">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="CUSTOMERID" VALUE="$CUSTOMERID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispTab"  VALUE="$WHAT">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="db"       VALUE="$dbin">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="opt"      VALUE="$opt">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="sf"       VALUE="$sf">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inNPI"    VALUE="$inNPI">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispNPI"  VALUE="$dispNPI">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inTPPID"   VALUE="$inTPPID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispTPPID" VALUE="$dispTPPID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inAFFID"   VALUE="$inAFFID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispAFFID" VALUE="$dispAFFID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inVNID"   VALUE="$inVNID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispVNID" VALUE="$dispVNID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inPVID"   VALUE="$inPVID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispPVID" VALUE="$dispPVID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inPTID"   VALUE="$inPTID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispPTID" VALUE="$dispPTID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inTBID"   VALUE="$inTBID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispTBID" VALUE="$dispTBID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inBIN"    VALUE="$inBIN">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispBIN"  VALUE="$dispBIN">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inCompanyID" VALUE="$inCompanyID">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="inCompany"    VALUE="$inCompany">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="dispCompany"  VALUE="$dispCompany">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="ACTION"   VALUE="$ACTION">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="SELD"     VALUE="$SELD">\n#;
  print qq#    <INPUT TYPE="Submit" VALUE="$submitvalue">\n#;
  print qq#  </FORM>\n#;

}

#______________________________________________________________________________

sub dispReportHeadings {
  
  my $mytd = qq#<td align=left valign=middle>#;

  print qq#<table border=0 cellpadding=2 cellspacing=2>\n#;
  print qq#<tr>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Invoices";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
#  print qq#${mytd}\n#;
#    $WHAT = "Affiliates";
#    &doform_Reports($WHAT);
#   print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "ThirdParty,Third Party";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Pharmacies";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "PharmacyAdhoc,Pharmacy Adhoc";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Vendors";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Interventions";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Admin";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Dashboard";
    &doform($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#</tr>\n#;
  print qq#</table>\n#;
  #----------------------------
  #----------------------------
  print qq#<table border=0 cellpadding=2 cellspacing=2>\n#;
  print qq#<tr>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "PharmVendRels, Pharmacy/Vendor Relationships";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "SuccessStory,Success Stories";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "RBS,RBS";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#${mytd}\n#;
    $WHAT = "Credentialing,Credentialing";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  if ( $PAI_Reports_DBDump =~ /^Yes/i ) {
     print qq#${mytd}\n#;
       $WHAT = "DBDump,DB Dump";
       &doform_Reports($WHAT);
     print qq#</td>\n#;
  }
  print qq#${mytd}\n#;
    $WHAT = "RBSDirect,RBS Direct";
    &doform_Reports($WHAT);
  print qq#</td>\n#;

  print qq#${mytd}\n#;
    $WHAT = "RingCentral,RingCentral";
    &doform_Reports($WHAT);
  print qq#</td>\n#;
  #----------------------------
  print qq#</tr>\n#;
  print qq#</table>\n#;
  #----------------------------

}

#______________________________________________________________________________

sub doform_Reports {

  my ($WHAT) = @_;
  my $display;

  if ( $WHAT =~ /,/ ) {
     ($page, $display) = split(",", $WHAT, 2);
     $page =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
     $display =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
     $URL  = "Reports${page}.cgi";
     $submitvalue = "$display";
  } else {
     $URL  = "Reports${WHAT}.cgi";
     $submitvalue = "$WHAT";
  }

  print qq#  <FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="debug"    VALUE="$debug">\n#;
  print qq#    <INPUT TYPE="hidden" NAME="verbose"  VALUE="$verbose">\n#;
  print qq#    <INPUT TYPE="Submit" NAME="REPORT"   VALUE="$submitvalue">\n#;
  print qq#  </FORM>\n#;

}

#______________________________________________________________________________

sub MyRBSDesktopHeaderMainMenu {

# Print the header
  print &PrintHeader;
#####
# chomp($hostname = `hostname`);
  $ntitle = $title;
  if ( $ntitle =~ /\<\s*A/i ) {
     $ntitle =~ s/<[^>]*>//g;
  }
# $ntitle = "$hostname - $ntitle";

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PAIDesktopHeader_MainMenu.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyRBSDesktopHeader {

# Print the header
  print &PrintHeader;
#####
# chomp($hostname = `hostname`);
  $MYDEVENV;
  my ($ENV) = &What_Env_am_I_in;
  if ( $ENV =~ /Dev/i ) {
     $MYDEVENV = " ( " . uc($ENV) . " )";
  } else {
     $MYDEVENV = "";
  }

  $ntitle = $title;
  if ( $ntitle =~ /\<\s*A/i ) {
     $ntitle =~ s/<[^>]*>//g;
  }

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PAIDesktopHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub read_canned_header {
  my $FILE = shift;
	
  print &PrintHeader;

  # Read in canned file, use variables to fill in "<%var%>" values

  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}
sub MyPharmassessMembersHeader {
  print &PrintHeader;

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PharmassessMembersHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

sub CredentialingMembersHeader {
  print &PrintHeader;

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "CredentialingMembersHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyPharmassessMembersTrailer {

  # Read in canned file, use variables to fill in "<%var%>" values

  ($CPYEAR) = (localtime())[5];
  $CPYEAR  += 1900;

  my $FILE = "OutcomesRBSTrailer.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyPharmassessReportingTrailerPrint {

  # Read in canned file, use variables to fill in "<%var%>" values

  ($CPYEAR) = (localtime())[5];
  $CPYEAR  += 1900;

  my $FILE = "PharmassessReportingTrailerPrint.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyAreteRxHeader_old {

# Print the header
  print &PrintHeader;
#####
  my ($package, $filename, $line) = caller;
  my ($prog, $dir, $ext) = fileparse($filename, '\..*');

  ($title = "$prog") =~ s/_/ /g;
  ##$title =~  s/AreteRx//g;
  ##$title = qq#Arete Pharmacy Network - $title#;
  $title = qq#${RECONRXCOMPANY} - $title# if ( $RECONRXCOMPANY );

  $ntitle = $title;
  if ( $ntitle =~ /\<\s*A/i ) {
     $ntitle =~ s/<[^>]*>//g;
  }

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "ReconRxHeader.html";
  ##my $FILE = "AreteRxHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }

# &set_Webinar_or_Testing_DBNames;

}
#______________________________________________________________________________

sub MyReconRxHeader {

# Print the header
  print &PrintHeader;
#####
  my ($package, $filename, $line) = caller;
  my ($prog, $dir, $ext) = fileparse($filename, '\..*');

  ($title = "$prog") =~ s/_/ /g;
  $title = qq#${RECONRXCOMPANY} - $title# if ( $RECONRXCOMPANY );

  $ntitle = $title;
  if ( $ntitle =~ /\<\s*A/i ) {
     $ntitle =~ s/<[^>]*>//g;
  }

  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "ReconRxHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }

# &set_Webinar_or_Testing_DBNames;

}

#______________________________________________________________________________

sub MyReconRxTrailer {

  # Read in canned file, use variables to fill in "<%var%>" values

  ($CPYEAR) = (localtime())[5];
  $CPYEAR  += 1900;

  my $FILE = "ReconRx_trailer.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyPharmassessReportingWeeklyHeader {

# Print the header
  print &PrintHeader;
#####
  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PharmassessReportingWeeklyHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyPharmassessReportingMonthlyHeader {

# Print the header
  print &PrintHeader;
#####
  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PharmassessReportingMonthlyHeader.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub MyPharmassessReportingMonthlyHeaderPrint {

# Print the header
  print &PrintHeader;
#####
  # Read in canned file, use variables to fill in "<%var%>" values

  my $FILE = "PharmassessReportingMonthlyHeaderPrint.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }
}

#______________________________________________________________________________

sub header {

# Print the header
  print &PrintHeader;

}

#______________________________________________________________________________

sub trailer {

  print "<br>sub trailer: entry<br>\n" if ($debug);

  ($CPYEAR) = (localtime())[5];
  $CPYEAR  += 1900;

  my $FILE = "PAIDesktop_trailer.html";
  my ($message, @array) = &read_canned_file($FILE);
  foreach $line (@array) {
     print "$line\n";
  }

  if ($debug) {
     if ( $start > 0 ) {
        $elapsed = time() - $start;
        print "<hr>Elapsed: $elapsed<hr>\n";
     }
  }

  print "sub trailer: end<P>\n" if ($debug);

}

#______________________________________________________________________________

sub getDBinfo {

# my $debug++;
# my $verbose++;

  my ($HEADPREFIX) = @_;

  print "<hr>sub getDBinfo: Entry. HEADPREFIX: $HEADPREFIX, sfStatus: $sfStatus, sf: $sf, inNPI: $inNPI,<br>inBIN: $inBIN, inVNName: $inVNName, inInterventionID: $inInterventionID, inPharmacyID: $inPharmacyID, inTBID: $inTBID, inStatus: $inStatus<br><br>\n" if ($debug);
  my ($ENV) = &What_Env_am_I_in;

  if ( $sf =~ /'|"/ ) {
     $sf2 = "\Q$sf\E";
  }

  if ( $HEADPREFIX =~ /CO/i ) {
     $myStatusvar = "Status_Cred";
  } else {
     $myStatusvar = "Status";
  }

  my $sql;
  my $addcloser = 0;
  my $INTKEYS   = "";

  if ( $sfStatus =~ /Active|Transition|Pending/i ) {
    if ( $HEADPREFIX =~ /PH|PM|P2/i ) {

       $sql = qq#SELECT * FROM $DBNAME.$TABLE #;
       $sql .= qq#WHERE (
(  Status_Cred='$sfStatus'
|| Status_RBS='$sfStatus'
|| Status_RBS_Direct='$sfStatus'
|| Status_ReconRx='$sfStatus'
|| Status_ReconRx_Clinic='$sfStatus'
|| Status_RedeemRx='$sfStatus'
|| Status_DefaultCash = '$sfStatus'
) && #;
       $addcloser++;
    } elsif ( $HEADPREFIX =~ /CO/i ) {
       $sql = qq#SELECT * FROM $DBNAME.$TABLE #;
       $sql .= qq#WHERE ( ( Status_Cred='$sfStatus' ) && #;
       $addcloser++;
    } elsif ( $HEADPREFIX =~ /AF|VN|PV|PT|TB/i ) {
       $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE #;
    } elsif ( $HEADPREFIX =~ /RP/i ) {
       $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE #;
    } elsif ( $HEADPREFIX =~ /IN/i ) {
       if ( $inPharmacyID =~ /^All$/i ) {
          $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE (#;
       } else {
          $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE (Pharmacy_ID = '$inPharmacyID') && (#;
       }
       $addcloser++;
    } else {
       $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE #;
       $addcloser = 0;
    }
  } else {
    $sql = qq#SELECT * FROM $DBNAME.$TABLE WHERE #;
    $addcloser = 0;
  }
  if ( $inRxNumber ) {
     $sql .= qq# Mac_Rx_Number='$inRxNumber' && #;
     print "3ll. sql: $sql<br>\n" if ($debug);
  }

  if ( ($sf        && $sf        !~ /\*all/i) ||
       ($inNPI     && $inNPI     !~ /\*all/i) ||
       ($inNCPDP   && $inNCPDP   !~ /\*all/i) ||
       ($inTPPID   && $inTPPID   !~ /\*all/i) || 
       ($inBIN     && $inBIN     !~ /\*all/i) || 
       ($inAFFName && $inAFFName !~ /\*all/i) ||
       ($inVNName  && $inVNName  !~ /\*all/i) ||
       ($inPVID    && $inPVID    !~ /\*all/i) ||
       ($inPTID    && $inPTID    !~ /\*all/i) ||
       ($inTBID    && $inTBID    !~ /\*all/i) ||
       ($inOPName  && $inOPName  !~ /\*all/i) ||
        $inStatus || $inCSR || $inType ||
        $inInterventionID || $inCategory || $inProgram || $inComments ||
    $inOpenedDate || $inClosedDate ||
    $in2OpenedDate || $in2ClosedDate 
     ) {

     print "2. TABLE: $TABLE, sql:<br>$sql<hr>\n" if ($debug);

     if ( $TABLE =~ /Interventions/i ) {
        if ( $sql !~ /Pharmacy_ID/i ) {
           if ( $inNPI ) {
              $jNCPDP = $Pharmacy_NPIs{$inNPI};
              if ( $jNCPDP ) {
                 $sql .= qq# Pharmacy_ID LIKE '%$jNCPDP%' OR #;
                 print "3jj. sql: $sql<br>\n" if ($debug);
              }
           }
           if ( $inNCPDP ) {
              if ( $inNCPDP ) {
                   $sql .= qq# Pharmacy_ID LIKE '%$inNCPDP%' OR #;
                 print "3kk. sql: $sql<br>\n" if ($debug);
                }
           }
        }
     }
     if ( $inNPI && $TABLE !~ /Interventions/i ) {
        $sql .= qq# NPI LIKE '%$inNPI%'#;
        print "3a. sql: $sql<br>\n" if ($debug);
     } elsif ( $inNCPDP && $TABLE !~ /Interventions|Rep/i ) {
        $sql .= qq# NCPDP LIKE '%$inNCPDP%'#;
        print "3b. sql: $sql<br>\n" if ($debug);
     } elsif ( $inBIN ) {
        $sql .= qq# BIN LIKE '%$inBIN%' OR #;
     print "3c. sql: $sql<br>\n" if ($debug);
     } elsif ( $inTPPID ) {
        $sql .= qq# Third_Party_Payer_ID LIKE '%$inTPPID%' OR #;
     print "3d. sql: $sql<br>\n" if ($debug);
     } elsif ( $inAFFName ) {
        $sql .= qq# Affiliate_Name LIKE '%$inAFFName%' OR #;
     print "3e. sql: $sql<br>\n" if ($debug);
     } elsif ( $inVNName ) {
        $sql .= qq# Vendor_Name LIKE '%$inVNName%' OR #;
     print "3f. sql: $sql<br>\n" if ($debug);
     } elsif ( $inPVID ) {
        $sql .= qq# Pharmacys_Vendor_ID LIKE '%$inPVID%' OR #;
     print "3g. sql: $sql<br>\n" if ($debug);
     } elsif ( $inPTID ) {
        $sql .= qq# Pharmacys_TPP_ID LIKE '%$inPTID%' OR #;
     print "3g. sql: $sql<br>\n" if ($debug);
     } elsif ( $inTBID ) {
        $sql .= qq# TPP_ID LIKE '%$inPTID%' OR #;
     print "3g. sql: $sql<br>\n" if ($debug);

     } elsif ( $inStatus || $inCSR || $inType || $inInterventionID ||
           $inCategory || $inProgram || $inComments ||
           $inOpenedDate || $inClosedDate ||
           $in2OpenedDate || $in2ClosedDate ) {
        $sql .= qq# ( #;

         if ( $sf && $sf !~ /^\s*$|^ALL$/i) {
            $sql .= qq# Comments LIKE '%$sf2%' && #;
         }
         if ( $inStatus && $inStatus !~ /^\s*$|^ALL$/i) {
            $sql .= qq# $myStatusvar LIKE '%$inStatus%' && #;
         }
         if ( $inType && $inType !~ /^\s*$|^All$/i) {
            $sql .= qq# Type LIKE '%$inType%' && #;
         }
         if ( $inInterventionID && $inInterventionID !~ /^\s*$|^ALL$/i) {
            $sql .= qq# Intervention_ID LIKE '%$inInterventionID%' && #;
         }
         if ( $inCategory && $inCategory !~ /^\s*$|^ALL$/i) {
            $sql .= qq# Category LIKE '%$inCategory%' && #;
         }
         if ( $inProgram && $inProgram !~ /^\s*$|^ALL$/i) {
            $sql .= qq# Program LIKE '%$inProgram%' && #;
         }
         if ( ($inOpenedDate && $inOpenedDate !~ /^\s*$|^ALL$/i) ||
              ($in2OpenedDate && $in2OpenedDate !~ /^\s*$|^ALL$/i) ) {
        if ( $inOpenedDate ) {
               $IOD = $inOpenedDateTS;
        } else {
               $IOD = 0;
        }
        if ( $in2OpenedDate ) {
               $I2OD = $in2OpenedDateTS;
        } else {
               $I2OD = 9999999999;
        }
        $sql .= qq# (Opened_Date_TS >= '$IOD' && Opened_Date_TS <= '$I2OD') && #;
         }
        if ( ($inClosedDate && $inClosedDate !~ /^\s*$|^ALL$/i) ||
              ($in2ClosedDate && $in2ClosedDate !~ /^\s*$|^ALL$/i) ) {
           if ( $inClosedDate ) {
              $ICD = $inClosedDateTS;
           } else {
              $ICD = 0;
           }
           if ( $in2ClosedDate ) {
              $I2CD = $in2ClosedDateTS;
           } else {
              $I2CD = 9999999999;
           }
           $sql .= qq# (Closed_Date_TS >= '$ICD' && Closed_Date_TS <= '$I2CD') && #;
         }
   ######################

         if ( $inCSR && $inCSR !~ /^\s*$|^ALL$/i) {
       $sql .= qq# CSR_Name LIKE '%$inCSR%' && #;
         }
       $sql =~ s/ && $//gi;
       $sql .= qq# ) #;
       $sql =~ s/ \(\s*\)//gi;
       $sql =~ s/ WHERE\s*$//gi;
       print "3h. sql: $sql<br>\n" if ($debug);

     } else {

       print "4a. sf: $sf, sf2: $sf2<br>\n" if ($debug);
       if ( $sf !~ /^\s*$/ ) {
          $sql =~ s/$/ && (/ if ( $inNPI );
          $sql .= qq#( #;
          foreach $field (@$FIELDS2) {
            $field =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
            $sql .= qq#$field LIKE '%$sf2%' OR #;
          }
          $sql .= qq# ) \n#;
       }
     }
     $sql =~ s/ OR $//;
     print "4. sql: $sql<br>\n" if ($debug);

  } elsif ( ($sf    =~ /^all$|\*all/i) ||
        ($inNPI     =~ /^all$|\*all/i) ||
        ($inNCPDP   =~ /^all$|\*all/i) ||
        ($inTPPID   =~ /^all$|\*all/i) ||
        ($inBIN     =~ /^all$|\*all/i) ||
        ($inAFFName =~ /^all$|\*all/i) ||
        ($inVNName  =~ /^all$|\*all/i) ||
        ($inPVID    =~ /^all$|\*all/i) ||
        ($inPTID    =~ /^all$|\*all/i) ||
        ($inTBID    =~ /^all$|\*all/i) ||
        ($inInterventionID =~ /^all$|\*all/i)
          ) {
     print "5. sql: $sql<br>\n" if ($debug);

  } else {

     print "6. sql: $sql<br>\n" if ($debug);
  }

  $sql =~ s/ WHERE $//i if ( $sql =~ / WHERE $/i );
  $sql =~ s/ and $//i if ( $sql =~ / and $/i );
  $sql .= " )" if ($addcloser);
  print "7. sql: $sql<br>\n" if ($debug);

  $sql =~ s/\s+&&\s*\)\s*$/\)/g;
  $sql =~ s/\s*\(\s*\)\s*$//i;
  $sql =~ s/\s*WHERE\s*$//i;
  $sql =~ s/ && \( \)//i;
  $sql =~ s/ \(\s+\)//i;
  $sql =~ s/ &&\s*$//i;
  $sql =~ s/ OR\s*\)/\)/i;

  if ( $dbin =~ /PHDBNAME|P2DBNAME/i ) {
     $sql .= qq# ORDER BY Pharmacy_Name#;
  } elsif ( $dbin =~ /TPDBNAME/i ) {
     $sql .= " ORDER BY Third_Party_Payer_ID";
  } elsif ( $dbin =~ /AFDBNAME/i ) {
     $sql .= " ORDER BY Affiliate_Name";
  } elsif ( $dbin =~ /VNDBNAME/i ) {
     $sql .= " ORDER BY Vendor_Name";
  } elsif ( $dbin =~ /PTDBNAME/i ) {
     $sql .= " ORDER BY Pharmacys_TPP_ID";
  } elsif ( $dbin =~ /PSDBNAME/i ) {
     $sql .= " ORDER BY TPP_Pri_Sec_ID";
  } elsif ( $dbin =~ /TBDBNAME/i ) {
     $sql .= " ORDER BY TPP_ID";
  } elsif ( $dbin =~ /PSDBNAME/i ) {
     $sql .= " ORDER BY TPP_Pri_Sec_ID";
  } else {
     # leave as is if not defined
  }

# print "ENV: $ENV, debug: $debug<hr>\n";
  if ( $ENV =~ /dev/i || $debug ) {
#    print "<hr><pre>sql:\n$sql</pre><hr>\n";
  }
  $JSQL = $sql;

  $sthx = $dbx->prepare($sql);
  $sthx->execute();
   
  my $numofrows = $sthx->rows;
  print "Number of rows found: " . $sthx->rows . "<br>\n" if ($debug);
  $NumOfRowsFound = $numofrows;

  while ( my $tabref = $sthx->fetchrow_hashref() ) {
  
    $keyf = "";
    foreach $jkey (@KEYFs) {
       $keyf .= $tabref->{"$jkey"} . ":";
    }
    chop($keyf);    # remove the trailing ":"
    print qq#Key Field: $keyf<br>\n#  if ($verbose);

    foreach $field (@$FIELDS2) {
       $field =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces
       $value = $tabref->{"$field"};
       $value = "&nbsp;" if ( !$value && $value != 0 );
       print qq#JJJ: field: $field, value: $value<br>\n# if ($incdebug);
       $HoH{$keyf}->{$field} = "$value";
       print qq#KKK: HoH($keyf): $HoH{$keyf}->{$field}<hr>\n# if ($incdebug);
    }
    print "<hr size=4 noshade color=red>\n" if ($verbose);
  }
  $sthx->finish();
  
  (my $sqlout = $sql) =~ s/\n/<br>\n/g;

  return (\%HoH);
   
}

#______________________________________________________________________________

sub set_fields_types {

  print "sub set_fields_types: Entry.<p>\n" if ($verbose);

  $set_fields_types_start = time();

  my %attr = ( PrintWarn=>1, RaiseError=>1, PrintError=>1, AutoCommit=>1, InactiveDestroy=>0, HandleError => \&handle_error_batch );
  my $db0 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST", $dbuser,$dbpwd, \%attr) || &handle_error_batch;
  DBI->trace(1) if ($dbitrace);

  foreach $db (@RBSDesktopDBs) {
     $DBNAME = $DBNAMES{$db};
     $TABLE  = $DBTABN{$db};
     $HASH   = $HASHNAMES{$db};
     $XXFIELDS = $DBFLDS{"$db"};
     $$XXFIELDS = "";

     my $sth0 = $db0->prepare("SELECT * FROM $DBNAME.$TABLE WHERE 1=0;");
     $sth0->execute;
     my @colsn = @{$sth0->{NAME}}; # or NAME_lc if needed
     my @colst = @{$sth0->{mysql_type_name}};
     $ptr = 0;
     print "Column Name | Type<br>\n" if ($debug);
     foreach my $key ( @colsn ) {
       $$HASH{$key} = $colst[$ptr];
       printf( "%s | %s<br>\n", $key, $colst[$ptr] ) if ($debug);

       $$XXFIELDS .= qq#$key, #;

       $ptr++;
     }
     $$XXFIELDS =~ s/, $//;    # remove trailing ", "

     $sth0->finish;

  }
  # Close the Database
  $db0->disconnect;

  (@ACFIELDS2)  = &create_dol_fields($ACFIELDS);
  (@AFFIELDS2)  = &create_dol_fields($AFFIELDS);
  (@BGFIELDS2)  = &create_dol_fields($BGFIELDS);
  (@BXFIELDS2)  = &create_dol_fields($BXFIELDS);
  (@CBFIELDS2)  = &create_dol_fields($CBFIELDS);
  (@CCFIELDS2)  = &create_dol_fields($CCFIELDS);
  (@C8FIELDS2)  = &create_dol_fields($C8FIELDS);
  (@CAFIELDS2)  = &create_dol_fields($CAFIELDS);
  (@CDFIELDS2)  = &create_dol_fields($CDFIELDS);
  (@CEFIELDS2)  = &create_dol_fields($CEFIELDS);
  (@COFIELDS2)  = &create_dol_fields($COFIELDS);
  (@FRFIELDS2)  = &create_dol_fields($FRFIELDS);
  (@ICFIELDS2)  = &create_dol_fields($ICFIELDS);
  (@IGFIELDS2)  = &create_dol_fields($IGFIELDS);
  (@INFIELDS2)  = &create_dol_fields($INFIELDS);
  (@IRFIELDS2)  = &create_dol_fields($IRFIELDS);
  (@LTFIELDS2)  = &create_dol_fields($LTFIELDS);
  (@MAFIELDS2)  = &create_dol_fields($MAFIELDS);
  (@MCFIELDS2)  = &create_dol_fields($MCFIELDS);
  (@MHFIELDS2)  = &create_dol_fields($MHFIELDS);
  (@M2FIELDS2)  = &create_dol_fields($M2FIELDS);
  (@M01FIELDS2) = &create_dol_fields($M01FIELDS);
  (@M02FIELDS2) = &create_dol_fields($M02FIELDS);
  (@M03FIELDS2) = &create_dol_fields($M03FIELDS);
  (@M04FIELDS2) = &create_dol_fields($M04FIELDS);
  (@M05FIELDS2) = &create_dol_fields($M05FIELDS);
  (@M06FIELDS2) = &create_dol_fields($M06FIELDS);
  (@M07FIELDS2) = &create_dol_fields($M07FIELDS);
  (@M08FIELDS2) = &create_dol_fields($M08FIELDS);
  (@M09FIELDS2) = &create_dol_fields($M09FIELDS);
  (@M10FIELDS2) = &create_dol_fields($M10FIELDS);
  (@M11FIELDS2) = &create_dol_fields($M11FIELDS);
  (@M12FIELDS2) = &create_dol_fields($M12FIELDS);
  (@M13FIELDS2) = &create_dol_fields($M13FIELDS);
  (@M14FIELDS2) = &create_dol_fields($M14FIELDS);
  (@M15FIELDS2) = &create_dol_fields($M15FIELDS);
  (@M16FIELDS2) = &create_dol_fields($M16FIELDS);
  (@OPFIELDS2)  = &create_dol_fields($OPFIELDS);
  (@OVFIELDS2)  = &create_dol_fields($OVFIELDS);
  (@P2FIELDS2)  = &create_dol_fields($P2FIELDS);
  (@P8FIELDS2)  = &create_dol_fields($P8FIELDS);
  (@PAFIELDS2)  = &create_dol_fields($PAFIELDS);
  (@PHFIELDS2)  = &create_dol_fields($PHFIELDS);
  (@PMFIELDS2)  = &create_dol_fields($PMFIELDS);
  (@PSFIELDS2)  = &create_dol_fields($PSFIELDS);
  (@PTFIELDS2)  = &create_dol_fields($PTFIELDS);
  (@PVFIELDS2)  = &create_dol_fields($PVFIELDS);
  (@PWFIELDS2)  = &create_dol_fields($PWFIELDS);
  (@R3FIELDS2)  = &create_dol_fields($R3FIELDS);
  (@R8FIELDS2)  = &create_dol_fields($R8FIELDS);
  (@RAFIELDS2)  = &create_dol_fields($RAFIELDS);
  (@RBFIELDS2)  = &create_dol_fields($RBFIELDS);
  (@RDFIELDS2)  = &create_dol_fields($RDFIELDS);
  (@REFIELDS2)  = &create_dol_fields($REFIELDS);
  (@RIFIELDS2)  = &create_dol_fields($RIFIELDS);
  (@RLFIELDS2)  = &create_dol_fields($RLFIELDS);
  (@RMFIELDS2)  = &create_dol_fields($RMFIELDS);
  (@RNFIELDS2)  = &create_dol_fields($RNFIELDS);
  (@RPFIELDS2)  = &create_dol_fields($RPFIELDS);
  (@RRFIELDS2)  = &create_dol_fields($RRFIELDS);
  (@RSFIELDS2)  = &create_dol_fields($RSFIELDS);
  (@RTFIELDS2)  = &create_dol_fields($RTFIELDS);
  (@RWFIELDS2)  = &create_dol_fields($RWFIELDS);
  (@RXFIELDS2)  = &create_dol_fields($RXFIELDS);
  (@SEFIELDS2)  = &create_dol_fields($SEFIELDS);
  (@SGFIELDS2)  = &create_dol_fields($SGFIELDS);
  (@SMFIELDS2)  = &create_dol_fields($SMFIELDS);
  (@SCFIELDS2)  = &create_dol_fields($SCFIELDS);
  (@SHFIELDS2)  = &create_dol_fields($SHFIELDS);
  (@SXFIELDS2)  = &create_dol_fields($SXFIELDS);
  (@SWFIELDS2)  = &create_dol_fields($SWFIELDS);
  (@TCFIELDS2)  = &create_dol_fields($TCFIELDS);
  (@TNFIELDS2)  = &create_dol_fields($TNFIELDS);
  (@TPFIELDS2)  = &create_dol_fields($TPFIELDS);
  (@VNFIELDS2)  = &create_dol_fields($VNFIELDS);
  (@WAFIELDS2)  = &create_dol_fields($WAFIELDS);
  (@WLFIELDS2)  = &create_dol_fields($WLFIELDS);
  (@ZZFIELDS2)  = &create_dol_fields($ZZFIELDS);

  (@DCFIELDS2)  = &create_dol_fields($DCFIELDS);
  (@DIFIELDS2)  = &create_dol_fields($DIFIELDS);

  # Southern Scripts Tables
  (@S8FIELDS2)  = &create_dol_fields($S8FIELDS);
  (@SPFIELDS2)  = &create_dol_fields($SPFIELDS);

  (@SSFIELDS2)  = &create_dol_fields($SSFIELDS);
  (@SAFIELDS2)  = &create_dol_fields($SAFIELDS);

  $set_fields_types_end = time();
  $set_fields_types_elapsed = $end - $start;

  print "sub set_fields_types: Exit.<p>\n" if ($verbose);

}

#______________________________________________________________________________

sub setheadings {

#--------------------------------------------------

# Now do Pharmacy Headings

  foreach $fld (@PHFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";

    if ( $fld =~ /^PHZip$/i ) {
      $heading = "Zip Code";
    } 
    $heading = $fld if ( !$heading);
    $heading =~ s/_/ /g;
    my $prefix = "PH";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

  foreach $fld (@COFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";

    if ( $fld =~ /^COZip$/i ) {
      $heading = "Zip Code";
    } 
    $heading = $fld if ( !$heading);
    $heading =~ s/_/ /g;
    my $prefix = "CO";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

  foreach $fld (@PMFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";

    if ( $fld =~ /^PMZip$/i ) {
      $heading = "Zip Code";
    } 
    $heading = $fld if ( !$heading);
    $heading =~ s/_/ /g;
    my $prefix = "PM";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
#--------------------------------------------------

# Now do RBSDesktop RLoginDB Headings

  foreach $fld (@RLFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";

    if ( $fld =~ /^LCustomerID$/i ) {
      $heading = "Customer ID";
    } elsif ( $fld =~ /^LLoginID$/i ) {
      $heading = "Login ID";
    } elsif ( $fld =~ /^LPassword$/i ) {
      $heading = "Password";
    } elsif ( $fld =~ /^LType$/i ) {
      $heading = "Type";
    } elsif ( $fld =~ /^LDateAdded$/i ) {
      $heading = "Date Added";
    } elsif ( $fld =~ /^LFirstLogin$/i ) {
      $heading = "First Login";
    } elsif ( $fld =~ /^LFirstName$/i ) {
      $heading = "First Name";
    } elsif ( $fld =~ /^LLastName$/i ) {
      $heading = "Last Name";
    }
    $heading = $fld if ( !$heading);
    my $prefix = "RL";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Third Party Payers Headings

  foreach $fld (@TPFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Third_Party_Payer_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Third_Party_Payer_Name/i ) {
       $heading = "Name";
    } elsif ( $fld =~ /City/i ) {
       $heading = "City";
    } elsif ( $fld =~ /State/i ) {
       $heading = "State";
    } elsif ( $fld =~ /Primary_Secondary/i ) {
       $heading = "P/S";
    }
    $heading = $fld if (!$heading);
    my $prefix = "TP";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Affiliate Headings

  foreach $fld (@AFFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Affiliate_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Affiliate_Name/i ) {
       $heading = "Name";
    }
    $heading = $fld if (!$heading);
    my $prefix = "AF";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Vendor Headings

  foreach $fld (@VNFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Vendor_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Vendor_Name/i ) {
       $heading = "Name";
    } elsif ( $fld =~ /City/i ) {
       $heading = "City";
    } elsif ( $fld =~ /State/i ) {
       $heading = "State";
    }
    $heading = $fld if (!$heading);
    my $prefix = "VN";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Vendor Headings

  foreach $fld (@PVFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Pharmacys_Vendor_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Pharmacy_ID/i ) {
       $heading = "Pharmacy ID";
    } elsif ( $fld =~ /Internal_Vendor_ID/i ) {
       $heading = "Internal Vendor ID";
    } elsif ( $fld =~ /Start_Date/i ) {
       $heading = "Start Date";
    } elsif ( $fld =~ /Term_Date/i ) {
       $heading = "Term Date";
    } elsif ( $fld =~ /User_ID/i ) {
       $heading = "User_ID";
    } elsif ( $fld =~ /Password/i ) {
       $heading = "Password";
    } elsif ( $fld =~ /Notes/i ) {
       $heading = "Notes";
    }
    $heading = $fld if (!$heading);
    my $prefix = "PV";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Third Party Payer Pri/Sec Relationship Headings

  foreach $fld (@PSFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /TPP_Pri_Sec_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /TPP_Pri_ID/i ) {
       $heading = "Primary BIN";
    } elsif ( $fld =~ /TPP_Sec_ID/i ) {
       $heading = "Secondary BIN";
    } elsif ( $fld =~ /Start_Date/i ) {
       $heading = "Start Date";
    } elsif ( $fld =~ /Term_Date/i ) {
       $heading = "Term Date";
    } elsif ( $fld =~ /Notes/i ) {
       $heading = "Notes";
    }
    $heading = $fld if (!$heading);
    my $prefix = "PS";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Third Party Payer Headings

  foreach $fld (@PTFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Pharmacys_TPP_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Pharmacy_ID/i ) {
       $heading = "Pharmacy ID";
    } elsif ( $fld =~ /Internal_TPP_ID/i ) {
       $heading = "Internal TPP ID";
    } elsif ( $fld =~ /Start_Date/i ) {
       $heading = "Start Date";
    } elsif ( $fld =~ /Term_Date/i ) {
       $heading = "Term Date";
    } elsif ( $fld =~ /User_ID/i ) {
       $heading = "User_ID";
    } elsif ( $fld =~ /Password/i ) {
       $heading = "Password";
    } elsif ( $fld =~ /Notes/i ) {
       $heading = "Notes";
    }
    $heading = $fld if (!$heading);
    my $prefix = "PT";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do OPTS Headings

  foreach $fld (@OPFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /OPTS_ID/i ) {
       $heading = "OPTS_ID";
    } elsif ( $fld =~ /Description/i ) {
       $heading = "Description";
    } elsif ( $fld =~ /Array/i ) {
       $heading = "Array";
    }
    $heading = $fld if (!$heading);
    my $prefix = "OP";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

#--------------------------------------------------

# Now do Interventions Headings

  foreach $fld (@INFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /CSR_ID/i ) {
       $heading = "CSR ID";
    } elsif ( $fld =~ /CSR_Name/i ) {
       $heading = "CSR";
    } elsif ( $fld =~ /Open_Date/i ) {
       $heading = "Open Date";
    } elsif ( $fld =~ /Due_Date/i ) {
       $heading = "Due Date";
    } elsif ( $fld =~ /Closed_Date/i ) {
       $heading = "Closed Date";
    } elsif ( $fld =~ /Intervention_ID/i ) {
       $heading = "ID";
    } elsif ( $fld =~ /Type_ID/i ) {
       $heading = "Type ID";
    } elsif ( $fld =~ /Pharmacy_ID/i ) {
       $heading = "Pharmacy";
    }
    $heading = $fld if (!$heading);
    my $prefix = "IN";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
#--------------------------------------------------

# Now do Intervention Rows Headings

  foreach $fld (@IRFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    if ( $fld =~ /Row_Intervention_Row_ID/i ) {
       $heading = "Row Intervention Row ID";
    } elsif ( $fld =~ /Row_Intervention_ID/i ) {
       $heading = "Intervention ID";
    } elsif ( $fld =~ /Row_CSR_ID/i ) {
       $heading = "CSR ID";
    } elsif ( $fld =~ /Row_CSR_Name/i ) {
       $heading = "CSR Name";
    } elsif ( $fld =~ /^Row_Date_TS$/i ) {
       $heading = "Row Date TS";
    } elsif ( $fld =~ /^Row_Date$/i ) {
       $heading = "Row Date";
    } elsif ( $fld =~ /Row_Comments/i ) {
       $heading = "Row Comments";
    } elsif ( $fld =~ /Row_Attachments/i ) {
       $heading = "Row Attachments";
    }
    $heading = $fld if (!$heading);
    my $prefix = "IR";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
#--------------------------------------------------

# Now do Access Headings

  foreach $fld (@ACFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    my $prefix = "AC";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
#--------------------------------------------------

# Now do ReconRx Incoming Headings

  foreach $fld (@RIFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    my $prefix = "RI";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
#--------------------------------------------------

# Now do ReconRx 835 Remit Headings

  foreach $fld (@R8FIELDS2) {
    ($fld) = &StripJunk($fld);
    print "fld: $fld, heading: $heading, key: $key<br>\n" if ($debug);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "R8";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

# Now do ReconRx 835 Remit Archive Headings

  foreach $fld (@P8FIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "P8";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
   
#--------------------------------------------------

# Now do ReconRx Incomingtb Archive Headings

  foreach $fld (@RAFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "RA";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
#--------------------------------------------------

# Now do ReconRx Exception Routing Headings

  foreach $fld (@REFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "RE";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }
   
#--------------------------------------------------

# Now do Cash Claims Headings

  foreach $fld (@CCFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "CC";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

# Now do PaymentNoRemit_Archive Headings

  foreach $fld (@PAFIELDS2) {
    ($fld) = &StripJunk($fld);
    my $heading = "";
    $heading = $fld if (!$heading);
    $prefix = "PA";
    my $key    = "$prefix" . "##" . "$fld";
    $HEADINGS{"$key"} = "$heading";
    print qq#prefix: $prefix, key: $key, HEADINGS(): $HEADINGS{"$key"}<br>\n# if ($debug);
  }

}

#______________________________________________________________________________

sub displayData {

# my $debug++;
# my $verbose++;

  my ($MODE2, $URL, $dispTab) = @_;
  print "<hr>displayData. Entry. MODE2: $MODE2, URL: $URL, disptab: $disptab<hr>\n" if ($debug);
  my %jTypes   = ();
  my %jTFields = ();
  $ptr = -1;
  $do = 0;
  my %uniqueTF = ();

  if ( $URL !~ /dispTabs/i ) {
       $URL .= "#dispTabs";
  }

  # MODE2: View or Edit
  if ( $debug ) {
     print "<hr>MODE2: $MODE2, MODE: $MODE, URL: $URL, dispTab: $dispTab<br>\n";
     print "<hr>inVNID: $inVNID, dispVNID: $dispVNID<br>\n";
  }

  $newMODE2 = "View";   # after Save hit, return to View mode

  print qq#  <FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="debug"     VALUE="$debug">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="verbose"   VALUE="$verbose">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="db"        VALUE="$dbin">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="opt"       VALUE="$opt">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="sf"        VALUE="$sf">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="SORT"      VALUE="$SORT">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="ACTION"    VALUE="$ACTION">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="SELD"      VALUE="$SELD">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="MODE"      VALUE="$MODE">\n\n#;
  print qq#  <INPUT TYPE="hidden" NAME="MODE2"     VALUE="$newMODE2">\n\n#;

  print qq#  <INPUT TYPE="hidden" NAME="inBIN"     VALUE="$inBIN">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispBIN"   VALUE="$dispBIN">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inNPI"     VALUE="$inNPI">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispNPI"   VALUE="$dispNPI">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inTPPID"   VALUE="$inTPPID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispTPPID" VALUE="$dispTPPID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inAFFID"   VALUE="$inAFFID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispAFFID" VALUE="$dispAFFID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inVNID"    VALUE="$inVNID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispVNID"  VALUE="$dispVNID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inPVID"    VALUE="$inPVID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispPVID"  VALUE="$dispPVID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inPTID"    VALUE="$inPTID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispPTID"  VALUE="$dispPTID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inTBID"    VALUE="$inTBID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispTBID"  VALUE="$dispTBID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inDesc"    VALUE="$inDesc">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispDesc"  VALUE="$dispDesc">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inCompanyID" VALUE="$inCompanyID">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="inCompany"   VALUE="$inCompany">\n#;
  print qq#  <INPUT TYPE="hidden" NAME="dispCompany" VALUE="$dispCompany">\n#;

  foreach $pc (@$FIELDS3) {
    $ptr++;
    my $name = @$FIELDS2[$ptr];
     next if($name =~ /Authorized/);
    ${$name} = $pc || $nbsp;
    next if ( $JTYPE =~ /^CIPN$|^CIPN Direct$|^VacOnly$/i
            && $name =~ /^Accountant|^Compliance|^Invoicing|^Payables|Recon/i );

    next if ( $JTYPE =~ /^ReconRx$|^VacOnly$/i
            && $name =~ /^Credentialing|^Compliance|MACAppeal|PIC/i );
    next if ( $JTYPE =~ /^VacOnly$/i
            && $name =~ /Owner|Secondary|Communication|Remits|Sales\s*Rep/i );
    next if ( $JTYPE !~ /CIPN/i && $name =~ /MACAppeal/i );

    if ( $name =~ /_${dispTab}_/i ) {
       ($type, $rest) = split("_", $name, 2);
       $do = 2;
       $jTypes{$type}   = $ptr;
       $jTFields{$name} = $ptr;
    } elsif ( $name =~ /^${dispTab}_/i ) {
       ($type, $rest) = split("_", $name, 2);
       $do = 1;
       $jTypes{$type}   = $ptr;
       $jTFields{$name} = $ptr;
    }
  }

  if ( $LPERMISSIONLEVEL !~ /View/i ) {
     print qq#<INPUT TYPE="Submit" NAME="inEDIT2" VALUE="Edit Contacts">\n#;
  }

  # print headings
  print qq#<table class="main" border=1 cellpadding=1 cellspacing=1>\n#;
  print qq#<tr><th class="grey" align=left>Type</th>\n#;
  foreach $field (sort { $jTFields{$a} <=> $jTFields{$b} } keys %jTFields) {
     @pcs = split("_", $field);
     shift(@pcs) if ($do > 0);
     shift(@pcs) if ($do > 1);
     $heading = join(" ", @pcs);
     next if ( exists($uniqueTF{$heading}) );

     $uniqueTF{$heading}++;
     print qq#<th align=left class="grey">$heading</th>\n#;
  }
  print "</tr>\n";

  # now print the data lines

  foreach $type ( sort { $jTypes{$a} <=> $jTypes{$b} } keys %jTypes) {
     print "<tr>\n";
     $typeout = $type;
     if ( $typeout =~ /MACAppeal/i ) {
        $typeout =~ s/MACA/MAC A/gi;
     } elsif ( $typeout =~ /Salesrep/i ) {
        $typeout =~ s/Salesrep/Sales Rep/gi;
     }

     print qq#<th class="grey" align=left>$typeout</th>\n#;

     foreach $field (sort { $jTFields{$a} <=> $jTFields{$b} } keys %jTFields) {
        if ( $field =~ /^$type/ ) {
           my $val = $$field;
           $val = "" if ( $field eq $val );
           if ( $MODE2 =~ /Edit/i ) {
              my $fieldname = "UpDB_" . $field;
              # Call routine 
              if ( $field =~ /State/i ) {
                 &dropdown_contacts("$field", @OPTSStates);
              } else {
                if ( $field =~ /ext$|Zip$/i ) {
                   $size =  9;
                } elsif ( $field =~ /Address|Email$/i ) {
                   $size = 22;
                } else {
                   $size = 12;
                }
                $val = $nbsp if ( $val =~ /^\s*$/ );
                print qq#<td class="green"><INPUT TYPE="text" NAME="$fieldname" SIZE=$size VALUE="$val"></td>\n#;
             }
        #
           } else {
             if ( $field =~ /Email/i && $val =~ /\@/ ) {
                my $email = $$field;
#                print "<hr><font color=red>email: $email</font><hr>\n";
                print qq#<td> <A HREF="mailto:$email">$val</A> </td>\n#;
             } else {
                print "<td>$val</td>\n";
             }
           }
        }
     }
     print "</tr>\n";
  }
  $fldcount = keys(%jTypes) + 2;   # +1 for Type column, +1 as total is 0-max...
  if ( $MODE2 =~ /Edit/i ) {
    $submit_string = "Save $dispTab Changes";
    print qq#<tr><th align=center colspan=$fldcount><INPUT style="background-color:\#FF0; padding:5px; margin:5px" TYPE="Submit" NAME="Submit" VALUE="$submit_string"></th></tr>\n#;
  }
  
  print "</FORM>";
}

#______________________________________________________________________________

sub readInterventions {

# my $debug++;
# my $verbose++;
# my $incdebug++;

  my ($Pharmacy, $CSR_ID, $NoTest) = @_;

  print "<hr>sub readInterventions: Entry. Pharmacy: $Pharmacy, CSR_ID: $CSR_ID<br>\n" if ( $incdebug );

  my $dbin    = "INDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $sql;
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = qq#SELECT Intervention_ID, Pharmacy_ID, Type, Type_ID, Category, CSR_ID, CSR_Name, Status, Opened_Date_TS, Opened_Date, Closed_Date_TS, Closed_Date, Last_Touched, Comments, Recon_Success_Story, Recon_Check_Date, Recon_Check_Number, Mac_Approved_Denied, Mac_index, LPAD(Mac_NCPDP,7,"0"), Mac_NPI, Mac_Pharmacy_Name, Mac_Primary_Contact, Mac_Phone, Mac_DOS, Mac_Bin, Mac_Rx_Number, Mac_Member_ID, Mac_Group_Number, Mac_Patient_Fname, Mac_Patient_Lname, Mac_DOB, Mac_PCN, Mac_Quantity, Mac_Claim_Authorization_Number, Mac_Usual_Customary_Price, Mac_Acquisition_Cost, Mac_Patients_Copay, Mac_Paid_TPP, Mac_Total_Reimbursed_To_Pharmacy, Mac_Notes, Mac_TPP_Parent_ID, Mac_TPP_Parent, Mac_Drug_Name, Mac_Drug_Strength, Mac_NDC, Mac_Pharmacy_Filename, Mac_Filename, Attachments, Mac_Paid_Actual, Mac_Manual_Case_Number, Mac_Manual_Date_Called, Mac_Manual_Comments, Mac_Paid, Mac_Charge, Program, PNC_Pharmacy_Name, PNC_NPI, LPAD(PNC_NCPDP,7,"0"), PNC_BIN, PNC_PCN, PNC_Group, PNC_Rx_Number, PNC_DOS, PNC_Member_Name, PNC_DOB, PNC_Member_ID, PNC_Notes FROM $DBNAME.$TABLE #;

  my $ADDIT = " (1=1) ";
  # print "Pharmacy: $Pharmacy<br>\n";
  if ( $Pharmacy && $Pharmacy !~ /^All$/i ) {
     $ADDIT .= qq# && Pharmacy_ID = $Pharmacy#;
  }
  # print "Pharmacy: $Pharmacy<br>\n";
  if ( $CSR_ID && $CSR_ID !~ /^All$/i ) {
     $ADDIT .= qq# && # if ( $ADDIT );
     $ADDIT .= qq# CSR_ID = $CSR_ID#;
  }
  if ( $NoTest ) {
     $ADDIT .= " && (
          (Mac_NCPDP NOT IN (1111111,2222222,3333333,9879879) ||
           PNC_NCPDP NOT IN (1111111,2222222,3333333,9879879) )
     ) ";
  }
  if ( $ADDIT ) {
     $sql .= " WHERE $ADDIT ";
  } 

  print "sql:<br>$sql<br>\n" if ($incdebug);

  $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($incdebug);

  @OPTSIntIDs = ();
  push(@OPTSIntIDs, "ALL");
  while ( my @row = $sthx->fetchrow_array() ) {
     my ($Intervention_ID, $Pharmacy_ID, $Type, $Type_ID, $Category, $CSR_ID, $CSR_Name, $Status, $Opened_Date_TS, $Opened_Date, $Closed_Date_TS, $Closed_Date, $Last_Touched, $Comments, $Recon_Success_Story, $Recon_Check_Date, $Recon_Check_Number, $Mac_Approved_Denied, $Mac_index, $Mac_NCPDP, $Mac_NPI, $Mac_Pharmacy_Name, $Mac_Primary_Contact, $Mac_Phone, $Mac_DOS, $Mac_Bin, $Mac_Rx_Number, $Mac_Member_ID, $Mac_Group_Number, $Mac_Patient_Fname, $Mac_Patient_Lname, $Mac_DOB, $Mac_PCN, $Mac_Quantity, $Mac_Claim_Authorization_Number, $Mac_Usual_Customary_Price, $Mac_Acquisition_Cost, $Mac_Patients_Copay, $Mac_Paid_TPP, $Mac_Total_Reimbursed_To_Pharmacy, $Mac_Notes, $Mac_TPP_Parent_ID, $Mac_TPP_Parent, $Mac_Drug_Name, $Mac_Drug_Strength, $Mac_NDC, $Mac_Pharmacy_Filename, $Mac_Filename, $Attachments, $Mac_Paid_Actual, $Mac_Manual_Case_Number, $Mac_Manual_Date_Called, $Mac_Manual_Comments, $Mac_Paid, $Mac_Charge, $Program, $PNC_Pharmacy_Name, $PNC_NPI, $PNC_NCPDP, $PNC_BIN, $PNC_PCN, $PNC_Group, $PNC_Rx_Number, $PNC_DOS, $PNC_Member_Name, $PNC_DOB, $PNC_Member_ID, $PNC_Notes) = @row;

     $Opened_Date =~ s/\s*00:00:00//g;
     $Closed_Date =~ s/\s*00:00:00//g;

     $key = $Intervention_ID;
     $Intervention_IDs{$key}++;
     if ( $CSR_ID > 0 ) {
            $INTKEYS .= "$Intervention_ID,";
         }

         $Int_Intervention_IDs{$key}   = $Intervention_ID;

         $Int_Pharmacy_ID{$key}           = $Pharmacy_ID;
         $Int_Type{$key}                  = $Type;
         $Int_Type_ID{$key}               = $Type_ID;
         $Int_Category{$key}              = $Category;
         $Int_Program{$key}               = $Program;
         $Int_CSR_ID{$key}                = $CSR_ID;
         $Int_CSR_Name{$key}              = $CSR_Name;
         $Int_Status{$key}                = $Status;
         $Int_Opened_Date_TS{$key}        = $Opened_Date_TS;
         $Int_Opened_Date{$key}           = $Opened_Date;
         $Int_Closed_Date_TS{$key}        = $Closed_Date_TS;
         $Int_Closed_Date{$key}           = $Closed_Date;
         $Int_Last_Touched{$key}          = $Last_Touched;
         $Int_Comments{$key}              = $Comments;
         $Int_Recon_Success_Story{$key}   = $Recon_Success_Story;
         $Int_Recon_Check_Date{$key}      = $Recon_Check_Date;
         $Int_Recon_Check_Number{$key}    = $Recon_Check_Number;
         $Int_Mac_Approved_Denied{$key}   = $Mac_Approved_Denied;
         $Int_Mac_index{$key}             = $Mac_index;
         $Int_Mac_NCPDP{$key}             = $Mac_NCPDP;
         $Int_Mac_NPI{$key}               = $Mac_NPI;
         $Int_Mac_Pharmacy_Name{$key}     = $Mac_Pharmacy_Name;
         $Int_Mac_Primary_Contact{$key}   = $Mac_Primary_Contact;
         $Int_Mac_Phone{$key}             = $Mac_Phone;
         $Int_Mac_DOS{$key}               = $Mac_DOS;
         $Int_Mac_Bin{$key}               = $Mac_Bin;
         $Int_Mac_Rx_Number{$key}         = $Mac_Rx_Number;
         $Int_Mac_Member_ID{$key}         = $Mac_Member_ID;
         $Int_Mac_Group_Number{$key}      = $Mac_Group_Number;
         $Int_Mac_Patient_Fname{$key}     = $Mac_Patient_Fname;
         $Int_Mac_Patient_Lname{$key}     = $Mac_Patient_Lname;
         $Int_Mac_DOB{$key}               = $Mac_DOB;
         $Int_Mac_PCN{$key}               = $Mac_PCN;
         $Int_Mac_Quantity{$key}          = $Mac_Quantity;
         $Int_Mac_Claim_Authorization_Number{$key} = $Mac_Claim_Authorization_Number;
         $Int_Mac_Usual_Customary_Price{$key}      = $Mac_Usual_Customary_Price;
         $Int_Mac_Acquisition_Cost{$key}  = $Mac_Acquisition_Cost;
         $Int_Mac_Patients_Copay{$key}    = $Mac_Patients_Copay;
         $Int_Mac_Paid_TPP{$key}          = $Mac_Paid_TPP;
         $Int_Mac_Total_Reimbursed_To_Pharmacy{$key} = $Mac_Total_Reimbursed_To_Pharmacy;
         $Int_Mac_Notes{$key}             = $Mac_Notes;
         $Int_Mac_TPP_Parent_ID{$key}     = $Mac_TPP_Parent_ID;
         $Int_Mac_TPP_Parent{$key}        = $Mac_TPP_Parent;
         $Int_Mac_Drug_Name{$key}         = $Mac_Drug_Name;
         $Int_Mac_Drug_Strength{$key}     = $Mac_Drug_Strength;
         $Int_Mac_NDC{$key}               = $Mac_NDC;
         $Int_Mac_Pharmacy_Filename{$key} = $Mac_Pharmacy_Filename;
         $Int_Mac_Filename{$key}          = $Mac_Filename;
         $Int_Attachments{$key}           = $Attachments;
         $Int_Mac_Paid_Actual{$key}       = $Mac_Paid_Actual;
         $Int_Mac_Manual_Case_Number{$key}= $Mac_Manual_Case_Number;
         $Int_Mac_Manual_Date_Called{$key}= $Mac_Manual_Date_Called;
         $Int_Mac_Manual_Comments{$key}   = $Mac_Manual_Comments;
         $Int_Mac_Paid{$key}              = $Mac_Paid;
         $Int_Mac_Charge{$key}            = $Mac_Charge;

         $Int_PNC_Pharmacy_Names{$key}    = $PNC_Pharmacy_Name;
         $Int_PNC_NPI{$key}               = $PNC_NPI;
         $Int_PNC_NCPDP{$key}             = $PNC_NCPDP;
         $Int_PNC_BIN{$key}               = $PNC_BIN;
         $Int_PNC_PCN{$key}               = $PNC_PCN;
         $Int_PNC_Group{$key}             = $PNC_Group;
         $Int_PNC_Rx_Number{$key}         = $PNC_Rx_Number;
         $Int_PNC_DOS{$key}               = $PNC_DOS;
         $Int_PNC_Member_Name{$key}       = $PNC_Member_Name;
         $Int_PNC_DOB{$key}               = $PNC_DOB;
         $Int_PNC_Member_ID{$key}         = $PNC_Member_ID;
         $Int_PNC_Notes{$key}             = $PNC_Notes;

         push(@OPTSIntIDs, "$key");

    #    print "sub readInterventions: Intervention_ID: $Intervention_ID<br>\n" if ($incdebug);
      }
      $sthx->finish;
      $dbm->disconnect;

  $INTKEYS =~ s/,\s*$//g;

  print "<hr size=4 color=red noshade>\n" if ($incdebug);

}

#______________________________________________________________________________

sub readIntRows {

# my $debug++;
# my $verbose++;

  print "<hr>sub readIntRows: Entry.<br>\n" if ( $debug );

  my $dbin    = "IRDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $sql;
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  DBI->trace(1) if ($dbitrace);

  $sql = qq#SELECT Row_Intervention_Row_ID, Row_Intervention_ID, Row_CSR_ID, Row_CSR_Name,
                   Row_Date_TS, Row_Date, Row_Comments, Row_Attachments FROM $DBNAME.$TABLE #;
  if ( $INTKEYS ) {
     $sql .= " WHERE Row_Intervention_ID IN ($INTKEYS) ";
  }

  print "sql:<br>$sql<br>\n" if ($debug);

  $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows affected: $NumOfRows<br>\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
    my ($Row_Intervention_Row_ID, $Row_Intervention_ID, $Row_CSR_ID, $Row_CSR_Name, $Row_Date_TS, $Row_Date, $Row_Comments, $Row_Attachments) = @row;

     $key = $Row_Intervention_Row_ID;
     $Row_Intervention_Row_IDs{$key} = $Row_Intervention_Row_ID;
     $Row_Intervention_IDs{$key}     = $Row_Intervention_ID;
     $Row_CSR_IDs{$key}              = $Row_CSR_ID;
     $Row_CSR_Names{$key}            = $Row_CSR_Name;
     $Row_Date_TS{$key}              = $Row_Date_TS;
     $Row_Dates{$key}                = $Row_Date;
     $Row_Comments{$key}             = $Row_Comments;
     $Row_Attachments{$key}          = $Row_Attachments;
#    print "readIntRows key: $key, Row_Intervention_Row_ID: $Row_Intervention_ID<br>\n" if ($debug);

  }
  $sthx->finish;
  $dbm->disconnect;

  print "sub readIntRows. Rows Found: $NumOfRows<br>\n" if ($debug);
  print "<hr size=4 color=red noshade>\n" if ($debug);
}

#______________________________________________________________________________
 
sub MembersLogin {

  my $URL = "/members/index.cgi";
  
  print qq#<FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#<INPUT TYPE="hidden" NAME="debug"   VALUE="$debug">\n#;
  print qq#<INPUT TYPE="hidden" NAME="verbose" VALUE="$verbose">\n#;
  
  print "JJJ: NEWPASS: $NEWPASS, USER: $USER, PASS: $PASS, LFIRSTLOGIN: $LFIRSTLOGIN, $LPERMISSIONLEVEL,<br>CUSTOMERID: $CUSTOMERID<br>\n" if ($debug);
  
  $addtext = "";
  &askforMemberUSERPASS($addtext);
  $dontdoHiddenuserpass++;
  
  if ( !$dontdoHiddenuserpass ) {
    print qq#<INPUT TYPE="hidden" NAME="USER"     VALUE="$USER">\n#;
    print qq#<INPUT TYPE="hidden" NAME="PASS"     VALUE="$PASS">\n#;
    print qq#<INPUT TYPE="hidden" NAME="CUSTOMERID"  VALUE="$CUSTOMERID">\n#;
  }
  print qq#<INPUT TYPE="hidden" NAME="VALID"    VALUE="$VALID">\n#;
  print qq#<INPUT TYPE="hidden" NAME="isAdmin"  VALUE="$isAdmin">\n#;
  print qq#<INPUT TYPE="hidden" NAME="isMember" VALUE="$isMember">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LTYPE"    VALUE="$LTYPE">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LFIRSTLOGIN" VALUE="$LFIRSTLOGIN">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LPERMISSIONLEVEL" VALUE="$LPERMISSIONLEVEL">\n#;
  print "</FORM>\n";
  
}

#______________________________________________________________________________
 
sub askforMemberUSERPASS {

  my ($addtext) = @_;

  print qq#<br>sub askforMemberUSERPASS. Entry. USER: $USER, addtext: $addtext<br>\n# if ($debug);

  print qq#<div id="mainbody-members">\n#;

# print qq#If you are not a member, please contact Name? Email? for more information.<br>\n#;

  print qq#<div id="textarea">\n#;
  
  if ( $addtext ) {
     print qq#<p class="instructions"><strong>$addtext</strong></p>\n#;
  }

  print qq#<h1 class="loginhead">Member Login</h1>\n#;
  print qq#<p class="instructions">\n#;
  print qq#Please enter your User ID and Password\n#;
# print qq#<br>isMember: $isMember, USER: $USER, PASS: $PASS<br>\n# if ($debug);
  print qq#<br>Incorrect User ID and/or Password entered\n# if ( !$isMember && $USER !~ /^\s*$/ && $PASS !~ /^\s*$/ );
  print qq#</p>\n#;

  print qq#<table class="main">\n#;
  print qq#<tr><th align=left>User ID</th><td> <INPUT TYPE="text"     NAME="USER" SIZE=40 MAXLENGTH=60 VALUE="$USER"></td></tr>\n#;
  print qq#<tr><th align=left>Password</th><td><INPUT TYPE="PASSWORD" NAME="PASS" SIZE=40 MAXLENGTH=60 VALUE="$PASS"></td></tr>\n#;
    
  print qq#<tr><th>$nbsp</th><th align=left><INPUT TYPE="Submit" VALUE="Log In"></th></tr>\n#;
  
  print "</TABLE>\n";

  print qq#</div> <!-- end text area -->\n#;
  print qq#  <br clear="all">\n#;

  print qq#</div>\n#;    # end mainbody-members
  print "\nsub askforMemberUSERPASS. Exit.<br>\n" if ($debug);

}

#______________________________________________________________________________
# Pharm AssessRBS screen

sub MembersHeaderBlock {
  my ($ENV) = &What_Env_am_I_in;
  my ($inReports) = @_;
  my $image = 'Outcomes_RBS.png'; 
  my $logo_css = 'small_logo';
  my $www = 'members';
  if ( $ENV =~ /Dev/i ) {
  my $www = 'www';
  }
  &readPharmacies;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-members">\n#;
  print qq#  \n#;

  if ( $USER ) {
    print qq#    <div id="leftcolumn-sidenav">\n#;
    print qq#      <!-- start nav include --> \n#;
  
    #---------------------------------------------------------------------------------------------------------
    if ( ($Pharmacy_Types{$PH_ID} =~ /RBS Direct/i ) && ($Pharmacy_Types{$PH_ID} !~ /RBS$/ && $Pharmacy_Types{$PH_ID} !~ /RBS:/)) {
      $image = 'Outcomes_RBS.png' ;
      $logo_css = 'small_rbsd_logo';
    }

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "/members/home_super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    #---------------------------------------------------------------------------------------------------------
    ##################  Pharm Assess Members Nav Bar ######################
    print qq#      <ul id="nav_members">\n#;

    if ( $TYPE =~ /^ADMIN$/i && !$PH_ID) {
       if ($prog =~ /cred_/i) {
         print qq#   <li><a href="../admin/cred_pharmacy.php?"><strong>Admin</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="../admin/cred_pharmacy.php?">Admin</a></li>\n#;
       }
       if ($prog =~ /enrollments/i) {
         print qq#   <li><a href="/members/Enrollments.cgi?status=pending"><strong>Enrollments</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/members/Enrollments.cgi?status=pending">Enrollments</a></li>\n#;
       }
       print "<hr>";
    }    

#    print "$prog<br>";
    if ( $PH_ID ) {
       $VACPROGONLY = 0;
       $INCRED      = 0;
       if ( $Pharmacy_Types{$PH_ID} =~ /VacOnly/i ) {
          $VACPROGONLY++;
       }
       if ( $Pharmacy_Types{$PH_ID} =~ /Cred/i ) {
          $INCRED++;
       }

       if ( $VACPROGONLY ) {
         if ( $INCRED ) {
           if ($prog =~ /credentialing/i) {
             print qq#      <li><a href="/members/credentialing.cgi"><strong>Credentialing</strong></a></li>\n#;
	   } else {
             print qq#      <li><a href="/members/credentialing.cgi">Credentialing</a></li>\n#;
	   }
         }
         use Date::Calc qw/Delta_Days/;
         my ($y1, $m1, $d1) = split("-", $Pharmacy_Active_Date_VacOnlys{$inNCPDP});
         my @first = ($y1, $m1, $d1);
         my @second = ($syear, $smonth, $sday);
         my $dd = Delta_Days( @first, @second );

         if ( $dd <= 365 ) {
            print qq#      <li><a href="/members/SpecialPrograms.cgi"  >Special Programs</a></li>\n#;
         }

         if ($prog =~ /interventions/i) {
           print qq#      <li><a href="/members/interventions.cgi"><strong>Interventions</strong></a></li>\n#;
         } else {
           print qq#      <li><a href="/members/interventions.cgi">Interventions</a></li>\n#;
	 }
         print qq#      <li><a href="http://www.recon-rx.com" target="_blank">Reconciliation</a></li>\n#;
         print qq#      <li><a href="http://www.CIPNetwork.com/members" >CIPN</a></li>\n#;
       } elsif ( $Pharmacy_Types{$PH_ID} =~ /Special Programs/i ) {
         print qq#      <li><a href="/members/SpecialPrograms.cgi">Special Programs</a></li>\n#;
       } elsif ( $Pharmacy_Types{$PH_ID} !~ /Special Programs/i ) {
         if ($prog =~ /credentialing/i) {
           print qq#      <li><a href="/members/credentialing.cgi"><strong>Credentialing</strong></a></li>\n#;
         } else {
           print qq#      <li><a href="/members/credentialing.cgi">Credentialing</a></li>\n#;
         }
         if ( $Pharmacy_Types{$PH_ID} =~ /Cred/i && $Pharmacy_Types{$PH_ID} =~ /Default Cash/i && $TYPE !~ /RBS/i ) {
           print qq#      <li><a href="/members/SpecialPrograms.cgi">Special Programs</a></li>\n#;
	 }
		 
         if (($Pharmacy_Types{$PH_ID} =~ /RBS/i && $Pharmacy_RBSReporting{$PH_ID} =~ /Yes/i) || ($Pharmacy_Types{$PH_ID} =~ /RBS Direct/i))  {
           if ($prog =~ /rbsreporting/i) {
             print qq#      <li><a href="/members/rbsreporting.cgi"><strong>RBS Reporting</strong></a></li>\n#;
	   } else {
             print qq#      <li><a href="/members/rbsreporting.cgi">RBS Reporting</a></li>\n#;
	   }
         }

	 ## if ($Pharmacy_Types{$PH_ID} =~ /RBS/i && $Pharmacy_Types{$PH_ID} =~ /ReconRx/i && $PH_ID == 11 ) {
	 ##  if ($prog =~ /reconciliation/i) {
	 ##    print qq#      <li><a href="http://www.Recon-Rx.com" target="_blank"><strong>Reconciliation</strong></a></li>\n#;
	 ##  } else {
	 ##    print qq#      <li><a href="http://dev.Recon-Rx.com/cgi-bin/MyReconRx.cgi?PH_ID=$PH_ID&USER=$USER" target="_blank">Reconciliation</a></li>\n#;
	 ##  }
	 ## }

         if ($prog =~ /interventions/i) {
           print qq#      <li><a href="/members/interventions.cgi"><strong>Interventions</strong></a></li>\n#;
         } else {
           print qq#      <li><a href="/members/interventions.cgi">Interventions</a></li>\n#;
	 }

         if ( $Pharmacy_Types{$PH_ID} =~ /RBS Direct/i) {
             if ($prog =~ /thirdpartypayers/i) {
               print qq#      <li><a href="/members/thirdpartypayers_rbsdirect.cgi" ><strong>Third Party Direct Payers</strong></a></li>\n#;
	     } 
             else {
               print qq#      <li><a href="/members/thirdpartypayers_rbsdirect.cgi" >Third Party Direct Payers</a></li>\n#;
	     }
	 }

         if ( $Pharmacy_Types{$PH_ID} =~ /RBS/i || $TYPE =~ /RBS/i) {
           if ($prog =~ /specialprograms/i) {
             print qq#      <li><a href="/members/SpecialPrograms.cgi"  ><strong>Special Programs</strong></a></li>\n#;
           } else {
             print qq#      <li><a href="/members/SpecialPrograms.cgi"  >Special Programs</a></li>\n#;
	   }
         }

	 ## if ( $Pharmacy_Types{$PH_ID} =~ /RBS/i || $TYPE =~ /RBS/i) {
	 ##    if ($prog =~ /HowToWebinars/i) {
	 ##      print qq#      <li><a href="/members/HowToWebinars.cgi"    ><strong>"How To" Webinars</strong></a></li>\n#;  
	 ##    } else {
	 ##      print qq#      <li><a href="/members/HowToWebinars.cgi"    >"How To" Webinars</a></li>\n#;  
	 ##    }
	 ## }
      }
    } else {
       print qq#      <li><a href="/members/RBSReportingWeekly.cgi">Weekly Reports</a></li>\n#;
       print qq#      <li><a href="/members/RBSCombinedMonthly.cgi">Monthly/Quarterly</a></li>\n#;
    }
    #---------------------------------------------------------------------------------------------------------

    print qq#      <li><a href="/members/ContactUs.cgi"        ><i>Contact Us</i></a></li>\n#;
    print qq#      <li><a href="/members/logout.cgi"           >LOGOUT</a></li>\n#;
    print qq#      </ul> \n#;
    print qq#      <!-- end  nav include --> \n#;
    print qq#      <div class="leftcolumn_logo">\n#;
    print qq#        <img class="$logo_css" src="../images/$image" alt="Logo" title="">\n#;
    print qq#      </div><!-- end  left column logo--> \n#;
    print qq#    </div><!-- end  left column --> \n#;
    print qq#  \n#;
  }
  print qq#    <div id="textarea">\n#;
}

sub AreteRxHeaderBlock_old {
  my ($nosidenav) = @_;

  ($ENV) = &What_Env_am_I_in;

  my $dbin     = "PHDBNAME";
  my $db       = $dbin;
  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  my $ctl_table = 'pharmacy_ctl';

   
  $Pharmacy_Name = "";

  $nosidenav = 1 if ($nosidenav !~ /^\s*$/);

  &set_Webinar_or_Testing_DBNames;

  if ( $TYPE =~ /SuperUser|Admin/i && !$PH_ID) {
    $Pharmacy_Name = "Reconciliation";  
  } else {
    $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
           { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
    DBI->trace(1) if ($dbitrace);

    my $sql = "SELECT *, upload835 FROM (
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip, umbrella_policy
                  FROM $DBNAME.$TABLE
	         WHERE Pharmacy_ID = '$PH_ID'
		UNION
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip, umbrella_policy
                  FROM $DBNAME.${TABLE}_coo
	         WHERE Pharmacy_ID = '$PH_ID'
	      
	      ) a
               LEFT JOIN $DBNAME.$ctl_table ON (NCPDP = ctl_id)";

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    my $numofrows = $sthp->rows;

    my @row = $sthp->fetchrow_array();
    ($inNCPDP, $Pharmacy_Name, $Address, $City, $State, $Zip, $ph_upload, $upload) = @row;
    $sthp->finish();

    $DBNAME == 'webinar' if ($PH_ID == 23);
    #### Check for actions needed
    $sql = "SELECT *
              FROM $DBNAME.${TABLE}_action_req
	     WHERE Pharmacy_ID = '$PH_ID'
	       AND program = '$PROGRAM'";

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $action_req = $sthp->rows;
    $sthp->finish();

#    print "Action: $action_req<br>";
    
    # Close the Databases
    $dbp->disconnect;
  }

  ##<img class="main_logo_arete" src="/images/AreteLogowTDS_Top_Header.png" border="0"  alt="Arete Pharmacy Network"  class="logographic"/>
  print qq#<figure class="mbr-figure container">
             <div class="header-block_arete_reduced" >
               <img class="main_logo" src="/images/ReconRX_LogoWTag.png" border="0"  alt="ReconRx"  class="logographic"/>
             </div>
           </figure>\n#;

  print qq#<div id="membersheaderborder"></div>\n#;

  if ( $Pharmacy_Name =~ /^\s*$/ ) {
     # Do nothing
  } elsif ( $Pharmacy_Name =~ /Reconciliation/i ) {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">user: $LOGIN</div>#;
    print qq#</div>#;
  } else {
    print qq#<div class="header_info_arete">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">ncpdp: $inNCPDP</div>#;
    print qq#</div>#;
  }
  if ( $WHICHDB =~ /^LIVE$/i ) {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  } else {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  }
  print qq#  <div style="clear: both;"></div>#;
#  print qq#  </div><!-- end reconheader -->\n#;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-recon">\n#;

  if ( !$nosidenav ) {

  ##################  Recon-Rx Nav Bar ######################

    print qq#  <div id="leftcolumn-sidenav">\n#;

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "MyArete_Super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="hidden" NAME="Mode"    VALUE="Super">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    print qq#    <ul>\n#;
    if ( $TYPE =~ /^ADMIN$/i && $Pharmacy_Name =~ /Reconciliation|^\s*$/i ) {
       if ($prog =~ /ADMIN/i) {
         print qq#   <li><a href="ADMIN_menu.cgi"><strong>ADMIN</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="ADMIN_menu.cgi">ADMIN</a></li>\n#;
       }

       if ($prog =~ /Intervention_Dashboard/i) {
         print qq#   <li><a href="Intervention_Dashboard.cgi"><strong>Interventions</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Intervention_Dashboard.cgi">Interventions</a></li>\n#;
       }

       if ($prog =~ /enrollments/i) {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete"><strong>Enrollments</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete">Enrollments</a></li>\n#;
       }
       if ($prog =~ /ThirdPartyPayers/i) {
         print qq#   <li><a href="/cgi-bin/ThirdPartyPayersList.cgi"><strong>Third Party Payers List</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/cgi-bin/ThirdPartyPayersList.cgi">Third Party Payers List</a></li>\n#;
       }
    }

    if ( $Pharmacy_Name && $Pharmacy_Name !~ /Reconciliation/i && $USER !~ /^\s*$/ ) {
       if ($prog =~ /MyReconRx/i) {
         print qq#   <li><a href="MyReconRx.cgi"><strong>Dashboard</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="MyReconRx.cgi">Dashboard</a></li>\n#;
       }	 
       if ($prog =~ /Review_My_Aging/i) {
         print qq#   <li><a href="Review_My_Aging.cgi"><strong>Review My Aging</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Review_My_Aging.cgi">Review My Aging</a></li>\n#;
       }
       if ($prog =~ /Post_Payment_to_Remits/i) {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi"><strong>Post Payment<br>to Remits</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi">Post Payment<br>to Remits</a></li>\n#;
       }
       if ($prog =~ /Post_Check_with_No_Remit/i) {
         print qq#   <li><a href="Post_Check_with_No_Remit.cgi"><strong>Post Check<br>with No Remit</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Post_Check_with_No_Remit.cgi">Post Check<br>with No Remit</a></li>\n#;
       }
       if ($prog =~ /Reconciled_Detail_Remittance/i) {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi"><strong>Reconciled Detail<br>Remittance</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi">Reconciled Detail<br>Remittance</a></li>\n#;
       }

       if ( $ph_upload =~ /Yes/i ) {
         if ($prog=~ /Upload835/i) {
           print qq#   <li><a href="Upload835.cgi"><span style="font-weight: bold; color: red;">Remittance Upload</span></a></li>\n#;
         } else {
           print qq#   <li><a href="Upload835.cgi">Remittance Upload</a></li>\n#;
         }
       }

       if ( $action_req ) {
         if ($prog=~ /Action Required/i) {
           print qq#   <li><a href="Action_Required.cgi"><span style="font-weight: bold; color: red;">Action Required</span></a></li>\n#;
         } else {
           print qq#   <li><a href="Action_Required.cgi"><span style="color: red;">Action Required</span></a></li>\n#;
         }
       }

       if ($prog =~ /Interventions/i) {
         print qq#   <li><a href="Interventions.cgi"><strong>Interventions</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Interventions.cgi">Interventions</a></li>\n#;
       }
       if ($prog =~ /^Search$/i) {
         print qq#   <li><a href="Search.cgi"><strong>Detailed Search</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Search.cgi">Detailed Search</a></li>\n#;
       }
      if ($prog =~ /Reports/i) {
        print qq#      <li><a href="Report_Menu.cgi"><strong>Reports</strong></a></li>\n#;
      } else {
        print qq#      <li><a href="Report_Menu.cgi">Reports</a></li>\n#;
      }
       if ( $Pharmacy_Arete{$PH_ID} eq 'B') {
         if ($prog =~ /ADMIN|Research_Tool/i) {
           print qq#   <li><a href="ADMIN_menu_Arete.cgi"><strong>Research Tools</strong></a></li>\n#;
         } else {
           print qq#   <li><a href="ADMIN_menu_Arete.cgi">Research Tools</a></li>\n#;
         }
       }
       if ($prog =~ /Upload835/i) {
	       ##    print qq#   <li><a href="Upload835.cgi"><strong>Upload 835</strong></a></li>\n# if($upload);
       } else {
	       ##  print qq#   <li><a href="Upload835.cgi">Upload 835</a></li>\n# if($upload);
       }
       if ($prog =~ /Success_Stories/i) {
         print qq#   <li><a href="Success_Stories.cgi"><strong>Success Stories</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Success_Stories.cgi">Success Stories</a></li>\n#;
       }
       if ($prog =~ /Vendors/i) {
         print qq#   <li><a href="Vendors.cgi"><strong>Vendors</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Vendors.cgi">Vendors</a></li>\n#;
       }
       if ($prog =~ /Broadcast_Communications/i) {
         print qq#   <li><a href="Broadcast_Communications.cgi"><strong>Broadcast<br>Communications</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Broadcast_Communications.cgi">Broadcast<br>Communications</a></li>\n#;
       }
       if ($prog =~ /Third_Party_Payers/i) {
         print qq#   <li><a href="Third_Party_Payers.cgi"><strong>Third Party Payers</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Third_Party_Payers.cgi">Third Party Payers</a></li>\n#;
       }
       if ($prog =~ /Web_Training/i) {
         print qq#   <li><a href="Web_Training.cgi"><strong>Web Training<br>Session</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Web_Training.cgi">Web Training<br>Session</a></li>\n#;
       }
    }
    if ($prog =~ /Contact_Us/i) {
      print qq#      <li><a href="Contact_Us.cgi"><i>Contact Us</i></a></li>\n#;
    } else {
      print qq#      <li><a href="Contact_Us.cgi"><i>Contact Us</i></a></li>\n#;
    }
    print qq#      <li><a href="Logout.cgi">Log Out</a></li>\n#;

    print qq#    </ul>\n#;
    print qq#      <div class="leftcolumn_logo">\n#;
    print qq#        <img class="small_logo" src="../images/ReconRX_Logo_Grey_bg.png" alt="Logo" title="">\n#;
    print qq#      </div><!-- end  left column logo--> \n#;
    print qq#  </div><!-- end leftcolumn-sidenav -->\n#; 
  }
  
  print qq#  <div id="textarea">\n#;
}

sub ReconRxAggregatedHeaderBlock {
  my ($nosidenav) = @_;

  ($ENV) = &What_Env_am_I_in;

  my $dbin     = "PHDBNAME";
  my $db       = $dbin;
  my $DBNAME   = $DBNAMES{"$dbin"};
  my $TABLE    = $DBTABN{"$dbin"};
  my $ctl_table = 'pharmacy_ctl';
  &readPharmacies;
   
  $Pharmacy_Name = "";

  $nosidenav = 1 if ($nosidenav !~ /^\s*$/);

  &set_Webinar_or_Testing_DBNames;

  if ( $TYPE =~ /SuperUser|Admin/i && !$PH_ID) {
    $Pharmacy_Name = "Reconciliation";  
  } 

  print qq#<figure class="mbr-figure container">
             <div class="header-block" >
               <img class="main_logo" src="/images/ReconRX_LogoWTag.png" border="0"  alt="ReconRx"  class="logographic"/>
             </div>
           </figure>\n#;

  print qq#<div id="membersheaderborder"></div>\n#;

  if ( $Pharmacy_Name =~ /^\s*$/ ) {
     # Do nothing
  } elsif ( $Pharmacy_Name =~ /Reconciliation/i ) {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">user: $LOGIN</div>#;
    print qq#</div>#;
  } else {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">ncpdp: $inNCPDP</div>#;
    print qq#</div>#;
  }
  if ( $WHICHDB =~ /^LIVE$/i ) {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  } else {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  }
  print qq#  <div style="clear: both;"></div>#;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-recon">\n#;

  if ( !$nosidenav ) {

  ##################  Recon-Rx Nav Bar ######################

    print qq#  <div id="leftcolumn-sidenav">\n#;

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "MyReconRx_Super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="hidden" NAME="Mode"    VALUE="Super">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    print qq#    <ul>\n#;
    if ( $TYPE =~ /^ADMIN$/i && $Pharmacy_Name =~ /Reconciliation|^\s*$/i ) {
       if ($prog =~ /ADMIN/i) {
         print qq#   <li><a href="ADMIN_menu.cgi"><strong>ADMIN</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="ADMIN_menu.cgi">ADMIN</a></li>\n#;
       }

       if ($prog =~ /enrollments/i) {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete"><strong>Enrollments</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete">Enrollments</a></li>\n#;
       }
    }

    if ( $PH_ID =~ /Aggregated/i && $USER !~ /^\s*$/ ) {
       if ($prog =~ /MyReconRx/i) {
         print qq#   <li><a href="MyReconRx.cgi"><strong>Dashboard</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="MyReconRx.cgi">Dashboard</a></li>\n#;
       }	 
       if ($prog =~ /Review_My_Aging/i) {
         print qq#   <li><a href="Review_My_Aging.cgi"><strong>Review My Aging</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Review_My_Aging.cgi">Review My Aging</a></li>\n#;
       }
       if ($prog =~ /Post_Payment_to_Remits/i) {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi"><strong>Post Payment<br>to Remits</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi">Post Payment<br>to Remits</a></li>\n#;
       }
       if ($prog =~ /Reconciled_Detail_Remittance/i) {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi"><strong>Reconciled Detail<br>Remittance</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi">Reconciled Detail<br>Remittance</a></li>\n#;
       }

       if ($prog =~ /^Search$/i) {
         print qq#   <li><a href="Search.cgi"><strong>Detailed Search</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Search.cgi">Detailed Search</a></li>\n#;
       }
       if ($prog =~ /Reports/i) {
         print qq#      <li><a href="Report_Menu_All.cgi"><strong>Reports</strong></a></li>\n#;
       } else {
         print qq#      <li><a href="Report_Menu_All.cgi">Reports</a></li>\n#;
       }

       if ($prog =~ /Success_Stories/i) {
         print qq#   <li><a href="Success_Stories.cgi"><strong>Success Stories</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Success_Stories.cgi">Success Stories</a></li>\n#;
       }
    }
    if ($prog =~ /Contact_Us/i) {
      print qq#      <li><a href="Contact_Us.cgi"><i>Contact Us</i></a></li>\n#;
    } else {
      print qq#      <li><a href="Contact_Us.cgi"><i>Contact Us</i></a></li>\n#;
    }
    print qq#      <li><a href="Logout.cgi">Log Out</a></li>\n#;

    print qq#    </ul>\n#;
    print qq#      <div class="leftcolumn_logo">\n#;
    print qq#        <img class="small_logo" src="../images/Outcomes_ReconRx.png" alt="Logo" title="">\n#;
    print qq#      </div><!-- end  left column logo--> \n#;
    print qq#  </div><!-- end leftcolumn-sidenav -->\n#; 
  }
  
  print qq#  <div id="textarea">\n#;
}

sub ReconRxAggregatedHeaderBlock_New {
  
  my ($nosidenav) = @_;
  my ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
  $year  += 1900;    # reported as "years since 1900".
  $tmpmonth  = $month;
  $tmpmonth  = 12 if ($tmpmonth == 0);
  $tmpmonth2 = $tmpmonth -1;
  $tmpmonth2 = 12 if($tmpmonth2 ==0); 
  $dispmonth  = $FMONTHS{$tmpmonth};
  $dispmonth2 = $FMONTHS{$tmpmonth2};

  ($ENV) = &What_Env_am_I_in;

  my $db_office      = 'officedb';
  my $tbl_pharmacy   = 'pharmacy';
  my $ctl_table      = 'pharmacy_ctl';
  my $Dashboard      = 'Dashboard';
  my $ReviewMyAging  = 'Review My Aging';
  my $PostPayment    = 'Post Payment<br>to Remit';
  my $PostCheck      = 'Post Payment<br>with No Remit';
  my $Reconcile      = 'Reconciled Detail<br>Remittance';
  my $Interventions  = 'Interventions';
  my $DetailedSearch = 'Detailed Search';
  my $Reports        = 'Reports';
  my $SuccessStories = 'Success Stories';
  my $SpecialProgram = 'Business Tools';
  my $Vendors        = 'Vendors';
  my $Broadcast      = 'Broadcast<br>Communications';
  my $TPP            = 'Third Party Payers';
  my $WebTraining    = 'Web Training Session';
  my $ContactUs      = 'Contact Us';
  my $LogOut         = 'Log Out';
  my $TPPList        = 'Third Party<br>Payers List';
  my $fileyear = $year - 1;
  my $EOYFName;
  my $EOYACFName;
  my $webpathRec;
  my $webpathAC;
  my $newmenu;


  
  &readPharmacies;
  &setmenupgm;
  &login_rpt_ctl;


  $NCPDP = $Pharmacy_NCPDPs{$PH_ID};
  $EOYACFName = "ReconRx_End_of_Fiscal_Year_Accounts_Receivable_${USER}_Aggregated_$fileyear.xlsx";
  $EOYFName   = "ReconRx_End_of_Fiscal_Year_Reconciled_Claims_Summary_${USER}_Aggregated_$fileyear.xlsx";
  my $outdir    = qq#D:\\WWW\\members.recon-rx.com\\WebShare#;
  $webpathRec = "$outdir\\End_of_Fiscal_Year_Reconciled_Claims\\Aggregated\\$EOYFName";
  $webpathAC  = "$outdir\\End_of_Fiscal_Year$testing\\Aggregated\\$EOYACFName";
  
  &readCSRs() if ( scalar keys %CSR_Reverse_ID_Lookup == 0 );
   
  $Pharmacy_Name = "";

  $nosidenav = 1 if ($nosidenav !~ /^\s*$/);

  &set_Webinar_or_Testing_DBNames;

  print qq#<figure class="mbr-figure container">
             <div class="header-block" >
               <img class="main_logo" src="/images/Outcomes_ReconRx.png" border="0"  alt="ReconRx"  class="logographic"/>
             </div>
           </figure>\n#;

  print qq#<div id="membersheaderborder"></div>\n#;

  if ( $Pharmacy_Name =~ /^\s*$/ ) {
     # Do nothing
  } elsif ( $Pharmacy_Name =~ /Reconciliation/i ) {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">user: $LOGIN</div>#;
    print qq#</div>#;
  } else {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">ncpdp: $inNCPDP</div>#;
    print qq#</div>#;
  }
  if ( $WHICHDB =~ /^LIVE$/i ) {
	  ##print qq#<h2 class="demo">$WHICHDB</h2>\n#;
          &displayMenuOption if($PH_ID > 1 );
  } else {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  }
  print qq#  <div style="clear: both;"></div>#;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-recon">\n#;

  if ( !$nosidenav ) {

  ##################  Recon-Rx Nav Bar ######################

    print qq#  <div id="leftcolumn-sidenav">\n#;

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "MyReconRx_Super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="hidden" NAME="Mode"    VALUE="Super">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    print ' 
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link rel="stylesheet" href="/css/jquery-ui.css">
      <script src="https://code.jquery.com/ui/1.13.1/jquery-ui.js"></script>
      <script>
      $( function() {
        $( "#menu" ).menu();
      } );
      </script>
      <style>
      .ui-menu {width: 196px; background: #f2f2f2;}
      </style>
    ';

    print qq# <ul id="menu">#;
   
    # if ( $Pharmacy_Name && $Pharmacy_Name !~ /Reconciliation/i && $USER !~ /^\s*$/ ) {
      print qq# <li><div><a href="MyReconRx.cgi">$pgm{Dashboard} $Dashboard $pgm2{Dashboard}</a></div> \n#;
      print qq# <li><div><a href="Review_My_Aging.cgi">$pgm{RMA} $ReviewMyAging $pgm2{RMA}</a></div> \n#;
      print qq# <li><div><a href="Post_Payment_to_Remits.cgi">$pgm{PPTR} $PostPayment $pgm2{PPTR}</a></div> \n#;
      print qq# <li><div><a href="Success_Stories.cgi">$pgm{SS} $SuccessStories $pgm2{SS}</a></div> \n#;
      
	  # Report Menu Begin
      print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{ReportsAll} Reports $pgm2{ReportsAll}</a></div> \n#;	  
      print qq# <ul class="MenuUL"> \n#;
	  
	  print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{AcctsRec} Accounts Receivable $pgm2{AcctsRec}</a></div> \n#;
	  print qq# <ul class="MenuUL"> \n#;
	  print qq# <li><div><a href="Review_My_Accounts_Receivable_Monthly.cgi">$pgm{RMAM} End of Month $pgm2{RMAM}</a></div></li> \n#;
	  print qq# <li><div><a href="Review_My_Accounts_Receivable_Yearly.cgi"> $pgm{RMAY} End of Year  $pgm2{RMAY}</a></div></li> \n#;
          
      print qq# </ul> \n#;
	  
	  print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{RMRC} Reconciled Claims $pgm2{RMRC}</a></div> \n#;
	  print qq# <ul class="MenuUL"> \n#;
	  print qq# <li><div><a href="Review_My_Reconciled_Claims_Monthly.cgi">$pgm{RMRC}End of Month$pgm2{RMRC}</a></div></li> \n#;
	  ## print qq# <li><div><a href="Review_My_Reconciled_Claims_Quarterly.cgi">$pgm{RMRCQ}Quarterly$pgm2{RMRCQ}</a></div></li> \n#;
	  print qq# <li><div><a href="Review_My_Reconciled_Claims_Yearly.cgi">End of Year</a></div></li> \n#;
	  print qq# <li><div><a href="YTD_Reconciled_Claims_Summary.cgi">$pgm{YTDRC}Year to Date$pgm2{YTDRC}</a></div></li> \n#;
	  #print qq# <li><div><a href="Review_My_PLB_Monthly_Aggregated.cgi">Monthly PLB Aggregated</a></div></li> \n#;
	  print qq# <li><div><a href="Reconciled_Detail_Remittance.cgi">$pgm{RDR}Remittance Detail$pgm2{RDR}</a></div></li> \n#;
      print qq# </ul> \n#;
	  
        print qq# <li><div><a href="M3P.cgi">$pgm{M3P} M3P $pgm2{M3P}</a></div> \n#;
        print qq# <li><div><a href="NRID.cgi">$pgm{NRID} NRID $pgm2{NRID}</a></div> \n# if($nrid_rpt{$USER});
        print qq# <li><div><a href="Copay_Menu_All.cgi">$pgm{COPAY} COPAY $pgm2{COPAY}</a></div> \n# if($copay_rpt{$USER});
	  
      print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{TotalSales} Total Sales $pgm2{TotalSales}</a></div> \n#;
      print qq# <ul class="MenuUL"> \n#;
      print qq# <li><div><a href="Total_Sales_Report_Aggregated.cgi">$pgm{TSAM} End Of Month $pgm2{TSAM}</a></div></li> \n#;
      ## print qq# <li><div><a href="Total_Sales_Report_Aggregated_Quarterly.cgi">$pgm{TSAQ} End Of Quarter $pgm2{TSAQ}</a></div></li> \n#;
      print qq# </ul> \n#;
	  print qq# </li> \n#;
	  # Report Menu End
	  ###################################
	  
      print qq# </ul> \n#;
      print qq# </li> \n#;
      print qq# <li><div><a href="Tools_Menu.cgi">$pgm{Tools} Tools $pgm2{Tools}</a></div> #;
      print qq# <ul class="MenuUL"> \n#;
      print qq#   <li><div><a href="Search.cgi">$pgm{Search}$DetailedSearch$pgm2{Search}</a></div></li> \n#;

      if ( $Pharmacy_Arete{$PH_ID} eq 'B') {
        print qq# <li><div><a href="ADMIN_menu_Arete.cgi">$pgm{Research}Research$pgm2{Research}</a></div> \n#;
        print qq# <ul class="MenuUL"> \n#;
        print qq# <li><div><a href="Basic_Claim_Research_Tool.cgi">$pgm{BscClm}Claim Research$pgm2{BscClm}</a></div></li> \n#;
        print qq# <li><div><a href="Basic_Payment_Research_Tool.cgi">$pgm{BscPmt}Payment Research$pgm2{BscPmt}</a></div></li> \n#;
        print qq# </ul> \n#;
        print qq# </li> \n#;
      }
      if ( $ph_upload =~ /Yes/i ) {
        print qq#   <li><div><a href="EOBConverter.cgi">$pgm{EOB} EOB Converter$pgm2{EOB}</a></div></li> \n#;
      }
      if ( $upload =~ /Yes/i ) {
        print qq#   <li><div><a href="Upload835.cgi">$pgm{Up835}Remittance Upload$pgm2{Up835}</a></div></li> \n#;
      }
      print qq# <li><div><a href="Web_Training.cgi">$pgm{WebT}ReconRx Demo$pgm2{WebT}</a></div></li> \n#;
      #print qq# <li><div><a href="Bulk_835_Download.cgi">$pgm{Bulk835}Weekly 835 Download$pgm2{Bulk835}</a></div></li> \n#;
      #print qq# <li><div><a href="EFT.cgi">$pgm{EFT}EFT Request$pgm2{EFT}</a></div></li> \n#;
      #######################################
      print qq# </ul> \n#;
      print qq# </li> \n#;
  
    print qq# <li><div><a href="Contact_Us.cgi">$pgm{Contact} $ContactUs $pgm2{Contact}</a></div> \n#;
    print qq# <li><a href="Logout.cgi">$LogOut</a></li>\n#;

    print qq# </ul>\n#;
    print qq# <div class="leftcolumn_logo">\n#;
    print qq# <img class="small_logo" src="../images/Outcomes_ReconRx.png" alt="Logo" title="">\n#;
    print qq# </div><!-- end  left column logo--> \n#;
    print qq# </div><!-- end leftcolumn-sidenav -->\n#; 
  }
  print qq# <div id="textarea">\n#;
}	

sub setmenupgm {
  $strong         = '<strong>';
  $strong2        = '</strong>';
  $prg  = '';
  $prg2 = '';
  $prg3 = '';

  $prg = 'Admin'           if ($prog =~ /ADMIN/i);
  $prg = 'Dashboard'       if ($prog =~ /MyReconRx/i);
  $prg = 'RmbTrk'          if ($prog =~ /ReimbursementTracking/i);
  $prg = 'ReportsAll'      if ($prog =~ /Report_Menu_All/i);
  $prg = 'ReportsAll'      if ($prog =~ /Total_Sales_Report_/i);
  $prg = 'ReportsAll'      if ($prog =~ /TotalSalesRpt_/i);
  $prg = 'ReportsAll'      if ($prog =~ /M3P/i);
  $prg = 'ReportsAll'      if ($prog =~ /Review_My_/i);
  $prg = 'RMA'             if ($prog =~ /Review_My_Aging/i);
  $prg = 'ReportsAll'      if ($prog =~ /Reconciled_Detail_Remittance/i);
  $prg = 'ReportsAll'      if ($prog =~ /BusinessTools/i);
  $prg = 'ReportsAll'      if ($prog =~ /MedSync/i);
  $prg = 'ReportsAll'      if ($prog =~ /Inventory_Rpt/i);
  $prg = 'ReportsAll'      if ($prog =~ /PSP/i);
  $prg = 'ReportsAll'      if ($prog =~ /NRID/i);
  $prg = 'ReportsAll'      if ($prog =~ /COPAY/i);
  $prg = 'PPTR'            if ($prog =~ /Post_Payment_to_Remits/i);
  $prg = 'PPNR'            if ($prog =~ /Post_Check_with_No_Remit/i);
  $prg = 'SS'              if ($prog =~ /Success_Stories/i);
  $prg = 'Int'             if ($prog =~ /Interventions/i);
  $prg = 'Tools'           if ($prog =~ /Tools_Menu/i);
  $prg = 'Tools'           if ($prog =~ /Search/i);
  $prg = 'Tools'           if ($prog =~ /EOBConverter/i);
  $prg = 'Tools'           if ($prog =~ /Bulk_835/i);
  $prg = 'Tools'           if ($prog =~ /Upload835/i);
  $prg = 'Tools'           if ($prog =~ /Web_Training/i);
  $prg = 'Tools'           if ($prog =~ /EFT/i);
  $prg = 'Tools'           if ($prog =~ /ADMIN_menu_Arete/i);
  $prg = 'Messenger'       if ($prog =~ /Messenger/i);
  $prg = 'Contact'         if ($prog =~ /Contact_Us/i);
  $prg = 'Enroll'          if ($prog =~ /Enrollments/i);
  $prg = 'TPPList'         if ($prog =~ /ThirdPartyPayersList/i);
  ##  print "$prog....$prg";

  $pgm{$prg}  = $strong; 
  $pgm2{$prg} = $strong2; 

  ####2nd Tier Menu####
  #
  #
  ##  $prg2 = 'TotalSales' if ($prog =~ /QTR_TotalSalesRpt_/i);
  ##$prg2 = 'DirFee'     if ($prog =~ /Report_Menu_All/i);
  ##  $prg2 = 'RMA'        if ($prog =~ /Review_My_Aging_Monthly/i);
  #
  $prg2 = 'TotalSales' if ($prog =~ /Total_Sales_Report_/i);
  $prg2 = 'TotalSales' if ($prog =~ /TotalSalesRpt_/i);
  $prg2 = 'AcctsRec'   if ($prog =~ /Review_My_Accounts_Receivable_/i);
  $prg2 = 'AcctsRec'   if ($prog =~ /Review_My_Aging_Detailed/i);
  $prg2 = 'RecClaims'  if ($prog =~ /Review_My_Reconciled_Claims_/i);
  $prg2 = 'RecClaims'  if ($prog =~ /Reconciled_Detail_Remittance/i);
  $prg2 = 'RecClaims'  if ($prog =~ /YTD_Reconciled_Claims_Summary/i);
  ##  $prg2 = 'RecClaims'  if ($prog =~ /Review_My_Reconciled_Claims_Quarterly/i);
  $prg2 = 'Search'     if ($prog =~ /^Search/i);
  $prg2 = 'EOB'        if ($prog =~ /EOBConverter/i);
  $prg2 = 'Up835'      if ($prog =~ /Upload835/i);
  $prg2 = 'WebT'       if ($prog =~ /Web_Training/i);
  $prg2 = 'Bulk835'    if ($prog =~ /Bulk_835/i);
  $prg2 = 'EFT'        if ($prog =~ /EFT/i);
  $prg2 = 'Business'   if ($prog =~ /BusinessTools/i);
  $prg2 = 'Business'   if ($prog =~ /MedSync/i);
  $prg2 = 'Business'   if ($prog =~ /Inventory_Rpt/i);
  $prg2 = 'Business'   if ($prog =~ /PSP/i);
  $prg2 = 'Research'   if ($prog =~ /ADMIN_menu_Arete/i);
  $prg2 = 'Research'   if ($prog =~ /Basic_Claim/i);
  $prg2 = 'Research'   if ($prog =~ /Basic_Payment/i);
  $prg2 = 'M3P'        if ($prog =~ /M3P/i);
  $prg2 = 'NRID'       if ($prog =~ /NRID/i);
  $prg2 = 'COPAY'      if ($prog =~ /COPAY/i);

  if ($prg2) {
    $pgm{$prg2}  = $strong; 
    $pgm2{$prg2} = $strong2; 
  }

  ####3rd Tier Menu####
  #
  $prg3 = 'Summary' if ($prog =~ /TotalSalesRpt_Summary/i);
  $prg3 = 'Detail'  if ($prog =~ /TotalSalesRpt_Dtl/i);
  $prg3 = 'MedSync' if ($prog =~ /MedSync/i);
  $prg3 = 'InvRpt'  if ($prog =~ /Inventory_Rpt/i);
  $prg3 = 'PSP'     if ($prog =~ /PSP/i);
  $prg3 = 'BscClm'  if ($prog =~ /Basic_Claim/i);
  $prg3 = 'BscPmt'  if ($prog =~ /Basic_Payment/i);
  $prg3 = 'RMAM'    if ($prog =~ /Accounts_Receivable_Monthly/i);
  $prg3 = 'RMAY'    if ($prog =~ /Accounts_Receivable_Yearly/i);
  ##  $prg3 = 'RMRCQ'   if ($prog =~ /_Reconciled_Claims_Quarterly/i);
  $prg3 = 'RMRC'    if ($prog =~ /_Reconciled_Claims_Monthly/i);
  $prg3 = 'RMRCY'   if ($prog =~ /_Reconciled_Claims_Yearly/i);
  $prg3 = 'RMAD'    if ($prog =~ /Review_My_Aging_Detailed/i);
  $prg3 = 'TSAM'    if ($prog =~ /Sales_Report_Aggregated/i);
  $prg3 = 'TSAQ'    if ($prog =~ /Sales_Report_Aggregated_Quarterly/i);
  $prg3 = 'YTDRC'   if ($prog =~ /YTD_Reconciled_Claims_Summary/i);
  $prg3 = 'RDR'     if ($prog =~ /Reconciled_Detail_Remittance/i);

  if ($prg3) {
    $pgm{$prg3}  = $strong; 
    $pgm2{$prg3} = $strong2; 
  }
}

sub ReconRxHeaderBlock_NewMenu {

  my ($nosidenav) = @_;
  my ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
  $year  += 1900;    # reported as "years since 1900".
  $tmpmonth  = $month;
  $tmpmonth  = 12 if ($tmpmonth == 0);
  $tmpmonth2 = $tmpmonth -1;
  $tmpmonth2 = 12 if($tmpmonth2 ==0); 
  $dispmonth  = $FMONTHS{$tmpmonth};
  $dispmonth2 = $FMONTHS{$tmpmonth2};

  ($ENV) = &What_Env_am_I_in;

  my $db_office      = 'officedb';
  my $tbl_pharmacy   = 'pharmacy';
  my $ctl_table      = 'pharmacy_ctl';
  my $Dashboard      = 'Dashboard';
  my $ReviewMyAging  = 'Review My Aging';
  my $PostPayment    = 'Post Payment<br>to Remit';
  my $PostCheck      = 'Post Payment<br>with No Remit';
  my $Reconcile      = 'Reconciled Detail<br>Remittance';
  my $Interventions  = 'Interventions';
  my $DetailedSearch = 'Detailed Search';
  my $Reports        = 'Reports';
  my $SuccessStories = 'Success Stories';
  my $SpecialProgram = 'Business Tools';
  my $Vendors        = 'Vendors';
  my $Broadcast      = 'Broadcast<br>Communications';
  my $TPP            = 'Third Party Payers';
  my $WebTraining    = 'Web Training Session';
  my $ContactUs      = 'Contact Us';
  my $LogOut         = 'Log Out';
  my $TPPList        = 'Third Party<br>Payers List';
  my $fileyear = $year - 1;
  my $EOYFName;
  my $EOYACFName;
  my $webpathRec;
  my $webpathAC;
  my $newmenu;


  
  &readPharmacies;
  &setmenupgm;

  $NCPDP = $Pharmacy_NCPDPs{$PH_ID};
  $EOYACFName = "ReconRx_End_of_Fiscal_Year_Accounts_Receivable_${NCPDP}_${PH_ID}_$fileyear.xlsx";
  $EOYFName   = "ReconRx_End_of_Fiscal_Year_Reconciled_Claims_Summary_${NCPDP}_${PH_ID}_$fileyear.xlsx";
  $ReimTrkng  = "ReimbursementTracking_${NCPDP}_${PH_ID}_$dispmonth.xlsx";
  $ReimTrkng2 = "ReimbursementTracking_${NCPDP}_${PH_ID}_$dispmonth2.xlsx";
  my $outdir    = qq#D:\\WWW\\members.recon-rx.com\\WebShare\\#;
  $webpathRec = "$outdir\\End_of_Fiscal_Year_Reconciled_Claims$Agg\\$EOYFName";
  $webpathAC  = "$outdir\\End_of_Fiscal_Year$testing\\$EOYACFName";
  $webpathRT  = "$outdir\\ReimbursementTracking\\$ReimTrkng";
  $webpathRT2 = "$outdir\\ReimbursementTracking\\$ReimTrkng2";
  
  
  &readCSRs() if ( scalar keys %CSR_Reverse_ID_Lookup == 0 );
   
  $Pharmacy_Name = "";

  $nosidenav = 1 if ($nosidenav !~ /^\s*$/);

  &set_Webinar_or_Testing_DBNames;

  $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
         { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  if ( $TYPE =~ /SuperUser|Admin/i && !$PH_ID) {
    $Pharmacy_Name = "Reconciliation";  
  } else {
   $PH_ID = 0 if(!$PH_ID);
    my $sql = "SELECT a.*, EOBConversion, upload835 FROM (
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip 
                  FROM $db_office.$tbl_pharmacy
	         WHERE Pharmacy_ID = '$PH_ID'
		UNION
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip 
                  FROM $db_office.${tbl_pharmacy}_coo
	         WHERE Pharmacy_ID = '$PH_ID'
	      
	      ) a
               LEFT JOIN $db_office.$ctl_table ON ($PH_ID = pharmacyid)";

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    my $numofrows = $sthp->rows;

    my @row = $sthp->fetchrow_array();
    ($inNCPDP, $Pharmacy_Name, $Address, $City, $State, $Zip, $ph_upload, $upload) = @row;
    $sthp->finish();

    #### Check for actions needed
    $sql = "SELECT *
              FROM $db_office.${tbl_pharmacy}_action_req
	     WHERE Pharmacy_ID = '$PH_ID'
	       AND program = '$PROGRAM'";

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $action_req = $sthp->rows;
    $sthp->finish();

  }

  $tmp_user = "$USER";

  if ( $CSR_Reverse_ID_Lookup{$USER} ) {
    $com_where = "b.ReconRx_Account_Manager = '$CSR_Reverse_ID_Lookup{$USER}'";
    $tmp_user = 'SELECT wlsuperuser from officedb.webloginaccess where reconrx_ram = 1';
    
  }
  elsif ( $PH_ID ) {
    $com_where = "a.Pharmacy_ID = $PH_ID";
  }
  else {
    $com_where = "1 = 2";
  }

  #### Check for Communications
  $sql = "SELECT a.id
           FROM reconrxdb.communication a
           JOIN officedb.pharmacy b ON (a.Pharmacy_ID = b.Pharmacy_ID)
          WHERE $com_where
            AND a.status = 'N' 
            AND a.user_id NOT IN ($tmp_user)";
    
  $sthp = $dbp->prepare($sql);
  $sthp->execute();
  $new_communication = $sthp->rows;
  $sthp->finish();
       
  if ( $new_communication > 0) {
    $box_color = 'Red';
  }
  else {
    $box_color = 'Green';
  }

  # Close the Databases
  $dbp->disconnect;

  print qq#<figure class="mbr-figure container">
             <div class="header-block" >
               <img class="main_logo" src="/images/Outcomes_ReconRx.png" border="0"  alt="ReconRx"  class="logographic"/>
             </div>
           </figure>\n#;

  print qq#<div id="membersheaderborder"></div>\n#;

  if ( $Pharmacy_Name =~ /^\s*$/ ) {
     # Do nothing
  } elsif ( $Pharmacy_Name =~ /Reconciliation/i ) {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">user: $LOGIN</div>#;
    print qq#</div>#;
  } else {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">ncpdp: $inNCPDP</div>#;
    print qq#</div>#;
  }
  if ( $WHICHDB =~ /^LIVE$/i ) {
	  ##print qq#<h2 class="demo">$WHICHDB</h2>\n#;
          &displayMenuOption if($PH_ID > 1 );
  } else {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  }
  print qq#  <div style="clear: both;"></div>#;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-recon">\n#;

  if ( !$nosidenav ) {

  ##################  Recon-Rx Nav Bar ######################

    print qq#  <div id="leftcolumn-sidenav">\n#;

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "MyReconRx_Super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="hidden" NAME="Mode"    VALUE="Super">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    print ' 
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link rel="stylesheet" href="/css/jquery-ui.css">
      <script src="https://code.jquery.com/ui/1.13.1/jquery-ui.js"></script>
      <script>
      $( function() {
        $( "#menu" ).menu();
      } );
      </script>
      <style>
      .ui-menu {width: 196px; background: #f2f2f2;}
      </style>
    ';

    print qq# <ul id="menu">#;
    if ( $TYPE =~ /^ADMIN$/i && $Pharmacy_Name =~ /Reconciliation|^\s*$/i ) {
       print qq# <li><div><a href="ADMIN_menu.cgi">$pgm{Admin} ADMIN $pgm2{Admin}</a></div> \n#;
       print qq# <li><div><a href="Intervention_Dashboard.cgi">$pgm{Int} $Interventions $pgm2{Int}</a></div> \n#;
       print qq# <li><a href="Messenger.cgi">$pgm{Messenger} Messenger $pgm2{Messenger}&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li> \n#;
       print qq# <li><div><a href="Enrollments.cgi?status=complete">$pgm{Enroll} Enrollments $pgm2{Enroll}</a></div> \n#;
       print qq# <li><div><a href="ThirdPartyPayersList.cgi">$pgm{TPPList} $TPPList $pgm2{TPPList}</a></div> \n#;
    }

    if ( $Pharmacy_Name && $Pharmacy_Name !~ /Reconciliation/i && $USER !~ /^\s*$/ ) {
      print qq# <li><div><a href="MyReconRx.cgi">$pgm{Dashboard} $Dashboard $pgm2{Dashboard}</a></div> \n#;
      print qq# <li><div><a href="Review_My_Aging.cgi">$pgm{RMA} $ReviewMyAging $pgm2{RMA}</a></div> \n#;
      print qq# <li><div><a href="Post_Payment_to_Remits.cgi">$pgm{PPTR} $PostPayment $pgm2{PPTR}</a></div> \n#;
      print qq# <li><div><a href="Post_Check_with_No_Remit.cgi">$pgm{PPNR} $PostCheck $pgm2{PPNR}</a></div> \n#;

      if ( $action_req ) {
        if ($prog=~ /Action Required/i) {
          print qq# <li><a href="Action_Required.cgi"><span style="font-weight: bold; color: red;">Action Required</span></a></li>\n#;
        } else {
          print qq# <li><a href="Action_Required.cgi"><span style="color: red;">Action Required</span></a></li>\n#;
        }
      }

      print qq# <li><a href="Messenger.cgi">$pgm{Messenger} Messenger $pgm2{Messenger}&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li> \n#;
      print qq# <li><div><a href="Success_Stories.cgi">$pgm{SS} $SuccessStories $pgm2{SS}</a></div> \n#;
      print qq# <li><div><a href="Interventions.cgi">$pgm{Int} $Interventions $pgm2{Int}</a></div> \n#;

      # Report Menu Begin
	  
      print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{ReportsAll} Reports $pgm2{ReportsAll}</a></div> \n#;
      print qq# <ul class="MenuUL"> \n#;  
	  
	  print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{AcctsRec} Accounts Receivable $pgm2{AcctsRec}</a></div> \n#;
	  print qq# <ul class="MenuUL"> \n#;
	  print qq# <li><div><a href="Review_My_Accounts_Receivable_Monthly.cgi">$pgm{RMAM} End of Month $pgm2{RMAM}</a></div></li> \n#;
	  print qq# <li><div><a href="Review_My_Accounts_Receivable_Yearly.cgi">$pgm{RMAY}  End of Year $pgm2{RMAY}</a></div></li> \n#;
	  print qq# <li><div><a href="Review_My_Aging_Detailed.cgi">$pgm{RMAD}Current Aging Detail$pgm2{RMAD}</a></div></li> \n#;
      print qq# </ul> \n#;
	  
	  print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{RecClaims} Reconciled Claims $pgm2{RecClaims}</a></div> \n#;
	  print qq# <ul class="MenuUL"> \n#;
	  print qq# <li><div><a href="Review_My_Reconciled_Claims_Monthly.cgi">$pgm{RMRC}End of Month$pgm2{RMRC}</a></div></li> \n#;
	  ##	  print qq# <li><div><a href="Review_My_Reconciled_Claims_Quarterly.cgi">$pgm{RMRCQ}Quarterly$pgm2{RMRCQ}</a></div></li> \n#;
	  print qq# <li><div><a href="Review_My_Reconciled_Claims_Yearly.cgi">$pgm{RMRCY}End of Year$pgm2{RMRCY}</a></div></li> \n#;
	  print qq# <li><div><a href="YTD_Reconciled_Claims_Summary.cgi">$pgm{YTDRC}Year to Date$pgm2{YTDRC}</a></div></li> \n#;
	  #print qq# <li><div><a href="Review_My_PLB_Monthly.cgi">Monthly PLB</a></div></li> \n#;
	  print qq# <li><div><a href="Reconciled_Detail_Remittance.cgi">$pgm{RDR}Remittance Detail$pgm2{RDR}</a></div></li> \n#;
      print qq# </ul> \n#;
	  
      	  print qq# <li><div><a href="M3P.cgi">$pgm{M3P} M3P $pgm2{M3P}</a></div> \n#;
       print qq# </li> \n#;
	  
	  print qq# <li><div><a href="Report_Menu_All.cgi">$pgm{TotalSales} Total Sales $pgm2{TotalSales}</a></div> \n#;
      print qq# <ul class="MenuUL"> \n#;
      print qq# <li><div><a href="TotalSalesRpt_Summary.cgi">$pgm{Summary} Summary $pgm2{Summary}</a></div></li> \n#;
      print qq# <li><div><a href="TotalSalesRpt_Dtl.cgi">$pgm{Detail} Detail $pgm2{Detail}</a></div></li> \n#;
      print qq# </ul> \n#;
	  
	  # Report Menu End
  	
      if ($Pharmacy_Arete{$PH_ID} =~ /^B|E$/) {
        $tmpdate = $Pharmacy_Active_Date_ReconRxs{$PH_ID};
        $tmpdate =~ s/-//g;
        if ($tmpdate > 20200630) {
          print qq# <li><div><a href="BusinessTools.cgi">$pgm{Business}Business$pgm2{Business}</a></div> \n#;
          print qq# <ul class="MenuUL"> \n#;
          print qq# <li><div><a href="MedSync_Rpt.cgi">$pgm{MedSync}Med Sync Report$pgm2{MedSync}</a></div></li> \n#;
          print qq# <li><div><a href="Inventory_Rpt.cgi">$pgm{InvRpt}Inventory Management Report$pgm2{InvRpt}</a></div></li> \n#;
          print qq# <li><div><a href="psp.cgi">$pgm{PSP}Prescription Savings Program$pgm2{PSP}</a></div></li> \n#;		  
	  ##  print qq# <li><div><a href="Review_My_End_of_Month_BAC.cgi">End of Month Billed vs. Adjudicated</a></div></li> \n#;
	  ## print qq# <li><div><a href="Review_My_End_of_Fiscal_Year_BAC.cgi">End of Year Billed vs. Adjudicated</a></div></li> \n#;
          print qq# </ul> \n#;
          print qq# </li> \n#;
        }
      }   
	  
      if (-e $webpathRT || -e $webpathRT2) {
        print qq# <li><div><a href="ReimbursementTracking.cgi">$pgm{RmbTrk}Rembursement Tracking$pgm2{RmbTrk}</a></div></li> \n#;
      
      }

      print qq# </ul> \n#;
      print qq# </li> \n#;
      print qq# <li><div><a href="Tools_Menu.cgi">$pgm{Tools} Tools $pgm2{Tools}</a></div> #;
      print qq# <ul class="MenuUL"> \n#;
      print qq#   <li><div><a href="Search.cgi">$pgm{Search}$DetailedSearch$pgm2{Search}</a></div></li> \n#;

      if ( $Pharmacy_Arete{$PH_ID} eq 'B') {
        print qq# <li><div><a href="ADMIN_menu_Arete.cgi">$pgm{Research}Research$pgm2{Research}</a></div> \n#;
        print qq# <ul class="MenuUL"> \n#;
        print qq# <li><div><a href="Basic_Claim_Research_Tool.cgi">$pgm{BscClm}Claim Research$pgm2{BscClm}</a></div></li> \n#;
        print qq# <li><div><a href="Basic_Payment_Research_Tool.cgi">$pgm{BscPmt}Payment Research$pgm2{BscPmt}</a></div></li> \n#;
        print qq# </ul> \n#;
        print qq# </li> \n#;
      }
      if ( $ph_upload =~ /Yes/i ) {
        print qq#   <li><div><a href="EOBConverter.cgi">$pgm{EOB} EOB Converter$pgm2{EOB}</a></div></li> \n#;
      }
      if ( $upload =~ /Yes/i ) {
        print qq#   <li><div><a href="Upload835.cgi">$pgm{Up835}Remittance Upload$pgm2{Up835}</a></div></li> \n#;
      }
      print qq# <li><div><a href="Web_Training.cgi">$pgm{WebT}ReconRx Demo$pgm2{WebT}</a></div></li> \n#;
      print qq# <li><div><a href="Bulk_835_Download.cgi">$pgm{Bulk835}Weekly 835 Download$pgm2{Bulk835}</a></div></li> \n#;
      print qq# <li><div><a href="EFT.cgi">$pgm{EFT}EFT Request$pgm2{EFT}</a></div></li> \n#;
      print qq# </ul> \n#;
      print qq# </li> \n#;
    }

    print qq# <li><div><a href="Contact_Us.cgi">$pgm{Contact} $ContactUs $pgm2{Contact}</a></div> \n#;
    print qq# <li><a href="Logout.cgi">$LogOut</a></li>\n#;

    print qq# </ul>\n#;
    print qq# <div class="leftcolumn_logo">\n#;
    print qq# <img class="small_logo" src="../images/Outcomes_ReconRx.png" alt="Logo" title="">\n#;
    print qq# </div><!-- end  left column logo--> \n#;
    print qq# </div><!-- end leftcolumn-sidenav -->\n#; 
  }
  print qq# <div id="textarea">\n#;
}

sub ReconRxHeaderBlock {
  # my $menuoption = &getMenuOption;
  # if($menuoption eq 'Yes') {
    &ReconRxHeaderBlock_NewMenu;
  # }
  # else {
    # &ReconRxHeaderBlock_OldMenu;
  # }
}

sub ReconRxHeaderBlock_OldMenu {
  my ($nosidenav) = @_;

  ($ENV) = &What_Env_am_I_in;

  my $db_office      = 'officedb';
  my $tbl_pharmacy   = 'pharmacy';
  my $ctl_table      = 'pharmacy_ctl';
  my $ctl_table      = 'pharmacy_ctl';
  my $Dashboard      = 'Dashboard';
  my $ReviewMyAging  = 'Review My Aging';
  my $PostPayment    = 'Post Payment<br>to Remits';
  my $PostCheck      = 'Post Check<br>with No Remit';
  my $Reconcile      = 'Reconciled Detail<br>Remittance';
  my $Interventions  = 'Interventions';
  my $DetailedSearch = 'Detailed Search';
  my $Reports        = 'Reports';
  my $SuccessStories = 'Success Stories';
  my $SpecialProgram = 'Business Tools';
  my $Vendors        = 'Vendors';
  my $Broadcast      = 'Broadcast<br>Communications';
  my $TPP            = 'Third Party Payers';
  my $WebTraining    = 'Web Training Session';
  my $ContactUs      = 'Contact Us';
  my $LogOut         = 'Log Out';

  &readPharmacies;
  
  &readCSRs() if ( scalar keys %CSR_Reverse_ID_Lookup == 0 );
   
  $Pharmacy_Name = "";

  $nosidenav = 1 if ($nosidenav !~ /^\s*$/);

  &set_Webinar_or_Testing_DBNames;

  $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
         { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  if ( $TYPE =~ /SuperUser|Admin/i && !$PH_ID) {
    $Pharmacy_Name = "Reconciliation";  
  } else {

    my $sql = "SELECT a.*, EOBConversion, upload835 FROM (
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip 
                  FROM $db_office.$tbl_pharmacy
	         WHERE Pharmacy_ID = '$PH_ID'
		UNION
                SELECT NCPDP, Pharmacy_Name, Address, City, State, Zip 
                  FROM $db_office.${tbl_pharmacy}_coo
	         WHERE Pharmacy_ID = '$PH_ID'
	      
	      ) a
               LEFT JOIN $db_office.$ctl_table ON ($PH_ID = pharmacyid)";
   $sthp = $dbp->prepare($sql);
    $sthp->execute();
    my $numofrows = $sthp->rows;

    my @row = $sthp->fetchrow_array();
    ($inNCPDP, $Pharmacy_Name, $Address, $City, $State, $Zip, $ph_upload, $upload) = @row;
    $sthp->finish();

    #### Check for actions needed
    $sql = "SELECT *
              FROM $db_office.${tbl_pharmacy}_action_req
	     WHERE Pharmacy_ID = '$PH_ID'
	       AND program = '$PROGRAM'";

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $action_req = $sthp->rows;
    $sthp->finish();

#    print "Action: $action_req<br>";
  }

  if ( $CSR_Reverse_ID_Lookup{$USER} ) {
    $com_where = "b.ReconRx_Account_Manager = '$CSR_Reverse_ID_Lookup{$USER}'";
  }
  elsif ( $PH_ID ) {
    $com_where = "a.Pharmacy_ID = $PH_ID";
  }
  else {
    $com_where = "1 = 2";
  }

  #### Check for Communications
  $sql = "SELECT a.id
           FROM reconrxdb.communication a
           JOIN officedb.pharmacy b ON (a.Pharmacy_ID = b.Pharmacy_ID)
          WHERE $com_where
            AND (a.status = 'N' )
            AND a.user_id != $USER";
    
  $sthp = $dbp->prepare($sql);
  $sthp->execute();
  $new_communication = $sthp->rows;
  $sthp->finish();

  if ( $new_communication > 0) {
    $box_color = 'Red';
  }
  else {
    $box_color = 'Green';
  }

  # Close the Databases
  $dbp->disconnect;

#  print qq#<div id="wrapper"><!-- wrapper -->\n#;

#  print qq#  <div id="reconheader" > \n#;
  print qq#<figure class="mbr-figure container">
             <div class="header-block" >
               <img class="main_logo" src="/images/ReconRX_LogoWTag.png" border="0"  alt="ReconRx"  class="logographic"/>
             </div>
           </figure>\n#;

  print qq#<div id="membersheaderborder"></div>\n#;

#  print qq#    <div class="logo"><img src="/images/reconrx_800.png" alt="ReconRx" class="header_background"></div>\n#;
  if ( $Pharmacy_Name =~ /^\s*$/ ) {
     # Do nothing
  } elsif ( $Pharmacy_Name =~ /Reconciliation/i ) {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">user: $LOGIN</div>#;
    print qq#</div>#;
  } else {
    print qq#<div class="header_info">#;
    print qq#  <h1 class="pharm_name">$Pharmacy_Name</h1>\n#;
    print qq#  <div style="clear: both;"></div>#;
    print qq#  <div class="pharm_ncpdp">ncpdp: $inNCPDP</div>#;
    print qq#</div>#;
  }
  if ( $WHICHDB =~ /^LIVE$/i ) {
     &displayMenuOption if($PH_ID > 1 );
  } else {
     print qq#<h2 class="demo">$WHICHDB</h2>\n#;
  }
  print qq#  <div style="clear: both;"></div>#;
#  print qq#  </div><!-- end reconheader -->\n#;

  print qq#  <!-- body -->\n#;
  print qq#  <div id="mainbody-recon">\n#;

  if ( !$nosidenav ) {

  ##################  Recon-Rx Nav Bar ######################

    print qq#  <div id="leftcolumn-sidenav">\n#;

    if ( $TYPE =~ /Admin/i || $PH_COUNT > 1) {
       print qq#<div class="leftcolumn_title">\n#;
       $URLH = "MyReconRx_Super.cgi";
       print qq#<FORM ACTION="$URLH" METHOD="POST">\n#;
       print qq#<INPUT TYPE="hidden" NAME="Mode"    VALUE="Super">\n#;
       print qq#<INPUT TYPE="Submit" VALUE="Super User Select">\n#;
       print qq#</FORM>\n#;
       print qq#</div>\n#;
    }

    print ' 
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/jquery-ui.css">
    ';

    print qq#    <ul>\n#;
    if ( $TYPE =~ /^ADMIN$/i && $Pharmacy_Name =~ /Reconciliation|^\s*$/i ) {
       if ($prog =~ /ADMIN/i) {
         print qq#   <li><a href="ADMIN_menu.cgi"><strong>ADMIN</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="ADMIN_menu.cgi">ADMIN</a></li>\n#;
       }

       if ($prog =~ /Intervention_Dashboard/i) {
         print qq#   <li><a href="Intervention_Dashboard.cgi"><strong>Interventions</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Intervention_Dashboard.cgi">Interventions</a></li>\n#;
       }

       if ($prog =~ /Messenger/i) {
         print qq#   <li><a href="Messenger.cgi"><strong>Messenger</strong>&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li>\n#;
       } else {
         print qq#   <li><a href="Messenger.cgi">Messenger&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li>\n#;
       }
       
       if ($prog =~ /enrollments/i) {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete"><strong>Enrollments</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/cgi-bin/Enrollments.cgi?status=complete">Enrollments</a></li>\n#;
       }
       if ($prog =~ /ThirdPartyPayers/i) {
         print qq#   <li><a href="/cgi-bin/ThirdPartyPayersList.cgi"><strong>Third Party Payers List</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="/cgi-bin/ThirdPartyPayersList.cgi">Third Party Payers List</a></li>\n#;
       }
    }

    if ( $Pharmacy_Name && $Pharmacy_Name !~ /Reconciliation/i && $USER !~ /^\s*$/ ) {
       if ($prog =~ /MyReconRx/i) {
         print qq#   <li><a href="MyReconRx.cgi"><strong>$Dashboard</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="MyReconRx.cgi">$Dashboard</a></li>\n#;
       }	 
       if ($prog =~ /Review_My_Aging/i) {
         print qq#   <li><a href="Review_My_Aging.cgi"><strong>$ReviewMyAging</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Review_My_Aging.cgi">$ReviewMyAging</a></li>\n#;
       }
       if ($prog =~ /Post_Payment_to_Remits/i) {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi"><strong>$PostPayment</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Post_Payment_to_Remits.cgi">$PostPayment</a></li>\n#;
       }
       if ($prog =~ /Messenger/i) {
         print qq#   <li><a href="Messenger.cgi"><strong>Messenger</strong>&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li>\n#;
       } else {
         print qq#   <li><a href="Messenger.cgi">Messenger&nbsp<span style="background-color: $box_color; color: \#FFFFFF; padding: 1px 4px; border-radius: 35px">$new_communication</span></a></li>\n#;
       }
       if ($prog =~ /Post_Check_with_No_Remit/i) {
         print qq#   <li><a href="Post_Check_with_No_Remit.cgi"><strong>$PostCheck</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Post_Check_with_No_Remit.cgi">$PostCheck</a></li>\n#;
       }
       if ($prog =~ /Reconciled_Detail_Remittance/i) {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi"><strong>$Reconcile</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Reconciled_Detail_Remittance.cgi">$Reconcile</a></li>\n#;
       }
       if ( $ph_upload =~ /Yes/i ) {
         if ($prog=~ /EOB/i) {
           print qq#   <li><a href="EOBConverter.cgi"><strong>EOB Converter</strong></a></li>\n#;
         } else {
           print qq#   <li><a href="EOBConverter.cgi">EOB Converter</a></li>\n#;
         }
       }

       if ( $upload =~ /Yes/i ) {
         if ($prog=~ /Upload835/i) {
           print qq#   <li><a href="Upload835.cgi"><span style="font-weight: bold; color: red;">Remittance Upload</span></a></li>\n#;
         } else {
           print qq#   <li><a href="Upload835.cgi">Remittance Upload</a></li>\n#;
         }
       }

       if ( $action_req ) {
         if ($prog=~ /Action Required/i) {
           print qq#   <li><a href="Action_Required.cgi"><span style="font-weight: bold; color: red;">Action Required</span></a></li>\n#;
         } else {
           print qq#   <li><a href="Action_Required.cgi"><span style="color: red;">Action Required</span></a></li>\n#;
         }
       }

       if ($prog =~ /Interventions/i) {
         print qq#   <li><a href="Interventions.cgi"><strong>$Interventions</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Interventions.cgi">$Interventions</a></li>\n#;
       }
       if ($prog =~ /^Search$/i) {
         print qq#   <li><a href="Search.cgi"><strong>$DetailedSearch</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Search.cgi">$DetailedSearch</a></li>\n#;
       }
       if ($prog =~ /Report_Menu|TotalSalesRpt/i) {
         print qq#      <li><a href="Report_Menu.cgi"><strong>$Reports</strong></a></li>\n#;
       } else {
         print qq#      <li><a href="Report_Menu.cgi">$Reports</a></li>\n#;
       }
       if ( $Pharmacy_Arete{$PH_ID} eq 'B') {
         if ($prog =~ /ADMIN|Research_Tool/i) {
           print qq#   <li><a href="Basic_Menu.cgi"><strong>Research Tools</strong></a></li>\n#;
         } else {
           print qq#   <li><a href="Basic_Menu.cgi">Research Tools</a></li>\n#;
         }
       }
       if ($prog =~ /Upload835/i) {
	       ##    print qq#   <li><a href="Upload835.cgi"><strong>Upload 835</strong></a></li>\n# if($upload);
       } else {
	       ##  print qq#   <li><a href="Upload835.cgi">Upload 835</a></li>\n# if($upload);
       }

       if ($prog =~ /Success_Stories/i) {
         print qq#   <li><a href="Success_Stories.cgi"><strong>$SuccessStories</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Success_Stories.cgi">$SuccessStories</a></li>\n#;
       }

       if ($Pharmacy_Arete{$PH_ID} =~ /^B|E$/) {
         $tmpdate = $Pharmacy_Active_Date_ReconRxs{$PH_ID};
         $tmpdate =~ s/-//g;
         if ($tmpdate > 20200630) {
           if ($prog =~ /BusinessTools/i) {
             print qq#   <li><a href="BusinessTools.cgi"><strong>$SpecialProgram</strong></a></li>\n#;
           } else {
             print qq#   <li><a href="BusinessTools.cgi">$SpecialProgram</a></li>\n#;
           }
         }
       }

       if ($prog =~ /Vendors/i) {
         print qq#   <li><a href="Vendors.cgi"><strong>$Vendors</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Vendors.cgi">$Vendors</a></li>\n#;
       }
       if ($prog =~ /Broadcast_Communications/i) {
         print qq#   <li><a href="Broadcast_Communications.cgi"><strong>$Broadcast</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Broadcast_Communications.cgi">$Broadcast</a></li>\n#;
       }
       if ($prog =~ /Third_Party_Payers/i) {
         print qq#   <li><a href="Third_Party_Payers.cgi"><strong>$TPP</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Third_Party_Payers.cgi">$TPP</a></li>\n#;
       }
       if ($prog =~ /Web_Training/i) {
         print qq#   <li><a href="Web_Training.cgi"><strong>$WebTraining</strong></a></li>\n#;
       } else {
         print qq#   <li><a href="Web_Training.cgi">$WebTraining</a></li>\n#;
       }
    }
    if ($prog =~ /Contact_Us/i) {
      print qq#      <li><a href="Contact_Us.cgi"><strong><i>$ContactUs</i></strong></a></li>\n#;
    } else {
      print qq#      <li><a href="Contact_Us.cgi"><i>$ContactUs</i></a></li>\n#;
    }
    print qq#      <li><a href="Logout.cgi">$LogOut</a></li>\n#;

    print qq#    </ul>\n#;
    print qq#      <div class="leftcolumn_logo">\n#;
    print qq#        <img class="small_logo" src="../images/ReconRX_Logo_Grey_bg.png" alt="Logo" title="">\n#;
    print qq#      </div><!-- end  left column logo--> \n#;
    print qq#  </div><!-- end leftcolumn-sidenav -->\n#; 
  }
  
  print qq#  <div id="textarea">\n#;
}

#______________________________________________________________________________

sub ReconRxMembersLogin {

  my $URL = "MyReconRx.cgi";
  
  print qq#<FORM ACTION="$URL" METHOD="POST">\n#;
  print qq#<INPUT TYPE="hidden" NAME="debug"   VALUE="$debug">\n#;
  print qq#<INPUT TYPE="hidden" NAME="verbose" VALUE="$verbose">\n#;
  
  print "JJJ: NEWPASS: $NEWPASS, USER: $USER, PASS: $PASS, LFIRSTLOGIN: $LFIRSTLOGIN, $LPERMISSIONLEVEL,<br>CUSTOMERID: $CUSTOMERID<br>\n" if ($debug);
  
  &askforMemberUSERPASS;
  $dontdoHiddenuserpass++;
  
  if ( !$dontdoHiddenuserpass ) {
    print qq#<INPUT TYPE="hidden" NAME="USER"     VALUE="$USER">\n#;
    print qq#<INPUT TYPE="hidden" NAME="PASS"     VALUE="$PASS">\n#;
    print qq#<INPUT TYPE="hidden" NAME="CUSTOMERID"  VALUE="$CUSTOMERID">\n#;
  }
  print qq#<INPUT TYPE="hidden" NAME="VALID"     VALUE="$VALID">\n#;
  print qq#<INPUT TYPE="hidden" NAME="isAdmin"   VALUE="$isAdmin">\n#;
  print qq#<INPUT TYPE="hidden" NAME="isMember"  VALUE="$isMember">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LTYPE"     VALUE="$LTYPE">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LFIRSTLOGIN" VALUE="$LFIRSTLOGIN">\n#;
  print qq#<INPUT TYPE="hidden" NAME="LPERMISSIONLEVEL" VALUE="$LPERMISSIONLEVEL">\n#;
  print "</FORM>\n";
  
}

#______________________________________________________________________________

sub ReconRxGotoNewLogin {

  print "Location: ../Login.html\n\n";
  exit(0);
}

#______________________________________________________________________________

# read in all 835 remit database "already processed" filenames

sub read_db_FTP_Filenames {

  print "<hr>sub read_db_FTP_Filenames: Entry.\n" if ( $incdebug );

  my $dbin    = "R8DBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $FIELDS  = $DBFLDS{"$dbin"};
  my $FIELDS2 = $DBFLDS{"$dbin"} . "2";
  my $prefix  = "R8";    # unique to this table

#______________________________________________________________________________
  my @fieldnames = ();
  my @pcs = split(", ", $$FIELDS);
  foreach $pc (@pcs) {
    $key = "${prefix}##$pc";
    $pchead = $HEADINGS{"$key"};
#   print "pc: '$pc', pchead: $pchead\n" if ($incdebug);
    push(@fieldnames, "$pchead");
  }
#______________________________________________________________________________

  my $dbm = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
        { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  my $sql = "SELECT R_FTP_Filename FROM $DBNAME.$TABLE";
  print "sql:\n$sql\n" if ($incdebug);
  $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows found: $NumOfRows\n" if ($incdebug);

  if ( $NumOfRows > -1 ) {
     while ( my @row = $sthx->fetchrow_array() ) {

        ($R_FTP_Filename) = @row;
        my @pcs = split("\/", $R_FTP_Filename);
        my $key = pop(@pcs);
        my $TPP = pop(@pcs);
        $Seen_FTP_Filenames{$key} = "$TPP";
     }
  } else {
     print qq#UNKNOWN Problem. No records found for $dbin.\n#;
  }
  $sthx->finish;

# Now get Switch FTP filenames
#
  my $dbin    = "RIDBNAME";  # Only database needed for this routine
  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $FIELDS  = $DBFLDS{"$dbin"};
  my $FIELDS2 = $DBFLDS{"$dbin"} . "2";
  my $prefix  = "RI";    # unique to this table

#______________________________________________________________________________
  my @fieldnames = ();
  my @pcs = split(", ", $$FIELDS);
  foreach $pc (@pcs) {
    $key = "${prefix}##$pc";
    $pchead = $HEADINGS{"$key"};
    print "pc: '$pc', pchead: $pchead\n" if ($incdebug);
    push(@fieldnames, "$pchead");
  }
#______________________________________________________________________________

  my $sql = "SELECT dbSwVendor, dbFTP_Filename FROM $DBNAME.$TABLE";
  print "sql:\n$sql\n" if ($incdebug);
  $sthx  = $dbm->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows found: $NumOfRows\n" if ($incdebug);

  if ( $NumOfRows > -1 ) {
     while ( my @row = $sthx->fetchrow_array() ) {

        ($dbSwVendor, $dbFTP_Filename) = @row;
        my @pcs = split("\/", $dbFTP_Filename);
        my $key = pop(@pcs);
        my $TPP = pop(@pcs);
        $Seen_FTP_Filenames{$key} = "$dbSwVendor";
     }
  } else {
     print qq#UNKNOWN Problem. No records found for $dbin.\n#;
  }
  $sthx->finish;
  $dbm->disconnect;

  if ( $incdebug ) {
     print "Filenames found:\n";
     foreach $key (sort { $Seen_FTP_Filenames{$a} cmp $Seen_FTP_Filenames{$b} || $a cmp $b } keys %Seen_FTP_Filenames ) {
       my $TPP = $Seen_FTP_Filenames{$key};
       printf("%-15s | %-s\n", $TPP, $key);
     }
     print "-"x72, "\n\n";
  }

  print "sub read_db_FTP_Filenames: Exit.\n" if ( $incdebug );
  print "-", "\n" if ( $incdebug );
}

#______________________________________________________________________________

sub seen_file_yet {

  my ($filename) = @_;

  my $debug = 0;
 
  print "sub seen_file_yet: Entry. filename: $filename\n" if ($debug || $incdebug);

  my $yn    = "N";    # default to "we have not seen the file yet, process it"
  my $SwDir = "\\\\$FLSERVER\\FTPData\\ReconRx_Get_FTP_Switch_Data";    # Switch save directories
  
# print qq#Check if it is a Audit file or TEXT only or ref.edi\nfilename: $filename\n# if ($debug || $incdebug);
  if ( ($filename =~ /_AUD_/i) || $filename =~ /-TEXT$/i || $filename =~ /835_5010ref.edi/i ||
        $filename =~ /test.txt/i || $filename =~ /test1.txt/i
     ) {
     print "\tSkipping! File is a Medco _AUD_ || Medimpact ref || PDMI TEXT file\n";
     $yn = "Y";
  }

  my @pcs = split(/\\|\//, $DataDirectory);
  $whoami = pop(@pcs);
  $whoami = pop(@pcs) if ( $whoami =~ /ReconRx$/i );
  print "whoami: $whoami\n" if ($debug || $incdebug);
  if ( $whoami =~ /Switch$/i ) {
     ($whoami, $p2) = split(/Switch/i, $whoami, 2);
  }

# print qq#Check if exists: "$DataDirectory\\$filename" || "$DataDirectory\\processed\\$filename"\n# if ($debug || $incdebug);
  
#####(my $DataDir2 = $DataDirectory) ;#=~ s/\\/\//g;

   my $DataDir2 = $DataDirectory;
  (my $newDD  = $DataDir2) =~ s/\.com/\.com_processed/gi;
  (my $DDwoPP = $DataDir2) =~ s/PreProcess\///gi;

  my $newDD2 = "${DataDir2}\\Processed";					# For dirs like "Preprocess\Medco\Processed"

  (my $DDwoPP = $DataDir2) =~ s/PreProcess[\/|\\]//gi;

  my $ckdir1 = "$DataDir2\\$filename";						# Read into and saved from FTP file
  my $ckdir2 = "$DDwoPP\\$filename";						# directory of PreProcess'd files after processed
  my $ckdir3 = "$newDD2\\$filename";						# For dirs like "Preprocess\Medco\Processed"
  my $ckdir4 = "$newDD\\processed\\$filename";				# Processed file directory
  my $ckdir5 = "${SwDir}_$whoami\\$filename";		
  my $ckdir6 = "${SwDir}_$whoami\\processed\\$filename";	# Switch data directory, like "ReconRx_Get_FTP_Switch_Data_Emdeon"
  my $ckdir7 = "$newDD\\$filename";				# Processed file directory - New Location

  if ( $debug || $incdebug ) {
     print "look for filename '$filename'\n";
     print "ckdir1 : $ckdir1\n";
     print "ckdir2 : $ckdir2\n";
     print "ckdir3 : $ckdir3\n";
     print "ckdir4 : $ckdir4\n";
     print "ckdir5 : $ckdir5\n";
     print "ckdir6 : $ckdir6\n";
     print "ckdir7 : $ckdir7\n";
     print "\n";
     if ( -e "$ckdir1") { print "1. Exists: $ckdir1\n"};
     if ( -e "$ckdir2") { print "2. Exists: $ckdir2\n"};
     if ( -e "$ckdir3") { print "3. Exists: $ckdir3\n"};
     if ( -e "$ckdir4") { print "4. Exists: $ckdir4\n"};
     if ( -e "$ckdir5") { print "5. Exists: $ckdir5\n"};
     if ( -e "$ckdir6") { print "6. Exists: $ckdir6\n"};
     if ( -e "$ckdir7") { print "7. Exists: $ckdir7\n"};

  }

  if ( -e "$ckdir1" || -e "$ckdir2" || -e "$ckdir3" || -e "$ckdir4" || -e "$ckdir5" || -e "$ckdir6" || -e "$ckdir7" ) {
     print qq#\tSkipping! File '$filename' found on disk! (dir or subdir)\n#;
     $yn = "Y";
  }
  $SwTPP = $Seen_FTP_Filenames{"$key"};
  if ( $Seen_FTP_Filenames{"$key"} ) {
     print qq#\tSkipping! File '$filename' already in Database for Sw/TPP: $SwTPP!\n#;
     $yn = "Y";
  }
  print "-"x72, "\n" if ( $yn eq "Y" && ($debug || $incdebug) );

  print "sub seen_file_yet: Exit. yn: $yn. filename: $filename\n" if ($incdebug);

  return ($yn);
}

#______________________________________________________________________________

sub ReconRx_jdo_sql {

# $incdebug++;

  my ($sql) = @_;
  my $rowsfound = 0;
  if ( $incdebug ) {
     print "sub ReconRx_jdo_sql. Entry.\n";
     print "sql:\n$sql\n";
  }

  my $sth2112 = $dbx->prepare($sql);
  $sth2112->execute;
  $rowsfound = $sth2112->rows;

  print "ReconRx_jdo_sql: rowsfound: $rowsfound\n" if ($incdebug);
  if ( $rowsfound =~ /^0$|0E0|^\s*$/i ) {
#    print "Setting rowsfound to ZERO: 0\n" if ($incdebug);
     $rowsfound = 0;
  }

  if ( $rowsfound > 0 && $sql !~ /^\s*INSERT|^\s*UPDATE|^\s*REPLACE|^\s*DELETE/i ) {
     while ( my @row = $sth2112->fetchrow_array() ) {
        print qq#row: #, join(",", @row), qq#\n# if ($incdebug);
     }
  }
  $sth2112->finish;

  $sql = "";

  if ( $incdebug ) {
     print "sub ReconRx_jdo_sql. Exit. rowsfound: $rowsfound\n";
     print "-"x96, "\n";
  }

  return($rowsfound);

}

# ______________________________________________________________________________

sub Determine_BrandOrGeneric {

  my ($NDC) = @_;
  my ($BrandOrGeneric) = "";

# my $incdebug++;
# my $debug++;

  print "sub Determine_BrandOrGeneric: Entry. NDC (NDC): $NDC\n" if ($incdebug);

  $NDC =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white spaces

  my $dbin   = "LTDBNAME";  # Only database needed for this routine
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  if ( $NDC =~ /^\d+$/ ) { 
     $sql = "SELECT MSBorG FROM $DBNAME.$TABLE WHERE NDC=$NDC ";
  } else {
     $sql = "SELECT MSBorG FROM $DBNAME.$TABLE WHERE NDC='$NDC' ";
  }
  
  print "sql:<br>$sql<br>\n" if ($incdebug);

  my $sthx  = $dbi->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of rows found: $NumOfRows<br>\n" if ($incdebug);

  while ( my @row = $sthx->fetchrow_array() ) {
     ($BrandOrGeneric) = @row;
     print "JJJ: NDC: BrandOrGeneric: $BrandOrGeneric\n";
  }

  print "sub Determine_BrandOrGeneric: Exit. BrandOrGeneric: $BrandOrGeneric\n" if ($incdebug);

  return ($BrandOrGeneric);

}
 
#______________________________________________________________________________

sub Validate_No_Expired_Licenses {
  my ($Pharmacy_ID) = @_;

  my %Check_Fields    = ();
  my %Types           = ();
  my ($Licenses_Okay) =  1;    # Set to "TRUE", prove false below
  my $Licenses_Broken = "";

  if ( $TYPE =~ /Admin/i ) {
     print "Super User: $dispNCPDP. Skipping\n" if ($debug);
  } else {
    my $dbin     = "PHDBNAME";
    my $db       = $dbin;
    my $DBNAME   = $DBNAMES{"$dbin"};
    my $TABLE    = $DBTABN{"$dbin"};
    my $FIELDS   = $DBFLDS{"$dbin"};
    my $FIELDS2  = $DBFLDS{"$dbin"} . "2";
    my $fieldcnt = $#${FIELDS2} + 2;
    
    # Process Expiration Dates. Highlight on screen. Yellow for < 30 days, Red for Due today or Past Due
    
    # connect to the pharmacy MySQL database
    $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
              { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
    DBI->trace(1) if ($dbitrace);
  
    my $sql = "SELECT $$FIELDS FROM $DBNAME.$TABLE WHERE Pharmacy_ID = $Pharmacy_ID";
  
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
	
        next if ( $name =~ /BNDD|DPS|^CMEA/i );
        next if ( $name !~ /Exp|^Type$|^DEA$|^Liability_Ins|^PIC_License|^State_PermitNumber|^State_Controlled/i );
	next if ( $pc =! /NULL|N\/A/i );
  
        ${$name} = $pc ;# || $nbsp;
        $Check_Fields{"$name"} = $pc;
      }
    }
  
    $sthp->finish();
  
    # Close the Databases
    $dbp->disconnect;
  
    my ($min, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
    $year  += 1900;    # reported as "years since 1900".
    $month += 1;    # reported ast 0-11, 0==January
    my $checkitdate = sprintf("%04d%02d%02d", $year, $month, $day);
  
    my $future = time() + (30 * 24 * 60 * 60);
    my ($min30, $hour30, $day30, $month30, $year30)   = (localtime($future))[1,2,3,4,5];
    $year30  += 1900;    # reported as "years since 1900".
    $month30 += 1;    # reported ast 0-11, 0==January
    my $checkitdate30 = sprintf("%04d%02d%02d", $year30, $month30, $day30);
  
    foreach $jfield (sort keys %Check_Fields) {
       next if ( $jfield =~ /^Type$/i );
       print "jfield: $jfield<br><hr>\n" if ($debug);
       if ( ( $jfield =~ /^DEA/i  && $DEA  =~ /N\/A/i ) || 
            ( $jfield =~ /^Liability_Ins/i        && $Liability_Ins_Policy_Number =~ /N\/A/i ) ||
            ( $jfield =~ /^PIC_License/i          && $PIC_License_Number  =~ /N\/A/i ) ||
            ( $jfield =~ /^State_Permit_Number/i  && $State_Permit_Number =~ /N\/A/i ) ||
            ( $jfield =~ /^State_Controlled/i     && $State_Controlled_Substance_License =~ /N\/A/i )
       ) {
          # Skip these!
       } else {
          if ( $jfield =~ /_Exp/i) {
             $jval = $Check_Fields{"$jfield"};
             $jval =~ s/\-//g;
             print "Checking jfield: $jfield, jval: $jval<br>\n" if ($debug);
             if ( !$jval || $jval !~ /NULL|^\s*$/ ) {
                if ( $jval < $checkitdate ) {
               print qq#$jfield - Expired! - $Check_Fields{"$jfield"}<br>\n# if ($debug);
                   $Licenses_Okay = 0;
               $Licenses_Broken .= sprintf("$Check_Fields{$jfield} - Expired! - $jfield##");
            } elsif ( $jval < $checkitdate30 ) {
               print qq#$jfield - Expires soon - $Check_Fields{"$jfield"}<br>\n# if ($debug);
           # $Licenses_Okay = 0;    # Don't set on Expires soon, just include if Expireds! found!
               $Licenses_Broken .= sprintf("$Check_Fields{$jfield} - Expires Soon - $jfield##");
            }
             }
          }
       }
    }
  }
  return ($Licenses_Okay, $Licenses_Broken);
}

#______________________________________________________________________________

sub get_all_Filenames_in_DB {

  $Archive_TABLE = $TABLE . "_archive";
  print "sub get_all_Filenames_in_DB: Entry. DBNAME: $DBNAME, TABLE: $TABLE, Archive_TABLE: $Archive_TABLE\n";
  if ( $DBNAME =~ /testing/i ) {
     print "OVERWRITING $DBNAME to be ReconRxDB. Use prod data for getting all Filenames\n";
     $DBNAME = "ReconRxDB";
  }

  my $sql  = qq# SELECT DISTINCT Filename FROM \n#;
     $sql .= qq# ( \n#;
     $sql .= qq# SELECT DISTINCT Filename FROM $DBNAME.$TABLE  \n#;
     $sql .= qq# UNION ALL \n#;
     $sql .= qq# SELECT DISTINCT Filename FROM $DBNAME.${Archive_TABLE} \n#;
     $sql .= qq# ) allremits \n#;
     $sql .= qq# ORDER BY Filename \n#;

  print "\nsql:\n$sql\n\n";

  my $sthx  = $dbx->prepare("$sql") or warn $DBI::errstr;
  $NumOfRows = $sthx->execute;
  print "Number of rows affected: $NumOfRows\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
     ($FN) = @row;
     my @pcs = split(/\\/, $FN);
     my $JFN = pop(@pcs);

     $All_Filenames{"$JFN"}++;    # Save unique filenames
  }

  $sthx->finish;

  print "sub get_all_Filenames_in_DB: Exit. NumOfRows: $NumOfRows\n" if ($debug);

}

#______________________________________________________________________________

sub doDBWrites {
  my $doRBSDB        = 0;
  my $doRECONDB      = 0;
  my $RECONARCH      = 0;
  my $doCASHDB       = 0;
  my $doOVERFLOW     = 0;
  my $jbin           = 0;
  my $jgroup         = 0;
  my $claimid;
  
  my $goon_ReconRx++;
  
  print "doDBWrites- MBinNumber: $MBinNumber\n";

  # Do not add to ReconRx database if if this BIN is 15433 (RedeemRx) and has a matching Group in the DoNotAddMarkCash015433 list
  if ( $MBinNumber == 15433 ) {
     print "BIN 15433 found. See if a CASH group matches:\n";
     foreach $jgroup ( keys %DoNotAddMarkCash015433 ) {
       if ( $jgroup =~ /^$MGroupID$/i ) {
         print "Found BIN: 15433, Group: $MGroupID - Skipping as in hash DoNotAddMarkCash015433 : $DoNotAddMarkCash015433{$jgroup}\n\n";
         $goon_ReconRx = 0;
         last;
       }
     }
  }

  if ( !$readTPPPriSec_DONE ) {
     print "call readTPPPriSec!!!!!\n";
     &readTPPPriSec;
  }
  
 if ( $testing || $debug ) {
     print "TPP_Reconciles($MBinParentdbkey): $TPP_Reconciles{$MBinParentdbkey}\n";
     print "\n";
 }
  
  if ($local_FTPpr_Dir) {;
    $MFTP_Filename = "${local_FTPpr_Dir}/${inFileName}";
  }
  else {
    $MFTP_Filename = $inFileName;
  }

  ($output) = &print_incoming_record2;
  print "$output\n";

  my $CHKNCPDP = substr("0000000" . $MNCPDPNumber, -7);

  if ( $testing || $debug ) {
     print "JJJJJ- MNCPDPNumber: $MNCPDPNumber\n";
     print "JJJJJ- CHKNCPDP    : $CHKNCPDP\n";
  }

  print "0. CASHBINNAME: $CASHBINNAME, MBinNumber: $MBinNumber\n";

  if ( $MBinNumber =~ /^\s*$/ ) {
     $MBinNumber = 0; # Force to be CASH
     print "2. Bin blank, set to 0. MBinNumber: $MBinNumber\n";
  }
  if ( $CASHBINNAME =~ /^\s*$/ ) {
     print "Skip Cash Bin check as CASHBINNAME is blank\n" if ($testing || $debug);
  } else {
     if ( $MBinNumber =~ /$CASHBINNAME|CASH/i ) {
        $MBinNumber = 0; # Force to be CASH
        print "3. Bin matches Cash name. MBinNumber: $MBinNumber\n";
     }
  }
  print "9. exit Bin check- MBinNumber: $MBinNumber\n";

#------------------------
  if ( $testing || $debug ) {
     print "Pharmacy_Types($MPharmacy_ID)       : $Pharmacy_Types{$MPharmacy_ID}\n";
     print "Pharmacy_RBSReporting($MPharmacy_ID): $Pharmacy_RBSReporting{$MPharmacy_ID}\n";
  }
#------------------------
  
  $ADD = 1;
  if ( $MTransactionCode !~ /^E1$/i ) {
     ($ADD) = &isNDCBogus($MNDC, $MCompoundCode);
  }

  print "Pharmacy Type: $Pharmacy_Types{$MPharmacy_ID}\n";
  print "RBSReporting : $Pharmacy_RBSReporting{$MPharmacy_ID}\n";

  if ( $ADD
       && (( $Pharmacy_Status_RBSs{$MPharmacy_ID} =~ /Active/i && $Pharmacy_RBSReporting{$MPharmacy_ID} =~ /^Y/i) || ( $Pharmacy_Status_RBS_Directs{$MPharmacy_ID} =~ /Active/i))
       && $MTransactionCode !~ /^E1$/i
       && $MResponseCode    !~ /^R$/i) { 	    
     # Insert into RBS Reporting data

     $doRBSDB++;

     print "Setting doRBSDB++\n" if ($testing || $debug);
  }

#------------------------
  
  if ( $Pharmacy_Status_DefaultCashs{$MPharmacy_ID} =~ /Active/i  
       && $MTransactionCode !~ /^E1$/i
       && $MResponseCode    !~ /^R$/i) {	    
     # Insert into CASH Reporting data

     $doCASHDB++;

     print "Setting doCASHDB++\n" if ($testing || $debug);
  }

#------------------------
  
  my $jBIN = substr("000000" . $MBinNumber, -6);
  my $jkey1 = $Reverse_TPP_BINs_ALL{$jBIN};

  my $jkey = $MBinNumber + 0;
  my $jkey2 = $Reverse_TPP_BINs_ALL{$jkey};
  
  $goon_ReconRx = 0  if (!$jkey1 && !$jkey2);

  if ( $Pharmacy_Status_ReconRxs{$MPharmacy_ID} =~ /Active/i && (($MTransactionCode !~ /^E1$/i && $MResponseCode =~ /^P$|^A$|^D$/i && $goon_ReconRx) || $inFileName =~ /rx30_CO/i) ) {
      $doRECONDB++;
    if ( $TPP_Reconciles{$MBinParentdbkey} =~ /^N/i || $TPP_Reconciles{$jkey1} =~ /^N/i || $TPP_Reconciles{$jkey2} =~ /^N/i ) {
      $RECONARCH++;
    } 
    print "Setting doRECONDB++\n" if ($testing || $debug);
  } 
  else {
     print "Not Setting doRECONDB++\n" if ($testing || $debug);
  }

#------------------------
  
  if ( $MTransactionCode =~ /^E1$/i ) {
     print "Skipping row. 'E1' found for TransactionCode\n";
     return;
  } elsif ( $doRBSDB || $doRECONDB || $doCASHDB) {
     # yea! we have a place to go!
  } else {
     $doOVERFLOW++;
  }
#------------------------
#------------------------
  
  print "sub doDBWrites: fileSwVendor: $fileSwVendor, doRBSDB: $doRBSDB, doRECONDB: $doRECONDB, RECONARCH: $RECONARCH, doCASHDB: $doCASHDB,  doOVERFLOW: $doOVERFLOW\n";

  $MSwVendor = $fileSwVendor;
  $MTCode    = "";
  $MCode     = "NP";

  ($claimexists, $claimid) = &DoesClaimExist("CLDBNAME");
  
  if ( $claimexists ) {
     print ">>> Claim Exists! Claim Id - $claimid!!!! <<<\n\n";
  } elsif ($MResponseCode =~ /^R$/i ) {
     print "--- Skipping Claims Insert due to 'R' Response Code. ---\n\n";     
  } else {
     print ">>> NEW Claims Record. <<<\n\n";
     ($claimid) = &Write_Record_to_Claims("CLDBNAME", "CLHASH");
  }
  ## This will look for LTC locations where the Retail location is not in Recon
  # This must be loaded AFTER claimsdata.claims
  if ($goon_ReconRx && $ltc_locations{$MServiceProviderID}) {
    $MPharmacy_ID =  $ltc_locations{$MServiceProviderID}; 
    if ( $Pharmacy_Status_ReconRxs{$MPharmacy_ID} =~ /Active/i && $MTransactionCode !~ /^E1$/i && $MResponseCode    =~ /^P$|^A$|^D$/i) {
      $MNCPDPNumber =  $Pharmacy_NCPDPs{$MPharmacy_ID};
      $MNationalProviderID = $MServiceProviderID;
      $doRECONDB++;

      if ( $TPP_Reconciles{$MBinParentdbkey} =~ /^N/i || $TPP_Reconciles{$jkey1} =~ /^N/i || $TPP_Reconciles{$jkey2} =~ /^N/i ) {
        $RECONARCH++;
      }
    }
  }

  $MTCode    = "RECNO" if($RECONARCH > 0);

  my @writetodbs = ();
  
  push (@writetodbs, "ZZDBNAME") if ( $doRBSDB );
  push (@writetodbs, "RIDBNAME") if ( $doRECONDB );
  push (@writetodbs, "DCDBNAME") if ( $doCASHDB );
  push (@writetodbs, "OVDBNAME") if ( $doOVERFLOW );

  my $DBNAME  = "";
  my $TABLE   = "";
  my $HASH    = "";
  my $RRNAME  = "";

  foreach $dbin ( @writetodbs ) {
    $DBNAME  = $DBNAMES{"$dbin"};
    $TABLE   = $DBTABN{"$dbin"};
    $HASH    = $HASHNAMES{$dbin};
    $RRDESC  = $DBDESCS{$dbin};

    if ($dbin =~ /RIDBNAME/i) {
      ($recordexists) = &doesRecordExist2($dbin);
      if ( !$recordexists ) { #       Check Archive areas!
        $dbina = "";     
        if ( $dbin =~ /RIDBNAME/i ) {
           $dbina = "RADBNAME";
           print "Not in Prod, check in Archive. dbina: $dbina\n";
           ($recordexists) = &doesRecordExist2($dbina);
        }
      }
  
      if ( $recordexists ) {
         print ">>> Record Exists! Skipping!!!! <<<\n\n";
      } else {
         print ">>> NEW Record. Create record in DB: $dbin - $RRDESC <<<\n\n";
         &Write_Record_to_Database2($dbin, $HASH);
      }
    }

    ($incomingexists) = &DoesClaimExistIncoming($dbin, $claimid);
      
    if ($dbin eq 'OVDBNAME') {
      $rows = $dbi->do("UPDATE claimsdata.claims
                           SET StatusCode = 'OVF'
	                 WHERE claimid = '$claimid'
                           AND StatusCode = ''") or warn $DBI::errstr;
      $sqlcount++;
    }
    elsif (!$incomingexists) {
#     elsif (($dbin eq 'DCDBNAME' || $dbin eq 'ZZDBNAME' || $dbin eq 'TDDBNAME') && !$incomingexists) {
      print ">>> NEW Record. Create record in DB: $dbin with Id $claimid <<<\n\n";

       if ($dbin eq 'ZZDBNAME') {
         $MPatientPayAmountPaid = -20000 if ($MPatientPayAmountPaid =~ /^\s*$/ );
	 $MTotalAmountPaid = -20000 if ($MTotalAmountPaid =~ /^\s*$/ );
	 $MGrossAmountDue = -20000 if ($MGrossAmountDue =~ /^\s*$/ );
	 $MIngredientCost = -20000 if ($MIngredientCost =~ /^\s*$/ );

         $rows = $dbi->do("INSERT INTO $DBNAME.incoming (claimid, PatientPayAmountPaid, TotalAmountPaid, GrossAmountDue, IngredientCost) 
  	                   VALUES ($claimid, $MPatientPayAmountPaid, $MTotalAmountPaid, $MGrossAmountDue, $MIngredientCost)") or warn $DBI::errstr;
        }
	else {
          $rows = $dbi->do("INSERT INTO $DBNAME.incoming (claimid) VALUES ($claimid)") or warn $DBI::errstr;
        }

        $sqlcount++;
      }

      print "$rows row(s) affected\n" if ($testing || $debug);
      printf "Write_Record_to_Incoming: Exit. %4d: $rows rows affected\n", $sqlcount;
  }

  print "sub doDBWrites: Exit. recordexists: $recordexists\n" if ($testing || $debug);
  print "="x96, "\n\n" if ($debug);
}

#______________________________________________________________________________

# if NDC bogus, don't add
# if Compound Code is 2, go ahead and add
# If Compound Code is not 2, check NDC 
#    if NDC has spaces in it, fail
#    if NDC has no numeric characters in it, fail

sub isNDCBogus {

  my ($MNDC, $MCompoundCode) = @_;
  my $ADD = 1;	# Default to ADD
  my $debug = 0;

  print "sub isNDCBogus. Entry. MNDC: $MNDC, MCompoundCode: $MCompoundCode\n" if ($debug);

  $lenMNDC = length($MNDC);

  if ( $MCompoundCode == 2 && $lenMNDC <= 11) {
     $ADD++;
  } elsif ( $lenMNDC > 11 ) {
     $ADD = 0;
     print "NDC caused record to not be added: $MNDC - Too long (>11)\n";
  } elsif ( $MNDC =~ /\s+/ ) {
     $ADD = 0;
     print "NDC caused record to not be added: $MNDC - Spaces in NDC\n";
  } elsif ( $MNDC !~ /^\d+$/ ) {
     $ADD = 0;
     print "NDC caused record to not be added: $MNDC - Not numeric\n";
  }
  
  print "sub isNDCBogus. Exit. ADD: $ADD\n" if ($debug);
  return ($ADD);
}

#______________________________________________________________________________

sub doesRecordExist2 {

  my ($dbin) = @_;
# my $debug++;

  # See if this record alreadys exists before replacing

  my ($recordexists);
  
  print "sub doesRecordExist2: Entry. dbin: $dbin\n" if ( $testing || $debug );

  my $select = "";
  my $where  = "";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};
  my $keys   = $DBKEYF{$dbin};
  my @keyarr = split(":", $keys);

  foreach $key (@keyarr) {
     if ($dbin eq "DCDBNAME") {
       $name = $key;
     }
     else {    
       ($p1, $name) = split(/^db/i, $key);
     }

     print "key: $key, name: $name\n" if ($testing || $debug);
     $tmp = "M${name}";
     $myhash{$key} = $$tmp;
     $select .= "$key, ";
     ($$tmp) = &StripJunk($$tmp);
     $noleadingzeros = $$tmp;
     $noleadingzeros += 0;    # Add zero, forcing numeric, checking for no leading zeros

     if ( $key !~ /SwVendor/i || $$tmp != $noleadingzeros ) {
       $where  .= "($key='$$tmp' OR $key='$noleadingzeros' || $key=$noleadingzeros) && ";
     } else {
       $where  .= "$key='$$tmp' && ";
     }
  }
  $select =~ s/, $//gi;
  $where  =~ s/ && $//gi;

  print "select: $select\nwhere: $where\n\n" if ($testing || $debug);

  $sql = qq#SELECT $select FROM $DBNAME.$TABLE WHERE $where#;

  print "sql:\n$sql\n\n" if ($testing || $verbose);
  
  $sthi = $dbi->prepare($sql) || die "Error preparing query" . $dbi->errstr;
  $sthi->execute() or die $DBI::errstr;
  my $numofrows = $sthi->rows;
  print "Number of rows found: $numofrows\n" if ($testing || $verbose);

  if ( $numofrows > 0 ) {
     $recordexists++;
      my @record = $sthi->fetchrow_array();
      print "\n>>> EXISTS: ", join(" - ", @record), " <<< \n\n";
  } else {
     $recordexists = 0;
  }
  $sthi->finish();

  print "sub doesRecordExist2: Exit. recordexists: $recordexists\n" if ( $testing || $verbose );
  print "- "x36, "\n" if ($testing || $verbose);

  return($recordexists);

}

sub DoesClaimExistIncoming {

  my ($dbin, $claimid) = @_;
# my $debug++;

  # See if claim exists in the incoming table before adding

  my $incomingexists = 0;
  
  print "sub doesRecordExist2: Entry. dbin: $dbin\n" if ( $testing || $debug );

  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  $sql = "SELECT id
            FROM $DBNAME.incoming
	   WHERE claimid = '$claimid'";

  print "sql:\n$sql\n\n"  if ($testing || $verbose);
  
  $sthi = $dbi->prepare($sql) || die "Error preparing query" . $dbi->errstr;
  $sthi->execute() or die $DBI::errstr;
  my $numofrows = $sthi->rows;
  print "Number of rows found: $numofrows\n" if ($testing || $verbose);

  if ( $numofrows > 0 ) {
     $incomingexists++;
      my @record = $sthi->fetchrow_array();
      print "\n>>> Incoming Exists: ", join(" - ", @record), " <<< \n\n";
  } else {
     $incomingexists = 0;
  }
  $sthi->finish();

  print "sub DoesClaimExistIncoming: Exit. ClaimExistsIncoming: $incomingexists\n" if ( $testing || $verbose );
  print "- "x36, "\n" if ($testing || $verbose);

  return($incomingexists);
}

#______________________________________________________________________________

sub Write_Record_to_Database2 {

  my ($dbin, $HASH) = @_;

# my $debug++;
# my $testing++;

  print "Write_Record_to_Database2: Entry. dbin: $dbin, ADD/UPDATE this record\n";
  # Now process the saved fields by writing them as a record to the database

  &SetdbVals2($dbin, $HASH);

  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $col = '';
  $sql  = "REPLACE INTO $DBNAME.$TABLE SET ";

  foreach $key (@GCNCOLUMNS) {
    $col = $key; # Set to allow change in field names for default cash
    
    next if ( $col =~ /dbDateAdded/i );
    next if ( $col =~ /incomingtbID/i );
#    next if ( $col =~ /Pharmacy_ID/i );

    $val = $$key;
    $val =~ s/\\$//g;
    $val =~ s/\\\s*$//g;
    $val =~ s/\\\s+/ /g;

    if ( $val =~ /\\/ ) {
       print "JDH- key: $col, val: $val\n";
       $sql .= qq#$col="$val", #;
    } elsif ( $val =~ /^NULL$/i ) {
       $sql .= "$col=NULL, ";
    } else {
       $sql .= qq#$col='$val', #;
    }
  }
  $sql =~ s/, $//;

  print "Write_Record_to_Database2 - sql:\n$sql\n"; # if ($testing || $debug);
 
  $rows = $dbi->do("$sql") or warn $DBI::errstr;
  $sqlcount++;

  print "$rows row(s) affected\n" if ($testing || $debug);
  $rowsaffected++;
  $SAVEROWS{$TABLE}++;

  printf "Write_Record_to_Database2: Exit. %4d: $rows rows affected\n", $sqlcount;
}

sub Write_Record_to_Claims {
  my $sth;
  my ($dbin, $HASH) = @_;

  print "Write_Record_to_Claims: Entry. dbin: $dbin, ADD/UPDATE this record\n";
  # Now process the saved fields by writing them as a record to the database

  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};
  $sql = "REPLACE INTO $DBNAME.$TABLE SET ";

  $MReconciledDate = NULL if ( !$MReconciledDate || $MReconciledDate =~ /^\s*$/ );

  if ( $MTotalAmountPaid != $MTotalAmountPaid_Remaining ) {
     $MTotalAmountPaid_Remaining = $MTotalAmountPaid;
  }
    
  foreach $fieldname (@CCNCOLUMNS) {
     next if ( $fieldname =~ /^DateAdded$/i );
     next if ( $fieldname =~ /^claimid$/i );
     next if ( $fieldname =~ /^Processed$/i );

     $var = "M" . $fieldname;

     $fieldtype = $$HASH{$fieldname};
     $fieldval  = $$var;

     ### Data Cleanup

     $fieldval =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white space
     $fieldval =~ s/ ''$//g;    # DELME? From NewTech code
     $fieldval =~ s/'/\\'/g;
     $fieldval =~ s/\\$//g;
     $fieldval =~ s/\\\s*$//g;
     $fieldval =~ s/\\\s+/ /g;
     $fieldval =~ s/|"//g;
     $fieldval =~ s/\\$//g;
     if ($fieldname =~ /EvoucherAmountPaid/i ) {
        $fieldval = 0.00 if ( $fieldval =~ /^\s*$/ );
     } elsif ( $fieldname =~ /RxNumber$|RxNumberExtended/i ) {
        $fieldval =~ s/^0+//g;
     }

     if ($fieldtype !~ /varchar/i ) {
       print "ZZZ: key: $fieldname, fieldtype: $fieldtype, fieldval: '$fieldval'\n" if ($incdebug);
     }

     if ($fieldtype =~ /^int|^bigint|^decimal/i && $fieldval =~ /^\s*$/ ) {
        $fieldval = -20000;
        print "SET: Setting $fieldname to val: $fieldval\n" if ($incdebug);
     }

     ### Build SQL Statement

     if ( $fieldval =~ /\\/ ) {
        $sql .= "$fieldname=\"$fieldval\", ";
     } elsif ( $fieldval =~ /^NULL$/i ) {
        $sql .= "$fieldname=NULL, ";
     } else {
        $sql .= "$fieldname='$fieldval', ";
     }
  }
  $sql =~ s/, $//;

  print "Write_Record_to_Claims - sql:\n$sql" if ($testing || $debug);
 
  $rows = $dbi->do("$sql") or warn $DBI::errstr;
  $sqlcount++;

  print "$rows row(s) affected\n"; # if ($testing || $debug);

  ### Select newly inserted claimid
  
  $sth = $dbi->prepare("SELECT LAST_INSERT_ID()") || die "Error preparing query" . $dbi->errstr;
  $sth->execute() or die $DBI::errstr;
  my ($claimid) = $sth->fetchrow_array();

  print "Write_Record_to_Claims: Exit. $sqlcount: $rows rows affected\n";

  return($claimid);
}  

sub DoesClaimExist {
  # See if this record alreadys exists before replacing

  my ($dbin) = @_;
  my $recordexists;
  
  print "sub DoesClaimExist: Entry." if ( $testing || $debug );

  my $claimid= 0;
  my $select = "claimid, ";
  my $where  = "";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};
  my $keys   = $DBKEYF{$dbin};
  my @keyarr = split(":", $keys);
#  my @keyarr = ("SwVendor","DateTransmitted","NCPDPNumber","DateOfService","RxNumber","TransactionCode","DateOfBirth","TotalAmountPaid","BinNumber","FillNumber");

  foreach $key (@keyarr) {
     $name = $key;

     print "key: $key, name: $name\n" if ($testing || $debug);
     $tmp = "M${name}";
     $myhash{$key} = $$tmp;
     $select .= "$key, ";
     ($$tmp) = &StripJunk($$tmp);
     $noleadingzeros = $$tmp;
     $noleadingzeros += 0;    # Add zero, forcing numeric, checking for no leading zeros

     if ( $key !~ /SwVendor/i || $$tmp != $noleadingzeros ) {
       $where  .= "($key='$$tmp' OR $key='$noleadingzeros' || $key=$noleadingzeros) && ";
     } else {
       $where  .= "$key='$$tmp' && ";
     }
  }
  $select =~ s/, $//gi;
  $where  =~ s/ && $//gi;

  print "select: $select\nwhere: $where\n\n" if ($testing || $debug);

  $sql = "SELECT $select
            FROM $DBNAME.$TABLE 
           WHERE $where";

  print "sql:\n$sql\n\n" if ($testing || $verbose);
  
  $sthi = $dbi->prepare($sql) || die "Error preparing query" . $dbi->errstr;
  $sthi->execute() or die $DBI::errstr;
  my $numofrows = $sthi->rows;
  print "Number of rows found: $numofrows\n" if ($testing || $verbose);

  if ( $numofrows > 0 ) {
     $recordexists++;
     my @record = $sthi->fetchrow_array();
     $claimid = $record[0];
  } else {
     $recordexists = 0;
  }
  $sthi->finish();

  print "sub doesClaimExist: Exit. recordexists: $recordexists- $claimid\n" if ( $testing || $verbose );
  print "- "x36, "\n" if ($testing || $verbose);

  return($recordexists, $claimid);
}

#______________________________________________________________________________

sub print_incoming_record2 {

  print "-"x72, "\n";
  print "sub print_incoming_record2. Entry.\n";


  my $output;
  $output = "";

  foreach $COL (@GCNCOLUMNS) {
     ($VAR   = $COL) =~ s/^db/M/i;
     ($JMVAR = $COL) =~ s/^db/JM/i;
     $VAL    = $$VAR;
     $VAL    =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white space
     if ( $VAL =~ /^NULL$/i ) {
        $VAL = NULL;
     }
     $output .= sprintf("%-36s : %s ", $VAR, $VAL);
     if ( $$JJMVAR ) {
        $JMVAL   = $$JMVAR;
        if ( $JMVAL =~ /^NULL$/i ) {
           $JMVAL = NULL;
        }
        $output .= "\t($JMVAL)";
     }
     $output .= "\n";
  }

  print "sub print_incoming_record2. Exit. output:\n";
  print "$output\n";

  print "-"x72, "\n";

}

#______________________________________________________________________________

sub SetdbVals2 {

  my ($dbin, $HASH) = @_;

# my $debug++;
# my $incdebug++;

  print "-"x80, "\n";
  print "sub SetdbVals2: Entry.\n" if ($incdebug);

  my $DBNAME  = $DBNAMES{"$dbin"};
  my $TABLE   = $DBTABN{"$dbin"};
  my $col;

  foreach $key (sort keys %$HASH) {
    undef $key;
  }

  $dbReconciledDate    = "NULL" if ( !$dbReconciledDate || $dbReconciledDate =~ /^\s*$/ );

  foreach $COL (@GCNCOLUMNS) {
     if ($COL =~ /^db/i) {
       ($VAR = $COL) =~ s/^db/M/i;		# HERE I AM!!!!!!!!!!!!!!!!!!!!!
     }
     else {
       $VAR = "M" . $COL;     # Set to match variable names correctly for default cash
#       $COL = "db" . $COL;
     }

     $VAL  = $$VAR;
     $VAL  =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing white space
     $VAL  =~ s/ ''$//g;    # DELME? From NewTech code
     $VAL  =~ s/'/\\'/g;
     $VAL  =~ s/\\$//g;
     $VAL  =~ s/'|"//g;
     if (      $VAR =~ /EvoucherAmountPaid/i ) {
        $VAL = 0.00 if ( $VAL =~ /^\s*$/ );
     } elsif ( $VAR =~ /RxNumber$|RxNumberExtended/i ) {
        print "1. YELLOW! VAR: $VAR, doldolVAR: $VAL\n" if ($debug);
        $VAL =~ s/^0+//g;
        print "2. YELLOW! VAR: $VAR, doldolVAR: $VAL\n" if ($debug);
     }
     $$COL = $VAL;
  }

#  print "PRINT out non-varchar fields:\n";
#  print "-----------------------------\n";

  print "$dbSwVendor - TAP: $dbTotalAmountPaid, TAP_R: $dbTotalAmountPaid_Remaining\n" if ($testing || $debug);
  if ( $dbTotalAmountPaid != $dbTotalAmountPaid_Remaining ) {
     $dbTotalAmountPaid_Remaining = $dbTotalAmountPaid;
  }

  foreach $key (sort keys %$HASH) {
    $col = $key;      # Set to allow change in field names for default cash
    if ($key !~ /^db/i) {
      if ($key !~ /incomingtbID/i || $key !~ /claimid/i || $key !~ /Pharmacy_ID/i) {
        $key = "db" . $key; # Add "db" to field names to match variables for default cash
      }
    }

    $fieldtype = $$HASH{$col};
    $fieldval  = $$key;
    next if ( $fieldtype =~ /varchar/i );

    $jfmt = "ZZZ- %-28s | %-15s | %s\n";
    $fieldvalstring = sprintf("%20s", $fieldval);
    printf("$jfmt", $key, $fieldtype, $fieldvalstring);
#    print "ZZZ: key: $key, fieldtype: $fieldtype, fieldval: '$fieldval' ($fieldvalstring)\n" if ($incdebug);

    if ( $fieldtype =~ /^int|^bigint|^decimal/i && $fieldval =~ /^\s*$/ ) {
       $$key = -20000;
       print "SET: Setting $key to val: $$key\n"  if ($incdebug);
    }
  }

  print "sub SetdbVals2: Exit.\n" if ($incdebug);
  print "-"x80, "\n";

}

#______________________________________________________________________________

sub purge_this_file_from_db {

  my ($FILE) = @_;

  print "-"x80, "\n";
  print "sub purge_this_file_from_db. Entry. FILE: $FILE\n";
 
  my $reccnt = 0;
  my $dbin   = "MCDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};
  
  my $sql = "";
  
  $sql = " DELETE FROM $DBNAME.$TABLE WHERE A5_FileName='$FILE' ";
  
  print "sql:\n$sql\n\n" if ($debug);
  
  $sth = $dbx->prepare("$sql");
  $reccnt = $sth->execute;
  $sth->finish();

  print "sub purge_this_file_from_db. Exit. Records deleted: $reccnt\n";
  print "-"x80, "\n";

}

#______________________________________________________________________________

sub read_file_format {

# my $debug++;
# my $verbose++;

  print "sub read_file_format. Entry.\n" if ($debug);

  my $dbin   = "CIDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  my $sql = "SELECT FORD, CNUM, REQF, FNAME, PIC, FBEG, FLEN, FEND, FDESC FROM $DBNAME.$TABLE ";

  if ( $debug ) {
#    print "-"x80, "\n";
     print "sql:\n$sql\n\n";
  }

  $strff = $dbx->prepare("$sql");
  $strff->execute;

  my $NumOfRows = $strff->rows;
# print "sub read_file_format: Number of rows found: $NumOfRows\n" if ($debug);

  while ( my @row = $strff->fetchrow_array() ) {

    my ( $FORD, $CNUM, $REQF, $FNAME, $PIC, $FBEG, $FLEN, $FEND, $FDESC ) = @row;

    $key = $FORD;

    $FORDs{$key}  = $FORD;
    $CNUMs{$key}  = $CNUM;
    $REQFs{$key}  = $REQF;
    $FNAMEs{$key} = $FNAME;
    $PICs{$key}   = $PIC;
    $FBEGs{$key}  = $FBEG;
    $FLENs{$key}  = $FLEN;
    $FENDs{$key}  = $FEND;
    $FDESCs{$key} = $FDESC;

    $RevCNUMs{$CNUM} = $key;

    #------------------------------------------

    my $DEC = 0;

    if ( $PIC =~ /PIC\s*9/i ) {
       my $p1 = 0;
       my $p2 = 0;

       if ( $PIC =~ /V/i ) {
          ($p1, $p2) = split(/PIC\s*9/i, $PIC, 2);    # p1: blank, p2: "(06)V9999" for "PIC 9(06)V9999"
          ($p1, $p2) = split(/V/i, $p2, 2);            # p1: (06),  p2: 9999
          $p1 =~ s/$lparen|$rparen//g;
          
          if ( $p2 =~ /$lparen/ ) {
             $p2 =~ s/9\s*$lparen//g;
             $p2 =~ s/$lparen|$rparen//g;
          } else {
             $p2 = length($p2);
          }
          
          $p1 =~ s/^0+//g;

          $DEC = $p2;
       } else {
          ($p1, $p2) = split(/PIC\s*9/i, $PIC, 2);    # p1: blank, p2: "(06)V9999" for "PIC 9(06)V9999"
          $p2 =~ s/9\s*$lparen//g;
          $p2 =~ s/$lparen|$rparen//g;
       }
    }
    $DECs{$key} = $DEC;

    #------------------------------------------

  }
  $strff->finish();

  print "sub read_file_format. Exit. NumOfRows: $NumOfRows\n" if ($debug);

}

#______________________________________________________________________________

sub readCfieldnames {

  print "sub readCfieldnames: Entry.\n" if ($debug);

  my $dbin   = "MCDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  $sql = "show columns from $DBNAME.$TABLE";

  print "-"x80, "\n";
  print "sql:\n$sql\n\n" if ($debug);

  $sthrCfn = $dbx->prepare("$sql");
  $sthrCfn->execute;

  my $NumOfRows = $sthrCfn->rows;

  while ( my @row = $sthrCfn->fetchrow_array() ) {

     my ($name, $type, $rest) = @row;
     if ( $name =~ /_/ ) {
        ($p1, $p2) = split("_", $name, 2);
     } else {
        $p1 = $name;
     }
     $CNames{$p1} = $name;

  }
  $sthrCfn->finish();
  print "sub readCfieldnames: Exit.\n" if ($debug);

}

#______________________________________________________________________________

sub Remove_Reversals {

#  my $debug++;

  my ($FILE) = @_;

  my $dbin   = "MCDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  my $sql = "";
  $sql = "UPDATE $DBNAME.$TABLE SET A3_Code='RVL', A3_Reason='Reversal' WHERE C17_Claim_Type = 'R' && A5_FileName='$FILE' ";

  if ( $debug ) {
    print "-"x80, "\n";
    print "RR UPDATE sql:\n$sql\n\n";
  }
  
  $sth = $dbx->prepare("$sql");
  $NumOfRows = $sth->execute;

  if ( $debug ) {
     print "sub RR UPDATE: Number of rows found: $NumOfRows\n";
  }
  $sth->finish();

  #-----------------------------------------

  $sql = "SELECT C6_Product_Service_ID, C8_Quantity_Dispensed, C9_Date_of_Service, C10_Service_Provider_ID, C12_Prescription_Rx_Number, C13_Fill_Number, C21_Insurance_Code FROM $DBNAME.$TABLE WHERE C17_Claim_Type = 'R' && A5_FileName='$FILE' ";

  if ( $debug ) {
     print "-"x80, "\n";
     print "RR SELECT sql:\n$sql\n\n";
  }
  
  $sth = $dbx->prepare("$sql");
  $NumOfRows = $sth->execute;
  print "sub RR SELECT: Number of rows found: $NumOfRows\n" if ($debug);
  while ( my @row = $sth->fetchrow_array() ) {

    my ($C6_Product_Service_ID, $C8_Quantity_Dispensed, $C9_Date_of_Service, $C10_Service_Provider_ID, $C12_Prescription_Rx_Number, $C13_Fill_Number, $C21_Insurance_Code) = @row;
    $key = "$C6_Product_Service_ID##$C8_Quantity_Dispensed##$C9_Date_of_Service##$C10_Service_Provider_ID##$C12_Prescription_Rx_Number##$C13_Fill_Number##$C21_Insurance_Code";
    $CHECKTHESE{$key} = $C9_Date_of_Service;
#   print "JDH- key: $key\n";
  }
  $sth->finish();

  #-----------------------------------------
  
  foreach $key (sort { $CHECKTHESE{$a} cmp $CHECKTHESE{$b} } keys %CHECKTHESE) {

     ($C6_Product_Service_ID, $C8_Quantity_Dispensed, $C9_Date_of_Service, $C10_Service_Provider_ID,
      $C12_Prescription_Rx_Number, $C13_Fill_Number, $C21_Insurance_Code) = split("##", $key, 7);

     $Neg_C8 = $C8_Quantity_Dispensed * -1.0;
#    print "JJJ- C8_Quantity_Dispensed: $C8_Quantity_Dispensed, Neg_C8: $Neg_C8\n";

     $ptr++;
     $tmp = sprintf("%04d", $ptr);

     $sql  = " UPDATE $DBNAME.$TABLE SET A3_Code='RVL', A3_Reason='Reversal', A4_Comments='$tmp' ";
     $sql .= " WHERE 
             C6_Product_Service_ID      = '$C6_Product_Service_ID'
          && C10_Service_Provider_ID    = '$C10_Service_Provider_ID'
          && C12_Prescription_Rx_Number = $C12_Prescription_Rx_Number
          && C8_Quantity_Dispensed      = $Neg_C8
          && (A3_Code <> 'RVL' || A3_Code IS NULL)
          && C17_Claim_Type = 'P'
          && A5_FileName='$FILE'
          && (C9_Date_of_Service = $C9_Date_of_Service || C13_Fill_Number = $C13_Fill_Number )
          ORDER BY C9_Date_of_Service ASC
          LIMIT 1 ";

     if ( $debug ) {
        print "-"x80, "\n";
        print "RR LOOP $ptr UPDATE sql:\n$sql\n\n";
     }
     $sth = $dbx->prepare("$sql");
     $NumOfRows = $sth->execute;
     $NumOfRows = 0 if ( $NumOfRows =~ /0E0/i );
    
     print "sub RR LOOP UPDATE: Number of rows found: $NumOfRows\n" if ($debug);

     if ( $NumOfRows == 0 ) {

        $sql = "UPDATE $DBNAME.$TABLE SET A3_Code='RVLNM', A3_Reason='Reversal No Match', A4_Comments='$tmp' ";
        $sql .= " WHERE 
             C6_Product_Service_ID      = $C6_Product_Service_ID
          && C10_Service_Provider_ID    = $C10_Service_Provider_ID
          && C12_Prescription_Rx_Number = $C12_Prescription_Rx_Number
          && C8_Quantity_Dispensed      = $C8_Quantity_Dispensed
          && (A4_Comments IS NULL)
          && C17_Claim_Type = 'R'
          && A5_FileName='$FILE'
          && (C9_Date_of_Service = $C9_Date_of_Service || C13_Fill_Number = $C13_Fill_Number )
          ORDER BY C9_Date_of_Service ASC
          LIMIT 1 ";

        if ( $debug ) {
           print "-"x80, "\n";
           print "RR UPDATE sql:\n$sql\n\n";
        }
  
        $sth = $dbx->prepare("$sql");
        $NumOfRows = $sth->execute;
        print "sub RR UPDATE: Number of rows found: $NumOfRows\n" if ($debug);
        $sth->finish();
     }
     
  }
  if ( $debug ) {
     print "-"x80, "\n";
     print "-"x80, "\n";
  }
}


sub Remove_Drugs_Not_Eligible {

  my ($NewestDOS, $FILE) = @_;

#  my $debug++;
#  my $incdebug++;
  &load_otc_exclusions;


  if ( $debug ) {
     print "="x96, "\n";
     print "="x96, "\n";
     print "Now remove drugs that are not eligble to be sent.\n";
     print "NewestDOS: $NewestDOS\n";
     print "FILE: $FILE\n";

     if ( $NewestDOS == 0 || $NewestDOS =~ /^\s*$/ ) {
        print "NewestDOS WAS: $NewestDos. ";
        $NewestDOS = time();
        print "Setting to $NewestDOS\n\n";
     }
  }
  
  my $dbin   = "MCDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};
  
  #--------------------------
  
  $sql = "
  SELECT C6_Product_Service_ID,C8_Quantity_Dispensed,C18_Days_Supply,
         A1_Provider,C2_Carrier,C3_Contract,C4_Group,C9_Date_of_Service,C10_Service_Provider_ID,
         C12_Prescription_Rx_Number, C13_Fill_Number,C21_Insurance_Code,A8_Unique_Value
  FROM $DBNAME.$TABLE
  WHERE A5_FileName='$FILE'
";
  
  if ( $debug ) {
     print "-"x80, "\n";
     print "Remove_Drugs_Not_Eligible: No Medispan. sql:\n$sql\n";
  }
  
  $sth = $dbx->prepare("$sql");
  $NumOfRows = $sth->execute;
  
  my $NumOfRows = $sth->rows;
  
  print "Number of rows found: $NumOfRows<br>\n\n" if ($incdebug);

  if ( $NumOfRows > -1 ) {

     if ( $NewestDOS !~ /^\s*$/ && $NewestDOS > 0 ) {
       my ($month) = substr($NewestDOS, 4, 2);
       my ($day  ) = substr($NewestDOS, 6, 2);
       my ($year ) = substr($NewestDOS, 0, 4);
       my $hours = 0;
       my $min   = 0;
       my $sec   = 0;
       $month--;	# for the call to timelocal
       print "NewestDOS: $NewestDOS, month: $month, day: $day, year: $year\n" if ($debug);
       
       my $now = timelocal($sec,$min,$hours,$day,$month,$year); 
       print "NewestDOS: $NewestDOS, now: $now\n";
     } else {
        $now = time();
        print "now: $now\n" if ($debug);
     }

     while ( my @row = $sth->fetchrow_array() ) {
#          $rx_otc_indicator_code,$tcgpi_name,$route_of_administration,
       my ($C6_Product_Service_ID,$C8_Quantity_Dispensed,$C18_Days_Supply,
           $A1_Provider,$C2_Carrier,$C3_Contract,$C4_Group,$C9_Date_of_Service,$C10_Service_Provider_ID,
           $C12_Prescription_Rx_Number, $C13_Fill_Number,$C21_Insurance_Code,$A8_Unique_Value) = @row;

       # Process this row here:
       $Reason   = $A3_Reason;
       $Comments = $A4_Comments;

       #------------------

#      if DOS > 150 days ago INELIGIBLE!!!! 

       my $ExcludeAfterDays = 150;

       my $ExcludeAfterSecs = $ExcludeAfterDays * 24 * 60 * 60;

       my ($month) = substr($C9_Date_of_Service, 4, 2);
       my ($day  ) = substr($C9_Date_of_Service, 6, 2);
       my ($year ) = substr($C9_Date_of_Service, 0, 4);
       my $hours = 0;
       my $min   = 0;
       my $sec   = 0;
       $month--;	# for the call to timelocal
       print "C9_DOS: $C9_Date_of_Service, month: $month, day: $day, year: $year\n" if ($debug);
       
       my $C9_time = timelocal($sec,$min,$hours,$day,$month,$year); 
       print "C9_Date_of_Service: $C9_Date_of_Service, C9_time: $C9_time\n";
       
       my $age = $now - $C9_time;
       print "age: $age, ExcludeAfterSecs: $ExcludeAfterSecs\n" if ($debug);
       if ( $age > $ExcludeAfterSecs ) {
          print "EXCLUDE!\n" if ($debug);
          $Reason   .= "Age over $ExcludeAfterDays days: ";
          $Comments .= "";
       } else {
          print "Keep!\n" if ($debug);
       }

       #------------------
       print "C6_Product_Service_ID  : $C6_Product_Service_ID (", substr($C6_Product_Service_ID, 0, 5), ")\n";
       my $otc  = $Lookup_MSBorG_OTC{$C6_Product_Service_ID};
       if ( substr($C6_Product_Service_ID, 0, 5) <= 0 ) {
          $Reason   .= "NDC - No MFG: ";
          $Comments .= "";
       }
       print "C6_Product_Service_ID  : $C6_Product_Service_ID (", length($C6_Product_Service_ID), ")\n";
       if ( length($C6_Product_Service_ID) < 9 ) {
          $Reason   .= "NDC < 9 digits: ";
          $Comments .= "";
       }

       if ($otc eq 'Y' && !$exclusions{$C6_Product_Service_ID}) {
          $Reason   .= "OTC";
          $Comments .= "";
       }
       #------------------
       print "C18_Days_Supply        : $C18_Days_Supply\n";
       if ( $C18_Days_Supply < 3 ) {
          $Reason   .= "Days Supply < 3: ";
          $Comments .= "";
       } elsif ( $C18_Days_Supply > 180 ) {
          $Reason   .= "Days Supply > 180: ";
          $Comments .= "";
       }
       #------------------
       print "C8_Quantity_Dispensed  : $C8_Quantity_Dispensed\n";
       if ( $C8_Quantity_Dispensed <= 0 ) {
          $Reason   .= "Quantity Dispensed <= 0: ";
          $Comments .= "";
       } elsif ( $C8_Quantity_Dispensed > 960 ) {
          $Reason   .= "Quantity Dispensed > 960: ";
          $Comments .= "";
       }
#####################################################################


       $Reason   =~ s/:\s*$//g;
       $Comments =~ s/:\s*$//g;

       print "Reason                 : $Reason\n";
       print "Comments               : $Comments\n";
       print "-"x96, "\n";

       if ( $Reason !~ /^\s*$/ || $Comments !~/^\s*$/ ) {
          my $sql = " UPDATE $DBNAME.$TABLE ";
          $sql .= " SET $DBNAME.$TABLE.A3_Code='NotEligible', A3_Reason='$Reason', A4_Comments='$Comments' ";
          $sql .= " WHERE ";
	  $sql .= "    A5_FileName='$FILE'";
          $sql .= " && A1_Provider='$A1_Provider' ";
          $sql .= " && C2_Carrier='$C2_Carrier' ";
          $sql .= " && C3_Contract='$C3_Contract' ";
          $sql .= " && C4_Group='$C4_Group' ";
          $sql .= " && C9_Date_of_Service=$C9_Date_of_Service ";
          $sql .= " && C10_Service_Provider_ID=$C10_Service_Provider_ID ";
          $sql .= " && C12_Prescription_Rx_Number=$C12_Prescription_Rx_Number ";
          $sql .= " && C13_Fill_Number=$C13_Fill_Number ";
          $sql .= " && C21_Insurance_Code='$C21_Insurance_Code' ";
          $sql .= " && A8_Unique_Value=$A8_Unique_Value";

          if ( $debug ) {
             print "-"x80, "\n";
             print "sql:\n$sql\n\n";
          }

          $stha = $dbx->prepare("$sql");
          $NumOfRows = $stha->execute;
         
          $stha->finish();

       }
     }
  }
  
  print "sub Remove_Drugs_Not_Eligible. Exit. NumOfRows: $NumOfRows\n" if ($debug);
  print "="x96, "\n";
  print "="x96, "\n";
  
  $sth->finish();

}

#______________________________________________________________________________

sub Remove_Claims {

#  my $debug++;

  my ($FILE) = @_;


# $removeclaims{"RRX011"} = "2016-03-21: Mark said to start sending RRX011 again";
 $removeclaims{"RRX011"} = "2016-07-01: Mark said to remove RRX011 again";
 $removeclaims{"RRX024"} = "2016-06-02: Mark said not to send RRX024 claims";


  print "\n", "-"x72, "\n";
  print "sub Remove_Claims. Entry. FILE: $FILE\n" if ($debug);

  my $dbin   = "MCDBNAME";
  my $DBNAME = $DBNAMES{"$dbin"};
  my $TABLE  = $DBTABN{"$dbin"};

  foreach $key (sort keys %removeclaims) {
     print qq#$key - $removeclaims{"$key"}\n#;

     my $sql = "";
     $sql = qq#
UPDATE $DBNAME.$TABLE
SET A3_Code='NotEligible', A3_Reason='$key'
WHERE A1_Provider='RxC' && C244_Hierarchy_Level_3='$key' && A5_FileName='$FILE'
#;
   
     if ( $debug ) {
       print "-"x80, "\n";
       print "Remove_Claims UPDATE sql:\n$sql\n\n";
     }
     
     $sth = $dbx->prepare("$sql");
     $NumOfRows = $sth->execute;
   
     if ( $debug ) {
        print "sub Remove_Claims UPDATE: Number of rows found: $NumOfRows\n";
     }
     $sth->finish();
  }

  #-----------------------------------------
  if ( $debug ) {
     print "-"x80, "\n";
     print "-"x80, "\n";
  }
  print "sub Remove_Claims. Exit.\n" if ($debug);

}

#______________________________________________________________________________

sub set835 {

# my $debug++;
# my $verbose++;
# my $incdebug++;

  my $Check_ID = shift @_;

  my ($DateAdded)     = "0";
  my ($my835Filename) = "";

  print "<hr>sub set835. Entry. CheckNumber: $CheckNumber, Q: $Q, SFDATE2: $SFDATE2<br>\n" if ($debug);

  $DBNAME = 'ReconRxdb';
  $TABLE  = 'Checks';

  my $sql  = qq#
    SELECT R_JAddedDate, R_Filename_Formatted
    FROM $DBNAME.$TABLE
    WHERE Check_ID = $Check_ID
  #;

  print "set835: sql:<br>$sql<br>\n" if ($debug);

  $stb = $dbx->prepare($sql);
  $numofrows = $stb->execute;
  print "set835: numofrows: $numofrows<br>\n" if ($debug);

  if ( $numofrows <= 0 ) {
    my $jout = "set835: No records found for this Check Number!";
    print "<hr>$jout<hr>\n" if ($debug);
  } else {
    my $ptr = 0;
    while (my @row = $stb->fetchrow_array()) {
       ($R_JAddedDate, $my835Filename) = @row;
    }
  }
  $stb->finish();

  my @pcs = split(" ", $R_JAddedDate, 2);
  $DateAdded = $pcs[0];
  print "sub set835. Exit. DateAdded: $DateAdded<br>my835Filename = $my835Filename<hr>\n" if ($debug);

  return ($DateAdded, $my835Filename);
}

#______________________________________________________________________________

sub read_Other_Sources_835s {

# my $debug++;

  if ( $debug ) {
     print "<hr size=4 color=green>\n";
     print "sub read_Other_Sources_835s. Entry.\n";
  }
 
  my $sql = qq#
SELECT Other_Source_TPP_ID, Other_Source, Other_Source_REF01, Other_Source_Use_Adjustment_Description
FROM ReconRxDB.Other_Sources_835s
#;
  
  print "read_Other_Sources_835s sql:<br>\n$sql<br><br>\n\n" if ($debug);
  
  my $sth8;
  $sth8 = $dbx->prepare($sql);
  $sth8->execute();
   
  my $NumOfRowsFound = $sth8->rows;
  print "Number of rows found: " . $sth8->rows . "<br>\n" if ($debug);

  if ( $NumOfRowsFound > 0 ) {
    if ( $debug ) {
       print "<table border=5>\n";
       print "<tr>";
       print "<td>Other_Source_TPP_ID</td>";
       print "<td>Other_Source</td>";
       print "<td>Other_Source_REF01</td>";
       print "<td>Other_Source_Use_Adjustment_Description</td>";
       print "</tr>\n";
    }
    while ( my @row = $sth8->fetchrow_array() ) {
       ($Other_Source_TPP_ID, $Other_Source, $Other_Source_REF01, $Other_Source_Use_Adjustment_Description) = @row;
       $key = $Other_Source_TPP_ID;
       $Other_Source_TPP_IDs{$key} = $Other_Source_TPP_ID;
       $Other_Sources{$key}        = $Other_Source;
       $Other_Source_REF01s{$key}  = $Other_Source_REF01;
       $Other_Source_Use_Adjustment_Descriptions{$key}  = $Other_Source_Use_Adjustment_Description;
  
       if ( $debug ) {
         print "<tr>";
         print "<td>$Other_Source_TPP_ID</td>";
         print "<td>$Other_Source</td>";
         print "<td>$Other_Source_REF01</td>";
         print "<td>$Other_Source_Use_Adjustment_Description</td>";
         print "</tr>";
       }
    }
    if ( $debug ) {
       print "</table>";
    }
  }
  $sth8->finish();

  if ( $debug ) {
     print "sub read_Other_Sources_835s. Exit. NumOfRowsFound: $NumOfRowsFound<br>\n";
     print "<hr size=4 color=green>\n";
  }

}

#______________________________________________________________________________

sub read_Other_Sources_835s_Lookup {

# my $debug++;

  if ( $debug ) {
     print "<hr size=4 color=green>\n";
     print "sub read_Other_Sources_835s_Lookup. Entry.\n";
  }
 
  my $sql = qq#
SELECT Lookup_Other_Source_TPP_ID,Lookup_BIN_REF,Lookup_TPP_Display_on_Remit_TPP_ID,Lookup_TPP_Display_on_Remit
FROM ReconRxDB.Other_Sources_835s_Lookup
#;
  
  print "sql:<br>\n$sql<br><br>\n\n" if ($debug);

  my $sth8;
  $sth8 = $dbx->prepare($sql);
  $sth8->execute();
   
  my $NumOfRowsFound = $sth8->rows;
  print "Number of rows found: " . $sth8->rows . "<br>\n" if ($debug);

  if ( $NumOfRowsFound > 0 ) {
    if ( $debug ) {
       print "<table border=5>\n";
       print "<tr>";
       print "<td>Lookup_Other_Source_TPP_ID</td>";
       print "<td>Lookup_BIN_REF</td>";
       print "<td>Lookup_TPP_Display_on_Remit_TPP_ID</td>";
       print "<td>Lookup_TPP_Display_on_Remit</td>";
       print "</tr>\n";
    }
    while ( my @row = $sth8->fetchrow_array() ) {
       ($Lookup_Other_Source_TPP_ID,$Lookup_BIN_REF,$Lookup_TPP_Display_on_Remit_TPP_ID,$Lookup_TPP_Display_on_Remit) = @row;

       if ( $Lookup_BIN_REF =~ /^\d+$/ ) {
          $Lookup_BIN_REF = sprintf("%06d", $Lookup_BIN_REF);
       }
       $key = "$Lookup_Other_Source_TPP_ID##$Lookup_BIN_REF";

       $Lookup_Other_Source_TPP_IDs{$key}         = $Lookup_Other_Source_TPP_ID;
       $Lookup_BIN_REFs{$key}                     = $Lookup_BIN_REF;
       $Lookup_TPP_Display_on_Remit_TPP_IDs{$key} = abs($Lookup_TPP_Display_on_Remit_TPP_ID);
       $Lookup_TPP_Display_on_Remits{$key}        = $Lookup_TPP_Display_on_Remit;
  
       if ( $debug ) {
          print "<tr>";
          print "<td>$key</td>\n";
          print "<td>$Lookup_Other_Source_TPP_ID</td>\n";
          print "<td>$Lookup_BIN_REF</td>\n";
          print "<td>$Lookup_TPP_Display_on_Remit_TPP_ID</td>\n";
          print "<td>$Lookup_TPP_Display_on_Remit</td>\n";
          print "</tr>\n";
       }
    }
    if ( $debug ) {
       print "</table>";
    }
  }
  $sth8->finish();

  if ( $debug ) {
    print "sub read_Lookup_BIN_REFs_835s_Lookup. Exit. NumOfRowsFound: $NumOfRowsFound<br>\n";
    print "<hr size=4 color=green>\n";
  }

}

#______________________________________________________________________________

sub check_Other_Source {

# my $debug++;

  my ($R_TPP_PRI, $R_TPP, $R_REF01_Name, $R_REF02_Value, $R_OC_Actual_TPP_ID) = @_;
  my $R_TPP_return = $R_TPP;
  my $pc = "";
  my $skip = 0;
  my $OtherSource = 0;
  my $Display_TPPID = "";
  my $Display_on_Remits = "";

  print "<hr>sub check_Other_Source. Entry. R_TPP: $R_TPP R_TPP_PRI: $R_TPP_PRI<br>\n" if ($debug);
# print "GREEN- R_TPP_PRI: $R_TPP_PRI<br>Other_Source_TPP_IDs(): $Other_Source_TPP_IDs{$R_TPP_PRI}<hr>\n";
  if ( !$Other_Source_TPP_IDs{$R_TPP_PRI} ) {
    print "Skipping... TPP_ID not in list<br>\n" if ($debug);
    $skip++;
  } elsif ( $R_REF01_Name =~ /^\s*$/ ) {
    print "REF01 is blank. Skipping...<br>\n" if ($debug);
  } else {
    if ( $debug ) {
       print "DOIT!<br>\n";
       print "<table border=1>\n";
       print "<tr><td>R_TPP_PRI</td> <td> $R_TPP_PRI</td></tr>\n";
       print "<tr><td>R_TPP</td> <td> $R_TPP</td></tr>\n";
       print "<tr><td>R_REF01_Name</td> <td> $R_REF01_Name</td></tr>\n";
       print "<tr><td>R_REF02_Value</td> <td> $R_REF02_Value</td></tr>\n";
       print "<tr><td>R_OC_Actual_TPP_ID</td> <td> $R_OC_Actual_TPP_ID</td></tr>\n";
       print "</table>\n";
    }

    foreach $pc (sort keys %Lookup_Other_Source_TPP_IDs) {

      ($p1, $p2) = split(/##/, $pc, 2);
      my $OSREF01 = $Other_Source_REF01s{$p1};
      if ( $debug ) {
         print "<hr>\n";
         print "pc: $pc, OSREF01: $OSREF01<br>\n";
      }
      if ( $pc =~ /^$R_TPP_PRI/ && $OSREF01 =~ /^$R_REF01_Name/i ) {
         $LKEY1 = "$R_TPP_PRI##$R_REF02_Value";
         $LKEY2 = sprintf("%s##%06d", $R_TPP_PRI, $R_REF02_Value);
         print "MATCH! pc: $pc, OSREF01: $OSREF01, LKEY1: $LKEY1, LKEY2: $LKEY2<br>\n" if ($debug);

         $Display_TPPID = $Lookup_TPP_Display_on_Remit_TPP_IDs{$LKEY1} ||
                          $Lookup_TPP_Display_on_Remit_TPP_IDs{$LKEY2};
         $Display_TPPID = abs($Display_TPPID);

         $Display_on_Remits = $Lookup_TPP_Display_on_Remits{$LKEY1} ||
                              $Lookup_TPP_Display_on_Remits{$LKEY2}; 

         $R_TPP_return = $Lookup_TPP_Display_on_Remits{$LKEY1} || $Lookup_TPP_Display_on_Remits{$LKEY2};
         $OtherSource++;

         last;
      }
    }
  }

  if ( $skip ) {
     print "SKIPPING...<br>\n" if ($debug);
  } elsif ( $R_TPP_return =~ /^\s*$/ ) {
     $R_TPP_return = $R_TPP;
     print "OVERRIDE!<br>\n" if ($debug);
  } else {
     print "FOUND IT! R_TPP_return: $R_TPP_return<hr size=8 color=red noshade>\n" if ($debug);
  }
  print "sub check_Other_Source. Exit. R_TPP_return: $R_TPP_return, OtherSource: $OtherSource<hr>\n" if ($debug);

  return ($R_TPP_return, $OtherSource, $Display_TPPID, $Display_on_Remits);

}

#______________________________________________________________________________

sub read_Unique_FTP_Filenames_quick {

# Load all Unique Check Numbers into %ThisRun_FTP_Filenames

#  my $debug++;
#  my $verbose++;

  print "-"x96, "\n" if ($debug);
  print "\nsub read_Unique_FTP_Filenames_quick: Entry. time(): ", time(), "\n" if ( $debug );
  &print_time_to_here("Entry. read_Unique_FTP_Filenames_quick");

  my $DBNAME  = "ReconRxDB";
  my $TABLE   = "unique_r_ftp_filenames";

#______________________________________________________________________________

  my $sql = qq#
SELECT DISTINCT R_FTP_Filename
FROM ReconRxDB.unique_r_ftp_filenames
ORDER BY R_FTP_Filename
#;

  print "sql:\n$sql\n";

  my $sthx  = $dbx->prepare("$sql");
  $sthx->execute;

  my $NumOfRows = $sthx->rows;
  print "Number of Unique Check Number rows found: $NumOfRows\n" if ($debug);

  if ( $NumOfRows > -1 ) {
     while ( my @row = $sthx->fetchrow_array() ) {
       foreach $pc (@row) {
          $ThisRun_FTP_Filenames{"$pc"}++;
#         print "added: $pc\n" if ($debug);
       }
     }
  } else {
     print qq#No Data found!\n\n#;
  }
  $sthx->finish;

  &print_time_to_here("Exit. read_Unique_FTP_Filenames_quick");
  print "sub read_Unique_FTP_Filenames_quick: Exit. time(): ", time(), "\n" if ( $debug );
  print "-"x96, "\n" if ($debug);

}

#______________________________________________________________________________

sub read_first_remit_dates_table {

# my $debug++;

  print "sub read_first_remit_dates_table. Entry. time(): ", time(), "<br>\n" if ($debug);

  &print_time_to_here("Entry. read_first_remit_dates_table");

  # Put in data in a hash

  my $sql  = qq#
SELECT DateAdded, NCPDP, BIN, FirstRemitDate
FROM ReconRxdb.`first_remit_dates`
#;

  print "\nsql:\n$sql\n\n" if ($debug);

  my $sthx  = $dbx->prepare("$sql") or warn $DBI::errstr;
  $NumOfRows = $sthx->execute;
  print "Number of rows found: $NumOfRows\n" if ($debug);

  while ( my @row = $sthx->fetchrow_array() ) {
    ($date_added, $NCPDP, $BIN, $first_remit_date) = @row;

     $key = "$NCPDP##$BIN";
     $first_remit_dates{"$key"}       = $first_remit_date;
     $first_remit_date_addeds{"$key"} = $date_added;
  }
  $sthx->finish;

  &print_time_to_here("Exit. read_first_remit_dates_table");

  print "\nsub read_first_remit_dates_table. Exit. time(): ", time(), ". rows found: $NumOfRows\n" if ( $debug );

}

sub do835Verification {
  my ($file, $tpp_id) = @_;
  print "-"x96, "\n";
  print "sub do835Verification. Entry. file: $file\n";

  my $WHAT;
  my $recsplit;
  my $remit_status = 1;
  my $clp_rpt_cnt = 0;
  my $clp_cnt = 0;
  my $net_sum = 0;

  my @tmparray = ();

  my %chk_date = (); # Key = Check Number
  my %chk_total = (); # Key = Check Number
  my %chk_npi_amt = (); # Key Check Number:NPI
  my %plb_amt = (); # Key Check Number:NPI

  my $initial_splitchars = "[\*||\^|\|]||\~]";		# SET FROM ISA Record!

  open(IFILE, "< $file")  || die "Couldn't open input file '$file'\n\t$!\n\n";
  while ($line = <IFILE>) {
    chomp($line);
    next if ( $line =~ /^\s*$/ ); # skip blank lines
    $line =~ s/^\s*(.*?)\s*$/$1/; # trim leading and trailing white space
    @pcs = ();

    if ( $line =~ /^BPR|^TRN|^TS3|^CLP|^PLB/i ) {
      my @tmparray = split(/${initial_splitchars}/, $line);

      $WHAT = $tmparray[0];
      ($WHAT, $rest) = split( /${initial_splitchars}/, $line, 2 );

      if ( !$recsplit ) {
        ($test = $line) =~ s/^$WHAT//;
        $recsplit = substr($test, 0, 1);
        if ( $recsplit =~ /\\*/ ) {
          $recsplit = "\\" . $recsplit;
        }
      }
	    
      my @pcs = split(/${recsplit}/, $line);

      if ($line =~ /^BPR/i ) {
        $chk_amt  = $pcs[2];	    
        $chk_date = $pcs[16];
      }
      elsif ($line =~ /^TRN/i ) {
        $chk_num = $pcs[2];	    
        $chk_total{"$chk_num"} = $chk_amt;
        $chk_date{"$chk_num"}  = $chk_date;
      }
      elsif ($line =~ /^TS3/i ) {
        $npi = $pcs[1];
        if ( !$chk_npi_amt{"$chk_num:$npi"} ) {
          $chk_npi_amt{"$chk_num:$npi"} = 0;
	}	
        if( $pcs[4] !~ /^\s*$/ ) {
          $clp_rpt_cnt += $pcs[4];
        }
      }
      elsif ($line =~ /^CLP/i ) {
        $claim_pd = $pcs[4] + 0;
        $chk_npi_amt{"$chk_num:$npi"} += $claim_pd;
        $chk_npi_amt{"$chk_num:$npi"} = sprintf "%.2f", $chk_npi_amt{"$chk_num:$npi"};
        ++$clp_cnt;
      }
      elsif ($line =~ /^PLB/i ) {
        $plb_npi = $pcs[1];
        $plb_amt = 0;

        if ( !$chk_npi_amt{"$chk_num:$plb_npi"} ) {
          $chk_npi_amt{"$chk_num:$plb_npi"} = 0;
        }

        for (my $plb_ctr = 4; $plb_ctr <= $#pcs; $plb_ctr += 2) {
          $plb_amt += $pcs[$plb_ctr];
        }

        $plb_amt{"$chk_num:$plb_npi"} += $plb_amt;
        $plb_amt{"$chk_num:$plb_npi"} = sprintf "%.2f", $plb_amt{"$chk_num:$plb_npi"};
      }
      elsif ($line =~ /^REF/i ) {
        $REF02 = $pcs[2];
        $key = "$TPPID##$REF02";

	if ($Other_Source_Use_Adjustment_Descriptions{$TPPID} =~ /Yes/i ) {
	  if (!$Lookup_Other_Source_TPP_IDs{$key}) {
             $ref02_error++;
	  }
	}
      }      
    }
  }

  close IFILE;

### REF02 Check

  if ($ref02_error > 0) {
    print "Failed REF02 Check - Missing Other_Source Entry\n";
    $remit_status = 0;
  }

### CHECK DATE Check

  if ($chk_date < ($currdate - 10000)) {
    print "Check Date Validation -> Check Date: $chk_date\n";
    $remit_status = 0;
  }

### CLP Count Check

  print "CLP COUNTS: Actual=$clp_cnt Reported=$clp_rpt_cnt  -> ";
  if ($clp_rpt_cnt > 0 && $clp_cnt != $clp_rpt_cnt) {
    $remit_status = 0;
#    print "CLP COUNT ERROR\n";
  }
  else {
#    print "CLP COUNT GOOD\n";
  }

  foreach $key ( sort { $a cmp $b } keys %chk_npi_amt ) {
    ($k_chk_num, $k_npi) = split( /:/, $key);

    if ($k_chk_num ne $chk_num_sav) {
      if ($firstone > 1) {
        $row++; $col = 0;
      }
      $net_sum = 0;
    }

    ($k_chk_num, $k_npi) = split( /:/, $key);

    $chk_npi_amt{$key} =~ s/^\s*(.*?)\s*$/$1/;
    $plb_amt{$key} =~ s/^\s*(.*?)\s*$/$1/;

    $net_amt = (($chk_npi_amt{$key} + 0) - ($plb_amt{$key} + 0));
    print "CLP=$chk_npi_amt{$key} - PLB=$plb_amt{$key}\n";
    $net_sum += $net_amt;

    $chk_num_sav = $k_chk_num;
    $firstone++;
  }

  print "TPP: $tpp_id\n";
  if ($chk_total{$k_chk_num} ne $net_sum && $file =~ /AmerisourceBergen|CardinalHealth/) {
    print "FIXING CENTRAL PAY +/-\n";
    $net_sum = abs($net_sum);
  }

  $net_sum = sprintf "%.2f", $net_sum;
  $chk_total{$k_chk_num} = sprintf "%.2f", $chk_total{$k_chk_num};  

  if ($chk_total{$k_chk_num} ne $net_sum) {
    unless ($chk_total{$k_chk_num} eq '0.00' && $net_sum == 0) {
#      print "**** FAILED TO BALANCE ****\n";
      print "BALANCE? TOTAL: $net_sum CHK AMT: $chk_total{$k_chk_num}\n";
      $remit_status = 0;
    }
  }  

  print "$chk_total{$k_chk_num}/$net_sum\n";

  print "*"x96, "\n";

#--------------------------------------------------------

  print "sub do825Verification. Exit.\n";
  print "-"x96, "\n";
  return $remit_status;
}      

#______________________________________________________________________________

sub getsuperuserncpdps {
  my $Wlogin       = $USER;
  my $DBNAME       = 'officedb'; 
  my $tbl_Pharmacy = 'pharmacy'; 
  my $tbl_WLLogin  = 'WebLogintb'; 

  my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
            { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  $sql = "
    SELECT CASE WHEN WLNCPDPs = 'ALL' THEN (SELECT GROUP_CONCAT(ncpdp SEPARATOR ',')
                                             FROM $DBNAME.$tbl_Pharmacy WHERE type LIKE '%RBS%'
                                               && rbsreporting = 'Yes'
                                               && NCPDP NOT IN (1111111,2222222)
                                           )
           ELSE 
             REPLACE(WLNCPDPs, ';',',') 
           END as WLNCPDPs,
           CASE WHEN WLNCPDPs = 'ALL' THEN WLNCPDPs
	   ELSE 'CONSOLIDATED'
	   END as TYPE

      FROM $DBNAME.$tbl_WLLogin 
     WHERE WLLoginID='$Wlogin' && (WLType = 'Admin' || WLType = 'SuperUser') && WLPrograms LIKE '%RBS%' 
  ";

  $sth99 = $dbm99->prepare($sql);
  $sth99->execute();

  my $NumOfRows = $sth99->rows;

  my (@row,$type) = $sth99->fetchrow_array();
  $sth99->finish;
  $dbm99->disconnect;
  return (@row,$type);
}

sub get_user_pharmacyids {
  my $Wlogin       = shift;
  my $DBNAME       = 'officedb'; 
  my $tbl_Pharmacy = 'pharmacy'; 
  my $tbl_WLLogin_dtl = 'WebLogin_dtl';
  my $ids = '';
  my $NumOfRows = 0;
  my $type = 'CONSOLIDATED';

  my $dbm99 = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
            { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";

  $sql = "
    SELECT GROUP_CONCAT(Pharmacy_ID SEPARATOR ',')
      FROM $DBNAME.$tbl_WLLogin_dtl
     WHERE login_id = $Wlogin
  ";

  $sth99 = $dbm99->prepare($sql);
  $sth99->execute();

  $NumOfRows = $sth99->rows;

  my $ids = $sth99->fetchrow_array();

  if ( $TYPE =~ /Admin/i && ($ids == 0  || $ids eq '') ) {
    $sth99->finish;
    $sql = "
      SELECT GROUP_CONCAT(Pharmacy_ID SEPARATOR ',')
        FROM $DBNAME.$tbl_Pharmacy 
       WHERE type LIKE '%RBS%'
          && rbsreporting = 'Yes'
          && NCPDP NOT IN (1111111,2222222)
    ";

    $sth99 = $dbm99->prepare($sql);
    $sth99->execute();

    $NumOfRows = $sth99->rows;

    $ids = $sth99->fetchrow_array();
    $type = 'ALL';
  }

  $sth99->finish;
  $dbm99->disconnect;
#  return ($NumOfRows, $ids);
  return ($ids, $type);
}
sub get_RBSReporting_Pharmacies {

  my @RBSReportingPharmacies;

  my $sql = "
    SELECT NCPDP 
      FROM officedb.pharmacy 
     WHERE Type LIKE '%RBS%' 
        && Status_RBS = 'Active' 
        && RBSReporting = 'Yes' 
     ORDER BY NCPDP 
  ";
  $sthx  = $dbx->prepare("$sql");
  $sthx->execute;

  while ( my $ncpdp = $sthx->fetchrow() ) {
    push(@RBSReportingPharmacies, $ncpdp);
  }
  return \@RBSReportingPharmacies;
}

sub getMenuOption { 

 $PHID    = shift;
 $val     = shift;
 $tbl_ctl = 'pharmacy_ctl';

 $menuoption = '';

 $menuval = 'No';
 $menuval = 'Yes' if($val == 1);

  my $DBNAME= 'officedb'; 
  
  $dbp = DBI->connect("DBI:mysql:$DBNAME:$DBHOST",$dbuser,$dbpwd,
         { RaiseError => 1, InactiveDestroy => 0 } ) || die "$DBI::errstr";
  DBI->trace(1) if ($dbitrace);

  if($PHID > 0) {
    $sql =  "INSERT INTO $DBNAME.$tbl_ctl (pharmacyID, NewMenu)
               VALUES($PHID,'$menuval') 
               ON DUPLICATE KEY UPDATE `NewMenu` = '$menuval' 
	    "; 

    $sthp = $dbp->prepare($sql);
    $sthp->execute();
  }
  else {
    $PHID = $PH_ID;

    $sql = "SELECT newmenu 
               FROM $DBNAME.$tbl_ctl
               WHERE PharmacyID = '$PHID'
            ";
    $sthp = $dbp->prepare($sql);
    $sthp->execute();
    $menuoption = $sthp->fetchrow;
    return $menuoption;
  }
 
    $sthp->finish();

  $dbp->disconnect;

}

sub displayMenuOption {

print qq# 

<script>


function menuchange(phid) {

 var menu = document.getElementById("menuoption").checked;

        window.location.reload();
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange=function() {
        if (this.readyState == 4 && this.status == 200) {
        }
      };
      var url ="includes/savemenuoption.pl?PHID=" +phid + "&Menu=" +menu;
         xhttp.open("POST", url, true);
           xhttp.send()
}

</script>

<style>
.switch {
  position: relative;
  display: inline-block;
  width: 40px;
  height: 18px;
}


.switch input { 
  opacity: 0;
  width: 0;
  height: 0;
}


.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  transition: .4s;
  background-color: lightgrey;
  -webkit-transition: .4s;
}


.slider:before {
  position: absolute;
  content: "";
  height: 13px;
  width: 13px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  -webkit-transition: .4s;
  transition: .4s;
}

input:checked + .slider {
  background-color: \#133562;
}

input:focus + .slider {
  box-shadow: 0 0 1px grey;
}


input:checked + .slider:before {
  -webkit-transform: translateX(20px);
  -ms-transform: translateX(20px);
  transform: translateX(20px);
}


/* Rounded sliders */
.slider.round {
  border-radius: 34px;
}

.slider.round:before {
  border-radius: 50%;
}

</style>
#;
}

sub produce_MEV_HTML{

  my ($contact_name, $ncpdp, $today, $rm) = @_; 
  my $reminder;
  my $color = '#0492C2';
  

  if ($rm) {
    $reminder = "According to our records, we have not received your required Monthly Employee Verification Form for RBS.<br><br>"; 
  }

  my $emailHTML = <<EOF;
  
  <table border='0' cellpadding='5' cellspacing='0' width='800'>
      <tr>
        <td>
          <img src="cid:Outcomes_RBS.png" alt='Outcomes RBS: Retail Business Solution'/>
        </td>
        <td style='padding-left: 8px;'>
          <strong><u>Contact Us:</u></strong><br/>
          web: <a href='https://members.pharmassess.com/Login.html' target='_blank' style='color: $color'>Outcomes RBS</a><br />
          call: (888) 255-6526<br />
            email: <a href='mailto: rbs\@outcomes?subject=RBS Credentialing Question' style='color: $color;'> rbs\@outcomes.com</a>
        </td>
      </tr>
  <tr>
  <td><h2 style='color: $color;'>RBS Credentialing Monthly Employee Verification</h2></td>
  <td><p>
${today}
  <br />
  <strong>
  Action Required
  </strong>
  </p></td>
  </tr>
  </table>

  <hr/>
  <p>${contact_name} - ${ncpdp}</p>
  $reminder
  Please log into your <a href='https://members.pharmassess.com/Login.html' target='_blank' style='color: $color;'> Outcomes RBS </a> account and complete the Monthly Employee Verification process. <br> Click on Monthly Employee Verification found right underneath the Credentialing Profile. To add, edit, and remove pharmacy employees in your Credentialing Profile, select Edit in the bottom left corner to unlock the profile. Click Manage to edit or remove pharmacy employees and click Add to add new hires. Once complete, select Save Changes and the changes will be reflected in your pharmacy profile.
  <br><br>
  Additionally, please submit all required documents online via the Upload File Feature found within your online Outcomes RBS Credentialing account. This applies to license renewals, certificates, and any other associated documents. To upload, simply click on Upload License/Document in your Member's Section. Once you select the correct document, click on Upload File.
  
  <br>As a reminder, please complete this by the end of the month so we may complete your monthly OIG/GSA exclusion verifications.
  
  
  <p>
  If you have any questions, please contact us by email at <a href='mailto:rbs\@outcomes.com?subject=Monthly Employee Verification Form'>rbs\@outcomes.com</a> or by phone toll-free at (888) 255-6526.
  </p>
  <br>
  <br>
  Thank you, 
  
  <h2 style="color:$color"> Outcomes RBS Team </h2>
  <br/>
EOF

   return($emailHTML);	
}




# ______________________________________________________________________________

1;    # Required for a Perl include file
