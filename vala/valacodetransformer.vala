/* valacodetransformer.vala
 *
 * Copyright (C) 2011  Luca Bruno
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Luca Bruno <lucabru@src.gnome.org>
 */

/**
 * Code visitor for transforming the code tree.
 */
public class Vala.CodeTransformer : CodeVisitor {
	public CodeContext context;

	public CodeBuilder b;
	public ArrayList<CodeBuilder> builder_stack = new ArrayList<CodeBuilder> ();
	public HashMap<string, CodeNode> wrapper_cache;
	/* Keep tracks of generated stuff to avoid cycles */
	public HashSet<CodeNode> unit_generated = new HashSet<CodeNode> ();

	public Namespace current_namespace = null;

	public void push_builder (CodeBuilder builder) {
		builder_stack.add (b);
		b = builder;
	}

	public void pop_builder () {
		b.cleanup ();
		
		b = builder_stack[builder_stack.size - 1];
		builder_stack.remove_at (builder_stack.size - 1);
	}

	/**
	 * Transform the code tree for the specified code context.
	 *
	 * @param context a code context
	 */
	public void transform (CodeContext context) {
		this.context = context;
		/* we're only interested in non-pkg source files */
		var source_files = context.get_source_files ();
		foreach (SourceFile file in source_files) {
			/* clear wrapper cache for every file */
			wrapper_cache = new HashMap<string, CodeNode> (str_hash, str_equal);
			file.accept (this);
		}
	}

	public static DataType? copy_type (DataType? type, bool? value_owned = null, bool? nullable = null) {
		if (type == null) {
			return null;
		}
		
		var ret = type.copy ();
		if (value_owned != null) {
			ret.value_owned = value_owned;
		}
		if (nullable != null) {
			ret.nullable = nullable;
		}
		return ret;
	}

	// Create an access to a temporary variable, with proper reference transfer if needed to avoid unnecessary copies
	public Expression return_temp_access (string local, DataType value_type, DataType? target_type, DataType? formal_target_type = null) {
		Expression temp_access = new MemberAccess.simple (local, b.source_reference);

		var target_owned = target_type == null || target_type.value_owned;
		if (target_owned && value_type.is_disposable ()) {
			temp_access = new ReferenceTransferExpression (temp_access, b.source_reference);
			temp_access.target_type = target_type != null ? target_type.copy () : value_type.copy ();
			temp_access.target_type.value_owned = true;
			temp_access.formal_target_type = copy_type (formal_target_type);
		} else {
			temp_access.target_type = copy_type (target_type);
		}
		
		return temp_access;
	}

	public bool get_cached_wrapper (string key, out CodeNode node) {
		node = wrapper_cache.get (key);
		return node != null;
	}

	public void add_cached_wrapper (string key, CodeNode node) {
		wrapper_cache.set (key, node);
	}

	public string temp_func_cname () {
		return "_vala_func_" + CodeNode.get_temp_name ().substring (1);
	}

	public bool wrapper_method (DataType return_type, string? cache_key, out Method m, Symbol? parent = null) {
		CodeNode n = null;
		if (cache_key != null && get_cached_wrapper (cache_key, out n)) {
			m = (Method) n;
			return true;
		}
		m = new Method (temp_func_cname (), return_type, b.source_reference);
		(parent == null ? context.root : parent).add_method (m);
		m.access = SymbolAccessibility.PRIVATE;
		add_cached_wrapper (cache_key, m);
		return false;
	}

	public Symbol symbol_from_string (string s) {
		return CodeBuilder.symbol_from_string (s);
	}

	public DataType data_type (string s, bool value_owned = true, bool nullable = false) {		
		return CodeBuilder.data_type (s, value_owned, nullable);
	}

	public Expression expression (string str) {
		return b.expression (str);
	}

	public void check (CodeNode node) {
		node.accept (context.resolver);
		if (!node.check (context)) {
			return;
		}
		node.accept (this);
	}

	public bool is_visited (CodeNode node) {
		var file = node.source_reference.file;
		return file.file_type == SourceFileType.SOURCE || (context.header_filename != null && file.file_type == SourceFileType.FAST);
	}

	public void accept_external (CodeNode node) {
		if (node.source_reference != null) {
			if (!is_visited (node) && !unit_generated.contains (node)) {
				unit_generated.add (node);
				check (node);
			}
		}
	}
}