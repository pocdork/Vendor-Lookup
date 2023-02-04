#!/bin/sh

date=$(date +"%d-%m-%Y")
base_dir="/root/Vendor-Lookup"
hook_url=$(sed -n 1p $base_dir/src/.hook_url)
mkdir -p "$base_dir/res/"
mkdir -p "$base_dir/tmp/"

function TheHackersNews(){
    curl --silent "https://feeds.feedburner.com/TheHackersNews" |  xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/HN_$date"
}

function CVEDetails(){
    # echo "cve_id |,| title |,| url" | tee -a "$base_dir/res/CVE_$date"
    curl "https://www.cvedetails.com/json-feed.php?numrows=30&vendor_id=0&product_id=0&version_id=0&hasexp=0&opec=0&opov=0&opcsrf=0&opfileinc=0&opgpriv=0&opsqli=0&opxss=0&opdirt=0&opmemc=0&ophttprs=0&opbyp=0&opginf=0&opdos=0&orderby=1&cvssscoremin=0" | 
    jq -r '["cve_id", "title", "url"], (.[] | [.cve_id, .summary, .url]) | @csv'| 
    tee -a "$base_dir/tmp/CVE_$date"

}
function BleepingComputer(){
    curl --silent "https://www.bleepingcomputer.com/feed/" | xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/BC_$date"
}

function NakedSecurity(){
        curl --silent "https://nakedsecurity.sophos.com/feed/"|xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/NS_$date"
}

function Portswigger(){
    curl --silent "https://portswigger.net/daily-swig/rss"|xmlstarlet sel -t -m '/rss/channel/item' -v 'title' -n -v 'link' -n |  awk '{
        title=$0
        gsub(/"/, "&&", title)
        getline
        printf "\"%s\",\"%s\"\n", title, $0
    }'| tee -a "$base_dir/tmp/PS_$date"
}

function VendorCheck(){
    cat "$base_dir/tmp/HN_$date" "$base_dir/tmp/BC_$date" "$base_dir/tmp/NS_$date" "$base_dir/tmp/PS_$date" > "$base_dir/tmp/news_$date"
    while read vendors
    do
        chk=$(cat "$base_dir/tmp/news_$date" | sed -r ':a;s/(("[0-9,]*",?)*"[0-9,]*),/\1/;ta; s/""/"-->"/g;'| awk -F "\"*-->\"*" '{print $1}' | grep -i -w "$vendors")
        if [ "$chk" ]
        then

            cat "$base_dir/tmp/news_$date" | grep "$chk" | sed -r ':a;s/(("[0-9,]*",?)*"[0-9,]*),/\1/;ta; s/""/"|"/g;' | tee -a "$base_dir/res/news_$date"
        else
            echo "--"
        fi      
             
    done < "$base_dir/src/vendor_list" 
    
    #For CVE Check:
    while read vendors
    do
        chk1=$(cat "$base_dir/tmp/CVE_$date" | sed -r ':a;s/(("[0-9,]*",?)*"[0-9,]*),/\1/;ta; s/""/"-->"/g;'| awk -F "\"*-->\"*" '{print $2}' | grep -i -w "$vendors")
        if [ "$chk1" ]
        then

            cat "$base_dir/tmp/CVE_$date" | grep "$chk1" | sed -r ':a;s/(("[0-9,]*",?)*"[0-9,]*),/\1/;ta; s/""/"|"/g;' | tee -a "$base_dir/res/CVE_$date"
        else
            echo "--"
        fi
    done < "$base_dir/src/vendor_list" 
}

function Notification(){
    #HackerNews
    while IFS="|" read -r title url
    do
        T=$(echo ${title}|tr -d '"')
        U=$(echo ${url}|tr -d '"')
        curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$T"'\n'"$U"'"}' "$hook_url"
    done < "$base_dir/res/news_$date"

    #CVEDetails
    while IFS="|" read -r cve_id  title url
    do
        I=$(echo ${cve_id}|tr -d '"')
        T=$(echo ${title}|tr -d '"')
        U=$(echo ${url}|tr -d '"')
        curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$I"'\n'"$T"'\n'"$U"'"}' "$hook_url"
    done < "$base_dir/res/CVE_$date"

    }

function DeleteFiles(){
    rm "$base_dir/tmp/HN_$date"
    rm "$base_dir/res/HN_$date"
    rm "$base_dir/tmp/CVE_$date"
    rm "$base_dir/res/CVE_$date"
    rm "$base_dir/tmp/BC_$date"
    rm "$base_dir/res/BC_$date"
    rm "$base_dir/tmp/NS_$date"
    rm "$base_dir/res/NS_$date"
    rm "$base_dir/tmp/PS_$date"
    rm "$base_dir/res/PS_$date"
}

TheHackersNews
CVEDetails
BleepingComputer
NakedSecurity
Portswigger
VendorCheck
Notification
DeleteFiles

