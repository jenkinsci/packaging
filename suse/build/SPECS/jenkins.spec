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
# Unfortunately the Oracle Java RPMs do not register as providing anything (including "java" or "jdk")
# So either we make a hard requirement on the OpenJDK or none at all
# Only workaround would be to use a java virtual package, see https://github.com/keystep/virtual-java-rpm
# TODO: Fix the query for Java 11 if it is reenabled
# Requires: java >= 1:1.8.0
Requires:	procps
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
%__sed -i 's,~~WAR~~,%{_prefix}/%{name}.war,g' "%{buildroot}/etc/init.d/%{name}"
%__install -d "%{buildroot}/usr/sbin"
%__ln_s "../../etc/init.d/%{name}" "%{buildroot}/usr/sbin/rc%{name}"

%__install -D -m0644 "%{SOURCE2}" "%{buildroot}/etc/sysconfig/%{name}"
%__sed -i 's,~~HOME~~,%{workdir},g' "%{buildroot}/etc/sysconfig/%{name}"

%__install -D -m0644 "%{SOURCE3}" "%{buildroot}/etc/logrotate.d/%{name}"

%__install -D -m0644 "%{SOURCE4}" "%{buildroot}/etc/zypp/repos.d/%{name}.repo"
%pre
/usr/sbin/groupadd -r %{name} &>/dev/null || :
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null || :

%post
[ $1 -eq 1 ] && /sbin/chkconfig --add %{name}

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
