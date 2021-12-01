#!/bin/bash

file=$1
if [ ${OSTYPE} == "darwin20" ]; then
  base64=$(which gbase64)
else
  base64=$(which base64)
fi
gzip=$(which gzip)
col=80

${gzip} --best -c ${file} | ${base64}
