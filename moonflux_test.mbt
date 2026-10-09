///|
test "encode a complete point" {
  let point = @moonflux.new_point("weather")
    .add_tag("location", "shanghai")
    .add_field("temperature", @moonflux.FieldValue::DoubleValue(21.5))
    .add_field("ok", @moonflux.FieldValue::BoolValue(true))
    .set_timestamp(1700000000000000000L)
  match @moonflux.encode_point(point) {
    Ok(line) =>
      @test.assert_eq(
        line, "weather,location=shanghai temperature=21.5,ok=true 1700000000000000000",
      )
    Err(error) => @test.fail(error)
  }
}

///|
test "escape and parse comma measurement" {
  let point = @moonflux.new_point("a,b").add_field(
    "value",
    @moonflux.FieldValue::IntValue(1L),
  )
  match @moonflux.encode_point(point) {
    Ok(line) => {
      @test.assert_eq(line, "a\\,b value=1i")
      match @moonflux.parse_line(line) {
        Ok(parsed) => @test.assert_eq(parsed.measurement, "a,b")
        Err(error) => @test.fail(error)
      }
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "parse string boolean and unsigned fields" {
  match @moonflux.parse_line("m,host=a name=\"x,y\",active=false,n=42u 100") {
    Ok(point) => {
      @test.assert_eq(point.tags[0], ("host", "a"))
      @test.assert_eq(point.timestamp, Some(100L))
      match point.fields[0] {
        (_, @moonflux.StringValue(value)) => @test.assert_eq(value, "x,y")
        _ => @test.fail("expected string field")
      }
      match point.fields[1] {
        (_, @moonflux.BoolValue(value)) => @test.assert_eq(value, false)
        _ => @test.fail("expected boolean field")
      }
      match point.fields[2] {
        (_, @moonflux.UIntValue(value)) => @test.assert_eq(value, 42UL)
        _ => @test.fail("expected unsigned field")
      }
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "reject point without fields" {
  let point = @moonflux.new_point("m")
  @test.assert_eq(
    @moonflux.encode_point(point),
    Err("at least one field is required"),
  )
}

///|
test "validate duplicate and non-finite point values" {
  let duplicate = @moonflux.new_point("m")
    .add_tag("host", "a")
    .add_tag("host", "b")
    .add_field("value", @moonflux.IntValue(1L))
  @test.assert_eq(
    @moonflux.validate_point(duplicate),
    Err("duplicate tag key: host"),
  )

  let non_finite = @moonflux.new_point("m").add_field(
    "value",
    @moonflux.DoubleValue(@double.not_a_number),
  )
  @test.assert_eq(
    @moonflux.validate_point(non_finite),
    Err("float field must be finite: value"),
  )
}

///|
test "parse annotated CSV" {
  let text = "#datatype,string,long,double\n" +
    "#group,false,false,false\n" +
    "#default,_result,,\n" +
    ",result,table,_value\n" +
    ",mean,0,21.5\n" +
    ",mean,1,22.5\n"
  match @moonflux.parse_annotated_csv(text) {
    Ok(parsed) => {
      @test.assert_eq(parsed.columns.length(), 3)
      @test.assert_eq(parsed.columns[0].name, "result")
      @test.assert_eq(parsed.columns[2].data_type, "double")
      @test.assert_eq(parsed.rows.length(), 2)
      @test.assert_eq(parsed.rows[1].values[3], "22.5")
    }
    Err(error) => @test.fail(error)
  }
}
