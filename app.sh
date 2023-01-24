#!/bin/sh

date=$(date +"%d-%m-%Y")
base_dir="/root/Vendor-Lookup"

function TheHackersNews(){
    curl --silent "https://feeds.feedburner.com/TheHackersNews" |  xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/$date"
}
TheHackersNews

while read vendors
do
    cat "$base_dir/tmp/$date" | grep -i "$vendors" | tee -a "$base_dir/res/$date"
done < "$base_dir/src/vendor_list" 

