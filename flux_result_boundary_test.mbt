///|
test "parse quoted newline in flux csv cell" {
  let csv = "#datatype,string,long,string\n" +
    "#group,false,false,false\n" +
    "#default,,,\n" +
    ",result,table,message\n" +
    ",,0,\"line1\nline2\"\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(result) => {
      @test.assert_eq(result.table_count(), 1)
      match result.tables[0].rows[0][2].value {
        @moonflux.StringValue(value) => @test.assert_eq(value, "line1\nline2")
        _ => @test.fail("expected quoted string")
      }
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "apply flux default values to empty cells" {
  let csv = "#datatype,string,long,double\n" +
    "#group,false,false,false\n" +
    "#default,_result,,1.5\n" +
    ",result,table,_value\n" +
    ",,0,\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(result) =>
      match result.tables[0].rows[0][2].value {
        @moonflux.DoubleValue(value) => @test.assert_eq(value, 1.5)
        _ => @test.fail("expected default double")
      }
    Err(error) => @test.fail(error)
  }
}

///|
test "preserve header-only flux table" {
  let csv = "#datatype,string,long,double\n" +
    "#group,false,false,false\n" +
    "#default,,,\n" +
    ",result,table,_value\n" +
    "\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(result) => {
      @test.assert_eq(result.table_count(), 1)
      @test.assert_eq(result.tables[0].row_count(), 0)
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "reject malformed flux csv boundaries" {
  let bad_width = "#datatype,string,long,double\n" +
    "#group,false,false,false\n" +
    "#default,,,\n" +
    ",result,table,_value\n" +
    ",,0\n"
  match @moonflux.parse_flux_query_result(bad_width) {
    Ok(_) => @test.fail("expected column count error")
    Err(error) => @test.assert_eq(true, error.contains("expected"))
  }

  let bad_group = "#datatype,string\n#group,maybe\n#default,\n,result\n"
  match @moonflux.parse_flux_query_result(bad_group) {
    Ok(_) => @test.fail("expected group error")
    Err(error) => @test.assert_eq(true, error.contains("#group"))
  }
}
