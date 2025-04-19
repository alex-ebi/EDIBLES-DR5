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
https://archive.eso.org/downloadportalapi/readme/ec23062f-6d69-431e-b694-fbbf5cd1c475
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:40:07.588.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:15:41.770.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:12:39.989
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:35:59.983
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:53:26.012.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:51:34.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:54:10.770.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:51:22.193
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:44:46.097.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:48:58.045.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:52:56.220.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:38:50.061.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:09:50.030.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:59:04.972.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:02:18.419
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:46:03.573.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:02:27.620.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:02:33.777.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:37:57.405
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:04:52.764.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:49:08.056.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:17:45.006.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:20:55.217.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:19:25.419
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:12:19.128.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:14:24.503
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:02:37.826
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:57:06.761.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:17:37.522.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:26:13.166
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:49:37.967
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:22:02.944
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:19:21.302
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:49:55.824
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:38:06.185
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:48:29.008.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:26:52.839.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:38:34.617
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:51:35.846.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:08:31.429.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:42:59.595
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:34:56.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:14:55.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:53:55.803
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:52:42.773
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:11:01.051.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:55:16.966
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:41:10.002
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:09:16.400.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:02:18.419.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:51:33.039.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:47:30.382.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:36:14.047.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:19:27.661.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:34:53.335
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:38:34.617.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:22:50.062
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:13:29.985
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:18:29.287
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:00:02.812
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:04:08.219.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:32:23.886.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:41:48.716
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:46:32.710.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:48:38.527
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:43:07.594.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:39:23.572
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:52:39.280
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:51:55.964.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:14:55.236
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:52:42.773.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:55:40.024.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:02:27.620
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:13:29.985.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:51:55.964
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:09:44.044
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:33:25.520
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:37:50.178
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:20:55.217
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:34:42.926
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:37:46.224
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:35:59.983.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:39:14.632
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:51:22.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:54:17.967
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:41:42.028.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:11:48.979.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:46:07.720
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:12:19.128
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:50:15.422.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:16:45.308
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:47:37.988.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:47:20.881.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:04:37.949.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:51:25.796.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:49:08.056
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:40:24.682
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:32:09.521
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:03:51.115
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:36:48.418
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:23:20.331.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:37:17.280.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:39:07.544.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:04:08.219
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:52:53.583.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:36:15.352
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:39:27.993
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:14:21.058.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:23:16.056.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:50:02.843.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:01:15.800.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:50:08.299
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:17:37.522
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:25:35.562
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:47:20.881
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:52:53.583
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:39:14.632.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:50:18.610.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:53:59.700.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:23:32.822
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:56:26.979.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:34:07.884.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:23:20.331
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:44:37.732
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:01:20.229
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:32:09.521.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:49:55.824.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:05:57.599
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:31:31.041.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:40:07.588
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:42:52.001
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:59:58.664
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:46:54.841.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:16:02.986
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:09:44.044.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:35:07.130
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:15:41.770
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:55:13.199
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:54:57.030
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:22:50.062.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:24:31.052
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:51:20.149
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:34:42.926.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:59:58.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:50:02.843
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:04:55.171
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:03:34.796
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:47:56.218.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:39:27.993.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:28:10.366
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:40:40.709
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:35:07.130.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:47:40.649.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:18:10.404.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:50:04.806.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:52:56.220
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:25:35.562.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:52:21.052
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:34:53.335.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:42:52.001.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:41:58.616
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:43:06.122
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:01:54.995
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:24:33.973
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:20:45.247.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:47:40.649
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:16:45.308.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:53:59.700
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:09:50.016
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:27:33.413.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:34:22.486.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:10:58.369.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:13:37.035
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:49:01.173
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:02:37.826.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:09:16.400
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:07:55.167.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:50:25.816.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:01:00.851
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:51:35.846
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:08:26.758.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:37:32.544.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:17:22.816
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:10:31.232.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:48:12.848.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:46:14.016.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:49:30.114.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:34:56.170
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:34:22.486
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:59:42.435
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:36:48.418.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:51:42.838
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:52:50.386.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:02:33.777
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:41:42.028
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:33:15.870
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:07:15.116.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:54:57.030.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:36:04.084.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:49:07.814.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:50:11.365
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:01:00.851.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:05:57.599.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:02:17.890.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:47:50.197
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:44:37.732.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:50:25.251.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:00:46.230
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:57:24.893.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:45:37.524.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:41:10.002.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:16:02.986.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:30:47.343.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:15:52.743.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:59:43.197.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:07:13.942.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:36:04.084
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:37:57.405.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:04:52.764
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:16:25.474
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:10:31.232
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:51:33.039
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:05:55.436
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:47:56.218
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:16:05.099.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:51:03.995
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:46:54.841
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:47:11.575
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:51:34.052
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:45:37.524
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:13:06.266
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:22:12.785.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:03:55.273
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:16:05.099
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:05:08.491.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:01:15.800
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:14:47.772.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:44:33.030.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:48:29.008
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:54:10.770
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:36:15.352.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:07:15.116
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:40:24.682.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:03:34.796.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:55:40.024
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:55:16.966.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:13:06.266.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:05:55.436.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:19:21.302.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:50:08.299.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:52:50.386
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:21:08.453.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:32:23.886
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:58:45.375.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:53:55.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:50:25.251
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:12:12.808.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:20:45.247
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:50:25.816
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:49:45.988
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:48:58.045
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:06:25.229.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:11:07.606
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:51:03.995.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:03:24.983
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:48:12.848
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:53:26.012
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:08:32.563
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:47:11.575.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:03:55.273.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:43:06.122.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:01:00.534
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:33:31.338
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:50:15.422
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:24:53.119.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:47:50.197.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:02:17.890
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:54:17.967.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:40:31.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:52:21.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:47:37.988
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:08:26.758
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:47:30.382
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:23:16.056
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:03:24.983.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:33:25.520.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:48:47.779.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:49:45.988.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:57:06.761
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:25:51.989.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:22:02.944.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:21:58.039.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:44:46.097
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:17:55.521.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:36:14.047
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:46:03.573
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:52:39.280.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:49:37.967.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:40:40.709.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:49:30.114
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:24:18.115
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:09:50.030
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:19:26.011
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:50:11.365.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:20:40.032
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:00:02.812.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:58:24.448
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:50:47.651
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:22:12.785
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:49:07.814
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:18:29.287.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:55:13.199.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:04:37.949
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:14:47.772
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:01:20.229.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:27:33.413
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:12:39.989.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:42:59.595.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:33:31.338.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:28:10.366.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:59:04.972
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:24:31.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:52:37.825
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:59:43.197
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:56:26.979
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:23:32.822.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:46:14.016
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:17:22.816.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:17:45.006
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:17:55.521
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:57:24.893
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:44:33.030
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:50:47.651.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:33:15.870.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:19:25.419.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:46:07.720.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:06:25.229
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:58:45.375
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:40:31.619
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:24:33.973.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:31:31.041
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:20:40.032.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:38:06.185.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:15:52.743
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:50:18.610
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:11:07.606.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:37:17.280
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:19:26.011.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:08:31.429
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:37:46.224.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-13T11:34:07.884
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:51:42.838.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:41:48.716.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:00:46.230.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:03:51.115.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:09:50.016.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:13:37.035.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T12:07:13.942
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:04:55.171.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:01:54.995.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:30:47.343
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:16:25.474.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:48:47.779
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:01:00.534.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:23:00.488
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:21:08.453
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:49:01.173.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:10:58.369
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:59:42.435.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:58:24.448.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:43:07.594
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:25:51.989
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:26:52.839
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:21:58.039
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:39:07.544
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:48:38.527.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:38:50.061
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:14:24.503.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:52:37.825.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:51:20.149.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:37:50.178.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:24:53.119
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:18:10.404
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:51:25.796
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:24:18.115.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:11:01.051
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:39:23.572.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:14:21.058
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:05:08.491
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:37:32.544
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:46:32.710
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:19:27.661
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:08:32.563.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:12:12.808
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:50:04.806
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:41:58.616.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:23:00.488.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-23T10:26:13.166.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:07:55.167
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:11:48.979
__EOF__