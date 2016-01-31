#!/bin/bash -e

#############################################################
# A lightweight HTTP server written in bash and based on ncat
# Author : David Gayerie
#
# This server distributes available files in the current 
# directory. You can optionnally specify as parameter
# the ABSOLUTE path of the root server directory 
# (without trailing slash).
# This serveur only supports the HTTP GET method
#
# This server is provided as-is without any warranty.
# DO NOT USE this script for production environment.
#############################################################

# Server port
HTTP_PORT=8080

function send_http_error ()
{
  local STATUS_CODE=$1
  local MESSAGE="$2"

  echo "HTTP/1.1 $STATUS_CODE $MESSAGE"
  echo "Content-type: text/plain"
  echo "Content-length: ${#MESSAGE}"
  echo
  echo -n "$MESSAGE"
  exit 1
}

function process_request ()
{
  DOCUMENT_DIR=$1

  # Parsing incoming request
  read STATUS_LINE
  >&2 echo "$(date -uR) - $STATUS_LINE"

  read -a REQUEST <<< "$STATUS_LINE"

  RESOURCE=$(readlink -f "$DOCUMENT_DIR${REQUEST[1]%%\?*}")

  # check errors

  if [ ${REQUEST[0]} != "GET" ]
  then
    send_http_error 405 "Method ${REQUEST[0]} not allowed"
  fi

  if [[ "$RESOURCE" != $DOCUMENT_DIR\/* ]]
  then
    send_http_error 403 "File access forbidden"
  fi

  if [ ! -f "$RESOURCE" ]
  then
    send_http_error 404 "File ${REQUEST[1]} not found!"
  fi

  # Generating response

  # FIX : the 'file' command does not return the expected MIME-type for css file
  if [[ "$RESOURCE" == *.css ]]
  then
      MIME_TYPE="text/css"
  else
      MIME_TYPE="$(file -i $RESOURCE | cut -d : -f 2)"
  fi

  echo "HTTP/1.1 200 OK"
  echo "Content-type:$MIME_TYPE"
  echo "Content-length: $(stat -c%s $RESOURCE)"
  echo "Date: $(date -uR)"
  echo
  cat $RESOURCE
}

if [ "$1" == "-daemon" ]
then
  process_request "$2"
else
  echo "Starting server on port $HTTP_PORT"
  echo "Please open your browser at this URL : http://localhost:$HTTP_PORT/blender_express.html"
  ncat -k -l $HTTP_PORT --sh-exec "$0 -daemon ${1:-$(pwd)/web}"
fi
