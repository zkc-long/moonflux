///|
test "parse multiple typed Flux tables" {
  let csv = "#datatype,string,long,dateTime:RFC3339,double,string,string\n" +
    "#group,false,false,false,false,true,true\n" +
    "#default,_result,,,,,\n" +
    ",result,table,_time,_value,_field,_measurement\n" +
    ",,0,2026-10-16T00:00:00Z,21.5,temperature,weather\n" +
    ",,0,2026-10-16T01:00:00Z,22.5,temperature,weather\n" +
    "\n" +
    "#datatype,string,long,dateTime:RFC3339,long,string,string\n" +
    "#group,false,false,false,false,true,true\n" +
    "#default,_result,,,,,\n" +
    ",result,table,_time,_value,_field,_measurement\n" +
    ",,1,2026-10-16T00:00:00Z,42,humidity,weather\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(result) => {
      @test.assert_eq(result.table_count(), 2)
      @test.assert_eq(result.tables[0].row_count(), 2)
      @test.assert_eq(result.tables[1].row_count(), 1)
      @test.assert_eq(result.tables[0].table_id(), Some("0"))
      @test.assert_eq(result.tables[1].table_id(), Some("1"))
      @test.assert_eq(result.tables[0].columns[3].data_type, "double")
      @test.assert_eq(result.tables[1].columns[3].data_type, "long")
      match result.tables[0].rows[0][3].value {
        @moonflux.DoubleValue(value) => @test.assert_eq(value, 21.5)
        _ => @test.fail("expected double value")
      }
      match result.tables[1].rows[0][3].value {
        @moonflux.LongValue(value) => @test.assert_eq(value, 42L)
        _ => @test.fail("expected long value")
      }
      @test.assert_eq(
        result.tables[0].group_key_string(0),
        "_field=temperature, _measurement=weather",
      )
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "render multi-table Flux result as JSON" {
  let csv = "#datatype,string,long,dateTime:RFC3339,double,string,string\n" +
    "#group,false,false,false,false,true,true\n" +
    "#default,_result,,,,,\n" +
    ",result,table,_time,_value,_field,_measurement\n" +
    ",,0,2026-10-16T00:00:00Z,21.5,temperature,weather\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(result) => {
      let json = @moonflux.flux_query_result_json(result)
      @test.assert_eq(true, json.contains("\"tables\""))
      @test.assert_eq(true, json.contains("\"temperature\""))
      @test.assert_eq(true, json.contains("21.5"))
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "reject invalid annotated CSV types" {
  let csv = "#datatype,string,long,double\n" +
    "#group,false,false,false\n" +
    "#default,,,\n" +
    ",result,table,_value\n" +
    ",,0,not-a-number\n"
  match @moonflux.parse_flux_query_result(csv) {
    Ok(_) => @test.fail("expected invalid double error")
    Err(error) => @test.assert_eq(true, error.contains("invalid double value"))
  }
}
