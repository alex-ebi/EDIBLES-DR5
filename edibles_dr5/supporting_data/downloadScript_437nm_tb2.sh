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
https://archive.eso.org/downloadportalapi/readme/15910e4e-ed72-4498-9db7-4e88879368f5
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:14:15.240.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:32:40.612
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:36:35.510.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:18:57.848
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:25:44.649.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:00:55.499
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:01:02.141.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:31:44.077
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:57:53.169
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:10:43.008
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:51:06.615
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:59:14.743.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:33:25.038
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:36:31.303
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:43:44.604.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:36:00.128
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:12:20.458.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:31:03.438.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:14:06.205.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:20:29.211.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:15:43.694.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:21:01.911
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:00:32.639
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:07:49.099
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T12:04:39.825
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:57:08.730
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:52:28.472
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:45:26.680.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:54:31.035.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:39:54.961.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:20:29.211
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:14:06.205
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:40:40.623
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:26:24.586
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:14:16.178
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:42:47.093
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:31:03.438
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:43:20.803
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T11:58:30.204.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:51:06.615.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:11:28.278.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:05:02.888
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:27:40.071
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T11:58:30.204
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:19:07.129.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:00:32.076.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:36:00.128.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:57:18.398
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:33:25.038.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:08:04.751
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:29:17.076
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:10:51.993
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:10:51.993.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:07:49.099.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:12:11.256.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:46:43.948
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:20:53.238.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:14:16.178.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:50:05.255.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:17:29.812.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:03:55.945
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:04:05.042
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:39:23.825.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:01:32.446.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:55:51.597
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-11T16:29:49.162.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T11:55:06.789.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:43:18.209
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:08:26.105.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:24:25.336
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:21:33.944
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:19:12.683
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:27:16.104.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:00:41.855.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:39:57.238
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:36:33.902
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:04:05.042.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:45:29.949.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:39:59.348.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:01:53.310
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:31:38.533.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:47:26.951
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:50:05.255
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:39:57.238.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-11T16:29:49.162
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:50:50.299
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:47:26.951.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:49:34.268
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:43:35.446.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:14:15.240
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:34:35.674
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:34:35.674.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:53:45.564
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:08:57.152.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:36:48.455
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T12:57:32.143.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:38:43.747
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:22:30.615
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:59:00.284
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:24:57.402
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:04:41.043.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:53:54.923.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:45:41.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:54:30.022
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:49:05.015
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:24:16.715.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:07:42.401.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:05:38.928
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:04:19.175
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:15:34.832.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:28:15.137
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:01:39.482.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:11:49.531.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:05:33.647.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:28:20.569
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:57:53.169.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:46:58.772.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:11:28.278
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:40:11.851
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:52:13.732.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:15:34.832
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:12:11.256
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:55:36.958.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:29:48.494.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:31:38.533
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:42:47.093.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:33:10.427
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T12:04:39.825.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:43:35.446
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:53:54.923
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:11:05.313
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:46:43.948.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:19:12.683.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:46:10.610.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:31:57.104
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:46:41.947.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:15:49.408
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:04:43.272
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:31:57.104.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:27:16.104
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T14:01:18.132
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:07:19.342
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:49:34.268.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:36:31.303.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:04:25.510
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:51:07.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:17:29.812
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:41:48.629
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:34:02.957.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:25:44.649
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:26:24.586.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:21:01.911.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:27:40.071.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:11:12.337.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T11:55:06.789
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:04:25.510.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:47:44.079.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:11:49.531
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:33:12.071
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:25:53.700.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:01:17.536
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:31:12.248.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:47:44.079
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:54:31.035
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:29:48.494
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:28:20.569.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:43:20.803.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:48:50.036
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:18:10.736.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:02:10.281
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T14:57:38.734
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:23:52.758
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T11:54:30.022.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:52:13.732
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:18:57.848.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:52:28.472.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:07:28.497
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:35:01.658
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:01:17.536.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:01:02.141
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:24:16.715
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:57:54.554
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:30:01.902
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:03:55.945.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:21:33.944.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:07:28.497.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:50:50.299.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:44:03.972.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:24:25.336.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T12:01:16.427.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:28:15.137.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:15:43.694
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T12:54:08.838.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:50:22.069.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:45:41.729
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:40:11.851.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:57:54.554.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:04:41.043
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T14:01:18.132.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:04:19.175.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:24:57.402.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:31:44.077.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:38:43.747.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:45:26.680
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T12:57:32.143
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:44:03.972
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:05:33.647
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T14:57:38.734.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:35:20.301
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:46:41.947
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:01:53.310.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:07:54.407.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:55:51.597.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:36:48.455.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-24T12:18:10.736
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:32:40.612.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:47:08.090
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:08:57.152
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:47:08.090.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:04:43.272.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:49:05.015.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:07:42.401
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T12:57:54.298
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:02:10.281.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:54:13.596
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T12:57:54.298.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:46:58.772
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:12:26.011
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:41:48.629.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:57:08.730.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:33:10.427.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:35:01.658.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:15:49.408.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:20:53.238
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:00:32.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:50:22.069
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:46:10.610
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:30:39.541.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:29:17.076.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T13:00:55.499.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:07:54.407
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:27:48.743.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:08:26.105
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:05:16.736
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:09:02.624.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:34:02.957
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T21:00:41.855
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:39:54.961
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-16T11:43:18.209.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:23:52.758.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:27:48.743
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:38:25.234.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:22:30.615.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-02T15:11:12.337
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:12:26.011.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:33:12.071.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:55:36.958
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:08:40.163.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:45:29.949
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:48:50.036.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-30T12:01:16.427
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-13T13:51:07.607
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:50:31.606
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:05:02.888.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-15T13:08:04.751.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T11:36:33.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T12:54:08.838
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T19:00:32.076
https://dataportal.eso.org/dataportal_new/file/UVES.2015-08-21T13:59:14.743
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:09:02.624
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:11:05.313.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:12:20.458
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:40:40.623.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T16:01:39.482
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:22:21.454.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:57:18.398.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:39:59.348
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-13T12:38:25.234
https://dataportal.eso.org/dataportal_new/file/UVES.2015-04-30T11:54:13.596.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:25:53.700
https://dataportal.eso.org/dataportal_new/file/UVES.2015-05-18T12:36:35.510
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:42:06.802
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:35:20.301.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:05:16.736.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-30T11:42:06.802.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:07:19.342.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:53:45.564.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-17T12:31:12.248
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T20:10:43.008.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T13:30:39.541
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-07T18:19:07.129
https://dataportal.eso.org/dataportal_new/file/UVES.2015-09-12T11:22:21.454
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-01T11:59:00.284.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-25T14:01:32.446
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:43:44.604
https://dataportal.eso.org/dataportal_new/file/UVES.2015-07-20T18:30:01.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-26T13:05:38.928.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-28T20:50:31.606.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-19T12:08:40.163
https://dataportal.eso.org/dataportal_new/file/UVES.2015-06-12T12:39:23.825
__EOF__
