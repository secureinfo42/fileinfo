# fileinfo

Simple bash script to get detailed informations about files.

Verbose is slower because it computes ratio of NULL bytes and Strings.

## Synopsis

```sh
░█▀▀░▀█▀░█░░░█▀▀░▀█▀░█▀█░█▀▀░█▀█
░█▀▀░░█░░█░░░█▀▀░░█░░█░█░█▀▀░█░█
░▀░░░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀
>>> fileinfo ===================

Usage: fileinfo [-j [-v]] <item> [item2 [item3]...]

 -j  : output is in JSON format
 -v  : get more informations

Without options do stat and common hash digests

Exemples:
fileinfo /bin/ls /bin/sh /etc/hosts
fileinfo -j ~/ # Can be a folder
fileinfo -j -v /usr/bin/jq
```

> PS : banner is sent to stderr :)
	
## SHA256.BASE64 ?

SHA256 and SHA512 have long output. To shorten this, some SIEM and tools use the base64 format of the hash. It can be found this way :

`openssl dgst -sha512 /path/to/file | cut -d' ' -f1 | xxd -ps -r | base64 -w0`

- `openssl dgst -sha512 /path/to/file` : get the SHA512
- `cut -d' ' -f1` : output of `openssl` is `hash file`, separator is space  
- `xxd -ps -r | base64 -w0` : unhex the output to make it raw, then encode in base64 without new line (`-w0`)

Exemple :

```
/usr/bin/openssl dgst -sha512 -r /bin/ls|cut -d' ' -f1
```

```
# Output
cad90c4f41ecbf0c29a0ad68ca5af0335effc804c1fe226bd2bbc7cdf50bbfc9a1986f18e04960664aa5684c733d8e631683379de8803ffda37e85cc62dcfd07
```

```sh
/usr/bin/openssl dgst -sha512 -r /bin/ls|cut -d' ' -f1|xxd -ps -r|xxd
```

```
# Output
00000000: cad9 0c4f 41ec bf0c 29a0 ad68 ca5a f033  ...OA...)..h.Z.3
00000010: 5eff c804 c1fe 226b d2bb c7cd f50b bfc9  ^....."k........
00000020: a198 6f18 e049 6066 4aa5 684c 733d 8e63  ..o..I`fJ.hLs=.c
00000030: 1683 379d e880 3ffd a37e 85cc 62dc fd07  ..7...?..~..b...
```

```
/usr/bin/openssl dgst -sha512 -r /bin/ls|cut -d' ' -f1|xxd -ps -r|base64 -w0
```

```
# Output
ytkMT0HsvwwpoK1oylrwM17/yATB/iJr0rvHzfULv8mhmG8Y4ElgZkqlaExzPY5jFoM3neiAP/2jfoXMYtz9Bw==
```

## Which informations are gathered ?

- files
- filename
- basename_hex
- found
- type
- user
- group
- uid
- gid
- permissions
- mode
- size
- flags
- attributes
- dates
	- human_format
		- birth
		- modified
		- last_access
		- status_changed
	- timestamp
		- birth
		- modified
		- last_access
		- status_changed
- digests
	- filename:md5
	- filename:sha1
	- filename:sha256
	- data:md5
	- data:sha1
	- data:sha256
	- data:sha512
	- data:crc32
	- data:sha256.base64
	- data:sha512.base64
- stats
	- strings
	- nullbytes
- metadata
	- darwin_version
	- darwin_bundle
	- darwin_content_type
	- darwin_filesystem_name
	- darwin_display_name
	- darwin_usecount

## Basic format data

```
  File: /bin/sh
  Size: 150384    	Blocks: 24         IO Block: 4096   regular file
Device: 100000fh/16777231d	Inode: 1152921500312779669  Links: 1
Access: (0755/-rwxr-xr-x)  Uid: (    0/    root)   Gid: (    0/   wheel)
Access: 2022-05-09 23:30:48.000000000 +0200
Modify: 2022-05-09 23:30:48.000000000 +0200
Change: 2022-05-09 23:30:48.000000000 +0200
 Birth: 2022-05-09 23:30:48.000000000 +0200
   MD5: aa6a7346afb5f4ee0ac618c4873f1cbb
  SHA1: 2bce3dae92fc48a6671c86af83206f4a99a2b9bf
SHA256: ff4917c0f8c86f4a85e2bef778691a70f3ea05a7ca9a6c2b121acd4b2e359d16
```

For JSON format, you can use `jq` to make your output more pretty

## JSON format data

```json
{
  "files": [
    { "filename": "/bin/sh", "found": "true", "type": "Mach-O universal binary with 2 architectures: [x86_64:012- Mach-O 64-bit x86_64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>] [arm64e (caps: 0x2):012- Mach-O 64-bit arm64e (caps: PAC00) executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>]", "user": "root", "group": "wheel", "uid": "0", "gid": "0", "permissions": "-rwxr-xr-x", "mode": "755", "size": "150384", "flags": "restricted,compressed", "attributes": "-", "dates": {  "human_format": {   "birth": "2022-05-09 23:30:48.000000000 +0200",   "modified": "2022-05-09 23:30:48.000000000 +0200",   "last_access": "2022-05-09 23:30:48.000000000 +0200",   "status_changed": "2022-05-09 23:30:48.000000000 +0200"  },  "timestamp": {   "birth": "1652131848",   "modified": "1652131848",   "last_access": "1652131848",   "status_changed": "1652131848"  } }, "digests": {  "data:md5": "aa6a7346afb5f4ee0ac618c4873f1cbb",  "data:sha1": "2bce3dae92fc48a6671c86af83206f4a99a2b9bf",  "data:sha256": "ff4917c0f8c86f4a85e2bef778691a70f3ea05a7ca9a6c2b121acd4b2e359d16",  "data:sha512": "db9733f30022707186edf3b58de0bae4f7eed6bf6365a5976b44a4efff61a5a403d00ee5176af9d0433d81b36ce317ce33df787feec607c7051ec0d6b722338c" }}
  ]
}
```

## JSON detailed format data

```json
{
  "files": [
    { "filename": "/bin/sh", "basename_hex": "7368", "found": "true", "type": "Mach-O universal binary with 2 architectures: [x86_64:012- Mach-O 64-bit x86_64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>] [arm64e (caps: 0x2):012- Mach-O 64-bit arm64e (caps: PAC00) executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>]", "user": "root", "group": "wheel", "uid": "0", "gid": "0", "permissions": "-rwxr-xr-x", "mode": "755", "size": "150384", "flags": "restricted,compressed", "attributes": "-", "dates": {  "human_format": {   "birth": "2022-05-09 23:30:48.000000000 +0200",   "modified": "2022-05-09 23:30:48.000000000 +0200",   "last_access": "2022-05-09 23:30:48.000000000 +0200",   "status_changed": "2022-05-09 23:30:48.000000000 +0200"  },  "timestamp": {   "birth": "1652131848",   "modified": "1652131848",   "last_access": "1652131848",   "status_changed": "1652131848"  } }, "digests": {  "filename:md5": "5f54a6ad4e4e28b1cfea4c1160ba743d",  "filename:sha1": "db8502aaf162a542f38cc564ea14f0c98bfe1ed0",  "filename:sha256": "968849b35858c8eb6132f7567f9c8d18af4d995b3189226526e63d6c6fe3efb9",  "data:md5": "aa6a7346afb5f4ee0ac618c4873f1cbb",  "data:sha1": "2bce3dae92fc48a6671c86af83206f4a99a2b9bf",  "data:sha256": "ff4917c0f8c86f4a85e2bef778691a70f3ea05a7ca9a6c2b121acd4b2e359d16",  "data:sha512": "db9733f30022707186edf3b58de0bae4f7eed6bf6365a5976b44a4efff61a5a403d00ee5176af9d0433d81b36ce317ce33df787feec607c7051ec0d6b722338c",  "data:crc32": "562ead1a",  "data:sha256.base64": "/0kXwPjIb0qF4r73eGkacPPqBafKmmwrEhrNSy41nRY=",  "data:sha512.base64": "25cz8wAicHGG7fO1jeC65Pfu1r9jZaWXa0Sk7/9hpaQD0A7lF2r50EM9gbNs4xfOM994f+7GB8cFHsDWtyIzjA==" }, "stats": {  "strings": "0.150%",  "nullbytes": "1.275%" }, "metadata": {  "darwin_version": "N/A",  "darwin_bundle": "N/A",  "darwin_content_type": "public.unix-executable",  "darwin_filesystem_name": "sh",  "darwin_display_name": "sh",  "darwin_usecount": "N/A" }}
  ]
}
```

With `jq` it looks like : 

```json
{
  "files": [
    {
      "filename": "/bin/sh",
      "basename_hex": "7368",
      "found": "true",
      "type": "Mach-O universal binary with 2 architectures: [x86_64:012- Mach-O 64-bit x86_64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>] [arm64e (caps: 0x2):012- Mach-O 64-bit arm64e (caps: PAC00) executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>]",
      "user": "root",
      "group": "wheel",
      "uid": "0",
      "gid": "0",
      "permissions": "-rwxr-xr-x",
      "mode": "755",
      "size": "150384",
      "flags": "restricted,compressed",
      "attributes": "-",
      "dates": {
        "human_format": {
          "birth": "2022-05-09 23:30:48.000000000 +0200",
          "modified": "2022-05-09 23:30:48.000000000 +0200",
          "last_access": "2022-05-09 23:30:48.000000000 +0200",
          "status_changed": "2022-05-09 23:30:48.000000000 +0200"
        },
        "timestamp": {
          "birth": "1652131848",
          "modified": "1652131848",
          "last_access": "1652131848",
          "status_changed": "1652131848"
        }
      },
      "digests": {
        "filename:md5": "5f54a6ad4e4e28b1cfea4c1160ba743d",
        "filename:sha1": "db8502aaf162a542f38cc564ea14f0c98bfe1ed0",
        "filename:sha256": "968849b35858c8eb6132f7567f9c8d18af4d995b3189226526e63d6c6fe3efb9",
        "data:md5": "aa6a7346afb5f4ee0ac618c4873f1cbb",
        "data:sha1": "2bce3dae92fc48a6671c86af83206f4a99a2b9bf",
        "data:sha256": "ff4917c0f8c86f4a85e2bef778691a70f3ea05a7ca9a6c2b121acd4b2e359d16",
        "data:sha512": "db9733f30022707186edf3b58de0bae4f7eed6bf6365a5976b44a4efff61a5a403d00ee5176af9d0433d81b36ce317ce33df787feec607c7051ec0d6b722338c",
        "data:crc32": "562ead1a",
        "data:sha256.base64": "/0kXwPjIb0qF4r73eGkacPPqBafKmmwrEhrNSy41nRY=",
        "data:sha512.base64": "25cz8wAicHGG7fO1jeC65Pfu1r9jZaWXa0Sk7/9hpaQD0A7lF2r50EM9gbNs4xfOM994f+7GB8cFHsDWtyIzjA=="
      },
      "stats": {
        "strings": "0.150%",
        "nullbytes": "1.275%"
      },
      "metadata": {
        "darwin_version": "N/A",
        "darwin_bundle": "N/A",
        "darwin_content_type": "public.unix-executable",
        "darwin_filesystem_name": "sh",
        "darwin_display_name": "sh",
        "darwin_usecount": "N/A"
      }
    }
  ]
}
```



