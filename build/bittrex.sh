#! /bin/bash
#===============================================================#
#
# BUILD CRYPTONET - (build-cryptonet.sh)
#
# Fetches the cryptocurrencies listed on various exchanges
# and sorts the incoming data into nodes and links for graphical
# rendering with d3.js (https://d3js.org).
#
# The following output schema is observed:
#
# {
#     "nodes": [{
#             "id": "",
#             "group": ""
#         }
#     ],
#     "links": [{
#             "source": "",
#             "target": "",
#             "value": ""
#         }
#     ]
# }
#
# Created by h8rt3rmin8r on 20190119
#
#===============================================================#

# VARIABLE DECLARATIONS

HERE=$(pwd)
SELF_NAME="build-cryptonet"
SELF_OUT="[${SELF_NAME}]"
COMBOGEN_SRC="https://pastebin.com/raw/wJ0sjLEa"
# Data document part variables
DOC_PART_OPEN='ewogICAgIm5vZGVzIjogW3sKCg=='
DOC_ITEM_ID='ICAgICAgICAgICAgImlkIjogCg=='
DOC_ITEM_GROUP='ICAgICAgICAgICAgImdyb3VwIjogCg=='
DOC_PART_SECTION='ICAgIF0sCiAgICAibGlua3MiOiBbewoK'
DOC_ITEM_SOURCE='ICAgICAgICAgICAgInNvdXJjZSI6IAo='
DOC_ITEM_TARGET='ICAgICAgICAgICAgInRhcmdldCI6IAo='
DOC_ITEM_VALUE='ICAgICAgICAgICAgInZhbHVlIjogCg=='
DOC_PART_CLOSE='ICAgIF0KfQoK'
DOC_ITEM_OPEN='ICAgICAgICB7Cg=='
DOC_ITEM_CLOSE='ICAgICAgICB9LAo='
DOC_ITEM_CLOSE_FINAL='ICAgICAgICB9Cg=='

# FUNCTION DECLARATIONS

function silent_listing() {
    # Fetch data and sort it into respective storage files for further processing
    BTRX_ARR=( $(curl -s 'https://bittrex.com/api/v1.1/public/getmarkets' | jq -r '.result | map(.MarketName) | .[]' | sort | uniq) )
    for i in ${BTRX_ARR[@]};
    do
        echo "xx${i}" | sed 's/xx.*-//g' >> quote-currencies.txt
        echo "${i}xx" | sed 's/\-.*//g' >> base-currencies.txt
    done
    return
}

function dataProcess_bittrex() {
    # Process data from Bittrex.com
    # Create fresh data storage locations for each fundamental section of the incoming data
    touch pairs.txt; echo -n > pairs.txt
    touch pairs-index.txt; echo -n > pairs-index.txt
    touch baseCurrencies.txt; echo -n > baseCurrencies.txt
    touch baseCurrencies-index.txt; echo -n > baseCurrencies-index.txt
    touch baseCount.txt; echo -n > baseCount.txt

    # Fetch the data

    ### (pairs.txt)
    curl -s 'https://bittrex.com/api/v1.1/public/getmarkets' | jq -r '.result | map(.MarketName) | .[]' | sort | uniq > pairs.txt

    # Process the locally stored data into respective storage locations

    ### (pairs-index.txt)
    awk '{print NR "-" $s}' pairs.txt > pairs-index.txt

    ### (baseCurrencies.txt)
    cat pairs.txt | while read line; do echo $line | cut -d '-' -f 1; done >> baseCurrencies.txt
    touch baseCurrencies-temp.txt
    echo -n > baseCurrencies-temp.txt
    cat baseCurrencies.txt | sort | uniq >> baseCurrencies-temp.txt

    ### (baseCurrencies-index.txt)
    awk '{print NR "-" $s}' baseCurrencies-temp.txt > baseCurrencies-index.txt

    ### (baseCount.txt)
    printf '%s' $(cat baseCurrencies.txt | wc -l) > baseCount.txt

    return
}

function dataProcess_bittrex_clear() {
    # Clean up the workspace after performing data processing on Bittrex Exchange data sets
    rm pairs.txt &>/dev/null
    rm pairs-index.txt &>/dev/null
    rm baseCurrencies.txt &>/dev/null
    rm baseCurrencies-index.txt &>/dev/null
    rm baseCurrencies-temp.txt &>/dev/null
    rm baseCount.txt &>/dev/null
    return
}

function document_build() {
    # Generate the required data source file for graphical rendering
    # Set runtime variables (these require prior execution of the data processing function)
    BASE_COUNT="$(cat baseCount.txt)"

    # Create the local empty document
    touch cryptoNet.json

    # Write the opening template information
    echo "${DOC_PART_OPEN}" | base64 -d > cryptoNet.json

    # Iterate across local data to write the first group of key-value pairs
    ### (base currencies)
    cat baseCurrencies-index.txt | while read line;
    do
        local ITEM_ID="$(echo $line | cut -d '-' -f2)"
        local ITEM_GROUP="$(echo $line | cut -d '-' -f1)"
        echo "$(echo ${DOC_ITEM_ID} | base64 -d)"'"'"${ITEM_ID}"'",' >> cryptoNet.json
        echo "$(echo ${DOC_ITEM_GROUP} | base64 -d)"'"'"${ITEM_GROUP}"'"' >> cryptoNet.json
        echo "${DOC_ITEM_CLOSE}" | base64 -d >> cryptoNet.json
        echo "${DOC_ITEM_OPEN}" | base64 -d >> cryptoNet.json
    done
    ### (quote currencies)
    cat pairs-index.txt | while read line;
    do
        local ITEM_ID="$(echo $line | cut -d '-' -f3)"
        local ITEM_REF="$(echo $line | cut -d '-' -f2)"
        local ITEM_GROUP="$(cat baseCurrencies-index.txt | grep "${ITEM_REF}$" | cut -d '-' -f1)"
        echo "$(echo ${DOC_ITEM_ID} | base64 -d)"'"'"${ITEM_ID}"'",' >> cryptoNet.json
        echo "$(echo ${DOC_ITEM_GROUP} | base64 -d)"'"'"${ITEM_GROUP}"'"' >> cryptoNet.json
        echo "${DOC_ITEM_CLOSE}" | base64 -d >> cryptoNet.json
        echo "${DOC_ITEM_OPEN}" | base64 -d >> cryptoNet.json
    done
    touch temp.json
    cat cryptoNet.json | sed '$ d' | sed '$ d' > temp.json
    echo "${DOC_ITEM_CLOSE_FINAL}" | base64 -d >> temp.json
    mv temp.json cryptoNet.json

    # Write the transition section between both key-value pair groups
    echo "${DOC_PART_SECTION}" | base64 -d >> cryptoNet.json

    # Iterate across local data to write the second group of key-value pairs
    cat pairs-index.txt | while read line;
    do
        local ITEM_SOURCE="$(echo $line | cut -d '-' -f2)"
        local ITEM_TARGET="$(echo $line | cut -d '-' -f3)"
        local ITEM_VALUE="1"
        echo "$(echo ${DOC_ITEM_SOURCE} | base64 -d)"'"'"${ITEM_SOURCE}"'",' >> cryptoNet.json
        echo "$(echo ${DOC_ITEM_TARGET} | base64 -d)"'"'"${ITEM_TARGET}"'",' >> cryptoNet.json
        echo "$(echo ${DOC_ITEM_VALUE} | base64 -d)"'"'"${ITEM_VALUE}"'"' >> cryptoNet.json
        echo "${DOC_ITEM_CLOSE}" | base64 -d >> cryptoNet.json
        echo "${DOC_ITEM_OPEN}" | base64 -d >> cryptoNet.json
    done
    touch temp.json
    cat cryptoNet.json | sed '$ d' | sed '$ d' > temp.json
    echo "${DOC_ITEM_CLOSE_FINAL}" | base64 -d >> temp.json
    mv temp.json cryptoNet.json

    # Write the closing of the data document
    echo "${DOC_PART_CLOSE}" | base64 -d >> cryptoNet.json

    # Prettyprint the json data and exit the doc builder function
    cat cryptoNet.json | jq '.' > cryptoNet-temp.json
    mv cryptoNet-temp.json cryptoNet.json
    return
}

function ask_if() {
    # Ask the terminal user a YES/NO question and wait for input
    # The programatic result of this function is an exported new variable "OUST".
    # The OUST variable will be either Y (yes), N (no), or X (unknown input).
    
    # Take the incoming question and format it into an array
    INST=""
    if [ -t 0 ]; then
        local IN=( $(echo "$@") )
    else
        local IN=( $(</dev/stdin) $(echo "$@") )
    fi
    INST=( $(echo ${IN[@]}) )

    # Ask the question to the terminal user
    read -p "$(echo ${INST[@]}) (Y/N):  " -n 1 REPLY
    echo

    # Parse the response and eliminate any potential injection attempts
    # then export the new variable "OUST" back to the calling function
    case $(echo "$REPLY" | tr '[A-Z]' '[a-z]' | tr -d "'*\\\"") in
        y)
            OUST="Y"
            # Bug test by uncommenting the following two lines:
            #echo "Your input: "'"'$(echo "$REPLY" | tr '[A-Z]' '[a-z]' | tr -d "'*\\\"")'"'
            #echo "OUST: "'"'${OUST}'"'
            export ${OUST}
            return
            ;;
        n)
            OUST="N"
            # Bug test by uncommenting the following two lines:
            #echo "Your input: "'"'$(echo "$REPLY" | tr '[A-Z]' '[a-z]' | tr -d "'*\\\"")'"'
            #echo "OUST: "'"'${OUST}'"'
            export ${OUST}
            return
            ;;
        *|'')
            OUST="X"
            # Bug test by uncommenting the following two lines:
            #echo "Your input: "'"'$(echo "$REPLY" | tr '[A-Z]' '[a-z]' | tr -d "'*\\\"")'"'
            #echo "OUST: "'"'${OUST}'"'
            export OUST="X"
            return
            ;;
    esac
}

function depends_check_dos2unix() {
    # Verify the presence of the dos2unix
    if [[ ! "$(dos2unix --version &>/dev/null; echo $?)" == 0 ]];
    then
        echo "${SELF_OUT} ERROR: Required software 'dos2unix' is not installed!"
        ask_if "${SELF_OUT} Would you like to install dos2unix now?"
        case "${OUST}" in
            Y)
                echo "${SELF_OUT} Installing dos2unix"
                sleep 0.6
                sudo apt-get update
                sudo apt-get -y install dos2unix
                echo "${SELF_OUT} Done."
                ;;
            N)
                sleep 0.6
                echo "${SELF_OUT} You can install dos2unix manually with the following: "
                echo
                echo '   sudo apt-get -y install dos2unix'
                echo ""
                echo "${SELF_OUT} Exiting script"
                exit 1
                ;;
            X)
                echo "${SELF_OUT} Unknown response"
                sleep 0.6
                depends_check_dos2unix
                ;;
        esac
    fi
}

function depends_check_combogen() {
    # Verify the presence of the combogen script
    if [[ ! "$(combogen --version &>/dev/null; echo $?)" == 0 ]];
    then
        echo "${SELF_OUT} ERROR: Required software 'combogen' is not installed!"
        ask_if "${SELF_OUT} Would you like to install combogen now?"
        case "${OUST}" in
            Y)
                echo "${SELF_OUT} Installing combogen"
                sleep 0.6
                touch /usr/local/bin/combogen
                curl "https://pastebin.com/raw/wJ0sjLEa" | dos2unix > /usr/local/bin/combogen
                sudo chmod +x /usr/local/bin/combogen
                echo "${SELF_OUT} Done."
                ;;
            N)
                sleep 0.6
                echo "${SELF_OUT} You can install combogen manually with the following: "
                echo
                echo '   curl "https://pastebin.com/raw/wJ0sjLEa" | dos2unix > /usr/local/bin/combogen'
                echo '   sudo chmod +x /usr/local/bin/combogen'
                echo ""
                echo "${SELF_OUT} Exiting script"
                exit 1
                ;;
            X)
                echo "${SELF_OUT} Unknown response"
                sleep 0.6
                depends_check_combogen
                ;;
        esac
    fi
}

function depends_check_jq() {
    # Verify the presence of the jq
    if [[ ! "$(jq --version &>/dev/null; echo $?)" == 0 ]];
    then
        echo "${SELF_OUT} ERROR: Required software 'jq' is not installed!"
        ask_if "${SELF_OUT} Would you like to install jq now?"
        case "${OUST}" in
            Y)
                echo "${SELF_OUT} Installing jq"
                sleep 0.6
                sudo apt-get update
                sudo apt-get -y install jq
                echo "${SELF_OUT} Done."
                ;;
            N)
                sleep 0.6
                echo "${SELF_OUT} You can install jq manually with the following: "
                echo
                echo '   sudo apt-get -y install jq'
                echo ""
                echo "${SELF_OUT} Exiting script"
                exit 1
                ;;
            X)
                echo "${SELF_OUT} Unknown response"
                sleep 0.6
                depends_check_jq
                ;;
        esac
    fi
}

# VALIDATION AND FILTERING

depends_check_dos2unix
depends_check_combogen
depends_check_jq

if [[ "$1" == "--clear" ]];
then
    dataProcess_bittrex_clear
    exit 0
fi

# OPERATIONS EXECUTION

dataProcess_bittrex
document_build
dataProcess_bittrex_clear

#===============================================================#
