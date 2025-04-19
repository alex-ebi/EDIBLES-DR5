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
https://archive.eso.org/downloadportalapi/readme/f09fe9ec-dd4a-4e26-987c-eb8a045df194
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:52:42.283
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:12:50.828.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:08:23.213.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:48:39.801
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T15:03:00.145.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:58:45.480
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:18:33.845.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:27:48.463
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:06:16.743
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:46:49.471.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:08:28.213.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:16:32.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:58:27.527.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:12:06.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:38:21.751
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:36:54.958.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:10:43.827
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:54:44.936
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:08:37.185.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:46:47.158.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:06:27.092
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:16:20.917
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:32:41.147
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:19:45.071
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:25:47.682.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:49:58.747.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:14:13.794.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:02:03.230
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:36:33.697
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:39:01.729
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:34:48.088.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:33:51.095.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:18:36.537
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:40:28.514.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:54:31.215.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:45:58.201.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T15:00:52.552
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:09:59.810
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:52:05.559
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:44:40.155.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:23:48.753
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:14:57.679
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:32:41.147.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T15:00:52.552.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T13:59:56.460.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:17:04.641.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:36:54.958
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:46:17.093
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:30:33.816
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:48:05.323
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T13:59:56.460
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:38:21.751.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:29:49.104
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:17:04.641
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:20:34.706
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:45:58.201
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:09:59.810.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:18:33.845
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:19:45.071.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:04:26.182
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:52:05.559.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:20:34.706.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:40:35.659
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:43:51.471.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:21:46.092
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:43:51.471
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:31:59.563.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:04:09.962.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:56:20.115.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:50:41.393
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:50:30.684.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:28:03.285.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:48:54.599
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:08:03.284.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:04:09.962
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:29:52.170.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:48:05.323.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:51:01.232
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:23:46.922.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:34:07.205
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:54:12.512
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:56:20.115
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:22:50.452.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:24:57.014.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:56:38.458
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:42:36.669.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:10:43.827.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:52:19.194.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:30:09.956
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:22:50.452
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:31:49.724.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:18:36.537.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T15:03:00.145
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:18:27.789.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:44:42.458
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:14:25.532
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:34:32.717
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:04:26.182.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:50:12.573
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:27:44.098.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:54:31.215
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:46:49.471
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:34:48.088
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:52:37.685
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:42:36.669
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:32:17.015.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:33:51.095
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:12:29.944
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:16:20.917.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:31:49.724
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:36:14.598.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:10:28.953.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:29:52.170
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:36:14.598
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:14:25.532.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:30:33.816.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:34:07.205.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:02:03.230.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:31:59.563
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-03T12:39:01.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:42:33.083
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:25:56.474.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:16:29.395.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:10:11.397
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:12:18.559.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:44:37.580
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:14:31.154.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:46:47.158
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:05:55.701
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:30:09.956.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:17:44.440.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:16:32.555
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:48:54.599.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:28:03.285
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:51:01.232.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:16:29.395
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:44:37.580.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:20:43.020
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:40:35.659.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:50:30.684
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:44:42.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:58:27.527
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:21:46.092.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:14:13.794
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:48:23.903.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:32:17.015
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:23:46.922
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:08:23.213
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:12:29.944.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:54:12.512.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:48:39.801.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:42:33.083.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:14:31.154
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T14:06:16.743.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:20:43.020.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:08:03.284
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:14:57.679.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:58:45.480.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:42:35.496
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:12:18.559
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:22:36.146.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:50:12.573.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:36:33.697.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:08:37.185
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:42:35.496.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:25:47.682
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:52:37.685.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:46:38.551.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:05:55.701.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:06:27.092.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:22:36.146
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T15:10:11.397.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T14:49:58.747
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:38:34.668
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:23:48.753.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:35:52.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:27:48.463.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:10:28.953
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:17:44.440
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:48:23.903
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T13:24:57.014
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T12:44:40.155
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:54:44.936.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:56:38.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:08:28.213
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:50:41.393.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T14:12:50.828
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:34:32.717.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T13:46:17.093.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T14:52:19.194
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:46:38.551
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:38:34.668.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:52:42.283.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:35:52.555
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T12:25:56.474
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:12:06.803
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-31T12:18:27.789
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-01T12:27:44.098
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:29:49.104.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T14:40:28.514
__EOF__
