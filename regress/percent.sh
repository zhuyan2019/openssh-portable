#	$OpenBSD: percent.sh,v 1.1 2020/04/03 02:33:31 dtucker Exp $
#	Placed in the Public Domain.

tid="percent expansions"

USER=`id -u -n`
USERID=`id -u`
HOST=`hostname -s`
HOSTNAME=`hostname`

# Localcommand is evaluated after connection because %T is not available
# until then.  Because of this we use a different method of exercising it,
# and we can't override the remote user otherwise authentication will fail.
# We also have to explicitly enable it.
echo "permitlocalcommand yes" >> $OBJ/ssh_proxy

trial()
{
	opt="$1"; arg="$2"; expect="$3"

	trace "test $opt=$arg $expect"
	if [ "$opt" = "localcommand" ]; then
		${SSH} -F $OBJ/ssh_proxy -o $opt="echo '$arg' >$OBJ/actual" \
		    somehost true
		got=`cat $OBJ/actual`
	else
		got=`${SSH} -F $OBJ/ssh_proxy -o $opt="$arg" -G \
		    remuser@somehost | awk '$1=="'$opt'"{print $2}'`
	fi
	if [ "$got" != "$expect" ]; then
		fail "$opt=$arg expect $expect got $got"
	else
		trace "$opt=$arg expect $expect got $got"
	fi
}

for i in localcommand remotecommand controlpath identityagent forwardagent; do
	if [ "$i" = "localcommand" ]; then
		HASH=94237ca18fe6b187dccf57e5593c0bb0a29cc302
		REMUSER=$USER
		trial $i '%T' NONE
	else
		HASH=dbc43d45c7f8c0ecd0a65c0da484c03b6903622e
		REMUSER=remuser
	fi
	trial $i '%%' '%'
	trial $i '%C' $HASH
	trial $i '%i' $USERID
	trial $i '%h' 127.0.0.1
	trial $i '%d' $HOME
	trial $i '%L' $HOST
	trial $i '%l' $HOSTNAME
	trial $i '%n' somehost
	trial $i '%p' $PORT
	trial $i '%r' $REMUSER
	trial $i '%u' $USER
	trial $i '%%/%C/%i/%h/%d/%L/%l/%n/%p/%r/%u' \
	    "%/$HASH/$USERID/127.0.0.1/$HOME/$HOST/$HOSTNAME/somehost/$PORT/$REMUSER/$USER"
done

# A subset of options support tilde expansion
for i in controlpath identityagent forwardagent; do
	trial $i '~' $HOME/
	trial $i '~/.ssh' $HOME/.ssh
done
