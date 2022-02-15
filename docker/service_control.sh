#!/bin/bash
validate_arguments ()
{
  if [ "$1" != "0" ]; then
    exit 1
  fi
}

parse_show ()
{
  PARSED_ARGUMENTS=$(getopt -a -n systemctl -o p: --long properties:,values -- "$@")

  validate_arguments $?

  eval set -- "$PARSED_ARGUMENTS"
  while :
  do
    case "$1" in
      -p | --properties)
        IFS="," read -a PROPERTIES <<< $2
        shift 2
        ;;
      --values)
        shift
        ;;
      --)
        shift;
        UNITS=($@)
        break
        ;;
      *)
        echo "systemctl: unexpected option: $1 - this should not happen."
        exit 2
        ;;
    esac
  done

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

  exit 0
}

parse_list_units ()
{
  PARSED_ARGUMENTS=$(getopt -a -n systemctl -o at --long all,type:,plain,no-legend -- "$@")

  validate_arguments $?

  eval set -- "$PARSED_ARGUMENTS"
  while :
  do
    case "$1" in
      -a | --all)
        shift
        ;;
      -t | --type)
        shift 2
        ;;
      --plain)
        shift
        ;;
      --no-legend)
        shift
        ;;
      --)
        shift;
        break
        ;;
      *)
        echo "systemctl: unexpected option: $1 - this should not happen."
        exit 2
        ;;
    esac
  done

  sudo /usr/bin/supervisorctl status | awk '{print $1".service\tloaded\tactive\t"tolower($2)"\t"$1" service"}'

  exit 0
}

COMMAND="$1"

shift

case "$COMMAND" in
  show)
    parse_show "$@"
    ;;
  list-units)
    parse_list_units "$@"
    ;;
  start | stop | restart)
    UNIT="$1"

    if [ "$UNIT" = "klipper" ]; then
      sudo /usr/bin/supervisorctl "$COMMAND" simulavr klipper
    else
      sudo /usr/bin/supervisorctl "$COMMAND" "$UNIT"
    fi
    ;;
  *)
    echo "systemctl: unknown command '$COMMAND'"
    exit 1
    ;;
esac

exit 0