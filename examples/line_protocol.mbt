///| Encode and parse a point with MoonFlux.
fn main {
  let point = @moonflux.new_point("weather")
    .add_tag("location", "shanghai")
    .add_field("temperature", @moonflux.DoubleValue(21.5))
    .add_field("ok", @moonflux.BoolValue(true))
    .set_timestamp(1700000000000000000L)

  match @moonflux.encode_point(point) {
    Ok(line) => {
      println(line)
      match @moonflux.parse_line(line) {
        Ok(parsed) => println(parsed.measurement)
        Err(error) => println(error)
      }
    }
    Err(error) => println(error)
  }
}
