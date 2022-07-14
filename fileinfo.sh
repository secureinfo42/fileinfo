#!/bin/sh



#######################################################################################################################
#
# Globz
#
##

APP="$(basename "$0")"

banner() {
	(
	echo
	echo 'G1sxOzM0beKWkeKWiOKWgOKWgOKWkeKWgOKWiOKWgOKWkeKWiOKWkeKWkeKWkeKWiOKWgOKWgOKW
keKWgOKWiOKWgOKWkeKWiOKWgOKWiOKWkeKWiOKWgOKWgOKWkeKWiOKWgOKWiArilpHilojiloDi
loDilpHilpHilojilpHilpHilojilpHilpHilpHilojiloDiloDilpHilpHilojilpHilpHiloji
lpHilojilpHilojiloDiloDilpHilojilpHilogK4paR4paA4paR4paR4paR4paA4paA4paA4paR
4paA4paA4paA4paR4paA4paA4paA4paR4paA4paA4paA4paR4paA4paR4paA4paR4paA4paR4paR
4paR4paA4paA4paACj4+PiBmaWxlaW5mbyA9PT09PT09PT09PT09PT09PT09'|base64 -d
	printf "\033[0m\n\n"
	) >&2
}


#######################################################################################################################
#
# Compute
#
##

#=== Use python for calculation =======================================================================================

function calc() {
	python -c "print($*)" 2>/dev/null
}

#=== Ratio of strings, regex: \S+ =====================================================================================

function calc_strings() {
	item="$1"
	size="$2"
	nbrc="$(strings "$item"|grep -Po '\S+'|grep -o .|grep -c .)"
	calc "($nbrc/$size)*100"|grep -o '^.....' || echo "0"
}

#=== Ratio of nullbytes ===============================================================================================

function calc_nullbytes() {
	item="$1"
	size="$2"
	nbrc="$(hexdump -C "$item"|grep -o ' 00'|grep -c .)"
	calc "(($nbrc/2)/$size)*100"|grep -o '^.....' || echo "0"
}



#######################################################################################################################
#
# Get infos
#
##

#=== Specific to macOS ================================================================================================

function get_mdls() {
	metadata="$1"
	item="$2"
	mdls -name $metadata "$item"|awk -F' = ' '{ print $2 }'|sed 's/^"//;s/"$//'|sed 's#(null)#N/A#'
}

#=== Specific to macOS ================================================================================================

function get_dgst() {
	item="$1"
	if [ -f "$item" ]; then
	  md5="$(openssl dgst -r -md5 "$item"|cut -d' ' -f1)"
	  sha1="$(openssl dgst -r -sha1 "$item"|cut -d' ' -f1)"
	  sha256="$(openssl dgst -r -sha256 "$item"|cut -d' ' -f1)"
	  sha512="$(openssl dgst -r -sha512 "$item"|cut -d' ' -f1)"
	fi
}

#=== Getinfo as generic as possible ===================================================================================

function get_info {

  item="$1"
  verbose=0 ; [ $# -eq 2 ] && verbose="$2"

  item_hex="$(basename "$item"|tr -d "\n"|xxd -ps|tr -d "\n")"
	type=$(file -b -L "$item"|tr "\n" ","|sed -r 's/[\x01-\x1f]//g;s/\\//g;s/,$//1')

  # Basic infos -------------------------------------------------------------------------------------------------------

  eval $(stat -c "user='%U';group='%G';uid='%u';gid='%g';perm='%A';mode='%a';size='%s'" "$item")

  # Dates -------------------------------------------------------------------------------------------------------------

  eval $(stat -c "date_birth='%w';date_modified='%y';date_last_access='%x';date_status_changed='%z'" "$item")
  eval $(stat -c "timestamp_birth='%W';timestamp_modified='%Y'" "$item")
  eval $(stat -c "timestamp_last_access='%X';timestamp_status_changed='%Z'" "$item")

  # Flags -------------------------------------------------------------------------------------------------------------

  # extra permissions made with chattr
  attributes="-" ; [ "$(uname)" = "Linux" ] && [ -x "$(which lsattr)" ] && \
   attributes="$(/usr/bin/lsattr "$item"|cut -d' ' -f1)"

  # restricted,schg,uchg,sunlink, ...
  [ "$(uname)" = "Darwin" ] && \
   flags="$(/bin/ls -ldO@ "$item"|awk '{ print $5 }'|sed 's:\-::1')" || flags="-"

  # Digests -----------------------------------------------------------------------------------------------------------

  if [ -f "$item" ]; then
  	get_dgst $item # md5, sha1, sha256, sha512base64

	  if [ $verbose -eq 1 ]; then
	  	crc32="$(crc32 "$item"|strings|tr -d "\n")"
		  sha256b64="$(printf "$sha256"|xxd -ps -r|base64 -w0)"
		  sha512b64="$(printf "$sha512"|xxd -ps -r|base64 -w0)"
		  # name_crc32="$(echo -n "$item"|crc32)"
		  name_md5="$(echo -n "$item"|openssl dgst -r -md5|cut -d' ' -f1)"
		  name_sha1="$(echo -n "$item"|openssl dgst -r -sha1|cut -d' ' -f1)"
		  name_sha256="$(echo -n "$item"|openssl dgst -r -sha256|cut -d' ' -f1)"
		  strings_stats="$(calc_strings "$item" $size)%%"
		  strings_nullbytes="$(calc_nullbytes "$item" $size)%%"
		fi
	fi

  # Darwin metadata ---------------------------------------------------------------------------------------------------

  if [ $verbose -eq 1 ]; then
		darwin_version="N/A"         ; darwin_arch="N/A"
		darwin_bundle="N/A"          ; darwin_content_type="N/A"
		darwin_filesystem_name="N/A" ; darwin_display_name="N/A"
		darwin_usecount="N/A"

		if [ "$(uname)" = "Darwin" ]; then
			darwin_version="$(get_mdls kMDItemVersion "$item")"
			darwin_bundle="$(get_mdls kMDItemCFBundleIdentifier "$item")"
			darwin_content_type="$(get_mdls kMDItemContentType "$item")"
			darwin_filesystem_name="$(get_mdls kMDItemFSName "$item")"
			darwin_display_name="$(get_mdls kMDItemDisplayName "$item")"
			darwin_usecount="$(get_mdls kMDItemUseCount "$item")"
		fi
	fi
}



#######################################################################################################################
#
# JSON output
#
##

json_header() {
	printf "{"
	printf "\n  \"files\": [\n"
}

#----------------------------------------------------------------------------------------------------------------------

json_data() {
	item="$1"
	verbose=0 ; [ $# -eq 2 ] && verbose="$2"

	printf "    {"
	printf " \"filename\": \"$item\","

	if [ $verbose -eq 1 ]; then
		printf " \"basename_hex\": \"$item_hex\","
	fi

	printf " \"found\": \"$found\","
	printf " \"type\": \"$type\","
	printf " \"user\": \"$user\","
	printf " \"group\": \"$group\","
	printf " \"uid\": \"$uid\","
	printf " \"gid\": \"$gid\","
	printf " \"permissions\": \"$perm\","
	printf " \"mode\": \"$mode\","
	printf " \"size\": \"$size\","
	printf " \"flags\": \"$flags\","
	printf " \"attributes\": \"$attributes\","
	printf " \"dates\": {"
	printf "  \"human_format\": {"
	printf "   \"birth\": \"$date_birth\","
	printf "   \"modified\": \"$date_modified\","
	printf "   \"last_access\": \"$date_last_access\","
	printf "   \"status_changed\": \"$date_status_changed\""
	printf "  },"
	printf "  \"timestamp\": {"
	printf "   \"birth\": \"$timestamp_birth\","
	printf "   \"modified\": \"$timestamp_modified\","
	printf "   \"last_access\": \"$timestamp_last_access\","
	printf "   \"status_changed\": \"$timestamp_status_changed\""
	printf "  }"
	printf " },"
	printf " \"digests\": {"

	if [ $verbose -eq 1 ]; then
		printf "  \"filename:md5\": \"$name_md5\","
		printf "  \"filename:sha1\": \"$name_sha1\","
		printf "  \"filename:sha256\": \"$name_sha256\","
	fi

	printf "  \"data:md5\": \"$md5\","
	printf "  \"data:sha1\": \"$sha1\","
	printf "  \"data:sha256\": \"$sha256\","
	printf "  \"data:sha512\": \"$sha512\""

	if [ $verbose -eq 1 ]; then
		printf ","
		printf "  \"data:crc32\": \"$crc32\","
		printf "  \"data:sha256.base64\": \"$sha256b64\","
		printf "  \"data:sha512.base64\": \"$sha512b64\""
	fi

	printf " }"

	if [ $verbose -eq 1 ]; then
		printf ","
		printf " \"stats\": {"
		printf "  \"strings\": \"$strings_stats\","
		printf "  \"nullbytes\": \"$strings_nullbytes\""
		printf " },"
		printf " \"metadata\": {"
		printf "  \"darwin_version\": \"$darwin_version\","
		printf "  \"darwin_bundle\": \"$darwin_bundle\","
		printf "  \"darwin_content_type\": \"$darwin_content_type\","
		printf "  \"darwin_filesystem_name\": \"$darwin_filesystem_name\","
		printf "  \"darwin_display_name\": \"$darwin_display_name\","
		printf "  \"darwin_usecount\": \"$darwin_usecount\""
		printf " }"
	fi

	printf "}"
}

#----------------------------------------------------------------------------------------------------------------------

json_array() {
	[ $1 -ge 1 ] && printf ",\n" && return 1
	[ $1 -eq 0 ] && return 0
}

#----------------------------------------------------------------------------------------------------------------------

json_end() {
	printf "\n  ]"
	printf "\n}"
}



#######################################################################################################################
#
# Main
#
##

#======================================================================================================================

if [ "$1" = "-h" -o "$1" = "-?" -o $# -eq 0 ]; then
	banner
	echo "Usage: $APP [-j [-v]] <file> [file2 [file3]...]"
	echo 
	echo " -j  : output is in JSON format"
	echo " -v  : get more informations"
	echo 
	echo "Without options do stat and common hash digests"
	echo 
	echo "Exemples:"
	echo "$APP /bin/ls /bin/sh /etc/hosts"
	echo "$APP -j ~/"
	echo 
	exit
fi

#======================================================================================================================

if [ "$1" != "-j" ]; then
	banner
	while true ; do
		stat -- "$1"
		if [ -f "$1" ]; then
			get_dgst "$1"
			printf   "   MD5: $md5"
			printf "\n  SHA1: $sha1"
			printf "\nSHA256: $sha256"
		fi
		printf "\n\n"
		shift
		[ $# -eq 0 ] && break
	done
fi

#======================================================================================================================

if [ "$1" = "-j" ]; then
	banner
	shift

	verbose=""
	if [ "$1" = "-v" ]; then
		shift
		verbose="1"
	fi

	json_header
	while true ; do

		item="$1"
		shift

		found="false"
		if [ -f "$item" ]; then
			get_info "$item" $verbose
			found="true"
		fi

		json_data "$item" $verbose
		json_array $#
		[ $# -eq 0 ] && break	

	done
	json_end
fi
