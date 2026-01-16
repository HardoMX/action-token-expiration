#!/bin/bash

set -euo pipefail

# Accept inputs from action configuration
token="$1" # The token to check
repository="$2" # The repository to check token against. Probably unnecessary, but needed for now
warn_days="$3" # The number of days before token expiration to start warning
error_early="$4" # Trigger an error if true, before the token has actually expired
current_date=$(date +%Y-%m-%d)
rotation_warning_days=$(test "$error_early" = "true" && echo $((warn_days + 16)) || echo 16)


# Set up colors
green="\033[0;32m"
yellow="\033[0;33m"
red="\033[0;31m"
nc="\033[0m" #No Color

export GITHUB_TOKEN="${token}"

# Get expiration date from Github API header
expiration_date=$(curl -IsH 'authorization: token '"$token" https://api.github.com/repos/"${repository}" | grep 'github-authentication-token-expiration' | grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}')


# Calculate the time to token expiration so we can display a message.
    days_until_expiry=$(( ( $(date -d "$expiration_date" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))

    expiration_message="This token will expire in ${days_until_expiry} days."

    if [[ $days_until_expiry -le $warn_days ]]; then
        if [[ $error_early == "true" ]]; then
            # Display an error if the token is set to expire in the future.
            echo -e "${red}ERROR: ${expiration_message}. Please rotate the token now.${nc}"
            exit 1
        fi
        # Display a notice that the token is going to expire within the month.
        echo -e "${yellow}WARNING: ${expiration_message}${nc}"
    elif [[ $days_until_expiry -le 0 ]]; then
        # Display an error if the token has already expired.
        echo -e "${red}ERROR: This token has expired.${nc}"
        exit 1
    else
        # Display a notice that says how many days are left on the token.
        echo -e "${green}${expiration_message}${nc}"
    fi

    # Display a reminder to add token rotation to the upcoming sprint.
    if [[ $days_until_expiry -le $rotation_warning_days ]]; then
        echo "Please make a plan to rotate the token in the next couple weeks."
    fi
