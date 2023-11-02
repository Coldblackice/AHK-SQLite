#Requires Autohotkey v2.0+ ; prefer 64-Bit
#Include <v2\Yunit\Yunit>
#Include <v2\Yunit\Window>

#Include .\..\lib\interfaces\SQLite3.ahk

Yunit.Use(YunitWindow).Test(tInterface)

class tInterface
{
	static flags := SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_MEMORY

	t1check_module_is_loaded_automatically() => Yunit.Assert(SQLite3.hModule, 'module was not loaded')
	t2check_properties_are_setup()
	{
		props := Map(
			'hModule', 'Integer',
			'bin',     'String',
			'dllPath', 'String',
			'ptrs',    'Map'
		)

		for prop,prop_type in props
		{
			Yunit.Assert(SQLite3.HasOwnProp(prop), prop ' was not initialized')
			Yunit.Assert( Type(SQLite3.%prop%) == prop_type, prop ' has unexpected type ' prop_type)
		}
	}
	t3version_strings()
	{
		Yunit.Assert(SQLite3.sourceid() == SQLITE_SOURCE_ID, 'source ids dont match')
		Yunit.Assert(SQLite3.libversion() == SQLITE_VERSION, 'version strings dont match')
		Yunit.Assert(SQLite3.libversion_number() = SQLITE_VERSION_NUMBER, 'version numbers dont match')
	}
	class t1ValidInput
	{
		test1_open_v2()
		{
			res := SQLite3.open_v2('test.db', &pDB, tInterface.flags)
			
			; check that the database opened without issues
			Yunit.Assert(res = SQLITE_OK, SQLite3.errmsg(pDB))
			Yunit.Assert(pDB != false, 'the database pointer was not set')
			SQLite3.close_v2(pDB)
		}
		test2_close_v2()
		{
			res := SQLite3.open_v2('test.db', &pDB, tInterface.flags)
			
			; check that the database opened without issues
			Yunit.Assert(res = SQLITE_OK, SQLite3.errmsg(pDB))
			SQLite3.close_v2(pDB)
			Yunit.Assert(!SQLite3.ptrs.Has(pDB), 'the database pointer was not removed')

			; as the database is closed the following call should return
			; code 21 which is 'bad parameter or other API misuse'
			Yunit.Assert(SQLite3.errcode(pDB) = SQLITE_MISUSE, 'the expected error code was not returned')
		}
		test7_exec()
		{
			static statement := "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);"

			res := SQLite3.open_v2('test.db', &pDB, tInterface.flags)
			
			; check that the database opened without issues
			Yunit.Assert(res = SQLITE_OK, SQLite3.errmsg(pDB))

			res := SQLite3.exec(pDB, statement, &errmsg)
			errmsg := 'Failed to execute simple SQL statement: ' (errmsg ? StrGet(errmsg, 'utf-8') : '')
			Yunit.Assert(res = SQLITE_OK, errmsg)
			SQLite3.close_v2(pDB)
		}
	}

	Class t2InvalidInput
	{
		test1_open_v2_invalid_flags()
		{
			res := SQLite3.open_v2('test.db', &pDB, -1)
			Yunit.Assert(res = SQLITE_MISUSE, "open_v2 should throw an exception with invalid flags")
			SQLite3.close_v2(pDB)
		}
		test2_open_v2_zVfs_set()
		{
			try
			{
				res := SQLite3.open_v2('test.db', &pDB, tInterface.flags, 1)
				Yunit.Assert(false, 'open_v2 should throw an exception when zVfs is set')
			}
			catch Error
				Yunit.Assert(true)
		}
		test3_close_v2_invalid_pointer()
		{
			res := SQLite3.open_v2('test.db', &pDB, tInterface.flags)
			
			; check that the database opened without issues
			Yunit.Assert(res = SQLITE_OK, SQLite3.errmsg(pDB))

			try
			{
				SQLite3.close_v2('invalid pointer')
				Yunit.Assert(false)
			}
			catch Error
				Yunit.Assert(true)
		}
		test8_exec_invalid_statement()
		{
			static statement := "INVALID SQL STATEMENT"

			res := SQLite3.open_v2('test.db', &pDB, tInterface.flags)
			
			; check that the database opened without issues
			Yunit.Assert(res = SQLITE_OK, SQLite3.errmsg(pDB))

			res := SQLite3.exec(pDB, statement, &errmsg)
			errmsg := 'Incorrect result code: ' (errmsg ? StrGet(errmsg, 'utf-8') : '')
			Yunit.Assert(res = SQLITE_ERROR, errmsg)
			SQLite3.close_v2(pDB)
		}
	}
}