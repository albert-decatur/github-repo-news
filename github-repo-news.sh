#!/bin/bash
# tweet descriptions and URLs for new github repos that
# only takes into account repos that: 1) still exist, 2) meet user min size, 3) relate to trending twitter hashtags
# user args: 1) username:password for github (OAuth requests have a much higher rate limit), 2) minimum size of repo to consider (totally empty repos will always be ignored)
# NB: user arg for min size is optional
# TODO
  # limit to create events that represent the creation of repo 
  # limit to repos with names or descriptions that mention trending twitter hashtags
  # do not pull from last hour - not enough content
# example use: $0 "username:password" 1

authstring=$1
minsize=$2

# check if user included min size arg - if not then set to 0
if [[ -z $minsize ]]; then
	minsize=0
fi
# get githubarchive for the hour before the current hour
previous_hour=$(expr $(date +%H) - 1)
time_minus_hour=$( date +%Y-%m-%d-${previous_hour} )
curl -s "http://data.githubarchive.org/${time_minus_hour}.json.gz" |\
# gunzip to stdout
gunzip -c |\
# parse for create events, return github api url
jq 'select(.type=="CreateEvent")|.repo.url' |\
# get a unique list - repos are sometimes created and destroyed repeatedly
sort |\
uniq |\
# consider only repos over a size threshold set by the user
while read repo
do
	echo curl -u $authstring -s $repo | sh |\
	# ignore if empty repo
	# determine if min size is met
	# note that backslashes are *not* used to escape multiline commands in jq
	jq --arg minsize $minsize '
		select(.message!="Not Found")|
		select(.size>($minsize|tonumber))|
		[.name,.description,.html_url]|@csv
	'|\
	# reformat from jq csv output
	sed 's:\\"::g;s:^"\|"$::g'
done
