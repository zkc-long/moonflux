///|
/// A typed value from an InfluxDB annotated CSV cell.
pub(all) enum FluxValue {
  StringValue(String)
  LongValue(Int64)
  UnsignedLongValue(UInt64)
  DoubleValue(Double)
  BooleanValue(Bool)
  DateTimeValue(String)
  DurationValue(String)
  Base64BinaryValue(String)
  UnknownValue(String)
}

///|
/// One annotated CSV cell with its raw text and parsed value.
pub(all) struct FluxCell {
  raw : String
  value : FluxValue
}

///|
/// Column metadata for one Flux result table.
pub(all) struct FluxColumn {
  name : String
  data_type : String
  group : Bool
  default : String
}

///|
/// One table in a Flux annotated CSV response.
pub(all) struct FluxTable {
  columns : Array[FluxColumn]
  rows : Array[Array[FluxCell]]
}

///|
/// Multi-table Flux query result.
pub(all) struct FluxQueryResult {
  tables : Array[FluxTable]
}

///|
/// Parse a multi-table Flux annotated CSV response.
pub fn parse_flux_query_result(
  text : String,
) -> Result[FluxQueryResult, String] {
  let records = match parse_csv_records(text) {
    Ok(records) => records
    Err(error) => return Err(error)
  }
  let tables : Array[FluxTable] = Array(capacity=0)
  let mut data_types : Array[String]? = None
  let mut groups : Array[Bool]? = None
  let mut defaults : Array[String]? = None
  let mut header : Array[String]? = None
  let mut raw_rows : Array[Array[String]] = Array(capacity=0)

  for record in records {
    if is_blank_record(record) {
      match flush_flux_table(header, data_types, groups, defaults, raw_rows) {
        Ok(Some(table)) => tables.push(table)
        Ok(None) => ()
        Err(error) => return Err(error)
      }
      header = None
      data_types = None
      groups = None
      defaults = None
      raw_rows = Array(capacity=0)
      continue
    }
    if record.is_empty() {
      continue
    }
    let first = record[0]
    if first == "#datatype" {
      match header {
        Some(_) => {
          match
            flush_flux_table(header, data_types, groups, defaults, raw_rows) {
            Ok(Some(table)) => tables.push(table)
            Ok(None) => ()
            Err(error) => return Err(error)
          }
          header = None
          groups = None
          defaults = None
          raw_rows = Array(capacity=0)
        }
        None => ()
      }
      data_types = Some(annotation_tail(record))
      continue
    }
    if first == "#group" {
      match parse_group_annotation(record) {
        Ok(values) => groups = Some(values)
        Err(error) => return Err(error)
      }
      continue
    }
    if first == "#default" {
      defaults = Some(annotation_tail(record))
      continue
    }
    if first.has_prefix("#") {
      continue
    }
    match header {
      Some(_) => raw_rows.push(record)
      None => header = Some(record)
    }
  }

  match flush_flux_table(header, data_types, groups, defaults, raw_rows) {
    Ok(Some(table)) => tables.push(table)
    Ok(None) => ()
    Err(error) => return Err(error)
  }
  Ok({ tables, })
}

///|
/// Number of tables in a Flux result.
pub fn FluxQueryResult::table_count(self : FluxQueryResult) -> Int {
  self.tables.length()
}

///|
/// Number of data rows in a Flux table.
pub fn FluxTable::row_count(self : FluxTable) -> Int {
  self.rows.length()
}

///|
/// Find a column index by name.
pub fn FluxTable::column_index(self : FluxTable, name : String) -> Int? {
  for i in 0..<self.columns.length() {
    if self.columns[i].name == name {
      return Some(i)
    }
  }
  None
}

///|
/// Return column names in table order.
pub fn FluxTable::column_names(self : FluxTable) -> Array[String] {
  self.columns.map(column => column.name)
}

///|
/// Return the group-key columns for one row.
pub fn FluxTable::group_pairs(
  self : FluxTable,
  row_index : Int,
) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = Array(capacity=0)
  if row_index >= self.rows.length() {
    return pairs
  }
  for column_index in 0..<self.columns.length() {
    let column = self.columns[column_index]
    if column.group {
      let row = self.rows[row_index]
      if column_index < row.length() {
        pairs.push((column.name, row[column_index].raw))
      }
    }
  }
  pairs
}

///|
/// Render group keys as a stable display string.
pub fn FluxTable::group_key_string(self : FluxTable, row_index : Int) -> String {
  let pairs = self.group_pairs(row_index)
  let parts : Array[String] = Array(capacity=0)
  for pair in pairs {
    parts.push(pair.0 + "=" + pair.1)
  }
  parts.join(", ")
}

///|
/// Return a named string value from one row.
pub fn FluxTable::string_value(
  self : FluxTable,
  row_index : Int,
  column_name : String,
) -> String? {
  match self.column_index(column_name) {
    Some(column_index) => {
      if row_index >= self.rows.length() ||
        column_index >= self.rows[row_index].length() {
        return None
      }
      Some(self.rows[row_index][column_index].raw)
    }
    None => None
  }
}

///|
/// Return the first row's table identifier.
pub fn FluxTable::table_id(self : FluxTable) -> String? {
  self.string_value(0, "table")
}

///|
/// Return the first row's measurement.
pub fn FluxTable::measurement(self : FluxTable) -> String? {
  self.string_value(0, "_measurement")
}

///|
/// Return the first row's field.
pub fn FluxTable::field(self : FluxTable) -> String? {
  self.string_value(0, "_field")
}

///|
/// Render a Flux value for terminal output.
pub fn flux_value_display(value : FluxValue) -> String {
  match value {
    StringValue(value)
    | DateTimeValue(value)
    | DurationValue(value)
    | Base64BinaryValue(value)
    | UnknownValue(value) => value
    LongValue(value) => value.to_string()
    UnsignedLongValue(value) => value.to_string()
    DoubleValue(value) => value.to_string()
    BooleanValue(value) => if value { "true" } else { "false" }
  }
}

///|
/// Render a Flux value as a JSON token.
pub fn flux_value_json(value : FluxValue) -> String {
  match value {
    StringValue(value)
    | DateTimeValue(value)
    | DurationValue(value)
    | Base64BinaryValue(value)
    | UnknownValue(value) => "\"" + escape_json(value) + "\""
    LongValue(value) => value.to_string()
    UnsignedLongValue(value) => value.to_string()
    DoubleValue(value) => value.to_string()
    BooleanValue(value) => if value { "true" } else { "false" }
  }
}

///|
/// Render a complete multi-table Flux result as JSON.
pub fn flux_query_result_json(result : FluxQueryResult) -> String {
  let out = StringBuilder()
  out.write_string("{\"tables\":[")
  for table_index in 0..<result.tables.length() {
    if table_index > 0 {
      out.write_char(',')
    }
    let table = result.tables[table_index]
    out.write_string("{\"tableId\":")
    match table.table_id() {
      Some(value) => out.write_string("\"" + escape_json(value) + "\"")
      None => out.write_string("null")
    }
    out.write_string(",\"columns\":[")
    for column_index in 0..<table.columns.length() {
      if column_index > 0 {
        out.write_char(',')
      }
      let column = table.columns[column_index]
      out.write_string("{")
      out.write_string("\"name\":\"" + escape_json(column.name) + "\",")
      out.write_string(
        "\"dataType\":\"" + escape_json(column.data_type) + "\",",
      )
      out.write_string("\"group\":")
      out.write_string(if column.group { "true" } else { "false" })
      out.write_char(',')
      out.write_string("\"default\":\"" + escape_json(column.default) + "\"")
      out.write_string("}")
    }
    out.write_string("],\"rows\":[")
    for row_index in 0..<table.rows.length() {
      if row_index > 0 {
        out.write_char(',')
      }
      out.write_char('{')
      let row = table.rows[row_index]
      for column_index in 0..<table.columns.length() {
        if column_index > 0 {
          out.write_char(',')
        }
        out.write_string(
          "\"" + escape_json(table.columns[column_index].name) + "\":",
        )
        out.write_string(flux_value_json(row[column_index].value))
      }
      out.write_char('}')
    }
    out.write_string("]}")
  }
  out.write_string("]}")
  out.to_string()
}

///|
/// Build one table from its header, annotations, and raw rows.
fn make_flux_table(
  header : Array[String],
  data_types : Array[String]?,
  groups : Array[Bool]?,
  defaults : Array[String]?,
  raw_rows : Array[Array[String]],
) -> Result[FluxTable, String] {
  let columns : Array[FluxColumn] = Array(capacity=0)
  for column_index in 1..<header.length() {
    columns.push({
      name: header[column_index],
      data_type: annotation_string(data_types, column_index - 1, "string"),
      group: annotation_bool(groups, column_index - 1, false),
      default: annotation_string(defaults, column_index - 1, ""),
    })
  }

  let rows : Array[Array[FluxCell]] = Array(capacity=0)
  for row_index in 0..<raw_rows.length() {
    let raw_row = raw_rows[row_index]
    if raw_row.length() != header.length() {
      return Err(
        "Flux table row \{row_index} has \{raw_row.length()} cells; expected \{header.length()}",
      )
    }
    let cells : Array[FluxCell] = Array(capacity=0)
    for column_index in 0..<columns.length() {
      let effective = if raw_row[column_index + 1].is_empty() {
        columns[column_index].default
      } else {
        raw_row[column_index + 1]
      }
      match parse_flux_value(effective, columns[column_index].data_type) {
        Ok(value) => cells.push({ raw: effective, value, })
        Err(error) =>
          return Err(
            "Flux table row \{row_index}, column \{columns[column_index].name}: \{error}",
          )
      }
    }
    rows.push(cells)
  }
  Ok({ columns, rows, })
}

///|
/// Parse a typed annotated CSV value.
fn parse_flux_value(
  raw : String,
  data_type : String,
) -> Result[FluxValue, String] {
  if data_type.has_prefix("dateTime") {
    return Ok(DateTimeValue(raw))
  }
  if data_type.has_prefix("duration") {
    return Ok(DurationValue(raw))
  }
  if data_type.has_prefix("base64Binary") {
    return Ok(Base64BinaryValue(raw))
  }
  match data_type {
    "long" =>
      match parse_int64_value(raw) {
        Ok(value) => Ok(LongValue(value))
        Err(error) => Err(error)
      }
    "unsignedLong" =>
      match parse_uint64_value(raw) {
        Ok(value) => Ok(UnsignedLongValue(value))
        Err(error) => Err(error)
      }
    "double" =>
      match parse_double_value(raw) {
        Ok(value) => Ok(DoubleValue(value))
        Err(error) => Err(error)
      }
    "boolean" => {
      let lower = raw.to_lower()
      if lower == "true" || lower == "t" || lower == "1" {
        Ok(BooleanValue(true))
      } else if lower == "false" || lower == "f" || lower == "0" {
        Ok(BooleanValue(false))
      } else {
        Err("invalid boolean value \{raw}")
      }
    }
    "string" => Ok(StringValue(raw))
    _ => Ok(UnknownValue(raw))
  }
}

///|
/// Parse a CSV document into logical rows.
fn parse_csv_records(text : String) -> Result[Array[Array[String]], String] {
  let records : Array[Array[String]] = Array(capacity=0)
  let mut current : Array[String] = Array(capacity=0)
  let field = StringBuilder()
  let mut in_quotes = false
  let mut i = 0
  while i < text.length() {
    let code = text.at(i).to_int()
    if in_quotes {
      if code == 34 {
        if i + 1 < text.length() && text.at(i + 1).to_int() == 34 {
          field.write_char('"')
          i = i + 1
        } else {
          in_quotes = false
        }
      } else {
        field.write_char(text.at(i).to_char().unwrap())
      }
    } else if code == 34 {
      in_quotes = true
    } else if code == 44 {
      current.push(field.to_string())
      field.reset()
    } else if code == 10 {
      current.push(field.to_string())
      field.reset()
      records.push(current)
      current = Array(capacity=0)
    } else if code != 13 {
      field.write_char(text.at(i).to_char().unwrap())
    }
    i = i + 1
  }
  if in_quotes {
    return Err("unterminated quoted CSV field")
  }
  if current.length() > 0 || !field.is_empty() {
    current.push(field.to_string())
    records.push(current)
  }
  Ok(records)
}

///|
/// Check whether a CSV record is an empty table separator.
fn is_blank_record(record : Array[String]) -> Bool {
  record.length() == 0 || (record.length() == 1 && record[0].is_empty())
}

///|
/// Drop the annotation marker from a CSV record.
fn annotation_tail(record : Array[String]) -> Array[String] {
  record[1:record.length()].to_owned()
}

///|
/// Parse #group annotation values.
fn parse_group_annotation(
  record : Array[String],
) -> Result[Array[Bool], String] {
  let values = annotation_tail(record)
  let out : Array[Bool] = Array(capacity=0)
  for value in values {
    let lower = value.to_lower()
    if lower == "true" {
      out.push(true)
    } else if lower == "false" || lower.is_empty() {
      out.push(false)
    } else {
      return Err("invalid #group value \{value}")
    }
  }
  Ok(out)
}

///|
/// Return one annotation value or a default.
fn annotation_string(
  values : Array[String]?,
  index : Int,
  default : String,
) -> String {
  match values {
    Some(values) =>
      if index < values.length() {
        values[index]
      } else {
        default
      }
    None => default
  }
}

///|
/// Return one boolean annotation value or a default.
fn annotation_bool(values : Array[Bool]?, index : Int, default : Bool) -> Bool {
  match values {
    Some(values) =>
      if index < values.length() {
        values[index]
      } else {
        default
      }
    None => default
  }
}

///|
/// Flush the current table state.
fn flush_flux_table(
  header : Array[String]?,
  data_types : Array[String]?,
  groups : Array[Bool]?,
  defaults : Array[String]?,
  raw_rows : Array[Array[String]],
) -> Result[FluxTable?, String] {
  match header {
    None => Ok(None)
    Some(header) =>
      match make_flux_table(header, data_types, groups, defaults, raw_rows) {
        Ok(table) => Ok(Some(table))
        Err(error) => Err(error)
      }
  }
}

///|
/// Parse an Int64 field with context-free errors.
fn parse_int64_value(text : String) -> Result[Int64, String] {
  Ok(@string.parse_int64(text)) catch {
    _ => Err("invalid long value \{text}")
  }
}

///|
/// Parse a UInt64 field with context-free errors.
fn parse_uint64_value(text : String) -> Result[UInt64, String] {
  Ok(@string.parse_uint64(text)) catch {
    _ => Err("invalid unsignedLong value \{text}")
  }
}

///|
/// Parse a Double field with context-free errors.
fn parse_double_value(text : String) -> Result[Double, String] {
  Ok(@string.parse_double(text)) catch {
    _ => Err("invalid double value \{text}")
  }
}

///|
/// Escape one JSON string.
fn escape_json(value : String) -> String {
  let out = StringBuilder()
  for i in 0..<value.length() {
    let code = value.at(i).to_int()
    match code {
      34 => out.write_string("\\\"")
      92 => out.write_string("\\\\")
      10 => out.write_string("\\n")
      13 => out.write_string("\\r")
      9 => out.write_string("\\t")
      _ => out.write_char(value.at(i).to_char().unwrap())
    }
  }
  out.to_string()
}
