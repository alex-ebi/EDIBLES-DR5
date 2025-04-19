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
https://archive.eso.org/downloadportalapi/readme/7f697389-8e99-4663-920b-b01eb9f6409a
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:25:03.873.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:09:08.561.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:28:43.722.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:02:02.222.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T12:58:17.336.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:51:05.661
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:36:50.555
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:56:33.190
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:52:16.018
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:47:48.975
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:58:34.543.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:02:02.222
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:00:07.306
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:52:29.802.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:41:37.339.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:30:47.989.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:57:32.526
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:32:47.023
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:49:16.802.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:50:40.792
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:01:01.508
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:44:56.098.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:34:48.054
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:47:16.013.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:56:47.322.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:49:03.361.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:42:10.064.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:30:45.543
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:31:29.997
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:30:00.389.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:56:59.487.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:10:39.698
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:52:40.711.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:49:45.994
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:23:25.885.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:03:47.335.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:29:48.536
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:56:32.800
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:34:48.054.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:29:28.936.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:56:45.204.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:32:23.721
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:49:38.424
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:56:59.487
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:06:52.944
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:06:05.573
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:35:30.256.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:19:17.943.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:54:56.135.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:52:44.920.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:01:57.336
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:45:48.392.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:27:27.966.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:23:25.235
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:52:55.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:42:53.897.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:47:16.013
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:53:18.432.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:47:37.012
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:52:16.018.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:51:33.204.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:27:27.966
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:08:07.193
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:28:18.367
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:31:49.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:23:25.235.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:26:10.637.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:14:17.706.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:59:58.208.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:37:20.235.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:28:11.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:10:39.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:35:33.908.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:52:04.898.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:43:59.473.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:56:19.700.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:00:49.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:11:09.622
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:24:21.517.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:26:53.723.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:50:43.789
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:25:27.346
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T03:55:58.130.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:38:51.916.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:39:35.948
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:54:58.707.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:32:23.721.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:08:54.035.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:55:08.411
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T03:57:59.560.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:14:12.226
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T12:00:23.353.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:53:54.517.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:33:17.283.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:55:43.526
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:42:10.064
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:54:19.151.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:31:49.607
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:21:21.663
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:08:07.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:26:53.723
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:25:48.634
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:52:40.711
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:39:35.948.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:02:50.933
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:52:29.802
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:47:48.975.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:56:45.204
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:14:17.706
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:24:33.331.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:00:00.552
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:54:29.740.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T03:57:59.560
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:28:11.479
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:01:57.336.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T12:02:12.193
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:30:00.389
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:49:38.424.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:56:19.700
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:13:10.612
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:58:08.738
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:55:08.411.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:51:05.661.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:52:44.920
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:38:51.916
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:41:37.339
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:30:33.722.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T12:56:27.607
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:59:22.005
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:30:47.989
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:25:27.346.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:12:28.897.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:57:32.526.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:57:16.023
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:49:45.994.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:17:14.022
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:33:41.197.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:07:06.700.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:07:01.879
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:08:50.738
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:52:55.170
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:25:03.873
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:12:28.897
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:00:49.902
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:26:22.229
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:57:16.023.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:31:51.887.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:31:29.997.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:54:19.151
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:56:32.800.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:39:09.465.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:09:08.561
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:44:56.098
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:31:51.887
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:54:58.707
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:28:44.132
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:58:34.543
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:50:40.792.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:03:47.335
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:29:28.936
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:51:28.413.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:35:47.265
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T12:58:17.336
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:03:02.498.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:25:28.606
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:11:09.622.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:33:31.937
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:24:21.517
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:57:57.029
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:30:33.722
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:35:30.256
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:07:06.700
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:35:33.908
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:24:33.331
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-02T15:28:43.722
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:33:31.937.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:27:59.816
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:05:05.020
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:06:05.573.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:52:04.898
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:54:45.931.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:54:03.198
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:31:37.545.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:54:43.860
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:29:48.536.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:58:48.931.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:00:00.552.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T15:26:22.229.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:13:10.612.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T13:00:07.306.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:53:54.517
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:46:57.007.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:56:08.151.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:35:47.265.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:21:21.663.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:45:48.392
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:54:46.000
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:59:00.597
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:55:43.526.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:51:28.413
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T03:55:58.130
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:27:59.816.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:10:08.854.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:04:04.082.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:56:47.322
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:37:20.235
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:30:45.543.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:39:09.465
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-09T12:59:22.005.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:54:43.860.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T13:49:16.802
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:12:10.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:10:08.854
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:54:45.931
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:14:12.226.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:54:03.198.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:49:25.952
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:59:58.208
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:58:48.931
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:36:50.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T19:50:43.789.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:26:10.637
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:08:50.738.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:12:10.555
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:17:14.022.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T12:00:23.353
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:54:29.740
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:46:57.007
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:51:33.204
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-06T11:31:37.545
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:57:57.029.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:32:47.023.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:28:44.132.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T05:59:00.597.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-15T14:56:08.151
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:08:54.035
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:59:03.193
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:25:48.634.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:23:25.885
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-21T13:58:08.738.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-04T12:33:41.197
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T12:56:27.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T10:53:18.432
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:47:37.012.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T11:54:56.135
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:40:52.916
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:25:28.606.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:59:03.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:28:18.367.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:04:51.933
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:42:53.897
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:49:25.952.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-05T16:40:52.916.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-30T12:02:12.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:54:46.000.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-09T11:19:17.943
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:56:33.190.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:05:05.020.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:03:02.498
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:04:51.933.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T15:49:03.361
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:06:52.944.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T20:02:50.933.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:37:34.928
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-01T04:04:04.082
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-18T11:43:59.473
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-18T14:07:01.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-04T00:37:34.928.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T11:33:17.283
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-02T06:01:01.508.NL
__EOF__