#!/bin/bash

source bashargs.sh
VERSION="0.0.1"


echo "************* main script sample **************************************"

# this function is called by bashargs.sh if ARG_HELP is true
show_help() {
    echo "bashargs.sh sample script"
    echo "OPTIONS:"
    bargs::show_usage "  "
}
# this function is called by bashargs.sh if ARG_VERSION is true
show_version() {
    echo "$VERSION"
}

# initialize global variable
bargs::init_global

# fixed option (optional)
#                 LABEL           OPTION  TYPE      REQUIRED  HELP                STORE  DEFAULT
bargs::add_option "ARG_VERSION"   "-v"     "bool"    "false"  "show version"       true  false
bargs::add_option "ARG_HELP"      "--help" "bool"    "false"  "show help message"  true  false
bargs::add_option_alias "ARG_VERSION" "--version"
bargs::add_option_alias "ARG_HELP" "-h"

# custom option
#                 LABEL           OPTION  TYPE       REQUIRED HELP                STORE  DEFAULT
bargs::add_option "ARG_A"         "-a"     "bool"    "true"   "this is -a"         none
bargs::add_option "ARG_BCD"       "--bcd"  "int"     "false"  "this is -bcd"       none  1024
bargs::add_option "ARG_EFG"       "--efg"  "bool"    "true"   "this is --efg"      none
bargs::add_option "ARG_IJK"       "--ijk"  "string"  "false"  "this is --ijk"      none  "ijk default value"
bargs::add_option_alias "ARG_EFG" "-e"

echo
echo "------- show all options settings ------"
bargs::show_all_option
echo "----------------------------------------"

# parse script arguments
bargs::parse "$@"

########### sample to handle values ###########
echo
echo "------------- show all values ----------"
bargs::show_all_value
echo "----------------------------------------"

echo
echo "------------- get a value ---------------"
echo "-a value is " $( bargs::get_value "ARG_A" )
echo "--bcd value is " $( bargs::get_value "ARG_BCD" )
echo "----------------------------------------"

echo
echo "------------- update a value ------------"
echo -n "-a value is " $( bargs::get_value "ARG_A" )
bargs::set_value "ARG_A" false
echo " ---> " $( bargs::get_value "ARG_A" )
echo "-----------------------------------------"

echo
echo "------------- delete a value ------------"
echo -n "--bcd value is " $( bargs::get_value "ARG_BCD" )
bargs::del_value "ARG_BCD"
echo " ---> " $( bargs::get_value "ARG_BCD" )
echo "-----------------------------------------"

######## sample to handle values in function #########
echo "********************************************************************"
myfunc_test() {
    bargs::init_local
    #                 LABEL           OPTION   TYPE      REQUIRED HELP                         STORE  DEFAULT
    bargs::add_option "MY_A"          "-a"     "bool"    "true"   "this is -a in myfunc"       none
    bargs::add_option "MY_BCD"        "--bcd"  "string"  "false"  "this is --bcd in myfunc"    none   "bcd default value"
    bargs::add_option "MY_STR"        "--str"  "string"  "true"   "this is --bcd in myfunc"    none

    bargs::parse "$@"
    bargs::show_all_value
}
echo
echo "************* myfunc sample 1 **************************************"
myfunc_test -a true --bcd mybcd --str "hello world 1"
echo "********************************************************************"
echo
echo "************* myfunc sample 2 **************************************"
myfunc_test -a false --str "hello world 2" -- after \"--\"  all option -h --help is ignored
echo "********************************************************************"