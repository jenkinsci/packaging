using System;
using System.Security;
using WixToolset.Dtf.WindowsInstaller;

namespace JenkinsCA {
    public class ImpersonatedSession : IDisposable {
        Windows.WindowsImpersonation windowsImpersonation;
        readonly Session session;

        public ImpersonatedSession(Session session) {
            this.session = session;
            string username = session["LOGON_USERNAME"];
            string domain = Utilities.SplitUsername(ref username);
            SecureString password = new SecureString();
            foreach(char val in session["LOGON_PASSWORD"]) {
                password.AppendChar(val);
            }
            Windows.LOGON32_LOGON_TYPE logonType = Utilities.GetPropertyValue(session, "LOGON_TYPE", Windows.LOGON32_LOGON_TYPE.LOGON32_LOGON_NETWORK);
            windowsImpersonation = new Windows.WindowsImpersonation(domain, username, password, logonType);
            windowsImpersonation.ImpersonateUser();
        }

        public string this[string property] {
            get {
                return session[property];
            }
            set {
                session[property] = value;
            }
        }

        public void Dispose() {
            if(windowsImpersonation != null) {
                windowsImpersonation.Dispose();
                windowsImpersonation = null;
            }
        }
    }
}
