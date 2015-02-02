/* valaplugin.vala
 *
 * Author:
 * 	Kamanashis Roy <kamanashisroy@gmail.com>
 */

using GLib;

/**
 * \defgroup plugin Plugin
 * refer to external coupling
 */

/** \addtogroup Plugin
 *  @{
 */
public delegate void shotodolplug.ExtensionVisitor(Extension e);
public class shotodolplug.Plugin : Module {
	static CompositeExtension?x;
	public Plugin() {
		string nm = "Plugin";
		string ver = "0.0.0";
		base(nm,ver);
		x = null;
	}
	public static int register(string target, Extension e) {
		return x.register(target, e);
	}
	public static int unregister(string target, Extension e) {
		return x.unregister(target, e);
	}
	public static string? swarm(string target, string inmsg) {
		string?output = x.swarm(target, inmsg);
		string composite = "extension/composite";
		Extension?root = x.get(composite);
		while(root != null) {
			CompositeExtension cx = (CompositeExtension)root;
			output = cx.swarm(target, inmsg);
			Extension?next = root.getNext();
			root = next;
		}
		return output;
	}
	public static void acceptVisitor(string target, ExtensionVisitor visitor) {
		x.acceptVisitor(target, visitor);
		string composite = "extension/composite";
		Extension?root = x.get(composite);
		while(root != null) {
			CompositeExtension cx = (CompositeExtension)root;
			cx.acceptVisitor(target, visitor);
			Extension?next = root.getNext();
			root = next;
		}
	}
#if false
	public static void list(OutputStream pad) {
		x.list(pad);
	}
#endif
	
	public override int init() {
		x = new CompositeExtension(this);
		return 0;
	}
	public override int deinit() {
		x = null;
		return 0;
	}
}
/** @}*/
