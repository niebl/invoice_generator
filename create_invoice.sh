#!/bin/bash

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
if [[ -z ${CLIENTSTREET+x} ]]; then
    CLIENTSTREET="\leavevmode"
fi
if [[ -z ${CLIENTZIP+x} ]]; then
    CLIENTZIP="\leavevmode"
fi
if [[ -z ${CLIENTCITY+x} ]]; then
    CLIENTCITY="\leavevmode"
fi

if [[ "$INVOICELANGUAGE" == "english" ]]; then
  LANGSHORT="en"
fi

echo "CREATING INVOICE ${INVOICENR}"
echo "FOR ${CLIENTNAME}"
echo "INVOICE DATE: ${CREATIONDATE}"
echo "DUE DATE: ${DUEDATE}"
echo "SERVICE: $PRODUCT: $PRICE"

SALUTATION_DE="Guten Tag,"
SALUTATION_EN="Greetings,"

INVOICEBODY_DE="Für die erbrachten Arbeiten erhalten Sie hiermit die folgende Rechnung.
\\\\Bitte Überweisen Sie den fälligen Betrag auf das folgende Bankkonto:
\\begin{center}
\\accountBankName, \\textbf{\\accountIBAN} (BIC: \\accountBIC) \\\\
\\end{center}
Bitte geben Sie auch die Rechnungsnummer (\\invoiceReference) im Betreff an."
INVOICEBODY_EN="For the listed services you are receiving the following invoice.
\\\\Please transfer the due amount to the following bank account:
\\begin{center}
\\accountBankName, \\textbf{\\accountIBAN} (BIC: \\accountBIC) \\\\
\\end{center}
Please mention the invoice number (\\invoiceReference) in the subject line."

USTGNOTE_DE="Die Rechnung enthält gemäß § 19 UStG keine Umsatzsteuer.\\\\"
USTGNOTE_EN="Die Rechnung enthält gemäß § 19 UStG keine Umsatzsteuer.\\\\VAT-Free according to § 19 section 1 UStG."

CLOSING_DE="Mit freundlichen Grüßen,"
CLOSING_EN="Best,"


# REPLACE VALUES
TEMPLATE=$(cat invoice/invoice-template.tex)
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

echo "$DATA" > invoice/invoice-data.tex

cd invoice
pdflatex main.tex
cp main.pdf "../invoice_$LANGSHORT_$INVOICENR.pdf"
cd ..
okular "invoice_$LANGSHORT_$INVOICENR.pdf"

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi
