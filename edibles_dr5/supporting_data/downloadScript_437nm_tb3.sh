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
https://archive.eso.org/downloadportalapi/readme/77c57f3c-f74d-4c04-b980-e2b87b34828a
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:14:03.007.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:14:33.789.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:49:43.914.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:10:31.369.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:36:51.893.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:18:20.633.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:32:07.857.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:51:59.930
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:52:54.631
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:35:18.974.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:20:30.765.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:50:44.231.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:48:27.303.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:38:29.862
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:04:41.634
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:25:02.360.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:34:17.565
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:01:30.397
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:12:32.430
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:34:56.564
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:20:00.744
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:01:30.397.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:27:53.748
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T09:57:17.611.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:36:29.664
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:01:28.165
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:06:28.651.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:31:48.025.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:47:21.640.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:56:55.663
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:30:38.483.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:19:43.609.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:25:39.827.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:55:41.772
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:06:19.940
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:24:24.045
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:56:05.479
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:50:02.841.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:25:49.128
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:22:27.174.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:46:02.724.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:25:51.961.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:47:03.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:26:38.340.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:20:24.941
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:18:33.443.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:32:54.813
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:16:36.683
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T11:02:14.793.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:20:21.924
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:47:39.196.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:20:30.094.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:52:29.299.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:47:39.196
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:28:46.265
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:25:20.322.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:28:14.151.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:21:31.798
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:47:35.237.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:49:00.199
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:39:07.258.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:37:21.461
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:23:05.449
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:41:00.677.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:35:35.443.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:21:08.399.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:41:31.949
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:03:54.958
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:20:30.094
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:47:21.640
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:21:31.798.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:29:23.990
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:30:38.483
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:24:42.593
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:33:27.863.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:20:30.765
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:34:50.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:14:03.007
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:26:58.848
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:11:56.169.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:43:37.810.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:56:01.846
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:24:15.594.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:50:44.231
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:49:18.599
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:28:56.980
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:22:08.772
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:45:14.424.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:25:02.360
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:04:41.634.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:25:03.198.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T11:02:14.793
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:11:30.193.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:50:52.529.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:33:44.846.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:44:25.942.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:19:43.609
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:53:17.079
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:33:38.304
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:33:27.863
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:06:19.940.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:33:52.608
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:07:06.476
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:34:32.635
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:20:24.941.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:21:08.399
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:47:03.479
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:29:03.283.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:18:24.993
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:22:18.794.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:07:40.813
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:41:40.638.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:32:49.333.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:14:53.509
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:25:39.827
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:56:01.846.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:43:09.547
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:27:53.974.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:24:13.397
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:22:30.721
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:26:59.151.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:10:52.039.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:50:57.110
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:20:44.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:36:58.245
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:55:00.028
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:14:53.509.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:48:27.303
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:24:42.593.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:21:57.923.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:25:48.559
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:20:44.458
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:51:05.221.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:18:16.806
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:49:18.599.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:33:44.846
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:52:29.299
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:55:09.236.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:41:40.638
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:45:06.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:34:17.565.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:20:00.744.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:38:29.862.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:23:54.832.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T10:50:40.299.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:30:47.664
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:57:24.800
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:43:21.839
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:41:16.647.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:38:07.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:09:31.258.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:32:35.563.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:34:56.564.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:24:13.397.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:46:02.740.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:57:24.800.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:27:45.380
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:32:54.813.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:43:21.839.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:02:07.224
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:15:09.679.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:51:59.930.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:31:52.844.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:23:05.449.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:29:44.265.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:10:52.039
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:17:13.994
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:54:58.922
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:29:44.265
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:32:35.563
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:53:56.910.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:54:58.922.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:21:40.171
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:52:54.631.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:15:09.679
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:22:55.589.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:12:32.430.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:41:31.949.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:13:02.227.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:35:24.852
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:51:05.221
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:48:27.617.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:30:10.068
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:16:36.683.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:24:33.905.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:23:24.024
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:50:52.529
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:23:54.832
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:55:37.274.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:24:38.439
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:59:31.075
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:59:49.542
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T09:59:42.433
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:57:50.498.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:02:07.224.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:59:31.075.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:46:32.887.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:37:32.513.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:26:35.169.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:47:35.237
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T09:57:17.611
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:30:10.068.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:19:57.598
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:55:53.569.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:28:46.265.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:04:07.810
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:25:20.322
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:52:34.967.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:57:50.498
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:31:31.114
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:46:02.724
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:34:32.635.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:55:41.772.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:22:08.772.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:54:54.200
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:21:54.438
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:38:59.486
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:55:37.274
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:19:21.556
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:50:52.116.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:31:48.025
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:07:40.813.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:53:40.583.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:10:31.369
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:20:58.872
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:36:51.893
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:24:15.594
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:13:02.227
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:35:24.852.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:06:57.038.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:39:07.258
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T09:59:42.433.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:23:24.024.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:59:49.542.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:35:42.046.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:06:28.651
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:28:14.151
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:25:51.961
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:18:20.633
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:24:38.439.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:56:55.663.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:38:26.715
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:00:04.708
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:18:03.905
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:50:04.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:59:05.686.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:30:39.054
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:11:30.193
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:58:03.257
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:20:21.924.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:44:25.942
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:53:02.022
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:49:43.914
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:50:04.148
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:53:40.583
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:22:41.498
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:33:38.304.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-10T11:27:53.748.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:03:54.958.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:29:23.990.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:46:32.887
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:21:57.923
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T11:59:05.686
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:38:59.486.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:18:24.993.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:38:07.532
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:23:51.609.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:55:00.028.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:56:05.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:07:06.476.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:53:02.022.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:29:03.283
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:02:16.483.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:43:09.547.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:29:51.185
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:22:27.174
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:31:28.055
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:32:49.333
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-22T10:17:13.994.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:35:18.974
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:11:56.169
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T10:50:40.299
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:35:42.046
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:18:16.806.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:38:26.715.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:28:32.340.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:02:16.483
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:27:45.375
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:54:54.200.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:22:30.721.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:31:52.844
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:25:03.198
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:45:06.698
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:02:06.419
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:06:57.038
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:51:15.618.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:37:21.461.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:49:08.131.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:35:35.443
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:53:12.468
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:30:39.054.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:19:57.598.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:23:51.609
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:02:06.419.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:53:56.910
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:33:52.608.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:08:44.881
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:04:07.810.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T18:41:16.647
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:57:34.084
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:31:41.175.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:50:02.841
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:26:59.151
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:31:28.055.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:57:34.084.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:08:44.881.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:27:45.375.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:48:27.617
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:04:32.016.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:16:11.552.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:08:29.971
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T18:45:14.424
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:55:53.569
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:34:50.803
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:25:48.559.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:46:02.740
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:18:33.443
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:50:52.116
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-24T10:04:32.016
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:36:58.245.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-18T11:09:31.258
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-13T08:53:17.079.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-11T10:24:24.045.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:16:11.552
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:43:37.810
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:32:07.857
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:25:49.128.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:27:53.974
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:36:42.216
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T10:53:05.561.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:21:54.438.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:28:32.340
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:26:35.169
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-31T10:26:38.340
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:14:33.789
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:30:47.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-25T11:36:29.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:28:55.881
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T12:01:28.165.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:51:15.618
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-12T10:28:56.980.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T11:36:42.216.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-01T11:22:18.794
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T10:28:55.881.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-09T10:53:05.561
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-08T11:31:31.114.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-14T10:22:41.498.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-17T11:08:29.971.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:22:55.589
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-18T11:27:45.380.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:53:17.212
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:53:17.212.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-10T10:20:58.872.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-11-30T10:29:51.185.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:53:12.468.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:24:33.905
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T13:00:04.708.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:50:57.110.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-29T11:55:09.236
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-26T15:41:00.677
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T18:19:21.556.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-01-04T10:49:00.199.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-01T10:26:58.848.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-22T11:18:03.905.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:37:32.513
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-21T12:58:03.257.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-12-28T10:49:08.131
https://dataportal.eso.org/dataportal_new/file/UVES.2016-03-02T10:52:34.967
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-21T12:21:40.171.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2016-02-15T11:31:41.175
__EOF__