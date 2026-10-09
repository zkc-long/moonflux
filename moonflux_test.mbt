test "encode a complete point" {
  let point = @moonflux.new_point("weather")
    .add_tag("location", "shanghai")
    .add_field("temperature", @moonflux.FieldValue::DoubleValue(21.5))
    .add_field("ok", @moonflux.FieldValue::BoolValue(true))
    .set_timestamp(1700000000000000000L)
  match @moonflux.encode_point(point) {
    Ok(line) => @test.assert_eq(
      line,
      "weather,location=shanghai temperature=21.5,ok=true 1700000000000000000",
    )
    Err(error) => @test.fail(error)
  }
}

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

test "reject point without fields" {
  let point = @moonflux.new_point("m")
  @test.assert_eq(@moonflux.encode_point(point), Err("at least one field is required"))
}
