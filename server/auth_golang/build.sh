#!/bin/bash
BASEDIR=$(dirname $0)
cd $BASEDIR
CURRENT_DIR=`pwd`

fmtsrc() {
  for file in `find $1 -iregex '.*\.\(go\)$'`;do
    if [[ "$file" =~ go$ ]];then
      gofmt -w $file
      echo $file
    fi
  done
}

case "$1" in
format)
  fmtsrc $CURRENT_DIR
  ;;
*)
  set -x
  go build -o test test.go
esac
