#!/bin/bash

##  Command line tool to generate invoices from templates. 
##  Copyright (C) 2026  niebl
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License along
##  with this program; if not, write to the Free Software Foundation, Inc.,
##  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# get arguments from user
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--number)
      INVOICENR="$2"
      shift # past argument
      shift # past value
      ;;
    -n|--name)
      CLIENTNAME="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--street)
      CLIENTSTREET="$2"
      shift # past argument
      shift # past value
      ;;
    -z|--ZIP)
      CLIENTZIP="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--city)
      CLIENTCITY="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--date)
      CREATIONDATE="$2"
      shift # past argument
      shift # past value
      ;;
    -dd|--duedate)
      CREATIONDATE="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--language)
      INVOICELANGUAGE="$2"
      shift # past argument
      shift # past value
      ;;
    #TODO: Allow for multiple entries
    -S|--service)
      PRODUCT="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--price)
      PRICE="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

interactiveMode() {
  # set default variables
  if [[ -z ${INVOICELANGUAGE+x} ]]; then
    read -p "select invoice langauge [de / en]:
                          ^       " user_lang
    if [[ "x$user_clientname" == x || "$user_lang" == "de" || "$user_lang" == "en" ]]; then
      LANGSHORT=$user_lang
      INVOICELANGUAGE=$( [[ "$LANGSHORT" == "de" ]] && echo "german" || echo "english" )
    else
      echo "invalid input"
      exit 2
    fi
  fi
  if [[ -z ${INVOICENR+x} ]]; then
    read -p "enter the invoice-nr (required): 
    " user_invoicenr
    if [ "x$user_invoicenr" = x ]; then
      echo "invalid input"
      exit 2
    fi
    INVOICENR=$user_invoicenr
  fi
  if [[ -z ${CLIENTNAME+x} ]]; then
    read -p "enter the name of your client (required): 
    " user_clientname
    if [ "x$user_clientname" = x ]; then
      echo "invalid input"
      exit 2
    fi
    CLIENTNAME=$user_clientname
  fi
  if [[ -z ${CLIENTSTREET+x} ]]; then
    read -p "enter the street-name of your client (blank if empty): 
    " user_cstreet
    CLIENTSTREET=${user_cstreet:-"\leavevmode"}
  fi
  if [[ -z ${CLIENTZIP+x} ]]; then
    read -p "enter the zip code of your client (blank if empty): 
    " user_czip
    CLIENTZIP=${user_czip:-"\leavevmode"}
  fi
  if [[ -z ${CLIENTCITY+x} ]]; then
    read -p "enter the city-name of your client (blank if empty): 
    " user_ccity
    CLIENTCITY=${user_ccity:-"\leavevmode"}
  fi
  if [[ -z ${CREATIONDATE+x} ]]; then
    local TODAY=$(date --iso-8601)
    read -p "enter a date [$TODAY]: 
    " user_date
    CREATIONDATE=${user_date:-$TODAY}
  fi
  if [[ -z ${DUEDATE+x} ]]; then
    read -p "enter a due-date [$CREATIONDATE]: 
    " user_duedate
    DUEDATE=${user_date:-$CREATIONDATE}
  fi
}

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

interactiveMode

echo "CREATING INVOICE ${INVOICENR}"
echo "FOR ${CLIENTNAME}"
echo "INVOICE DATE: ${CREATIONDATE}"
echo "DUE DATE: ${DUEDATE}"
echo "SERVICE: $PRODUCT: $PRICE"

# load invoice text templates
source templates/invoice_text.sh

# REPLACE VALUES
TEMPLATE=$(cat templates/invoice-template.tex)
DATA=${TEMPLATE/"%date"/$CREATIONDATE}
DATA=${DATA/"%duedate"/$DUEDATE}
DATA=${DATA/"%number"/$INVOICENR}
DATA=${DATA/"%customerName"/$CLIENTNAME}
DATA=${DATA/"%customerStreet"/$CLIENTSTREET}
DATA=${DATA/"%customerZIP"/$CLIENTZIP}
DATA=${DATA/"%customerCity"/$CLIENTCITY}
DATA=${DATA/"%service"/$PRODUCT}
DATA=${DATA/"%price"/$PRICE}
DATA=${DATA/"%language"/$INVOICELANGUAGE}
SALUTATION="$( [[ "$INVOICELANGUAGE" == "english" ]] && echo "$SALUTATION_EN" || echo "$SALUTATION_DE")"
CLOSING="$( [[ "$INVOICELANGUAGE" == "english" ]] && echo "$CLOSING_EN" || echo "$CLOSING_DE")"
BODY="$( [[ "$INVOICELANGUAGE" == "english" ]] && echo "$INVOICEBODY_EN" || echo "$INVOICEBODY_DE")"
USTG="$( [[ "$INVOICELANGUAGE" == "english" ]] && echo "$USTGNOTE_EN" || echo "$USTGNOTE_DE")"
DATA=${DATA/"%salutation"/"$SALUTATION"}
DATA=${DATA/"%closing"/"$CLOSING"}
DATA=${DATA/"%body"/"$BODY"}
DATA=${DATA/"%ustg"/"$USTG"}

echo "$DATA" > templates/invoice-data.tex

# generate and display pdf

cd templates
pdflatex main.tex
cp main.pdf "../invoice_$LANGSHORT_$INVOICENR.pdf"
cd ..
okular "invoice_$LANGSHORT_$INVOICENR.pdf"

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi