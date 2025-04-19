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
https://archive.eso.org/downloadportalapi/readme/7da7237e-1b4e-4ccf-bea0-a4d2d9da305f
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:14:16.314.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:10:50.603
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:40:28.673
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:18:27.456.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:49:45.524.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:30:18.689.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:59:05.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:51:18.870.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:19:38.554
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:14:38.548.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:04:55.424.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:48:40.517.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:41:52.771.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:38:18.868
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:52:06.417
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:53:48.686
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:11:11.945
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:05:39.869.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:08:18.672
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:05:39.869
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:25:13.612.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:45:07.283.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:46:58.578
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:57:29.024
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:46:58.578.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:15:48.373.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:33:42.237
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:56:27.258
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:38:28.534
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:57:23.563.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:49:41.043
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:32:52.302
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:45:20.981.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:41:16.460
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:21:02.419.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:43:34.691.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:38:18.868.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:16:45.427.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:02:27.600.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:46:12.904.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:55:48.716.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:09:30.867
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:42:55.177
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:16:18.497.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:19:42.850.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:17:30.928.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:44:40.428.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:21:02.419
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:55:30.325.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:41:42.855
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:21:50.514
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:14:10.650.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:24:16.338.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:50:37.597.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:49:37.272
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:12:53.865.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:13:00.754.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:33:42.237.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:00:49.642
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:12:53.865
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:19:12.241
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:19:11.317
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:13:22.629.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:52:06.417.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:27:47.565.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:33:49.676.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:01:23.476.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:02:27.600
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:41:52.771
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:15:58.672
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:06:24.382
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:16:18.497
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:47:54.883
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:36:08.691
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:39:32.239.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:36:37.289
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:07:30.336
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:43:52.232
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:20:09.015.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:14:06.583.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:45:45.031.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:30:27.698
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:18:27.456
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:18:03.750
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:48:56.379
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:45:17.190.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:32:44.962.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:17:39.631
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:15:58.672.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:19:42.850
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:13:22.629
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:36:47.575.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:36:10.473.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:50:24.568.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:58:07.295
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:29:22.195.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:57:23.563
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:58:07.295.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:17:58.376
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:03:13.975.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:14:36.064
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:09:12.546.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:40:00.926
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:35:05.465
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:00:46.521
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:15:03.938.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:12:34.934
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:12:30.621.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:59:48.874.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:11:41.320
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:15:03.938
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:30:18.689
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:04:08.859
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:52:19.226
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:14:41.723.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:12:58.379
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:33:14.871
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:17:30.928
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:19:21.200
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:59:43.377.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:58:53.453.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:25:13.612
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:42:09.832.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:40:10.513.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:29:50.943.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:35:29.644.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:19:43.719.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:39:34.991
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:35:29.644
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:34:28.384
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:45:33.231.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:44:40.428
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:04:44.393
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:23:06.999
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:35:23.556.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:23:32.253.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:41:13.538
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:53:00.899.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:15:50.789
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:34:27.282.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:39:34.991.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:50:22.517
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:38:46.354.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:04:10.148
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:36:08.691.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:19:38.554.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:44:36.436.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:16:18.062.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:07:31.397
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:55:42.234
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:09:10.504
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:00:35.082
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:09:59.931.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:28:37.270.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:03:03.804
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:47:02.360
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:34:55.930.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:21:25.559
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:50:37.597
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:01:32.306
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:29:29.124.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:44:36.436
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:47:59.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:42:55.177.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:48:40.517
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:16:18.062
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:16:45.427
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:38:46.354
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:29:22.195
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:53:04.040.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:14:10.650
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:53:00.899
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:08:18.672.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:27:39.766
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:59:48.874
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:36:10.473
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:03:58.450
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:35:05.465.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:22:43.878.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:29:29.124
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:59:50.417
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:37:05.066.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:44:05.073.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:42:58.529.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:29:50.943
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:05:50.156
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:36:47.575
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:45:20.981
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:11:11.945.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:34:27.282
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:26:06.396.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:28:46.860.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:27:39.766.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:35:23.556
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:42:58.529
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:39:32.239
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:04:10.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:10:43.805.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:01:32.306.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:49:37.272.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:18:03.750.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:24:25.317
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:59:09.533
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:43:24.874
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:51:22.542.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:11:41.320.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:45:33.231
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:02:16.511.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:46:18.655
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:14:16.314
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:03:13.975
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:00:49.642.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:12:25.215.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:10:53.585.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:02:16.511
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:45:45.031
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:14:38.548
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:09:59.931
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:17:30.011.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:33:49.676
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:13:00.754
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:48:43.589
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:17:30.011
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:22:34.838
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:26:55.521.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:02:30.229.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:31:32.902
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:51:22.542
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:40:28.673.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:15:50.789.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:49:06.609.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:47:54.883.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:49:06.609
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:54:00.415
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:05:49.938
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:25:58.347
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:19:21.200.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:00:46.521.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:06:24.382.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:46:21.937
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:54:45.590
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:41:16.460.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:04:55.424
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:30:27.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:45:17.190
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:53:04.040
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:06:37.273.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:37:50.020.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:54:00.415.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:10:43.805
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:19:12.241.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:14:36.064.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:46:21.937.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:43:24.874.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:05:49.938.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:07:49.688.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:17:58.376.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:52:19.226.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:59:43.377
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:28:37.270
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:07:31.397.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:04:44.393.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:16:23.212
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:58:08.938.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:20:09.015
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:21:25.559.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:32:00.278
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:06:37.273
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:31:32.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:10:50.603.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:09:12.546
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:14:41.723
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:59:50.417.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:49:45.524
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:44:30.815
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:32:44.962
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-07T12:12:58.379.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:16:23.212.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:27:47.565
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:46:18.655.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:50:22.517.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:02:30.229
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:31:03.554.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:57:12.244
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:48:56.379.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:23:06.999.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:42:24.723
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:48:03.555
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:37:52.482
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:26:55.521
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:54:45.590.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:14:06.583
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:22:43.878
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:43:34.691
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:38:28.534.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:17:39.631.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:47:02.360.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:44:30.815.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:59:09.533.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:24:25.317.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:47:14.840.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:09:02.557
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:01:23.476
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:41:42.855.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:07:21.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:46:12.904
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:34:28.384.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:56:24.877.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:37:05.066
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:18:00.522.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:50:24.568
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:47:14.840
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:09:30.867.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:10:53.585
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:31:03.554
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T14:19:43.719
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:41:13.538.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:48:43.589.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:31:11.193
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:21:50.514.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:26:06.396
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:57:29.024.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:36:37.289.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:44:05.073
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:32:08.707.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:59:05.052
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:23:32.253
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:42:09.832
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:32:52.302.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:49:41.043.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:00:35.082.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:12:30.621
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:58:53.453
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:56:24.877
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:20:53.480
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:07:21.458
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:58:08.938
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:07:30.336.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:09:10.504.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:54:42.878.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:32:08.707
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:34:55.930
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:04:08.859.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:33:14.871.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:40:00.926.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:55:42.234.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:09:02.557.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:40:10.513
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:43:52.232.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:07:49.688
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:47:59.624
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:03:58.450.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:47:25.109.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T17:18:00.522
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:45:07.283
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T10:55:48.716
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:42:24.723.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:37:52.482.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:56:27.258.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:19:11.317.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-12T11:47:25.109
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:37:50.020
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:51:18.870
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:55:30.325
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-01T11:05:50.156.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:25:58.347.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:12:25.215
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:15:48.373
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:53:48.686.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T13:03:03.804.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-09-06T11:28:46.860
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:24:16.338
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:31:11.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:48:03.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:22:34.838.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T20:12:34.934.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T01:54:42.878
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T17:57:12.244.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T18:20:53.480.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-31T19:32:00.278.NL
__EOF__
