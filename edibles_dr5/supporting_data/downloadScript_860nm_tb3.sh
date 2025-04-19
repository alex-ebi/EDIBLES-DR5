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
https://archive.eso.org/downloadportalapi/readme/8b51be78-fe4d-496a-95ea-e3821564f306
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:03:06.059
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:57:31.161.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:54:02.438.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:29:29.320
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:55:24.010.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:46:14.447
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:53:16.479
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:00:04.700.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:04:56.080
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:14:37.890.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:00:04.084.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:05:56.064.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:46:14.447.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:33:23.038.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:35:32.550.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:31:14.883
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:29:29.161
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:58:27.654
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:17:26.895
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:14:09.832
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:07:02.050.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:03:09.967.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:27:41.011
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:28:04.482.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:04:34.255.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:01:29.687
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:33:04.810.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:17:26.895.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:03:28.850.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:36:06.018
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:02:04.562
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:48:38.570
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:35:11.269.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:07:44.625.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:01:29.112.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:58:39.087.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:28:04.482
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:39:24.031.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:57:14.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:55:24.010
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:58:39.087
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:02:04.562.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:10:12.649
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:30:54.257
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:13:02.504.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:11:19.073
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:18:22.284
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:03:28.850
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:52:01.294
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:04:53.159.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:40:19.040
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:06:20.088
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:29:06.686
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:01:29.687.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:03:31.363.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:02:54.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:04:34.255
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:11:19.073.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:58:40.473
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:07:42.212
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:11:49.275
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:39:48.552
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:04:31.166
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:15:33.820.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:04:53.598.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:55:36.973.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:13:13.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:01:41.072.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:57:24.942
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:05:56.064
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:36:52.564.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:31:17.010
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:48:38.570.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:04:31.166.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:15:52.039
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:48:25.085
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:52:14.479
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:02:53.926
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:18:22.284.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:16:03.017.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:37:30.425
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:50:13.105.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:14:37.890
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:00:16.594.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:44:06.046.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:09:10.031.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:33:23.038
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:55:36.403.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:53:48.913
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:34:52.619
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:04:18.233
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:53:47.893.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:02:44.027.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:32:39.041.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:37:30.425.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:36:36.037
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:35:27.616
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:04:53.159
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:29:29.320.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:57:24.942.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:48:23.038.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:41:43.917
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:07:23.080
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:04:18.233.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:35:27.616.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:44:06.046
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:35:32.550
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:33:46.121
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:31:17.010.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:54:02.438
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:53:48.913.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:05:58.752.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:59:12.872.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:38:54.633.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:02:54.170
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:41:57.574
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:00:35.016
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:34:02.978
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:13:28.064
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:41:57.574.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:09:09.583.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:46:50.191.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:07:44.625
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:00:16.594
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:50:26.579.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:26:40.285.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:03:06.059.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:58:40.473.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:36:06.018.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:33:04.810
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:09:10.031
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:11:37.467.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:29:06.686.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:06:17.785
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:00:35.016.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:13:28.064.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:52:01.294.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:25:16.137.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:04:53.598
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:46:50.191
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:35:11.269
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:31:14.883.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:07:42.212.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:02:44.027
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:40:19.040.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:39:48.552.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:14:09.832.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:53:16.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:08:47.167
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:14:26.651.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:51:59.893
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:05:58.752
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:27:41.011.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:01:46.214.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:12:45.215
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:11:37.467
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:51:59.893.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:12:45.215.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:11:49.275.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:50:26.579
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:07:23.080.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:16:57.817
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:02:53.926.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:37:40.041.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:26:40.285
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:06:17.785.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:16:57.817.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:34:52.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:36:36.037.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:34:02.978.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:41:43.917.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:08:47.167.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:54:11.312
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:50:13.105
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:53:47.893
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:55:36.973
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:09:09.583
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:03:09.967
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:14:26.651
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:00:04.700
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:56:19.063
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:15:52.039.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:38:54.633
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:06:20.088.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:33:46.121.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T12:01:41.072
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:54:11.312.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:13:02.504
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:25:16.137
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:31:15.036
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:29:29.161.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:36:52.564
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:39:24.031
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:07:02.050
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:30:54.257.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:59:39.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:48:25.085.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:38:00.024.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:59:12.872
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:16:03.017
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:48:23.038
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:56:19.063.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:59:39.052
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:13:13.902
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:10:12.649.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:01:46.214
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:31:15.036.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:04:56.080.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:32:39.041
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T13:57:31.161
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:01:29.112
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T16:52:14.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:03:31.363
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:58:27.654.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T21:57:14.619
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:38:00.024
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T22:00:04.084
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:55:36.403
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:37:40.041
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:15:33.820
__EOF__