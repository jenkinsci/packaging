#!/bin/bash -eux

removeEnclosingQuotes() {
  local unquotedText=$(sed -e 's/^"//' -e 's/"$//' <<<"$1")
  echo $unquotedText
}

getCreateRepoPackageForDistro() {
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  local DISTRIB=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
  local DISTRO=$(removeEnclosingQuotes "$DISTRIB")
  # echo "Distribution is ${DISTRO}"
  if [[ ${DISTRO} == "Ubuntu"* ]]; then
    if uname -a | grep -q '^Linux.*Microsoft';
    then
      # ubuntu via WSL Windows Subsystem for Linux
      echo "createrepo"
    else
      # native ubuntu
      local UBUNTU_VERSION=$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)
      local FINAL_UBUNTU_VERSION=$(removeEnclosingQuotes "${UBUNTU_VERSION}")
      if [[ $(echo "$FINAL_UBUNTU_VERSION > 21.04" | bc -l) ]]; then
        echo "createrepo-c"
      elif [[ $(echo "$FINAL_UBUNTU_VERSION < 18.04" | bc -l) ]]; then
        echo "createrepo"
      else
        echo "We're doomed"
        exit 1
      fi
    fi
  elif [[ ${DISTRO} == "Debian"* ]]; then
    # debian
    echo "createrepo"
  else
    echo "We're doomed"
    exit 1
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS OSX
  echo "We're doomed"
  exit 1
fi
}

getCreateRepoPackageForDistro


sudo apt-get install -y rpm expect $(getCreateRepoPackageForDistro) || true

exit 0
