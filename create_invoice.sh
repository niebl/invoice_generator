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

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# set default variables
if [[ -z ${CREATIONDATE+x} ]]; then
    CREATIONDATE=$(date --iso-8601)
fi
if [[ -z ${DUEDATE+x} ]]; then
    DUEDATE=$CREATIONDATE
fi
if [[ -z ${INVOICELANGUAGE+x} ]]; then
    INVOICELANGUAGE="german"
    LANGSHORT="de"
fi
if [[ "$INVOICELANGUAGE" == "english" ]]; then
  LANGSHORT="en"
fi
if [[ -z ${CLIENTSTREET+x} ]]; then
    CLIENTSTREET="\leavevmode"
fi
if [[ -z ${CLIENTZIP+x} ]]; then
    CLIENTZIP="\leavevmode"
fi
if [[ -z ${CLIENTCITY+x} ]]; then
    CLIENTCITY="\leavevmode"
fi

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

interactiveMode() {
  
}