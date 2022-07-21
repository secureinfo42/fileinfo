#!/bin/sh


#######################################################################################################################
#
# Globz
#
##

APP="$(basename "$0")"

export LC_ALL=C 

function banner() {
	(
	echo
	echo 'G1sxOzM0beKWkeKWiOKWgOKWgOKWkeKWgOKWiOKWgOKWkeKWiOKWkeKWkeKWkeKWiOKWgOKWgOKWkeKWgOKWiOKWgOKWkeKWiOKWgOKWiOKWkeKWiOKWgOKWgOKWkeKWiOKWgOKWiArilpHilojiloDiloDilpHilpHilojilpHilpHilojilpHilpHilpHilojiloDiloDilpHilpHilojilpHilpHilojilpHilojilpHilojiloDiloDilpHilojilpHilogK4paR4paA4paR4paR4paR4paA4paA4paA4paR4paA4paA4paA4paR4paA4paA4paA4paR4paA4paA4paA4paR4paA4paR4paA4paR4paA4paR4paR4paR4paA4paA4paACj4+PiBmaWxlaW5mbyA9PT09PT09PT09PT09PT09PT09'|base64 -d
	printf "\033[0m\n\n"
	)
}

function error() {
	printf "\033[1;31m\n"
	echo "Error: $*" >&2
	printf "\033[0m\n"
}

function usage() {
	echo
	echo "Usage: $APP <format> [-v] <item> [item2 [item3]...]"
	echo 
	echo "format :"
	echo " - stat format :"
	echo "   - see \`man stat\`"
	echo "   - aliases :"
	echo "     - size, filename, user, uid, group, gid, md5, sha1, sha256, sha512, mime, type"
	echo " - yaml"
	echo " - json"
	echo
	echo "-v : verbose"
	echo
	echo "item : can be file, folder or link (will be dereferenced)"
	echo 
	echo "'verbose' is uneffective on 'stat format'."
	echo "'verbose' add these informations :"
	echo " - type : full type via \`file\` command" 
	echo " - mime : via \`file -i\` command" 
	echo " - statistics :"
	echo "   - strings   [\\\x20-\\\x7f]"
	echo "   - binary    [\\\x00-\\\x19\\\x80-\\\xFF]"
	echo "   - nullbytes [\\\x00]"
	echo " - metadata : if OS is Darwin-like else values are empty"
	echo 
	echo "Exemples:"
	echo "$APP filename,user,group,sha1 -- /bin/ls /bin/sh /etc/hosts"
	echo "$APP yaml ~/"
	echo "$APP json -v /usr/bin/nc /usr/bin/finger|jq"
	echo 
	exit
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

function python_wrapper() {
	# global item
	python -c "import re; buff=open('$item','rb').read() ; $*  ; print(len(c),end='')"
}

function calc_strings() {
	item="$1"
	size="$2"
	nbrc=$(python_wrapper 'c=re.findall(rb"[\x20-\x7f]",buff)')
	calc "($nbrc/$size)*100"|grep -o '^.....' || echo "0"
}

#=== Ratio of nullbytes ===============================================================================================

function calc_nullbytes() {
	item="$1"
	size="$2"
	nbrc=$(python_wrapper 'c=re.findall(rb"\x00",buff)')
	calc "($nbrc/$size)*100"|grep -o '^.....' || echo "0"
}

#=== Ratio of binary bytes ============================================================================================

function calc_binarybytes() {
	item="$1"
	size="$2"
	nbrc=$(python_wrapper 'c=re.findall(rb"[\x00-\x19\x80-\xFF]",buff)')
	calc "($nbrc/$size)*100"|grep -o '^.....' || echo "0"
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

#=== common digests ===================================================================================================

function get_dgst() {
	item="$1"
	[ $# -eq 2 ] && dgst="$2"
	if [ -f "$item" -a $# -eq 1 ]; then
	  md5="$(openssl dgst -r -md5 "$item"|cut -d' ' -f1)"
	  sha1="$(openssl dgst -r -sha1 "$item"|cut -d' ' -f1)"
	  sha256="$(openssl dgst -r -sha256 "$item"|cut -d' ' -f1)"
	  sha512="$(openssl dgst -r -sha512 "$item"|cut -d' ' -f1)"
	fi
	if [ -f "$item" -a $# -eq 2 ]; then
	  [ "$dgst" = "md5" ]    && md5="$(openssl dgst -r -md5 "$item"|cut -d' ' -f1)"
	  [ "$dgst" = "sha1" ]   && sha1="$(openssl dgst -r -sha1 "$item"|cut -d' ' -f1)"
	  [ "$dgst" = "sha256" ] && sha256="$(openssl dgst -r -sha256 "$item"|cut -d' ' -f1)"
	  [ "$dgst" = "sha512" ] && sha512="$(openssl dgst -r -sha512 "$item"|cut -d' ' -f1)"
	fi
}

#=== Getinfo as generic as possible ===================================================================================

function get_ps() {
	if [ -x "$item" ]; then
		pids=$(lsof -n|awk '{ if( $9 == "'$item'" ) print $2 }'|tr "\n" ",")
	fi
}

#=== Getinfo as generic as possible ===================================================================================

function get_type() {
	if [ -f "$item" ]; then
		mime=$(file -b -i -L "$item")
		type=$(file "$item"|head -n1|cut -d':' -f2|sed 's/^ //1')
	fi
}

#=== Getinfo as generic as possible ===================================================================================

function get_data {

  item="$1"
  verbose=0 ; [ $# -eq 2 ] && verbose="$2"

  item_hex="$(basename "$item"|tr -d "\n"|xxd -ps|tr -d "\n")"
	type=$(file -b -L "$item"|tr "\n" ","|sed -r 's/[\x01-\x1f]//g;s/\\//g;s/,$//1')
	mime=$(file -b -i -L "$item")

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
		  stats_strings="$(calc_strings "$item" $size)"
		  stats_nullbytes="$(calc_nullbytes "$item" $size)"
		  stats_binarybytes="$(calc_binarybytes "$item" $size)"
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
# Stat output
#
##

function stat_output() {
	what="$1"
	item="$2"
	echo "$what"|grep -sq "md5"    && get_dgst $item md5
	echo "$what"|grep -sq "sha1"   && get_dgst $item sha1
	echo "$what"|grep -sq "sha256" && get_dgst $item sha256
	what=$(echo "$what"|sed \ "
	s/size/%s/g
	s/user/%U/;
	s/group/%G/;
	s/uid/%u/;
	s/gid/%g/;
	s/filename/%n/
	")

	stat -L -c "$what" "$item"|sed \ "
	s/md5/$md5/
	s/sha1/$sha1/
	s/sha256/$sha256/
	s/sha512/$sha512/
	"
}



#######################################################################################################################
#
# JSON output
#
##

function json_header() {
	printf "{"
	printf "\n  \"files\": [\n"
}

#----------------------------------------------------------------------------------------------------------------------

function json_data() {
	item="$1"
	verbose=0 ; [ $# -eq 2 ] && verbose="$2"

	printf "    {"
	printf " \"filename\": \"$item\","

	if [ $verbose -eq 1 ]; then
		printf " \"basename_hex\": \"$item_hex\","
	fi

	printf " \"found\": \"$found\","
	printf " \"type\": \"$type\","
	if [ $verbose -eq 1 ]; then
		printf " \"mime\": \"$mime\","
	fi
	printf " \"user\": \"$user\","
	printf " \"group\": \"$group\","
	printf " \"uid\": $uid,"
	printf " \"gid\": $gid,"
	printf " \"permissions\": \"$perm\","
	printf " \"mode\": \"$mode\","
	printf " \"size\": $size,"
	printf " \"flags\": \"$flags\","
	printf " \"attributes\": \"$attributes\","
	printf " \"dates\": {"
	printf "  \"timestamp\": {"
	printf "   \"birth\": $timestamp_birth,"
	printf "   \"modified\": $timestamp_modified,"
	printf "   \"last_access\": $timestamp_last_access,"
	printf "   \"status_changed\": $timestamp_status_changed"
	printf "  }"
	if [ $verbose -eq 1 ]; then
		printf ","
		printf "  \"human_format\": {"
		printf "   \"birth\": \"$date_birth\","
		printf "   \"modified\": \"$date_modified\","
		printf "   \"last_access\": \"$date_last_access\","
		printf "   \"status_changed\": \"$date_status_changed\""
		printf "  }"
	fi
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
		printf "  \"strings\": $stats_strings,"
		printf "  \"nullbytes\": $stats_nullbytes,"
		printf "  \"binarybytes\": $stats_binarybytes"
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

function json_array() {
	[ $1 -ge 1 ] && printf ",\n" && return 1
	[ $1 -eq 0 ] && return 0
}

#----------------------------------------------------------------------------------------------------------------------

function json_end() {
	printf "\n  ]"
	printf "\n}"
}



#######################################################################################################################
#
# YAML output
#
##

function yaml_header() {
	# item="$1"
	echo "files:"
}

function yaml_data() {
	item="$1"
	verbose=0 ; [ $# -eq 2 ] && verbose="$2"
	echo "  - \"$item\":"
	echo "    filename: \"$item\""

	if [ $verbose -eq 1 ]; then
		echo "    basename_hex: \"$item_hex\""
	fi

	echo "    found: \"$found\""
	echo "    type: \"$type\""
	if [ $verbose -eq 1 ]; then
		echo "    mime": \"$mime\"
	fi
	echo "    user: \"$user\""
	echo "    group: \"$group\""
	echo "    uid: $uid"
	echo "    gid: $gid"
	echo "    permissions: \"$perm\""
	echo "    mode: \"$mode\""
	echo "    size: $size"
	echo "    flags: \"$flags\""
	echo "    attributes: \"$attributes\""
	echo "    dates:"
	echo "      timestamp:"
	echo "      - birth: $timestamp_birth"
	echo "      - modified: $timestamp_modified"
	echo "      - last_access: $timestamp_last_access"
	echo "      - status_changed: $timestamp_status_changed"
	echo "      human_format:"
	echo "      - birth: \"$date_birth\""
	echo "      - modified: \"$date_modified\""
	echo "      - last_access: \"$date_last_access\""
	echo "      - status_changed: \"$date_status_changed\""
	echo "    digests:"
	if [ $verbose -eq 1 ]; then
		echo "      filename:md5: \"$name_md5\""
		echo "      filename:sha1: \"$name_sha1\""
		echo "      filename:sha256: \"$name_sha256\""
	fi
	echo "      data:md5: \"$md5\""
	echo "      data:sha1: \"$sha1\""
	echo "      data:sha256: \"$sha256\""
	echo "      data:sha512: \"$sha512\""
	if [ $verbose -eq 1 ]; then
		echo "      data:crc32: \"$crc32\""
		echo "      data:sha256.base64: \"$sha256b64\""
		echo "      data:sha512.base64: \"$sha512b64\""
		echo "    stats:"
		echo "      - strings: \"$stats_strings\""
		echo "      - nullbytes: \"$stats_nullbytes\""
		echo "      - binarybytes: \"$stats_binarybytes\""
		echo "    metadata:"
		echo "      - darwin_version: \"$darwin_version\""
		echo "      - darwin_bundle: \"$darwin_bundle\""
		echo "      - darwin_content_type: \"$darwin_content_type\""
		echo "      - darwin_filesystem_name: \"$darwin_filesystem_name\""
		echo "      - darwin_display_name: \"$darwin_display_name\""
		echo "      - darwin_usecount: \"$darwin_usecount\""
	fi
}

function yaml_array() {
	true
}

function yaml_end() {
	true
}




#######################################################################################################################
#
# Generic funcz
#
##

function print_data() {
	local format="$1"
	local item="$2"
	local verbose="$3"

	if [ "$format" = "json" ]; then
		get_data "$item" $verbose
		json_data "$item" $verbose
	elif [ "$format" = "yaml" ]; then
		get_data "$item" $verbose
		yaml_data "$item" $verbose
	else
		stat_output "$format" "$item" $verbose
	fi
}

function header() {
	[ "$1" = "json" ] && json_header
	[ "$1" = "yaml" ] && yaml_header
}

function end() {
	[ "$1" = "json" ] && json_end
	[ "$1" = "yaml" ] && yaml_end
}

function array() {
	[ "$1" = "json" ] && json_array $2
	[ "$1" = "yaml" ] && yaml_array $2
}



#######################################################################################################################
#
# Main
#
##

#======================================================================================================================

if [ "$1" = "help" ]; then
	banner
	usage 0
fi

#======================================================================================================================

verbose="0"

case "$1" in
	"json") format="json" ;;
	"yaml") format="yaml" ;;
	*)      format="$1"   ;;
esac
shift

if [ "$1" = "-v" ]; then
	verbose=1
	shift
fi

if [ $# -eq 0 ]; then
	error "missing items"
	usage 1
fi

#======================================================================================================================

header $format
while test $# -ne 0 ; do
	item="$1"
	found="false" ; [ -e "$item" ] && found="true"
	print_data $format $what "$item" $verbose
	shift
	array "$format" $#
done
end $format


