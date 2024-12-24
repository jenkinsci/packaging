using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Security;
using System.Security.Principal;
using System.Text.RegularExpressions;
using WixToolset.Dtf.WindowsInstaller;

namespace JenkinsCA {
    public static class CustomActions {
        private static ActionResult LogException(Session session, Exception ex) {
            using (Record record = new Record()) {
                record.FormatString = "Error occurred during installer: [0]";
                record.SetString(1, ex.Message);
                session.Message(InstallMessage.FatalExit, record);
            }
            return ActionResult.Failure;
        }

        [CustomAction]
        public static ActionResult BackupJenkinsXmlFile(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                DirectoryInfo jenkinsDirPath = new DirectoryInfo(session["JENKINSDIR"]);
                if (jenkinsDirPath.Exists) {
                    FileInfo srcPath = new FileInfo(Path.Combine(jenkinsDirPath.FullName, "jenkins.xml"));
                    if (srcPath.Exists) {
                        FileInfo dstPath = new FileInfo(srcPath.FullName + ".backup");
                        int suffix = 0;
                        while (dstPath.Exists) {
                            dstPath = new FileInfo(srcPath.FullName + string.Format(".backup_{0}", suffix));
                            suffix++;
                        }
                        srcPath.CopyTo(dstPath.FullName, true);
                    }
                }
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult ValidateJavaHome(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                DirectoryInfo javaHome = new DirectoryInfo(session["JAVA_HOME"]);
                session["JAVA_EXE_FOUND"] = "0";
                session["JAVA_EXE_VERSION"] = "";
                if (javaHome.Exists) {
                    FileInfo javaExe = new FileInfo(Path.Combine(javaHome.FullName, Path.Combine("bin", "java.exe")));
                    if (javaExe.Exists) {
                        session["JAVA_EXE_FOUND"] = "1";
                        FileVersionInfo javaExeVersionInfo = FileVersionInfo.GetVersionInfo(javaExe.FullName);
                        string javaExeVersion = javaExeVersionInfo.FileVersion;
                        session["JAVA_EXE_VERSION"] = javaExeVersion.Split(new char[] { '.' })[0];
                    }
                }
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult StripJenkinsDir(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                session["JENKINSDIR_STRIPPED"] = session["JENKINSDIR"].TrimEnd('\\');
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult StringTrim(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                string whiteSpaces = session["STRING_TRIM_WHITESPACES"];
                if (string.IsNullOrEmpty(whiteSpaces)) {
                    whiteSpaces = " \t";
                }
                session["STRING_TRIM_RESULT"] = session["STRING_TRIM_INPUT"].Trim(whiteSpaces.ToCharArray());
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult RegexMatch(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                string inputString = session["REGEX_MATCH_INPUT_STRING"];
                string patternString = session["REGEX_MATCH_EXPRESSION"];
                session["REGEX_MATCH_RESULT"] = Regex.IsMatch(inputString, patternString, RegexOptions.None) ? "1" : "0";
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult CheckCredentials(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                using (ImpersonatedSession impersonatedSession = new ImpersonatedSession(session)) {
                    session["LOGON_VALID"] = "0";
                    session["LOGON_ERROR"] = "";
                    session.Log("Checking credentials");

                    string username = session["LOGON_USERNAME"];
                    string domain = Utilities.SplitUsername(ref username);
                    session.Log(string.Format("username={0}, domain={1}", username, domain));
                    SecureString password = Utilities.SecureStringFromString(session["LOGON_PASSWORD"]);
                    Windows.LOGON32_LOGON_TYPE logonType = Utilities.GetPropertyValue(session, "LOGON_TYPE", Windows.LOGON32_LOGON_TYPE.LOGON32_LOGON_NETWORK);

                    Utilities.LogInfo(session, "CheckCredentials", "Userame: {0}", username);
                    Utilities.LogInfo(session, "CheckCredentials", "Password: {0}", password.Length > 0 ? "********" : "<blank>");
                    try {
                        Windows.LogonUser(domain, username, password, logonType);
                        session["LOGON_VALID"] = "1";
                    } catch (Win32Exception ex) {
                        session["LOGON_ERROR"] = ex.Message;
                    }
                }
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult CheckMembership(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                using (ImpersonatedSession impersonatedSession = new ImpersonatedSession(session)) {
                    Utilities.LogInfo(session, "CheckMembership", "Checking membership");
                    session["LOGON_IS_MEMBER"] = "0";

                    SecurityIdentifier sid = new SecurityIdentifier(session["SID"]);
                    session["LOGON_IS_MEMBER"] = Windows.IsMember(sid) ? "1" : "0";
                }
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }

        [CustomAction]
        public static ActionResult BindSocket(Session session) {
            ActionResult result = ActionResult.Success;
            try {
                session["TCPIP_BIND_SUCCEEDED"] = "0";
                int port = int.Parse(session["TCP_PORT"]);
                Utilities.CheckBool(port >= 0 && port <= 65536, "Invalid port specified");
                string ipAddress = session["TCP_IPADDRESS"];
                if (string.IsNullOrEmpty(ipAddress)) {
                    ipAddress = "127.0.0.1";
                }

                // we may have a hostname instead
                if (!IPAddress.TryParse(ipAddress, out IPAddress address)) {
                    IPHostEntry entry = Dns.GetHostEntry(ipAddress);                    
                    address = entry.AddressList[0];
                }

                IPEndPoint endPoint = new IPEndPoint(address, port);
                using (Socket socket = new Socket(address.AddressFamily, SocketType.Stream, ProtocolType.IP)) {
                    socket.Bind(endPoint);
                    session["TCPIP_BIND_SUCCEEDED"] = "1";
                }
            } catch (Exception ex) {
                result = LogException(session, ex);
            }
            return result;
        }        
    }
}
