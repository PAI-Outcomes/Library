sub printCredEmployeesTesting {
  my ($Pharmacy_ID, $PROGRAM, $DOCHOST, $COLORMODE, $disp_cred, $alert) = @_;
  
  my $DBNAME = '';
  my $TABLE  = '';
  my $NCPDP;
  $disp_cred = 'inline-block';
  

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
                    (DATEDIFF(CURDATE(), exp_date) ) AS 'LicAge', (DATEDIFF(CURDATE(), date_hired) ) AS 'DOH', oig_gsa_match, exp_date, date_hired,address
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

  print qq#<span style="color: green; font-size: 12px;">$alert</span>\n#;
  print qq#<table class="credEmployees">\n#;
  print "<tr>
  <th style=\"min-width: 130px; text-align: left;\"></th>
  <th style=\"min-width: 130px; text-align: left;\">Name</th>
  <th style=\"min-width: 130px; text-align: left;\">Title</th>
  <th width=\"160px\" class=\"center\">FWA</th>
  <th width=\"85px\" class=\"center\">HIPAA</th>
  <th width=\"85px\" class=\"center\">COI/COC</th>
  <th width=\"85px\" class=\"center\">Handbook</th>
  <th width=\"85px\" class=\"center\">OIG/GSA</th>
  </tr>\n";

  while ( my @row = $employees->fetchrow_array() ) {
     my ($emp_id, $fname, $lname, $title, $fwa_c, $fwa_m, $hipaa, $coi_coc, $handbook, $oig_gsa, $license, $LicAge, $doh, $oig_gsa_match, $exp_date, $date_hired,$addr) = @row;
         $doh = '30' if (!$doh);
	 
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
     my	$am = 0;
     if ( $LicAge < -60 || $LicAge =~ /^\s*$/ ) {
     } elsif ( $LicAge < 0 ) { 
        $bgcolorbeg = qq#class="yellow"#;
	$am = 1;
     } else { 
        $bgcolorbeg = qq#class="red"#;
	$am = 1;
     } 

     $doh90 = '';

     if ( $doh <= 30  ) {
       $doh90 = '*';
       $doh_cnt++;
     }
     $match = ''; 
     $match = '<td class="match">MATCH</td>' if ($oig_gsa_match);
		
     print "<tr>
         <td><button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='manage_employee(\"$fname\", \"$lname\", \"$title\", \"$license\", \"$exp_date\", \"$date_hired\", \"$emp_id\", \"$addr\" , \"$am\")'>Edit</button></td>
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
       print "<td><button style='display: $disp_cred' type='button' class='button-form-small manage' onClick='add_employee()'>Add Employee</button></td>";
     }

       print "<td></td>
    	      <td></td>
	      <td></td>
	      <td></td>
	      <td></td>
	      <td colspan='2'>
                <form id='form' action='credentialing.cgi' method='post'>
                  <input type='hidden' name='action' value='Save'>
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

      function showhide(){
        var thisform = 'form1';
        var doc     = document.forms[thisform];
        var dta     = doc["title"].value; 
        var action  = doc["action"].value; 
	var msg     = doc["action"].value; 

        if(dta.match(/PIC|Pharmacist|Technician|Intern|Technician Candidate/)) {
          if(msg == 'Update') {
            \$("#lic_exp").show();
            \$("#upload_lic").show();
	  }
	  else {
            \$("#lic_exp").hide();
            \$("#upload_lic2").show();
	  }
        }
	else {
          \$("#lic_exp").hide();
          \$("#upload_lic").hide();
          \$("#upload_lic2").hide();
        }

      }

        function checkinfo(){
          var thisform = 'form1';
	  var message = '';
	  var doc     = document.forms[thisform];
          var dta     = doc["title"].value; 
          var type    = doc["action"].value;

	  if(doc["fname"].value == '') {
            message = "First Name is required\\n";
	  }
	  if(doc["lname"].value == '') {
            message = message + "Last Name is required\\n";  
	  }
	  if(type.match(/Add/) && doc["soc"].value == '') {
            message = message + "Invalid Social Security #\\n";  
	  }
	  if(doc["addr"].value == '') {
            message = message + "Address is required\\n";
	  }
	  if(doc["title"].value == '') {
            message = message + "Title is required\\n";
	  }
          if(!(isValidDate(doc["date_hired"].value))) {
            message = message + "Invalid Date Of Hire\\n";  
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
            message = "Authorizing Name is required\\n";
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

      function manage_employee(fname, lname, title, license, exp_date, date_hired, emp_id, addr, licexp) {
	\$("#lic_msg").val("");
        \$("#fname").val(fname);
        \$("#lname").val(lname);
        \$("#title").val(title);
        \$("#addr").val(addr);
        \$("#license").val(license);
        \$("#license_exp").val(exp_date);
        \$("#date_hired").val(date_hired);
        \$("#action").val('Update');
        \$("#emp_id").val(emp_id);
        \$("#disp_name").val(fname + ' ' + lname);
        \$("#disp_title").val(title);
        \$("#socs").hide();
        \$("#lic_exp").show();
        \$("#termbutton").show();
        \$("#dialog-form1").dialog("open");	
        \$('#ui-id-1').text('Edit Employee');
        \$("#upload_lic").hide();
        \$("#upload_lic2").hide();
        \$("#upload_link").attr('href', "https://members.pharmassess.com/members/upload_cred_documents.cgi?fname=" + fname + "&lname=" + lname + "&ltype=" + title + "&lnumber=" + license);

        if(title.match(/PIC|Pharmacist|Technician|Intern|Technician Candidate/)) {
          \$("#lic_exp").show();
	  if(!license || !exp_date) {
            \$("#upload_lic").show();
	  }
	  if(licexp) {
            \$("#upload_lic").show();
	  }
        }
	else {
          \$("#upload_lic").hide();
          \$("#lic_exp").hide();
        }
      }

      function add_employee() {
        \$("#fname").val('');
        \$("#lname").val('');
        \$("#addr").val('');
        \$("#soc").val('');
        \$("#title").val('');
        \$("#license").val('');
        \$("#license_exp").val('');
        \$("#date_hired").val('');
	\$("#lic_msg").val("");
        \$("#socs").show();
        \$("#lic_exp").hide();
        \$("#termbutton").hide();
        \$("#action").val('Add');
        \$('#ui-id-1').text('Add Employee');
        \$("#dialog-form1").dialog("open");	
        \$("#upload_lic").hide();
        \$("#upload_lic2").hide();
      }

      function term_employee() {
        if (window.confirm("Term " + \$("#fname").val() + ' ' + \$("#lname").val() + '?')) {
          \$("#action").val('Term');
	  \$('#form1').submit();
	}
      }

      function mev_auth() {
          \$("#dialog-form2").dialog("open");	
      }

      \$(function() {
        \$( "#dialog-form1" ).dialog({
		autoOpen: false,
		height: 345,
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
      <form id="form1" action="credentialing_testing.cgi" method="post">
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
	  <tr id='socs' style="display:table-row;">
	    <td class="tdNoBorder">
	      <label for="addr">Social Security # </label>
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="soc" id="soc" value="" class="text ui-corner-all"><br />
	    </td>
          </tr>
	  <tr>
	    <td class="tdNoBorder">
	      <label for="addr">Address</label>
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="addr" id="addr" value="" class="text ui-corner-all"><br />
	    </td>
          </tr>
	  <tr>
	    <td class="tdNoBorder">
	      <label for="title">Title</label>
            </td>
	    <td class="tdNoBorder">
	      <select name="title" id="title" class="cipn-dropdown-form required" onChange='showhide()'>
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
	  <tr id='lic_exp' style="display:table-row;">
	    <td class="tdNoBorder">
	      <label for="license">License</label><br />
	    </td>
	    <td class="tdNoBorder">
              <input type="text" name="license" id="license" value="" readonly="readonly"  class="text ui-corner-all" style="width: 150px;">
	    </td>	
	    <td class="tdNoBorder">
	      <label for="license_exp">Expiration</label><br />
	    </td>
	    <td class="tdNoBorder">
	      <input type="text" name="license_exp" id="license_exp" value="" placeholder="yyyy-mm-dd" readonly="readonly" class="text ui-corner-all" style="width: 150px;">
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
	<div id="termbutton" style="float: right">
	  <button id='term' type='button' class='button-form-small' style="color: red" onClick='term_employee()'>Term Employee</button>
	</div>
	<br>
	<br>
	<table width=500px>
	  <tr id='upload_lic' style="display:table-row;">
	    <td class="tdNoBorder" colspan="2">
	      <a href="https://members.pharmassess.com/members/upload_cred_documents.cgi" target="_blank" id='upload_link' rel="noopener noreferrer" style="color:red;">Please upload license</a>
	    </td>	
	  </tr>
	  <tr id='upload_lic2' style="display:table-row;">
	    <td class="tdNoBorder" colspan="2">
	      <a href="https://members.pharmassess.com/members/upload_cred_documents.cgi" target="_blank" rel="noopener noreferrer" style="color:red;">Please upload license within 30 days</a>
	    </td>	
	  </tr>
	</table>
      </form>
    </div>

    <div id="dialog-form2" title="Monthly Employee Verification" style="display: none;">
      <form id="mev_form" action="credentialing_testing.cgi" method="post">
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


sub printCredInfoTesting {
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

  &printCredEmployeesTesting($Pharmacy_ID, $PROGRAM, $dochost, "Color", $disp_manage, $alert);
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
  print qq#<tr><td class="tdNoBorder"><strong>*</strong>  Within 30 Days Of Hire</td></tr># if ($doh_cnt);
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
		
    print qq# <div><a href="upload_cred_documents.cgi" target="_Blank" >Click Here to Upload Document</a></div>\n#;
    
  print qq#
    <br>
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


1;
