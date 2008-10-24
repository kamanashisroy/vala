/* libgnome-2.0.vapi generated by lt-vapigen, do not modify. */

[CCode (cprefix = "Gnome", lower_case_cprefix = "gnome_")]
namespace Gnome {
	[Compact]
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public class ModuleInfo {
		public weak Gnome.ModuleClassInitHook class_init;
		public weak string description;
		public weak Gnome.ModuleGetGOptionGroupFunc get_goption_group_func;
		public weak Gnome.ModuleInitHook init_pass;
		public weak Gnome.ModuleHook instance_init;
		public weak string name;
		public weak string opt_prefix;
		public weak Gnome.ModuleHook post_args_parse;
		public weak Gnome.ModuleHook pre_args_parse;
		public weak Gnome.ModuleRequirement requirements;
		public weak string version;
	}
	[Compact]
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public class ModuleRequirement {
		public weak Gnome.ModuleInfo module_info;
		public weak string required_version;
	}
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public class Program : GLib.Object {
		public static weak Gnome.Program get ();
		public weak string get_app_id ();
		public weak string get_app_version ();
		public weak string get_human_readable_name ();
		public static weak Gnome.Program init (string app_id, string app_version, Gnome.ModuleInfo module_info, [CCode (array_length_pos = 3.9)] string[] argv, ...);
		public static weak Gnome.Program init_paramv (GLib.Type type, string app_id, string app_version, Gnome.ModuleInfo module_info, [CCode (array_length_pos = 4.9)] string[] argv, uint nparams, GLib.Parameter params);
		public static weak Gnome.Program initv (GLib.Type type, string app_id, string app_version, Gnome.ModuleInfo module_info, [CCode (array_length_pos = 4.9)] string[] argv, string first_property_name, void* args);
		public class uint install_property (GLib.ObjectGetPropertyFunc get_fn, GLib.ObjectSetPropertyFunc set_fn, GLib.ParamSpec pspec);
		public weak string locate_file (Gnome.FileDomain domain, string file_name, bool only_if_exists, GLib.SList ret_locations);
		public static weak Gnome.ModuleInfo module_load (string mod_name);
		public static void module_register (Gnome.ModuleInfo module_info);
		public static bool module_registered (Gnome.ModuleInfo module_info);
		[NoAccessorMethod]
		public string app_datadir { get; set; }
		public string app_id { get; }
		[NoAccessorMethod]
		public string app_libdir { get; set; }
		[NoAccessorMethod]
		public string app_prefix { get; set; }
		[NoAccessorMethod]
		public string app_sysconfdir { get; set; }
		public string app_version { get; }
		[NoAccessorMethod]
		public bool create_directories { get; construct; }
		[NoAccessorMethod]
		public bool enable_sound { get; set; }
		[NoAccessorMethod]
		public string espeaker { get; set; }
		[NoAccessorMethod]
		public string gnome_datadir { get; construct; }
		[NoAccessorMethod]
		public string gnome_libdir { get; construct; }
		[NoAccessorMethod]
		public string gnome_path { get; construct; }
		[NoAccessorMethod]
		public string gnome_prefix { get; construct; }
		[NoAccessorMethod]
		public string gnome_sysconfdir { get; construct; }
		[NoAccessorMethod]
		public void* goption_context { get; construct; }
		[NoAccessorMethod]
		public string human_readable_name { get; construct; }
		[NoAccessorMethod]
		public void* popt_context { get; }
		[NoAccessorMethod]
		public int popt_flags { construct; }
		[NoAccessorMethod]
		public void* popt_table { construct; }
	}
	[Compact]
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public class Trigger {
		public weak string level;
		public Gnome.TriggerType type;
		public void* u;
	}
	[CCode (cprefix = "GNOME_FILE_DOMAIN_", has_type_id = "0", cheader_filename = "libgnome/libgnome.h")]
	public enum FileDomain {
		UNKNOWN,
		LIBDIR,
		DATADIR,
		SOUND,
		PIXMAP,
		CONFIG,
		HELP,
		APP_LIBDIR,
		APP_DATADIR,
		APP_SOUND,
		APP_PIXMAP,
		APP_CONFIG,
		APP_HELP
	}
	[CCode (cprefix = "GNOME_HELP_ERROR_", has_type_id = "0", cheader_filename = "libgnome/libgnome.h")]
	public enum HelpError {
		INTERNAL,
		NOT_FOUND
	}
	[CCode (cprefix = "GTRIG_", has_type_id = "0", cheader_filename = "libgnome/libgnome.h")]
	public enum TriggerType {
		NONE,
		FUNCTION,
		COMMAND,
		MEDIAPLAY
	}
	[CCode (cprefix = "GNOME_URL_ERROR_", has_type_id = "0", cheader_filename = "libgnome/libgnome.h")]
	public enum URLError {
		PARSE,
		LAUNCH,
		URL,
		NO_DEFAULT,
		NOT_SUPPORTED,
		VFS,
		CANCELLED
	}
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static delegate void ModuleClassInitHook (void* klass, Gnome.ModuleInfo mod_info);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static delegate weak GLib.OptionGroup ModuleGetGOptionGroupFunc ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static delegate void ModuleHook (Gnome.Program program, Gnome.ModuleInfo mod_info);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static delegate void ModuleInitHook (Gnome.ModuleInfo mod_info);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static delegate void TriggerActionFunction (string msg, string level, string[] supinfo);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string DOT_GNOME;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string DOT_GNOME_PRIVATE;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_DATADIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_ID;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_LIBDIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_PREFIX;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_SYSCONFDIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_APP_VERSION;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_CREATE_DIRECTORIES;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_ENABLE_SOUND;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_ESPEAKER;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GNOME_DATADIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GNOME_LIBDIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GNOME_PATH;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GNOME_PREFIX;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GNOME_SYSCONFDIR;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_GOPTION_CONTEXT;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_HUMAN_READABLE_NAME;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_POPT_CONTEXT;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_POPT_FLAGS;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public const string PARAM_POPT_TABLE;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak Gnome.ModuleInfo bonobo_module_info_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void clearenv ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_async (string dir, int argc, string[] argv);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_async_fds (string dir, int argc, string[] argv, bool close_fds);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_async_with_env (string dir, int argc, string[] argv, int envc, string[] envv);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_async_with_env_fds (string dir, int argc, string[] argv, int envc, string[] envv, bool close_fds);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_shell (string dir, string commandline);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_shell_fds (string dir, string commandline, bool close_fds);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_terminal_shell (string dir, string commandline);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int execute_terminal_shell_fds (string dir, string commandline, bool close_fds);
	[CCode (cname = "g_extension_pointer", cheader_filename = "libgnome/libgnome.h")]
	public static weak string g_extension_pointer (string path);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string gconf_get_app_settings_relative (Gnome.Program program, string subkey);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string gconf_get_gnome_libs_settings_relative (string subkey);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display (string file_name, string link_id) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_desktop (Gnome.Program program, string doc_id, string file_name, string link_id) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_desktop_with_env (Gnome.Program program, string doc_id, string file_name, string link_id, out weak string envp) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_uri (string help_uri) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_uri_with_env (string help_uri, out weak string envp) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_with_doc_id (Gnome.Program program, string doc_id, string file_name, string link_id) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool help_display_with_doc_id_and_env (Gnome.Program program, string doc_id, string file_name, string link_id, out weak string envp) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static GLib.Quark help_error_quark ();
	[CCode (cname = "libgnome_module_info_get", cheader_filename = "libgnome/libgnome.h")]
	public static weak Gnome.ModuleInfo libgnome_module_info_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void prepend_terminal_to_vector (int argc, out weak string argv);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int setenv (string name, string value, bool overwrite);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int sound_connection_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void sound_init (string hostname);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void sound_play (string filename);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static int sound_sample_load (string sample_name, string filename);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void sound_shutdown ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void triggers_add_trigger (Gnome.Trigger nt);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void triggers_do (string msg, string level);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void triggers_vadd_trigger (Gnome.Trigger nt, string[] supinfo);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void triggers_vdo (string msg, string level, string[] supinfo);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static void unsetenv (string name);
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static GLib.Quark url_error_quark ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool url_show (string url) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static bool url_show_with_env (string url, out weak string envp) throws GLib.Error;
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string user_accels_dir_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string user_dir_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string user_private_dir_get ();
	[CCode (cheader_filename = "libgnome/libgnome.h")]
	public static weak string util_user_shell ();
}
