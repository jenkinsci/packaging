# TODO:
# - how to add to the trusted service of the firewall?

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
Source5:	jenkins.service
Source6:	jenkins.sh
Source7:	migrate.sh
URL:		@@HOMEPAGE@@
Group:		Development/Tools/Building
License:	@@LICENSE@@
BuildRoot:	%{_tmppath}/build-%{name}-%{version}
# Unfortunately the Oracle Java RPMs do not register as providing anything (including "java" or "jdk")
# So either we make a hard requirement on the OpenJDK or none at all
# Only workaround would be to use a java virtual package, see https://github.com/keystep/virtual-java-rpm
# TODO: Fix the query for Java 17 if it is reenabled
# Requires: java >= 1:1.8.0
Requires:	procps
Requires(pre): /usr/sbin/useradd, /usr/sbin/groupadd
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
%__install -D -m0644 "%{SOURCE0}" "%{buildroot}%{_javadir}/%{name}.war"
%__install -d "%{buildroot}%{workdir}"
%__install -d "%{buildroot}%{workdir}/plugins"

%__install -d "%{buildroot}/var/log/%{name}"
%__install -d "%{buildroot}/var/cache/%{name}"

%__install -D -m0755 "%{SOURCE1}" "%{buildroot}/etc/init.d/%{name}"
%__sed -i 's,~~WAR~~,%{_javadir}/%{name}.war,g' "%{buildroot}/etc/init.d/%{name}"
%__install -d "%{buildroot}/usr/sbin"
%__ln_s "../../etc/init.d/%{name}" "%{buildroot}/usr/sbin/rc%{name}"

%__install -D -m0644 "%{SOURCE2}" "%{buildroot}/etc/sysconfig/%{name}"
%__sed -i 's,~~HOME~~,%{workdir},g' "%{buildroot}/etc/sysconfig/%{name}"

%__install -D -m0644 "%{SOURCE3}" "%{buildroot}/etc/logrotate.d/%{name}"

%__install -D -m0644 "%{SOURCE4}" "%{buildroot}/etc/zypp/repos.d/%{name}.repo"

%__install -D -m0644 "%{SOURCE5}" "%{buildroot}%{_unitdir}/%{name}.service"
%__install -D -m0755 "%{SOURCE6}" "%{buildroot}%{_bindir}/%{name}"
%__install -d "%{buildroot}%{_datadir}/%{name}"
%__install -D -m0755 "%{SOURCE7}" "%{buildroot}%{_datadir}/%{name}/migrate"

%pre
/usr/bin/getent group %{name} &>/dev/null || /usr/sbin/groupadd -r %{name} &>/dev/null
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/bin/getent passwd %{name} &>/dev/null || /usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null

%post
%{_datadir}/%{name}/migrate "/etc/sysconfig/%{name}" || true
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%clean
%__rm -rf "%{buildroot}"

%files
%defattr(-,root,root)
%{_javadir}/%{name}.war
%attr(0755,%{name},%{name}) %dir %{workdir}
%attr(0750,%{name},%{name}) /var/log/%{name}
%attr(0750,%{name},%{name}) /var/cache/%{name}
%config(noreplace) /etc/logrotate.d/%{name}
%config(noreplace) /etc/init.d/%{name}
%config(noreplace) /etc/sysconfig/%{name}
%config(noreplace) /etc/zypp/repos.d/%{name}.repo
/usr/sbin/rc%{name}
%{_unitdir}/%{name}.service
%{_bindir}/%{name}
%dir %{_datadir}/%{name}
%{_datadir}/%{name}/migrate

%changelog
* Wed Sep 28 2011 kk@kohsuke.org
- See [@@CHANGELOG_PAGE@@] for complete details
