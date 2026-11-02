///|
test "field value suffix detection" {
  match parse_field_value("17i") {
    Ok(IntValue(value)) => assert_eq(value, 17L)
    _ => assert_eq(false, true)
  }
  match parse_field_value("17u") {
    Ok(UIntValue(value)) => assert_eq(value, 17UL)
    _ => assert_eq(false, true)
  }
  match parse_field_value("17.5") {
    Ok(DoubleValue(value)) => assert_eq(value, 17.5)
    _ => assert_eq(false, true)
  }
}
