#!/bin/bash

retimestamp(){
   ymd=;SOURCE_DATE_EPOCH=;
   ymd=$(tar --full-time -tvf "$1" | awk '{print $4" "$5;exit}')
   SOURCE_DATE_EPOCH=$(date -d "$ymd" +%s)
   touch -hd "@$SOURCE_DATE_EPOCH" "$1"
}

