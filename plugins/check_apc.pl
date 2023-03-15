#!/usr/bin/perl -w
#
# check_apc.pl v1.0
#
# Nagios plugin script for checking APC Uninteruptible Power Supplies.
#
# License: GPL v2
# Copyright (c) 2012 LayerThree B.V.
# Author: Michael van den Berg
# http://www.layerthree.nl
#

use strict 'vars';
use Net::SNMP qw(ticks_to_time);;
use Switch;
use Getopt::Std;
use Time::Local;

# Command arguments
my %options=();
getopts("H:C:l:p:t:w:c:u", \%options);

# Help message etc
(my $script_name = $0) =~ s/.\///;

my $help_info = <<END;
\n$script_name - v1.0

Nagios script to check status of an APC Uninteruptable Power Supply.

Usage:
-H 	Address of hostname of UPS (required)
-C	SNMP community string (required)
-l 	Command (optional, see command list)
-p	SNMP port (optional, defaults to port 161)
-t 	Connection timeout (optional, default 10s)
-w 	Warning threshold (optional)
-c 	Critical threshold (optional)
-u	Script / connection errors will return unknown rather than critical

Commands (supplied with -l argument):

	status
	  Shows output status of UPS (On battery power, bypass, etc)

	health
	  Shows result of last diagnostic test and date run. Optional warning or critical
	  values for days since last test was run. Will also warn if battery needs replacing.

	load[:###]
	  Shows output load in percentage of maximum load. Optional warning or critical
	  values in percentages of total load. 

	  If an integer value of the maximum output wattage capacity of the UPS is included 
	  after a colon (:), then the output in watts will be included in the result.

No command is supplied, the script return OKAY with the UPS model information.

Example:
$script_name -H ups1.domain.local -C public -l health

END

# OIDs for the checks
my $oid_upsmodel	= ".1.3.6.1.4.1.318.1.1.1.1.1.1.0";	# UPS Model
my $oid_outputstatus 	= ".1.3.6.1.4.1.318.1.1.1.4.1.1.0";	# Output status (battery power, mains, etc)
my $oid_runtimeleft	= ".1.3.6.1.4.1.318.1.1.1.2.2.3.0";	# Runtime remaining of load if on battery power
my $oid_lastdiagresult 	= ".1.3.6.1.4.1.318.1.1.1.7.2.3.0";	# Last system diagnostic result
my $oid_lastdiagdate 	= ".1.3.6.1.4.1.318.1.1.1.7.2.4.0";	# Last system diagnostic run date
my $oid_battstatus 	= ".1.3.6.1.4.1.318.1.1.1.2.2.4.0";	# Battery replacement status
my $oid_outputload	= ".1.3.6.1.4.1.318.1.1.1.4.2.3.0"; 	# System load (percentage capacity)


# Nagios exit codes
my $OKAY 	= 0;
my $WARNING 	= 1;
my $CRITICAL 	= 2;
my $UNKNOWN 	= 3;

# Command arguments and defaults
my $snmp_host		= $options{H};
my $snmp_community	= $options{C};
my $snmp_port		= $options{p} || 161;	# SNMP port default is 161
my $connection_timeout	= $options{t} || 10;    # Connection timeout default 10s
my $default_error	= (!defined $options{u}) ? $CRITICAL : $UNKNOWN;
my $check_command	= $options{l};
my $critical_threshold 	= $options{c};
my $warning_threshold	= $options{w};
my $session;
my $error;

# APCs have a maximum length of 15 characters for snmp community strings
if(defined $snmp_community) {$snmp_community = substr($snmp_community,0,15);}

# If we don't have the needed command line arguments exit with UNKNOWN.
if(!defined $options{H} || !defined $options{C}){
	print "$help_info Not all required options were specified.\n\n";
	exit $UNKNOWN;
}

# Setup the SNMP session
($session, $error) = Net::SNMP->session(
               	-hostname 	=> $snmp_host,
               	-community 	=> $snmp_community,
               	-timeout  	=> $connection_timeout,
               	-port 		=> $snmp_port,
		-translate	=> [-timeticks => 0x0],  
		);

# If we cannot build the SMTP session, error and exit
if (!defined $session) {
      my $output_header = ($default_error == $CRITICAL) ? "CRITICAL" : "UNKNOWN";
      printf "$output_header: %s\n", $error;
      exit $default_error;
}

# Determine what we need to do based on the command input
if(!defined $options{l}){  # If no command was given, just output the UPS model
	my $ups_model = query_oid($oid_upsmodel);
	$session->close();
	print "$ups_model, reporting for duty\n";
	exit $OKAY;	
}else{	# Process the supplied command. Script will exit as soon as it has a result.
	switch($check_command){
		case "status"{	
			# Status check - Checks power status and runtime remaining.
			my $ups_status = query_oid($oid_outputstatus);
			my $perf_data;
			my $ups_runtime_mins;
			if ($ups_status == 2 || $ups_status == 3){  # Only get remaining runtime if under power or battery
				my $ups_runtime_ticks = query_oid($oid_runtimeleft);
				$ups_runtime_mins = int($ups_runtime_ticks / 100 / 60);
                        	$perf_data = "|'Runtime Remaining'=$ups_runtime_mins"."m;";
			}
			$session->close();
			
			switch($ups_status){
		  		case 2{ # This means all is good - the only good result of this check
					print "OK: UPS is online (Runtime remaining: $ups_runtime_mins minutes)$perf_data\n";
					exit $OKAY;
				}
				case 3{	# UPS is running on battery
					print "CRITICAL: On battery power (Runtime remaining: $ups_runtime_mins minutes)$perf_data\n";
					exit $CRITICAL;
				}
				case 7{ # The UPS is off
					print "CRITICAL: UPS is offline!\n"
				}
				case 10{ # Hardware bypass failure
					print "CRITICAL: Hardware bypass failure\n";
					exit $CRITICAL;
				}
				else{ # Something bad is happening but we don't know what
					print "CRITICAL: Status issue present\n";
					exit $CRITICAL;
				}
		  	}
		}
		case "health"{	
			# Health check - Gets last diagnostic result and the date it was run. Also polls wether battery needs replacement
			my $diag_result  = query_oid($oid_lastdiagresult);
			my $diag_date	 = query_oid($oid_lastdiagdate);
			my $diag_battery = query_oid($oid_battstatus);
			$session->close();

			# Critical if the self test returns failed
			if ($diag_result == 2 || $diag_result == 3){
				print "CRITICAL: Self test failure\n";
				exit $CRITICAL;
			}elsif ($diag_battery == 2){	# Battery flagged for replacement
				print "WARNING: Battery needs to be relaced\n";
				exit $WARNING;
			}else{	
			# If Okay, then check the date of the last self test before returning result of check
				# First the returned date is converted to epoch for simplified date math
				# UPS returns date as mm/dd/yyyy	
				my @diagdate_split = split(/\//,$diag_date);	
				my $diagdate_epoch = timelocal(0,0,12,$diagdate_split[1],$diagdate_split[0] - 1,$diagdate_split[2]);
				my $diag_daysago = int((time - $diagdate_epoch) / 86400 + 0.5);	# How many days since last self test
			
				if (defined $critical_threshold && $diag_daysago > $critical_threshold){
					print "CRITICAL: Self test last ran on $diag_date ($diag_daysago days ago)\n";
					exit $CRITICAL;
				}elsif(defined $warning_threshold && $diag_daysago > $warning_threshold){
					print "WARNING: Self test last ran on $diag_date ($diag_daysago days ago)\n";
					exit $WARNING;
				}else{
					print "OK: Self test passed on $diag_date ($diag_daysago days ago)\n";
					exit $OKAY; 
				}
			}
		}
		case m/^load$|^load:\d{2,5}$/{	
			# Load check - Gets load as a percentage of maximum real power output. Can also return 
			# real power in watts if the max real power load is supplied (APC snmp doesn't have this info)  
			my $output_load = query_oid($oid_outputload);	# UPS returns load as percentage of real power rating
			$session->close();

			my @load_command = split(/:/,$check_command);	# Split off the watt number if included
			my $crit = (defined $critical_threshold) ? $critical_threshold : 0;
			my $warn = (defined $warning_threshold) ? $warning_threshold : 0;
			my $perf_data = "|load=$output_load%;$warn;$crit;0";	# Perf data for load percentage

			my $output_watts;
			my $wattage;

			if (defined $load_command[1]) {	
				# If the max watt number was included, then calculate the load in watts using the 
				# percentage. This output is then concatenated with the load percentage
				$output_watts = ($output_load / 100) * $load_command[1];
				$wattage = "($output_watts"."W)";
                        	my $crit = (defined $critical_threshold) ? ($critical_threshold / 100 * $load_command[1]) : 0;
                        	my $warn = (defined $warning_threshold) ? ($warning_threshold / 100 * $load_command[1]) : 0;
				$perf_data = $perf_data . " output=$output_watts"."W;$warn;$crit;0";	# Perf data for watts
			}else{ $wattage = ""; }
 			
			# Output the result and exit as usual
			if (defined $critical_threshold && $output_load > $critical_threshold){
				print "CRITICAL: Output load: $output_load% $wattage"."$perf_data\n";
				exit $CRITICAL;
			}elsif(defined $warning_threshold && $output_load > $warning_threshold){
				print "WARNING: Output load: $output_load% $wattage"."$perf_data\n";
				exit $WARNING;
			}else{
				print "OK: Output load: $output_load% $wattage$perf_data\n";
				exit $OKAY;
			}
		}else{
			print "$script_name - '$check_command' is not a valid comand\n";
			exit $UNKNOWN;
		}
	}
}

sub query_oid {
# This function will poll the active SNMP session and return the value
# of the OID specified. Only inputs are OID. Will use global $session 
# variable for the session.
	my $oid = $_[0];
	my $response = $session->get_request(-varbindlist => [ $oid ],);
	
	# If there was a problem querying the OID error out and exit
	if (!defined $response) {
      		my $output_header = ($default_error == $CRITICAL) ? "CRITICAL" : "UNKNOWN";
      		printf "$output_header: %s\n", $session->error();
      		$session->close();
      		exit $default_error;
	}

	return $response->{$oid};
}

# The end. We shouldn't get here, but in case we do exit unknown
print "UNKNOWN: Unknown script error\n";
exit $UNKNOWN;
