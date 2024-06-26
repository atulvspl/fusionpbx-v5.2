=pod
	Version 1.0
	Developed by Velantro inc
	Contributor(s):
	George Gabrielyan <george@velantro.com>
=cut

sub login() {
	
sub api_access_check {
	my ($domain) = @_;
	
  %hash  = &database_select_as_hash("select
										1, domain_uuid
									from
										v_domains
									where
										domain_name='$domain'",
									'uuid');
									
	$uuid = $hash{1}{uuid};
	
	if (!$uuid) { &print_api_error_end_exit("13","Domain UUID not found");	}

	  %hash1  = &database_select_as_hash("select
										1, api_access
									from
										v_video_codecs
									where
									    api_access = 'true' 
									and
										domain_uuid = '$uuid'",
									'api_access');
									
	$api_access = $hash1{1}{api_access};	
	
	return $api_access;
  }
  
	#
	# check already login (save resources)
	&websession_attach();
	if (&websession_is_active()) {
		if (&websession_get("user_id") ne "") {
			%response 				= ();
			$response{stat}			= "ok";
			$response{domain}		= &websession_get("pbx_host");
			
			if (!$response{domain}) { &print_api_error_end_exit("13","domain is null");	}
	
			$api_access = api_access_check($response{domain});

			if (!$api_access) { &print_api_error_end_exit("13","API Access Disabled");	}
			
			#$response{user}{name}	= &websession_get("user_name");
			$response{timestamp}	= time;
			&print_json_response(%response);
			exit;
		}
	}
	#
	# check user
	$user = $form{user};
	$user = &clean_str($user,"TEXT");
	if ($user eq "")			{ &print_api_error_end_exit("10","Empty user");		}
	if ($user ne $form{user}) 	{ &print_api_error_end_exit("11","invalid user");	}
	if (length($user) > 32)		{ &print_api_error_end_exit("12","invalid user");	}
    $domain = $form{domain};
    $domain = &database_clean_string($domain);
	
    if (!$domain) { &print_api_error_end_exit("13","domain is null");	}
	
	$api_access = api_access_check($domain);

	if (!$api_access) { &print_api_error_end_exit("13","API Access Disabled");	}

	#
	# check password
	$pwd = $form{password};
	$pwd = &clean_str($pwd,"TEXT");
	if ($pwd eq "")					{ &print_api_error_end_exit("20","Empty password");		}
	if ($pwd ne $form{password}) 	{ &print_api_error_end_exit("21","invalid password");	}
	if (length($pwd) > 64)			{ &print_api_error_end_exit("22","invalid password");	}
	#
	# check login
	
    %login = &do_pbx_login($user, $pwd, $domain);
    if ($login{stat} ne 'ok') {
        &print_api_error_end_exit("22","authen fail");
    }
    
	# create session
	&websession_create();
	&websession_set("user_id", $login{cookie_id});
    &websession_set("pbx_host", $domain);
    &websession_set("pbx_cookie", $login{cookie});

	#
	# response	
	%response 				= ();
	$response{stat}			= "ok";
	$response{code}			= "0";
	$response{timestamp}	= time;
	&print_json_response(%response);
}

sub logout() {
	&websession_destroy();
	%response = ();
	$response{stat}		= "ok";
	$response{code}		= "0";
	$response{timestamp}= time;
	&print_json_response(%response);
}

sub logincheck() {
	&websession_attach();
    &pbx_debug(\%app);
	if (&websession_is_active()) {
		$user_id	= &websession_get("user_id");
		if ($user_id eq "") {
			&print_api_error_end_exit("11","no login information") 		
		}
		%response 				= ();
		$response{stat}			= "ok";
		$response{code}			= "0";
		
		$response{timestamp}	= time;
			
		&print_json_response(%response);
	} else {
		&print_api_error_end_exit("10","no websession");
	}
}
# ==============================================

1;
