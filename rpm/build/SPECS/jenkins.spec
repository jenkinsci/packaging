# TODO:
# - how to add to the trusted service of the firewall?

%define _prefix	%{_usr}/lib/@@ARTIFACTNAME@@
%define workdir	%{_var}/lib/@@ARTIFACTNAME@@

Name:		@@ARTIFACTNAME@@
Version:	%{ver}
Release:	1.1
Summary:	@@SUMMARY@@
Source:		jenkins.war
Source1:	jenkins.init.in
Source2:	jenkins.sysconfig.in
Source3:	jenkins.logrotate
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
# Kohsuke - 2009/09/29
#    test by mrooney on what he believes to be RHEL 5.2 indicates
#    that there's no such packages. JRE/JDK RPMs from java.sun.com
#    do not have this virtual package declarations. So for now,
#    I'm dropping this requirement.
# Requires:	java >= 1:1.6.0
Requires: procps
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
%__sed -i 's,~~WAR~~,%{_prefix}/%{name}.war,g' "%{buildroot}/etc/init.d/%{name}"
%__install -d "%{buildroot}/usr/sbin"
%__ln_s "../../etc/init.d/%{name}" "%{buildroot}/usr/sbin/rc%{name}"

%__install -D -m0600 "%{SOURCE2}" "%{buildroot}/etc/sysconfig/%{name}"
%__sed -i 's,~~HOME~~,%{workdir},g' "%{buildroot}/etc/sysconfig/%{name}"

%__install -D -m0644 "%{SOURCE3}" "%{buildroot}/etc/logrotate.d/%{name}"

%pre
/usr/sbin/groupadd -r %{name} &>/dev/null || :
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null || :

  # Used to decide later if we should perform a chown in case JENKINS_INSTALL_SKIP_CHOWN is false
  # Check if a previous installation exists, if so use the configured JENKINS_USER to generate a files file for later use
  # And check the JENKINS_HOME value and existing owners of work, log and cache dir, need to to this check
  # here because the %files directive overwrites folder owners, I have not found a simple way to make the
  # files directive to use JENKINS_USER as owner.
  if [ -f "/etc/sysconfig/%{name}" ]; then
      . /etc/sysconfig/%{name}
      touch /tmp/cacheowner
      ls -ld /var/cache/%{name} | awk 'NR==1 {print $3}' > /tmp/cacheowner
      touch /tmp/logowner
      ls -ld /var/log/%{name} | awk 'NR==1 {print $3}' >  /tmp/logowner
      touch /tmp/workdirowner
      ls -ld ${JENKINS_HOME:-%{workdir}}| awk 'NR==1 {print $3}'  > /tmp/workdirowner
  fi

%post
/sbin/chkconfig --add %{name}

# Ensure the right ownership on files only if not owned by JENKINS_USER
. /etc/sysconfig/%{name}
if test x"$JENKINS_INSTALL_SKIP_CHOWN" != "xtrue"; then
    if [ -f "/tmp/cacheowner" ]; then
      cacheOwner=$(cat /tmp/cacheowner)
      rm -f /tmp/cacheowner
    fi
    if [ "${JENKINS_USER:-%{name}}" != "%{name}" ] || [ "${cacheOwner:-%{name}}" != "${JENKINS_USER:-%{name}}" ] ; then
        chown -R ${JENKINS_USER:-%{name}} /var/cache/%{name}
    fi
    if [ -f "/tmp/logowner" ]; then
      logOwner=$(cat /tmp/logowner)
      rm -f /tmp/logowner
    fi
    if [ "${JENKINS_USER:-%{name}}" != "%{name}" ] || [ "${logOwner:-%{name}}" != "${JENKINS_USER:-%{name}}" ] ; then
        chown -R ${JENKINS_USER:-%{name}} /var/log/%{name}
    fi
    if [ -f "/tmp/workdirowner" ]; then
      workdirOwner=$(cat /tmp/workdirowner)
      rm -f /tmp/workdirowner
    fi
    if [ "${JENKINS_USER:-%{name}}" != "%{name}" ] || [ "${workdirOwner:-%{name}}" != "${JENKINS_USER:-%{name}}" ] ; then
        chown -R ${JENKINS_USER:-%{name}} ${JENKINS_HOME:-%{workdir}}
    fi
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
%config /etc/logrotate.d/%{name}
%config(noreplace) /etc/init.d/%{name}
%config(noreplace) /etc/sysconfig/%{name}
/usr/sbin/rc%{name}

%changelog
* Sat Apr 19 2014 mbarr@mbarr.net
- Removed the jenkins.repo installation.  Per https://issues.jenkins-ci.org/browse/JENKINS-22690
* Wed Sep 28 2011 kk@kohsuke.org
- See [@@CHANGELOG_PAGE@@] for complete details
