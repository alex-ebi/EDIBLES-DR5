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
https://archive.eso.org/downloadportalapi/readme/fdd9a8eb-7e90-45f8-a47d-ee0733a9b4a4
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:01:37.974
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:56:45.213.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:21:08.249.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:27:51.023.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:58:09.874
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:09:48.419.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:45:25.966.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:19:08.992
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:47:41.565
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:39:53.289.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:39:45.516.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:13:34.916
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:30:37.890
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:26:56.882.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:53:21.170
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:33:29.040
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:39:46.032.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:32:19.998
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:34:13.794.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:30:33.990
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:36:13.765.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:36:13.765
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:26:56.882
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:26:40.172.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:19:08.992.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T10:09:21.679.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:12:58.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:29:57.799
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T09:11:01.540
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:48:02.245.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T13:05:49.585.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T09:11:01.540.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:39:09.045
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:47:41.565.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:01:37.974.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T12:10:20.406.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:10:51.707.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:00:36.870.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:48:49.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:42:56.680
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:48:22.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:48:02.245
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:49:46.294
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:59:27.198.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:36:17.425
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:37:16.715
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:21:14.480.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:28:26.011.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:37:16.715.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:14:47.259.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:43:56.619.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:04:08.213
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:36:12.815.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T15:09:29.244
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T13:00:09.499
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:53:47.143
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:56:52.534.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:44:06.679.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:41:57.332
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T15:09:29.244.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:31:37.029.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:18:38.580
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:35:37.633.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:24:34.879
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T12:04:40.630
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:52:22.452
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:56:52.534
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:04:08.213.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:32:36.838.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:45:25.966
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:26:54.297.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:47:36.807.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:43:53.364.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:09:48.419
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:27:24.284
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:59:41.819
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:38:13.758
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:36:42.866.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:18:37.349.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:45:25.341
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:30:33.990.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:07:35.181.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:36:08.815.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:14:47.259
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:21:00.116
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:07:18.179
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:10:51.707
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:39:09.045.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:25:56.973.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:52:29.959
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:35:37.633
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:47:36.807
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:18:38.580.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:15:28.094
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:53:16.393
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:53:16.393.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:34:06.086.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:17:36.234.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:50:03.274
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:43:10.753.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:47:37.247
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:42:22.531.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:36:17.425.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T12:04:40.630.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:24:54.115
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:18:55.023.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:32:19.998.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:32:36.838
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:18:55.023
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:48:50.908.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:52:22.452.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:13:34.916.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:22:11.467.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:12:58.555
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:39:45.516
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:47:37.247.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:23:15.929.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:24:34.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:46:42.636
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T15:03:49.509.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:22:08.770.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T09:55:58.238.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:59:21.845.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:21:14.480
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:37:30.829.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:54:30.943
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:27:24.284.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:51:05.127
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:46:50.404.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:26:07.032
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:55:26.100
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:19:14.480.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:59:00.975.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:43:10.753
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:31:51.063
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T14:05:06.703.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T14:10:46.488
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:37:30.829
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:11:56.389
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:15:20.220
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:16:29.035.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:41:56.951.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:59:41.819.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:59:27.198
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:45:33.233
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:33:04.129.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:36:08.815
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:00:36.870
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:07:18.179.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:27:48.925.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:31:37.029
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T11:06:45.840
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:24:54.115.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:36:17.266.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:12:57.664
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:54:02.034.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:43:53.364
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:29:57.799.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:53:42.220
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:05:11.531
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:16:31.562.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:31:46.987.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:46:50.404
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:53:21.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:30:28.681
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:11:56.389.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:13:29.498.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T09:05:21.545
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:25:56.973
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:48:50.908
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:30:33.179
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T10:09:21.679
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:52:29.959.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:28:26.011
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:48:07.179
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:55:26.100.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:38:13.758.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:20:27.197.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T12:10:20.406
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:16:31.562
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:34:06.086
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:09:07.575.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:34:05.560.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:23:15.929
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:39:46.032
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:44:23.478
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T11:01:05.875.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:33:04.129
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:56:45.213
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:45:33.233.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:27:48.925
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:32:33.902
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:41:57.332.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:54:29.343.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T09:55:58.238
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:36:12.815
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:05:11.531.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:24:57.984
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T14:05:06.703
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:48:07.179.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:50:03.274.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:26:40.172
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:31:46.987
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:53:12.110.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:24:18.195.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:21:08.249
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:09:40.575
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:51:12.868.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:42:22.531
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:30:33.179.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:53:42.220.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:27:51.023
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:01:55.365.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:18:37.349
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:16:29.035
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:26:07.032.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:41:52.599.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:54:29.343
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T10:03:41.914
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:06:16.334
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:09:40.575.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:54:30.943.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:24:48.857.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T15:03:49.509
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-04T11:59:00.975
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:07:35.181
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:26:54.297
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:53:12.110
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:43:09.602
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:17:36.234
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:20:27.197
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:48:22.148
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:30:37.560.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:47:32.345.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-06T12:32:33.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:21:17.297
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:45:25.341.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:36:17.266
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:51:05.962
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:38:43.814.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T08:54:02.034
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-25T10:12:57.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:43:09.602.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T13:53:47.143.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:21:00.116.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:36:42.866
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:34:13.794
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-25T10:06:16.334.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:30:28.681.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-03T12:09:07.575
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:22:08.770
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:13:29.498
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T11:01:05.875
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-03T14:10:46.488.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:41:56.951
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:20:17.028
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-08T12:30:37.560
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:26:48.204.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T10:03:41.914.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T12:48:49.458
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:38:16.533
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:58:02.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:47:32.345
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:34:05.560
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:30:37.890.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-13T09:05:21.545.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:38:16.533.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:01:55.365
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:39:53.289
https://dataportal.eso.org/dataportal_new/file/UVES.2019-02-03T13:51:05.127.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:49:46.294.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:46:42.636.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:43:56.619
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:20:17.028.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-02T16:24:18.195
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-22T14:31:51.063.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:44:23.478.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:15:28.094.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-16T14:58:09.874.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-12T09:15:20.220.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-28T12:26:48.204
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T13:00:09.499.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-04-20T13:05:49.585
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:13:15.057.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-06T11:51:05.962.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-19T11:38:43.814
https://dataportal.eso.org/dataportal_new/file/UVES.2019-01-03T10:24:57.984.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T10:44:06.679
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-26T11:41:52.599
https://dataportal.eso.org/dataportal_new/file/UVES.2019-03-25T12:22:11.467
https://dataportal.eso.org/dataportal_new/file/UVES.2019-12-12T09:58:02.148
https://dataportal.eso.org/dataportal_new/file/UVES.2019-08-14T13:13:15.057
https://dataportal.eso.org/dataportal_new/file/UVES.2019-07-14T12:19:14.480
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-16T11:59:21.845
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-17T10:33:29.040.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-06-29T11:51:12.868
https://dataportal.eso.org/dataportal_new/file/UVES.2019-10-09T11:21:17.297.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:42:56.680.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2019-05-11T11:24:48.857
https://dataportal.eso.org/dataportal_new/file/UVES.2019-11-03T11:06:45.840.NL
__EOF__
