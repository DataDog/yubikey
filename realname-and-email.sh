#!/bin/bash

# Stop on error.
set -e

source env.sh

# Get some information from the user.

# 1. Real name.
REALNAME=$($GIT config --global --default '' --get user.name)
echo "What is the real name you use on GitHub?"
read -rp "Real name (press Enter to accept '$REALNAME'): " input

if [[ -z $REALNAME ]]
then
  if [[ -z $input ]]
  then
    echo "No name given!"
    exit 1
  else
    REALNAME=$input
    echo "Using given input: $REALNAME"
  fi
else
  if [[ -z $input ]]
  then
    echo "Using given user.name: $REALNAME"
  else
    REALNAME=$input
    echo "Using given input: $REALNAME"
  fi
fi

REALNAME_LEN=${#REALNAME}
if [[ $REALNAME_LEN -lt 5 ]]
then
  echo "Real name has $REALNAME_LEN < 5 characters!"
  exit 2
fi

echo

# 2. Email address.
EMAIL=$($GIT config --global --default '' --get user.email)
echo "What is an email address you have registered with GitHub?"
read -rp "Email (press Enter to accept '$EMAIL'): " input

if [[ -z $EMAIL ]]
then
  if [[ -z $input ]]
  then
    echo "No email given!"
    exit 3
  else
    EMAIL=$input
    echo "Using given input: $EMAIL"
  fi
else
  if [[ -z $input ]]
  then
    echo "Using given user.email: $EMAIL"
  else
    EMAIL=$input
    echo "Using given input: $EMAIL"
  fi
fi

echo
