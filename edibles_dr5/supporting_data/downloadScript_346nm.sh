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
https://archive.eso.org/downloadportalapi/readme/8066de6f-e3c3-4efa-8306-4fa9ee86a71d
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:24:19.099
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:26:23.351.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:24:19.099.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:34:17.191.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:29:46.551
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:44:00.017
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:49:28.195
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:15:42.323.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:06:32.227.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:33:47.418.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:49:42.087.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:54:45.702.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:36:43.259
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:52:20.192
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:13:03.082.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:56:03.607.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:55:38.738
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:04:54.659
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:48:14.776.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:53:10.243
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:33:06.292
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:12:21.267.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:18:42.336
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:51:49.517.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:46:50.929
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:33:00.969.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:44:37.318
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:30:47.204.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:48:05.949
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:24:10.323.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:50:06.900.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:11:28.651
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:39:27.315.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:15:25.706.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:55:38.738.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:15:52.338.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:05:22.799.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:44:06.648
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:39:35.688.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:45:58.389
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:03:06.549.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:17:49.695.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:17:49.695
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T12:01:37.766
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:12:25.762
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:04:23.195
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:20:05.529.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:26:44.688
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:59:35.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:53:10.243.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:32:09.961.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:17:16.363.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:10:41.799.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:07:23.623
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:44:06.648.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:36:08.125.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:24:10.323
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:59:35.639
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:05:13.689.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:22:08.818.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:26:16.974.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T12:01:07.200
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:09:08.558
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:30:37.452.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:30:47.204
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:32:09.961
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:26:26.778.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:13:38.112.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:26:33.343.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:15:09.762.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:27:28.623
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:13:18.585
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:43:07.435
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:43:49.468
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:53:42.854
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:34:36.339.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:48:57.680
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:03:15.569.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:42:29.138
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:48:05.949.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:16:39.982.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:48:03.978
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:48:14.776
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:55:50.265.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:47:35.397.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:42:29.828.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:27:11.245
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:30:21.639
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:55:50.265
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:49:28.195.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:48:03.978.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:33:00.969
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:31:53.812.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:59:31.157.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:03:15.569
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:46:07.296.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:37:20.474
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:14:56.439
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:57:23.876
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:57:46.149
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:30:54.090
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:59:00.131
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:24:16.650.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:24:37.637
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:36:23.902
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:50:28.878
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:53:42.854.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:47:55.770.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:47:35.397
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:50:58.968
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:02:16.055.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:46:50.929.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:20:06.057
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:15:20.519.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:22:03.432
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:44:00.017.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:37:20.474.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:20:22.814.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:43:49.468.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:44:37.318.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:32:29.019.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:05:10.673.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:31:40.097.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:14:28.377
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:15:52.338
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:22:30.075
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:41:59.428.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:15:47.087.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:51:04.912
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:54:21.853.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:10:18.832.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:16:39.982
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:19:55.801
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:45:58.389.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:19:34.421.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:11:37.643
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:28:30.521
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:47:59.309
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:55:16.427
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:56:03.607
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:50:21.456.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:17:03.349
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:07:01.708
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:08:11.733.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:13:03.082
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:09:08.558.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:07:21.169
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:22:30.075.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:00:08.875
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:00:08.875.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:23:05.971.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:29:18.026
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:50:58.677.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:04:23.195.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:57:23.876.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:28:34.738.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:54:45.702
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:29:27.134
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:22:08.818
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:17:54.088.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:55:16.427.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:57:20.019
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:48:21.388
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:17:48.921.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:38:53.435.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:21:30.566
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:45:57.048
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:19:34.421
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T12:58:51.698
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:27:28.623.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:15:20.519
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:29:33.057.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:48:21.388.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:23:48.224
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T11:58:01.996.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:45:14.475.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:24:37.637.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:19:39.958
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:17:54.088
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:27:25.898.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:40:22.257.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:56:53.431.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:07:30.189.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:23:14.741.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:26:39.329
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:41:42.568
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:19:23.845.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:57:20.019.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:23:14.741
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:05:16.783
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:17:59.287.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:55:13.048
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:22:57.664.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:17:03.349.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:46:44.558.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:10:41.799
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:22:12.289
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:22:12.289.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:45:57.048.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:48:57.680.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:40:38.014.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:11:31.342
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:11:38.618.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:09:25.714
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:05:22.799
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T11:58:04.564
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:50:13.131
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:51:34.985.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:29:35.214.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:36:43.259.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:43:51.417
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:20:22.814
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:11:31.342.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:36:45.675
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:51:04.912.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:25:32.149
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:02:18.726.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:52:14.041.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:56:28.693
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:38:31.153
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T11:01:39.028
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:03:09.843.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:11:15.917.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T11:01:42.410.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:55:20.547.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:39:35.688
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:10:14.337
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:12:48.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:07:23.623.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:24:32.300
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:09:30.453.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:57:27.948
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:17:27.400.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T12:03:44.836.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:17:59.287
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:33:47.418
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:13:40.166.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:18:42.336.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:56:53.431
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:28:34.738
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:14:32.802
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:51:34.985
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:27:11.245.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:19:23.845
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:30:21.639.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:52:20.192.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T12:01:37.766.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:01:08.000.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:35:54.048.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:35:54.048
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:05:16.783.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:25:21.582
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:22:18.530
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:41:33.946.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:13:45.617.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:41:59.428
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:11:11.834.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:53:31.857
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:47:21.355.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:25:12.762
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:59:27.000.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:24:26.082
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:45:48.009.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:13:40.166
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T13:02:00.120
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:33:06.292.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:46:13.849.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:13:22.896
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:42:29.138.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:05:13.689
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:53:56.447
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:46:44.558
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:56:28.693.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:31:40.097
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:40:22.257
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:43:41.087
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:38:53.435
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:28:52.459
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:45:14.475
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:11:37.643.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:09:25.714.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:31:53.812
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:53:12.593.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:03:09.843
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:15:25.706
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:12:25.762.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:19:39.958.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:08:33.918.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:13:18.585.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:50:03.511.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:19:55.801.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:12:48.729
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:49:42.087
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:43:41.087.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:21:41.372.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:28:46.769
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:59:27.000
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:57:46.149.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:15:09.762
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:53:31.857.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:28:46.769.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:26:39.329.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:55:17.324
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:17:32.696
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:52:38.182.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:34:01.093
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:55:17.324.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:26:44.688.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:54:21.853
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:30:59.480
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:43:51.417.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:13:35.502
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:26:16.974
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:50:28.878.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:29:27.134.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:41:00.345
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-25T12:50:13.131.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:52:28.575
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:46:07.296
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:31:25.176
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:27:25.898
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:53:05.957.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:16:35.086
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:17:27.400
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:28:40.454
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:38:14.766
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:29:35.214
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T13:02:00.120.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T11:01:39.028.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:08:11.733
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:09:21.260
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:59:00.131.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:00:11.286.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:14:28.377.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:53:05.957
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:39:27.315
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T12:58:51.698.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-29T15:46:13.849
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:25:12.762.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:24:16.650
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:29:46.551.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:44:35.879
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:04:25.486
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:05:10.673
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-07T10:41:42.568.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:31:42.424.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T12:03:44.836
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:38:31.153.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:27:20.083
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:26:23.351
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:22:57.664
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-20T12:09:30.453
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:38:14.766.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-02T11:29:33.057
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:28:30.521.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:15:42.323
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:11:11.834
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:28:52.459.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:31:25.176.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:23:05.971
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:03:06.549
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:51:49.517
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:04:54.659.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:41:00.345.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:11:38.618
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:32:29.019
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T11:55:55.105
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:53:12.593
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:45:48.009
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:34:17.191
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:17:16.363
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:09:37.729
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:25:04.414
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:43:07.435.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:09:37.729.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:07:30.189
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:13:35.502.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:52:14.041
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:00:11.286
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:44:43.487.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T11:52:38.182
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:55:13.048.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:41:33.946
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:57:24.045
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:20:58.709.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:11:32.555
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:09:24.643
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:07:01.708.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:34:36.339
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:57:27.948.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:26:33.343
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:20:05.529
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:23:48.224.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-11T11:17:32.696.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:04:25.486.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T11:58:01.996
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:50:03.511
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:14:56.439.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:10:18.832
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:42:29.828
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T11:53:56.447.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T11:55:55.105.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:38:50.148
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:11:32.555.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-05-07T10:01:08.000
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:09:21.260.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:27:20.083.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:30:54.090.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:59:30.826
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:00:59.479.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T11:20:58.709
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:36:23.902.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-19T12:15:47.087
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:16:35.086.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:59:53.290
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T11:03:49.041
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:47:21.355
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:30:59.480.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:12:21.267
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:09:24.643.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:27:39.220.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-09T12:01:07.200.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-16T12:59:53.290.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:07:17.593
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:25:04.414.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:07:17.593.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:59:31.157
https://dataportal.eso.org/dataportal_new/file/UVES.2017-09-22T12:38:50.148.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-26T11:13:38.112
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:13:45.617
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:07:21.169.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-15T10:57:24.045.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-08-15T11:26:26.778
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:25:32.149.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T19:21:30.566.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:24:26.082.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-02T11:11:28.651.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:48:51.878.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T11:58:04.564.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:47:59.309.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-30T09:14:32.802.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:47:55.770
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:06:32.227
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T11:01:42.410
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:36:08.125
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T11:03:49.041.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-10-01T11:10:14.337.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-01T17:36:45.675.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:11:15.917
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-17T11:24:32.300.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:50:21.456
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:35:13.363.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:48:51.878
https://dataportal.eso.org/dataportal_new/file/UVES.2017-01-02T10:50:58.968.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-23T12:02:18.726
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:44:35.879.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-26T11:20:06.057.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:27:39.220
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:22:18.530.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-07T17:34:01.093.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-20T09:52:28.575.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-02-12T10:55:20.547
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:31:42.424
https://dataportal.eso.org/dataportal_new/file/UVES.2018-03-17T11:21:41.372
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:17:48.921
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-31T11:25:21.582.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-10-06T09:30:37.452
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-30T10:22:03.432.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-06-15T12:02:16.055
https://dataportal.eso.org/dataportal_new/file/UVES.2018-12-19T12:13:22.896.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-01-24T09:44:43.487
https://dataportal.eso.org/dataportal_new/file/UVES.2017-12-18T13:50:06.900
https://dataportal.eso.org/dataportal_new/file/UVES.2018-08-09T11:28:40.454.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-01T05:50:58.677
https://dataportal.eso.org/dataportal_new/file/UVES.2017-07-19T11:59:30.826.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2018-09-09T14:35:13.363
https://dataportal.eso.org/dataportal_new/file/UVES.2017-02-23T13:00:59.479
https://dataportal.eso.org/dataportal_new/file/UVES.2018-07-15T11:40:38.014
https://dataportal.eso.org/dataportal_new/file/UVES.2018-06-03T12:29:18.026.NL
https://dataportal.eso.org/dataportal_new/file/UVES.2017-04-23T11:08:33.918
__EOF__
