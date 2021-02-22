#!/bin/bash


### INITIALIZATION ###

year=$(date +%Y 1>&1) #current year by default

# mode 0: Simone Giertz's every day calendar inspired output
# mode 1: mode 1 with shifted columns to align days of the week
mode=1

# output 0: normal text output
# output 1: html output (supports underlineing and bordering)
ouput=0 #output (cli or to file (need name))

# lines 0: no underlineing (compatible with output=0)
# lines 1: underline sundays (to differ weeks) (requires output=1)
# lines 2: overline saturday and underline sundays (to differ weekends) (requires output=1)
lines=0

# current 0: no current date infromation
# current 1: prints additional info about current date add border around current day or brackets if output=0
current=0

# spaced 1: month columns are one space appart
# spaced n: month columns are n spaces appart
space=1

todays_date=$(date "+%F")


print_usage() {
	printf "Usage: ..."
}

# set the flags
while getopts 'y:m:o:l:cs:' flag; do
	case "${flag}" in
		y) year=${OPTARG} ;;
		m) mode=${OPTARG} ;;
		o) output=${OPTARG} ;;
		l) lines=${OPTARG} ;;
		c) current=1 ;;
		s) space=${OPTARG} ;;
		*) print_usage
			exit 1;;
	esac
done


### CREATE CALENDAR TABLE ###

# need to declare with -A flag (associateve arrays) because bash doesnt have true 2D arrays
declare -A calendar

# fill header with month names
if [[ $output -eq 0 ]]; then
	calendar[0,0,0]=" j"
	calendar[0,1,0]=" f"
	calendar[0,2,0]=" m"
	calendar[0,3,0]=" a"
	calendar[0,4,0]=" m"
	calendar[0,5,0]=" j"
	calendar[0,6,0]=" j"
	calendar[0,7,0]=" a"
	calendar[0,8,0]=" s"
	calendar[0,9,0]=" o"
	calendar[0,10,0]=" n"
	calendar[0,11,0]=" d"
elif [[ $output -eq 1 ]]; then
	calendar[0,0,0]="&nbsp;j"
	calendar[0,1,0]="&nbsp;f"
	calendar[0,2,0]="&nbsp;m"
	calendar[0,3,0]="&nbsp;a"
	calendar[0,4,0]="&nbsp;m"
	calendar[0,5,0]="&nbsp;j"
	calendar[0,6,0]="&nbsp;j"
	calendar[0,7,0]="&nbsp;a"
	calendar[0,8,0]="&nbsp;s"
	calendar[0,9,0]="&nbsp;o"
	calendar[0,10,0]="&nbsp;n"
	calendar[0,11,0]="&nbsp;d"
fi

for (( m=1; m<=12; m++ )); do # for each month
	# get month length (date of first of this month + 1 month - 1 day = last of this month)
	month_len=$(date -d "$year-$m-01 + 1 month - 1 day" "+%d")

	shift_days=0;
	if (( $mode == 1 )); then
		# get shift amount (get day of the week (mon=1) minus 1 for the first day of the month)
		shift_days=$(( $(date -d "$year-$m-01" "+%u") - 1 ))
	fi

	for (( d=1; d<=$month_len; d++ )); do # for each day in this month
		# save the day (with leading zeros) in table ($m-1 because start with zero)
		calendar[$(( $d + $shift_days )),$(( $m - 1 )),0]=$(printf "%02d" $d)

		if [ $lines -eq 1 ] || [ $lines -eq 2 ]; then
			# note day of week for use with -l flag
			day_of_week=$(date -d "$year-$m-$d" "+%u")
			calendar[$(( $d + $shift_days )),$(( $m - 1 )),1]=$(printf $day_of_week)
		fi

		if [ $current -eq 1 ]; then
			# note current date for use with -c flag by comparing to todays_date
			if [ $todays_date = $(date -d "$year-$m-$d" "+%F") ]; then
				calendar[$(( $d + $shift_days )),$(( $m - 1 )),2]=1
			fi
		fi
	done
done


### OUTPUT ###

calendar_string=""

# build html structure with some simple css for -l and -c flags
if [[ $output -eq 1 ]]; then
	calendar_string+="<!DOCTYPE html>\n<html>\n<head>\n<style>\nbody {\n\tfont-family: 'Courier';\n}\n"
	if [[ $lines -gt 0 ]]; then
		calendar_string+=".u {\n\ttext-decoration: underline;\n}\n"
	fi

	if [[ $lines -gt 1 ]]; then
		calendar_string+=".o {\n\ttext-decoration: overline;\n\ttext-decoration-color: darkgray;\n}\n"
	fi

	if [[ $current -eq 1 ]]; then
		calendar_string+=".curr {\n\tborder: 1px solid red;\n\tmargin-left: -2px;\n\tmaring-right: -2px;\n}\n"
	fi

	calendar_string+="</style>\n</head>\n<body>\n"
fi

# print header
# if -c or -l flag is used with cli output (-o 0) we need to ensure first column has space before (for possible [ or _/¨ characters)
if [[ $output -eq 0 ]] && ( [[ $current -eq 1 ]] || [[ $lines -gt 0 ]] ); then
	if [[ $output -eq 0 ]]; then
		calendar_string+=" "
	elif [[ $output -eq 1 ]]; then
		calendar_string+="&nbsp;"
	fi
fi

# build the header row
for (( i=0; i<12; i++ )); do
	if [[ $output -eq 1 ]]; then
		calendar_string+="<span>"
	fi

	calendar_string+="${calendar[0,$i,0]}"

	if [[ $output -eq 1 ]]; then
		calendar_string+="</span>"
	fi

	# insert proper amount of spaces between
	temp_spaces=0
	for (( s=$temp_spaces; s<$space; s++ )); do
		if [[ $output -eq 0 ]]; then
			calendar_string+=" "
		elif [[ $output -eq 1 ]]; then
			calendar_string+="&nbsp;"
		fi
	done
done

# insert empty line after header
if [[ $output -eq 0 ]]; then
	calendar_string+="\n\n"
elif [[ $output -eq 1 ]]; then
	calendar_string+="<br /><br />\n\n"
fi

# print days
for (( i=1; i<=37; i++ )); do
	# if -c or -l flag is used with cli output (-o 0) we need to ensure first column has space before (for possible [ or _/¨ characters)
	if [[ $output -eq 0 ]] && ( [[ $current -eq 1 ]] || [[ $lines -gt 0 ]] ); then
		if [[ $output -eq 0 ]]; then
			calendar_string+=" "
		elif [[ $output -eq 1 ]]; then
			calendar_string+="&nbsp;"
		fi
	fi

	for (( j=0; j<12; j++ )); do # for each month (quazi column)

		# if cli: overwrite last character with appropritat [, _, ¨ or " " character
		# if html: insert appropritate classes and html structure
		if [[ $output -eq 0 ]]; then
			if [[ $space -gt 0 ]]; then
				if [[ $current -eq 1 ]] && [[ ${calendar[$i,$j,2]} ]]; then
					calendar_string="${calendar_string::-1}["
				elif ( [[ $current -eq 1 ]] || [[ $lines -gt 0 ]] ) && [[ ${calendar_string: -1} != "]" ]]; then
					if ( [[ $lines -gt 0 ]] && [[ ${calendar[$i,$j,1]} -eq 7 ]] ) || ( [[ -z ${calendar[$i,$j,0]} ]]  && [[ ${calendar_string: -1} == "_" ]]); then
						calendar_string="${calendar_string::-1}_"
					elif ( [[ $lines -gt 1 ]] && [[ ${calendar[$i,$j,1]} -eq 6 ]] ) || ( [[ -z ${calendar[$i,$j,0]} ]]  && [[ ${calendar_string: -1} == "¨" ]] ); then
						calendar_string="${calendar_string::-1}¨"
					else
						calendar_string="${calendar_string::-1} "
					fi
				fi
			fi
		elif [[ $output -eq 1 ]]; then
			calendar_string+="<span class='"

			if [[ $lines -gt 0 ]] && [[ ${calendar[$i,$j,1]} -eq 7 ]]; then
				calendar_string+="u "
			fi

			if [[ $lines -gt 1 ]] && [[ ${calendar[$i,$j,1]} -eq 6 ]]; then
				calendar_string+="o "
			fi

			if [[ $current -eq 1 ]] && [[ ${calendar[$i,$j,2]} ]]; then
				calendar_string+="curr"
			fi

			calendar_string+="'>"
		fi

		if [ -z ${calendar[$i,$j,0]} ]; then # fill empty space if cell not set
			if [[ $output -eq 0 ]]; then
				calendar_string+="  "
			elif [[ $output -eq 1 ]]; then
				calendar_string+="&nbsp;&nbsp;"
			fi
		else # print the day if cell is set
			calendar_string+="${calendar[$i,$j,0]}"
		fi

		temp_spaces=0

		# this is WIP code (need to figure out how to insert brackets for cli and border class for html)
		#printf "]"
		# if cli: add appropiate ], _ or ¨ characters and shorten the number of remaining spaces by 1
		# if html: add html closing structure
		if [[ $output -eq 0 ]]; then
			if [[ $space -gt 0 ]]; then
				if [[ $current -eq 1 ]] && [[ ${calendar[$i,$j,2]} ]]; then
					calendar_string+="]"
					temp_spaces=1
				else
					if [[ $lines -gt 0 ]] && [[ ${calendar[$i,$j,1]} -eq 7 ]]; then
						calendar_string+="_"
						temp_spaces=1
					fi

					if [[ $lines -gt 1 ]] && [[ ${calendar[$i,$j,1]} -eq 6 ]]; then
						calendar_string+="¨"
						temp_spaces=1
					fi
				fi
			fi
		elif [[ $output -eq 1 ]]; then
			calendar_string+="</span>"
		fi

		# insert proper amount of spaces after
		for (( s=$temp_spaces; s<$space; s++ )); do
			if [[ $output -eq 0 ]]; then
				calendar_string+=" "
			elif [[ $output -eq 1 ]]; then
				calendar_string+="&nbsp;"
			fi
		done
	done

	# break line for new new row
	if [[ $output -eq 0 ]]; then
		calendar_string+="\n"
	elif [[ $output -eq 1 ]]; then
		calendar_string+="<br />\n"
	fi
done

# print additional info for -c flag
if [ $current -eq 1 ]; then
	if [[ $output -eq 0 ]]; then
		calendar_string+=$(printf "\n%s\n%s\n%s (day of week[1-7]: %s)\n%s (week of the year [00-53])\n%s (day of the year [001-366])\n" "$(date)" "$(date +%d.%m.%Y)" "$(date +%A)" "$(date +%u)" "$(date +%U)" "$(date +%j)")
	elif [[ $output -eq 1 ]]; then
		calendar_string+=$(printf "<br />\n<span>%s</span><br />\n<span>%s</span><br />\n<span>%s (day of week[1-7]: %s)</span><br />\n<span>%s (week of the year [00-53])</span><br />\n<span>%s (day of the year [001-366])</span>\n" "$(date)" "$(date +%d.%m.%Y)" "$(date +%A)" "$(date +%u)" "$(date +%U)" "$(date +%j)")
	fi
fi

# add closing html strucure
if [[ $output -eq 1 ]]; then
	calendar_string+="\n</body>\n<html>\n"
fi

# print the full final string
printf "$calendar_string"

## NOTES ##
# brackets to indicate current day in cli output overwrite lines for saturday or sunday
# if lines are used with space of 1 (-s 1) the prefixing lines of next column will overwrite the appending lines of previous column. this has effect if non-shifting mode is used (-m 0) where the correct lines will be left of the column
