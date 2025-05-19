#______________________________________________________________________________
# Input file for all Perl routines accessing the databases
#______________________________________________________________________________

$dbhost  = "OUT-PAIDBPROD01";
$dbuser  = "pharm";
$dbpwd   = "assess";
$dbSuser = "IT_Tasks";
$dbSpwd  = "IT\@PAI";

$TASKUSER = "pa-users\\PAISchTask";
$TASKPASS = "\$ch3dul3Me2Run";

$FLSERVER   = 'OUT-PAIFSPROD01';
$BTSERVER   = 'OUT-PAIBCHPRD01';
$WBSERVER   = 'OUT-PAIWEBPRD01';
$DBSERVER   = 'OUT-PAIDBPROD01';
$PAIT_EMAIL = 'PAIT@Outcomes.com';



$ReconWebshare = "\\\\$FLSERVER\\BSRVPROD\\WWW\\Recon";
$sig_img    = "D:\\RedeemRx\\CannedFiles\\Outcomes_ReconRx_sig.png";

##$DBSERVER  = "10.255.64.17";
  ## $dbhost  = "10.140.41.249";
##$BTSERVER  = 'PAIBATCHPROD01';
#$dbhost  = "PAIDBPROD01";
##$FLSERVER  = '10.255.64.18';
##$FLSERVER  = 'PAIFSPROD01';
##$DBHOST2   = "10.255.65.50";
##$WBSERVER  = '10.255.250.12';
##$dbhost  = "10.255.64.17";


1;
