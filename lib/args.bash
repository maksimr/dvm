#!/bin/bash

args(){
  local arg_name=$1
  shift;

  while [[ $# > 0  ]]
  do
    case $1 in
      --$arg_name=*)
        echo "$1" | sed "s/--$arg_name=//"
        shift ;;
      *) shift ;;
    esac
  done
}
