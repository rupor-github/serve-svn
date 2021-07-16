# serve-svn
## Very simple container to run WebSVN viewer and provide access to svn utilities and protocol.

I am using this container on my Synology NAS to have access to old code - recently DSM 7.0 dropped svn support and I am to lazy to move old code to git.

Normally I run it in read only mode, viewer is fully functional and you could use svn:// protocol to list things:

        sudo docker run -d --name svn -p 4000:80 -p 3690:3690 \
                -e SRV_HOST_PORT=192.168.50.10:4000 \
                -v /volume/docker/svn/data:/home/svn:ro \
                rupor/serve-svn

Since `svnadmin` does not care about access control lists you could always add more repositories:

		sudo docker exec -t svn svnadmin create /home/svn/<another repo>
		sudo docker exec -t svn svnadmin load /home/svn/<another repo> < dump

It is easy however to get a full access:

        sudo docker run -d --name svn -p 4000:80 -p 3690:3690 \
                -e SRV_HOST_PORT=192.168.50.10:4000 \
                -v /volume4/docker/svn/data:/home/svn \
                -v /volume4/docker/svn/svn/subversion-access-control:/etc/subversion/subversion-access-control \
                -v /volume4/docker/svn/svn/passwd:/etc/subversion/passwd \
                rupor/serve-svn

In this case you may want to change SVN access control lists and add users:

        sudo docker exec -t svn htpasswd -b /etc/subversion/passwd <username> <password>

## Technicalities

For some reason Alpine's build of subversion does not have svntools and without `svnauthz` [WebSVN](https://websvnphp.github.io/) refuses to work. So I had to build my own.
Setting up build environment is very simple. I used [this](https://github.com/yuk7/AlpineWSL) to install Alpine 3.14 under WSL2 in Windows 10 (you could use Hyper-V or VirtualBox too)
and then followed [the official guide](https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package#Setup_your_system_and_account). Takes about 3 minutes to complete.

Building Subversion with `svnauthz` requires a simple patch:

        diff --git a/main/subversion/APKBUILD b/main/subversion/APKBUILD
        index 6eb16766a2..3c20964d76 100644
        --- a/main/subversion/APKBUILD
        +++ b/main/subversion/APKBUILD
        @@ -85,10 +85,10 @@ check() {

        package() {
                local _pydir=$(python3 -c "import sysconfig;print(sysconfig.get_path('stdlib'))")
        -       make -j1 DESTDIR="$pkgdir" \
        +       make -j1 DESTDIR="$pkgdir" toolsdir=/usr/bin \
                        swig_pydir="$_pydir/libsvn"\
                        swig_pydir_extra="$_pydir/svn" \
        -               install install-swig-pl-lib install-swig-py
        +               install install-swig-pl-lib install-swig-py install-tools
                make pure_vendor_install -C subversion/bindings/swig/perl/native \
                        PERL_INSTALL_ROOT="$pkgdir"
                find "$pkgdir" \( -name perllocal.pod -o -name .packlist \) -delete

## Credits

* Thanks to [Luca Florio](https://github.com/elleFlorio) with his [elleFlorio/svn-docker](https://github.com/elleFlorio/svn-docker) for inspiration.

