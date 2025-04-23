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
https://archive.eso.org/downloadportalapi/readme/78a1475a-511f-4c1b-af6a-fb8f35237ecb
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:29:13.793
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:53:30.081.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:15:53.921
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:16:19.191.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:56:09.985.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:02:28.347.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:05:50.298.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:21:23.667
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:53:57.591
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:13:01.174
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:09:36.360
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:45:27.709.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:02:28.347
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:19:36.989
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:49:06.485
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:42:09.542
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:30:55.771
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:06:15.955.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:05:08.290
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:56:28.385.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:00:44.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:54:44.875
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:00:37.600.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:00:37.600
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:22:26.682.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:25:23.406
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:49:06.485.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:59:11.732
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:42:52.639
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:56:04.711
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:42:09.542.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:21:53.003.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:59:11.732.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T09:59:39.850.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:57:51.875
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:14:40.333
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:18:33.615
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:59:02.666
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:08:42.455
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:57:21.048.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:04:42.694
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:17:58.100
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:03:53.236
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:23:12.861
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:01:57.557.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:41:13.411.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:36:17.218.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:56:32.098
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:09:36.360.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:03:53.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:08:59.639
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:05:36.771.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:25:50.167.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:02:57.568
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:30:55.771.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:22:26.682
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:37:56.136.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:54:44.875.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:04:36.897.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:25:52.815
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:57:30.152.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:27:32.005.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:42:52.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:17:20.507
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:24:32.978.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:40:30.814
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:04:08.590.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:04:37.442.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:21:53.003
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:57:47.478.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:05:08.290.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:43:48.640.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:32:37.699.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:21:13.680.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:06:02.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:05:35.274.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:18:33.615.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:19:53.323.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:07:32.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:03:48.113.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:24:08.459.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:52:28.009
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:24:03.669.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:56:27.721
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:53:47.667.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:55:12.481.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:24:08.459
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:56:09.985
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:50:26.532
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:52:28.009.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:05:57.308.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:54:49.688.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:53:57.591.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:05:35.274
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:37:56.136
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:53:52.624
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:07:48.251
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:10:41.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:27:32.005
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:20:44.403.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:07:48.251.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:17:13.728.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:59:02.666.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:24:32.978
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:43:48.640
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:03:22.537.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:00:44.624
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:20:44.403
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:20:03.890
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:04:16.915
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:55:39.339
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:01:18.528.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:53:48.461
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:08:16.354
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:21:23.667.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:53:52.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:05:50.298
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:52:15.493.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:51:08.796.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:04:42.694.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:01:18.528
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:06:56.488.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:56:27.721.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:27:12.672
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:57:47.478
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:55:08.438
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:52:15.493
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:19:02.425
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:51:08.796
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:58:50.000
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:55:39.339.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:22:43.584.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:50:45.136.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:56:28.385
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:57:21.048
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:39:34.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:05:57.308
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:50:26.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:17:20.507.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:06:15.955
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:58:50.000.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:20:03.890.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:07:17.541.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:36:17.218
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:56:04.711.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:53:24.879
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:19:02.425.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:03:22.537
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:53:06.366
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:53:48.461.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:40:30.814.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:08:42.455.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:54:26.414.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:51:46.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:24:03.669
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:03:17.435.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:04:37.442
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:50:45.136
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:08:16.354.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:53:06.366.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:54:49.688
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:05:36.771
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:45:27.709
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:15:53.921.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:38:51.844.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:19:36.989.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:53:47.667
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:52:05.052
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:55:07.773.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:55:12.481
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:06:28.176.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:08:59.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:21:13.680
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:19:53.323
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:10:41.698
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:02:57.568.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T11:38:51.844
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T09:59:39.850
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:52:05.052.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:02:26.792
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:53:30.081
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:17:58.100.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:55:08.438.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:01:57.557
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:06:28.176
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:22:43.584
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T09:57:30.152
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:25:50.167
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:07:22.589.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T10:55:07.773
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:51:46.619
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:57:51.875.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:06:02.532
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:41:13.411
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:06:56.488
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:07:22.589
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:03:48.113
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:32:37.699
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T19:29:13.793.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T10:53:24.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-24T10:04:36.897
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:16:19.191
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:17:13.728
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:07:17.541
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:25:52.815.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T09:54:26.414
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:04:08.590
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:52:28.743.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:25:23.406.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:27:12.672.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:04:16.915.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:23:12.861.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:07:32.236
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:14:40.333.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T10:52:28.743
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-05T10:39:34.803
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:13:01.174.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T19:02:26.792.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:03:17.435
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T09:56:32.098.NL
__EOF__