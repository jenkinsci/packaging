# TODO:
# - how to add to the trusted service of the firewall?

%define _prefix	%{_usr}/lib/@@ARTIFACTNAME@@
%define workdir	%{_var}/lib/@@ARTIFACTNAME@@

Name:		@@ARTIFACTNAME@@
Version:	%{ver}
Release:	1.2
Summary:	@@SUMMARY@@
Source:		jenkins.war
Source1:	jenkins.init.in
Source2:	jenkins.sysconfig.in
Source3:	jenkins.logrotate
Source4:    jenkins.repo
URL:		@@HOMEPAGE@@
Group:		Development/Tools/Building
License:	@@LICENSE@@
BuildRoot:	%{_tmppath}/build-%{name}-%{version}
# see the comment below from java-1.6.0-openjdk.spec that explains this dependency
# java-1.5.0-ibm from jpackage.org set Epoch to 1 for unknown reasons,
# and this change was brought into RHEL-4.  java-1.5.0-ibm packages
# also included the epoch in their virtual provides.  This created a
# situation where in-the-wild java-1.5.0-ibm packages provided "java =
# 1:1.5.0".  In RPM terms, "1.6.0 < 1:1.5.0" since 1.6.0 is
# interpreted as 0:1.6.0.  So the "java >= 1.6.0" requirement would be
# satisfied by the 1:1.5.0 packages.  Thus we need to set the epoch in
# JDK package >= 1.6.0 to 1, and packages referring to JDK virtual
# provides >= 1.6.0 must specify the epoch, "java >= 1:1.6.0".
#
# java-1_6_0-sun provides this at least
Requires:	java >= 1.6
Obsoletes:  hudson
PreReq:		/usr/sbin/groupadd /usr/sbin/useradd
#PreReq:		%{fillup_prereq}
BuildArch:	noarch

%description
@@DESCRIPTION_FILE@@




Authors:
--------
    @@AUTHOR@@

%prep
%setup -q -T -c

%build

%install
rm -rf "%{buildroot}"
%__install -D -m0644 "%{SOURCE0}" "%{buildroot}%{_prefix}/%{name}.war"
%__install -d "%{buildroot}%{workdir}"
%__install -d "%{buildroot}%{workdir}/plugins"

%__install -d "%{buildroot}/var/log/%{name}"
%__install -d "%{buildroot}/var/cache/%{name}"

%__install -D -m0755 "%{SOURCE1}" "%{buildroot}/etc/init.d/%{name}"
%__sed -i 's,@@WAR@@,%{_prefix}/%{name}.war,g' "%{buildroot}/etc/init.d/%{name}"
%__install -d "%{buildroot}/usr/sbin"
%__ln_s "../../etc/init.d/%{name}" "%{buildroot}/usr/sbin/rc%{name}"

%__install -D -m0644 "%{SOURCE2}" "%{buildroot}/etc/sysconfig/%{name}"
%__sed -i 's,@@HOME@@,%{workdir},g' "%{buildroot}/etc/sysconfig/%{name}"

%__install -D -m0644 "%{SOURCE3}" "%{buildroot}/etc/logrotate.d/%{name}"

%__install -D -m0644 "%{SOURCE4}" "%{buildroot}/etc/zypp/repos.d/%{name}.repo"
%pre
/usr/sbin/groupadd -r %{name} &>/dev/null || :
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null || :

%post
[ $1 -eq 1 ] && /sbin/chkconfig --add %{name}

# If we have an old hudson install, rename it to jenkins
if test -d /var/lib/hudson; then
    # leave a marker to indicate this came from Hudson.
    # could be useful down the road
    # This also ensures that the .??* wildcard matches something
    touch /var/lib/hudson/.moving-hudson
    mv -f /var/lib/hudson/* /var/lib/hudson/.??* /var/lib/%{name}
    rmdir /var/lib/hudson
    find /var/lib/%{name} -user hudson -exec chown %{name} {} + || true
fi
if test -d /var/run/hudson; then
    mv -f /var/run/hudson/* /var/run/%{name}
    rmdir /var/run/hudson
fi

%preun
if [ "$1" = 0 ] ; then
    # if this is uninstallation as opposed to upgrade, delete the service
    /sbin/service %{name} stop > /dev/null 2>&1
    /sbin/chkconfig --del %{name}
fi
exit 0

%postun
if [ "$1" -ge 1 ]; then
    /sbin/service %{name} condrestart > /dev/null 2>&1
fi
exit 0

%clean
%__rm -rf "%{buildroot}"

%files
%defattr(-,root,root)
%dir %{_prefix}
%{_prefix}/%{name}.war
%attr(0755,%{name},%{name}) %dir %{workdir}
%attr(0750,%{name},%{name}) /var/log/%{name}
%attr(0750,%{name},%{name}) /var/cache/%{name}
%config(noreplace) /etc/logrotate.d/%{name}
%config(noreplace) /etc/init.d/%{name}
%config(noreplace) /etc/sysconfig/%{name}
%config(noreplace) /etc/zypp/repos.d/%{name}.repo
/usr/sbin/rc%{name}

%changelog
* Wed Sep 28 2011 kk@kohsuke.org
- See [@@CHANGELOG_PAGE@@] for complete details
