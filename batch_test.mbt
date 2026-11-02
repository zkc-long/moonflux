///|
test "split line protocol by point count" {
  let text = "a v=1\nb v=2\nc v=3\nd v=4\n"
  match
    @moonflux.split_line_protocol(text, @moonflux.BatchLimits::new(2, 1024)) {
    Ok(batches) => {
      @test.assert_eq(batches.length(), 2)
      @test.assert_eq(batches[0], "a v=1\nb v=2")
      @test.assert_eq(batches[1], "c v=3\nd v=4")
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "split line protocol by byte count" {
  let text = "a v=1\nb v=22\nc v=333"
  match
    @moonflux.split_line_protocol(text, @moonflux.BatchLimits::new(10, 12)) {
    Ok(batches) => {
      @test.assert_eq(batches.length(), 2)
      @test.assert_eq(batches[0], "a v=1\nb v=22")
      @test.assert_eq(batches[1], "c v=333")
    }
    Err(error) => @test.fail(error)
  }
}

///|
test "reject oversized batch line" {
  let text = "measurement field=123456789"
  match @moonflux.split_line_protocol(text, @moonflux.BatchLimits::new(10, 5)) {
    Ok(_) => @test.fail("expected oversized line error")
    Err(error) =>
      @test.assert_eq(true, error.contains("single point exceeds max_bytes"))
  }
}

///|
test "encode point batches" {
  let points = [
    @moonflux.new_point("a").add_field("v", @moonflux.IntValue(1L)),
    @moonflux.new_point("b").add_field("v", @moonflux.IntValue(2L)),
    @moonflux.new_point("c").add_field("v", @moonflux.IntValue(3L)),
  ]
  match
    @moonflux.encode_point_batches(points, @moonflux.BatchLimits::new(2, 1024)) {
    Ok(batches) => {
      @test.assert_eq(batches.length(), 2)
      @test.assert_eq(batches[0], "a v=1i\nb v=2i")
      @test.assert_eq(batches[1], "c v=3i")
    }
    Err(error) => @test.fail(error)
  }
}
