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
https://archive.eso.org/downloadportalapi/readme/af7741fb-6482-4b99-98a2-548c9bfcb664
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:29:13.793
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:36:59.800
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:31:56.178.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:28:44.619
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:16:19.191.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:56:48.868
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:49:54.851.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:42:57.229.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:54:38.175.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:51:56.757
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:29:47.866.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:48:39.809
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:12:31.718.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:47:26.537.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:05:50.298.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:49:39.255.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:32:16.674
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:53:57.591
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:30:18.573
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:26:30.888
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:57:55.272
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:29:12.449
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T12:03:39.431
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:43:00.824.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:13:01.174
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:45:27.709.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:35:12.944.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:36:09.002.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:19:36.989
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:57:55.272.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:52:55.523.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:42:09.542
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:56:12.961.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:30:55.771
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:31:36.249.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:17:49.684
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:32:16.674.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:06:15.955.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:15:03.120
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:28:44.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:00:44.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:44:46.901
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:22:03.545.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:49:51.466
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T13:02:46.637
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:22:26.682.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:56:45.453
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:56:57.909.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:28:39.723
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:27:08.667.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:42:52.639
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:51:21.537
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:23:44.578.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:42:09.542.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:15:03.120.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:26:30.888.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:54:38.175
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T12:03:39.431.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T09:59:39.850.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:24:43.247
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:29:35.267
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:14:40.333
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:59:02.666
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:21:28.423
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:53:51.223
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:04:03.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:57:21.048.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:10:00.226
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:32:45.137.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:17:58.100
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:03:53.236
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:28:21.880
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:57:21.946.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:25:23.428
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:41:13.411.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:36:17.218.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:17:45.148
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:43:00.824
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:23:13.871
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:03:53.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:08:59.639
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:52:18.792
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:25:50.167.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:02:57.568
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:30:55.771.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:15:29.449
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:48:39.809.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:22:26.682
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:50:34.977.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:38:29.550.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:37:56.136.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:04:36.897.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:42:09.854.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:48:04.169.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:28:21.880.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:29:35.267.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:22:03.545
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:45:22.651.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:27:32.005.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:42:52.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:16:40.536.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:17:20.507
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:37:19.969
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:25:15.152.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:40:30.814
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:47:08.591
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:17:10.512
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:15:29.449.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:04:56.702.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:04:08.590.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:07:28.524
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:53:41.573.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:23:13.871.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:29:45.223
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:43:48.640.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:23:44.578
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:32:37.699.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:51:56.757.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:35:12.944
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:05:35.274.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:34:48.327
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:42:05.624
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:44:46.901.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:44:54.645.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:20:27.570
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:07:32.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:22:10.664
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:52:18.792.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:24:08.459.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:48:04.169
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:59:29.588
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:16:40.536
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:39:51.561.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:29:47.866
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:49:51.466.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:53:51.223.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:24:08.459
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:49:58.130.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:26:18.329.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:49:03.811.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:40:15.153.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:53:57.591.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:19:56.853.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:42:09.854
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:54:50.234.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:07:28.524.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:59:53.668.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:21:28.423.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T15:00:14.264
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:47:08.591.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:05:35.274
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:37:19.969.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:22:10.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:37:56.136
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:27:13.171
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:15:36.559.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:27:01.556
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:15:36.559
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:10:41.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:27:32.005
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:20:44.403.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:45:22.651
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:38:48.716
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:30:25.695.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:59:02.666.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:54:50.234
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:43:48.640
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:47:18.432.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T15:00:14.264.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:00:44.624
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:20:44.403
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:55:39.339
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:32:45.137
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:25:20.393
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:01:18.528.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:24:43.247.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:05:50.298
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:52:15.493.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:18:46.447
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:30:25.695
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:56:12.961
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:42:22.963
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:49:58.130
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:29:45.223.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:18:46.447.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:34:48.327.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:01:18.528
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:50:25.057.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T12:10:33.438
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:38:48.716.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:52:15.493
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:19:02.425
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:10:15.122.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:31:36.249
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:44:54.645
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:10:00.226.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:55:39.339.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:12:31.718
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:39:26.040.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:57:21.048
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:23:51.170
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:39:34.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:17:49.684.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:33:42.722.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:32:51.994
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:10:56.252.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:17:20.507.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:06:15.955
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:42:22.963.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:59:29.588.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:53:41.573
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:36:09.002
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:07:17.541.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:36:17.218
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:57:21.946
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:27:13.171.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:19:02.425.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:12:12.051.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:40:15.153
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:18:53.726
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T13:00:24.344.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:49:03.811
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T11:51:21.537.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:40:30.814.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:26:18.329
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:56:48.868.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:36:06.856.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:20:27.570.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:10:15.122
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:49:39.255
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:25:27.622.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:17:45.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:38:29.550
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T11:42:05.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:47:18.432
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:45:27.709
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:36:59.800.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:38:51.844.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:19:36.989.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T12:10:33.438.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:12:12.051
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:19:56.853
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:27:08.667
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:08:59.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:10:41.698
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:02:57.568.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:38:51.844
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:57:07.798
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T09:59:39.850
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T11:25:20.393.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:35:15.867.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T14:25:15.152
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:02:26.792
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:52:55.523
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:04:56.702
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:17:10.512.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:17:58.100.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:29:12.449.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:57:07.798.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T14:35:15.867
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:10:56.252
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:47:26.537
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:31:56.178
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:25:50.167
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:56:45.453.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:33:42.722
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T11:42:57.229
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:56:57.909
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T13:00:24.344
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T13:02:46.637.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:32:51.994.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:28:39.723.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T12:39:26.040
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:41:13.411
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:02:25.160.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:36:06.856
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T12:50:34.977
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:32:37.699
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:29:13.793.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:04:36.897
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T11:04:03.170
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:16:19.191
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:07:17.541
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:30:18.573.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T11:23:51.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:39:51.561
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:04:08.590
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T11:27:01.556.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T12:25:23.428.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:07:32.236
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T20:02:25.160
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:49:54.851
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T14:50:25.057
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:14:40.333.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:39:34.803
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:13:01.174.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:02:26.792.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:25:27.622
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T12:18:53.726.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:59:53.668
__EOF__