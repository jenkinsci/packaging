using System;
using System.Security;
using System.Collections.Generic;
using WixToolset.Dtf.WindowsInstaller;

namespace JenkinsCA {
    public static class Utilities {

        public static T GetPropertyValue<T>(Session session, string property, T @default) where T : struct, Enum {
            string value = session[property];
            if(value.IndexOf('|') >= 0) {
                CheckHasFlags<T>();
                string[] items = value.Split('|');
                T res = default;
                foreach(string item in items) {
                    if(Enum.TryParse(item, out T curr)) {
                        uint val = Convert.ToUInt32(res) | Convert.ToUInt32(curr);
                        res = (T)Convert.ChangeType(val, typeof(T));
                    }
                }
                return res;
            } else {
                if(Enum.TryParse(value, out T result)) {
                    return result;
                }
            }
            return @default;
        }

        public static void CheckBool(bool condition, string message) {
            if(!condition) {
                throw new Exception(message);
            }
        }

        public static void LogInfo(Session session, string category, string format, params object[] args) {

        }

        public static SecureString SecureStringFromString(string input) {
            SecureString res = new SecureString();
            foreach(char c in input) {
                res.AppendChar(c);
            }
            return res;
        }

        public static string SplitUsername(ref string username) {
            string domain = ".";
            if(username.IndexOf('\\') >= 0) {
                string[] items = username.Split('\\');
                domain = items[0];
                username = items[1];
            } else if(username.IndexOf('@') >= 0) {
                string[] items = username.Split('@');
                domain = items[1];
                username = items[0];
            }
            return domain;
        }

        /// <summary>Determines whether the enumerated flag value has the specified flag set.</summary>
		/// <typeparam name="T">The enumerated type.</typeparam>
		/// <param name="flags">The enumerated flag value.</param>
		/// <param name="flag">The flag value to check.</param>
		/// <returns><c>true</c> if is flag set; otherwise, <c>false</c>.</returns>
		public static bool IsFlagSet<T>(this T flags, T flag) where T : struct, Enum {
			CheckHasFlags<T>();
			var flagValue = Convert.ToInt64(flag);
			return (Convert.ToInt64(flags) & flagValue) == flagValue;
		}

        /// <summary>Checks if <typeparamref name="T"/> represents an enumeration and throws an exception if not.</summary>
		/// <typeparam name="T">The <see cref="Type"/> to validate.</typeparam>
		/// <exception cref="System.ArgumentException"></exception>
		private static void CheckHasFlags<T>() where T : struct, Enum {
			if (!IsFlags<T>())
				throw new ArgumentException($"Type '{typeof(T).FullName}' doesn't have the 'Flags' attribute");
		}

		/// <summary>Determines whether this enumerations has the <see cref="FlagsAttribute"/> set.</summary>
		/// <typeparam name="T">The enumerated type.</typeparam>
		/// <returns><c>true</c> if this instance has the <see cref="FlagsAttribute"/> set; otherwise, <c>false</c>.</returns>
		private static bool IsFlags<T>() where T : struct, Enum {
            return Attribute.IsDefined(typeof(T), typeof(FlagsAttribute));
        }

        /// <summary>Adds an offset to the value of a pointer.</summary>
		/// <param name="pointer">The pointer to add the offset to.</param>
		/// <param name="offset">The offset to add.</param>
		/// <returns>A new pointer that reflects the addition of <paramref name="offset"/> to <paramref name="pointer"/>.</returns>
		public static IntPtr OffsetWith(this IntPtr pointer, long offset) {
			// On 64bits computer, we need ToInt64() to prevent exceptions when process is using more than int.MaxValue of memory.
			//
			// On 32bits computer, the use of ToInt64() has no effect except when the pointer moved by offset would make it past the
			// int.MaxValue barrier. We still need to fail in that case so let's make the IntPtr constructor fail with a meaningful error message.
			return new IntPtr(pointer.ToInt64() + offset);
        }
    }
}
