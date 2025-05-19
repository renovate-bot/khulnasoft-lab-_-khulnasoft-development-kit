_kdk_root()
{
  local root
  root="$(cd "$(dirname .)" || exit ; pwd -P)"

  while [ "$root" != "/" ]; do
    if [ -e "$root/KDK_ROOT" ]; then
      echo "$root"
      return
    fi

    root=$(dirname "$root")
  done
}

_kdk()
{
  local index cur action root words
  local j k

  index="$COMP_CWORD"
  cur="${COMP_WORDS[index]}"
  action="${COMP_WORDS[1]}"
  root=$(_kdk_root)

  if [ "$index" = 1 ]; then
    if [ -z "$root" ]; then
      words="help version init"
    else
      words=$(awk '/^  kdk / { print $2 }' "$root/HELP")
    fi
  else
    case "$action" in
      init)
        [ -n "$BASH_VERSION" ] && compopt -o nospace
        words=$(compgen -o dirnames -- "$cur")
        ;;
    esac

    if [ -n "$root" ]; then
      case "$action" in
        start|stop|status|restart|tail)
          words=$(ls "$root/services")
          ;;
        psql)
          if [ "$index" = 2 ]; then
            words="-d"
          elif [ "$index" = 3 ]; then
            words="khulnasofthq_development khulnasofthq_test"
          fi
          ;;
        redis-cli)
          if [ -n "$BASH_VERSION" ] && type -t _command_offset >/dev/null; then
            _command_offset 1
            return
          fi
          ;;
      esac
    fi
  fi

  for j in $(compgen -W "$words" -- "$cur")
  do
    COMPREPLY[k++]=$j
  done
}

complete -F _kdk kdk
