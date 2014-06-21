#!/bin/sh

idx=0
max=4
src_domain="www.qiushibaike.com"
dst_domain="localhost\/neck"
url=""
tmp=".raw"
dst="/opt/local/share/nginx/html/neck"
template_page="template.page"
template_index="template.index"
dir="90"

function escape()
{
    local src=$1;
    src=`echo $src | sed 's#\/#\\\/#g'`;
    src=`echo $src | sed 's/\"/\\\"/g'`;
    echo $src
}

function fetch_next_url()
{
    src=$1
    while read line
    do
        next=`echo $line | grep "a href" | grep "下一页"`;
        if [ -n "$next" ]; then
            url=`echo ${next#<a href=\"}`
            url=`echo ${url%%\">*}`
        fi
    done < $src
}

function fetch_data()
{
    src=$1
    # no br tag
    sed 's/<br\/>//g' $src > $src.mid
    while read line
    do
        line=`echo $line | grep "^糗友"`;
        if [ -n "$line" ]; then

            # fetch author
            author=$line
            author=`escape $author`

            # fetch content
            content=""
            while read next
            do
                if [ -z "$next" ]; then
                    break;
                else
                    content="$content""$next"
                fi
            done
            content=`escape $content`

            # fetch picture
            picture=""
            while read next
            do
                href=`echo $next | grep "<a href=\"http://pic.qiushibaike.com/system/pictures/"`
                if [ -n "$href" ]; then
                    picture=`echo ${href#<a href=\"}`
                    picture=`echo ${picture%\">}`
                    picture=`escape $picture`

                elif [ -n "$next" ]; then
                    break;
                fi
            done

            # dump
            if [ -n "$picture" ]; then
                if [ "$dir" == "90" ]; then
                    dir="-90"
                else
                    dir="90"
                fi
                file=$dst/$idx.html
                idx=`expr $idx + 1`
                sed -e 's/TAG_AUTHOR/'$author'/g'   \
                    -e 's/TAG_CONTENT/'$content'/g' \
                    -e 's/TAG_PICTURE/'$picture'/g' \
                    -e 's/TAG_DIRECTION/'$dir'/g'   \
                    -e 's/TAG_IDX/'$idx'/g'         \
                    -e 's/TAG_DST_DOMAIN/'$dst_domain'/g'   \
                    $template_page > $file
            fi
        fi
    done < $src.mid
    rm $src.mid
}

# fetch max by loop
rm $dst/*
while [ $idx -lt $max ]
do
    curl -o $tmp "$src_domain""$url"
    fetch_next_url $tmp
    fetch_data $tmp
done
rm $tmp

# index
file=$dst/index.html
sed -e 's/TAG_MAX/'$max'/g' \
    -e 's/TAG_DST_DOMAIN/'$dst_domain'/g' \
    $template_index > $file

# make script happy
mv $dst/0.html $dst/$idx.html

