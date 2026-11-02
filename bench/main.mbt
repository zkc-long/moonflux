///|
/// Build a deterministic set of points for throughput measurements.
fn make_points(count : Int32) -> Array[@moonflux.Point] {
  let points : Array[@moonflux.Point] = Array(capacity=count)
  for i in 0..<count {
    points.push(
      @moonflux.new_point("weather")
      .add_tag("host", "host-" + i.to_string())
      .add_field("temperature", @moonflux.DoubleValue(Double::from_int(i)))
      .add_field("ok", @moonflux.BoolValue(true))
      .set_timestamp(1700000000000000000L + i.to_int64()),
    )
  }
  points
}

///|
/// Build a deterministic annotated CSV with many logical tables.
fn make_flux_csv(rows : Int32) -> String {
  let out = StringBuilder()
  out.write_string(
    "#datatype,string,long,dateTime:RFC3339,double,string,string,string\n",
  )
  out.write_string("#group,false,false,false,false,true,true,true\n")
  out.write_string("#default,_result,,,,,,\n")
  out.write_string(",result,table,_time,_value,_field,_measurement,host\n")
  for i in 0..<rows {
    let table_id = i / 100
    let value = Double::from_int(i).to_string()
    out.write_string(
      ",,\{table_id},2026-10-16T00:00:00Z,\{value},temperature,weather,host-\{table_id}\n",
    )
  }
  out.to_string()
}

///|
/// Run deterministic encoding and parsing benchmarks.
fn main {
  let bench = @benchlib.Bench()
  let points = make_points(10000)
  let encoded = match @moonflux.encode_points(points) {
    Ok(value) => value
    Err(_) => ""
  }
  let csv = make_flux_csv(10000)

  bench.bench(name="encode_10k_points", count=5, () => {
    match @moonflux.encode_points(points) {
      Ok(value) => bench.keep(value)
      Err(_) => ()
    }
  })
  bench.bench(name="parse_10k_lines", count=5, () => {
    match @moonflux.parse_lines(encoded) {
      Ok(value) => bench.keep(value)
      Err(_) => ()
    }
  })
  bench.bench(name="parse_10k_flux_rows", count=5, () => {
    match @moonflux.parse_flux_query_result(csv) {
      Ok(value) => bench.keep(value)
      Err(_) => ()
    }
  })
  println(bench.dump_summaries())
}
