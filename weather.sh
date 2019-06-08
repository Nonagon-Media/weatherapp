#!/bin/bash

# This function just displays proper usage of the script
fn_usage() {
	echo "USAGE EXAMPLE: weather.sh 10.0.1.120"
	exit 1
}

# This function ensures that the IP given is in the proper format
fn_validate_ip() {
	local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      OIFS=$IFS
      IFS='.'
      ip=($ip)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
          && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi
  return $stat
}

# This function takes care of the location and forecast
fn_get_weather() {
	local ip=$1
	
	# First get the location coordinates and strip off extraneous characters
	ip_location=$(curl --silent http://ipinfo.io/$ip | jq .loc | cut -d '"' -f2)

	# These are the parameters for my iteration
	# Normally I don't use 'declare' but jq is finnicky about strings vs integers
	declare -i start_index=0
	declare -i end_index=3

	# Run through these commands for each index variable. 
	# In this context, we are gathering data for today and the next 3 days
	# There is a way to do this with one call if you put the curl output into a file
	# and pipe that file into jq but I felt more comfortable this way
	for  (( index=$start_index; index<=$end_index; index++ ))
		do
			# Eventually jq gives us two values. These are assigned to timestamp and forecast variables
			# --argjson is required to keep jq from passing a string as an index (which it doesn't allow)
			read -r timestamp forecast <<< $(curl --silent https://api.darksky.net/forecast/6ce2cb95ebf7afee7f2d76afcc037fb3/$ip_location?exclude=currently,minutely,hourly,alerts,flags | jq --argjson jq_index $index '.daily.data[$jq_index] | "\(.time) \(.summary)"')

			# Some variable formatting to strip off extra quotation marks which break the date command
			current_epoch=$(echo $timestamp | cut -d '"' -f2)
			formatted_forecast=$(echo $forecast | cut -d '"' -f1)

			# Change epoch date from the curl result into a more human form
			current_date=$(date -d @$current_epoch +"%Y-%m-%d")

			# Display the results
			echo "$current_date: $formatted_forecast"
		done
	}

############
### MAIN ###
############

# Make sure we got an address
if [ -z "$1" ]
  then
  	# If no IP is given, use the current location.
  	# This dig command will obtain that
  	ip_address=$(dig -4 @resolver1.opendns.com ANY myip.opendns.com +short)
  else
  	# If an IP (or more specifically, some input) is given, assign it to our variable
  	ip_address=$1
fi

# Make sure the IP given was properly formatted.
# If the IP is properly formatted go ahead and calculate the weather
# Otherwise display a usage message and exit
if fn_validate_ip $ip_address; then stat='good' && fn_get_weather "$ip_address"; else stat='bad' && echo "$ip_address is not a valid IP address" && fn_usage; fi
