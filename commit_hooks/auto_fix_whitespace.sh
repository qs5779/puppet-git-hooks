#!/bin/bash

# This script expects $1 to be passed and for $1 to be the filesystem location
# to a yaml file for which it will run syntax checks against.

file="$1"
FIXLFEOF=$2

function auto_fix_lfeof {
  typeset F="$1"
  typeset I="$2"
  typeset RC=0
  #typeset DF=$(echo "$F" | sed s/.save$//) # fix display name so user isn't as confused as me
  typeset DF="$F"

  if [ "$(tail -c1 "$F")" != '' ]
  then
    echo >> "$F"
    RC=1
  elif [ "$(tail -c2 "$F")" == '' ]
  then
      # remove all but last newline
    case "$platform" in
      win )
        sed -i "" -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$F" > "${F}.bak"
        mv -f "${F}.bak" "$F"
      ;;
      mac )
        sed -i "" -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$F"
      ;;
      * )
        sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$F"
      ;;
    esac
    RC=2
  fi
  if [ "$I" != "no" ]
  then
    case "$RC" in
      1 )
        echo -e "added line feed toend of file: $(tput setaf 1)${DF}$(tput sgr0)!"
      ;;
      2 )
        echo -e "removed extra line feed(s) at end of file: $(tput setaf 1)${DF}$(tput sgr0)!!"
      ;;
    esac
  fi
  return $RC
}

function auto_fix_whitespace {
  typeset F="$1"
  typeset I="$2"
  typeset RC=0
  #typeset DF=$(echo "$F" | sed s/.save$//) # fix display name so user isn't as confused as me
  typeset DF="$F"

  if grep -q '[[:space:]]$' "$F"
  then
    if [[ "$platform" == "win" ]]
    then
      # in windows, `sed -i` adds ready-only attribute to $F(I don't kown why), so we use temp file instead
      sed 's/[[:space:]]*$//' "$F" > "${F}.bak"
      mv -f "${F}.bak" "$file"
    elif [[ "$platform" == "mac" ]]
    then
      sed -i "" 's/[[:space:]]*$//' "$file"
    else
      sed -i 's/[[:space:]]*$//' "$file"
    fi
    if [ "$I" != "no" ]
    then
      echo -e "auto removed trailing whitespace for $(tput setaf 1)${DF}$(tput sgr0)!"
      RC=1
    fi
  fi
  return $RC # 1 if informed 0 if not
}

# since $file in working directory isn't always equal to $file in index, so we backup it
mv -f "$file" "${file}.working"
# discard changes in working directory
git checkout -- "$file"

auto_fix_whitespace "$file" yes
if [ $? -eq 0 ]
then
  INFORM=yes
else
  INFORM=no
fi
# fix the saved copy just in case it has same issues
auto_fix_whitespace "${file}.working" $INFORM

if [ "$FIXLFEOF" == "enabled" ]
then
  auto_fix_lfeof "$file" yes
  if [ $? -eq 0 ]
  then
    INFORM=yes
  else
    INFORM=no
  fi
  # now fix the save copy in case it was different from index
  auto_fix_lfeof "${file}.working" $INFORM
fi

git add "$file"

# restore the $file
cat "${file}.working" > "$file"
rm "${file}.working"

DF=/tmp/autofix.debug
echo "platform: $platform" > $DF
echo "OSTYPE: $OSTYPE" >> $DF
echo "AUTO_FIX_LFEOF: $AUTO_FIX_LFEOF" >> $DF

exit 0
