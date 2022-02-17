#!/bin/bash

die ()
{
  echo "$MY_NAME: $1"
  exit 1
}

MY_NAME="${0##*/}"

PARSED_ARGUMENTS="$(getopt -n "$MY_NAME" -o t:p:a --long type:,property:,all,value,no-legend,plain -- "$@")" || exit $?

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -t | --type)
      shift 2
      ;;
    -p | --property)
      IFS="," read -a PROPERTIES <<< $2
      shift 2
      ;;
    -a | --all)
      shift
      ;;
    --value)
      shift
      ;;
    --no-legend)
      shift
      ;;
    --plain)
      shift
      ;;
    --)
      shift;
      break
      ;;
    *)
      die "unexpected option: $1 - this should not happen."
      ;;
  esac
done

COMMAND="$1"
shift

UNITS=($@)

case "$COMMAND" in
  show)
    for UNIT in "${UNITS[@]}"
    do
      for PROPERTY in "${PROPERTIES[@]}"
      do
        case "$PROPERTY" in
          LoadState)
            echo "loaded"
            ;;
          ActiveState)
            echo "active"
            ;;
          SubState)
            sudo /usr/bin/supervisorctl status "$UNIT" | awk '{print tolower($2)}'
            ;;
          *)
            echo "unknown"
            ;;
        esac
      done
      echo ""
    done
    ;;

  list-units)
    sudo /usr/bin/supervisorctl status | awk '{print $1".service\tloaded\tactive\t"tolower($2)"\t"$1" service"}'
    ;;

  start | stop | restart)
    for UNIT in "${UNITS[@]}"
    do
      if [ "$UNIT" = "klipper" ]; then
        sudo /usr/bin/supervisorctl "$COMMAND" simulavr klipper
      else
        sudo /usr/bin/supervisorctl "$COMMAND" "$UNIT"
      fi
    done
    ;;

  *)
    die "unknown command '$COMMAND'"
    ;;
esac

exit 0