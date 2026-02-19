using System;
using System.Diagnostics;
using System.Security;
using System.Security.Principal;
using System.Security.Permissions;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace JenkinsCA
{
    public class Windows
    {
        // constants from winbase.h
        public enum LOGON32_LOGON_TYPE : int {
            LOGON32_LOGON_INTERACTIVE = 2,
            LOGON32_LOGON_NETWORK = 3,
            LOGON32_LOGON_BATCH = 4,
            LOGON32_LOGON_SERVICE = 5,
            LOGON32_LOGON_UNLOCK = 7,
            LOGON32_LOGON_NETWORK_CLEARTEXT = 8,
            LOGON32_LOGON_NEW_CREDENTIALS = 9,
        }

        internal enum LOGON32_PROVIDER_TYPE : int {
            LOGON32_PROVIDER_DEFAULT = 0,
            LOGON32_PROVIDER_WINNT35 = 1,
            LOGON32_PROVIDER_WINNT40 = 2,
            LOGON32_PROVIDER_WINNT50 = 3,
        }

        private enum SECURITY_IMPERSONATION_LEVEL : int
        {
            SecurityAnonymous = 0,
            SecurityIdentification = 1,
            SecurityImpersonation = 2,
            SecurityDelegation = 3,
        }

        [DllImport("advapi32", EntryPoint = "LogonUserW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern int LogonUser(string username, string domain, IntPtr password, LOGON32_LOGON_TYPE logonType, LOGON32_PROVIDER_TYPE logonProvider, ref IntPtr token);

        [DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern int DuplicateToken(IntPtr existingTokenHandle, SECURITY_IMPERSONATION_LEVEL impersonationLevel, ref IntPtr duplicateTokenHandle);

        [DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool RevertToSelf();

        [DllImport("kernel32", CharSet = CharSet.Auto)]
        private static extern bool CloseHandle(IntPtr handle);

        [DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool CheckTokenMembership(IntPtr tokenHandle, byte[] sidToCheck, ref bool isMember);

        /// <param name="hMem"></param>
		/// <returns></returns>
		[DllImport("kernel32", SetLastError = true)]
        public static extern IntPtr GlobalLock(IntPtr hMem);

        /// <summary>The GlobalUnlock function decrements the lock count associated with a memory object.</summary>
		/// <param name="hMem"></param>
		/// <returns></returns>
		[DllImport("kernel32", SetLastError = true)]
        public static extern bool GlobalUnlock(IntPtr hMem);

        [DebuggerNonUserCode]
        public static void LogonUser(string domain, string username, SecureString password, LOGON32_LOGON_TYPE logonType) {
            IntPtr token = IntPtr.Zero;
            IntPtr passwordHandle = Marshal.SecureStringToGlobalAllocUnicode(password);
            if (LogonUser(username, domain, passwordHandle, logonType, LOGON32_PROVIDER_TYPE.LOGON32_PROVIDER_DEFAULT, ref token) == 0) {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }

        public static bool IsMember(SecurityIdentifier sid) {
            byte[] binaryForm = new byte[sid.BinaryLength];
            sid.GetBinaryForm(binaryForm, 0);
            bool isMember = false;
            if (!CheckTokenMembership(IntPtr.Zero, binaryForm, ref isMember)) {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            return isMember;
        }

        public class WindowsImpersonation : IDisposable {
            private WindowsImpersonationContext impersonationContext;

            public WindowsImpersonation(string domain, string username, SecureString password, LOGON32_LOGON_TYPE logonType = LOGON32_LOGON_TYPE.LOGON32_LOGON_NETWORK) {
                Domain = domain;
                Username = username;
                Password = password;
                LogonType = logonType;
            }

            public string Username { get; set; }

            public string Domain { get; set; }

            [DebuggerNonUserCode]
            public SecureString Password { private get; set; }

            public LOGON32_LOGON_TYPE LogonType { get; set; }

            [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
            public bool ImpersonateUser() {
                bool result = false;
                IntPtr token = IntPtr.Zero;
                IntPtr tokenDuplicate = IntPtr.Zero;
                ImpersonationException exception = null;

                if (RevertToSelf()) {
                    IntPtr password = Marshal.SecureStringToGlobalAllocUnicode(Password);
                    int rc = LogonUser(Username, Domain, password, LOGON32_LOGON_TYPE.LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_TYPE.LOGON32_PROVIDER_DEFAULT, ref token);
                    if (rc != 0) {
                        if (DuplicateToken(token, SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, ref tokenDuplicate) != 0) {
                            impersonationContext = new WindowsIdentity(tokenDuplicate).Impersonate();
                            if (impersonationContext != null) {
                                result = true;
                            }
                        }
                    } else {
                        exception = new ImpersonationException(Domain, Username);
                    }

                    if (password != IntPtr.Zero) {
                        Marshal.ZeroFreeGlobalAllocUnicode(password);
                    }
                }

                if (tokenDuplicate != IntPtr.Zero) {
                    CloseHandle(tokenDuplicate);
                    tokenDuplicate = IntPtr.Zero;
                }

                if (token != IntPtr.Zero) {
                    CloseHandle(token);
                    token = IntPtr.Zero;
                }

                if (exception != null) {
                    throw exception;
                }
                return result;
            }

            [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
            [DebuggerNonUserCode]
            public void Undo() {
                impersonationContext?.Undo();
                impersonationContext = null;
            }

            [DebuggerNonUserCode]
            public static object InvokeAsUser(string domain, string username, SecureString password, Delegate methodToCall, params object[] args) {
                object result = null;
                using (WindowsImpersonation impersonation = new WindowsImpersonation(domain, username, password)) {
                    impersonation.ImpersonateUser();
                    result = methodToCall.DynamicInvoke(args);
                }
                return result;
            }

            ~WindowsImpersonation() {
                Dispose(false);
            }

            public void Dispose() {
                Dispose(true);
                System.GC.SuppressFinalize(this);
            }

            private bool disposed;

            protected void Dispose(bool disposing) {
                if (!disposed) {
                    if (disposing) {
                        if (impersonationContext != null) {
                            impersonationContext.Undo();
                            impersonationContext.Dispose();
                        }
                    }
                    impersonationContext = null;
                }
                disposed = true;
            }


            public class ImpersonationException : Exception {
                public string Username { get; private set; }

                public string Domain { get; private set; }

                public ImpersonationException(string domain, string username) : base(string.Format("Impersonation failure: {0}\\{1}", domain, username)) {
                    Domain = domain;
                    Username = username;
                }
            }
        }
    }
}
