#!/bin/bash

src_file=$1
tgt_file=$2
widths=$3

if [ -z "$src_file" ] || [ -z "$tgt_file" ] || [ -z "$widths" ]; then
    echo -e "\nUsage: $0 <source_file> <target_file> <widths>\n"
    exit 1
fi

read -p "File has header and trailer? (Y/N): " flag
flag=$(echo "$flag" | tr '[:lower:]' '[:upper:]')
read -p "Enter the delimiter: " delimiter

convert_fixed_to_delimited() {
    awk -v widths="$widths" -v delimiter="$delimiter" 'BEGIN {FIELDWIDTHS = widths} {
        for (i = 1; i <= NF; i++) {
            printf("%s%s", (i > 1) ? delimiter : "", $i)
        }
        printf("\n")
    }' "$1" > "$2"
}


if [ "$flag" == "Y" ]; then
    tail -n +2 "$src_file" | head -n -1 | convert_fixed_to_delimited - "$tgt_file"
else
    convert_fixed_to_delimited "$src_file" "$tgt_file"
fi
