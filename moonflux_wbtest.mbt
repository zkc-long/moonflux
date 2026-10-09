test "field value suffix detection" {
  match parse_field_value("17i") {
    Ok(IntValue(value)) => @test.assert_eq(value, 17L)
    _ => @test.fail("expected integer field")
  }
  match parse_field_value("17u") {
    Ok(UIntValue(value)) => @test.assert_eq(value, 17UL)
    _ => @test.fail("expected unsigned field")
  }
  match parse_field_value("17.5") {
    Ok(DoubleValue(value)) => @test.assert_eq(value, 17.5)
    _ => @test.fail("expected float field")
  }
}
