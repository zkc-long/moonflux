///|
/// InfluxDB field value variants.
pub(all) enum FieldValue {
  IntValue(Int64)
  UIntValue(UInt64)
  DoubleValue(Double)
  StringValue(String)
  BoolValue(Bool)
}

///|
/// A point ready for encoding as InfluxDB Line Protocol.
pub(all) struct Point {
  measurement : String
  tags : Array[(String, String)]
  fields : Array[(String, FieldValue)]
  timestamp : Int64?
}

///|
/// Create an empty point for a measurement.
pub fn new_point(measurement : String) -> Point {
  {
    measurement,
    tags: Array(capacity=0),
    fields: Array(capacity=0),
    timestamp: None,
  }
}

///|
/// Add one tag and return the updated point.
pub fn Point::add_tag(self : Point, key : String, value : String) -> Point {
  let point = self
  point.tags.push((key, value))
  point
}

///|
/// Add one field and return the updated point.
pub fn Point::add_field(
  self : Point,
  key : String,
  value : FieldValue,
) -> Point {
  let point = self
  point.fields.push((key, value))
  point
}

///|
/// Set a nanosecond timestamp and return the updated point.
pub fn Point::set_timestamp(self : Point, timestamp : Int64) -> Point {
  { ..self, timestamp: Some(timestamp), }
}
