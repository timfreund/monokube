# Monokube

## Deploy a Kubernetes cluster on a single monolithic host.

If you've read this far, you're already asking "OMG, why?!".  Here's
why: I want to iterate on building a small Kubernetes cluster with a
variety of tools and configurations, and it's only for prototyping.

Some folks do this with a small array of Raspberry Pi hardware, and
that's fine, but I don't love blinking LEDs that much and I'm already
sitting on plenty of gear: the smallest machine I use on a daily basis
has 16GB of RAM, and the largest is totally ridiculous.

## Use it

Open `monokube.env` and update the variables as necessary.  There are
a number of `IMAGE_URL` variables: uncomment the one you want and leave
the rest commented.  Feel free to add your own, too!

Run `./monokube-build.sh`  If you don't have all the required binaries
it will stop and ask you to correct that.  It'd be great to have a
list of required packages for Debian and RHEL variants here - pull
requests accepted.

Once the command completes, you'll have a `./cluster` directory with a
`.ssh` directory and key inside of it.  There are also metadata
directories for each of the newly created nodes.  We use cloud-init's
local datastore option to configure the machines on boot, so you
should be able to log in with the username `monokube` and the
`./cluster/.ssh/id_rsa` key.  Too bad you don't know the machine IP
addresses yet.

Now run `./monokube-update-metadata.sh` and once complete you should
find a file named `./cluster/inventory`.  I'm not going to force you
to use Ansible to configure the hosts, but I'm using Ansible so the
project generates an Ansible inventory file.  Maybe that becomes
a configuration option in the future.  If you do have ansible installed,
go into the cluster directory and run

Now do what you need to do to test a Kubernetes installation.

Once you're done, you can run `./monokube-destroy.sh`.

Warning: I've only tried the Ubuntu images thus far.  Report bugs if
you find issues with the others.  We can also attach a text file as a
serial console to the hosts with something like
`--serial file,path=/tmp/${node_name}.log` and that might help debug
issues.

## Completely Sane Questions

**So how should I install Kubernetes?**

I don't know yet, check back in a bit.

**This feels more like a general purpose cluster maker**

Yeah, kinda.  Maybe there's an abstraction waiting to be extracted.

**Wow, that's a whole lot of bash**

That's not really a question, but I get where you're coming from.  I
believe in hacks before systems, and if this project survives maybe
it'll grow to a "real" programming language.
