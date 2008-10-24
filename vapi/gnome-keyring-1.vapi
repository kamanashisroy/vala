/* gnome-keyring-1.vapi generated by lt-vapigen, do not modify. */

[CCode (cprefix = "GnomeKeyring", lower_case_cprefix = "gnome_keyring_")]
namespace GnomeKeyring {
	[Compact]
	[CCode (copy_function = "gnome_keyring_access_control_copy", cheader_filename = "gnome-keyring.h")]
	public class AccessControl {
		public weak GnomeKeyring.AccessControl copy ();
		[CCode (has_construct_function = false)]
		public AccessControl (GnomeKeyring.ApplicationRef application, GnomeKeyring.AccessType types_allowed);
	}
	[Compact]
	[CCode (copy_function = "gnome_keyring_application_ref_copy", cheader_filename = "gnome-keyring.h")]
	public class ApplicationRef {
		public weak GnomeKeyring.ApplicationRef copy ();
		[CCode (has_construct_function = false)]
		public ApplicationRef ();
	}
	[CCode (ref_function = "gnome_keyring_attribute_list_ref", unref_function = "gnome_keyring_attribute_list_unref", cheader_filename = "gnome-keyring.h")]
	public class AttributeList {
		[NoArrayLength]
		public GnomeKeyring.Attribute[] data;
		public uint len;
		public void append_string (string name, string value);
		public void append_uint32 (string name, uint value);
		public weak GnomeKeyring.AttributeList copy ();
		public GnomeKeyring.Attribute index (int i);
		public AttributeList ();
	}
	[Compact]
	[CCode (cheader_filename = "gnome-keyring.h")]
	public class Found {
		public weak GnomeKeyring.AttributeList attributes;
		public uint item_id;
		public weak string keyring;
		public weak string secret;
		public static void list_free (GLib.List found_list);
	}
	[Compact]
	[CCode (copy_function = "gnome_keyring_info_copy", cheader_filename = "gnome-keyring.h")]
	public class Info {
		public weak GnomeKeyring.Info copy ();
		public ulong get_ctime ();
		public bool get_is_locked ();
		public bool get_lock_on_idle ();
		public uint get_lock_timeout ();
		public ulong get_mtime ();
		public void set_lock_on_idle (bool value);
		public void set_lock_timeout (uint value);
	}
	[Compact]
	[CCode (copy_function = "gnome_keyring_item_info_copy", cheader_filename = "gnome-keyring.h")]
	public class ItemInfo {
		public weak GnomeKeyring.ItemInfo copy ();
		public ulong get_ctime ();
		public weak string get_display_name ();
		public ulong get_mtime ();
		public weak string get_secret ();
		[CCode (has_construct_function = false)]
		public ItemInfo ();
		public void set_display_name (string value);
		public void set_secret (string value);
		public void set_type (GnomeKeyring.ItemType type);
	}
	[Compact]
	[CCode (cheader_filename = "gnome-keyring.h")]
	public class NetworkPasswordData {
		public weak string authtype;
		public weak string domain;
		public uint item_id;
		public weak string keyring;
		public weak string object;
		public weak string password;
		public uint port;
		public weak string protocol;
		public weak string server;
		public weak string user;
	}
	[Compact]
	[CCode (cheader_filename = "gnome-keyring.h")]
	public class PasswordSchema {
		public void* attributes;
		public GnomeKeyring.ItemType item_type;
		public void* reserved1;
		public void* reserved2;
		public void* reserved3;
	}
	[CCode (cheader_filename = "gnome-keyring.h")]
	public struct Attribute {
		public weak string name;
		public GnomeKeyring.AttributeType type;
		public void* value;
	}
	[CCode (cprefix = "GNOME_KEYRING_ACCESS_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum AccessRestriction {
		ASK,
		DENY,
		ALLOW
	}
	[CCode (cprefix = "GNOME_KEYRING_ACCESS_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum AccessType {
		READ,
		WRITE,
		REMOVE
	}
	[CCode (cprefix = "GNOME_KEYRING_ATTRIBUTE_TYPE_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum AttributeType {
		STRING,
		UINT32
	}
	[CCode (cprefix = "GNOME_KEYRING_ITEM_INFO_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum ItemInfoFlags {
		BASICS,
		SECRET
	}
	[CCode (cprefix = "GNOME_KEYRING_ITEM_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum ItemType {
		GENERIC_SECRET,
		NETWORK_PASSWORD,
		NOTE,
		CHAINED_KEYRING_PASSWORD,
		ENCRYPTION_KEY_PASSWORD,
		LAST_TYPE
	}
	[CCode (cprefix = "GNOME_KEYRING_RESULT_", has_type_id = "0", cheader_filename = "gnome-keyring.h")]
	public enum Result {
		OK,
		DENIED,
		NO_KEYRING_DAEMON,
		ALREADY_UNLOCKED,
		NO_SUCH_KEYRING,
		BAD_ARGUMENTS,
		IO_ERROR,
		CANCELLED,
		KEYRING_ALREADY_EXISTS,
		NO_MATCH
	}
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationDoneCallback (GnomeKeyring.Result result);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetAttributesCallback (GnomeKeyring.Result result, GnomeKeyring.AttributeList attributes);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetIntCallback (GnomeKeyring.Result result, uint val);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetItemInfoCallback (GnomeKeyring.Result result, GnomeKeyring.ItemInfo info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetKeyringInfoCallback (GnomeKeyring.Result result, GnomeKeyring.Info info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetListCallback (GnomeKeyring.Result result, GLib.List list);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public delegate void OperationGetStringCallback (GnomeKeyring.Result result, string str);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const string DEFAULT;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const int GNOME_KEYRING_ITEM_APPLICATION_SECRET;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const int GNOME_KEYRING_ITEM_INFO_ALL;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const int GNOME_KEYRING_ITEM_TYPE_MASK;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const string GNOME_KEYRING_SESSION;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public const GnomeKeyring.PasswordSchema NETWORK_PASSWORD;
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak GLib.List acl_copy (GLib.List list);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void acl_free (GLib.List acl);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void cancel_request (void* request);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* change_password (string keyring, string? original, string? password, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result change_password_sync (string keyring, string? original, string? password);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* create (string keyring_name, string? password, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result create_sync (string keyring_name, string? password);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result daemon_prepare_environment_sync ();
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result daemon_set_display_sync (string display);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* @delete (string keyring, GnomeKeyring.OperationDoneCallback callback, void* data, GLib.DestroyNotify destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* delete_password (GnomeKeyring.PasswordSchema schema, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify destroy_data, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result delete_password_sync (GnomeKeyring.PasswordSchema schema, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result delete_sync (string keyring);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* find_items (GnomeKeyring.ItemType type, GnomeKeyring.AttributeList attributes, GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result find_items_sync (GnomeKeyring.ItemType type, GnomeKeyring.AttributeList attributes, GLib.List found);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* find_itemsv (GnomeKeyring.ItemType type, GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result find_itemsv_sync (GnomeKeyring.ItemType type, GLib.List found, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* find_network_password (string? user, string? domain, string? server, string? object, string? protocol, string? authtype, uint port, GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result find_network_password_sync (string? user, string? domain, string? server, string? object, string? protocol, string? authtype, uint port, GLib.List results);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* find_password (GnomeKeyring.PasswordSchema schema, GnomeKeyring.OperationGetStringCallback callback, GLib.DestroyNotify destroy_data, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result find_password_sync (GnomeKeyring.PasswordSchema schema, out weak string password, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void free_password (string password);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* get_default_keyring (GnomeKeyring.OperationGetStringCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result get_default_keyring_sync (out weak string keyring);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* get_info (string? keyring, GnomeKeyring.OperationGetKeyringInfoCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result get_info_sync (string? keyring, out weak GnomeKeyring.Info info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static bool is_available ();
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.AccessType item_ac_get_access_type (GnomeKeyring.AccessControl ac);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak string item_ac_get_display_name (GnomeKeyring.AccessControl ac);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak string item_ac_get_path_name (GnomeKeyring.AccessControl ac);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void item_ac_set_access_type (GnomeKeyring.AccessControl ac, GnomeKeyring.AccessType value);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void item_ac_set_display_name (GnomeKeyring.AccessControl ac, string value);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void item_ac_set_path_name (GnomeKeyring.AccessControl ac, string value);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_create (string? keyring, GnomeKeyring.ItemType type, string display_name, GnomeKeyring.AttributeList attributes, string secret, bool update_if_exists, GnomeKeyring.OperationGetIntCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_create_sync (string? keyring, GnomeKeyring.ItemType type, string display_name, GnomeKeyring.AttributeList attributes, string secret, bool update_if_exists, uint item_id);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_delete (string? keyring, uint id, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_delete_sync (string? keyring, uint id);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_get_acl (string? keyring, uint id, GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_get_acl_sync (string? keyring, uint id, GLib.List acl);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_get_attributes (string? keyring, uint id, GnomeKeyring.OperationGetAttributesCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_get_attributes_sync (string? keyring, uint id, out weak GnomeKeyring.AttributeList attributes);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_get_info (string? keyring, uint id, GnomeKeyring.OperationGetItemInfoCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_get_info_full (string? keyring, uint id, uint flags, GnomeKeyring.OperationGetItemInfoCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_get_info_full_sync (string? keyring, uint id, uint flags, out weak GnomeKeyring.ItemInfo info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak GnomeKeyring.Result? item_get_info_sync (string keyring, uint id, out weak GnomeKeyring.ItemInfo info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_grant_access_rights (string? keyring, string display_name, string full_path, uint id, GnomeKeyring.AccessType rights, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_grant_access_rights_sync (string? keyring, string display_name, string full_path, uint id, GnomeKeyring.AccessType rights);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_set_acl (string? keyring, uint id, GLib.List acl, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_set_acl_sync (string? keyring, uint id, GLib.List acl);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_set_attributes (string? keyring, uint id, GnomeKeyring.AttributeList attributes, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_set_attributes_sync (string? keyring, uint id, GnomeKeyring.AttributeList attributes);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* item_set_info (string? keyring, uint id, GnomeKeyring.ItemInfo info, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result item_set_info_sync (string? keyring, uint id, GnomeKeyring.ItemInfo info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* list_item_ids (string? keyring, GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result list_item_ids_sync (string? keyring, out GLib.List<uint> ids);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* list_keyring_names (GnomeKeyring.OperationGetListCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result list_keyring_names_sync (GLib.List keyrings);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* @lock (string keyring, GnomeKeyring.OperationDoneCallback callback, void* data, GLib.DestroyNotify destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* lock_all (GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result lock_all_sync ();
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result lock_sync (string? keyring);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* memory_alloc (ulong sz);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void memory_free (void* p);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static bool memory_is_secure (void* p);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* memory_realloc (void* p, ulong sz);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak string memory_strdup (string str);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* memory_try_alloc (ulong sz);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* memory_try_realloc (void* p, ulong sz);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void network_password_free (GnomeKeyring.NetworkPasswordData data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void network_password_list_free (GLib.List list);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static weak string result_to_message (GnomeKeyring.Result res);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* set_default_keyring (string keyring, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result set_default_keyring_sync (string keyring);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* set_info (string? keyring, GnomeKeyring.Info info, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result set_info_sync (string? keyring, GnomeKeyring.Info info);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* set_network_password (string? keyring, string? user, string? domain, string? server, string? object, string? protocol, string? authtype, uint port, string? password, GnomeKeyring.OperationGetIntCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result set_network_password_sync (string? keyring, string? user, string? domain, string? server, string? object, string? protocol, string? authtype, uint port, string? password, uint item_id);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* store_password (GnomeKeyring.PasswordSchema schema, string? keyring, string display_name, string password, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify destroy_data, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result store_password_sync (GnomeKeyring.PasswordSchema schema, string keyring, string display_name, string password, ...);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void string_list_free (GLib.List strings);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static void* unlock (string? keyring, string? password, GnomeKeyring.OperationDoneCallback callback, GLib.DestroyNotify? destroy_data);
	[CCode (cheader_filename = "gnome-keyring.h")]
	public static GnomeKeyring.Result unlock_sync (string? keyring, string? password);
}
