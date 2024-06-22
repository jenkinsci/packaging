# TODO:
# - how to add to the trusted service of the firewall?

%define workdir	%{_var}/lib/@@ARTIFACTNAME@@

Name:		@@ARTIFACTNAME@@
Version:	%{ver}
Release:	1.1
Summary:	@@SUMMARY@@
Source:		jenkins.war
Source1:	jenkins.service
Source2:	jenkins.sh
Source3:	migrate.sh
Source4:	jenkins.conf
URL:		@@HOMEPAGE@@
License:	@@LICENSE@@
BuildRoot:	%{_tmppath}/build-%{name}-%{version}
# Unfortunately the Oracle Java RPMs do not register as providing anything (including "java" or "jdk")
# So either we make a hard requirement on the OpenJDK or none at all
# Only workaround would be to use a java virtual package, see https://github.com/keystep/virtual-java-rpm
# TODO: If re-enable, fix the matcher for Java 17
# Requires: java >= 1:1.8.0
Requires: procps
Requires(pre): /usr/sbin/useradd, /usr/sbin/groupadd
BuildArch: noarch
%systemd_requires

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
%__install -D -m0644 "%{SOURCE1}" "%{buildroot}%{_unitdir}/%{name}.service"
%__install -D -m0755 "%{SOURCE2}" "%{buildroot}%{_bindir}/%{name}"
%__install -D -m0755 "%{SOURCE3}" "%{buildroot}%{_datadir}/%{name}/migrate"
%__install -D -m0755 "%{SOURCE4}" "%{buildroot}%{_tmpfilesdir}/%{name}.conf"

%pre
/usr/bin/getent group %{name} &>/dev/null || /usr/sbin/groupadd -r %{name} &>/dev/null
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/bin/getent passwd %{name} &>/dev/null || /usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null

%post
if [ $1 -eq 1 ]; then
    %__install -d -m 0755 -o %{name} -g %{name} %{workdir}
    %__install -d -m 0750 -o %{name} -g %{name} %{_localstatedir}/cache/%{name}
elif [ -f "%{_sysconfdir}/sysconfig/%{name}" ]; then
    %{_datadir}/%{name}/migrate "/etc/sysconfig/%{name}" || true
fi
%systemd_post %{name}.service

%preun
if [ $1 -eq 0 ]; then
    %__rm -rf %{_localstatedir}/cache/%{name}/war
fi
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%files
%{_javadir}/%{name}.war
%ghost %{workdir}
%ghost %{_localstatedir}/cache/%{name}
%{_unitdir}/%{name}.service
%{_bindir}/%{name}
%{_datadir}/%{name}/migrate
%{_tmpfilesdir}/%{name}.conf

%changelog
* Mon Nov 06 2023 minfrin@sharp.fm
- added unix domain socket support
* Mon Jun 19 2023 projects@unixadm.org
- removed sysv initscript for el>=7
- removed logrotate config
- avoid re-chowning workdir and cachedir on upgrades
* Sat Apr 19 2014 mbarr@mbarr.net
- Removed the jenkins.repo installation.  Per https://issues.jenkins-ci.org/browse/JENKINS-22690
* Wed Sep 28 2011 kk@kohsuke.org
- See [@@CHANGELOG_PAGE@@] for complete details
