# TODO:
# - how to add to the trusted service of the firewall?

%define _prefix		%{_usr}/lib/%{name}
%define workdir		%{_sharedstatedir}/%{name}
%define logdir		%{_localstatedir}/log/%{name}
%define cachedir	%{_localstatedir}/cache/%{name}

Name:		@@ARTIFACTNAME@@
Version:	%{ver}
Release:	1.1
Summary:	@@SUMMARY@@
Source:		jenkins.war
Source1:	jenkins-run.in
Source2:	jenkins.service.in
Source3:	jenkins.logrotate
URL:		@@HOMEPAGE@@
Group:		Development/Tools/Building
License:	@@LICENSE@@
# Unfortunately the Oracle Java RPMs do not register as providing anything (including "java" or "jdk")
# So either we make a hard requirement on the OpenJDK or none at all
# Only workaround would be to use a java virtual package, see https://github.com/keystep/virtual-java-rpm
# TODO: If re-enable, fix the matcher for Java 11
# Requires: java >= 1:1.8.0
Obsoletes: hudson
Conflicts: hudson
Requires(pre): /usr/sbin/groupadd /usr/sbin/useradd
%if 0%{?rhel} == 7
BuildRequires: systemd
%endif
%if 0%{?rhel} >= 8
BuildRequires: systemd-rpm-macros
%endif
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
%__install -D -m0644 "%{SOURCE1}" "%{buildroot}%{_libexecdir}/%{name}-run"
%__install -d "%{buildroot}%{workdir}"
%__install -d "%{buildroot}%{workdir}/plugins"

%__install -d "%{buildroot}%{logdir}"
%__install -d "%{buildroot}%{cachedir}"

%__install -D -m0644 "%{SOURCE2}" "%{buildroot}%{_unitdir}/%{name}.service"
%__sed -i 's,~~WAR~~,%{_prefix}/%{name}.war,g' "%{buildroot}%{_unitdir}/%{name}.service"
%__sed -i 's,~~HOME~~,%{workdir},g' "%{buildroot}%{_unitdir}/%{name}.service"

%__install -D -m0644 "%{SOURCE3}" "%{buildroot}%{_sysconfdir}/logrotate.d/%{name}"

%pre
/usr/sbin/groupadd -r %{name} &>/dev/null || :
# SUSE version had -o here, but in Fedora -o isn't allowed without -u
/usr/sbin/useradd -g %{name} -s /bin/false -r -c "@@SUMMARY@@" \
	-d "%{workdir}" %{name} &>/dev/null || :

  # Used to decide later if we should perform a chown in case JENKINS_INSTALL_SKIP_CHOWN is false
  # Check if a previous installation exists, if so check the JENKINS_HOME value and existing owners of work, log and cache dir, need to to this check
  # here because the %files directive overwrites folder owners, I have not found a simple way to make the
  # files directive to use JENKINS_USER as owner.
  if [ -f "%{_sysconfdir}/sysconfig/%{name}" ]; then
      logger -t %{name}.installer "Found previous config file %{_sysconfdir}/sysconfig/%{name}"
      . "%{_sysconfdir}/sysconfig/%{name}"
      stat --format=%U "%{cachedir}" > "/tmp/%{name}.installer.cacheowner"
      stat --format=%U "%{logdir}"  >  "/tmp/%{name}.installer.logowner"
      stat --format=%U ${JENKINS_HOME:-%{workdir}}  > "/tmp/%{name}.installer.workdirowner"
  else
      logger -t %{name}.installer "No previous config file %{_sysconfdir}/sysconfig/%{name} found"
  fi

%post
%systemd_post %{name}.service

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
. %{_sysconfdir}/sysconfig/%{name}
if test x"$JENKINS_INSTALL_SKIP_CHOWN" != "xtrue"; then
      chownIfNecessary "/tmp/%{name}.installer.cacheowner"  "%{cachedir}"
      chownIfNecessary "/tmp/%{name}.installer.logowner"  "%{logdir}"
      chownIfNecessary "/tmp/%{name}.installer.workdirowner"  ${JENKINS_HOME:-%{workdir}}
fi

%preun
%systemd_preun %{name}.service
exit 0

%postun
%systemd_postun_with_restart %{name}.service
exit 0

%clean
%__rm -rf "%{buildroot}"

%files
%defattr(-,root,root)
%dir %{_prefix}
%{_prefix}/%{name}.war
%{_libexecdir}/%{name}-run
%attr(0755,%{name},%{name}) %dir %{workdir}
%attr(0750,%{name},%{name}) %dir %{logdir}
%attr(0750,%{name},%{name}) %dir %{cachedir}
%config %{_sysconfdir}/logrotate.d/%{name}
%{_unitdir}/%{name}.service

%changelog
* Sat Apr 19 2014 mbarr@mbarr.net
- Removed the jenkins.repo installation.  Per https://issues.jenkins-ci.org/browse/JENKINS-22690
* Wed Sep 28 2011 kk@kohsuke.org
- See [@@CHANGELOG_PAGE@@] for complete details
