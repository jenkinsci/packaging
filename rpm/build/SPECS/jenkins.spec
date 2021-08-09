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
# Unfortunately the Oracle Java RPMs do not register as providing anything (including "java" or "jdk")
# So either we make a hard requirement on the OpenJDK or none at all
# Only workaround would be to use a java virtual package, see https://github.com/keystep/virtual-java-rpm
# TODO: If re-enable, fix the matcher for Java 11
# Requires: java >= 1:1.8.0
Requires: daemonize procps
Obsoletes: hudson
Conflicts: hudson
PreReq: /usr/sbin/groupadd /usr/sbin/useradd
BuildArch: noarch

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
  # Check if a previous installation exists, if so check the JENKINS_HOME value and existing owners of work, log and cache dir, need to to this check
  # here because the %files directive overwrites folder owners, I have not found a simple way to make the
  # files directive to use JENKINS_USER as owner.
  if [ -f "/etc/sysconfig/%{name}" ]; then
      logger -t %{name}.installer "Found previous config file /etc/sysconfig/%{name}"
      . "/etc/sysconfig/%{name}"
      stat --format=%U "/var/cache/%{name}" > "/tmp/%{name}.installer.cacheowner"
      stat --format=%U "/var/log/%{name}"  >  "/tmp/%{name}.installer.logowner"
      stat --format=%U ${JENKINS_HOME:-%{workdir}}  > "/tmp/%{name}.installer.workdirowner"
  else
      logger -t %{name}.installer "No previous config file /etc/sysconfig/%{name} found"
  fi

%post
/sbin/chkconfig --add %{name}

function chownIfNecessary {
  logger -t %{name}.installer "Checking ${2} ownership"
  if [ -f "${1}" ] ; then
    owner=$(cat "$1")
    rm -f "$1"
    logger -t %{name}.installer "Found previous owner of ${2}: ${owner} "
  fi
  if  [ "${owner:-%{name}}" != "${JENKINS_USER:-%{name}}" ] ; then
    logger -t %{name}.installer "Previous owner of ${2} is different than configured JENKINS_USER... Doing a recursive chown of ${2} "
    chown -R ${JENKINS_USER:-%{name}} "$2"
  elif [ "${JENKINS_USER:-%{name}}" != "%{name}" ] ; then
    # User has changed ownership of files and JENKINS_USER, chown only the folder
    logger -t %{name}.installer "Configured JENKINS_USER is different than default... Doing a non recursive chown of ${2} "
    chown ${JENKINS_USER:-%{name}} "$2"
  else
    logger -t %{name}.installer "No chown needed for ${2} "
  fi
}

# Ensure the right ownership on files only if not owned by JENKINS_USER and JENKINS_USER
# != %{name}, namely all cases but the default one (configured for %{name} owned by %{name})
# In any case if JENKINS_INSTALL_SKIP_CHOWN is true we do not chown anything to maintain
# the existing semantics
. /etc/sysconfig/%{name}
if test x"$JENKINS_INSTALL_SKIP_CHOWN" != "xtrue"; then
      chownIfNecessary "/tmp/%{name}.installer.cacheowner"  "/var/cache/%{name}"
      chownIfNecessary "/tmp/%{name}.installer.logowner"  "/var/log/%{name}"
      chownIfNecessary "/tmp/%{name}.installer.workdirowner"  ${JENKINS_HOME:-%{workdir}}
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
