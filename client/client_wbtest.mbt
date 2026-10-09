///|
test "client URL helpers encode query parameters" {
  let client = new_client({
    url: "http://localhost:8086/",
    token: "secret",
    org: "my org",
    bucket: "my/bucket",
  })
  assert_eq(base_url(client), "http://localhost:8086")
  assert_eq(
    write_url(client, "ms"),
    "http://localhost:8086/api/v2/write?org=my%20org&bucket=my%2Fbucket&precision=ms",
  )
  assert_eq(
    query_url(client),
    "http://localhost:8086/api/v2/query?org=my%20org",
  )
}
