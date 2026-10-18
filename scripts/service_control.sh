#!/bin/bash

die ()
{
  echo "$MY_NAME: $1"
  exit 1
}

MY_NAME="${0##*/}"

PARSED_ARGUMENTS="$(getopt -n "$MY_NAME" -o t:p:a --long type:,property:,all,value,no-legend,plain -- "$@")" || exit $?

eval set -- "$PARSED_ARGUMENTS"
while true; do
  case "$1" in
  -t | --type)
    shift 2
    ;;
  -p | --property)
    IFS="," read -a PROPERTIES <<<$2
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
    shift
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
  for UNIT in "${UNITS[@]}"; do
    PROGRAM="$UNIT"
    # "klipper" is the whole Klipper stack (see list-units), its state is klippy's
    [ "$UNIT" = "klipper" ] && PROGRAM="klipper_klippy"
    UNIT_STATE=$(sudo /usr/bin/supervisorctl status "$PROGRAM" | awk '{print tolower($2)}')

    for PROPERTY in "${PROPERTIES[@]}"; do
      case "$PROPERTY" in
      LoadState)
        echo "loaded"
        ;;
      ActiveState)
        [ "$UNIT_STATE" = "running" ] && echo "active" || echo "inactive"
        ;;
      SubState)
        [ "$UNIT_STATE" = "running" ] && echo "running" || echo "dead"
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
  STATUS="$(sudo /usr/bin/supervisorctl status)"
  echo "$STATUS" | awk '{print $1".service\tloaded\t"(tolower($2)=="running"?"active\trunning":"inactive\tdead")"\t"$1" service"}'
  # Moonraker and Mainsail restart Klipper as service "klipper"; there is no program of that
  # name, start/stop/restart below map it to all Klipper programs of the active MCU_TYPE
  echo "$STATUS" | awk '$1=="klipper_klippy" {print "klipper.service\tloaded\t"(tolower($2)=="running"?"active\trunning":"inactive\tdead")"\tklipper service"}'
  ;;

start | stop | restart)
  # Moonraker waits only 2 s for "systemctl start/stop/restart" and reports an error after
  # that, while restarting the Klipper programs takes longer. Hand the action to supervisor
  # in the background (detached, output to the supervisord log) and return at once.
  for UNIT in "${UNITS[@]}"; do
    if [ "$UNIT" = "klipper" ]; then
      # the MCU programs depend on MCU_TYPE, see /bin/start
      if grep -q "^\[program:simulavr\]" /etc/supervisor/conf.d/mcu.conf 2>/dev/null; then
        PROGRAMS=(simulavr klipper_klippy)
      else
        PROGRAMS=(printer_simulator webcam_renderer klipper_mcu klipper_klippy)
      fi
    else
      PROGRAMS=("$UNIT")
    fi
    setsid sudo /usr/bin/supervisorctl "$COMMAND" "${PROGRAMS[@]}" </dev/null >/dev/null 2>&1 &
  done
  ;;

*)
  die "unknown command '$COMMAND'"
  ;;
esac

exit 0