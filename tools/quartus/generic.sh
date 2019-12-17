# This file contains a lot of
# convenience functions and
# definitions.
#
# You will notice that mostly the caller
# has little or no influence on the function
# call; this is done on purpose.
#
# (at least some of) The scripts which 
# build on/make decisions based on the values
# returned from these functions are either
# run as root or run with root privilege.
#
# For the moment I (HV) decided to eliminate
# as much user-input-error as possible,
# giving the user as little possibility
# of passing in 'the wrong thing' before
# ruining something.
#

# make sure that use of unset vars triggers an error (-u)
# and automatically export to subsequent commands (-a)
# DS: no longer using set -u as it renders some tests 
#(e.g. test -z $1) unusable.
#set -ua 
set -a
#exits on any error in pipeline, not just the last error
set -o pipefail

# only set variables if we didn't set them before
if [ "${generic_read:-not_set}" = "not_set" ]; then

# display a (colourfull ...) error message. 
#    the script will be terminated immediately
# exit with <errorcode> (default=1)
# usage:  unb_error <caller> <message> [<errorcode>]
unb_error() {
    caller=${1:-""}
    msg=${2:-""}
    exitcode=${3:-1}
    if [ -z "${caller}" -o -z "${msg}" ]; then
        echo "usage: unb_error <caller's name> <message> [<exitcode>]"
        exit 1
    fi
    caller=`basename ${caller} | tr [a-z] [A-Z]`
    echo -en '\E[40;36m'"\033[1m[${caller}]\033[0m "
    echo -e '\E[40;31m'"\033[1mERROR - ${msg}. \033[0m "
    tput sgr0
    # Exit if $NO_EXIT does not exist, else only return.
    if [ -z ${NO_EXIT} ]; then exit ${exitcode}; else return 1; fi
}

# Non-exiting version of unb_error in case we wish to accumulate errors and
# call an exiting unb_error after displaying accumulated errors.
unb_error_noexit() {
    caller=${1:-""}
    msg=${2:-""}
    if [ -z "${caller}" -o -z "${msg}" ]; then
        echo "usage: unb_error <caller's name> <message> [<exitcode>]"
        exit 1
    fi
    caller=`basename ${caller} | tr [a-z] [A-Z]`
    echo -en '\E[40;36m'"\033[1m[${caller}]\033[0m "
    echo -e '\E[40;31m'"\033[1mERROR - ${msg}. \033[0m "
    tput sgr0
}

unb_warning() {
    caller=${1:-""}
    msg=${2:-""}
    exitcode=${3:-1}
    if [ -z "${caller}" -o -z "${msg}" ]; then
        echo "usage: unb_warning <caller's name> <message> [<exitcode>]"
        exit 1
    fi
    caller=`basename ${caller} | tr [a-z] [A-Z]`
    echo -en '\E[40;36m'"\033[1m[${caller}]\033[0m "
    echo -e '\E[40;35m'"\033[1mWARNING - ${msg}. \033[0m "
    tput sgr0
    return 0 
}


# usage:  unb_info <caller> <message>
unb_info() {
    caller=${1:-""}
    shift
    if [ -z "${caller}" -o -z "$*" ]; then
        echo "usage: unb_info <scriptname> <msg1> [<msg2> .. <msgN>]"
        exit 1
    fi
    caller=`basename ${caller} | tr [a-z] [A-Z]`
    echo -e '\E[40;36m'"\033[1m[${caller}] $* \033[0m "
    tput sgr0
    return 0
}

# usage:
#   unb_exec <calling script> [OPTS] <command to run>
#  OPTS:
#     [msg=<override defaultmsg>]
#           msg=no => suppress displaying of messages
#                     if command fails, do display the
#                     command that failed
#     [expect=<expected exit code>] (default: 0)
# exits with same exitcode as the command
unb_exec() {
    # step one: extract calling scriptname, which is $1
    caller=$1; shift
    # anything left is supposedly the command to exec + args
    # prepare the "msg" to display
    msg=
    output=
    expect=0
    # unless someone gave msg="...." as orginal 2nd arg
    #  (and now, since the first "shift", it is 1st)
    for ac ; do
        case ${ac} in 
            output=*)
                # well allrighty then, override default msg 
                output=`echo "${ac}" | sed 's/^output=//'`
                shift
                ;;
            msg=*)
                # well allrighty then, override default msg 
                msg=`echo "${ac}" | sed 's/^msg=//'`
                shift
                ;;
            expect=*)
                expect=`echo "${ac}" | sed 's/^expect=//'`
                shift
                ;;
            * )
                # first non-option argument; stop for loop!
                break
                ;;
        esac
    done
    if [ -z "${msg}" ]; then
        msg="Running \"$*\""
    fi
    # show usr what we're up to
    if [ "${msg}" != "no" ]; then
        unb_info ${caller} "${msg}"
    fi
    # and let's actually do it!
    if [ "${output}" = "no" ]; then
      $* >/dev/null 2>/dev/null
    else
      $*
    fi

    exitcode=$?
    if [ "${exitcode}" -ne "${expect}" ]; then
        if [ "${msg}" == "no" ]; then
            echo "****** Failed command ****"
            echo $*
            exit ${exitcode}
        fi
        unb_error ${caller} "\"${msg}\" failed" $?
    fi
}

# format the date in a specific form
# if changing the format, make sure
# that dateindent has the same length
# again (dateindent used for pretty
# printing multiline stuff without
# having to print the date in every line)
date="/bin/date +'%d %m %Y %T'"
# format    dd mm yyyy HH:MM:ss
dateindent='                   '

#
# Some generic, often used functions
#

# return the current date/time in a
# predefined format - see above
# Use eg as
# echo "`timestamp` Aaargh - Failed to clobber!"
timestamp() {
	eval ${date}
}


# strip both leading/trailing whitespace
# characters
strip_ws() {
    rv=
    if [ -n "$1" ]; then
        # actually, you can do it in one go [when you
        # finally read the fine manual of sed ;)]
        cmd="echo '$1' | ${sed} 's/^ \{0,\}//;s/ \{0,\}$//'"
        rv=`eval ${cmd}`
    fi
    echo ${rv}
}

# escape special characters
escape_chars() {
    rv=
    cmd="echo '${1}' | ${sed} 's#\([].,*[() \\\\/]\)#\\\\\1#g'"
    rv=`eval ${cmd}`
    echo ${rv}
}

# write all arguments to the logfile
dbglogfile="/tmp/dbglogfile"
dbglog() {
    touch ${dbglogfile}
    txt=
    for ac do
        txt="${txt} ${ac}"
    done
    echo ${txt} >> ${dbglogfile}
}

# if the argument is a single string
# return 1 otherwise return 0
# Single string meaning 
# 'series of characters without
#  space'
# Leading/trailing whitespace is
# ignored in the comparison
#
# Note: an empty string will
#       NOT be matched as
#       a single string and
#       hence returns '0'
is_single_string() {
    rv=0
    if [ -n "$1" ]; then
        ltrem=`strip_ws "$1"`
        # now see what happens if we remove remaining ws
        cmd="echo '${ltrem}' | ${sed} 's/ //g'"
        sstr=`eval ${cmd}`
        if [ "${sstr}" = "${ltrem}" ]; then
            rv=1
        fi
    fi
    echo ${rv}
}


# Mark the fact that we read this file...
generic_read="yes"

# this is the final fi of the 'include guard'
fi

# Add to the $PATH, only once to avoid double entries
pathadd() {
    if [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="${PATH:+"$PATH:"}$1"
    fi
}
