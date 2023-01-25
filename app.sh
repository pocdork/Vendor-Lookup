#!/bin/sh

date=$(date +"%d-%m-%Y")
base_dir="/root/Vendor-Lookup"
hook_url=$(sed -n 1p $base_dir/src/.hook_url)
mkdir -p "$base_dir/res/"

function TheHackersNews(){
    curl --silent "https://feeds.feedburner.com/TheHackersNews" |  xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/$date"
}

function VendorCheck(){
    while read vendors
    do
        cat "$base_dir/tmp/$date" | grep -i "$vendors" | sed -r ':a;s/(("[0-9,]*",?)*"[0-9,]*),/\1/;ta; s/""/"|"/g;' | tee -a "$base_dir/res/$date"
    done < "$base_dir/src/vendor_list" 
}

function Notification(){
    while IFS="|" read -r title url
    do
        T=$(echo ${title}|tr -d '"')
        U=$(echo ${url}|tr -d '"')
        curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$T"'\n'"$U"'"}' "$hook_url"
    done < "$base_dir/res/$date"

}
function DeleteFiles(){
    rm "$base_dir/tmp/$date"
    rm "$base_dir/res/$date"
}

TheHackersNews
VendorCheck
Notification
DeleteFiles
