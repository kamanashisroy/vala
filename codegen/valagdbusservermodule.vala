/* valagdbusservermodule.vala
 *
 * Copyright (C) 2010  Jürg Billeter
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
 * 	Jürg Billeter <j@bitron.ch>
 */

public class Vala.GDBusServerModule : GDBusClientModule {
	public static bool is_dbus_visible (CodeNode node) {
		var dbus_attribute = node.get_attribute ("DBus");
		if (dbus_attribute != null
		    && dbus_attribute.has_argument ("visible")
		    && !dbus_attribute.get_bool ("visible")) {
			return false;
		}

		return true;
	}

	public static string dbus_result_name (Method m) {
		var dbus_attribute = m.get_attribute ("DBus");
		if (dbus_attribute != null
		    && dbus_attribute.has_argument ("result")) {
			var result_name = dbus_attribute.get_string ("result");
			if (result_name != null && result_name != "") {
				return result_name;
			}
		}

		return "result";
	}

	string generate_dbus_wrapper (Method m, ObjectTypeSymbol sym, bool ready = false) {
		string wrapper_name = "_dbus_%s".printf (m.get_cname ());

		if (m.base_method != null) {
			m = m.base_method;
		} else if (m.base_interface_method != null) {
			m = m.base_interface_method;
		}

		if (ready) {
			// async ready function
			wrapper_name += "_ready";
		}

		var function = new CCodeFunction (wrapper_name);
		function.modifiers = CCodeModifiers.STATIC;

		if (!ready) {
			function.add_parameter (new CCodeFormalParameter ("self", sym.get_cname () + "*"));
			function.add_parameter (new CCodeFormalParameter ("parameters", "GVariant*"));
			function.add_parameter (new CCodeFormalParameter ("invocation", "GDBusMethodInvocation*"));
		} else {
			function.add_parameter (new CCodeFormalParameter ("source_object", "GObject *"));
			function.add_parameter (new CCodeFormalParameter ("_res_", "GAsyncResult *"));
			function.add_parameter (new CCodeFormalParameter ("_user_data_", "gpointer *"));
		}

		push_function (function);

		cfile.add_include ("gio/gunixfdlist.h");

		if (ready) {
			ccode.add_declaration ("GDBusMethodInvocation *", new CCodeVariableDeclarator ("invocation", new CCodeIdentifier ("_user_data_")));
		}

		var connection = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_method_invocation_get_connection"));
		connection.add_argument (new CCodeIdentifier ("invocation"));

		bool no_reply = is_dbus_no_reply (m);

		if (!m.coroutine || ready) {
			ccode.add_declaration ("GError*", new CCodeVariableDeclarator ("error", new CCodeConstant ("NULL")));
		}

		ccode.add_declaration ("GVariantIter", new CCodeVariableDeclarator ("_arguments_iter"));

		if (!ready) {
			var iter_init = new CCodeFunctionCall (new CCodeIdentifier ("g_variant_iter_init"));
			iter_init.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_arguments_iter")));
			iter_init.add_argument (new CCodeIdentifier ("parameters"));
			ccode.add_expression (iter_init);
		}

		CCodeFunctionCall ccall;
		if (!ready) {
			ccall = new CCodeFunctionCall (new CCodeIdentifier (m.get_cname ()));
			ccall.add_argument (new CCodeIdentifier ("self"));
		} else {
			ccall = new CCodeFunctionCall (new CCodeIdentifier (m.get_finish_cname ()));
			ccall.add_argument (new CCodeCastExpression (new CCodeIdentifier ("source_object"), sym.get_cname () + "*"));
			ccall.add_argument (new CCodeIdentifier ("_res_"));
		}

		if (!ready) {
			foreach (FormalParameter param in m.get_parameters ()) {
				if (param.direction != ParameterDirection.IN) {
					continue;
				}

				var owned_type = param.variable_type.copy ();
				owned_type.value_owned = true;

				ccode.add_declaration (owned_type.get_cname (), new CCodeVariableDeclarator.zero (param.name, default_value_for_type (param.variable_type, true)));

				var array_type = param.variable_type as ArrayType;
				if (array_type != null) {
					for (int dim = 1; dim <= array_type.rank; dim++) {
						string length_cname = get_parameter_array_length_cname (param, dim);

						ccode.add_declaration ("int", new CCodeVariableDeclarator.zero (length_cname, new CCodeConstant ("0")));
					}
				}

				read_expression (param.variable_type, new CCodeIdentifier ("_arguments_iter"), new CCodeIdentifier (param.name), param);
			}
		}

		foreach (FormalParameter param in m.get_parameters ()) {
			if (param.direction == ParameterDirection.IN && !ready) {
				var st = param.variable_type.data_type as Struct;
				if (st != null && !st.is_simple_type ()) {
					ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (param.name)));
				} else {
					ccall.add_argument (new CCodeIdentifier (param.name));
				}
			} else if (param.direction == ParameterDirection.OUT && (!m.coroutine || ready)) {
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (param.name)));
			}

			var array_type = param.variable_type as ArrayType;
			if (array_type != null) {
				for (int dim = 1; dim <= array_type.rank; dim++) {
					string length_cname = get_parameter_array_length_cname (param, dim);

					if (param.direction == ParameterDirection.IN && !ready) {
						ccall.add_argument (new CCodeIdentifier (length_cname));
					} else if (param.direction == ParameterDirection.OUT && !no_reply && (!m.coroutine || ready)) {
						ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (length_cname)));
					}
				}
			}
		}

		if (!m.coroutine || ready) {
			if (!(m.return_type is VoidType)) {
				if (m.return_type.is_real_non_null_struct_type ()) {
					ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("result")));
				} else {
					var array_type = m.return_type as ArrayType;
					if (array_type != null) {
						for (int dim = 1; dim <= array_type.rank; dim++) {
							string length_cname = get_array_length_cname ("result", dim);

							ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (length_cname)));
						}
					}
				}
			}
		}

		if (m.coroutine && !ready) {
			ccall.add_argument (new CCodeCastExpression (new CCodeIdentifier (wrapper_name + "_ready"), "GAsyncReadyCallback"));

			var ref_call = new CCodeFunctionCall (new CCodeIdentifier ("g_object_ref"));
			ref_call.add_argument (new CCodeIdentifier ("invocation"));

			ccall.add_argument (ref_call);
		}

		if (!m.coroutine || ready) {
			if (m.get_error_types ().size > 0) {
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("error")));
			}
		}

		if (!no_reply && (!m.coroutine || ready)) {
			if (m.return_type is VoidType || m.return_type.is_real_non_null_struct_type ()) {
				ccode.add_expression (ccall);
			} else {
				ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("result"), ccall));
			}

			if (m.get_error_types ().size > 0) {
				ccode.open_if (new CCodeIdentifier ("error"));

				// g_dbus_method_invocation_return_gerror consumes reference
				var ref_invocation = new CCodeFunctionCall (new CCodeIdentifier ("g_object_ref"));
				ref_invocation.add_argument (new CCodeIdentifier ("invocation"));

				var return_error = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_method_invocation_return_gerror"));
				return_error.add_argument (ref_invocation);
				return_error.add_argument (new CCodeIdentifier ("error"));
				ccode.add_expression (return_error);

				ccode.add_return ();

				ccode.close ();
			}

			ccode.add_declaration ("GDBusMessage*", new CCodeVariableDeclarator ("_reply_message"));

			var message_expr = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_method_invocation_get_message"));
			message_expr.add_argument (new CCodeIdentifier ("invocation"));

			ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_message_new_method_reply"));
			ccall.add_argument (message_expr);
			ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("_reply_message"), ccall));

			ccode.add_declaration ("GVariant*", new CCodeVariableDeclarator ("_reply"));
			ccode.add_declaration ("GVariantBuilder", new CCodeVariableDeclarator ("_reply_builder"));

			var builder_init = new CCodeFunctionCall (new CCodeIdentifier ("g_variant_builder_init"));
			builder_init.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_reply_builder")));
			builder_init.add_argument (new CCodeIdentifier ("G_VARIANT_TYPE_TUPLE"));
			ccode.add_expression (builder_init);

			ccode.add_declaration ("GUnixFDList", new CCodeVariableDeclarator ("*_fd_list"));
			ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("_fd_list"), new CCodeFunctionCall (new CCodeIdentifier ("g_unix_fd_list_new"))));

			foreach (FormalParameter param in m.get_parameters ()) {
				if (param.direction != ParameterDirection.OUT) {
					continue;
				}

				var owned_type = param.variable_type.copy ();
				owned_type.value_owned = true;

				ccode.add_declaration (owned_type.get_cname (), new CCodeVariableDeclarator.zero (param.name, default_value_for_type (param.variable_type, true)));

				var array_type = param.variable_type as ArrayType;
				if (array_type != null) {
					for (int dim = 1; dim <= array_type.rank; dim++) {
						string length_cname = get_parameter_array_length_cname (param, dim);

						ccode.add_declaration ("int", new CCodeVariableDeclarator.zero (length_cname, new CCodeConstant ("0")));
					}
				}

				send_dbus_value (param.variable_type, new CCodeIdentifier ("_reply_builder"), new CCodeIdentifier (param.name), param);
			}

			if (!(m.return_type is VoidType)) {
				if (m.return_type.is_real_non_null_struct_type ()) {
					ccode.add_declaration (m.return_type.get_cname (), new CCodeVariableDeclarator.zero ("result", default_value_for_type (m.return_type, true)));

					send_dbus_value (m.return_type, new CCodeIdentifier ("_reply_builder"), new CCodeIdentifier ("result"), m);

					if (requires_destroy (m.return_type)) {
						// keep local alive (symbol_reference is weak)
						// space before `result' is work around to not trigger
						// variable renaming, we really mean C identifier `result' here
						var local = new LocalVariable (m.return_type, " result");
						var ma = new MemberAccess.simple ("result");
						ma.symbol_reference = local;
						ma.value_type = local.variable_type.copy ();
						visit_member_access (ma);
						ccode.add_expression (get_unref_expression (new CCodeIdentifier ("result"), m.return_type, ma));
					}
				} else {
					ccode.add_declaration (m.return_type.get_cname (), new CCodeVariableDeclarator ("result"));

					var array_type = m.return_type as ArrayType;
					if (array_type != null) {
						for (int dim = 1; dim <= array_type.rank; dim++) {
							string length_cname = get_array_length_cname ("result", dim);

							ccode.add_declaration ("int", new CCodeVariableDeclarator.zero (length_cname, new CCodeConstant ("0")));
						}
					}

					send_dbus_value (m.return_type, new CCodeIdentifier ("_reply_builder"), new CCodeIdentifier ("result"), m);

					if (requires_destroy (m.return_type)) {
						// keep local alive (symbol_reference is weak)
						// space before `result' is work around to not trigger
						// variable renaming, we really mean C identifier `result' here
						var local = new LocalVariable (m.return_type, " result");
						var ma = new MemberAccess.simple ("result");
						ma.symbol_reference = local;
						ma.value_type = local.variable_type.copy ();
						visit_member_access (ma);
						ccode.add_expression (get_unref_expression (new CCodeIdentifier ("result"), m.return_type, ma));
					}
				}
			}

			var builder_end = new CCodeFunctionCall (new CCodeIdentifier ("g_variant_builder_end"));
			builder_end.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_reply_builder")));
			ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("_reply"), builder_end));

			var set_body = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_message_set_body"));
			set_body.add_argument (new CCodeIdentifier ("_reply_message"));
			set_body.add_argument (new CCodeIdentifier ("_reply"));
			ccode.add_expression (set_body);

			ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_message_set_unix_fd_list"));
			ccall.add_argument (new CCodeIdentifier ("_reply_message"));
			ccall.add_argument (new CCodeIdentifier ("_fd_list"));
			ccode.add_expression (ccall);

			ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_object_unref"));
			ccall.add_argument (new CCodeIdentifier ("_fd_list"));
			ccode.add_expression (ccall);
		} else {
			ccode.add_expression (ccall);
		}

		foreach (FormalParameter param in m.get_parameters ()) {
			if ((param.direction == ParameterDirection.IN && !ready) ||
			    (param.direction == ParameterDirection.OUT && !no_reply && (!m.coroutine || ready))) {
				var owned_type = param.variable_type.copy ();
				owned_type.value_owned = true;

				if (requires_destroy (owned_type)) {
					// keep local alive (symbol_reference is weak)
					var local = new LocalVariable (owned_type, param.name);
					var ma = new MemberAccess.simple (param.name);
					ma.symbol_reference = local;
					ma.value_type = local.variable_type.copy ();
					visit_member_access (ma);
					ccode.add_expression (get_unref_expression (new CCodeIdentifier (param.name), owned_type, ma));
				}
			}
		}

		if (!no_reply && (!m.coroutine || ready)) {
			var return_value = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_connection_send_message"));
			return_value.add_argument (connection);
			return_value.add_argument (new CCodeIdentifier ("_reply_message"));
			return_value.add_argument (new CCodeConstant ("G_DBUS_SEND_MESSAGE_FLAGS_NONE"));
			return_value.add_argument (new CCodeConstant ("NULL"));
			return_value.add_argument (new CCodeConstant ("NULL"));
			ccode.add_expression (return_value);

			if (ready) {
				var unref_call = new CCodeFunctionCall (new CCodeIdentifier ("g_object_unref"));
				unref_call.add_argument (new CCodeIdentifier ("invocation"));
				ccode.add_expression (unref_call);
			}

			var unref_call = new CCodeFunctionCall (new CCodeIdentifier ("g_object_unref"));
			unref_call.add_argument (new CCodeIdentifier ("_reply_message"));
			ccode.add_expression (unref_call);
		}

		pop_function ();

		cfile.add_function_declaration (function);
		cfile.add_function (function);

		if (m.coroutine && !ready) {
			// generate ready function
			generate_dbus_wrapper (m, sym, true);
		}

		return wrapper_name;
	}

	string generate_dbus_signal_wrapper (Signal sig, ObjectTypeSymbol sym, string dbus_iface_name) {
		string wrapper_name = "_dbus_%s_%s".printf (sym.get_lower_case_cname (), sig.get_cname ());

		var function = new CCodeFunction (wrapper_name, "void");
		function.modifiers = CCodeModifiers.STATIC;

		function.add_parameter (new CCodeFormalParameter ("_sender", "GObject*"));

		foreach (var param in sig.get_parameters ()) {
			// ensure ccodenode of parameter is set
			var cparam = generate_parameter (param, cfile, new HashMap<int,CCodeFormalParameter> (), null);

			function.add_parameter (cparam);
			if (param.variable_type is ArrayType) {
				var array_type = (ArrayType) param.variable_type;
				for (int dim = 1; dim <= array_type.rank; dim++) {
					function.add_parameter (new CCodeFormalParameter (get_parameter_array_length_cname (param, dim), "int"));
				}
			}
		}

		function.add_parameter (new CCodeFormalParameter ("_data", "gpointer*"));

		push_function (function);

		ccode.add_declaration ("GDBusConnection *", new CCodeVariableDeclarator ("_connection", new CCodeElementAccess (new CCodeIdentifier ("_data"), new CCodeConstant ("1"))));
		ccode.add_declaration ("const gchar *", new CCodeVariableDeclarator ("_path", new CCodeElementAccess (new CCodeIdentifier ("_data"), new CCodeConstant ("2"))));
		ccode.add_declaration ("GVariant", new CCodeVariableDeclarator ("*_arguments"));
		ccode.add_declaration ("GVariantBuilder", new CCodeVariableDeclarator ("_arguments_builder"));

		var builder_init = new CCodeFunctionCall (new CCodeIdentifier ("g_variant_builder_init"));
		builder_init.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_arguments_builder")));
		builder_init.add_argument (new CCodeIdentifier ("G_VARIANT_TYPE_TUPLE"));
		ccode.add_expression (builder_init);

		foreach (FormalParameter param in sig.get_parameters ()) {
			CCodeExpression expr = new CCodeIdentifier (param.name);
			if (param.variable_type.is_real_struct_type ()) {
				expr = new CCodeUnaryExpression (CCodeUnaryOperator.POINTER_INDIRECTION, expr);
			}
			write_expression (param.variable_type, new CCodeIdentifier ("_arguments_builder"), expr, param);
		}

		var builder_end = new CCodeFunctionCall (new CCodeIdentifier ("g_variant_builder_end"));
		builder_end.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_arguments_builder")));
		ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("_arguments"), builder_end));

		var ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_connection_emit_signal"));
		ccall.add_argument (new CCodeIdentifier ("_connection"));
		ccall.add_argument (new CCodeConstant ("NULL"));
		ccall.add_argument (new CCodeIdentifier ("_path"));
		ccall.add_argument (new CCodeConstant ("\"%s\"".printf (dbus_iface_name)));
		ccall.add_argument (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (sig))));
		ccall.add_argument (new CCodeIdentifier ("_arguments"));
		ccall.add_argument (new CCodeConstant ("NULL"));
		ccode.add_expression (ccall);

		pop_function ();

		cfile.add_function_declaration (function);
		cfile.add_function (function);

		return wrapper_name;
	}

	string generate_dbus_property_get_wrapper (Property prop, ObjectTypeSymbol sym) {
		string wrapper_name = "_dbus_%s".printf (prop.get_accessor.get_cname ());

		var function = new CCodeFunction (wrapper_name, "GVariant*");
		function.modifiers = CCodeModifiers.STATIC;
		function.add_parameter (new CCodeFormalParameter ("self", sym.get_cname () + "*"));

		push_function (function);

		var ccall = new CCodeFunctionCall (new CCodeIdentifier (prop.get_accessor.get_cname ()));
		ccall.add_argument (new CCodeIdentifier ("self"));

		if (prop.get_accessor.value_type.is_real_non_null_struct_type ()) {
			ccode.add_declaration (prop.get_accessor.value_type.get_cname (), new CCodeVariableDeclarator.zero ("result", default_value_for_type (prop.get_accessor.value_type, true)));
			ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("result")));

			ccode.add_expression (ccall);
		} else {
			ccode.add_declaration (prop.get_accessor.value_type.get_cname (), new CCodeVariableDeclarator ("result"));
			ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("result"), ccall));

			var array_type = prop.get_accessor.value_type as ArrayType;
			if (array_type != null) {
				for (int dim = 1; dim <= array_type.rank; dim++) {
					string length_cname = get_array_length_cname ("result", dim);

					ccode.add_declaration ("int", new CCodeVariableDeclarator (length_cname));
					ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier (length_cname)));
				}
			}
		}

		var reply_expr = serialize_expression (prop.get_accessor.value_type, new CCodeIdentifier ("result"));

		ccode.add_declaration ("GVariant*", new CCodeVariableDeclarator ("_reply"));
		ccode.add_expression (new CCodeAssignment (new CCodeIdentifier ("_reply"), reply_expr));

		if (requires_destroy (prop.get_accessor.value_type)) {
			// keep local alive (symbol_reference is weak)
			// space before `result' is work around to not trigger
			// variable renaming, we really mean C identifier `result' here
			var local = new LocalVariable (prop.get_accessor.value_type, " result");
			var ma = new MemberAccess.simple ("result");
			ma.symbol_reference = local;
			ma.value_type = local.variable_type.copy ();
			visit_member_access (ma);
			ccode.add_expression (get_unref_expression (new CCodeIdentifier ("result"), prop.get_accessor.value_type, ma));
		}

		ccode.add_return (new CCodeIdentifier ("_reply"));

		pop_function ();

		cfile.add_function_declaration (function);
		cfile.add_function (function);

		return wrapper_name;
	}

	string generate_dbus_property_set_wrapper (Property prop, ObjectTypeSymbol sym) {
		string wrapper_name = "_dbus_%s".printf (prop.set_accessor.get_cname ());

		var function = new CCodeFunction (wrapper_name);
		function.modifiers = CCodeModifiers.STATIC;
		function.add_parameter (new CCodeFormalParameter ("self", sym.get_cname () + "*"));
		function.add_parameter (new CCodeFormalParameter ("_value", "GVariant*"));

		push_function (function);

		var ccall = new CCodeFunctionCall (new CCodeIdentifier (prop.set_accessor.get_cname ()));
		ccall.add_argument (new CCodeIdentifier ("self"));

		var owned_type = prop.property_type.copy ();
		owned_type.value_owned = true;

		ccode.add_declaration (owned_type.get_cname (), new CCodeVariableDeclarator.zero ("value", default_value_for_type (prop.property_type, true)));

		var st = prop.property_type.data_type as Struct;
		if (st != null && !st.is_simple_type ()) {
			ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("value")));
		} else {
			ccall.add_argument (new CCodeIdentifier ("value"));

			var array_type = prop.property_type as ArrayType;
			if (array_type != null) {
				for (int dim = 1; dim <= array_type.rank; dim++) {
					ccode.add_declaration ("int", new CCodeVariableDeclarator (get_array_length_cname ("value", dim)));
					ccall.add_argument (new CCodeIdentifier (get_array_length_cname ("value", dim)));
				}
			}
		}

		var target = new CCodeIdentifier ("value");
		var expr = deserialize_expression (prop.property_type, new CCodeIdentifier ("_value"), target);
		ccode.add_expression (new CCodeAssignment (target, expr));

		ccode.add_expression (ccall);

		if (requires_destroy (owned_type)) {
			// keep local alive (symbol_reference is weak)
			var local = new LocalVariable (owned_type, "value");
			var ma = new MemberAccess.simple ("value");
			ma.symbol_reference = local;
			ma.value_type = local.variable_type.copy ();
			visit_member_access (ma);
			ccode.add_expression (get_unref_expression (new CCodeIdentifier ("value"), owned_type, ma));
		}

		pop_function ();

		cfile.add_function_declaration (function);
		cfile.add_function (function);

		return wrapper_name;
	}

	void handle_signals (ObjectTypeSymbol sym, CCodeBlock block) {
		string dbus_iface_name = get_dbus_name (sym);
		if (dbus_iface_name == null) {
			return;
		}

		foreach (Signal sig in sym.get_signals ()) {
			if (sig.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (sig)) {
				continue;
			}

			var connect = new CCodeFunctionCall (new CCodeIdentifier ("g_signal_connect"));
			connect.add_argument (new CCodeIdentifier ("object"));
			connect.add_argument (sig.get_canonical_cconstant ());
			connect.add_argument (new CCodeCastExpression (new CCodeIdentifier (generate_dbus_signal_wrapper (sig, sym, dbus_iface_name)), "GCallback"));
			connect.add_argument (new CCodeIdentifier ("data"));
			block.add_statement (new CCodeExpressionStatement (connect));
		}
	}

	void generate_interface_method_call_function (ObjectTypeSymbol sym) {
		var cfunc = new CCodeFunction (sym.get_lower_case_cprefix () + "dbus_interface_method_call", "void");
		cfunc.add_parameter (new CCodeFormalParameter ("connection", "GDBusConnection*"));
		cfunc.add_parameter (new CCodeFormalParameter ("sender", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("object_path", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("interface_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("method_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("parameters", "GVariant*"));
		cfunc.add_parameter (new CCodeFormalParameter ("invocation", "GDBusMethodInvocation*"));
		cfunc.add_parameter (new CCodeFormalParameter ("user_data", "gpointer"));

		cfunc.modifiers |= CCodeModifiers.STATIC;

		push_function (cfunc);

		ccode.add_declaration ("gpointer*", new CCodeVariableDeclarator ("data", new CCodeIdentifier ("user_data")));
		ccode.add_declaration ("gpointer", new CCodeVariableDeclarator ("object", new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("0"))));

		bool first = true;

		foreach (Method m in sym.get_methods ()) {
			if (m is CreationMethod || m.binding != MemberBinding.INSTANCE
			    || m.overrides || m.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (m)) {
				continue;
			}

			var ccheck = new CCodeFunctionCall (new CCodeIdentifier ("strcmp"));
			ccheck.add_argument (new CCodeIdentifier ("method_name"));
			ccheck.add_argument (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (m))));

			if (first) {
				ccode.open_if (new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, ccheck, new CCodeConstant ("0")));
				first = false;
			} else {
				ccode.else_if (new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, ccheck, new CCodeConstant ("0")));
			}

			var ccall = new CCodeFunctionCall (new CCodeIdentifier (generate_dbus_wrapper (m, sym)));
			ccall.add_argument (new CCodeIdentifier ("object"));
			ccall.add_argument (new CCodeIdentifier ("parameters"));
			ccall.add_argument (new CCodeIdentifier ("invocation"));
			ccode.add_expression (ccall);
		}

		ccode.close ();

		var ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_object_unref"));
		ccall.add_argument (new CCodeIdentifier ("invocation"));
		ccode.add_expression (ccall);

		pop_function ();

		cfile.add_function_declaration (cfunc);
		cfile.add_function (cfunc);
	}

	void generate_interface_get_property_function (ObjectTypeSymbol sym) {
		var cfunc = new CCodeFunction (sym.get_lower_case_cprefix () + "dbus_interface_get_property", "GVariant*");
		cfunc.add_parameter (new CCodeFormalParameter ("connection", "GDBusConnection*"));
		cfunc.add_parameter (new CCodeFormalParameter ("sender", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("object_path", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("interface_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("property_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("error", "GError**"));
		cfunc.add_parameter (new CCodeFormalParameter ("user_data", "gpointer"));

		cfunc.modifiers |= CCodeModifiers.STATIC;

		cfile.add_function_declaration (cfunc);

		var block = new CCodeBlock ();
		cfunc.block = block;

		var cdecl = new CCodeDeclaration ("gpointer*");
		cdecl.add_declarator (new CCodeVariableDeclarator ("data", new CCodeIdentifier ("user_data")));
		block.add_statement (cdecl);

		cdecl = new CCodeDeclaration ("gpointer");
		cdecl.add_declarator (new CCodeVariableDeclarator ("object", new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("0"))));
		block.add_statement (cdecl);

		CCodeIfStatement clastif = null;

		foreach (Property prop in sym.get_properties ()) {
			if (prop.binding != MemberBinding.INSTANCE
			    || prop.overrides || prop.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (prop)) {
				continue;
			}
			if (prop.get_accessor == null) {
				continue;
			}

			var ccheck = new CCodeFunctionCall (new CCodeIdentifier ("strcmp"));
			ccheck.add_argument (new CCodeIdentifier ("property_name"));
			ccheck.add_argument (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (prop))));

			var callblock = new CCodeBlock ();

			var ccall = new CCodeFunctionCall (new CCodeIdentifier (generate_dbus_property_get_wrapper (prop, sym)));
			ccall.add_argument (new CCodeIdentifier ("object"));

			callblock.add_statement (new CCodeReturnStatement (ccall));

			var cif = new CCodeIfStatement (new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, ccheck, new CCodeConstant ("0")), callblock);
			if (clastif == null) {
				block.add_statement (cif);
			} else {
				clastif.false_statement = cif;
			}

			clastif = cif;
		}

		block.add_statement (new CCodeReturnStatement (new CCodeConstant ("NULL")));

		cfile.add_function (cfunc);
	}

	void generate_interface_set_property_function (ObjectTypeSymbol sym) {
		var cfunc = new CCodeFunction (sym.get_lower_case_cprefix () + "dbus_interface_set_property", "gboolean");
		cfunc.add_parameter (new CCodeFormalParameter ("connection", "GDBusConnection*"));
		cfunc.add_parameter (new CCodeFormalParameter ("sender", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("object_path", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("interface_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("property_name", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("value", "GVariant*"));
		cfunc.add_parameter (new CCodeFormalParameter ("error", "GError**"));
		cfunc.add_parameter (new CCodeFormalParameter ("user_data", "gpointer"));

		cfunc.modifiers |= CCodeModifiers.STATIC;

		cfile.add_function_declaration (cfunc);

		var block = new CCodeBlock ();
		cfunc.block = block;

		var cdecl = new CCodeDeclaration ("gpointer*");
		cdecl.add_declarator (new CCodeVariableDeclarator ("data", new CCodeIdentifier ("user_data")));
		block.add_statement (cdecl);

		cdecl = new CCodeDeclaration ("gpointer");
		cdecl.add_declarator (new CCodeVariableDeclarator ("object", new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("0"))));
		block.add_statement (cdecl);

		CCodeIfStatement clastif = null;

		foreach (Property prop in sym.get_properties ()) {
			if (prop.binding != MemberBinding.INSTANCE
			    || prop.overrides || prop.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (prop)) {
				continue;
			}
			if (prop.set_accessor == null) {
				continue;
			}

			var ccheck = new CCodeFunctionCall (new CCodeIdentifier ("strcmp"));
			ccheck.add_argument (new CCodeIdentifier ("property_name"));
			ccheck.add_argument (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (prop))));

			var callblock = new CCodeBlock ();

			var ccall = new CCodeFunctionCall (new CCodeIdentifier (generate_dbus_property_set_wrapper (prop, sym)));
			ccall.add_argument (new CCodeIdentifier ("object"));
			ccall.add_argument (new CCodeIdentifier ("value"));

			callblock.add_statement (new CCodeExpressionStatement (ccall));
			callblock.add_statement (new CCodeReturnStatement (new CCodeConstant ("TRUE")));

			var cif = new CCodeIfStatement (new CCodeBinaryExpression (CCodeBinaryOperator.EQUALITY, ccheck, new CCodeConstant ("0")), callblock);
			if (clastif == null) {
				block.add_statement (cif);
			} else {
				clastif.false_statement = cif;
			}

			clastif = cif;
		}

		block.add_statement (new CCodeReturnStatement (new CCodeConstant ("FALSE")));

		cfile.add_function (cfunc);
	}

	CCodeExpression get_method_info (ObjectTypeSymbol sym) {
		var infos = new CCodeInitializerList ();

		foreach (Method m in sym.get_methods ()) {
			if (m is CreationMethod || m.binding != MemberBinding.INSTANCE
			    || m.overrides || m.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (m)) {
				continue;
			}

			var in_args_info = new CCodeInitializerList ();
			var out_args_info = new CCodeInitializerList ();

			foreach (FormalParameter param in m.get_parameters ()) {
				var info = new CCodeInitializerList ();
				info.append (new CCodeConstant ("-1"));
				info.append (new CCodeConstant ("\"%s\"".printf (param.name)));
				info.append (new CCodeConstant ("\"%s\"".printf (get_type_signature (param.variable_type, param))));

				var cdecl = new CCodeDeclaration ("const GDBusArgInfo");
				cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_" + param.name, info));
				cdecl.modifiers = CCodeModifiers.STATIC;
				cfile.add_constant_declaration (cdecl);

				if (param.direction == ParameterDirection.IN) {
					in_args_info.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_" + param.name)));
				} else {
					out_args_info.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_" + param.name)));
				}
			}

			if (!(m.return_type is VoidType)) {
				var info = new CCodeInitializerList ();
				info.append (new CCodeConstant ("-1"));
				info.append (new CCodeConstant ("\"%s\"".printf (dbus_result_name (m))));
				info.append (new CCodeConstant ("\"%s\"".printf (get_type_signature (m.return_type, m))));

				var cdecl = new CCodeDeclaration ("const GDBusArgInfo");
				cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_result", info));
				cdecl.modifiers = CCodeModifiers.STATIC;
				cfile.add_constant_declaration (cdecl);

				out_args_info.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_result")));
			}

			in_args_info.append (new CCodeConstant ("NULL"));
			out_args_info.append (new CCodeConstant ("NULL"));

			var cdecl = new CCodeDeclaration ("const GDBusArgInfo * const");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_in[]", in_args_info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			cdecl = new CCodeDeclaration ("const GDBusArgInfo * const");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_out[]", out_args_info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			var info = new CCodeInitializerList ();
			info.append (new CCodeConstant ("-1"));
			info.append (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (m))));
			info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_in")), "GDBusArgInfo **"));
			info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + m.name + "_out")), "GDBusArgInfo **"));

			cdecl = new CCodeDeclaration ("const GDBusMethodInfo");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_method_info_" + m.name, info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			infos.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_method_info_" + m.name)));
		}

		infos.append (new CCodeConstant ("NULL"));

		var cdecl = new CCodeDeclaration ("const GDBusMethodInfo * const");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_method_info[]", infos));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_constant_declaration (cdecl);

		return new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_method_info");
	}

	CCodeExpression get_signal_info (ObjectTypeSymbol sym) {
		var infos = new CCodeInitializerList ();

		foreach (Signal sig in sym.get_signals ()) {
			if (sig.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (sig)) {
				continue;
			}

			var args_info = new CCodeInitializerList ();

			foreach (FormalParameter param in sig.get_parameters ()) {
				var info = new CCodeInitializerList ();
				info.append (new CCodeConstant ("-1"));
				info.append (new CCodeConstant ("\"%s\"".printf (param.name)));
				info.append (new CCodeConstant ("\"%s\"".printf (get_type_signature (param.variable_type, param))));

				var cdecl = new CCodeDeclaration ("const GDBusArgInfo");
				cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + sig.get_cname () + "_" + param.name, info));
				cdecl.modifiers = CCodeModifiers.STATIC;
				cfile.add_constant_declaration (cdecl);

				args_info.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + sig.get_cname () + "_" + param.name)));
			}

			args_info.append (new CCodeConstant ("NULL"));

			var cdecl = new CCodeDeclaration ("const GDBusArgInfo * const");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + sig.get_cname () + "[]", args_info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			var info = new CCodeInitializerList ();
			info.append (new CCodeConstant ("-1"));
			info.append (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (sig))));
			info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_arg_info_" + sig.get_cname ())), "GDBusArgInfo **"));

			cdecl = new CCodeDeclaration ("const GDBusSignalInfo");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_signal_info_" + sig.get_cname (), info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			infos.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_signal_info_" + sig.get_cname ())));
		}

		infos.append (new CCodeConstant ("NULL"));

		var cdecl = new CCodeDeclaration ("const GDBusSignalInfo * const");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_signal_info[]", infos));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_constant_declaration (cdecl);

		return new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_signal_info");
	}

	CCodeExpression get_property_info (ObjectTypeSymbol sym) {
		var infos = new CCodeInitializerList ();

		foreach (Property prop in sym.get_properties ()) {
			if (prop.binding != MemberBinding.INSTANCE
			    || prop.overrides || prop.access != SymbolAccessibility.PUBLIC) {
				continue;
			}
			if (!is_dbus_visible (prop)) {
				continue;
			}

			var info = new CCodeInitializerList ();
			info.append (new CCodeConstant ("-1"));
			info.append (new CCodeConstant ("\"%s\"".printf (get_dbus_name_for_member (prop))));
			info.append (new CCodeConstant ("\"%s\"".printf (get_type_signature (prop.property_type, prop))));
			if (prop.get_accessor != null && prop.set_accessor != null) {
				info.append (new CCodeConstant ("G_DBUS_PROPERTY_INFO_FLAGS_READABLE | G_DBUS_PROPERTY_INFO_FLAGS_WRITABLE"));
			} else if (prop.get_accessor != null) {
				info.append (new CCodeConstant ("G_DBUS_PROPERTY_INFO_FLAGS_READABLE"));
			} else if (prop.set_accessor != null) {
				info.append (new CCodeConstant ("G_DBUS_PROPERTY_INFO_FLAGS_WRITABLE"));
			} else {
				info.append (new CCodeConstant ("G_DBUS_PROPERTY_INFO_FLAGS_NONE"));
			}

			var cdecl = new CCodeDeclaration ("const GDBusPropertyInfo");
			cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_property_info_" + prop.name, info));
			cdecl.modifiers = CCodeModifiers.STATIC;
			cfile.add_constant_declaration (cdecl);

			infos.append (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_property_info_" + prop.name)));
		}

		infos.append (new CCodeConstant ("NULL"));

		var cdecl = new CCodeDeclaration ("const GDBusPropertyInfo * const");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_property_info[]", infos));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_constant_declaration (cdecl);

		return new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_property_info");
	}

	CCodeExpression get_interface_info (ObjectTypeSymbol sym) {
		var info = new CCodeInitializerList ();
		info.append (new CCodeConstant ("-1"));
		info.append (new CCodeConstant ("\"%s\"".printf (get_dbus_name (sym))));
		info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_method_info (sym)), "GDBusMethodInfo **"));
		info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_signal_info (sym)), "GDBusSignalInfo **"));
		info.append (new CCodeCastExpression (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_property_info (sym)), "GDBusPropertyInfo **"));

		var cdecl = new CCodeDeclaration ("const GDBusInterfaceInfo");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_interface_info", info));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_constant_declaration (cdecl);

		return new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_interface_info");
	}

	CCodeExpression get_interface_vtable (ObjectTypeSymbol sym) {
		var vtable = new CCodeInitializerList ();
		vtable.append (new CCodeIdentifier (sym.get_lower_case_cprefix () + "dbus_interface_method_call"));
		vtable.append (new CCodeIdentifier (sym.get_lower_case_cprefix () + "dbus_interface_get_property"));
		vtable.append (new CCodeIdentifier (sym.get_lower_case_cprefix () + "dbus_interface_set_property"));

		generate_interface_method_call_function (sym);
		generate_interface_get_property_function (sym);
		generate_interface_set_property_function (sym);

		var cdecl = new CCodeDeclaration ("const GDBusInterfaceVTable");
		cdecl.add_declarator (new CCodeVariableDeclarator ("_" + sym.get_lower_case_cprefix () + "dbus_interface_vtable", vtable));
		cdecl.modifiers = CCodeModifiers.STATIC;
		cfile.add_constant_declaration (cdecl);

		return new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "dbus_interface_vtable");
	}

	public override void visit_method_call (MethodCall expr) {
		var mtype = expr.call.value_type as MethodType;
		if (mtype == null || mtype.method_symbol.get_cname () != "g_dbus_connection_register_object") {
			base.visit_method_call (expr);
			return;
		}

		var ma = (MemberAccess) expr.call;
		var type_arg = (ObjectType) ma.get_type_arguments ().get (0);

		if (get_dbus_name (type_arg.type_symbol) == null) {
			Report.error (expr.source_reference, "DBusConnection.register_object requires type argument with [DBus (name = ...)] attribute");
			return;
		}

		var args = expr.get_argument_list ();
		var path_arg = args[0];
		var obj_arg = args[1];

		// method can fail
		current_method_inner_error = true;

		var cregister = new CCodeFunctionCall (new CCodeIdentifier ("%sregister_object".printf (type_arg.type_symbol.get_lower_case_cprefix ())));
		cregister.add_argument (get_cvalue (obj_arg));
		cregister.add_argument (get_cvalue (ma.inner));
		cregister.add_argument (get_cvalue (path_arg));
		cregister.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_variable_cexpression ("_inner_error_")));
		set_cvalue (expr, cregister);
	}

	public override void generate_class_declaration (Class cl, CCodeFile decl_space) {
		base.generate_class_declaration (cl, decl_space);

		generate_object_type_symbol_declaration (cl, decl_space);
	}

	public override void generate_interface_declaration (Interface iface, CCodeFile decl_space) {
		base.generate_interface_declaration (iface, decl_space);

		generate_object_type_symbol_declaration (iface, decl_space);
	}

	public override void visit_class (Class cl) {
		base.visit_class (cl);

		visit_object_type_symbol (cl);
	}

	public override void visit_interface (Interface iface) {
		base.visit_interface (iface);

		visit_object_type_symbol (iface);
	}

	void generate_object_type_symbol_declaration (ObjectTypeSymbol sym, CCodeFile decl_space) {
		string dbus_iface_name = get_dbus_name (sym);
		if (dbus_iface_name == null) {
			return;
		}

		string register_object_name = "%sregister_object".printf (sym.get_lower_case_cprefix ());

		if (add_symbol_declaration (decl_space, sym, register_object_name)) {
			return;
		}

		// declare register_object function
		var cfunc = new CCodeFunction (register_object_name, "guint");
		cfunc.add_parameter (new CCodeFormalParameter ("object", "void*"));
		cfunc.add_parameter (new CCodeFormalParameter ("connection", "GDBusConnection*"));
		cfunc.add_parameter (new CCodeFormalParameter ("path", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("error", "GError**"));
		if (sym.is_private_symbol ()) {
			cfunc.modifiers |= CCodeModifiers.STATIC;
		}
		decl_space.add_function_declaration (cfunc);
	}

	void visit_object_type_symbol (ObjectTypeSymbol sym) {
		// only support registering a single D-Bus interface at a time (unlike old D-Bus support)
		// however, register_object can be invoked multiple times for the same object path with different interfaces
		string dbus_iface_name = get_dbus_name (sym);
		if (dbus_iface_name == null) {
			return;
		}

		cfile.add_include ("gio/gio.h");

		var cfunc = new CCodeFunction (sym.get_lower_case_cprefix () + "register_object", "guint");
		cfunc.add_parameter (new CCodeFormalParameter ("object", "gpointer"));
		cfunc.add_parameter (new CCodeFormalParameter ("connection", "GDBusConnection*"));
		cfunc.add_parameter (new CCodeFormalParameter ("path", "const gchar*"));
		cfunc.add_parameter (new CCodeFormalParameter ("error", "GError**"));
		if (sym.is_private_symbol ()) {
			cfunc.modifiers |= CCodeModifiers.STATIC;
		}

		var block = new CCodeBlock ();
		cfunc.block = block;

		var cdecl = new CCodeDeclaration ("guint");
		cdecl.add_declarator (new CCodeVariableDeclarator ("result"));
		block.add_statement (cdecl);


		// data consists of 3 pointers: object, connection, path
		cdecl = new CCodeDeclaration ("gpointer");
		cdecl.add_declarator (new CCodeVariableDeclarator ("*data"));
		block.add_statement (cdecl);

		var alloc_data = new CCodeFunctionCall (new CCodeIdentifier ("g_new"));
		alloc_data.add_argument (new CCodeIdentifier ("gpointer"));
		alloc_data.add_argument (new CCodeConstant ("3"));
		block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("data"), alloc_data)));

		var ref_object = new CCodeFunctionCall (new CCodeIdentifier (sym.get_ref_function ()));
		ref_object.add_argument (new CCodeIdentifier ("object"));
		block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("0")), ref_object)));

		ref_object = new CCodeFunctionCall (new CCodeIdentifier ("g_object_ref"));
		ref_object.add_argument (new CCodeIdentifier ("connection"));
		block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("1")), ref_object)));

		var dup_path = new CCodeFunctionCall (new CCodeIdentifier ("g_strdup"));
		dup_path.add_argument (new CCodeIdentifier ("path"));
		block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("2")), dup_path)));


		var cregister = new CCodeFunctionCall (new CCodeIdentifier ("g_dbus_connection_register_object"));
		cregister.add_argument (new CCodeIdentifier ("connection"));
		cregister.add_argument (new CCodeIdentifier ("path"));

		cregister.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_interface_info (sym)));
		cregister.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, get_interface_vtable (sym)));

		cregister.add_argument (new CCodeIdentifier ("data"));
		cregister.add_argument (new CCodeIdentifier ("_" + sym.get_lower_case_cprefix () + "unregister_object"));
		cregister.add_argument (new CCodeIdentifier ("error"));

		block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeIdentifier ("result"), cregister)));

		var error_block = new CCodeBlock ();
		error_block.add_statement (new CCodeReturnStatement (new CCodeConstant ("0")));
		block.add_statement (new CCodeIfStatement (new CCodeUnaryExpression (CCodeUnaryOperator.LOGICAL_NEGATION, new CCodeIdentifier ("result")), error_block));

		handle_signals (sym, block);

		block.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("result")));

		cfile.add_function (cfunc);


		cfunc = new CCodeFunction ("_" + sym.get_lower_case_cprefix () + "unregister_object");
		cfunc.add_parameter (new CCodeFormalParameter ("user_data", "gpointer"));
		cfunc.modifiers |= CCodeModifiers.STATIC;
		cfile.add_function_declaration (cfunc);

		block = new CCodeBlock ();
		cfunc.block = block;

		cdecl = new CCodeDeclaration ("gpointer*");
		cdecl.add_declarator (new CCodeVariableDeclarator ("data", new CCodeIdentifier ("user_data")));
		block.add_statement (cdecl);

		var unref_object = new CCodeFunctionCall (new CCodeIdentifier (sym.get_unref_function ()));
		unref_object.add_argument (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("0")));
		block.add_statement (new CCodeExpressionStatement (unref_object));

		unref_object = new CCodeFunctionCall (new CCodeIdentifier ("g_object_unref"));
		unref_object.add_argument (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("1")));
		block.add_statement (new CCodeExpressionStatement (unref_object));

		var free_path = new CCodeFunctionCall (new CCodeIdentifier ("g_free"));
		free_path.add_argument (new CCodeElementAccess (new CCodeIdentifier ("data"), new CCodeConstant ("2")));
		block.add_statement (new CCodeExpressionStatement (free_path));

		var free_data = new CCodeFunctionCall (new CCodeIdentifier ("g_free"));
		free_data.add_argument (new CCodeIdentifier ("data"));
		block.add_statement (new CCodeExpressionStatement (free_data));

		cfile.add_function (cfunc);
	}
}
