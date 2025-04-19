#!/bin/sh

usage () {
    cat <<__EOF__
usage: $(basename $0) [-hlp] [-u user] [-X args] [-d args]
  -h        print this help text
  -l        print list of files to download
  -p        prompt for password
  -u user   download as a different user
  -X args   extra arguments to pass to xargs
  -d args   extra arguments to pass to the download program

__EOF__
}

hostname=dataportal.eso.org
username=anonymous
anonymous=
xargsopts=
prompt=
list=
while getopts hlpu:xX:d: option
do
    case $option in
	h) usage; exit ;;
	l) list=yes ;;
	p) prompt=yes ;;
	u) prompt=yes; username="$OPTARG" ;;
	X) xargsopts="$OPTARG" ;;
	d) download_opts="$OPTARG";;
	?) usage; exit 2 ;;
    esac
done

if [ "$username" = "anonymous" ]; then
    anonymous=yes
fi

if [ -z "$xargsopts" ]; then
    #no xargs option specified, we ensure that only one url
    #after the other will be used
    xargsopts='-L 1'
fi

netrc=$HOME/.netrc
if [ -z "$anonymous" -a -z "$prompt" ]; then
    # take password (and user) from netrc if no -p option
    if [ -f "$netrc" -a -r "$netrc" ]; then
	grep -ir "$hostname" "$netrc" > /dev/null
	if [ $? -ne 0 ]; then
            #no entry for $hostname, user is prompted for password
            echo "A .netrc is available but there is no entry for $hostname, add an entry as follows if you want to use it:"
            echo "machine $hostname login anonymous password _yourpassword_"
            prompt="yes"
	fi
    else
	prompt="yes"
    fi
fi

if [ -n "$prompt" -a -z "$list" ]; then
    trap 'stty echo 2>/dev/null; echo "Cancelled."; exit 1' INT HUP TERM
    stty -echo 2>/dev/null
    printf 'Password: '
    read password
    echo ''
    stty echo 2>/dev/null
    escaped_password=${password//\%/\%25}
    auth_check=$(wget -O - --post-data "username=$username&password=$escaped_password" --server-response --no-check-certificate "https://www.eso.org/sso/oidc/accessToken?grant_type=password&client_id=clientid" 2>&1 | awk '/^  HTTP/{print $2}')
    if [ ! $auth_check -eq 200 ]
    then
        echo 'Invalid password!'
        exit 1
    fi
fi

# use a tempfile to which only user has access 
tempfile=`mktemp /tmp/dl.XXXXXXXX 2>/dev/null`
test "$tempfile" -a -f $tempfile || {
    tempfile=/tmp/dl.$$
    ( umask 077 && : >$tempfile )
}
trap 'rm -f $tempfile' EXIT INT HUP TERM

echo "auth_no_challenge=on" > $tempfile
# older OSs do not seem to include the required CA certificates for ESO
echo "check_certificate=off" >> $tempfile
echo "content_disposition=on" >> $tempfile
echo "continue=on" >> $tempfile
if [ -z "$anonymous" -a -n "$prompt" ]; then
    echo "http_user=$username" >> $tempfile
    echo "http_password=$password" >> $tempfile
fi
WGETRC=$tempfile; export WGETRC

unset password

if [ -n "$list" ]; then
    cat
else
    xargs $xargsopts wget $download_opts 
fi <<'__EOF__'
https://archive.eso.org/downloadportalapi/readme/813f890f-31a5-4f1b-b809-2301578db648
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:06:34.841.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:59:46.729
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:35:56.188.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:58:28.395
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:02:59.574
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:40:28.919.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:50:41.747.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:42:45.210
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:28:47.726
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:01:17.566.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:43:26.736
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:14:11.540.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:24:00.803
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:49:33.732
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:59:35.248.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:04:52.772
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:56:35.755
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:28:32.673.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:36:20.422
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:38:46.660.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:47:17.371
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:04:54.659
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:47:51.444
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:44:27.358.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:54:40.466.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:12:29.693
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:47:51.444.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:45:07.654
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:16:04.538.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:25:07.957
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:19:18.184.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:06:23.440.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:03:34.249
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:16:04.538
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:24:00.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:32:31.553
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:43:53.175
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:12:29.693.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:04:41.572.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:18:18.706
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:33:39.286
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:35:21.725
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:07:36.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:04:19.751.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:13:22.896
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:52:34.114.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:36:20.422.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:09:43.409
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:29:31.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:20:01.014
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:51:15.999
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:39:20.874
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:31:13.549
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:52:34.114
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:29:31.532
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:24:33.467.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:30:49.524
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:35:56.188
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:06:58.925.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:03:10.835
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:06:23.440
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:55:03.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:17:35.966.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:15:29.604
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:00:55.424
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:56:35.755.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:13:57.589
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:14:54.630.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T09:59:06.191
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:26:06.866
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:55:48.401.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:01:52.351.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:19:18.184
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:11:50.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:55:03.879
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:22:42.910.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:01:13.761.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:09:48.126.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:20:36.528
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:34:37.985
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:04:52.772.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:18:54.080
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:29:07.437
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:31:57.149.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:09:08.558
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:13:47.216
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:48:29.529
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:22:18.605.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:01:28.677.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:54:29.135
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:24:24.778.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:56:11.202
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:54:35.045
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:52:58.007
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:46:09.496.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:59:12.967
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:14:54.630
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:18:18.706.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:54:06.253
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:59:12.967.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:09:26.174
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:13:47.216.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:18:11.428.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:59:46.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:33:39.286.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:55:48.401
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:05:40.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:44:27.358
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:13:12.241
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:42:45.210.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:10:22.990
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:50:33.043
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:48:15.488
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:12:05.128.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:08:05.868.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:32:55.607
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:29:07.437.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:49:33.732.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:51:39.533
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:56:22.584.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:56:46.037.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:15:54.038.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:09:05.137.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:13:12.241.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:09:26.174.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:10:47.415.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:08:41.132.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:17:11.672
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:46:48.591
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:20:01.014.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:34:37.985.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:14:11.540
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:37:03.973.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:45:35.422
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:57:53.171
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:35:21.725.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:11:30.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:54:06.253.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:46:09.496
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:56:46.037
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:03:10.835.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:31:57.149
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:09:48.126
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:04:54.659.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:56:11.202.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:00:10.333
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:00:34.228
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:15:54.038
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:15:29.604.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:20:18.737
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:49:57.476
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:43:08.974.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:22:18.605
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:10:22.990.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:07:22.980
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:52:58.007.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:51:15.999.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:52:23.985.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:28:47.726.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:58:28.395.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:07:22.980.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:09:43.409.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:23:25.999.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:41:26.716.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:24:24.778
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:40:28.919
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:26:50.395
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:26:40.346
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:05:16.496
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:42:10.937
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:09:05.137
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:07:01.708.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:41:03.243
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:01:28.677
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:06:01.808.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:25:42.931.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:21:43.481
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:22:25.917.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:08:05.868
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:16:36.708.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:23:25.999
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:16:36.708
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:57:30.729
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:03:34.249.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:54:35.045.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:07:01.708
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:02:37.533
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:53:21.572.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:09:08.558.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:44:51.452.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:01:52.351
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:00:34.228.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:31:13.549.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:50:10.427.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:48:59.579.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:57:53.171.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:41:03.243.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:37:38.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:30:14.871
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:17:11.672.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:13:57.589.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:24:33.467
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:07:43.996.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:57:30.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:17:35.966
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:48:59.579
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:37:03.973
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:44:51.452
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:02:59.574.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:00:55.424.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:20:18.737.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:50:33.043.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:41:26.716
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:04:41.572
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:11:50.879
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:00:10.333.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:20:36.528.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:54:29.135.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:12:05.128
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:26:06.866.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:27:49.194.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:04:19.751
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:46:33.400.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:48:32.013.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:37:38.607
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:54:40.466
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:07:43.996
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:01:13.761
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:30:49.524.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:02:16.436.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:27:25.149.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T14:59:35.248
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:47:17.371.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:27:49.194
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:56:22.584
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:38:46.660
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:30:14.871.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:32:31.553.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:39:44.279
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:52:23.985
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:05:16.496.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:25:42.931
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:45:35.422.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:50:41.747
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:05:40.532
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:46:33.400
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:18:54.080.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:48:29.529.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:38:02.341.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:05:28.440.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:01:17.566
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:21:00.422
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:03:58.474
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:38:02.341
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:11:15.917
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:02:16.436
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:10:47.415
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:02:37.533.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T20:06:34.841
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:07:36.170
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:21:43.481.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:43:26.736.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:03:21.000.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:26:50.395.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:21:00.422.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:08:41.132
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:27:25.149
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:43:53.175.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:51:39.533.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T09:59:06.191.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:43:08.974
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:34:13.751.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:28:32.673
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T09:48:32.013
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:42:10.937.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:45:07.654.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:03:58.474.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:50:10.427
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:39:44.279.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-27T09:46:48.591.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:39:20.874.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:58:04.821
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:11:30.193
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:13:22.896.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T16:06:01.808
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:06:58.925
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:58:04.821.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:18:11.428
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:26:40.346.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T19:34:13.751
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:03:21.000
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:05:28.440
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:53:21.572
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T15:25:07.957.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:49:57.476.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:32:55.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:48:15.488.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-30T18:22:42.910
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:11:15.917.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:22:25.917
__EOF__
