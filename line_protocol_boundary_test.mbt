///|
test "roundtrip measurement tag and field key escapes" {
  let point = @moonflux.new_point("cpu load")
    .add_tag("host name", "a,b=c")
    .add_field("user time", @moonflux.DoubleValue(1.5))
  match @moonflux.encode_point(point) {
    Ok(line) => {
      @test.assert_eq(line, "cpu\\ load,host\\ name=a\\,b\\=c user\\ time=1.5")
      match @moonflux.parse_line(line) {
        Ok(parsed) => {
          @test.assert_eq(parsed.measurement, "cpu load")
          @test.assert_eq(parsed.tags[0], ("host name", "a,b=c"))
          @test.assert_eq(parsed.fields.length(), 1)
        }
        Err(error) => @test.fail(error)
      }
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "parse quoted commas spaces and boolean variants" {
  match @moonflux.parse_line("m msg=\"hello, world\",a=TRUE,b=t,c=False,d=f") {
    Ok(point) => {
      match point.fields[0] {
        (_, @moonflux.StringValue(value)) =>
          @test.assert_eq(value, "hello, world")
        _ => @test.fail("expected quoted string")
      }
      match point.fields[1] {
        (_, @moonflux.BoolValue(value)) => @test.assert_eq(value, true)
        _ => @test.fail("expected boolean")
      }
      match point.fields[2] {
        (_, @moonflux.BoolValue(value)) => @test.assert_eq(value, true)
        _ => @test.fail("expected boolean")
      }
      match point.fields[3] {
        (_, @moonflux.BoolValue(value)) => @test.assert_eq(value, false)
        _ => @test.fail("expected boolean")
      }
      match point.fields[4] {
        (_, @moonflux.BoolValue(value)) => @test.assert_eq(value, false)
        _ => @test.fail("expected boolean")
      }
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "parse scientific notation and negative timestamp" {
  match @moonflux.parse_line("m value=1.2e3 -100") {
    Ok(point) => {
      match point.fields[0] {
        (_, @moonflux.DoubleValue(value)) => @test.assert_eq(value, 1200.0)
        _ => @test.fail("expected double")
      }
      @test.assert_eq(point.timestamp, Some(-100L))
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "parse CRLF payload" {
  match @moonflux.parse_lines("a v=1\r\nb v=2\r\n") {
    Ok(points) => {
      @test.assert_eq(points.length(), 2)
      @test.assert_eq(points[0].measurement, "a")
      @test.assert_eq(points[1].measurement, "b")
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "reject malformed line protocol boundary cases" {
  let cases = ["m", "m v", "m =1", "m v=1 bad", "m,host= v=1", "m v=1i extra"]
  for line in cases {
    match @moonflux.parse_line(line) {
      Ok(_) => @test.fail("expected parse failure for " + line)
      Err(_) => ()
    }
  }
}

///|
test "reject invalid field values and duplicate keys" {
  let empty_tag = @moonflux.new_point("m")
    .add_tag("", "v")
    .add_field("v", @moonflux.IntValue(1L))
  @test.assert_eq(
    @moonflux.validate_point(empty_tag),
    Err("tag key must not be empty"),
  )

  let duplicate_field = @moonflux.new_point("m")
    .add_field("v", @moonflux.IntValue(1L))
    .add_field("v", @moonflux.IntValue(2L))
  @test.assert_eq(
    @moonflux.validate_point(duplicate_field),
    Err("duplicate field key: v"),
  )

  let infinite = @moonflux.new_point("m").add_field(
    "v",
    @moonflux.DoubleValue(@double.infinity),
  )
  @test.assert_eq(
    @moonflux.validate_point(infinite),
    Err("float field must be finite: v"),
  )
}
