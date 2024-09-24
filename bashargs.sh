#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

shopt -s expand_aliases

: ${BARGS_INFO:=true}
: ${BARGS_DEBUG:=false}

alias bargs::init_global='eval "$(__bargs::init_global__)"'
__bargs::init_global__() {
cat << 'END'
    BARGS_LABEL=""
    declare -A BARGS_OPTION_LABEL
    declare -A BARGS_OPTION_SHORT
    declare -A BARGS_OPTION_LONG
    declare -A BARGS_TYPE
    declare -A BARGS_REQUIRED
    declare -A BARGS_HELP
    declare -A BARGS_DEFAULT
    declare -A BARGS_STORE
    declare -A BARGS_VALUE
    declare -a BARGS_ARG
END
}

alias bargs::init_local='eval "$(__bargs::init_local__)"'
__bargs::init_local__() {
cat << 'END'
    local BARGS_LABEL=""
    local -A BARGS_OPTION_LABEL
    local -A BARGS_OPTION_SHORT
    local -A BARGS_OPTION_LONG
    local -A BARGS_TYPE
    local -A BARGS_REQUIRED
    local -A BARGS_HELP
    local -A BARGS_DEFAULT
    local -A BARGS_STORE
    local -A BARGS_VALUE
    local -a BARGS_ARG
END
}

__bargs::show_stack_trace__() {
    local i
    echo "  --- STACK TRACE ---" >&2
    for ((i=1; i<${#FUNCNAME[*]}; i++)); do
        echo "  ${FUNCNAME[$i]}() ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}" >&2
    done
}

# echo functions
bargs::echo_error() {
    echo "BARGS_ERROR: $*" >&2
    __bargs::show_stack_trace__
}

bargs::echo_error_and_exit() {
    bargs::echo_error "$*"
    exit 1
}

bargs::echo_info() {
    [[ "$BARGS_INFO" == "true" ]] && echo "BARGS: $*" >&2
}
bargs::echo_debug() {
    [[ "$BARGS_DEBUG" == "true" ]] && echo "BARGS_DEBUG: in ${FUNCNAME[1]}(): $*" >&2
}

# show help
bargs::help() {
    echo "Usage: source $0"
}

# cleck if label exists
has_label() {
    local LABEL="$1"
    local label

    [[ -z "$LABEL" ]] && bargs::echo_error_and_exit "has_label(): args is empty"
    for label in $BARGS_LABEL; do
        [[ "$label" == "$LABEL" ]] && return 0
    done
    return 1
}

# cleck if option exists
has_option() {
    local OPTION="$1"
    [[ -z "$OPTION" ]] && bargs::echo_error_and_exit "has_option(): args is empty"
    for label in $BARGS_LABEL; do
        [[ "${BARGS_OPTION_SHORT[$label]}" == "$OPTION" || "${BARGS_OPTION_LONG[$label]}" == "$OPTION" ]] && return 0
    done
    return 1
}

# Add an option
# arg1: label (required)
# arg2: option name (required)
# arg3: type (required)
#       type can be one of: string, int, bool
# arg4: required (required)
#       required can be one of: true, false
# arg5: help (required)
# arg6: store (required)
#       store can be one of: none, true, false
# arg7: default value (optional)
bargs::add_option() {
    local LABEL="$1"
    local OPTION="$2"
    local TYPE="$3"
    local REQUIRED="$4"
    local HELP="$5"
    local STORE="$6"
    local DEFAULT="$7"

    # check option
    [[ -z "$LABEL" ]] && bargs::echo_error_and_exit "label is empty"
    [[ "$LABEL" =~ " " ]] && bargs::echo_error_and_exit "$LABEL must not contain spaces"
    [[ -z "$OPTION" ]] && bargs::echo_error_and_exit "$LABEL option name is empty"
    [[ ! "$OPTION" =~ ^-{,2}[a-zA-Z]$ && ! "$OPTION" =~ ^--[a-zA-Z] ]] \
        && bargs::echo_error_and_exit "\"$OPTION\" must start with \"-\" or \"--\", and \"-\" require 1 character"
    [[ -z "$TYPE" ]] && bargs::echo_error_and_exit "$OPTION type is empty"
    [[ "$TYPE" != "string" && "$TYPE" != "int" && "$TYPE" != "bool" ]] \
        && bargs::echo_error_and_exit "$OPTION type \"$TYPE\" is invalid"
    [[ -z "$REQUIRED" ]] && bargs::echo_error_and_exit "required is empty"
    [[ "$REQUIRED" != "true" && "$REQUIRED" != "false" ]] && bargs::echo_error_and_exit "$OPTION required \"$REQUIRED\" is invalid"
    [[ -z "$HELP" ]] && bargs::echo_error_and_exit "$OPTION help is empty"
    [[ -z "$STORE" ]] && bargs::echo_error_and_exit "$OPTION store is empty"
    [[ "$STORE" != "none" && "$STORE" != "true" && "$STORE" != "false" ]] \
        && bargs::echo_error_and_exit "$OPTION store \"$STORE\" is invalid"
    if [[ "$STORE" == "true" || "$STORE" == "false" ]]; then
        [[ "$TYPE" != "bool" ]] && bargs::echo_error_and_exit "$OPTION store \"$STORE\" can only be used with type \"bool\""
    fi

    # check label
    has_label "$LABEL" && bargs::echo_error_and_exit "label \"$LABEL\" already exists"

    # check option
    has_option "$OPTION" && bargs::echo_error_and_exit "option \"$OPTION\" already exists"

    # check default
    if [[ "$TYPE" == "int" ]]; then
        if [[ ! -z "$DEFAULT" ]]; then
            [[ ! "$DEFAULT" =~ ^[0-9]+$ ]] && bargs::echo_error_and_exit "$OPTION default \"$DEFAULT\" must be an integer"
        fi
    fi
    if [[ "$TYPE" == "bool" ]]; then
        if [[ ! -z "$DEFAULT" ]]; then
            [[ "$DEFAULT" != "true" && "$DEFAULT" != "false" ]] \
                && bargs::echo_error_and_exit "$OPTION default \"$DEFAULT\" must be \"true\" or \"false\""
        fi
    fi

    # add option
    bargs::echo_debug "add LABEL: $LABEL, OPTION: $OPTION, TYPE: $TYPE, REQUIRED: $REQUIRED, HELP: $HELP, DEFAULT: $DEFAULT"
    BARGS_LABEL="$BARGS_LABEL $LABEL"
    BARGS_OPTION_LABEL["$OPTION"]="$LABEL"
    if [[ "$OPTION" =~ ^-- ]]; then
        BARGS_OPTION_LONG["$LABEL"]="$OPTION"
    else
        BARGS_OPTION_SHORT["$LABEL"]="$OPTION"
    fi
    BARGS_TYPE["$LABEL"]="$TYPE"
    BARGS_REQUIRED["$LABEL"]="$REQUIRED"
    BARGS_HELP["$LABEL"]="$HELP"
    BARGS_STORE["$LABEL"]="$STORE"
    BARGS_DEFAULT["$LABEL"]="$DEFAULT"
}

# add option alias
# arg1: label (required)
# arg2: alias (required)
bargs::add_option_alias() {
    local LABEL="$1"
    local ALIAS="$2"

    [[ -z "$LABEL" ]] && bargs::echo_error_and_exit "label is empty"
    [[ -z "$ALIAS" ]] && bargs::echo_error_and_exit "alias is empty"
    [[ ! "$ALIAS" =~ ^-{,2}[a-zA-Z]$ && ! "$ALIAS" =~ ^--[a-zA-Z] ]] \
        && bargs::echo_error_and_exit "\"$ALIAS\" must not start with \"-\" or \"--\", and \"-\" require 1 character"

    # check label
    has_label "$LABEL" || bargs::echo_error_and_exit "label \"$LABEL\" dose not exist"
    # check alias
    has_option "$ALIAS" && bargs::echo_error_and_exit "alias \"$ALIAS\" already exists"

    bargs::echo_debug "add LABEL: $LABEL, ALIAS: $ALIAS"
    if [[ "$ALIAS" =~ ^-- ]]; then
        BARGS_OPTION_LONG["$LABEL"]="$ALIAS"
        BARGS_OPTION_LABEL["$ALIAS"]="$LABEL"
    else
        BARGS_OPTION_SHORT["$LABEL"]="$ALIAS"
        BARGS_OPTION_LABEL["$ALIAS"]="$LABEL"
    fi
}

# check if arg is option
bargs::is_option() {
    local OPTION="$1"
    [[ -z "$OPTION" ]] && bargs::echo_error_and_exit "is_option(): args is empty"
    [[ "$OPTION" =~ " " ]] && return 1
    [[ ! "$OPTION" =~ ^-{,2}[a-zA-Z]$ && ! "$OPTION" =~ ^--[a-zA-Z] ]] && return 1
    return 0
}

# check value type
# arg1: type
# arg2: value
__bargs::check_value_type__() {
    local TYPE="$1"
    local VALUE="$2"
    [[ -z "$TYPE" ]] && bargs::echo_error_and_exit "TYPE is empty"
    [[ -z "$VALUE" ]] && bargs::echo_error_and_exit "VALUE is empty"
    [[ "$TYPE" != "string" && "$TYPE" != "int" && "$TYPE" != "bool" ]] \
        && bargs::echo_error_and_exit "type \"$TYPE\" is invalid"

    if [[ "$TYPE" == "int" ]]; then
        [[ ! "$VALUE" =~ ^[0-9]+$ ]] && bargs::echo_error_and_exit "value \"$VALUE\" must be an integer"
    fi
    if [[ "$TYPE" == "bool" ]]; then
        [[ "$VALUE" != "true" && "$VALUE" != "false" ]] \
            && bargs::echo_error_and_exit "value \"$VALUE\" must be \"true\" or \"false\""
    fi
    return 0
}

# parse args
bargs::parse() {
    local ARGS=("$@")
    local arg
    local num="-1"
    local next_arg
    local skip=false
    local skip_all=false
    local label
    local option
    local bargs_arg_num=0
    local type

    bargs::echo_debug "bargs::parse(): ${ARGS[*]}"
    for arg in "${ARGS[@]}"; do
        num=$(( $num + 1 ))
        if [[ "$skip_all" == "true" ]]; then
            BARGS_ARG[$bargs_arg_num]="$arg"
            bargs_arg_num=$(( $bargs_arg_num + 1 ))
            continue
        fi
        if [[ "$skip" == "true" ]]; then
            skip=false
            continue
        fi
        if [[ "$arg" == "--" ]]; then
            skip_all=true
            continue
        fi

        # fixed option
        if [[ "${FUNCNAME[1]}" == "main" ]]; then
            if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                if [[ "$( type -t show_help )" == "function" ]]; then show_help; else bargs::show_usage; fi
                exit 0
            fi
            if [[ "$arg" == "-v" || "$arg" == "--version" ]]; then
                if [[ "$( type -t show_version )" == "function" ]]; then show_version; else echo "no version"; fi
                exit 0
            fi
        else
            if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                bargs::show_usage ""
                exit 0
            fi
        fi

        bargs::echo_debug "bargs::parse(); parsing: $arg"
        if bargs::is_option "$arg"; then
            label="${BARGS_OPTION_LABEL[$arg]}"
            bargs::echo_debug "bargs::parse(): label:$label arg:$arg"
            if [[ -z "$label" ]]; then
                bargs::echo_error_and_exit "LABEL of \"$arg\" dose not exist"
            fi
            if [[ "${BARGS_STORE[$label]}" != "none" ]]; then
                [[ -n ${BARGS_VALUE["$label"]} ]] && bargs::echo_error_and_exit "$arg value is already set"
                bargs::echo_debug "bargs::parse(): $label value is ${BARGS_STORE[$label]}"
                BARGS_VALUE["$label"]="${BARGS_STORE[$label]}"
                skip=false
                continue
            fi
            next_arg="${ARGS[$(( $num + 1 ))]}"
            bargs::echo_debug "bargs::parse(): next_arg: $next_arg"
            [[ -z "$next_arg" ]] && bargs::echo_error_and_exit "$arg value is empty"
            bargs::is_option "$next_arg" && bargs::echo_error_and_exit "$arg value is empty"
            [[ -n ${BARGS_VALUE["$label"]} ]] && bargs::echo_error_and_exit "$arg value is already set"

            # check value type
            type="${BARGS_TYPE["$label"]}"
            __bargs::check_value_type__ "$type" "$next_arg" || exit 1

            BARGS_VALUE["$label"]="$next_arg"
            skip=true
            continue
        else
            BARGS_ARG[$bargs_arg_num]="$arg"
            bargs_arg_num=$(( $bargs_arg_num + 1 ))
        fi
    done

    # check required option
    for label in $BARGS_LABEL; do
        # get label option name
        if [[ -n "${BARGS_OPTION_SHORT[$label]}" ]]; then
            option="${BARGS_OPTION_SHORT[$label]}"
            if [[ -n "${BARGS_OPTION_LONG[$label]}" ]]; then
                [[ -z "$option" ]] && option="${BARGS_OPTION_LONG[$label]}"
                [[ -n "$option" ]] && option="$option or ${BARGS_OPTION_LONG[$label]}"
            fi
        else
            option="${BARGS_OPTION_LONG[$label]}"
        fi
        bargs::echo_debug "bargs::parse(): checking value: $label ($option)"

        # check required value is set
        [[ ${BARGS_REQUIRED["$label"]} == "true" && -z ${BARGS_VALUE["$label"]} ]] \
             && bargs::echo_error_and_exit "required option \"$option\" is not set"

        # set default value if value is not set
        if [[ ${BARGS_REQUIRED["$label"]} == "false" && -z ${BARGS_VALUE["$label"]} ]]; then
            BARGS_VALUE["$label"]="${BARGS_DEFAULT["$label"]}"
            case ${BARGS_TYPE["$label"]} in
                string) [[ -z ${BARGS_DEFAULT["$label"]} ]] && BARGS_VALUE["$label"]="";;
                int)    [[ -z ${BARGS_DEFAULT["$label"]} ]] && BARGS_VALUE["$label"]="0";;
                bool)   [[ -z ${BARGS_DEFAULT["$label"]} ]] && BARGS_VALUE["$label"]="false";;
                *) bargs::echo_error_and_exit "invalid type: ${BARGS_TYPE[$label]}";;
            esac
        fi
    done
}

# get value
bargs::get_value() {
    local label="$1"
    if ! has_label "$1"; then
        bargs::echo_error "label \"$label\" dose not defined"
        return 1
    fi
    echo "${BARGS_VALUE[$label]}"
}

# update value
bargs::set_value() {
    local label="$1"
    local value="$2"
    local type
    if ! has_label "$label"; then
        bargs::echo_error "label \"$label\" dose not defined"
        return 1
    fi
    type="${BARGS_TYPE[$label]}"
    __bargs::check_value_type__ "$type" "$value" || exit 1
    BARGS_VALUE["$label"]="$value"
}

# delete value
# arg1: label
#
# if type is string, value set empty.
# if type is int, value set 0.
# if type is bool, value set false.
bargs::del_value() {
    local label="$1"
    if ! has_label "$label"; then
        bargs::echo_error "label \"$label\" dose not defined"
        return 1
    fi
    case ${BARGS_TYPE["$label"]} in
        string) BARGS_VALUE["$label"]="";;
        int)    BARGS_VALUE["$label"]="0";;
        bool)   BARGS_VALUE["$label"]="false";;
        *) bargs::echo_error_and_exit "OOPS:invalid type: ${BARGS_TYPE[$label]}";;
    esac
}

# show all value
bargs::show_all_value() {
    local label
    for label in $BARGS_LABEL; do
        echo "$label=${BARGS_VALUE["$label"]}"
    done
    echo "BARGS_ARG=${BARGS_ARG[*]}"
}

# show all options as csv
bargs::show_all_option() {
    local label
    for label in $BARGS_LABEL; do
        echo -n "$label,"
        echo -n "${BARGS_OPTION_SHORT["$label"]},"
        echo -n "${BARGS_OPTION_LONG["$label"]},"
        echo -n "${BARGS_TYPE[$label]},"
        echo -n "${BARGS_REQUIRED[$label]},"
        echo -n "\"${BARGS_HELP[$label]}\","
        echo -n "${BARGS_STORE[$label]},"
        echo "\"${BARGS_DEFAULT[$label]}\""
    done
}

# show usage for help message
bargs::show_usage() {
    local PREFIX=$1
    local label
    local required
    local value

    for label in $BARGS_LABEL; do
        value=""
        if [[ ${BARGS_REQUIRED["$label"]} == "true" ]]; then
            required="(required)"
        else
            required="(optional)"
        fi
        [[ "${BARGS_STORE["$label"]}" == "none" ]] && value=" VALUE"

        if [[ -n "${BARGS_OPTION_SHORT["$label"]}" ]]; then
            echo -n "${PREFIX}* ${BARGS_OPTION_SHORT["$label"]}"
            if [[ -n "${BARGS_OPTION_LONG["$label"]}" ]]; then
                echo -n ", ${BARGS_OPTION_LONG["$label"]}"
                echo -e "${value}\t${required}"
            else
                echo -e "${value}\t\t\t${required}"
            fi
        else
            echo -n "${PREFIX}* ${BARGS_OPTION_LONG["$label"]}"
            echo -e "${value}\t\t${required}"
        fi
        echo "$PREFIX  * ${BARGS_HELP[$label]}"
        if [[ "${BARGS_STORE["$label"]}" == "none" ]]; then
            echo "$PREFIX  * VALUE: ${BARGS_TYPE[$label]}"
        fi
        if [[ "${BARGS_STORE["$label"]}" == "none" && "${BARGS_REQUIRED["$label"]}" == "false" ]]; then
            echo "$PREFIX  * DEFAULT: \"${BARGS_DEFAULT[$label]}\""
        fi
    done
}