///| InfluxDB v2 client configuration.
pub(all) struct ClientConfig {
  url : String
  token : String
  org : String
  bucket : String
}

///| A small InfluxDB v2 HTTP client.
pub(all) struct Client {
  config : ClientConfig
}

///| Create a client from configuration.
pub fn new_client(config : ClientConfig) -> Client {
  { config, }
}

///| Ping the InfluxDB /health endpoint and return the HTTP status.
pub async fn Client::ping(self : Client) -> Result[Int, String] {
  try {
    let url = self.config.url + "/health"
    let (response, _body) = @http.get(url)
    Ok(response.code)
  } catch {
    _ => Err("failed to reach InfluxDB health endpoint")
  }
}

///| Write a line-protocol payload to the configured bucket.
pub async fn Client::write(self : Client, line : String) -> Result[Int, String] {
  try {
    let headers : Map[@http.CaseInsensitiveString, String] = Map([
      ("Authorization", "Token " + self.config.token),
      ("Content-Type", "text/plain; charset=utf-8"),
    ])
    let url =
      self.config.url +
      "/api/v2/write?org=" +
      self.config.org +
      "&bucket=" +
      self.config.bucket
    let (response, _body) = @http.post(url, line, headers=headers)
    Ok(response.code)
  } catch {
    _ => Err("failed to write to InfluxDB")
  }
}

///| Run a Flux query and parse the annotated CSV response.
pub async fn Client::query(
  self : Client,
  flux : String,
) -> Result[@moonflux.AnnotatedCsv, String] {
  try {
    let headers : Map[@http.CaseInsensitiveString, String] = Map([
      ("Authorization", "Token " + self.config.token),
      ("Accept", "application/csv"),
      ("Content-Type", "application/vnd.flux"),
    ])
    let url = self.config.url + "/api/v2/query?org=" + self.config.org
    let (response, body) = @http.post(url, flux, headers=headers)
    if response.code < 200 || response.code >= 300 {
      return Err("InfluxDB query failed with status \{response.code}")
    }
    match @moonflux.parse_annotated_csv(body.text()) {
      Ok(parsed) => Ok(parsed)
      Err(error) => Err(error)
    }
  } catch {
    _ => Err("failed to query InfluxDB or decode annotated CSV")
  }
}
